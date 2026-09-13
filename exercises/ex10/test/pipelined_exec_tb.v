`timescale 1ns/1ps

module pipelined_exec_tb;

    localparam ADD = 4'b0010;

    integer pass_count = 0;
    integer total_count = 0;

    task check(input ok, input [767:0] label);
        begin
            total_count = total_count + 1;
            if (ok) pass_count = pass_count + 1;
            else $display("[FAIL] %0s", label);
        end
    endtask

    reg clk = 0;
    always #5 clk = ~clk;

    reg        rst;
    reg  [4:0] d_ra1, d_ra2, d_wa;
    reg  [3:0] d_alu_control;
    reg        d_reg_write;
    wire       stall;
    wire [4:0] e_wa;
    wire [31:0] e_result;
    wire       e_reg_write;

    pipelined_exec dut(
        .clk(clk), .rst(rst),
        .d_ra1(d_ra1), .d_ra2(d_ra2), .d_wa(d_wa),
        .d_alu_control(d_alu_control), .d_reg_write(d_reg_write),
        .stall(stall), .e_wa(e_wa), .e_result(e_result), .e_reg_write(e_reg_write)
    );

    task present(input [4:0] ra1_val, input [4:0] ra2_val, input [4:0] wa_val,
                 input [3:0] ctrl_val, input rw_val);
        begin
            d_ra1 = ra1_val; d_ra2 = ra2_val; d_wa = wa_val;
            d_alu_control = ctrl_val; d_reg_write = rw_val;
        end
    endtask

    integer i;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, pipelined_exec_tb);

        for (i = 0; i < 32; i = i + 1) dut.rf.regs[i] = 32'b0;
        dut.rf.regs[2] = 32'd10;
        dut.rf.regs[3] = 32'd20;

        rst = 1;
        present(5'd0, 5'd0, 5'd0, ADD, 1'b0);
        @(posedge clk); #1;
        rst = 0;

        // ---- Step 1: present A ($1 = $2 + $3 = 30). No hazard yet. ----
        present(5'd2, 5'd3, 5'd1, ADD, 1'b1);
        #1;
        check(stall === 1'b0, "step1: no hazard should exist yet (pipeline just reset)");
        @(posedge clk); #1;

        // ---- Step 2: present B ($4 = $1 + $2). $1 is A's destination -> RAW hazard. ----
        present(5'd1, 5'd2, 5'd4, ADD, 1'b1);
        #1;
        check(stall === 1'b1, "step2: B reads $1 which A (in Execute) is about to write -- must stall");
        check(e_wa === 5'd1 && e_result === 32'd30 && e_reg_write === 1'b1,
              "step2: instruction A must be computing $1 = 10 + 20 = 30 in the Execute stage");
        @(posedge clk); #1;

        // ---- Step 3: B is re-presented (it was stalled). Hazard is gone now. ----
        present(5'd1, 5'd2, 5'd4, ADD, 1'b1);
        #1;
        check(stall === 1'b0, "step3: after one stall cycle, A has committed -- B must proceed now");
        check(e_reg_write === 1'b0, "step3: a bubble must appear in the Execute stage this cycle");
        @(posedge clk); #1;

        // ---- Step 4: present C ($5 = $3 + $3 = 40). No hazard with B ($4). ----
        present(5'd3, 5'd3, 5'd5, ADD, 1'b1);
        #1;
        check(stall === 1'b0, "step4: C does not depend on $4 -- must not stall");
        check(e_wa === 5'd4 && e_result === 32'd40 && e_reg_write === 1'b1,
              "step4: instruction B must be computing $4 = $1 + $2 = 30 + 10 = 40 (using the CORRECT, post-stall $1)");
        @(posedge clk); #1;

        // ---- Step 5: present D ($0 = $2 + $3). Writes $0 -- must never cause a stall for anyone. ----
        present(5'd2, 5'd3, 5'd0, ADD, 1'b1);
        #1;
        check(stall === 1'b0, "step5: no hazard with C ($5)");
        @(posedge clk); #1;

        // ---- Step 6: present E ($6 = $0 + $3). D's dest ($0) "matches" ra1 but must be ignored. ----
        present(5'd0, 5'd3, 5'd6, ADD, 1'b1);
        #1;
        check(stall === 1'b0, "step6: a pending write to $0 must never cause a stall, even if register numbers match");
        @(posedge clk); #1;

        // ---- Step 7: flush with a NOP; check E computing correctly. ----
        present(5'd0, 5'd0, 5'd0, ADD, 1'b0);
        #1;
        check(e_wa === 5'd6 && e_result === 32'd20 && e_reg_write === 1'b1,
              "step7: instruction E must be computing $6 = $0 + $3 = 0 + 20 = 20");
        @(posedge clk); #1;

        // ---- Final register file state ----
        check(dut.rf.regs[1] === 32'd30, "final: $1 has the wrong value");
        check(dut.rf.regs[4] === 32'd40, "final: $4 has the wrong value (this is the hazard-dependent result)");
        check(dut.rf.regs[5] === 32'd40, "final: $5 has the wrong value");
        check(dut.rf.regs[6] === 32'd20, "final: $6 has the wrong value");
        check(dut.rf.regs[0] === 32'd0,  "final: $0 must remain 0 even though an instruction targeted it");

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

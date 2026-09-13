`timescale 1ns/1ps

module datapath_tb;

    localparam ADD = 4'b0010, SUB = 4'b0110, AND_OP = 4'b0000, OR_OP = 4'b0001, SLT = 4'b0111;

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
    reg        reg_dst, branch, mem_read, mem_to_reg, mem_write, alu_src, reg_write;
    reg  [3:0] alu_control;
    wire [31:0] pc_out;
    wire [5:0]  opcode, funct;
    wire        zero_flag;

    mips_datapath dut(
        .clk(clk), .rst(rst),
        .reg_dst(reg_dst), .branch(branch), .mem_read(mem_read), .mem_to_reg(mem_to_reg),
        .alu_control(alu_control), .mem_write(mem_write), .alu_src(alu_src), .reg_write(reg_write),
        .pc_out(pc_out), .opcode(opcode), .funct(funct), .zero_flag(zero_flag)
    );

    // Drive control signals based on the current PC -- standing in for the
    // control unit you'll build for real in Exercise 9.
    always @(*) begin
        case (pc_out)
            32'd0, 32'd4, 32'd44: begin // addi
                reg_dst = 0; branch = 0; mem_read = 0; mem_to_reg = 0;
                alu_control = ADD; mem_write = 0; alu_src = 1; reg_write = 1;
            end
            32'd8: begin // add
                reg_dst = 1; branch = 0; mem_read = 0; mem_to_reg = 0;
                alu_control = ADD; mem_write = 0; alu_src = 0; reg_write = 1;
            end
            32'd12: begin // sub
                reg_dst = 1; branch = 0; mem_read = 0; mem_to_reg = 0;
                alu_control = SUB; mem_write = 0; alu_src = 0; reg_write = 1;
            end
            32'd16: begin // and
                reg_dst = 1; branch = 0; mem_read = 0; mem_to_reg = 0;
                alu_control = AND_OP; mem_write = 0; alu_src = 0; reg_write = 1;
            end
            32'd20: begin // or
                reg_dst = 1; branch = 0; mem_read = 0; mem_to_reg = 0;
                alu_control = OR_OP; mem_write = 0; alu_src = 0; reg_write = 1;
            end
            32'd24: begin // slt
                reg_dst = 1; branch = 0; mem_read = 0; mem_to_reg = 0;
                alu_control = SLT; mem_write = 0; alu_src = 0; reg_write = 1;
            end
            32'd28: begin // sw
                reg_dst = 0; branch = 0; mem_read = 0; mem_to_reg = 0;
                alu_control = ADD; mem_write = 1; alu_src = 1; reg_write = 0;
            end
            32'd32: begin // lw
                reg_dst = 0; branch = 0; mem_read = 1; mem_to_reg = 1;
                alu_control = ADD; mem_write = 0; alu_src = 1; reg_write = 1;
            end
            32'd36: begin // beq
                reg_dst = 0; branch = 1; mem_read = 0; mem_to_reg = 0;
                alu_control = SUB; mem_write = 0; alu_src = 0; reg_write = 0;
            end
            default: begin
                reg_dst = 0; branch = 0; mem_read = 0; mem_to_reg = 0;
                alu_control = ADD; mem_write = 0; alu_src = 0; reg_write = 0;
            end
        endcase
    end

    integer i;
    reg [31:0] expected_pc_trace [0:10];

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, datapath_tb);

        // Zero the register file and data memory (regfile32/data_mem have
        // no reset port -- this mirrors initializing real hardware state
        // for a repeatable test, not something your datapath needs to do).
        for (i = 0; i < 32; i = i + 1) dut.rf.regs[i] = 32'b0;
        for (i = 0; i < 64; i = i + 1) dut.dmem.mem[i] = 32'b0;

        // Preload the test program (see README.md for the assembly).
        dut.imem.mem[0]  = 32'h20010005; // addi $1, $0, 5
        dut.imem.mem[1]  = 32'h20020003; // addi $2, $0, 3
        dut.imem.mem[2]  = 32'h00221820; // add  $3, $1, $2
        dut.imem.mem[3]  = 32'h00222022; // sub  $4, $1, $2
        dut.imem.mem[4]  = 32'h00222824; // and  $5, $1, $2
        dut.imem.mem[5]  = 32'h00223025; // or   $6, $1, $2
        dut.imem.mem[6]  = 32'h0041382A; // slt  $7, $2, $1
        dut.imem.mem[7]  = 32'hAC030000; // sw   $3, 0($0)
        dut.imem.mem[8]  = 32'h8C080000; // lw   $8, 0($0)
        dut.imem.mem[9]  = 32'h10210001; // beq  $1, $1, 1
        dut.imem.mem[10] = 32'h20090063; // addi $9, $0, 99   (must be skipped)
        dut.imem.mem[11] = 32'h200A002A; // addi $10, $0, 42  (branch target)

        expected_pc_trace[0]  = 32'd0;
        expected_pc_trace[1]  = 32'd4;
        expected_pc_trace[2]  = 32'd8;
        expected_pc_trace[3]  = 32'd12;
        expected_pc_trace[4]  = 32'd16;
        expected_pc_trace[5]  = 32'd20;
        expected_pc_trace[6]  = 32'd24;
        expected_pc_trace[7]  = 32'd28;
        expected_pc_trace[8]  = 32'd32;
        expected_pc_trace[9]  = 32'd36;
        expected_pc_trace[10] = 32'd44;

        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        check(pc_out === 32'd0, "PC must be 0 immediately after reset");

        for (i = 0; i < 11; i = i + 1) begin
            check(pc_out === expected_pc_trace[i],
                  "PC trace diverged from the expected instruction sequence");
            if (expected_pc_trace[i] == 32'd36)
                check(zero_flag === 1'b1, "zero_flag must be 1 during the beq comparison ($1 == $1)");
            @(posedge clk); #1;
        end

        check(pc_out === 32'd48, "PC after the final instruction must be 48");

        check(dut.rf.regs[1] === 32'd5,  "register $1 has the wrong value after addi");
        check(dut.rf.regs[2] === 32'd3,  "register $2 has the wrong value after addi");
        check(dut.rf.regs[3] === 32'd8,  "register $3 has the wrong value after add");
        check(dut.rf.regs[4] === 32'd2,  "register $4 has the wrong value after sub");
        check(dut.rf.regs[5] === 32'd1,  "register $5 has the wrong value after and");
        check(dut.rf.regs[6] === 32'd7,  "register $6 has the wrong value after or");
        check(dut.rf.regs[7] === 32'd1,  "register $7 has the wrong value after slt");
        check(dut.rf.regs[8] === 32'd8,  "register $8 has the wrong value after lw");
        check(dut.rf.regs[9] === 32'd0,  "register $9 must be untouched -- the branch must skip that instruction");
        check(dut.rf.regs[10] === 32'd42, "register $10 has the wrong value after the branch target instruction");
        check(dut.dmem.mem[0] === 32'd8, "data memory word 0 has the wrong value after sw");

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

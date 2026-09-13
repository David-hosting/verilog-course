`timescale 1ns/1ps

module mips_cpu_tb;

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

    reg         rst;
    wire [31:0] pc_out;

    mips_cpu dut(.clk(clk), .rst(rst), .pc_out(pc_out));

    integer i;
    integer seen_loop_check;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mips_cpu_tb);

        // Zero the register file and data memory for a deterministic run.
        for (i = 0; i < 32; i = i + 1) dut.dp.rf.regs[i] = 32'b0;
        for (i = 0; i < 64; i = i + 1) dut.dp.dmem.mem[i] = 32'b0;

        // Preload the sum-1-to-5 loop program (see README.md).
        dut.dp.imem.mem[0]  = 32'h20010005; // addi $1, $0, 5
        dut.dp.imem.mem[1]  = 32'h20020000; // addi $2, $0, 0
        dut.dp.imem.mem[2]  = 32'h10200003; // beq  $1, $0, 3
        dut.dp.imem.mem[3]  = 32'h00411020; // add  $2, $2, $1
        dut.dp.imem.mem[4]  = 32'h2021FFFF; // addi $1, $1, -1
        dut.dp.imem.mem[5]  = 32'h1000FFFC; // beq  $0, $0, -4
        dut.dp.imem.mem[6]  = 32'hAC020000; // sw   $2, 0($0)
        dut.dp.imem.mem[7]  = 32'h8C050000; // lw   $5, 0($0)
        dut.dp.imem.mem[8]  = 32'h20030001; // addi $3, $0, 1
        dut.dp.imem.mem[9]  = 32'h00433002; // srl  $6, $2, $3
        dut.dp.imem.mem[10] = 32'h20080002; // addi $8, $0, 2
        dut.dp.imem.mem[11] = 32'h00483800; // sll  $7, $2, $8

        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        check(pc_out === 32'd0, "PC must be 0 immediately after reset");

        // ---- Early sanity checkpoint: reach the loop-condition check ----
        seen_loop_check = 0;
        for (i = 0; i < 3 && !seen_loop_check; i = i + 1) begin
            @(posedge clk); #1;
            if (pc_out === 32'd8) seen_loop_check = 1;
        end
        check(seen_loop_check == 1,
              "PC must reach address 8 (the loop condition check) within the first few cycles");

        // ---- Run the rest of the program (29 total instructions executed) ----
        for (i = 0; i < 27; i = i + 1) begin
            @(posedge clk); #1;
        end

        check(pc_out === 32'd48, "PC after the full program must be 48 -- the loop or a branch offset is likely wrong");

        check(dut.dp.rf.regs[1] === 32'd0,  "register $1 (loop counter) must end at 0");
        check(dut.dp.rf.regs[2] === 32'd15, "register $2 (sum) must equal 1+2+3+4+5 = 15");
        check(dut.dp.rf.regs[3] === 32'd1,  "register $3 has the wrong value");
        check(dut.dp.rf.regs[5] === 32'd15, "register $5 (loaded back from memory) must equal 15");
        check(dut.dp.rf.regs[6] === 32'd7,  "register $6 (sum >> 1) must equal 7");
        check(dut.dp.rf.regs[7] === 32'd60, "register $7 (sum << 2) must equal 60");
        check(dut.dp.rf.regs[8] === 32'd2,  "register $8 has the wrong value");
        check(dut.dp.dmem.mem[0] === 32'd15, "data memory word 0 must equal 15 after the sw instruction");

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

`timescale 1ns/1ps

module alu32_tb;

    localparam OP_AND = 4'b0000;
    localparam OP_OR  = 4'b0001;
    localparam OP_ADD = 4'b0010;
    localparam OP_SLL = 4'b0100;
    localparam OP_SRL = 4'b0101;
    localparam OP_SUB = 4'b0110;
    localparam OP_SLT = 4'b0111;
    localparam OP_NOR = 4'b1100;

    integer pass_count = 0;
    integer total_count = 0;

    reg  [31:0] a, b;
    reg  [3:0]  alu_control;
    wire [31:0] result;
    wire        zero;
    wire        overflow;

    alu32 dut(.a(a), .b(b), .alu_control(alu_control), .result(result), .zero(zero), .overflow(overflow));

    task check_full(input [31:0] exp_result, input exp_overflow, input [511:0] label);
        reg exp_zero;
        begin
            exp_zero = (exp_result == 32'b0);
            total_count = total_count + 1;
            if (result === exp_result && zero === exp_zero && overflow === exp_overflow) begin
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: a=%h b=%h ctrl=%b -> expected result=%h zero=%b ovf=%b, got result=%h zero=%b ovf=%b",
                          label, a, b, alu_control, exp_result, exp_zero, exp_overflow, result, zero, overflow);
            end
        end
    endtask

    task run(input [31:0] a_val, input [31:0] b_val, input [3:0] ctrl,
             input [31:0] exp_result, input exp_overflow, input [511:0] label);
        begin
            a = a_val; b = b_val; alu_control = ctrl;
            #1;
            check_full(exp_result, exp_overflow, label);
        end
    endtask

    integer i;
    reg [31:0] ra, rb;
    reg [31:0] exp_add, exp_sub;
    reg        exp_ovf;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, alu32_tb);

        // ---------------- AND / OR / NOR ----------------
        run(32'hFFFFFFFF, 32'h00000000, OP_AND, 32'h00000000, 1'b0, "AND with zero");
        run(32'hFF00FF00, 32'h0FF00FF0, OP_AND, 32'h0F000F00, 1'b0, "AND pattern");
        run(32'hFFFFFFFF, 32'h00000000, OP_OR,  32'hFFFFFFFF, 1'b0, "OR with zero");
        run(32'hFF00FF00, 32'h00FF00FF, OP_OR,  32'hFFFFFFFF, 1'b0, "OR pattern");
        run(32'h00000000, 32'h00000000, OP_NOR, 32'hFFFFFFFF, 1'b0, "NOR of zero and zero");
        run(32'hFFFFFFFF, 32'h00000000, OP_NOR, 32'h00000000, 1'b0, "NOR with all-ones");

        // ---------------- ADD, no overflow ----------------
        run(32'd10, 32'd15, OP_ADD, 32'd25, 1'b0, "ADD basic, no overflow");
        run(32'h00000000, 32'h00000000, OP_ADD, 32'h00000000, 1'b0, "ADD zero+zero");
        run(32'hFFFFFFFF, 32'h00000001, OP_ADD, 32'h00000000, 1'b0, "ADD -1 + 1 = 0, no overflow");

        // ---------------- ADD, overflow ----------------
        run(32'h7FFFFFFF, 32'h00000001, OP_ADD, 32'h80000000, 1'b1, "ADD max positive + 1 must overflow");
        run(32'h80000000, 32'h80000000, OP_ADD, 32'h00000000, 1'b1, "ADD two large negatives must overflow");
        run(32'h7FFFFFFF, 32'h7FFFFFFF, OP_ADD, 32'hFFFFFFFE, 1'b1, "ADD max positive + max positive must overflow");

        // ---------------- SUB, no overflow ----------------
        run(32'd10, 32'd3, OP_SUB, 32'd7, 1'b0, "SUB basic, no overflow");
        run(32'd5, 32'd5, OP_SUB, 32'd0, 1'b0, "SUB equal operands -> zero");

        // ---------------- SUB, overflow ----------------
        run(32'h80000000, 32'h00000001, OP_SUB, 32'h7FFFFFFF, 1'b1, "SUB min negative - 1 must overflow");
        run(32'h7FFFFFFF, 32'hFFFFFFFF, OP_SUB, 32'h80000000, 1'b1, "SUB max positive - (-1) must overflow");

        // ---------------- overflow must be 0 for non-arithmetic ops ----------------
        run(32'h80000000, 32'h80000000, OP_AND, 32'h80000000, 1'b0, "overflow must be 0 for AND regardless of operands");
        run(32'h7FFFFFFF, 32'h00000001, OP_OR,  32'h7FFFFFFF, 1'b0, "overflow must be 0 for OR regardless of operands");
        run(32'h80000000, 32'h80000000, OP_NOR, 32'h7FFFFFFF, 1'b0, "overflow must be 0 for NOR regardless of operands");
        run(32'h80000000, 32'h00000001, OP_SLT, 32'd1,        1'b0, "overflow must be 0 for SLT regardless of operands");
        run(32'h80000000, 32'h00000001, OP_SLL, 32'h00000000, 1'b0, "overflow must be 0 for SLL regardless of operands");
        run(32'h80000000, 32'h00000001, OP_SRL, 32'h40000000, 1'b0, "overflow must be 0 for SRL regardless of operands");

        // ---------------- SLT: signed boundary cases ----------------
        run(32'd5, 32'd10, OP_SLT, 32'd1, 1'b0, "SLT: 5 < 10 must be 1");
        run(32'd10, 32'd5, OP_SLT, 32'd0, 1'b0, "SLT: 10 < 5 must be 0");
        run(32'd5, 32'd5, OP_SLT, 32'd0, 1'b0, "SLT: equal values must be 0");
        run(32'hFFFFFFFF, 32'd1, OP_SLT, 32'd1, 1'b0, "SLT: -1 < 1 must be 1 (signed!)");
        run(32'd1, 32'hFFFFFFFF, OP_SLT, 32'd0, 1'b0, "SLT: 1 < -1 must be 0 (signed!)");
        run(32'h80000000, 32'h7FFFFFFF, OP_SLT, 32'd1, 1'b0, "SLT: min negative < max positive must be 1");
        run(32'h7FFFFFFF, 32'h80000000, OP_SLT, 32'd0, 1'b0, "SLT: max positive < min negative must be 0");

        // ---------------- SLL / SRL ----------------
        run(32'h00000001, 32'd0,  OP_SLL, 32'h00000001, 1'b0, "SLL by 0 must not change the value");
        run(32'h00000001, 32'd1,  OP_SLL, 32'h00000002, 1'b0, "SLL by 1 incorrect");
        run(32'h00000001, 32'd31, OP_SLL, 32'h80000000, 1'b0, "SLL by 31 incorrect");
        run(32'h80000000, 32'd0,  OP_SRL, 32'h80000000, 1'b0, "SRL by 0 must not change the value");
        run(32'h80000000, 32'd1,  OP_SRL, 32'h40000000, 1'b0, "SRL by 1 incorrect (must be logical, zero-filled)");
        run(32'h80000000, 32'd31, OP_SRL, 32'h00000001, 1'b0, "SRL by 31 incorrect");
        // Shift amount must come from b[4:0] only -- higher bits of b ignored.
        run(32'h00000001, 32'hFFFFFFE1, OP_SLL, 32'h00000002, 1'b0,
            "SLL must use only b[4:0] as the shift amount (0xFFFFFFE1 & 0x1F = 1)");
        run(32'h80000000, 32'hFFFFFFE1, OP_SRL, 32'h40000000, 1'b0,
            "SRL must use only b[4:0] as the shift amount (0xFFFFFFE1 & 0x1F = 1)");

        // ---------------- unrecognized control code ----------------
        run(32'hFFFFFFFF, 32'hFFFFFFFF, 4'b1111, 32'h00000000, 1'b0, "unrecognized alu_control must produce result=0");

        // ---------------- randomized directed-operation checks ----------------
        for (i = 0; i < 60; i = i + 1) begin
            ra = {$random}; rb = {$random};

            exp_add = ra + rb;
            exp_ovf = (~(ra[31] ^ rb[31])) & (ra[31] ^ exp_add[31]);
            run(ra, rb, OP_ADD, exp_add, exp_ovf, "random ADD");

            exp_sub = ra - rb;
            exp_ovf = (ra[31] ^ rb[31]) & (ra[31] ^ exp_sub[31]);
            run(ra, rb, OP_SUB, exp_sub, exp_ovf, "random SUB");

            run(ra, rb, OP_AND, ra & rb, 1'b0, "random AND");
            run(ra, rb, OP_OR,  ra | rb, 1'b0, "random OR");
            run(ra, rb, OP_NOR, ~(ra | rb), 1'b0, "random NOR");
        end

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

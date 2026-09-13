`timescale 1ns/1ps

module mux_decoder_alu_tb;

    integer pass_count = 0;
    integer total_count = 0;

    task record(input ok, input [511:0] label);
        begin
            total_count = total_count + 1;
            if (ok) pass_count = pass_count + 1;
            else $display("[FAIL] %0s", label);
        end
    endtask

    // ---------------- mux2to1 (WIDTH=4) ----------------
    reg  [3:0] m2_in0, m2_in1;
    reg        m2_sel;
    wire [3:0] m2_out;
    mux2to1 #(.WIDTH(4)) dut_m2(.in0(m2_in0), .in1(m2_in1), .sel(m2_sel), .out(m2_out));

    // ---------------- mux4to1 (WIDTH=4) ----------------
    reg  [3:0] m4_in0, m4_in1, m4_in2, m4_in3;
    reg  [1:0] m4_sel;
    wire [3:0] m4_out;
    mux4to1 #(.WIDTH(4)) dut_m4(.in0(m4_in0), .in1(m4_in1), .in2(m4_in2), .in3(m4_in3),
                                 .sel(m4_sel), .out(m4_out));

    // ---------------- decoder3to8 ----------------
    reg  [2:0] dec_in;
    reg        dec_en;
    wire [7:0] dec_out;
    decoder3to8 dut_dec(.in(dec_in), .en(dec_en), .out(dec_out));

    // ---------------- mini_alu4 ----------------
    reg  [3:0] alu_a, alu_b;
    reg  [2:0] alu_op;
    wire [3:0] alu_result;
    wire       alu_zero;
    mini_alu4 dut_alu(.a(alu_a), .b(alu_b), .op(alu_op), .result(alu_result), .zero(alu_zero));

    integer i, j, k;
    reg [3:0] expected4;
    reg [7:0] expected_dec;
    reg signed [3:0] sa, sb;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mux_decoder_alu_tb);

        // ---- mux2to1: exhaustive over data + sel ----
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                m2_in0 = i[3:0]; m2_in1 = j[3:0]; m2_sel = 1'b0; #1;
                record(m2_out === m2_in0, "mux2to1: sel=0 should select in0");
                m2_sel = 1'b1; #1;
                record(m2_out === m2_in1, "mux2to1: sel=1 should select in1");
            end
        end

        // ---- mux4to1: exhaustive over sel, directed data ----
        m4_in0 = 4'h1; m4_in1 = 4'h2; m4_in2 = 4'h3; m4_in3 = 4'h4;
        for (i = 0; i < 4; i = i + 1) begin
            m4_sel = i[1:0]; #1;
            case (i)
                0: expected4 = m4_in0;
                1: expected4 = m4_in1;
                2: expected4 = m4_in2;
                3: expected4 = m4_in3;
            endcase
            record(m4_out === expected4, "mux4to1: incorrect selection for one sel value");
        end

        // ---- decoder3to8: exhaustive ----
        for (i = 0; i < 8; i = i + 1) begin
            dec_in = i[2:0];
            dec_en = 1'b1; #1;
            expected_dec = (8'b1 << i);
            record(dec_out === expected_dec, "decoder3to8: wrong one-hot output while enabled");

            dec_en = 1'b0; #1;
            record(dec_out === 8'b0, "decoder3to8: output must be all-zero when en=0");
        end

        // ---- mini_alu4: exhaustive per operation ----
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                alu_a = i[3:0]; alu_b = j[3:0];

                alu_op = 3'b000; #1;
                record(alu_result === (alu_a + alu_b), "mini_alu4 ADD: wrong result");
                record(alu_zero === (alu_result == 4'b0), "mini_alu4 ADD: wrong zero flag");

                alu_op = 3'b001; #1;
                record(alu_result === (alu_a - alu_b), "mini_alu4 SUB: wrong result");
                record(alu_zero === (alu_result == 4'b0), "mini_alu4 SUB: wrong zero flag");

                alu_op = 3'b010; #1;
                record(alu_result === (alu_a & alu_b), "mini_alu4 AND: wrong result");

                alu_op = 3'b011; #1;
                record(alu_result === (alu_a | alu_b), "mini_alu4 OR: wrong result");
            end
        end

        // ---- mini_alu4 SLT: directed signed boundary cases ----
        alu_op = 3'b100;
        for (k = -8; k <= 7; k = k + 1) begin
            sa = k[3:0];
            for (i = -8; i <= 7; i = i + 1) begin
                sb = i[3:0];
                alu_a = sa; alu_b = sb; #1;
                expected4 = (sa < sb) ? 4'b0001 : 4'b0000;
                record(alu_result === expected4, "mini_alu4 SLT: wrong signed comparison");
            end
        end

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

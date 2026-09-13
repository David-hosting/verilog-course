`timescale 1ns/1ps

module adders_tb;

    integer pass_count = 0;
    integer total_count = 0;

    // ---------- full_adder: exhaustive ----------
    reg fa_a, fa_b, fa_cin;
    wire fa_sum, fa_cout;

    full_adder dut_fa(.a(fa_a), .b(fa_b), .cin(fa_cin), .sum(fa_sum), .cout(fa_cout));

    integer i;
    reg exp_sum, exp_cout;

    // ---------- ripple_carry_adder: N=8 ----------
    localparam N = 8;
    reg  [N-1:0] rc_a, rc_b;
    reg          rc_cin;
    wire [N-1:0] rc_sum;
    wire         rc_cout;

    ripple_carry_adder #(.N(N)) dut_rc(.a(rc_a), .b(rc_b), .cin(rc_cin), .sum(rc_sum), .cout(rc_cout));

    integer k;
    integer seed;

    task check_rc(input [N-1:0] a_val, input [N-1:0] b_val, input cin_val, input [767:0] label);
        reg [N:0] exp;
        begin
            rc_a = a_val; rc_b = b_val; rc_cin = cin_val;
            #1;
            exp = {1'b0, a_val} + {1'b0, b_val} + cin_val;
            total_count = total_count + 1;
            if (rc_sum === exp[N-1:0] && rc_cout === exp[N]) begin
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] ripple_carry_adder (%0s): a=%b b=%b cin=%b -> expected sum=%b cout=%b, got sum=%b cout=%b",
                          label, a_val, b_val, cin_val, exp[N-1:0], exp[N], rc_sum, rc_cout);
            end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, adders_tb);

        // --- full adder: all 8 combinations ---
        for (i = 0; i < 8; i = i + 1) begin
            {fa_a, fa_b, fa_cin} = i[2:0];
            #1;
            exp_sum  = fa_a ^ fa_b ^ fa_cin;
            exp_cout = (fa_a & fa_b) | (fa_b & fa_cin) | (fa_a & fa_cin);
            total_count = total_count + 1;
            if (fa_sum === exp_sum && fa_cout === exp_cout) begin
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] full_adder: a=%b b=%b cin=%b -> expected sum=%b cout=%b, got sum=%b cout=%b",
                          fa_a, fa_b, fa_cin, exp_sum, exp_cout, fa_sum, fa_cout);
            end
        end

        // --- ripple carry adder: directed cases ---
        check_rc(8'h00, 8'h00, 1'b0, "zero + zero, cin=0");
        check_rc(8'hFF, 8'h00, 1'b0, "all-ones + zero, cin=0");
        check_rc(8'hFF, 8'h01, 1'b0, "all-ones + 1 (carry ripples across every bit)");
        check_rc(8'hFF, 8'hFF, 1'b1, "all-ones + all-ones + cin=1 (max value)");
        check_rc(8'h0F, 8'hF0, 1'b0, "nibble boundary, no carry");
        check_rc(8'h0F, 8'hF1, 1'b0, "nibble boundary, carry into upper nibble");
        check_rc(8'hAA, 8'h55, 1'b1, "alternating bit patterns, cin=1");

        // --- ripple carry adder: random cases ---
        seed = 42;
        for (k = 0; k < 50; k = k + 1) begin
            check_rc($random(seed), $random(seed), $random(seed) & 1'b1, "random case");
        end

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

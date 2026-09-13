`timescale 1ns/1ps

module dff_reg_tb;

    integer pass_count = 0;
    integer total_count = 0;

    task check(input ok, input [511:0] label);
        begin
            total_count = total_count + 1;
            if (ok) pass_count = pass_count + 1;
            else $display("[FAIL] %0s", label);
        end
    endtask

    // ---------------- clock ----------------
    reg clk = 0;
    always #5 clk = ~clk;

    // ---------------- dff_en_rst ----------------
    reg  d_rst, d_en, d_d;
    wire d_q;
    dff_en_rst dut_dff(.clk(clk), .rst(d_rst), .en(d_en), .d(d_d), .q(d_q));

    // ---------------- reg8 ----------------
    reg        r_rst, r_en;
    reg  [7:0] r_d;
    wire [7:0] r_q;
    reg8 dut_reg8(.clk(clk), .rst(r_rst), .en(r_en), .d(r_d), .q(r_q));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, dff_reg_tb);

        // ================= dff_en_rst =================
        d_rst = 1; d_en = 0; d_d = 1;
        @(posedge clk); #1;
        check(d_q === 1'b0, "dff_en_rst: rst must force q=0");

        d_rst = 0; d_en = 1; d_d = 1;
        @(posedge clk); #1;
        check(d_q === 1'b1, "dff_en_rst: en=1 must capture d");

        d_rst = 0; d_en = 0; d_d = 0; // d changes but en=0: must hold
        @(posedge clk); #1;
        check(d_q === 1'b1, "dff_en_rst: en=0 must hold previous value, ignoring d");

        d_rst = 0; d_en = 1; d_d = 0;
        @(posedge clk); #1;
        check(d_q === 1'b0, "dff_en_rst: en=1 must capture new d=0");

        d_rst = 1; d_en = 1; d_d = 1; // rst must beat en even when both asserted
        @(posedge clk); #1;
        check(d_q === 1'b0, "dff_en_rst: rst must take priority over en");

        // mid-cycle input change must not affect q until the next edge
        d_rst = 0; d_en = 1; d_d = 1;
        @(posedge clk); #1;
        check(d_q === 1'b1, "dff_en_rst: setup for mid-cycle test failed");
        d_d = 0; #1; // change d well before the next edge
        check(d_q === 1'b1, "dff_en_rst: q changed before the clock edge arrived");
        @(posedge clk); #1;
        check(d_q === 1'b0, "dff_en_rst: q did not update on the following edge");

        // ================= reg8 =================
        r_rst = 1; r_en = 0; r_d = 8'hFF;
        @(posedge clk); #1;
        check(r_q === 8'h00, "reg8: rst must force all bits to 0");

        r_rst = 0; r_en = 1; r_d = 8'hA5;
        @(posedge clk); #1;
        check(r_q === 8'hA5, "reg8: en=1 must capture d on every bit");

        r_rst = 0; r_en = 0; r_d = 8'h00; // must hold, ignoring new d
        @(posedge clk); #1;
        check(r_q === 8'hA5, "reg8: en=0 must hold previous value on every bit");

        r_rst = 0; r_en = 1; r_d = 8'h3C;
        @(posedge clk); #1;
        check(r_q === 8'h3C, "reg8: en=1 must capture new d value");

        r_rst = 1; r_en = 1; r_d = 8'hFF; // rst beats en
        @(posedge clk); #1;
        check(r_q === 8'h00, "reg8: rst must take priority over en");

        r_rst = 0; r_en = 1; r_d = 8'h81;
        @(posedge clk); #1;
        check(r_q === 8'h81, "reg8: setup for mid-cycle test failed");
        r_d = 8'h00; #1;
        check(r_q === 8'h81, "reg8: output changed before the clock edge arrived");
        @(posedge clk); #1;
        check(r_q === 8'h00, "reg8: output did not update on the following edge");

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

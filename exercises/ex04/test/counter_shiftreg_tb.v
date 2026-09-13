`timescale 1ns/1ps

module counter_shiftreg_tb;

    integer pass_count = 0;
    integer total_count = 0;

    task check(input ok, input [511:0] label);
        begin
            total_count = total_count + 1;
            if (ok) pass_count = pass_count + 1;
            else $display("[FAIL] %0s", label);
        end
    endtask

    reg clk = 0;
    always #5 clk = ~clk;

    // ---------------- counter ----------------
    reg        c_rst, c_load, c_en, c_up_down;
    reg  [7:0] c_load_val;
    wire [7:0] c_count;
    updown_counter8 dut_cnt(.clk(clk), .rst(c_rst), .load(c_load), .load_val(c_load_val),
                             .en(c_en), .up_down(c_up_down), .count(c_count));

    // ---------------- shift register ----------------
    reg        s_rst, s_en, s_load, s_dir, s_serial_in;
    reg  [7:0] s_load_val;
    wire [7:0] s_q;
    shift_reg8 dut_shift(.clk(clk), .rst(s_rst), .en(s_en), .load(s_load), .load_val(s_load_val),
                          .dir(s_dir), .serial_in(s_serial_in), .q(s_q));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, counter_shiftreg_tb);

        // ================= counter =================
        c_rst = 1; c_load = 0; c_en = 0; c_up_down = 1; c_load_val = 8'hAA;
        @(posedge clk); #1;
        check(c_count === 8'h00, "counter: rst must force count=0");

        c_rst = 0; c_load = 1; c_en = 0; c_load_val = 8'h10;
        @(posedge clk); #1;
        check(c_count === 8'h10, "counter: load must work even when en=0");

        c_load = 0; c_en = 1; c_up_down = 1;
        @(posedge clk); #1;
        check(c_count === 8'h11, "counter: en=1, up_down=1 must increment");
        @(posedge clk); #1;
        check(c_count === 8'h12, "counter: must keep incrementing while enabled");

        c_up_down = 0;
        @(posedge clk); #1;
        check(c_count === 8'h11, "counter: up_down=0 must decrement");

        c_en = 0;
        @(posedge clk); #1;
        check(c_count === 8'h11, "counter: en=0 must hold the current count");

        // wraparound up: FF -> 00
        c_load = 1; c_load_val = 8'hFF; c_en = 0;
        @(posedge clk); #1;
        c_load = 0; c_en = 1; c_up_down = 1;
        @(posedge clk); #1;
        check(c_count === 8'h00, "counter: must wrap FF -> 00 when incrementing");

        // wraparound down: 00 -> FF
        c_up_down = 0;
        @(posedge clk); #1;
        check(c_count === 8'hFF, "counter: must wrap 00 -> FF when decrementing");

        // reset must beat a simultaneous load
        c_rst = 1; c_load = 1; c_load_val = 8'h55; c_en = 0;
        @(posedge clk); #1;
        check(c_count === 8'h00, "counter: rst must take priority over a simultaneous load");

        // ================= shift register =================
        s_rst = 1; s_en = 0; s_load = 0; s_dir = 1; s_serial_in = 1; s_load_val = 8'hFF;
        @(posedge clk); #1;
        check(s_q === 8'h00, "shift_reg8: rst must force q=0");

        s_rst = 0; s_load = 1; s_en = 0; s_load_val = 8'b1001_0110;
        @(posedge clk); #1;
        check(s_q === 8'b1001_0110, "shift_reg8: load must work even when en=0");

        // shift left: new bit enters at LSB
        s_load = 0; s_en = 1; s_dir = 1; s_serial_in = 1;
        @(posedge clk); #1;
        check(s_q === 8'b0010_1101, "shift_reg8: shift-left result incorrect");
        s_serial_in = 0;
        @(posedge clk); #1;
        check(s_q === 8'b0101_1010, "shift_reg8: shift-left result incorrect on 2nd shift");

        // shift right: new bit enters at MSB
        s_dir = 0; s_serial_in = 1;
        @(posedge clk); #1;
        check(s_q === 8'b1010_1101, "shift_reg8: shift-right result incorrect");
        s_serial_in = 0;
        @(posedge clk); #1;
        check(s_q === 8'b0101_0110, "shift_reg8: shift-right result incorrect on 2nd shift");

        // en=0 must hold
        s_en = 0; s_serial_in = 1; s_dir = 1;
        @(posedge clk); #1;
        check(s_q === 8'b0101_0110, "shift_reg8: en=0 must hold the current value");

        // reset must beat a simultaneous load
        s_rst = 1; s_load = 1; s_load_val = 8'hFF; s_en = 0;
        @(posedge clk); #1;
        check(s_q === 8'h00, "shift_reg8: rst must take priority over a simultaneous load");

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

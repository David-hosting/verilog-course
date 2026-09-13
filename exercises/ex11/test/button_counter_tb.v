`timescale 1ns/1ps

module button_counter_tb;

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

    // ---------------- synchronizer ----------------
    reg  s_async_in;
    wire s_sync_out;
    synchronizer dut_sync(.clk(clk), .async_in(s_async_in), .sync_out(s_sync_out));

    // ---------------- debouncer ----------------
    localparam STABLE = 4;
    reg  d_rst, d_noisy_in;
    wire d_clean_out;
    debouncer #(.STABLE_CYCLES(STABLE)) dut_deb(.clk(clk), .rst(d_rst), .noisy_in(d_noisy_in), .clean_out(d_clean_out));

    // ---------------- button_edge_counter ----------------
    reg  b_rst, b_async_button;
    wire [7:0] b_press_count;
    button_edge_counter #(.STABLE_CYCLES(STABLE)) dut_btn(
        .clk(clk), .rst(b_rst), .async_button(b_async_button), .press_count(b_press_count)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, button_counter_tb);

        // ===================== synchronizer =====================
        s_async_in = 0;
        @(posedge clk); #1; // let it settle at 0

        s_async_in = 1; // change well before the next edge (simulating an async change)
        @(posedge clk); #1;
        check(s_sync_out === 1'b0, "synchronizer: sync_out must not react after only 1 clock edge");
        @(posedge clk); #1;
        check(s_sync_out === 1'b1, "synchronizer: sync_out must reflect the input after exactly 2 clock edges");

        // ===================== debouncer: clean sustained transition =====================
        d_rst = 1; d_noisy_in = 0;
        @(posedge clk); #1;
        d_rst = 0;
        check(d_clean_out === 1'b0, "debouncer: must start at 0 after reset");

        d_noisy_in = 1;
        @(posedge clk); #1; // cycle 1 of disagreement
        check(d_clean_out === 1'b0, "debouncer: must not flip before STABLE_CYCLES cycles have passed");
        @(posedge clk); #1; // cycle 2
        check(d_clean_out === 1'b0, "debouncer: must not flip before STABLE_CYCLES cycles have passed");
        @(posedge clk); #1; // cycle 3
        check(d_clean_out === 1'b0, "debouncer: must not flip before STABLE_CYCLES cycles have passed");
        @(posedge clk); #1; // cycle 4 == STABLE_CYCLES
        check(d_clean_out === 1'b1, "debouncer: must flip after exactly STABLE_CYCLES consecutive disagreeing cycles");

        // ===================== debouncer: bouncy input must not flip early =====================
        d_rst = 1; d_noisy_in = 0;
        @(posedge clk); #1;
        d_rst = 0;

        d_noisy_in = 1; @(posedge clk); #1; // disagree count=1
        check(d_clean_out === 1'b0, "debouncer (bounce test): premature flip");
        d_noisy_in = 1; @(posedge clk); #1; // disagree count=2
        check(d_clean_out === 1'b0, "debouncer (bounce test): premature flip");
        d_noisy_in = 0; @(posedge clk); #1; // AGREES with clean_out(0) -- must reset the count
        check(d_clean_out === 1'b0, "debouncer (bounce test): premature flip");
        d_noisy_in = 1; @(posedge clk); #1; // disagree count=1 (reset by the bounce above)
        check(d_clean_out === 1'b0, "debouncer (bounce test): the bounce must have reset the pending count");
        d_noisy_in = 1; @(posedge clk); #1; // disagree count=2
        check(d_clean_out === 1'b0, "debouncer (bounce test): premature flip");
        d_noisy_in = 1; @(posedge clk); #1; // disagree count=3
        check(d_clean_out === 1'b0, "debouncer (bounce test): premature flip");
        d_noisy_in = 1; @(posedge clk); #1; // disagree count=4 == STABLE_CYCLES -> accept
        check(d_clean_out === 1'b1, "debouncer (bounce test): must accept the change once it truly settles");

        // ===================== button_edge_counter: full noisy press/release/press =====================
        b_rst = 1; b_async_button = 0;
        @(posedge clk); #1;
        b_rst = 0;
        check(b_press_count === 8'd0, "button_edge_counter: must start at 0");

        // --- noisy press #1 ---
        b_async_button = 1; @(posedge clk); #1;
        b_async_button = 0; @(posedge clk); #1;
        b_async_button = 1; @(posedge clk); #1;
        b_async_button = 1; @(posedge clk); #1;
        b_async_button = 0; @(posedge clk); #1;
        b_async_button = 1; @(posedge clk); #1;
        // now hold solidly high long enough for sync (2) + debounce (4) + edge-detect (1) to settle
        repeat (10) begin
            b_async_button = 1; @(posedge clk); #1;
        end
        check(b_press_count === 8'd1, "button_edge_counter: exactly one press must be counted after the bounce settles high");

        // --- noisy release ---
        b_async_button = 0; @(posedge clk); #1;
        b_async_button = 1; @(posedge clk); #1;
        b_async_button = 0; @(posedge clk); #1;
        repeat (10) begin
            b_async_button = 0; @(posedge clk); #1;
        end
        check(b_press_count === 8'd1, "button_edge_counter: releasing the button must not itself increment the count");

        // --- noisy press #2 ---
        b_async_button = 1; @(posedge clk); #1;
        b_async_button = 0; @(posedge clk); #1;
        b_async_button = 1; @(posedge clk); #1;
        repeat (10) begin
            b_async_button = 1; @(posedge clk); #1;
        end
        check(b_press_count === 8'd2, "button_edge_counter: a second real press must increment the count to 2");

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

`timescale 1ns/1ps

module traffic_light_fsm_tb;

    localparam GREEN_TIME     = 6;
    localparam MIN_GREEN_TIME = 3;
    localparam YELLOW_TIME    = 2;

    localparam RED = 2'b00, YELLOW = 2'b01, GREEN = 2'b10;

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

    reg        rst, ped_request;
    wire [1:0] ns_light, ew_light;

    traffic_light_fsm #(.GREEN_TIME(GREEN_TIME), .MIN_GREEN_TIME(MIN_GREEN_TIME), .YELLOW_TIME(YELLOW_TIME))
        dut(.clk(clk), .rst(rst), .ped_request(ped_request), .ns_light(ns_light), .ew_light(ew_light));

    task check_lights(input [1:0] exp_ns, input [1:0] exp_ew, input [511:0] label);
        begin
            check(ns_light === exp_ns && ew_light === exp_ew, label);
        end
    endtask

    task do_reset;
        begin
            rst = 1; ped_request = 0;
            @(posedge clk); #1;
            rst = 0;
        end
    endtask

    integer c;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, traffic_light_fsm_tb);

        // ===================== Scenario 1: full undisturbed cycle =====================
        do_reset();
        check_lights(GREEN, RED, "S0 (right after reset): expected NS_GREEN");

        // S1..S5: still NS_GREEN (6 total green samples: S0-S5)
        for (c = 1; c <= 5; c = c + 1) begin
            @(posedge clk); #1;
            check_lights(GREEN, RED, "NS_GREEN phase ended too early (before GREEN_TIME cycles)");
        end

        // S6..S7: NS_YELLOW (2 samples)
        for (c = 0; c < YELLOW_TIME; c = c + 1) begin
            @(posedge clk); #1;
            check_lights(YELLOW, RED, "NS_YELLOW phase: wrong duration or wrong lights");
        end

        // S8..S13: EW_GREEN (6 samples)
        for (c = 0; c < GREEN_TIME; c = c + 1) begin
            @(posedge clk); #1;
            check_lights(RED, GREEN, "EW_GREEN phase: wrong duration or wrong lights");
        end

        // S14..S15: EW_YELLOW (2 samples)
        for (c = 0; c < YELLOW_TIME; c = c + 1) begin
            @(posedge clk); #1;
            check_lights(RED, YELLOW, "EW_YELLOW phase: wrong duration or wrong lights");
        end

        // S16: must wrap back to NS_GREEN
        @(posedge clk); #1;
        check_lights(GREEN, RED, "FSM did not wrap back to NS_GREEN after a full cycle");

        // ===================== Scenario 2: ped_request too early must be ignored =====================
        do_reset();
        ped_request = 1; // asserted at timer=0 (too early, MIN_GREEN_TIME-1 = 2)
        @(posedge clk); #1; // now at timer=1
        ped_request = 0;    // released before reaching the minimum
        check_lights(GREEN, RED, "early ped_request setup check failed");
        for (c = 0; c < 5; c = c + 1) begin // must still take the full GREEN_TIME=6 cycles
            @(posedge clk); #1;
        end
        check_lights(YELLOW, RED, "ped_request asserted before MIN_GREEN_TIME must not shorten the green phase");

        // ===================== Scenario 3: ped_request at the minimum must shorten NS_GREEN =====================
        do_reset();
        @(posedge clk); #1; // timer=1
        @(posedge clk); #1; // timer=2 (== MIN_GREEN_TIME - 1)
        check_lights(GREEN, RED, "shortened-green setup check failed (NS_GREEN)");
        ped_request = 1;
        @(posedge clk); #1; // this edge should see green_done and move to NS_YELLOW
        check_lights(YELLOW, RED, "ped_request at MIN_GREEN_TIME-1 must end NS_GREEN on that cycle");
        ped_request = 0;

        // ===================== Scenario 4: the same rule applies to EW_GREEN =====================
        do_reset();
        for (c = 0; c < GREEN_TIME + YELLOW_TIME; c = c + 1) begin
            @(posedge clk); #1; // fast-forward through NS_GREEN + NS_YELLOW
        end
        check_lights(RED, GREEN, "setup for EW_GREEN shortening test failed");
        @(posedge clk); #1; // timer=1
        @(posedge clk); #1; // timer=2
        ped_request = 1;
        @(posedge clk); #1; // should shorten EW_GREEN too
        check_lights(RED, YELLOW, "ped_request at MIN_GREEN_TIME-1 must also shorten EW_GREEN");
        ped_request = 0;

        // ===================== Scenario 5: reset works mid-sequence =====================
        do_reset();
        for (c = 0; c < 3; c = c + 1) begin
            @(posedge clk); #1;
        end
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        check_lights(GREEN, RED, "reset applied mid-sequence must return to NS_GREEN");

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

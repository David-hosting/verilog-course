`timescale 1ns/1ps

module regfile_tb;

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

    reg         we;
    reg  [4:0]  ra1, ra2, wa;
    reg  [31:0] wd;
    wire [31:0] rd1, rd2;

    regfile32 dut(.clk(clk), .we(we), .ra1(ra1), .ra2(ra2), .wa(wa), .wd(wd), .rd1(rd1), .rd2(rd2));

    integer i;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, regfile_tb);

        we = 0; ra1 = 0; ra2 = 0; wa = 0; wd = 0;

        // ---- $zero reads 0 before anything happens ----
        ra1 = 5'd0; ra2 = 5'd0; #1;
        check(rd1 === 32'b0 && rd2 === 32'b0, "register 0 must read 0 initially");

        // ---- writing to register 0 must be ignored ----
        we = 1; wa = 5'd0; wd = 32'hDEADBEEF;
        @(posedge clk); #1;
        we = 0;
        ra1 = 5'd0; #1;
        check(rd1 === 32'b0, "register 0 must still read 0 after attempting to write it");

        // ---- basic write then read back on a later cycle ----
        we = 1; wa = 5'd7; wd = 32'hCAFEF00D;
        @(posedge clk); #1;
        we = 0;
        ra1 = 5'd7; #1;
        check(rd1 === 32'hCAFEF00D, "reading back a value written to register 7 failed");

        // ---- simultaneous dual read of two different registers ----
        we = 1; wa = 5'd12; wd = 32'h12345678;
        @(posedge clk); #1;
        we = 0;
        ra1 = 5'd7; ra2 = 5'd12; #1;
        check(rd1 === 32'hCAFEF00D && rd2 === 32'h12345678,
              "dual-port read of two different registers returned a wrong value");

        // ---- both read ports pointing at the same nonzero register ----
        ra1 = 5'd12; ra2 = 5'd12; #1;
        check(rd1 === 32'h12345678 && rd2 === 32'h12345678,
              "both read ports on the same register must return the same value");

        // ---- read-during-write: must see the OLD value this cycle ----
        ra1 = 5'd7; // currently holds CAFEF00D
        we = 1; wa = 5'd7; wd = 32'h00000001;
        #1; // before the clock edge, still combinational old value
        check(rd1 === 32'hCAFEF00D, "read-during-write must return the old value before the clock edge");
        @(posedge clk); #1;
        we = 0;
        check(rd1 === 32'h00000001, "the new value must be visible starting the cycle after the write");

        // ---- several writes to several registers, then read all back ----
        for (i = 1; i < 8; i = i + 1) begin
            we = 1; wa = i[4:0]; wd = i * 32'h01010101;
            @(posedge clk); #1;
        end
        we = 0;
        for (i = 1; i < 8; i = i + 1) begin
            ra1 = i[4:0]; #1;
            check(rd1 === i * 32'h01010101, "cross-contamination detected after several sequential writes");
        end

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule

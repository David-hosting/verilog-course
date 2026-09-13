// Exercise 3: D flip-flop with sync reset/enable, and an 8-bit register.

module dff_en_rst(
    input      clk,
    input      rst,
    input      en,
    input      d,
    output reg q
);

    // TODO: always @(posedge clk) block, using <= (nonblocking).
    // Priority: rst (-> q <= 0) beats en (-> q <= d) beats hold (no change).

endmodule


module reg8(
    input        clk,
    input        rst,
    input        en,
    input  [7:0] d,
    output [7:0] q
);

    // TODO: instantiate 8 copies of dff_en_rst, one per bit, e.g.:
    // genvar i;
    // generate
    //     for (i = 0; i < 8; i = i + 1) begin : bits
    //         dff_en_rst ff(.clk(clk), .rst(rst), .en(en), .d(d[i]), .q(q[i]));
    //     end
    // endgenerate

endmodule

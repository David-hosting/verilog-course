// Exercise 3: D flip-flop with sync reset/enable, and an 8-bit register.

module dff_en_rst(
    input      clk,
    input      rst,
    input      en,
    input      d,
    output reg q
);

    // TODO: one always @(posedge clk) block, using nonblocking assignment.
    // Three things can each want to change q on the same edge -- rst, en,
    // and "neither" (hold). Only one outcome can win per edge; the README
    // spells out which one takes priority over which.

endmodule


module reg8(
    input        clk,
    input        rst,
    input        en,
    input  [7:0] d,
    output [7:0] q
);

    // TODO: this register is 8 independent copies of dff_en_rst, one per
    // bit, all sharing the same clk/rst/en. You already have a pattern for
    // "stamp out N identical instances without writing them out by hand"
    // from Lecture 2's ripple_carry_adder -- the same construct applies
    // here. 

endmodule

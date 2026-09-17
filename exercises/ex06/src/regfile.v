// Exercise 6: MIPS-style 32x32 register file.

module regfile32(
    input         clk,
    input         we,
    input  [4:0]  ra1,
    input  [4:0]  ra2,
    input  [4:0]  wa,
    input  [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2
);

    // TODO: you need storage for 32 words of 32 bits each. Lecture 7
    // covers exactly this: an array of registers is declared like a
    // vector, but with a second range for the number of entries.
    //
    // TODO: the write side is synchronous (posedge clk), gated by `we`.
    // Register 0 has to permanently read as zero -- decide whether you
    // enforce that on the write side (refuse to ever store into address 0)
    // or the read side (override the read value when the address is 0).
    // Either is a valid way to satisfy the spec; you don't need both.
    //
    // TODO: the read side is combinational, not clocked -- two independent
    // read ports, each just selecting one stored word by address.

endmodule

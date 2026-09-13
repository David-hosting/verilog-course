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

    // TODO: reg [31:0] regs [0:31];

    // TODO: always @(posedge clk) block: if (we && wa != 0) regs[wa] <= wd;
    // (guarding wa!=0 here is the simplest way to make register 0 permanently
    // read as zero -- it just never gets written).

    // TODO: assign rd1 = (ra1 == 5'b0) ? 32'b0 : regs[ra1];
    // TODO: assign rd2 = (ra2 == 5'b0) ? 32'b0 : regs[ra2];

endmodule

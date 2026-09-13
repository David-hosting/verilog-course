// Exercise 7: 32-bit MIPS ALU with zero and overflow flags.

module alu32(
    input      [31:0] a,
    input      [31:0] b,
    input      [3:0]  alu_control,
    output reg [31:0] result,
    output             zero,
    output reg         overflow
);

    // TODO: always @(*) block computing 'result' from a case on alu_control.
    // See the operation table in README.md. Default: result = 32'b0.
    // Use $signed(a) < $signed(b) for SLT.
    // Use a << b[4:0] / a >> b[4:0] for SLL/SRL.

    // TODO: always @(*) block computing 'overflow'.
    // Only ADD (4'b0010) and SUB (4'b0110) can set it; every other
    // alu_control value must produce overflow = 0. Use the two's
    // complement formulas from the README/lecture note.

    assign zero = (result == 32'b0);

endmodule

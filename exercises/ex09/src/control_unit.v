// Exercise 9: two-level MIPS control unit (main decoder + ALU decoder).

module main_decoder(
    input      [5:0] opcode,
    output           reg_dst,
    output           branch,
    output           mem_read,
    output           mem_to_reg,
    output           mem_write,
    output           alu_src,
    output           reg_write,
    output reg [1:0] alu_op
);

    // TODO: this module needs to drive 7 single-bit outputs plus alu_op.
    // A clean way: make ALL of them `reg` outputs assigned in one
    // always @(*) block with a case on opcode (change the port
    // declarations above to `output reg` as needed), following the
    // truth table in README.md. Remember a default case.

endmodule


module alu_decoder(
    input      [1:0] alu_op,
    input      [5:0] funct,
    output reg [3:0] alu_control
);

    // TODO: always @(*) block. alu_op==00 -> ADD, alu_op==01 -> SUB,
    // alu_op==10 -> look at funct (see README.md table). Default: ADD.

endmodule


module control_unit(
    input  [5:0] opcode,
    input  [5:0] funct,
    output       reg_dst,
    output       branch,
    output       mem_read,
    output       mem_to_reg,
    output       mem_write,
    output       alu_src,
    output       reg_write,
    output [3:0] alu_control
);

    // TODO: wire [1:0] alu_op;
    // TODO: instantiate main_decoder and alu_decoder, connecting alu_op
    // between them and passing every other port straight through.

endmodule

// Exercise 12 (capstone): wire the datapath and control unit together.

module mips_cpu(
    input         clk,
    input         rst,
    output [31:0] pc_out
);

    // TODO: declare wires for opcode, funct, and every control signal
    // (reg_dst, branch, mem_read, mem_to_reg, alu_control, mem_write,
    // alu_src, reg_write).

    // TODO: instantiate mips_datapath (required instance name: dp),
    // connecting its opcode/funct outputs to the wires above, and its
    // control inputs to the control signal wires above. pc_out connects
    // straight through. zero_flag is used internally by the datapath --
    // you can leave that port unconnected (.zero_flag()).

    // TODO: instantiate control_unit (required instance name: cu),
    // connecting opcode/funct as inputs and every control signal as
    // outputs -- the same wires the datapath instance uses.

endmodule

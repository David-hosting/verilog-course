// Exercise 10: 2-stage pipeline (Decode / Execute+Writeback) with a
// hazard-detection stall (no forwarding).

module pipelined_exec(
    input         clk,
    input         rst,

    input  [4:0]  d_ra1,
    input  [4:0]  d_ra2,
    input  [4:0]  d_wa,
    input  [3:0]  d_alu_control,
    input         d_reg_write,

    output        stall,

    output [4:0]  e_wa,
    output [31:0] e_result,
    output        e_reg_write
);

    // ---- pipeline register (Decode -> Execute) ----
    reg [31:0] id_ex_a, id_ex_b;
    reg [4:0]  id_ex_wa;
    reg [3:0]  id_ex_alu_control;
    reg        id_ex_reg_write;

    // TODO: `stall` is combinational -- true exactly when the instruction
    // currently latched in the pipeline register is going to write a real
    // (nonzero) register, and the instruction now at Decode wants to read
    // that same register on either source port. Get this condition from
    // the pipeline-register signals above and the module's d_ra1/d_ra2
    // inputs -- see the lecture note for why the "nonzero" part matters.

    wire [31:0] rd1, rd2;

    regfile32 rf(
        .clk(clk), .we(e_reg_write),
        .ra1(d_ra1), .ra2(d_ra2), .wa(e_wa), .wd(e_result),
        .rd1(rd1), .rd2(rd2)
    );

    // TODO: replace this placeholder with the real pipeline register logic.
    // On reset, and on a stall, the instruction moving into the Execute
    // stage should be a bubble -- meaning downstream logic must not treat
    // it as a real write (one field controls that). Otherwise, the
    // instruction currently at Decode moves forward: its just-read
    // register values and the rest of its control info get latched for
    // use next cycle. Think about why a stall can't just "do nothing" for
    // a cycle -- what would still be sitting in this register otherwise?
    always @(posedge clk) begin
        id_ex_reg_write <= 1'b0;
    end

    alu32 alu(
        .a(id_ex_a), .b(id_ex_b), .alu_control(id_ex_alu_control),
        .result(e_result), .zero(), .overflow()
    );

    assign e_wa = id_ex_wa;
    assign e_reg_write = id_ex_reg_write;

endmodule

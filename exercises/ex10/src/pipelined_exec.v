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

    // TODO: assign stall = id_ex_reg_write && (id_ex_wa != 5'b0) &&
    //                      ((id_ex_wa == d_ra1) || (id_ex_wa == d_ra2));

    wire [31:0] rd1, rd2;

    regfile32 rf(
        .clk(clk), .we(e_reg_write),
        .ra1(d_ra1), .ra2(d_ra2), .wa(e_wa), .wd(e_result),
        .rd1(rd1), .rd2(rd2)
    );

    // TODO: replace this placeholder with the real pipeline register logic:
    //   if (rst): id_ex_reg_write <= 1'b0  (bubble)
    //   else if (stall): id_ex_reg_write <= 1'b0  (bubble -- discard the
    //     stale read that just happened at Decode this cycle)
    //   else: latch rd1 -> id_ex_a, rd2 -> id_ex_b, d_wa -> id_ex_wa,
    //     d_alu_control -> id_ex_alu_control, d_reg_write -> id_ex_reg_write
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

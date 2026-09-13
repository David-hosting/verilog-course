// Exercise 8: single-cycle MIPS datapath.
// Control signals are direct inputs here (Lecture 10 builds the circuit
// that generates them for real). Wire the provided regfile32/alu32/
// instr_mem/data_mem together, plus the PC logic, sign extension, and
// the four muxes described in the lecture note.
//
// Required instance names (the testbench inspects these directly):
//   regfile32  instance named  rf
//   alu32      instance named  alu
//   instr_mem  instance named  imem
//   data_mem   instance named  dmem

module mips_datapath(
    input         clk,
    input         rst,          // sync reset: PC <- 0

    // control signals (see lecture 9 / provided by the testbench here)
    input         reg_dst,      // 1: write register = rd, 0: write register = rt
    input         branch,       // 1 if this is a branch-type instruction (beq)
    input         mem_read,     // 1 if this is lw (informational; read is always combinational)
    input         mem_to_reg,   // 1: write-back data = memory read data, 0: = ALU result
    input  [3:0]  alu_control,  // fed straight into the ALU
    input         mem_write,    // 1 if this is sw
    input         alu_src,      // 1: ALU operand 2 = sign-extended immediate, 0: = register rt data
    input         reg_write,    // 1: this instruction writes the register file

    // observability outputs (used by the testbench / later exercises)
    output [31:0] pc_out,
    output [5:0]  opcode,
    output [5:0]  funct,
    output        zero_flag
);

    // ---- PC register ----
    reg [31:0] pc;
    assign pc_out = pc;

    // TODO: wire [31:0] pc_plus4 = pc + 32'd4;

    // ---- instruction fetch ----
    wire [31:0] instr;
    instr_mem imem(.addr(pc), .instr(instr));

    // ---- instruction field extraction (bit-slicing only, given to you) ----
    assign opcode        = instr[31:26];
    wire [4:0] rs         = instr[25:21];
    wire [4:0] rt         = instr[20:16];
    wire [4:0] rd         = instr[15:11];
    wire [15:0] imm16     = instr[15:0];
    assign funct          = instr[5:0];

    // TODO: wire [31:0] sign_ext_imm = {{16{imm16[15]}}, imm16};

    // ---- register file ----
    wire [31:0] read_data1, read_data2;
    wire [4:0]  write_reg;   // TODO: reg_dst ? rd : rt
    wire [31:0] write_back_data; // TODO: mem_to_reg ? mem_read_data : alu_result

    regfile32 rf(
        .clk(clk), .we(reg_write),
        .ra1(rs), .ra2(rt), .wa(write_reg), .wd(write_back_data),
        .rd1(read_data1), .rd2(read_data2)
    );

    // ---- ALU ----
    wire [31:0] alu_operand2; // TODO: alu_src ? sign_ext_imm : read_data2
    wire [31:0] alu_result;
    wire        alu_overflow_unused;

    alu32 alu(
        .a(read_data1), .b(alu_operand2), .alu_control(alu_control),
        .result(alu_result), .zero(zero_flag), .overflow(alu_overflow_unused)
    );

    // ---- data memory ----
    wire [31:0] mem_read_data;
    data_mem dmem(
        .clk(clk), .mem_write(mem_write),
        .addr(alu_result), .write_data(read_data2),
        .read_data(mem_read_data)
    );

    // ---- next-PC logic ----
    // TODO: wire [31:0] branch_target = pc_plus4 + (sign_ext_imm << 2);
    // TODO: wire branch_taken = branch & zero_flag;
    // TODO: wire [31:0] next_pc = branch_taken ? branch_target : pc_plus4;

    always @(posedge clk) begin
        if (rst)
            pc <= 32'b0;
        else
            pc <= 32'b0; // TODO: replace with next_pc
    end

endmodule

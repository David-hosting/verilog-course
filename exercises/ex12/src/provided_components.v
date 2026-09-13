// PROVIDED reference components -- do not edit.
// Fully working copies of the register file, ALU, instruction/data memory,
// full single-cycle datapath, and control unit from Exercises 6-9. Your
// only job in this exercise is the top-level wiring in mips_cpu.v.

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
    reg [31:0] regs [0:31];

    always @(posedge clk) begin
        if (we && wa != 5'b0)
            regs[wa] <= wd;
    end

    assign rd1 = (ra1 == 5'b0) ? 32'b0 : regs[ra1];
    assign rd2 = (ra2 == 5'b0) ? 32'b0 : regs[ra2];
endmodule


module alu32(
    input      [31:0] a,
    input      [31:0] b,
    input      [3:0]  alu_control,
    output reg [31:0] result,
    output             zero,
    output reg         overflow
);
    always @(*) begin
        case (alu_control)
            4'b0000: result = a & b;
            4'b0001: result = a | b;
            4'b0010: result = a + b;
            4'b0110: result = a - b;
            4'b0111: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'b1100: result = ~(a | b);
            4'b0100: result = a << b[4:0];
            4'b0101: result = a >> b[4:0];
            default: result = 32'b0;
        endcase
    end

    always @(*) begin
        case (alu_control)
            4'b0010: overflow = (~(a[31] ^ b[31])) & (a[31] ^ result[31]);
            4'b0110: overflow = (a[31] ^ b[31]) & (a[31] ^ result[31]);
            default: overflow = 1'b0;
        endcase
    end

    assign zero = (result == 32'b0);
endmodule


module instr_mem(
    input  [31:0] addr,
    output [31:0] instr
);
    reg [31:0] mem [0:63];
    assign instr = mem[addr[7:2]];
endmodule


module data_mem(
    input         clk,
    input         mem_write,
    input  [31:0] addr,
    input  [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:63];

    always @(posedge clk) begin
        if (mem_write)
            mem[addr[7:2]] <= write_data;
    end

    assign read_data = mem[addr[7:2]];
endmodule


module mips_datapath(
    input         clk,
    input         rst,
    input         reg_dst,
    input         branch,
    input         mem_read,
    input         mem_to_reg,
    input  [3:0]  alu_control,
    input         mem_write,
    input         alu_src,
    input         reg_write,
    output [31:0] pc_out,
    output [5:0]  opcode,
    output [5:0]  funct,
    output        zero_flag
);
    reg [31:0] pc;
    assign pc_out = pc;

    wire [31:0] pc_plus4 = pc + 32'd4;

    wire [31:0] instr;
    instr_mem imem(.addr(pc), .instr(instr));

    assign opcode = instr[31:26];
    wire [4:0] rs = instr[25:21];
    wire [4:0] rt = instr[20:16];
    wire [4:0] rd = instr[15:11];
    wire [15:0] imm16 = instr[15:0];
    assign funct = instr[5:0];

    wire [31:0] sign_ext_imm = {{16{imm16[15]}}, imm16};

    wire [31:0] read_data1, read_data2;
    wire [4:0]  write_reg = reg_dst ? rd : rt;
    wire [31:0] write_back_data = mem_to_reg ? mem_read_data : alu_result;

    regfile32 rf(
        .clk(clk), .we(reg_write),
        .ra1(rs), .ra2(rt), .wa(write_reg), .wd(write_back_data),
        .rd1(read_data1), .rd2(read_data2)
    );

    wire [31:0] alu_operand2 = alu_src ? sign_ext_imm : read_data2;
    wire [31:0] alu_result;
    wire        alu_overflow_unused;

    alu32 alu(
        .a(read_data1), .b(alu_operand2), .alu_control(alu_control),
        .result(alu_result), .zero(zero_flag), .overflow(alu_overflow_unused)
    );

    wire [31:0] mem_read_data;
    data_mem dmem(
        .clk(clk), .mem_write(mem_write),
        .addr(alu_result), .write_data(read_data2),
        .read_data(mem_read_data)
    );

    wire [31:0] branch_target = pc_plus4 + (sign_ext_imm << 2);
    wire        branch_taken = branch & zero_flag;
    wire [31:0] next_pc = branch_taken ? branch_target : pc_plus4;

    always @(posedge clk) begin
        if (rst)
            pc <= 32'b0;
        else
            pc <= next_pc;
    end

endmodule


module main_decoder(
    input      [5:0] opcode,
    output reg       reg_dst,
    output reg       branch,
    output reg       mem_read,
    output reg       mem_to_reg,
    output reg       mem_write,
    output reg       alu_src,
    output reg       reg_write,
    output reg [1:0] alu_op
);
    always @(*) begin
        reg_dst = 0; branch = 0; mem_read = 0; mem_to_reg = 0;
        mem_write = 0; alu_src = 0; reg_write = 0; alu_op = 2'b00;
        case (opcode)
            6'b000000: begin // R-type
                reg_dst = 1; reg_write = 1; alu_op = 2'b10;
            end
            6'b100011: begin // lw
                alu_src = 1; mem_to_reg = 1; reg_write = 1; mem_read = 1; alu_op = 2'b00;
            end
            6'b101011: begin // sw
                alu_src = 1; mem_write = 1; alu_op = 2'b00;
            end
            6'b000100: begin // beq
                branch = 1; alu_op = 2'b01;
            end
            6'b001000: begin // addi
                alu_src = 1; reg_write = 1; alu_op = 2'b00;
            end
            default: begin
                // all-safe defaults already assigned above
            end
        endcase
    end
endmodule


module alu_decoder(
    input      [1:0] alu_op,
    input      [5:0] funct,
    output reg [3:0] alu_control
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 4'b0010; // ADD
            2'b01: alu_control = 4'b0110; // SUB
            2'b10: begin
                case (funct)
                    6'b100000: alu_control = 4'b0010; // add
                    6'b100010: alu_control = 4'b0110; // sub
                    6'b100100: alu_control = 4'b0000; // and
                    6'b100101: alu_control = 4'b0001; // or
                    6'b101010: alu_control = 4'b0111; // slt
                    6'b000000: alu_control = 4'b0100; // sll
                    6'b000010: alu_control = 4'b0101; // srl
                    default:   alu_control = 4'b0000; // and (safe default)
                endcase
            end
            default: alu_control = 4'b0010;
        endcase
    end
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
    wire [1:0] alu_op;

    main_decoder md(.opcode(opcode), .reg_dst(reg_dst), .branch(branch), .mem_read(mem_read),
                     .mem_to_reg(mem_to_reg), .mem_write(mem_write), .alu_src(alu_src),
                     .reg_write(reg_write), .alu_op(alu_op));

    alu_decoder ad(.alu_op(alu_op), .funct(funct), .alu_control(alu_control));
endmodule

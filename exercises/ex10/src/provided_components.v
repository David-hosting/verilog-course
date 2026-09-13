// PROVIDED reference components -- do not edit.

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

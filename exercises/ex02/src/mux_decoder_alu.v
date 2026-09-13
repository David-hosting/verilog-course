// Exercise 2: muxes, a decoder, and a 4-bit mini-ALU.

module mux2to1 #(parameter WIDTH = 1) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input               sel,
    output [WIDTH-1:0] out
);

    // TODO: out = sel ? in1 : in0

endmodule


module mux4to1 #(parameter WIDTH = 1) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    input  [WIDTH-1:0] in3,
    input  [1:0]        sel,
    output [WIDTH-1:0] out
);

    // TODO: build this structurally out of THREE mux2to1 instances.
    // wire [WIDTH-1:0] low_pick, high_pick;
    // mux2to1 #(.WIDTH(WIDTH)) m0(.in0(in0), .in1(in1), .sel(sel[0]), .out(low_pick));
    // mux2to1 #(.WIDTH(WIDTH)) m1(.in0(in2), .in1(in3), .sel(sel[0]), .out(high_pick));
    // mux2to1 #(.WIDTH(WIDTH)) m2(.in0(low_pick), .in1(high_pick), .sel(sel[1]), .out(out));

endmodule


module decoder3to8(
    input  [2:0] in,
    input        en,
    output reg [7:0] out
);

    // TODO: always @(*) block. Assign out = 8'b0 first (avoid a latch!),
    // then if (en) set exactly the bit indexed by 'in'.

endmodule


module mini_alu4(
    input  [3:0] a,
    input  [3:0] b,
    input  [2:0] op,
    output reg [3:0] result,
    output           zero
);

    // TODO: always @(*) block with a case statement on op.
    // op values: 000=ADD 001=SUB 010=AND 011=OR 100=SLT(signed), others=0.
    // Remember to assign a default value to 'result' before the case,
    // so every path is covered and no latch is inferred.

    assign zero = (result == 4'b0);

endmodule

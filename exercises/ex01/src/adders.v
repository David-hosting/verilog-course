// Exercise 1: Gate-level adders.
// Implement both modules using ONLY structural gate primitives
// (and/or/xor/not/nand/nor/xnor instances). No assign, no +, no ^ etc.

module full_adder(
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);

    // TODO: implement using gate primitives, e.g.:
    //   xor g1(some_wire, a, b);
    //   and g2(other_wire, a, b);
    // Remember: gate instantiation syntax is
    //   gate_type instance_name(output, input1, input2, ...);

    wire abXor, abCarry, cinCarry;
    xor partialSum(abXor, a, b);
    xor _sum(sum, abXor, cin);

    and c1(abCarry, a, b);
    and c2(cinCarry, abXor, cin);

    or carryOut(cout, abCarry, cinCarry);

endmodule


module ripple_carry_adder #(
    parameter N = 8
)(
    input  [N-1:0] a,
    input  [N-1:0] b,
    input          cin,
    output [N-1:0] sum,
    output         cout
);

    // TODO: declare an internal carry-chain wire wide enough for N+1 carries,
    // wire carry[0] = cin, then use a generate/genvar for-loop to instantiate
    // N copies of full_adder, chaining carry[i] -> carry[i+1].
    // Finally assign cout = carry[N] (a plain 'assign' for wiring an output
    // to an internal wire is fine -- the "gates only" rule is about the
    // logic itself, not about connecting ports).

    wire [N:0] carry;

    genvar i;
    
    assign carry[0] = cin;

    generate
        for (i = 0; i < N; i = i + 1) begin : adder_chain
            full_adder FA(
                .a(a[i]), .b(b[i]), .cin(carry[i]),
                .sum(sum[i]), .cout(carry[i+1])
            );
        end
    endgenerate

    assign cout = carry[N];

endmodule

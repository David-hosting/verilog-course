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

endmodule

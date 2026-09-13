# Lecture 3 — Muxes, Decoders & Behavioral Combinational Logic

## Concept: the multiplexer

A multiplexer (mux) selects one of several inputs based on a select signal.
It is, arguably, the single most-used building block in a CPU — every place
where a signal needs to come from "here, or there, depending on what
instruction this is" is a mux.

Behavioral style, using a ternary operator:

```verilog
module mux2to1 #(parameter WIDTH = 1) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input               sel,
    output [WIDTH-1:0] out
);
    assign out = sel ? in1 : in0;
endmodule
```

You can also build a wider mux *structurally*, out of smaller muxes — a
4-to-1 mux is just a tree of three 2-to-1 muxes: two of them narrow four
inputs down to two using `sel[0]`, and a third picks between those two
using `sel[1]`. This is the same idea as Lecture 2's adder chain: compose a
bigger structure out of instances of a smaller, already-verified one.

## Concept: the decoder

A decoder turns a binary code into a one-hot output — exactly one output bit
is set, indicating which input code was seen. A 3-to-8 decoder has a 3-bit
input and 8 outputs, of which output `n` is 1 exactly when the input equals
`n` (and only if an `enable` is asserted; if not enabled, every output is 0).

```verilog
module decoder3to8(input [2:0] in, input en, output reg [7:0] out);
    always @(*) begin
        out = 8'b0;
        if (en)
            out[in] = 1'b1;
    end
endmodule
```

## `always @(*)`: the behavioral combinational block

This is your workhorse for combinational logic going forward. Two rules
that matter enormously:

1. **List every signal you read on the right-hand side, or use `@(*)`** —
   `@(*)` auto-senses everything read inside the block, so use it always;
   don't hand-write sensitivity lists (`always @(a or b)`) — it's easy to
   forget a signal and get simulation/hardware mismatches.
2. **Assign every output on every possible path through the block**, or you
   accidentally infer a **latch**. If an `if` doesn't have a matching
   `else`, and the output isn't given a default value first, the synthesis
   tool has to insert memory to "remember" the old value when the condition
   is false — even though you never intended any memory at all. This is one
   of the most common real bugs in RTL design. The safe pattern:

```verilog
always @(*) begin
    result = 4'b0;       // default value first
    case (op)
        3'b000: result = a + b;
        3'b001: result = a - b;
        // ...
    endcase
end
```

With a default assigned up front, even an incomplete `case` can't infer a
latch — every path now assigns something.

## Where this fits in MIPS / architecture

A real ALU (Lecture 8) is fundamentally "compute several candidate results
in parallel, then mux the right one out based on an opcode" — exactly what
you're about to build at 4-bit scale. The register file's read ports
(Lecture 7) are muxes selecting one of 32 registers. The datapath (Lecture 9)
is *full of* muxes selecting between "the next PC" vs. "PC+4", or "ALU
result" vs. "memory data" as the value written back to a register — this is
precisely why P&H's datapath diagrams are covered in mux symbols.

## Electronics/VLSI note

A `case` statement inside `always @(*)` doesn't necessarily become a giant
if/else chain in silicon — for a small number of options, synthesis tools
often prefer a **mux tree** exactly like the structural one you're about to
build (a chain of 2:1 muxes is cheap and fast in CMOS: each stage is a
transmission-gate or two-inverter mux cell). Understanding the "many
candidates computed, then muxed" shape of your behavioral code helps you
predict roughly what hardware it becomes, even without knowing the exact
target library.

## Exercise

→ [`exercises/ex02`](../exercises/ex02) — build `mux2to1`, a structural
`mux4to1`, `decoder3to8`, and a 4-bit mini-ALU.

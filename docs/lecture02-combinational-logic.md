# Lecture 2 — Combinational Logic & Structural Modeling

## Concept

Combinational logic: outputs are a pure function of current inputs, with no
memory. In Verilog, the two primitive gate keywords you'll use structurally
are things like `and`, `or`, `xor`, `not`, `nand`, `nor`, `xnor`. Each
instantiates a gate:

```verilog
xor g1(y, a, b);   // y = a ^ b, gate named g1
```

The syntax is always `gate_type instance_name(output, input1, input2, ...);`
— **output first**, unlike a function call. This trips people up constantly;
get in the habit of checking port order against a gate's documentation.

## Building a half adder and full adder

A half adder adds two 1-bit numbers: `sum = a ^ b`, `carry = a & b`. That's
it — two gates, wired up exactly the way Lecture 1's `and_or` example
wired an intermediate signal between gates:

```verilog
module half_adder(input a, input b, output sum, output carry);
    xor g1(sum, a, b);
    and g2(carry, a, b);
endmodule
```

A full adder adds three 1-bit numbers (two operands plus a carry-in), which
is what you actually need to chain adders together. It's built from **two**
half adders plus one more gate combining their two carry conditions — the
same decomposition you'd see in a transistor-level schematic. Working out
exactly which gates and which intermediate wires that takes is this
lecture's exercise.

## Chaining adders: ripple-carry

To add two N-bit numbers, you'd chain N full adders, feeding each one's
carry-out into the next one's carry-in — but wiring up N instances by hand
for an arbitrary N isn't practical. Verilog's `generate`/`genvar` construct
solves exactly this: it's a `for` loop that runs *at elaboration time*, not
in simulation, stamping out a fixed number of instances before simulation
even starts. Here's the same idea applied to a different, smaller circuit —
a chain of `N` XOR gates computing the running parity of an `N`-bit bus,
each stage combining the previous stage's running result with one more
input bit:

```verilog
wire [N:0] parity_chain;
assign parity_chain[0] = 1'b0;

genvar i;
generate
    for (i = 0; i < N; i = i + 1) begin : parity_stage
        xor g(parity_chain[i+1], parity_chain[i], data[i]);
    end
endgenerate

assign parity_bit = parity_chain[N];
```

Notice the shape: a wire *array* one element wider than the instance count
(`parity_chain[0]` seeded directly, `parity_chain[N]` read out as the
result), and each generated instance reading one array element and writing
the next. A ripple-carry adder needs the identical shape — an array of
carries, one full adder per bit, each reading `carry[i]` and producing
`carry[i+1]` — just with `full_adder` in place of `xor` and two more
per-bit inputs feeding in alongside the chain.

This construct is fundamentally different from a software for-loop: there
is no "loop" left in the final hardware, just `N` physical gate instances
wired in series, all existing and active simultaneously.

This structure is called a **ripple-carry adder** because the carry signal
has to physically propagate (ripple) through all N full adders before the
final sum is valid — bit 31's sum isn't correct until the carry has rippled
all the way from bit 0. That's `N` full-adder delays on the critical path,
which is why real ALUs use faster (and more complex) carry structures like
carry-lookahead or carry-select adders — we'll revisit this tradeoff
directly in Lecture 8 when you build a real 32-bit ALU.

## Where this fits in MIPS / architecture

Every `add`, `addi`, `sub`, and address calculation (`lw`/`sw` effective
address, branch target) a MIPS CPU executes runs through an adder in the
ALU. The full-adder-chain structure here is the literal building block of
that ALU's arithmetic path.

## Electronics/VLSI note

Each gate above (`xor`, `and`, `or`) corresponds to one cell from a
standard-cell library in real silicon — the synthesis tool doesn't invent
transistor networks per design, it picks pre-characterized, pre-verified
cells (each with a known delay/area/power for a given process) and wires
them together exactly like the `generate` loop above wires together
`full_adder` instances. A ripple-carry adder's `N`-full-adder critical path
is a direct, physical consequence of the carry signal needing `N` sequential
gate delays to settle — this is the same phenomenon as fan-in/fan-out delay
chains you'd analyze in a static timing analysis (STA) report for a real
chip.

## Exercise

→ [`exercises/ex01`](../exercises/ex01) — build a structural full adder and
a parameterized N-bit ripple-carry adder from it.

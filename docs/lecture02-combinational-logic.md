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
it — two gates.

A full adder adds three 1-bit numbers (two operands plus a carry-in), which
is what you actually need to chain adders together:

```verilog
module full_adder(input a, input b, input cin, output sum, output cout);
    wire s1, c1, c2;
    xor g1(s1, a, b);
    xor g2(sum, s1, cin);
    and g3(c1, a, b);
    and g4(c2, s1, cin);
    or  g5(cout, c1, c2);
endmodule
```

Notice this is literally two half adders plus an OR gate combining the two
carry conditions — the standard way a full adder is built from smaller
pieces, and the same decomposition you'd see in a transistor-level schematic.

## Chaining adders: ripple-carry

To add two N-bit numbers, chain N full adders, feeding each one's `cout`
into the next one's `cin`:

```verilog
genvar i;
generate
    for (i = 0; i < N; i = i + 1) begin : adder_chain
        full_adder fa(.a(a[i]), .b(b[i]), .cin(carry[i]),
                       .sum(sum[i]), .cout(carry[i+1]));
    end
endgenerate
```

`generate`/`genvar` is Verilog's way of writing a `for` loop *at
elaboration time* — it doesn't run in simulation, it stamps out N copies of
`full_adder` before simulation even starts. This is fundamentally different
from a software for-loop; there is no "loop" in the final hardware, just N
physical adder circuits wired in series.

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

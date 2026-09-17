# Lecture 13 — Capstone: Integrating a Single-Cycle MIPS CPU

## Concept: there is no new logic left to write

Every piece exists and has already been individually tested: the register
file (Lecture 7), the ALU (Lecture 8), the datapath (Lecture 9), and the
control unit (Lecture 10). This lecture's exercise is pure **integration**
— instantiate the datapath and the control unit, and connect the
datapath's decoded-instruction outputs into the control unit's inputs, and
the control unit's control-signal outputs into the datapath's control
inputs. In the abstract, wiring two modules together so each one's outputs
feed the other's matching inputs looks like this:

```verilog
module top(
    input        clk,
    output [7:0] result
);
    wire [3:0] flag_a, flag_b;

    module_a a_inst(.clk(clk), .flag_out(flag_a), .flag_in(flag_b), .result(result));
    module_b b_inst(.flag_in(flag_a), .flag_out(flag_b));
endmodule
```

— a shared wire per signal, declared once, feeding into whichever
instance's port needs it as an input and out of whichever instance's port
produces it as an output. Your actual job is reading the real port lists
of `mips_datapath` and `control_unit` (both already written, in
Exercises 8 and 9) and doing exactly this for every signal that has to
cross between them — there's a specific, correct pairing for each one, and
getting a single pairing backwards is the most likely way to end up with a
CPU that compiles but doesn't run the test program correctly.

That's genuinely close to the entire exercise's new code. What makes this a
worthwhile capstone isn't the wiring — it's that, once wired, **you have a
real, working general-purpose processor**, capable of running an
arbitrary program made of the instructions you've supported, including
actual control flow: loops, via a backward branch. The test program for
this exercise sums the numbers 1 through 5 using a real conditional loop
(`beq` to test the loop condition, another `beq` to jump back to the top)
— something no single earlier exercise's test could exercise on its own,
since it requires the ALU, register file, control unit, program counter,
and branching logic all cooperating correctly across many cycles in a row.
If your CPU gets this right, every layer underneath it is correct in
concert, not just in isolation.

## A note on this course's `sll`/`srl` simplification

Real MIPS `sll`/`srl` take their shift amount from a literal 5-bit `shamt`
field baked into the instruction, with only one register operand (the
value to shift). This course's ALU (Lecture 8) instead treats every
R-type instruction uniformly as "two register operands, one ALU result" —
which means, in *this course's* simplified ISA, `sll`/`srl` take **both**
operands from registers: the value to shift from `rs`, and the shift
amount (via its lowest 5 bits) from `rt`. This was flagged as a deliberate
simplification back in Lecture 8, made specifically so the datapath and
control unit didn't need a third ALU-operand source (a `shamt` field) just
for two instructions. The capstone test program reflects this: it loads a
shift amount into a register with `addi` before using `sll`/`srl`, rather
than using a literal shift amount the way real MIPS assembly would.

## Where this fits in MIPS / architecture

This *is* a single-cycle MIPS CPU, in the same sense that Patterson &
Hennessy's textbook single-cycle design is a real (if minimal) CPU: given
a program in machine code, it fetches, decodes, executes, and
writes back results, one instruction per clock cycle, correctly handling
sequential control flow, conditional branches, memory access, and every
arithmetic/logical instruction in this course's ISA subset. Real
production CPUs add pipelining (Lecture 11), forwarding, caching, multiple
issue, out-of-order execution, and vastly larger instruction sets — but the
fundamental contract (fetch an instruction, decode it into control
signals, execute it, update architectural state) is exactly what you've
built here, in miniature.

## Electronics/VLSI note

Zoom out to the full picture this course has built, piece by piece: static
CMOS gates (Lecture 1-2) compose into muxes and decoders (Lecture 3), which
compose into registers and memory (Lectures 4, 5, 7), which compose into an
ALU (Lecture 8) and a control unit (Lecture 10), which compose into a full
CPU (this lecture) — and every step along the way, propagation delay,
setup/hold timing, and metastability (Lectures 1, 4, 12) constrain what
clock frequency the whole assembly can actually run at. A real
industrial CPU design is this same hierarchy, just far deeper and wider:
standard cells become larger IP blocks, which become CPU cores, which
become multi-core chips — but the composition principle, and the physical
constraints governing it, don't change.

## Exercise

→ [`exercises/ex12`](../exercises/ex12) — wire the datapath and control
unit together into a complete `mips_cpu`, and run a real loop-based
program (summing 1 through 5) through it.

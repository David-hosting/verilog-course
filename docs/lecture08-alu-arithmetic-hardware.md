# Lecture 8 — The ALU: Arithmetic Hardware & CMOS Realities

## Concept: an ALU is "compute everything, then mux"

An Arithmetic Logic Unit computes one of several possible operations on two
operands, selected by a control code. The cleanest way to build one in
behavioral Verilog is exactly the pattern from Lecture 3: a `case`
statement inside `always @(*)`, one branch per operation:

```verilog
always @(*) begin
    case (sel)
        2'b00: result = a + b;
        2'b01: result = a - b;
        2'b10: result = a ^ b;
        default: result = 32'b0;
    endcase
end
```

This maps to real hardware surprisingly directly: a real ALU typically does
compute several candidate results in parallel (dedicated adder hardware,
dedicated AND/OR gate arrays, etc. — all physically present, all
continuously active) and then uses a wide mux, selected by the control
code, to route only the wanted one to the output. Nothing is "skipped" at
the gate level just because a `case` branch wasn't taken — every branch's
hardware exists and runs every cycle; only the *mux* decides what you see.

## Signed comparison: `$signed()`

Verilog vectors are unsigned by default, even if you're conceptually
treating them as two's-complement signed numbers. `$signed(x)` reinterprets
a vector's bits as a signed value for the purpose of one expression (it
doesn't change how `x` is stored, only how *this comparison/operation*
interprets it). This matters enormously for `<`/`>` comparisons and for
right-shifts — get it wrong and, e.g., `-1 < 1` (obviously true) evaluates
as false, because unsigned `32'hFFFFFFFF` is *not* less than `32'h1`.

## Overflow detection

Overflow means "the true mathematical result doesn't fit in 32 signed
bits" — it is **not** the same as carry-out, and it only makes sense to
even ask the question for addition and subtraction. The standard two's
complement rule:

- **Addition overflows** exactly when both operands have the *same* sign
  but the result has the *opposite* sign (two positives can't legitimately
  sum to a negative number, and vice versa):
  `overflow = ~(a[31] ^ b[31]) & (a[31] ^ result[31])`
- **Subtraction overflows** exactly when the operands have *different*
  signs and the result's sign doesn't match the minuend (`a`)'s sign:
  `overflow = (a[31] ^ b[31]) & (a[31] ^ result[31])`

You'll implement exactly these two formulas in this exercise.

## Where this fits in MIPS / architecture

This *is* the MIPS ALU — the single most central piece of the datapath
you'll assemble in Lecture 9. Every arithmetic instruction, every address
calculation for `lw`/`sw`, and every `beq` comparison (computed as a
subtraction, checking if the result is zero) routes through this exact
module. The `alu_control` encoding used here (`AND=0000, OR=0001, ADD=0010,
SUB=0110, SLT=0111, NOR=1100`) matches the classic encoding from Patterson &
Hennessy's *Computer Organization and Design* almost exactly — Lecture 10's
control unit will generate precisely these codes from an instruction's
opcode and function field.

`sll`/`srl` (shift left/right logical) are included here too, generalized
as ALU operations that shift `a` by the amount in `b`'s lowest 5 bits
(`b[4:0]`) — enough to specify any shift amount from 0 to 31 for a 32-bit
value. In a real MIPS CPU these often live in a separate, dedicated shifter
unit outside the main ALU (since shift amount comes from a different
instruction field than a normal register operand) — we fold them into the
same module here to keep the datapath in later lectures simpler, at some
cost of strict textbook accuracy.

## Electronics/VLSI note: why not just use `+` for everything?

Lecture 2 built an adder from full-adder gates chained in series — a
**ripple-carry adder**. Its critical path (worst-case delay) grows
*linearly* with bit width: adding 32-bit numbers means the carry may have
to ripple through all 32 full adders before the final sum is trustworthy.
Real ALUs almost never use a plain ripple-carry adder at 32+ bits — they
use structures like **carry-lookahead** or **carry-select** adders, which
compute carries for multiple bit groups in parallel using extra gates, at
the cost of more area and power, to get a critical path that grows more
like *log(N)* instead of *N*. This is a direct, textbook example of the
area/power-vs-speed tradeoff that runs through all of VLSI design: iverilog
and Verilog's `+` operator hide this choice from you completely (it
synthesizes to whatever adder structure the tool decides is best), but the
physical tradeoff is real and is exactly why a chip's clock frequency is
partly determined by choices made inside blocks as "boring" as an adder.

## Exercise

→ [`exercises/ex07`](../exercises/ex07) — build a full 32-bit MIPS ALU with
zero and overflow flags.

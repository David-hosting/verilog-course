# Exercise 2 — Mux/Decoder-Based Mini-ALU

**Lecture:** 3 — Muxes, Decoders & Behavioral Combinational Logic

## What you're building

In `src/mux_decoder_alu.v`, four modules:

```verilog
module mux2to1 #(parameter WIDTH = 1) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input               sel,
    output [WIDTH-1:0] out
);

module mux4to1 #(parameter WIDTH = 1) (
    input  [WIDTH-1:0] in0, in1, in2, in3,
    input  [1:0]        sel,
    output [WIDTH-1:0] out
);

module decoder3to8(
    input  [2:0] in,
    input        en,
    output [7:0] out
);

module mini_alu4(
    input  [3:0] a,
    input  [3:0] b,
    input  [2:0] op,
    output [3:0] result,
    output       zero
);
```

### Rules for each module

- **`mux2to1`**: behavioral (`assign` with a ternary, or `always @(*)`).
- **`mux4to1`**: build it **structurally**, by instantiating `mux2to1`
  three times (two to narrow the four inputs to two based on `sel[0]`, one
  more to pick the final result based on `sel[1]`). Do not just write
  `assign out = sel==0 ? in0 : ...` here — the point is composing smaller
  verified blocks into a bigger one, same idea as Lecture 2's adder chain.
- **`decoder3to8`**: behavioral, `always @(*)` with a default value assigned
  first (avoid inferring a latch — see the lecture note on why this
  matters).
- **`mini_alu4`**: behavioral, `always @(*)` with a `case` on `op`. Supports:

  | `op` | Operation | `result` |
  |------|-----------|----------|
  | `000` | ADD | `a + b` (4-bit, wraps on overflow — ignore overflow for this exercise) |
  | `001` | SUB | `a - b` |
  | `010` | AND | `a & b` |
  | `011` | OR  | `a \| b` |
  | `100` | SLT | `1` if `a < b` as **signed** 4-bit numbers, else `0` (result in bit 0, rest zero) |
  | others | — | `result = 4'b0` |

  `zero` is combinational: `1` if `result == 0`, else `0`.

  `SLT` ("set less than") is not a style choice — it's the real MIPS `slt`
  instruction's behavior, which is how MIPS implements `if`/`while`
  comparisons in hardware (there's no hardware "less-than branch"; compilers
  emit `slt` followed by `beq`/`bne` against zero). You'll meet it again,
  at 32 bits, in Exercise 7.

## What's tested

- `mux2to1` and `mux4to1`: exhaustive over all select values, several data
  widths.
- `decoder3to8`: exhaustive over all 8 input codes, both with `en=1` and
  `en=0`.
- `mini_alu4`: every operation, exhaustive over all 256 `(a, b)` pairs for
  each defined op, plus explicit signed-boundary cases for `SLT` (e.g.
  negative vs. positive, most-negative vs. most-positive in 4-bit two's
  complement).

## Run it

```bash
bash scripts/run_exercise.sh ex02
```

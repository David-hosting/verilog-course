# Exercise 1 — Gate-Level Adders

**Lecture:** 2 — Combinational Logic & Structural Modeling

## What you're building

Two modules, in `src/adders.v`:

1. `full_adder` — a 1-bit full adder.
2. `ripple_carry_adder` — an N-bit adder built by chaining `full_adder`
   instances with a `generate` loop.

## Constraint (the actual point of this exercise)

Build both using **only structural gate primitives** (`and`, `or`, `xor`,
`not`, `nand`, `nor`, `xnor` instances) — no `assign`, no `+`, no behavioral
operators. The goal is to force the mapping from "logic function" to
"physical gates" to stop being abstract before you're allowed to use
shortcuts. From Exercise 2 onward, behavioral Verilog is fair game.

Grading only checks functional correctness (it can't easily verify *how* you
implemented it), but doing this one behaviorally defeats the point — you'll
feel the difference the moment you get to Lecture 8's carry-lookahead
discussion if you skip it now.

## Required interface

```verilog
module full_adder(
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);

module ripple_carry_adder #(
    parameter N = 8
)(
    input  [N-1:0] a,
    input  [N-1:0] b,
    input          cin,
    output [N-1:0] sum,
    output         cout
);
```

Port names and widths must match exactly — the testbench instantiates your
modules by name.

## What's tested

- `full_adder`: all 8 input combinations, exhaustively.
- `ripple_carry_adder` at `N=8`: directed corner cases (zero, all-ones,
  carry-in set, a case that ripples a carry across every bit) plus 50
  pseudo-random vectors, each checked against `{cout, sum} = a + b + cin`
  computed independently by the testbench.

## Run it

```bash
bash scripts/run_exercise.sh ex01
```

# Exercise 3 — D Flip-Flop & Register

**Lecture:** 4 — Sequential Logic: Latches, Flip-Flops, Timing

## What you're building

In `src/dff_reg.v`:

```verilog
module dff_en_rst(
    input      clk,
    input      rst,   // synchronous, active-high, highest priority
    input      en,
    input      d,
    output reg q
);

module reg8(
    input        clk,
    input        rst,
    input        en,
    input  [7:0] d,
    output [7:0] q
);
```

## Rules

- `dff_en_rst`: one `always @(posedge clk)` block, nonblocking assignment
  (`<=`). Priority order: `rst` beats `en` beats "hold." On `rst`, `q`
  becomes 0 regardless of `en`. If not resetting and `en` is high, `q`
  becomes `d`. Otherwise `q` holds its value.
- `reg8`: build it **structurally**, from 8 instances of `dff_en_rst` (one
  per bit), all sharing the same `clk`, `rst`, and `en`.

## What's tested

- `dff_en_rst`: a clocked sequence of directed scenarios checking reset
  priority over enable, enable gating (value must **not** change when
  `en=0` even if `d` changes), and normal capture on the rising edge only
  (changing `d` mid-cycle, between edges, must not affect `q` until the
  next edge).
- `reg8`: the same scenarios at 8-bit width, plus a check that all 8 bits
  update together atomically on one edge (no bit lagging behind another).

## Run it

```bash
bash scripts/run_exercise.sh ex03
```

# Exercise 4 — Up/Down Counter & Bidirectional Shift Register

**Lecture:** 5 — Registers, Counters, Shift Registers

## What you're building

In `src/counter_shiftreg.v`:

```verilog
module updown_counter8(
    input        clk,
    input        rst,      // sync, highest priority -> count = 0
    input        load,     // next priority -> count = load_val
    input  [7:0] load_val,
    input        en,       // gates counting only (not rst/load)
    input        up_down,  // 1 = increment, 0 = decrement
    output reg [7:0] count
);

module shift_reg8(
    input        clk,
    input        rst,        // sync, highest priority -> q = 0
    input        en,         // gates load/shift
    input        load,       // next priority -> q = load_val
    input  [7:0] load_val,
    input        dir,        // 1 = shift left, 0 = shift right
    input        serial_in,
    output reg [7:0] q
);
```

## Priority rules (must match exactly)

Both modules: `rst` beats `load` beats normal operation, and `en` gates
*only* the normal (count/shift) operation — `rst` always works regardless
of `en`. (Whether `load` also requires `en` is up to the classic MIPS-PC
convention this mirrors: here, `load` does **not** require `en=1`; only the
plain increment/decrement or shift path does. This asymmetry is intentional
and tested — read it twice.)

`shift_reg8` shift directions:
- `dir=1` (left): `q <= {q[6:0], serial_in}` — new bit enters at the LSB.
- `dir=0` (right): `q <= {serial_in, q[7:1]}` — new bit enters at the MSB.

## What's tested

- `updown_counter8`: reset, load (with `en=0`, to confirm load doesn't need
  `en`), count up with `en=1`, count down with `en=1`, holding when `en=0`,
  wraparound at `8'hFF -> 8'h00` and `8'h00 -> 8'hFF`, and reset priority
  over a simultaneous load.
- `shift_reg8`: reset, load (with `en=0`), shift-left and shift-right
  sequences checked bit-by-bit over multiple cycles, holding when `en=0`,
  and reset priority over a simultaneous load.

## Run it

```bash
bash scripts/run_exercise.sh ex04
```

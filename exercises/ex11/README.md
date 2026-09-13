# Exercise 11 — Debounced Async-Input Synchronizer

**Lecture:** 12 — Crossing into the Analog World: Synchronizers & Timing Closure

## What you're building

In `src/button_counter.v`, three modules:

```verilog
module synchronizer(
    input  clk,
    input  async_in,
    output sync_out
);

module debouncer #(
    parameter STABLE_CYCLES = 4
)(
    input      clk,
    input      rst,
    input      noisy_in,
    output reg clean_out
);

module button_edge_counter #(
    parameter STABLE_CYCLES = 4
)(
    input        clk,
    input        rst,
    input        async_button,   // raw, unsynchronized, possibly bouncing
    output [7:0] press_count     // increments once per real (debounced) press
);
```

**Required instance names inside `button_edge_counter`**: `synchronizer` as
`sync`, `debouncer` as `debounce`.

## Rules

- **`synchronizer`**: exactly two flip-flops in series (see the lecture
  note). `sync_out` lags `async_in` by exactly 2 clock cycles once
  `async_in` is stable.
- **`debouncer`**: only changes `clean_out` once `noisy_in` has
  *continuously* disagreed with the current `clean_out` for
  `STABLE_CYCLES` consecutive cycles. Any cycle where `noisy_in` agrees
  with `clean_out` resets the count back to zero (this is what makes it
  robust to bouncing, not just a fixed delay).
- **`button_edge_counter`**: chain `sync` → `debounce` → a rising-edge
  detector (a 1-cycle-delayed copy of the debounced signal, compared
  against the current value — the same idea as any edge detector: compare
  a signal to a registered copy of itself one cycle old) → an 8-bit
  counter (Lecture 5's pattern) that increments by 1 exactly once per
  detected rising edge. `press_count` wraps silently on overflow (ignore
  overflow — not the point of this exercise).

## What's tested

- `synchronizer` alone: a clean input change is reflected on `sync_out`
  exactly 2 clock cycles later, not sooner.
- `debouncer` alone: a clean, sustained input transition flips `clean_out`
  after exactly `STABLE_CYCLES` cycles; a **bouncy** input (toggling a few
  times before settling) must **not** flip `clean_out` early — every
  bounce back to the current value resets the count, and only a truly
  sustained change is ever accepted.
- `button_edge_counter`: a full noisy, bouncy simulated button press
  (several rapid toggles before settling high), held, then released
  (again noisily), then pressed a second time — `press_count` must read
  exactly `1` after the first settled press and exactly `2` after the
  second, never incrementing extra times from the bounce noise or from the
  release.

## Run it

```bash
bash scripts/run_exercise.sh ex11
```

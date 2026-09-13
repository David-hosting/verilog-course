# Exercise 6 — MIPS Register File

**Lecture:** 7 — Memory Modeling: RAM/ROM/Register Files

## What you're building

In `src/regfile.v`:

```verilog
module regfile32(
    input         clk,
    input         we,
    input  [4:0]  ra1,
    input  [4:0]  ra2,
    input  [4:0]  wa,
    input  [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2
);
```

32 registers, 32 bits each (`ra1`/`ra2`/`wa` are 5-bit addresses, `2^5 = 32`).

## Rules

- **Reads are combinational**: `rd1`/`rd2` must reflect the currently
  stored value at `ra1`/`ra2` immediately, with no clock edge required —
  this includes reflecting a write from a *previous* cycle the instant the
  read address is set, and *not* reflecting a write happening in the
  current cycle until the next clock edge (see the lecture note on
  read-during-write).
- **Writes are synchronous**: only take effect on the rising edge of `clk`,
  and only when `we=1`.
- **Register 0 (`$zero`) is hardwired to 0**: `ra1==0` or `ra2==0` must
  always read `32'b0`, regardless of anything ever written. A write with
  `wa==0` must be silently ignored (does not change any stored state, does
  not even change what register 0 would read as, which is always 0 anyway).

## What's tested

- Register 0 always reads 0, before and after attempting to write it.
- Writing a value to a register (1-31) and reading it back on a later
  cycle.
- Reading two different registers simultaneously via `ra1`/`ra2`, including
  both pointing at the same nonzero register.
- Read-during-write: setting a read address equal to the address currently
  being written (same cycle) must return the **old** value, not the new one
  landing this edge.
- A short sequence of several writes to several registers, then reading all
  of them back to confirm nothing was cross-contaminated.

## Run it

```bash
bash scripts/run_exercise.sh ex06
```

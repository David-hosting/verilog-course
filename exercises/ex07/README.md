# Exercise 7 — 32-bit MIPS ALU

**Lecture:** 8 — The ALU: Arithmetic Hardware & CMOS Realities

## What you're building

In `src/alu32.v`:

```verilog
module alu32(
    input      [31:0] a,
    input      [31:0] b,
    input      [3:0]  alu_control,
    output reg [31:0] result,
    output             zero,
    output reg         overflow
);
```

## Operation table

| `alu_control` | Name | `result` |
|---|---|---|
| `4'b0000` | AND | `a & b` |
| `4'b0001` | OR  | `a \| b` |
| `4'b0010` | ADD | `a + b` |
| `4'b0110` | SUB | `a - b` |
| `4'b0111` | SLT | `1` if `a < b` as **signed** 32-bit values, else `0` |
| `4'b1100` | NOR | `~(a \| b)` |
| `4'b0100` | SLL | `a << b[4:0]` (shift amount is `b`'s lowest 5 bits) |
| `4'b0101` | SRL | `a >> b[4:0]` (logical shift, zero-filled) |
| anything else | — | `result = 32'b0` |

## Flags

- `zero = 1` whenever `result == 32'b0`, for **any** operation (not just
  ADD/SUB).
- `overflow` is only meaningful for ADD and SUB, and must be `0` for every
  other operation. Use the standard two's-complement rule:
  - ADD: `overflow = ~(a[31] ^ b[31]) & (a[31] ^ result[31])`
  - SUB: `overflow = (a[31] ^ b[31]) & (a[31] ^ result[31])`

## What's tested

- Every operation, directed at boundary values: `0`, all-ones
  (`32'hFFFFFFFF`), max positive (`32'h7FFFFFFF`), max negative
  (`32'h80000000`), and alternating-bit patterns.
- `SLT`: explicit signed-boundary cases (negative vs. positive, both
  negative, both positive, equal values).
- `SLL`/`SRL`: shift amounts `0`, `1`, `31`, and a case where `b` has bits
  set *above* bit 4 (must be ignored — only `b[4:0]` selects the amount).
- `overflow`: explicit cases that must overflow and explicit cases that
  must not, for both ADD and SUB — plus confirmation that `overflow` reads
  `0` for every non-arithmetic operation regardless of operand values.
- `zero`: confirmed alongside every other check (any operation producing
  `result == 0` must assert it).
- ~300 pseudo-random directed-operation vectors (ADD/SUB/AND/OR/NOR),
  checked against values computed independently by the testbench.

## Run it

```bash
bash scripts/run_exercise.sh ex07
```

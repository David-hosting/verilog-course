# Exercise 12 (Capstone) — Full CPU Integration

**Lecture:** 13 — Capstone: Integrating a Single-Cycle MIPS CPU

## What you're building

`src/provided_components.v` gives you fully working copies of everything
from Exercises 6-9: `regfile32`, `alu32`, `instr_mem`, `data_mem`,
`mips_datapath`, and `control_unit` (don't edit this file). In
`src/mips_cpu.v`, complete `mips_cpu`: instantiate `mips_datapath` (as
`dp`) and `control_unit` (as `cu`), and wire the datapath's `opcode`/`funct`
outputs into the control unit's inputs, and the control unit's control
signals into the datapath's control inputs. See the code block in Lecture
13's note for the exact shape of this wiring — this really is close to the
entire exercise.

```verilog
module mips_cpu(
    input         clk,
    input         rst,
    output [31:0] pc_out
);
```

**Required instance names**: `mips_datapath` as `dp`, `control_unit` as
`cu` (the testbench inspects `dp`'s internals directly for the register
file and data memory).

## The test program

The testbench preloads instruction memory with a real loop that sums the
integers 1 through 5:

```
0:  addi $1, $0, 5        # $1 = 5   (loop counter)
4:  addi $2, $0, 0        # $2 = 0   (sum accumulator)
8:  beq  $1, $0, 3        # while ($1 != 0) { ... goto 24 when $1==0 }
12: add  $2, $2, $1       #   sum += counter
16: addi $1, $1, -1       #   counter -= 1
20: beq  $0, $0, -4       #   goto 8 (unconditional -- comparing $0 to itself)
24: sw   $2, 0($0)        # mem[0] = sum
28: lw   $5, 0($0)        # $5 = mem[0]           (memory round-trip check)
32: addi $3, $0, 1        # $3 = 1
36: srl  $6, $2, $3       # $6 = sum >> $3 (see the note below on sll/srl)
40: addi $8, $0, 2        # $8 = 2
44: sll  $7, $2, $8       # $7 = sum << $8
```

**Note on `sll`/`srl` in this course**: this course's ALU (Exercise 7)
gives every R-type instruction two register operands, so — unlike real
MIPS, which takes the shift amount from a literal `shamt` field —
`sll`/`srl` here take *both* operands from registers: the value to shift
from `rs`, the shift amount (its lowest 5 bits) from `rt`. That's why the
program loads `1` and `2` into registers before shifting with them,
instead of using a literal shift amount the way real MIPS assembly would.
This was flagged as a deliberate simplification back in Lecture 8.

If your CPU is wired correctly, the loop runs 5 times (once each for
counter values 5, 4, 3, 2, 1), summing to `1+2+3+4+5 = 15`.

## What's tested

- A sanity checkpoint early on (PC reaches the loop-condition check at
  address 8 for the first time) before the loop logic is trusted at all.
- After the exact number of cycles this program needs (the testbench
  knows this precisely, from tracing the loop), final `pc_out == 48`.
- Final register file contents (peeked directly via `dp.rf.regs[]`):
  `$1 == 0`, `$2 == 15`, `$3 == 1`, `$5 == 15`, `$6 == 7`, `$7 == 60`,
  `$8 == 2`.
- Final data memory contents (`dp.dmem.mem[0] == 15`).

If this fails, the most useful debugging tool is a waveform: every
testbench in this course dumps `dump.vcd` — open it with `gtkwave dump.vcd`
and watch `pc_out`, the control signals, and the register file's write
port over time to see exactly where behavior diverges from the trace
above.

## Run it

```bash
bash scripts/run_exercise.sh ex12
```

## You're done

If this passes, you've built — piece by piece, each one independently
tested — a real, working CPU that executes real machine code, including
loops. That's the whole course.

# Exercise 8 — Single-Cycle MIPS Datapath

**Lecture:** 9 — Datapath Design

## What you're building

`src/provided_components.v` gives you working copies of `regfile32`,
`alu32`, `instr_mem`, and `data_mem` (all from earlier exercises/lecture
notes — don't edit this file). In `src/datapath.v`, wire them together into
`mips_datapath`, filling in the `TODO`s: `pc_plus4`, sign extension, the
`write_reg` mux (`RegDst`), the `alu_operand2` mux (`ALUSrc`), the
`write_back_data` mux (`MemtoReg`), the branch target adder, the
branch-taken decision, the next-PC mux, and the PC register update itself.

Control signals (`reg_dst`, `branch`, `mem_to_reg`, `alu_control`, ...) are
plain module inputs here — the testbench drives them directly, playing the
role of a control unit for this exercise. Lecture 10 builds the circuit
that generates them for real from an instruction's opcode/funct.

**Required instance names** (the testbench inspects your datapath's
internals directly, so these must match exactly — the skeleton already has
them right, don't rename the instances):

| Module | Instance name |
|---|---|
| `regfile32` | `rf` |
| `alu32` | `alu` |
| `instr_mem` | `imem` |
| `data_mem` | `dmem` |

## The test program

The testbench preloads `instr_mem` with this fixed program (addresses are
byte addresses; MIPS instructions are always 4-byte aligned) and drives the
matching control signals for each instruction as your datapath's PC
reaches it:

```
0:  addi $1, $0, 5      # $1 = 5
4:  addi $2, $0, 3      # $2 = 3
8:  add  $3, $1, $2     # $3 = 8
12: sub  $4, $1, $2     # $4 = 2
16: and  $5, $1, $2     # $5 = 1
20: or   $6, $1, $2     # $6 = 7
24: slt  $7, $2, $1     # $7 = 1   ($2 < $1)
28: sw   $3, 0($0)      # mem[0] = 8
32: lw   $8, 0($0)      # $8 = 8
36: beq  $1, $1, 1      # always taken (comparing $1 to itself) -> target = 44
40: addi $9, $0, 99     # SKIPPED by the branch -- must never execute
44: addi $10, $0, 42    # branch target
```

If your datapath is wired correctly, the branch at address 36 is always
taken (since it compares `$1` to itself), so the instruction at address 40
must never execute, and execution should land on address 44 next.

## What's tested

- `pc_out` at every cycle follows the exact address trace above (including
  landing on 44, not 40, after the branch).
- `zero_flag` reads 1 during the `beq` cycle (confirming your ALU wiring
  for the comparison is correct, not just the branch-mux logic).
- Final register file contents (peeked directly): `$1..$10` match the
  values in the comments above, and `$9` is untouched (proving the skipped
  instruction really didn't execute).
- Final data memory contents: `mem[0] == 8`.
- Final `pc_out == 48` (one past the last executed instruction).

## Run it

```bash
bash scripts/run_exercise.sh ex08
```

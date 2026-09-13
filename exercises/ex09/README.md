# Exercise 9 — MIPS Control Unit

**Lecture:** 10 — Control Unit Design

## What you're building

In `src/control_unit.v`, three modules:

```verilog
module main_decoder(
    input      [5:0] opcode,
    output           reg_dst,
    output           branch,
    output           mem_read,
    output           mem_to_reg,
    output           mem_write,
    output           alu_src,
    output           reg_write,
    output reg [1:0] alu_op
);

module alu_decoder(
    input      [1:0] alu_op,
    input      [5:0] funct,
    output reg [3:0] alu_control
);

module control_unit(
    input  [5:0] opcode,
    input  [5:0] funct,
    output       reg_dst,
    output       branch,
    output       mem_read,
    output       mem_to_reg,
    output       mem_write,
    output       alu_src,
    output       reg_write,
    output [3:0] alu_control
);
```

`control_unit` just wires `main_decoder` and `alu_decoder` together
(instantiate both, connect `alu_op` between them) — no new logic of its own.

## Opcodes and functs you must support

| Instruction | opcode (binary / hex) |
|---|---|
| R-type (add/sub/and/or/slt/sll/srl) | `000000` / `0x00` |
| `lw` | `100011` / `0x23` |
| `sw` | `101011` / `0x2B` |
| `beq` | `000100` / `0x04` |
| `addi` | `001000` / `0x08` |

| R-type funct | Operation |
|---|---|
| `100000` / `0x20` | add |
| `100010` / `0x22` | sub |
| `100100` / `0x24` | and |
| `100101` / `0x25` | or |
| `101010` / `0x2A` | slt |
| `000000` / `0x00` | sll |
| `000010` / `0x02` | srl |

`alu_control` codes must match Exercise 7's encoding exactly:
`AND=0000, OR=0001, ADD=0010, SLL=0100, SRL=0101, SUB=0110, SLT=0111`.

## `main_decoder` truth table

| opcode | reg_dst | branch | mem_read | mem_to_reg | mem_write | alu_src | reg_write | alu_op |
|---|---|---|---|---|---|---|---|---|
| R-type | 1 | 0 | 0 | 0 | 0 | 0 | 1 | `10` |
| `lw`   | 0 | 0 | 1 | 1 | 0 | 1 | 1 | `00` |
| `sw`   | 0 (don't-care) | 0 | 0 | 0 (don't-care) | 1 | 1 | 0 | `00` |
| `beq`  | 0 (don't-care) | 1 | 0 | 0 (don't-care) | 0 | 0 | 0 | `01` |
| `addi` | 0 | 0 | 0 | 0 | 0 | 1 | 1 | `00` |
| anything else | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `00` |

(For "don't-care" entries, the tests only check the signals that actually
affect behavior for that opcode — but outputting `0` for them, as shown, is
the simplest correct choice and what's provided as the expected value.)

## `alu_decoder` truth table

| alu_op | funct (only checked if alu_op==10) | alu_control |
|---|---|---|
| `00` | — | `ADD` |
| `01` | — | `SUB` |
| `10` | add | `ADD` |
| `10` | sub | `SUB` |
| `10` | and | `AND` |
| `10` | or  | `OR` |
| `10` | slt | `SLT` |
| `10` | sll | `SLL` |
| `10` | srl | `SRL` |
| `10` | anything else | `AND` (default) |

## What's tested

- `main_decoder`: every listed opcode, exhaustively checking every output
  signal, plus one unrecognized opcode.
- `alu_decoder`: every listed `(alu_op, funct)` combination, plus an
  unrecognized `funct` under `alu_op=10`.
- `control_unit`: an integration check — for every instruction in
  Exercise 8's test program, confirms the *exact same* control signal
  bundle that exercise's testbench hardcoded is what your control unit
  produces from the real `opcode`/`funct` values.

## Run it

```bash
bash scripts/run_exercise.sh ex09
```

# Exercise 10 — 2-Stage Pipeline with a Stall

**Lecture:** 11 — Pipelining Fundamentals & Hazards

## What you're building

`src/provided_components.v` gives you `regfile32` and `alu32` again
(unchanged from earlier exercises — don't edit). In `src/pipelined_exec.v`,
complete `pipelined_exec`: a 2-stage pipeline (**Decode**: read two register
operands; **Execute+Writeback**: run the ALU and write the result back)
with hazard detection and stalling.

```verilog
module pipelined_exec(
    input         clk,
    input         rst,          // sync: clears the pipeline register to a bubble

    // Decode-stage inputs -- an external instruction sequencer (the
    // testbench, here) presents one instruction's fields per cycle,
    // and MUST hold the same fields steady across a cycle where `stall`
    // reads 1 (re-presenting the same instruction next cycle too).
    input  [4:0]  d_ra1,
    input  [4:0]  d_ra2,
    input  [4:0]  d_wa,
    input  [3:0]  d_alu_control,
    input         d_reg_write,

    output        stall,        // 1 = the instruction at Decode must be held

    // Execute-stage outputs (observability of what's about to write back)
    output [4:0]  e_wa,
    output [31:0] e_result,
    output        e_reg_write
);
```

**Required instance names**: `regfile32` as `rf`, `alu32` as `alu` (the
testbench inspects `rf` directly).

## What to implement

1. **Hazard detection** (`stall`): combinational. A hazard exists when the
   instruction currently sitting in the pipeline register (i.e., in the
   Execute stage *this* cycle) will write the register file, its
   destination register isn't `$0`, and that destination register matches
   either of the *new* instruction's source registers (`d_ra1`/`d_ra2`).
2. **The pipeline register itself**: on each clock edge —
   - if `rst`: clear it to a bubble (`reg_write` becomes 0).
   - else if `stall`: also load a bubble (discard whatever was just read at
     Decode this cycle — it was read using stale data and must not be
     allowed to execute).
   - else: latch the just-read register values (`rd1`/`rd2` from `rf`),
     `d_wa`, `d_alu_control`, and `d_reg_write` — this instruction now
     moves into the Execute stage next cycle.
3. Wire the pipeline register's latched fields into `alu32` (as `alu`) to
   produce `e_result`, and into `regfile32` (as `rf`)'s write port
   (`we = e_reg_write`, `wa = e_wa`, `wd = e_result`) — while `rf`'s *read*
   ports stay wired to the new instruction's `d_ra1`/`d_ra2` every cycle
   (Decode reads happen every cycle, hazard or not; only whether they're
   allowed to *proceed* into the pipeline register depends on `stall`).

## What's tested

A short fixed sequence of register-to-register ALU operations (seeded with
known starting register values, via direct peek/poke of `rf.regs[]` — see
`test/pipelined_exec_tb.v` if you want the exact trace) that includes:

- One genuine RAW hazard: an instruction whose source register is the very
  next instruction's destination — `stall` must read 1 for exactly one
  cycle, and the dependent instruction's eventual result must reflect the
  *correct*, already-written value (not the stale one).
- One instruction with **no** hazard immediately following a stall — must
  proceed with `stall=0`, confirming your detection logic doesn't
  over-trigger.
- One case where the pipeline register's destination register happens to
  be `$0` — must **never** cause a stall, even though the register number
  otherwise "matches."
- Confirmation that a bubble (`e_reg_write=0`) really appears in the
  Execute stage output during the stall-recovery cycle.
- Final register file contents, checked directly, for every register the
  sequence writes.

## Run it

```bash
bash scripts/run_exercise.sh ex10
```

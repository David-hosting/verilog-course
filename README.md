# Verilog, from Gates to a MIPS CPU

A hands-on Verilog course that builds up, lecture by lecture, from single logic
gates to a working single-cycle MIPS-style CPU — with side notes tying each
topic back to digital/analog electronics and VLSI (why the hardware behaves
the way it does) and to computer architecture (why MIPS is built the way it
is).

13 lectures, 12 graded exercises. Lecture 1 is setup/orientation and has no
exercise; every lecture from 2 through 13 pairs with one exercise, and the
exercises are cumulative — later ones reuse working reference copies of
modules from earlier lectures so a bug in an old exercise never blocks you
on new material.

## How this works

1. Read the lecture note in [`docs/`](docs/) for the topic.
2. Open the matching exercise folder in [`exercises/`](exercises/). Each has:
   - `README.md` — the spec: what to build, the exact module/port interface
     you must match, and what's being tested.
   - `src/` — skeleton file(s) with `TODO` markers for what you write, plus
     any "provided" files (clearly marked, already-working reference modules
     from earlier exercises) that you should not need to edit.
   - `test/` — the testbench. Read it if you want, but you shouldn't need to
     edit it. It's what grades you.
3. Implement your part in `src/`.
4. Run it locally (see below) until you get `RESULT: PASS`.
5. Commit and push. GitHub Actions re-runs every exercise's testbench on
   every push and reports pass/fail per exercise as a separate check — that's
   your "submission" record.

## Local toolchain

This repo assumes [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`,
`vvp`) for simulation and GTKWave for waveform viewing. Both are already
installed on this machine at `C:\iverilog` (added to PATH).

Run a single exercise's tests locally:

```bash
bash scripts/run_exercise.sh ex01
```

This compiles your `src/` files together with the testbench and prints either
`RESULT: PASS` or a list of the specific checks that failed. It's the exact
same script CI runs, so a local pass means a CI pass.

To inspect waveforms, add `$dumpfile`/`$dumpvars` to a testbench (already
done in most of them — check for a `.vcd` file after running) and open it
with:

```bash
gtkwave dump.vcd
```

## Syllabus

| # | Lecture | Exercise |
|---|---------|----------|
| 1 | [Intro: HDLs, digital logic foundations, toolchain](docs/lecture01-intro-hdl-toolchain.md) | — (setup only) |
| 2 | [Combinational logic & structural modeling](docs/lecture02-combinational-logic.md) | [ex01 — Gate-level adders](exercises/ex01) |
| 3 | [Muxes, decoders & behavioral combinational logic](docs/lecture03-mux-decoder-behavioral.md) | [ex02 — Mux/decoder-based mini-ALU](exercises/ex02) |
| 4 | [Sequential logic: latches, flip-flops, timing](docs/lecture04-sequential-logic-timing.md) | [ex03 — D flip-flop & register](exercises/ex03) |
| 5 | [Registers, counters, shift registers](docs/lecture05-registers-counters-shift.md) | [ex04 — Counter + shift register](exercises/ex04) |
| 6 | [Finite state machines](docs/lecture06-finite-state-machines.md) | [ex05 — Traffic-light FSM](exercises/ex05) |
| 7 | [Memory modeling: RAM/ROM/register files](docs/lecture07-memory-modeling.md) | [ex06 — MIPS register file](exercises/ex06) |
| 8 | [The ALU: arithmetic hardware & CMOS realities](docs/lecture08-alu-arithmetic-hardware.md) | [ex07 — 32-bit MIPS ALU](exercises/ex07) |
| 9 | [Datapath design](docs/lecture09-datapath-design.md) | [ex08 — Single-cycle MIPS datapath](exercises/ex08) |
| 10 | [Control unit design](docs/lecture10-control-unit-design.md) | [ex09 — MIPS control unit](exercises/ex09) |
| 11 | [Pipelining fundamentals & hazards](docs/lecture11-pipelining-hazards.md) | [ex10 — 2-stage pipeline with a stall](exercises/ex10) |
| 12 | [Crossing into the analog world: synchronizers & timing closure](docs/lecture12-synchronizers-timing-closure.md) | [ex11 — Debounced async-input synchronizer](exercises/ex11) |
| 13 | [Capstone: integrating a single-cycle MIPS CPU](docs/lecture13-capstone-cpu-integration.md) | [ex12 — Full CPU integration](exercises/ex12) |

## Scope note

This is a *learning* course, not a production CPU. The MIPS subset covered is
intentionally small (`add, sub, and, or, slt, sll, srl, lw, sw, beq, addi`) —
enough to run real short programs and see every piece of the datapath do real
work, without drowning in ISA corner cases.

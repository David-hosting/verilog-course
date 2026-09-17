# Lecture 11 — Pipelining Fundamentals & Hazards

## Concept: overlap, don't wait

Lecture 9's single-cycle datapath finishes one entire instruction every
clock edge — including `lw`, whose critical path runs through instruction
fetch, register read, ALU address calculation, data memory, *and* the
write-back mux, all in one cycle. Every other, simpler instruction (like
`and`) still has to wait for that same long clock period, even though it
personally only needed a fraction of it. **Pipelining**'s idea: split the
datapath into stages (classically, for MIPS: Fetch, Decode, Execute,
Memory, Write-back), put a **pipeline register** between each pair of
stages, and let *different instructions occupy different stages
simultaneously* — while instruction 2 is being decoded, instruction 1 is
already executing; while instruction 3 is being fetched, instruction 2 is
decoding and instruction 1 is accessing memory. The clock period only needs
to be as long as the *slowest single stage*, not the slowest whole
instruction — this is where pipelining's speedup comes from.

A pipeline register is exactly Lecture 5's register-with-enable, just
holding "everything the next stage needs to know about this instruction"
instead of a counter value:

```verilog
always @(posedge clk) begin
    if (rst) begin
        id_ex_valid <= 1'b0;
    end else begin
        id_ex_a     <= decode_stage_operand_a;
        id_ex_b     <= decode_stage_operand_b;
        id_ex_valid <= 1'b1;
    end
end
```

## Hazards: when overlapping breaks correctness

Overlapping instructions is only safe if they don't interfere with each
other. A **data hazard** happens when one instruction needs a value that a
*still-in-flight* earlier instruction hasn't produced yet. Concretely, a
**RAW (read-after-write) hazard**: instruction B reads a register that
instruction A, one stage ahead of it, is *about to write* — but hasn't
written *yet*, because the write only lands on a clock edge (Lecture 7's
synchronous-write/combinational-read register file). If B reads that
register in the same cycle A's write is landing, B gets the **old** value.

Real, high-performance pipelines solve most of this with **forwarding**
(routing a still-in-flight result directly to where it's needed, bypassing
the register file entirely) — genuinely important, but it's a separate,
larger topic. This exercise deliberately uses the simpler, more universal
fallback: **stalling**. When a hazard is detected, the following
instruction is held in place for one extra cycle (re-presented, not
allowed to advance), and a **bubble** (a "do-nothing" instruction, with
every write-enable forced to 0) is inserted into the pipeline stage that
would otherwise have received the hazardous instruction. This costs one
cycle of throughput but is always correct, and it's the fallback every real
pipeline still needs for hazards forwarding can't fully resolve (a
classic example: the result right after a `lw` isn't available in time
even for forwarding, forcing at least one stall cycle no matter what — the
"load-use hazard").

## Detecting the hazard

The detection logic itself is simple combinational comparison — a small
"hazard detection unit" that has to be true only when **all** of the
following hold at once: the instruction currently one stage ahead is
actually going to write the register file; that destination register isn't
`$0`; and the new instruction now entering the pipeline reads that exact
register on (at least) one of its own source ports.

The middle condition matters for the same reason `$zero` is special
everywhere else in this course: a write to register 0 is architecturally a
no-op, so it can never be the source of a real hazard, even if the
register numbers happen to match.

## Where this fits in MIPS / architecture

This is a deliberately simplified slice of the classic MIPS 5-stage
pipeline's hazard-detection unit, isolated down to just two stages
(everything before "read operands" collapsed into one "Decode" stage;
everything from "execute" onward collapsed into one "Execute+Writeback"
stage) so the actual new mechanism — pipeline register, hazard check,
stall, bubble — is front and center, without re-deriving instruction
fetch or the full datapath again. The real 5-stage pipeline has this exact
same hazard-detection idea, just checking more stage boundaries and (in a
real design) combined with forwarding paths that eliminate most stalls in
practice, saving stalling for the cases forwarding genuinely can't reach.

## Electronics/VLSI note

Every pipeline register you add is real flip-flop hardware with real
setup/hold requirements (Lecture 4) — pipelining trades *more area and more
total latency per single instruction* (an instruction now takes several
cycles to fully pass through the pipeline, not one) for *higher throughput*
(a new instruction can still start every cycle, once the pipeline is full).
This area/latency-vs-throughput tradeoff is a close cousin of the
speed-vs-area tradeoff from Lecture 8's adder discussion, and pipelining
depth is one of the single biggest levers real CPU designers pull when
deciding a chip's target clock frequency and power budget.

## Exercise

→ [`exercises/ex10`](../exercises/ex10) — build a 2-stage pipelined
execute unit with hazard detection and stall/bubble insertion.

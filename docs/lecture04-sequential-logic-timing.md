# Lecture 4 — Sequential Logic: Latches, Flip-Flops, Timing

## Concept: memory needs feedback

Every combinational circuit so far has zero memory — change the inputs,
the outputs eventually settle to a new value, with no dependence on the
past. To store a bit, a circuit needs **feedback**: an output looping back
to influence itself. The simplest example is an SR latch (two cross-coupled
NOR gates) — we won't build one, but understanding that memory = feedback
loop is the conceptual leap for this lecture.

## Latch vs. flip-flop

- A **latch** is *level-sensitive*: while its enable/clock input is high, it
  is transparent (output follows input); when the enable goes low, it holds
  whatever value was present at that instant.
- A **flip-flop** is *edge-sensitive*: it only samples its input at the
  instant the clock transitions (typically rising edge), and holds that
  value until the next edge, regardless of what the input does in between.

Nearly all synchronous digital design — everything from here on in this
course — uses edge-triggered flip-flops, because they make timing analysis
and multi-stage pipelines tractable: you only ever have to reason about
"what was true right before this clock edge," not "what happened during
this entire half-cycle."

In Verilog, `always @(posedge clk)` describes an edge-triggered flip-flop
(or a bank of them):

```verilog
module dff(input clk, input d, output reg q);
    always @(posedge clk)
        q <= d;
endmodule
```

## `<=` vs. `=`: nonblocking vs. blocking assignment

This is the second most common source of subtle bugs in this course (after
latch inference).

- **Blocking (`=`)** — executes immediately, in program order, like a
  normal assignment. Use this in `always @(*)` (combinational) blocks.
- **Nonblocking (`<=`)** — schedules the assignment to happen at the *end*
  of the current time step, after every right-hand side in the block has
  been evaluated using the *old* values. Use this in `always @(posedge clk)`
  (sequential) blocks.

Why it matters: if you swap registers in a shift register using blocking
assignment (`q1 = d; q2 = q1;` inside one clocked always block), `q2` ends
up getting the *new* `q1` value in the same clock edge — collapsing two
stages into one, which is never what you want from a pipeline register.
Nonblocking assignment (`q1 <= d; q2 <= q1;`) correctly gives every register
the value its input had *before* this clock edge, matching real
flip-flop behavior (they all sample simultaneously on the same edge).

**Rule of thumb you should treat as absolute for this entire course:**
blocking assignment only inside `always @(*)`; nonblocking assignment only
inside `always @(posedge clk)`. Never mix them within the same always block.

## Reset and enable

Real flip-flops almost always have extra control inputs:

```verilog
module dff_en_rst(input clk, input rst, input en, input d, output reg q);
    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else if (en)
            q <= d;
        // else: hold current value (no assignment = implicit "keep q")
    end
endmodule
```

Note this is a **synchronous** reset — `rst` only takes effect on a clock
edge, same as everything else in the block. (An *asynchronous* reset would
be in the sensitivity list as `always @(posedge clk or posedge rst)`
and take effect immediately, independent of the clock. Both exist in real
designs; synchronous reset is simpler to reason about and is what we use
throughout this course.)

## Electronics note: setup time, hold time, and metastability

A real flip-flop is not infinitely fast internally — it needs its `d` input
to be **stable** for a minimum window around the clock edge: stable for at
least `t_setup` *before* the edge, and held for at least `t_hold` *after*
it. Violate this window (`d` changes too close to the edge) and the
flip-flop can enter **metastability** — its output hovers at an invalid
voltage between logic 0 and 1 for an unpredictable amount of time before
resolving to *either* value, arbitrarily. This isn't a simulation artifact;
it's real physics (the flip-flop's internal feedback loop briefly balanced
at an unstable equilibrium), and it's the reason a signal from outside your
clock domain (a button press, a signal from another clock domain) can't be
fed directly into synchronous logic — you'll build the standard fix (a
2-flip-flop synchronizer) in Lecture 12.

This is also *why* a clock has a maximum frequency for a given design: the
clock period must be long enough for the slowest combinational path between
two flip-flops to settle, **plus** that next flip-flop's setup time. This
`t_v + t_pd(max) + t_setup ≤ T_clock` inequality — `t_v` being the source
flip-flop's clock-to-Q delay, `t_pd(max)` the worst-case propagation delay
through the combinational logic in between — is one of the two equations
that all static timing analysis (STA) in real VLSI design flows is built
around.

The other is a **hold-time** check, and it's easy to mix up with the one
above: `t_v(min) + t_pd(min) > t_hold`. This time it's the *fastest* the
data could possibly arrive that matters — if the source flip-flop's
clock-to-Q delay and the combinational path's propagation delay are both
at their *minimum* (best-case, not worst-case), the new data must still
not reach the next flip-flop's input before that flip-flop's hold window
(measured from the *same* clock edge) has closed. If it arrives too early,
the next flip-flop could latch the *new* value instead of the one it was
supposed to capture from before this edge — silently corrupting state, not
just running slow.

This is also why a hold violation is far more dangerous in practice than a
setup violation: a setup violation can always be fixed by slowing the
clock down (increasing `T_clock` relaxes the first inequality), but the
second inequality doesn't have `T_clock` in it at all — a hold violation
exists at *every* clock frequency, including a clock that never ticks
again. It has to be fixed structurally (adding deliberate delay to the
path, or a faster/slower cell choice), not by changing timing elsewhere.

## Where this fits in MIPS / architecture

The MIPS program counter (PC), every pipeline register between the 5
classic stages (IF/ID, ID/EX, EX/MEM, MEM/WB), and every register in the
register file are all built from exactly this D-flip-flop-with-enable
primitive. Lecture 9's datapath and Lecture 11's pipeline registers are
both, at the bit level, arrays of this exact circuit.

## Exercise

→ [`exercises/ex03`](../exercises/ex03) — build `dff_en_rst` and an 8-bit
register from it.

# Lecture 12 — Crossing into the Analog World: Synchronizers & Timing Closure

## Concept: not every signal is born synchronous

Every module in this course so far assumes every input changes in a way
that's at least *eventually* stable relative to `clk` — either it's
produced by other synchronous logic sharing the same clock, or the
testbench conveniently changes it well away from a clock edge. Real
systems have inputs that don't cooperate: a push-button, a switch, a signal
from a sensor, or a signal coming from an entirely different clock domain.
These can change at *any* instant, completely uncorrelated with your clock
— and if that change happens to fall inside your flip-flops' setup/hold
window (Lecture 4), the result is **metastability**: an output that
hovers at an invalid voltage for an unpredictable time before resolving,
arbitrarily, to a 0 or a 1. This isn't a corner case you can test away in
simulation — it's a real analog phenomenon inherent to any bistable circuit
sampling a changing input near its decision threshold.

## The fix: a 2-flip-flop synchronizer

You can't prevent metastability outright, but you can make the *probability*
of it ever affecting the rest of your design astronomically small, by
giving a potentially-metastable signal one extra clock cycle to resolve
before anything else depends on it:

```verilog
module sync_chain #(parameter STAGES = 3) (
    input  clk,
    input  in_raw,
    output out_sync
);
    reg [STAGES-1:0] chain;
    always @(posedge clk)
        chain <= {chain[STAGES-2:0], in_raw};
    assign out_sync = chain[STAGES-1];
endmodule
```

Each bit of `chain` is one flip-flop, all wired in series — every cycle,
every stage copies whatever the *previous* stage held. The first flip-flop
in the chain is the one allowed to go metastable (its input can change at
any time); every later stage only samples an already-registered signal —
by the time the signal reaches the last stage, the first flip-flop has
almost certainly settled to a valid 0 or 1. More stages make the failure
probability smaller still (real designs quantify this via **MTBF — mean
time between failures**) at the cost of more latency; the exercise asks
for the shortest chain still considered safe in practice.

## Debouncing: filtering a mechanical switch

A synchronizer fixes metastability — it does **not** fix a bouncy
mechanical switch, which can flicker between 0 and 1 several times over a
few milliseconds before settling as it physically presses. A **debouncer**
only accepts a new value once the (already-synchronized) input has been
*consistently* different from the current output for some minimum number
of consecutive cycles.

Structurally, this is another counter-with-reset-condition — exactly
Lecture 5's pattern — just gated by a comparison instead of a fixed enable
signal: a counter that increments every cycle the (synchronized) input
*disagrees* with what's currently being output, gets reset back to zero
the instant it agrees again, and only when that counter finally reaches
the required streak length does the output actually change to match the
input. Work out the exact `if`/`else if` priority yourself — it's the same
shape as every priority-cascade register you've built since Lecture 4,
just with an unusual condition (equality with the module's own output)
deciding one of the branches.

## Where this fits in MIPS / architecture

Nothing inside the MIPS CPU core you've built needs a synchronizer or
debouncer — every signal inside it (control signals, register file
contents, the PC) is produced by synchronous logic sharing the CPU's own
clock. But **no real CPU exists in isolation**: interrupt lines, reset
buttons, and signals crossing from a peripheral running on a different
clock all need exactly this treatment before they're allowed to touch
synchronous logic. This lecture is the "glue" that would let you connect
the CPU you've built to a real physical button or an asynchronous
peripheral, closing the loop back to genuinely analog, physical electrical
behavior (a voltage that isn't cleanly 0 or 1 for a brief window) rather
than the idealized digital abstraction the rest of this course has used.

## Electronics/VLSI note: this is a real timing-closure concern

Real chip design flows include a dedicated **CDC (clock domain crossing)**
verification step precisely because of this lecture's topic — a signal
crossing between clock domains (or from the fully asynchronous outside
world) without a proper synchronizer is one of the most common sources of
real, silent silicon bugs: it can pass simulation entirely (simulators
often don't model metastability's probabilistic resolution at all) and
still fail unpredictably in real hardware, sometimes only occurring once
per billion cycles — exactly the kind of bug that's nearly impossible to
reproduce and debug after the fact. Static timing analysis (STA) tools
generally exclude asynchronous input paths from normal setup/hold checking
and instead require a documented synchronizer at every clock domain
boundary — this lecture's `synchronizer` module is a simplified version of
a structure that has an entire, dedicated verification discipline behind
it in real VLSI design.

## Exercise

→ [`exercises/ex11`](../exercises/ex11) — build a 2-FF synchronizer, a
debouncer, and combine them (plus an edge detector and a counter) into a
debounced button-press counter.

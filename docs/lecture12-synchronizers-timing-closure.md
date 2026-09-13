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
module synchronizer(
    input  clk,
    input  async_in,
    output sync_out
);
    reg [1:0] sync_ff;
    always @(posedge clk)
        sync_ff <= {sync_ff[0], async_in};
    assign sync_out = sync_ff[1];
endmodule
```

The first flip-flop is the one allowed to go metastable (its input can
change at any time); the second flip-flop only samples the *first flip-flop's
already-registered output* — by the time the second edge arrives, the
first flip-flop has almost certainly settled to a valid 0 or 1. This costs
exactly one extra cycle of latency for the signal to become usable, in
exchange for making the whole design's failure probability from this
source negligible (real designs quantify this via **MTBF — mean time
between failures** — a longer synchronizer chain, e.g. 3 flip-flops,
pushes MTBF up further, at the cost of more latency; 2 stages is the
common default).

## Debouncing: filtering a mechanical switch

A synchronizer fixes metastability — it does **not** fix a bouncy
mechanical switch, which can flicker between 0 and 1 several times over a
few milliseconds before settling as it physically presses. A **debouncer**
only accepts a new value once the (already-synchronized) input has been
*consistently* different from the current output for some minimum number
of consecutive cycles:

```verilog
always @(posedge clk) begin
    if (rst) begin
        clean_out <= 1'b0;
        counter   <= 0;
    end else if (noisy_in == clean_out) begin
        counter <= 0;                    // agrees with current output: no pending change
    end else if (counter == STABLE_CYCLES-1) begin
        clean_out <= noisy_in;           // disagreed for long enough: accept it
        counter   <= 0;
    end else begin
        counter <= counter + 1;          // disagrees, but not long enough yet
    end
end
```

Notice this is, structurally, another counter-with-reset-condition —
exactly Lecture 5's pattern, just gated by "does the input currently agree
with our last accepted output" instead of a fixed enable signal.

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

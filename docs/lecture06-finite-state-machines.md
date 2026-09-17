# Lecture 6 — Finite State Machines

## Concept

A finite state machine (FSM) is a register (holding "which state am I in")
plus two pieces of combinational logic: one computing the *next* state from
the current state and inputs, and one computing the *outputs* from either
the current state alone (**Moore machine**) or the current state and inputs
together (**Mealy machine**). This course uses Moore machines throughout —
outputs depend only on state — because they're simpler to reason about and
avoid a subtle Mealy hazard: since a Mealy output can react combinationally
to an input, a glitch on that input can glitch the output within the same
cycle.

The canonical 3-block structure:

```verilog
// 1. State register
always @(posedge clk) begin
    if (rst) state <= S_INIT;
    else     state <= next_state;
end

// 2. Next-state logic (combinational)
always @(*) begin
    case (state)
        S_INIT: next_state = condition ? S_A : S_INIT;
        S_A:    next_state = ...;
        default: next_state = S_INIT;
    endcase
end

// 3. Output logic (combinational, Moore: depends only on state)
always @(*) begin
    case (state)
        S_INIT: outputs = ...;
        S_A:    outputs = ...;
        default: outputs = ...;
    endcase
end
```

Always give the `case` a `default` in blocks 2 and 3 — beyond avoiding
latches (Lecture 3), it also defines sane behavior if the state register
ever lands in an unused encoding (which can genuinely happen on power-up
before reset, or from a radiation-induced bit flip in real hardware — this
is why real FSM designs treat "unreachable" states as a safety question,
not just a style question).

## Combining an FSM with a counter

Many real FSMs need to *wait N cycles* in a state before moving on — a
traffic light staying green for a fixed duration, a bus controller waiting
out a fixed number of wait-states. The clean way to do this is a counter
that only increments while the FSM is in that state, and resets back to 0
the moment the FSM leaves it — which is the same feedback-register idea as
Lecture 5's counter, just gated by "are we staying in the same state" (a
comparison between the state that's about to be latched and the one
currently held) instead of a fixed enable signal.

Working out exactly how to phrase that comparison — and what it should do
to the counter in each of the two cases — is part of this lecture's
exercise.

## Where this fits in MIPS / architecture

A **multi-cycle** (as opposed to single-cycle) MIPS control unit is *built*
as an FSM: fetch is one state, decode is another, execute/memory-access/
write-back are further states, and the sequence of states taken literally
depends on the instruction's opcode — some instructions need fewer states
than others. Even in a *pipelined* CPU (Lecture 11), hazard-handling logic
that decides "stall this cycle or not" is a small FSM. You'll build a
single-cycle control unit in Lecture 10 (all combinational, no FSM needed,
since single-cycle designs finish an instruction every clock), but
understanding FSMs now is what makes multi-cycle and pipelined control
(and much of real protocol logic — SPI, UART, DDR controllers) tractable
later.

## Electronics/VLSI note

The traffic-light exercise below takes a `ped_request` input as if it's
already a clean, synchronous signal. In reality, a pedestrian push-button is
a mechanical switch: pressing it produces a "bouncy," asynchronous
electrical signal, not a single clean transition, and it isn't synchronized
to your clock at all. Feeding that directly into an FSM's combinational
next-state logic can cause invalid state transitions or metastability
(Lecture 4's note). The correct fix — a synchronizer plus a debouncer — is
exactly Lecture 12's topic; we're deliberately deferring it so this lecture
can focus purely on FSM structure.

## Exercise

→ [`exercises/ex05`](../exercises/ex05) — build a 4-state traffic light
controller with a pedestrian-request input that can shorten (but not
eliminate) a green phase.

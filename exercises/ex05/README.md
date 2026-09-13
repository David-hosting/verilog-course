# Exercise 5 — Traffic-Light FSM

**Lecture:** 6 — Finite State Machines

## What you're building

In `src/traffic_light_fsm.v`:

```verilog
module traffic_light_fsm #(
    parameter GREEN_TIME     = 6,  // cycles a green phase lasts if not shortened
    parameter MIN_GREEN_TIME = 3,  // minimum cycles green must last regardless
    parameter YELLOW_TIME    = 2   // cycles a yellow phase always lasts
)(
    input            clk,
    input            rst,          // sync, forces state = NS_GREEN, timer = 0
    input            ped_request,  // pedestrian button (see rule below)
    output reg [1:0] ns_light,     // 2'b10=GREEN, 2'b01=YELLOW, 2'b00=RED
    output reg [1:0] ew_light
);
```

A Moore FSM with 4 states, cycling forever in this order:
`NS_GREEN -> NS_YELLOW -> EW_GREEN -> EW_YELLOW -> NS_GREEN -> ...`

Outputs per state (exact encoding: `GREEN=2'b10`, `YELLOW=2'b01`, `RED=2'b00`):

| State | `ns_light` | `ew_light` |
|---|---|---|
| `NS_GREEN`  | GREEN  | RED    |
| `NS_YELLOW` | YELLOW | RED    |
| `EW_GREEN`  | RED    | GREEN  |
| `EW_YELLOW` | RED    | YELLOW |

## Timing rule (implement exactly this)

Track a per-state cycle counter `timer` that starts at 0 the moment a state
is entered and increments by 1 every cycle spent in that state.

- **Yellow states** always last exactly `YELLOW_TIME` cycles — move to the
  next state when `timer` reaches `YELLOW_TIME - 1` (i.e. this is the
  `YELLOW_TIME`-th cycle in the state).
- **Green states** normally last `GREEN_TIME` cycles (same rule: transition
  when `timer` reaches `GREEN_TIME - 1`) — **unless** `ped_request` is
  asserted at a point where `timer` has already reached at least
  `MIN_GREEN_TIME - 1`, in which case the green phase ends on that cycle
  instead (transition happens one cycle later, same as the normal case).
  `ped_request` asserted *before* `timer` reaches `MIN_GREEN_TIME - 1` must
  be ignored — the green phase must never be shorter than `MIN_GREEN_TIME`
  cycles.
- The rule applies identically to both `NS_GREEN` and `EW_GREEN`.

This means: `green_done = (timer == GREEN_TIME-1) || (timer >= MIN_GREEN_TIME-1 && ped_request)`.

## What's tested

Using the default parameters (`GREEN_TIME=6, MIN_GREEN_TIME=3, YELLOW_TIME=2`):

- A full, undisturbed cycle through all 4 states with `ped_request=0` the
  entire time, checking `ns_light`/`ew_light` on every single cycle against
  the exact expected sequence and phase lengths.
- `ped_request` asserted early (before `timer` reaches `MIN_GREEN_TIME-1`)
  during a green phase: the phase must **not** be shortened.
- `ped_request` asserted right at `timer == MIN_GREEN_TIME-1`: the phase
  must end exactly on schedule for the shortened case.
- Reset applied mid-sequence: must immediately return to `NS_GREEN`, timer 0.

## Run it

```bash
bash scripts/run_exercise.sh ex05
```

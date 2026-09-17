// Exercise 5: traffic-light FSM with a pedestrian-request shortened green.

module traffic_light_fsm #(
    parameter GREEN_TIME     = 6,
    parameter MIN_GREEN_TIME = 3,
    parameter YELLOW_TIME    = 2
)(
    input            clk,
    input            rst,
    input            ped_request,
    output reg [1:0] ns_light,
    output reg [1:0] ew_light
);

    // TODO: this is a Moore FSM, built from the same 3-block structure as
    // the lecture note: (1) a clocked state register, (2) combinational
    // next-state logic, (3) combinational output logic based only on the
    // current state. Give the 4 phases and the 3 light colors names of
    // your own choosing (2 bits each is enough for both).
    //
    // The tricky part is timing each phase. You'll need something that
    // counts how long the FSM has been in its *current* state, and resets
    // whenever the state actually changes -- otherwise you can't tell a
    // state that just started from one that's been running for a while.
    // The exact conditions for when a green or yellow phase should end are
    // spelled out precisely in README.md -- implement those conditions
    // rather than re-deriving them.

endmodule

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

    // TODO: state encoding. Suggested:
    // localparam S_NS_GREEN = 2'b00, S_NS_YELLOW = 2'b01,
    //            S_EW_GREEN = 2'b10, S_EW_YELLOW = 2'b11;
    // localparam RED = 2'b00, YELLOW = 2'b01, GREEN = 2'b10;

    // TODO: reg [1:0] state, next_state; reg [31:0] timer;

    // TODO block 1: state + timer register, always @(posedge clk).
    //   if (rst): state <= S_NS_GREEN, timer <= 0
    //   else: state <= next_state
    //         timer <= (next_state == state) ? timer + 1 : 0

    // TODO block 2: next-state combinational logic, always @(*).
    //   Use the green_done / yellow_done formulas from the README.

    // TODO block 3: Moore output combinational logic, always @(*),
    //   based only on 'state' (see the table in the README).

endmodule

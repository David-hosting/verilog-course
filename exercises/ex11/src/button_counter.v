// Exercise 11: synchronizer, debouncer, and a debounced press counter.

module synchronizer(
    input  clk,
    input  async_in,
    output sync_out
);

    // TODO: exactly two flip-flops in series, each one just sampling the
    // previous one's output on the clock edge. sync_out comes from the
    // *second* one -- the first one is the one allowed to go metastable.

endmodule


module debouncer #(
    parameter STABLE_CYCLES = 4
)(
    input      clk,
    input      rst,
    input      noisy_in,
    output reg clean_out
);

    // TODO: you'll need a counter that tracks how long noisy_in has
    // disagreed with the current clean_out, uninterrupted. The moment
    // noisy_in agrees with clean_out again, that streak is over. Only once
    // the disagreement has lasted STABLE_CYCLES cycles in a row should
    // clean_out actually change to match noisy_in. Reset should clear
    // both clean_out and the counter.

endmodule


module button_edge_counter #(
    parameter STABLE_CYCLES = 4
)(
    input        clk,
    input        rst,
    input        async_button,
    output reg [7:0] press_count
);

    wire sync_out;
    synchronizer sync(.clk(clk), .async_in(async_button), .sync_out(sync_out));

    wire clean_out;
    debouncer #(.STABLE_CYCLES(STABLE_CYCLES)) debounce(
        .clk(clk), .rst(rst), .noisy_in(sync_out), .clean_out(clean_out)
    );

    // TODO: press_count should increase by exactly one each time
    // clean_out transitions from 0 to 1 -- not while it's simply *sitting*
    // at 1. Detecting a transition (as opposed to a level) needs comparing
    // a signal against what it was on the *previous* cycle -- that means
    // remembering one extra bit of history.

endmodule

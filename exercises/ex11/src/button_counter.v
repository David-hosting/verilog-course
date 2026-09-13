// Exercise 11: synchronizer, debouncer, and a debounced press counter.

module synchronizer(
    input  clk,
    input  async_in,
    output sync_out
);

    // TODO: reg [1:0] sync_ff; always @(posedge clk) sync_ff <= {sync_ff[0], async_in};
    // TODO: assign sync_out = sync_ff[1];

endmodule


module debouncer #(
    parameter STABLE_CYCLES = 4
)(
    input      clk,
    input      rst,
    input      noisy_in,
    output reg clean_out
);

    // TODO: a counter (width doesn't matter much for STABLE_CYCLES this
    // small -- e.g. reg [7:0] counter) plus an always @(posedge clk) block
    // implementing the rule from the lecture note / README:
    //   rst            -> clean_out <= 0, counter <= 0
    //   noisy_in==clean_out -> counter <= 0 (nothing pending)
    //   counter == STABLE_CYCLES-1 -> clean_out <= noisy_in, counter <= 0
    //   else -> counter <= counter + 1

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

    // TODO: reg clean_out_prev; always @(posedge clk) block updating it
    // (also handle rst), then a rising-edge pulse: clean_out && !clean_out_prev.
    // TODO: another always @(posedge clk) block: on rst, press_count <= 0;
    // else if (rising edge pulse), press_count <= press_count + 1.

endmodule

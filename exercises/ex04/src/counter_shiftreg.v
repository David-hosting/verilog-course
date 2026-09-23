// Exercise 4: up/down counter and bidirectional shift register.

module updown_counter8(
    input        clk,
    input        rst,
    input        load,
    input  [7:0] load_val,
    input        en,
    input        up_down,
    output reg [7:0] count
);

    // TODO: always @(posedge clk).
    // Priority: rst (-> 0) beats load (-> load_val, regardless of en)
    // beats en-gated count up/down. Otherwise hold.

    always @(posedge clk) begin
        if (rst) count <= 8'b0;
        else if (load) count <= load_val;
        else if (en) begin
            if (up_down) count <= count + 8'b1;
            else 
                count <= count - 8'b1;
        end 
        // else hold current value
    end

endmodule


module shift_reg8(
    input        clk,
    input        rst,
    input        en,
    input        load,
    input  [7:0] load_val,
    input        dir,
    input        serial_in,
    output reg [7:0] q
);

    // TODO: always @(posedge clk).
    // Priority: rst (-> 0) beats load (-> load_val, regardless of en)
    // beats en-gated shift. dir=1: shift left, new bit at LSB.
    // dir=0: shift right, new bit at MSB. Otherwise hold.

    always @(posedge clk) begin
        if (rst) q <= 8'b0;
        else if (load) q <= load_val;
        else if (en) begin
            if (dir) q <= {q[6:0], serial_in};
            else 
                q <={serial_in, q[7:1]};
        end 
        // else hold
    end 

endmodule

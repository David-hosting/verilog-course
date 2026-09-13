# Lecture 5 — Registers, Counters, Shift Registers

## Concept: a counter is a register plus an adder

You already have both pieces. A counter is nothing more than a register
whose next value is computed by feeding its own current output back through
an incrementer (or decrementer):

```verilog
always @(posedge clk) begin
    if (rst)      count <= 8'b0;
    else if (load) count <= load_val;
    else if (en)   count <= up_down ? count + 1'b1 : count - 1'b1;
end
```

This is exactly the feedback-loop idea from Lecture 4, just with a
combinational adder in the loop instead of a plain wire. Priority matters
here the same way it did for the flip-flop: decide up front what wins when
multiple control signals are asserted at once (this design: `rst` > `load` >
`en`-gated count), and be consistent.

## Concept: shift registers

A shift register moves bits sideways every clock edge instead of forward
from a computed function. Two flavors matter:

- **Serial-in, parallel-out (SIPO)**: one new bit comes in each cycle,
  shifted in from one end; after N cycles you've accumulated N serial bits
  as one N-bit parallel word. This is literally how UART/SPI receivers
  reconstruct a byte from a serial line, and it's a very common way to get
  data out of a serial ADC (analog-to-digital converter) one bit per clock.
- **Parallel-in, serial-out (PISO)**: the reverse — load a full word in one
  cycle, then shift bits out one at a time. This is how a serial DAC
  (digital-to-analog converter) input, or a UART transmitter, is typically
  driven.

In this exercise you'll build one register that supports *both* directions
plus a parallel load, since the underlying flip-flop array is the same
either way — only the combinational logic feeding each bit's `d` input
changes (from a neighbor's `q value` instead of from a computed sum).

```verilog
always @(posedge clk) begin
    if (rst)       q <= 8'b0;
    else if (en) begin
        if (load)  q <= load_val;
        else if (dir) q <= {q[6:0], serial_in}; // shift left, new bit at LSB side
        else          q <= {serial_in, q[7:1]}; // shift right, new bit at MSB side
    end
end
```

## Where this fits in MIPS / architecture

The **program counter (PC)** in a MIPS CPU is precisely the up/down counter
you're about to build, specialized: it increments by 4 every cycle (each
instruction is 4 bytes), *except* when a branch or jump is taken, in which
case it's **loaded** with a new target address instead — exactly the
`load`/`load_val` path in the module above. You'll instantiate a PC register
built on this exact pattern when you build the datapath in Lecture 9.

Shift registers appear less directly inside the CPU's core datapath, but
they're the standard mechanism any real system uses to get data in or out
over a narrow (often 1-bit) serial interface to peripherals — which is how
a CPU talks to most real-world analog/digital converters, sensors, and
displays outside the chip.

## Electronics/VLSI note

A ripple counter (each bit toggling off the previous bit's output, rather
than a synchronous design like the one above) is smaller but suffers from
the same "ripple" delay problem as Lecture 2's ripple-carry adder, made
worse: the bits don't even update on the same clock edge, so downstream
logic can briefly see nonsense intermediate values. All the counters and
shift registers in this course are **synchronous** — every flip-flop shares
the exact same clock — which is standard practice in real digital design
specifically to avoid these hazards.

## Exercise

→ [`exercises/ex04`](../exercises/ex04) — build an up/down counter and a
bidirectional shift register with parallel load.

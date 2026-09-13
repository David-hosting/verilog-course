# Lecture 7 — Memory Modeling: RAM/ROM/Register Files

## Concept: an array of registers is just... an array

Verilog lets you declare an array of vectors directly:

```verilog
reg [31:0] mem [0:31];   // 32 entries, each 32 bits wide
```

`mem[5]` is a full 32-bit word. Combined with what you already know (a
`reg` assigned inside `always @(posedge clk)` is a real flip-flop bank),
this is literally how RAM, ROM, and register files are modeled in RTL —
there's no special "memory" keyword or construct beyond a declared array
plus the read/write logic you write around it.

## Synchronous write, combinational read

A register file (and most on-chip RAM) uses this pattern:

```verilog
module regfile32(
    input         clk,
    input         we,          // write enable
    input  [4:0]  ra1, ra2,    // read address ports (5 bits = 32 registers)
    input  [4:0]  wa,          // write address
    input  [31:0] wd,          // write data
    output [31:0] rd1, rd2     // read data
);
    reg [31:0] regs [0:31];

    // Write: synchronous, one clock edge, like any register.
    always @(posedge clk) begin
        if (we)
            regs[wa] <= wd;
    end

    // Read: combinational, no clock involved at all — the read address
    // directly selects which stored word appears on the output, this cycle.
    assign rd1 = regs[ra1];
    assign rd2 = regs[ra2];
endmodule
```

Why asymmetric? A **write** changes stored state, so it must be
synchronized to a clock edge exactly like any other flip-flop — otherwise
"when exactly does the write happen" has no well-defined answer. A **read**
doesn't change anything; it just needs to present whatever is *already*
stored at that address, so it can be pure combinational logic (a big mux,
conceptually — `regs[ra1]` is "select entry number `ra1` out of 32", which
is exactly the mux idea from Lecture 3, just with 32 inputs instead of 4).

This combinational-read/synchronous-write split is exactly how a real MIPS
register file behaves: within a single clock cycle, an instruction can read
two source registers *and* have those values immediately available to the
ALU, with no clock edge in between — while any write from a *previous*
instruction's result only becomes visible starting from a clean clock edge.

## A read-during-write edge case

What should `regs[ra1]` return if `ra1` happens to equal `wa` in the same
cycle that `we` is asserted — reading and writing the same register at
once? With the pattern above (nonblocking write, combinational read), the
read sees the **old** value during that cycle — the write hasn't taken
effect yet (nonblocking assignments update at the end of the time step).
This matches real hardware and real MIPS semantics: an instruction reading
register `$t0` while a *different*, earlier instruction's write to `$t0`
is landing this same cycle will only see the new value starting next cycle
— unless the CPU has special *forwarding* hardware to fix exactly this case
(which real pipelined MIPS designs do — you'll meet forwarding/hazards in
Lecture 11).

## Where this fits in MIPS / architecture

This lecture's register file **is** the MIPS register file — 32 general
purpose registers (`$0`-`$31`), each 32 bits, with the hardware quirk that
register `$0` is hardwired to the value zero: reading it always returns 0,
and writes to it are silently discarded. This isn't a software convention
enforced by an assembler — it's built into the hardware, and you'll build
that exact behavior into your register file in this exercise. Having a
constant zero available "for free" in every ALU operation and comparison
is a deliberate MIPS ISA design choice that saves an instruction wherever
code would otherwise need to compare against or move a literal 0.

## Electronics/VLSI note

A `reg [31:0] mem [0:31]` array like this synthesizes very differently
depending on its size and port count. A small, few-port array like a
32-entry register file typically becomes an actual bank of flip-flops with
big muxes on the read side (what you're conceptually building here). A
large single/dual-port memory (thousands of entries) instead typically maps
to a dedicated on-chip SRAM macro — a hand-optimized, dense analog/digital
circuit block from the process's IP library, because a flip-flop-based
implementation of, say, a 64KB cache would be enormous and power-hungry.
Real chips make this size-dependent tradeoff explicitly; for the register
file's small scale, flip-flops are exactly right.

## Exercise

→ [`exercises/ex06`](../exercises/ex06) — build a 32×32 MIPS-style register
file, with `$zero` behavior.

# Lecture 9 — Datapath Design

## Concept: a datapath is composition, not new logic

Every individual piece you need for a single-cycle CPU datapath already
exists from earlier lectures: a register with load (Lecture 5, for the
program counter), a register file (Lecture 7), an ALU (Lecture 8), muxes
(Lecture 3), and a memory array (Lecture 7's pattern, for instruction and
data memory). Building a datapath is almost entirely about **wiring these
together correctly, with muxes selecting the right signal at the right
point** — very little genuinely new logic gets written at this stage. This
is the payoff for having built each piece carefully and tested it in
isolation: bugs at this stage are almost always wiring bugs, not
arithmetic bugs.

## The single-cycle MIPS datapath, piece by piece

1. **Instruction fetch**: the PC addresses instruction memory
   (combinational read, like the register file), producing the 32-bit
   instruction. `PC+4` is computed by a plain adder, in parallel with
   everything else this cycle — every instruction is 4 bytes, so this is
   always "the next instruction" unless a branch overrides it.
2. **Instruction fields**: pure bit-slicing (no logic at all) pulls apart
   the fixed-position fields — `opcode = instr[31:26]`,
   `rs = instr[25:21]`, `rt = instr[20:16]`, `rd = instr[15:11]`,
   `imm16 = instr[15:0]`, `funct = instr[5:0]` — the same fixed layout for
   every instruction, which is precisely why MIPS is easy to build
   hardware for: the register file's read-address ports can be wired
   directly to fixed instruction bit positions with no decoding needed.
3. **Register read**: `rs` and `rt` feed the register file's two read
   ports — both source operands are available combinationally, same cycle.
4. **Sign extension**: the 16-bit immediate field, used by `lw`/`sw`/`addi`
   as a signed offset/constant, must be widened to 32 bits, replicating its
   sign bit (`instr[15]`) into the upper 16 bits — not zero-padding, which
   would corrupt negative immediates.
5. **ALU operand mux (`ALUSrc`)**: the ALU's second operand is either the
   register file's second read data (R-type instructions) or the
   sign-extended immediate (`lw`/`sw`/`addi`) — a single 2-to-1 mux,
   exactly Lecture 3's `mux2to1`.
6. **ALU**: computes the result — arithmetic for R-type/`addi`, an address
   for `lw`/`sw` (base register + offset), or a subtraction for `beq`
   (checking equality via the `zero` flag).
7. **Data memory**: `lw`/`sw` read/write at the address the ALU just
   computed; every other instruction ignores this stage entirely (the
   memory is still physically there and "active," but its output is
   simply not selected downstream).
8. **Write-back mux (`MemtoReg`)**: the value written back to the register
   file is either the ALU result (most instructions) or the value just
   read from data memory (`lw` only) — another 2-to-1 mux.
9. **Destination register mux (`RegDst`)**: the register file's *write*
   address is either `rt` (`lw`/`addi` — the I-type destination field) or
   `rd` (R-type instructions) — another 2-to-1 mux.
10. **Next-PC logic**: normally `PC+4`, but if the instruction is `beq`
    *and* the ALU's `zero` flag is set (operands were equal), the next PC
    is instead the **branch target**: `PC+4 + (sign-extended immediate
    << 2)` (shifted left 2 bits because the offset counts *instructions*,
    each 4 bytes, not bytes). One more 2-to-1 mux, selected by
    `Branch AND Zero`.

Every one of those "mux" decisions above is driven by a **control signal**
— `RegDst`, `Branch`, `MemRead`, `MemtoReg`, `MemWrite`, `ALUSrc`,
`RegWrite`, plus the ALU's own operation code. In this exercise, you'll
take those signals as direct module inputs (as if some external circuit
already computed them correctly) — Lecture 10 is where you build the
circuit that actually generates them from the instruction's opcode and
funct fields.

## Where this fits in MIPS / architecture

This lecture *is* the classic single-cycle MIPS datapath from Patterson &
Hennessy, almost unchanged. If you've seen the datapath diagram from that
book (or an equivalent architecture course), every box and every mux on it
maps directly onto a piece of this exercise.

## Electronics/VLSI note

Every path through this datapath — PC through instruction memory through
register file through ALU through data memory through the write-back mux
back to the register file — is a single combinational chain that must
fully settle **within one clock period**, because a single-cycle design
finishes one entire instruction per clock edge. This is precisely why
single-cycle CPUs are slow in practice: the clock period is dictated by
the *slowest* instruction's path (typically `lw`, which touches every
stage), even though most instructions (like `and` or `add`) could finish
much faster. This observation — different instructions have very different
critical-path lengths, but a single-cycle design forces one clock period to
fit the worst case — is the entire motivation for pipelining, which you'll
meet in Lecture 11.

## Exercise

→ [`exercises/ex08`](../exercises/ex08) — wire a single-cycle MIPS datapath
together from a provided register file, ALU, and instruction/data memory.

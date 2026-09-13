# Lecture 10 — Control Unit Design

## Concept: decoding an instruction into a control signal bundle

Lecture 9's datapath took `reg_dst`, `branch`, `mem_to_reg`, `alu_control`,
and the rest as plain inputs, as if something else already knew the right
values. That "something else" is the **control unit**: a purely
combinational circuit whose only job is `opcode, funct -> control signals`.
No clock, no state — just decoding.

## Two-level decoding: main decoder + ALU decoder

Rather than one giant `case` mapping every `(opcode, funct)` combination
directly to every control signal, the classic MIPS single-cycle design
(and this exercise) splits the job in two:

- **Main decoder**: looks at `opcode` alone, and sets every control signal
  *except* the exact ALU operation — for that, it only outputs a coarse
  2-bit `ALUOp` hint:
  - `ALUOp = 00` → "this instruction just needs an add" (`lw`, `sw`,
    `addi` all compute an address or a sum this way)
  - `ALUOp = 01` → "this instruction needs a subtract" (`beq`, to test
    equality via the zero flag)
  - `ALUOp = 10` → "this is an R-type instruction — look at `funct` to
    know which ALU operation"
- **ALU decoder**: turns `ALUOp` (and, when `ALUOp=10`, `funct`) into the
  actual 4-bit `alu_control` code the ALU from Lecture 8 expects.

Why split it this way instead of one flat table? Two reasons, both real
engineering, not just style:

1. **`funct` only matters for R-type instructions.** For every other
   opcode, the ALU operation is already fully determined by the
   instruction *type* alone (an address calculation is always an add; a
   branch comparison is always a subtract) — there's no reason to even
   look at `funct` for those, and folding it into a shared table would
   make every row repeat "add" or "subtract" needlessly.
2. **It mirrors the real MIPS instruction format.** `opcode` alone
   distinguishes instruction *categories*; `funct` only exists to
   distinguish *within* the R-type category (since all R-type instructions
   share `opcode = 000000`). Structuring the decoder in two levels that
   mirror the instruction format is easier to verify against a real ISA
   reference and easier to extend later (adding a new R-type instruction
   only touches the ALU decoder; adding a new instruction *format* only
   touches the main decoder).

## Where this fits in MIPS / architecture

This is, almost verbatim, Figure 4.14 (main decoder) and Figure 4.13 (ALU
decoder) from Patterson & Hennessy's single-cycle MIPS chapter — this
lecture's exercise asks you to implement exactly that two-level structure,
extended slightly to also cover `addi`, `sll`, and `srl` (which the
textbook's minimal example often omits, but which your Lecture 8 ALU
already supports). Once this exercise is done, you have every piece needed
for a real, working CPU: Lecture 13's capstone is *purely* wiring this
control unit's outputs into Lecture 9's datapath's control inputs — no new
logic gets written there at all.

## Electronics/VLSI note

A combinational decoder like this one is a direct, real-world case of the
mux-tree/case-statement synthesis discussion from Lecture 3 and Lecture 8:
`opcode` has only a handful of legal values in this design (5, plus
"anything else is don't-care/undefined behavior"), so a synthesis tool can
implement this compactly — but only if you give it a `default` case (as
always). An instruction with an opcode this control unit doesn't recognize
is exactly the "unreachable state" scenario from Lecture 6's FSM
discussion: real hardware must still do *something* well-defined if it
happens (whether from a corrupted instruction fetch or a genuinely
unsupported opcode), even though your program should never intentionally
produce one.

## Exercise

→ [`exercises/ex09`](../exercises/ex09) — build a two-level MIPS control
unit (main decoder + ALU decoder).

# Lecture 1 — Intro: HDLs, Digital Logic Foundations, Toolchain

No exercise attached to this one — it's the mental model and setup you need
before anything else in this course will make sense.

## 1. Verilog is not a programming language

This is the single most important idea in this whole course, and the one
that trips up everyone coming from software.

When you write:

```verilog
module example(input a, input b, output c, output d);
    assign c = a & b;
    assign d = a | b;
endmodule
```

`c` and `d` are **not computed in order**. There is no "first line runs, then
second line runs." Both `assign` statements describe two pieces of *physical
wire and logic gates* that exist simultaneously, all the time, continuously
recomputing. Verilog **describes hardware** — a fixed, static graph of gates,
wires, and registers. Simulation just replays that hardware's behavior over
time; synthesis turns it into an actual netlist of standard cells that a
fab will etch into silicon (or a tool will map onto an FPGA's LUTs and flip-flops).

Every line of RTL (register-transfer level) Verilog you write should map, in
your head, to "some real piece of silicon." If you can't picture what
hardware a line of your code would become, that's a sign you've slipped into
thinking of it as software.

## 2. Two fundamentally different kinds of logic

Digital design has exactly two building blocks, and almost everything in
this course is one or the other:

- **Combinational logic** — output depends only on the *current* input
  values. No memory. A NAND gate, a multiplexer, an adder. In Verilog:
  `assign` statements, or `always @(*)` blocks.
- **Sequential logic** — output depends on current input *and* history
  (state), captured in flip-flops that sample on a clock edge. A counter, a
  register, an FSM. In Verilog: `always @(posedge clk)` blocks.

Almost every bug you'll write in this course comes from blurring this line —
e.g. writing combinational logic that accidentally infers a latch (a
half-sequential element you didn't mean to create) because an `if` inside an
`always @(*)` block doesn't cover every input combination.

## 3. From transistors to gates (why this isn't just abstract)

A NAND gate isn't magic — in CMOS (Complementary Metal-Oxide-Semiconductor,
the fabrication technology behind essentially every digital chip made
today), it's built from exactly 4 transistors: two PMOS pulling the output
high, two NMOS pulling it low, wired so the two networks are never both
"on" and never both "off" for a valid input. This CMOS pattern — a
pull-up network of PMOS and a pull-down network of NMOS that are logical
complements of each other — is called **static CMOS logic**, and it's the
basis of standard-cell VLSI design: every gate in a chip's cell library
(`AND2`, `NAND2`, `INV`, `MUX2`, ...) is one of these transistor networks,
pre-characterized for delay, area, and power, and a synthesis tool just
picks cells from that library to implement your Verilog.

Two consequences that matter for real designs (and that we'll come back to):

- **Propagation delay**: signals don't move instantly. Every gate has a
  delay (transistors charging/discharging capacitance), so a chain of gates
  has a delay that's the sum along the longest ("critical") path. This is
  why a ripple-carry adder (Lecture 8) is slower than a carry-lookahead
  adder even though both are "just AND/OR/XOR gates" — the *path length*
  differs.
- **A gate can only drive so much**: fan-out (how many other gate inputs one
  output feeds) and wire capacitance add delay too. This is a large part of
  why VLSI floorplanning and buffering are entire disciplines.

You won't need transistor-level detail to write Verilog, but every time this
course says "this design is faster" or "this one has a shorter critical
path," this is the physical reason why.

## 4. Structural vs. behavioral modeling

Verilog lets you describe hardware two ways:

**Structural** — you explicitly wire together gate/module instances, like a
schematic in text form:

```verilog
module and_or(input a, input b, input c, output y);
    wire ab;
    and g1(ab, a, b);
    or  g2(y, ab, c);
endmodule
```

**Behavioral** — you describe *what* the output should be, and let the
synthesis tool figure out the gates:

```verilog
module and_or(input a, input b, input c, output y);
    assign y = (a & b) | c;
endmodule
```

Both produce (roughly) the same hardware. Lecture 2 makes you build things
structurally, gate by gate, specifically so the mapping from Verilog to
physical logic stops being abstract. From Lecture 3 onward we use behavioral
style, which is how real designs are written — but you'll understand what it
compiles down to.

## 5. Where MIPS fits in

Throughout this course, every new construct gets tied to a piece of a real
CPU: the classic 5-stage MIPS pipeline from Patterson & Hennessy's *Computer
Organization and Design* (if you have access to that book, it's an excellent
companion to this course — this course builds a simplified version of
exactly the CPU it describes). By Lecture 9 you'll have a register file and
an ALU. By Lecture 13 you'll have wired them, plus a control unit and
memory, into a running CPU that executes real machine code. Nothing here is
hypothetical "toy" logic disconnected from why it matters.

## 6. Toolchain

Two tools, both already installed on this machine:

- **`iverilog`** — compiles Verilog into a simulation executable.
- **`vvp`** — runs that executable.
- **`gtkwave`** — views waveforms (`.vcd` files) your testbenches dump, so
  you can see signals over time instead of just reading `$display` text.

The basic manual flow (you won't normally type this by hand — `scripts/run_exercise.sh`
does it for you — but you should understand what it's doing):

```bash
iverilog -g2012 -o sim.out my_design.v my_testbench.v
vvp sim.out
gtkwave dump.vcd   # optional, if the testbench dumped one
```

`-g2012` tells iverilog to accept SystemVerilog-2012 syntax extensions used
in a few of the testbenches (things like `logic` are avoided, but some minor
conveniences are used).

## 7. How grading works in this course

Every exercise's `test/` folder contains a self-checking testbench: it drives
your module with a set of inputs (some exhaustive, some directed at tricky
corner cases, some randomized) and compares the output against an
independently-computed expected value. At the end it prints either:

```
RESULT: PASS (64/64 checks)
```

or

```
[FAIL] check 14: op=SUB a=00001011 b=00000110 -> expected result=00000101, got=00000100
RESULT: FAIL (63/64 checks passed)
```

Failures tell you *what* was wrong (which inputs, what was expected vs. what
you produced) without telling you *why* — that diagnosis is the point of the
exercise.

You're ready for Lecture 2.

# Lecture 1 — Intro: HDLs, Digital Logic Foundations, Toolchain

No exercise attached to this one — it's the syntax literacy, mental model,
and setup you need before anything else in this course will make sense.
This lecture is longer than the others because it also has to teach you to
*read* the language, not just the ideas — take your time with it.

## 1. Verilog syntax, from zero

If you've never seen Verilog before, here is everything you need to be able
to *read* the code in this course. You will not remember all of this after
one pass — treat it as a reference to come back to whenever a later
lecture's code snippet uses something unfamiliar.

### 1.1 The shape of a module

Every piece of hardware you describe lives inside a `module ... endmodule`
block. Unlike most programming languages, there's no function call, no
`return` — a module is a named box with a fixed set of connection points
(ports), and a body that describes what's inside the box.

```verilog
module and_gate(
    input  a,
    input  b,
    output y
);
    assign y = a & b;
endmodule
```

Reading this line by line:

- `module and_gate( ... );` — declares a box named `and_gate` with the ports
  listed inside the parentheses. The semicolon at the end is required.
- `input a, input b` — two 1-bit signals that come *into* this box from
  whoever uses it.
- `output y` — one 1-bit signal this box drives *out*.
- `assign y = a & b;` — the body: a continuous statement wiring `y` to the
  AND of `a` and `b` (`&` is bitwise AND — see the operator table below).
  Every statement ends with a semicolon.
- `endmodule` — closes the box. No semicolon after this one.

To use (**instantiate**) that box elsewhere:

```verilog
and_gate my_gate1(.a(signal1), .b(signal2), .y(result));
```

This creates one instance of `and_gate`, named `my_gate1` (instance names
are arbitrary, like a variable name — pick anything descriptive), and wires
its `a` port to `signal1`, its `b` port to `signal2`, and its `y` port to
`result`. `.portname(signal)` is **named port connection** — the safest
style, because it doesn't depend on remembering the module's port *order*,
only its port *names*. Every module you build in this course should be
instantiated this way. (You'll also see a shorter, order-dependent form,
`and_gate my_gate1(signal1, signal2, result);`, used only for Verilog's
built-in primitive gates like `and`/`or`/`xor` in Lecture 2, where the
convention — output first, then inputs — is fixed and universal.)

### 1.2 `wire` vs. `reg`

Every signal declared inside a module (that isn't a port) is one of two
kinds:

- **`wire`** — a plain connection with no memory. You drive a wire with
  `assign`, or by connecting it to a port of an instantiated module. A
  `wire` cannot be assigned inside an `always` block.
- **`reg`** — despite the name, this does **not** necessarily mean a
  physical register/flip-flop! It just means "a signal assigned inside an
  `always` block." If that `always` block is `always @(posedge clk)`, a
  `reg` really does become a flip-flop. If it's `always @(*)` (purely
  combinational), the exact same `reg` keyword just becomes plain
  combinational logic with no memory at all — the keyword is a leftover of
  Verilog's history, and it trips up almost everyone at first. The rule is
  purely mechanical: **if you assign a signal inside any `always` block,
  declare it `reg`; otherwise, declare it `wire`** (or leave it as the
  default `wire` type, which is what an `output` port is unless declared
  otherwise).

You'll see this distinction directly in module headers throughout this
course, e.g. `output reg [3:0] result` (a 4-bit signal that gets assigned
inside an `always` block) vs. `output [3:0] sum` (assigned via `assign`, or
just wired straight through to something else).

### 1.3 Bit widths, literals, and vectors

A signal can be a single bit or a **vector** (a bus) of many bits:

```verilog
wire        single_bit;
wire [7:0]  a_byte;       // 8 bits, indices 7 (MSB) down to 0 (LSB)
wire [31:0] a_word;       // 32 bits
```

`[7:0]` means "bit 7 down to bit 0" — 8 bits total, with bit 7 as the most
significant. You can pick out a sub-range: `a_byte[3:0]` is its low nibble,
`a_byte[7]` is just its top bit.

**Number literals** use the format `<size>'<base><value>`:

```verilog
4'b1010   // 4 bits, binary, value 10 decimal
8'hFF     // 8 bits, hexadecimal, value 255 decimal
8'd25     // 8 bits, decimal, value 25
3'o7      // 3 bits, octal, value 7
```

`b`=binary, `h`=hex, `d`=decimal, `o`=octal. The size prefix is the number
of *bits*, not digits. If you omit the size (`'hFF`) Verilog picks a
default width (usually 32 bits) — always write the size explicitly in this
course to avoid surprises. A literal bit can also be `x` (unknown/don't
care) or `z` (high-impedance/undriven) — you'll see these show up in
simulation output for a signal nothing is driving yet.

### 1.4 Operators

| Category | Operators | Notes |
|---|---|---|
| Bitwise | `&` `\|` `^` `~` `^~`/`~^` | AND, OR, XOR, NOT, XNOR — applied bit-by-bit across a whole vector at once. |
| Logical | `&&` `\|\|` `!` | Treat their whole operand as one true/false value (nonzero = true). Used in `if` conditions, not for combining bits of a bus. |
| Reduction | `&x` `\|x` `^x` | Unary prefix form: ANDs (or ORs, or XORs) together *all* the bits of vector `x` into a single bit. `^x` (reduction XOR) computes parity. |
| Arithmetic | `+` `-` `*` `/` `%` | Ordinary binary arithmetic on vectors, treated as unsigned unless declared `signed`. |
| Comparison | `==` `!=` `<` `>` `<=` `>=` | `==`/`!=` treat `x`/`z` bits as "unknown → result unknown"; testbenches instead use `===`/`!==` (below) to get a definite true/false even across `x`/`z`. |
| Case equality | `===` `!==` | Exact bit-for-bit comparison, including `x`/`z`. **Only used in testbenches/simulation**, never in synthesizable design code. |
| Concatenation | `{a, b, c}` | Glues signals together into one wider vector, left-to-right = MSB-to-LSB. `{1'b0, a}` prepends a zero bit to `a`. |
| Replication | `{n{a}}` | Repeats `a` n times and concatenates the copies, e.g. `{4{2'b01}}` = `8'b01010101`. |
| Ternary | `cond ? a : b` | "If cond, then a, else b" — as a single expression, usable inside `assign` or anywhere else an expression is expected. |
| Shift | `<<` `>>` | Logical shift left/right, filling with zeros. |

A subtlety worth internalizing now because it will bite you later:
`<=` is **both** the "less-than-or-equal" comparison operator **and** the
nonblocking assignment operator — Verilog tells them apart purely from
context (inside an `if` condition vs. as a statement's assignment
operator). Lecture 4 covers nonblocking assignment.

### 1.5 `if`/`else` and `case`, inside `always` blocks

```verilog
always @(*) begin
    if (sel == 2'b00)
        y = a;
    else if (sel == 2'b01)
        y = b;
    else
        y = c;
end
```

`begin ... end` groups multiple statements into one block, the Verilog
equivalent of `{ ... }` in C-like languages — required whenever an
`always`/`if`/`else` body has more than one statement. `case` is often
cleaner than a long `if`/`else if` chain for multi-way branches:

```verilog
always @(*) begin
    case (op)
        2'b00: y = a + b;
        2'b01: y = a - b;
        2'b10: y = a & b;
        default: y = 4'b0;
    endcase
end
```

Always include a `default` — this becomes very important starting in
Lecture 3.

### 1.6 Comments and general punctuation

`// a comment to end of line` and `/* a comment spanning multiple lines */`
work exactly like C/C++/Java. Every statement ends in a semicolon; `module`,
`endmodule`, `begin`, `end`, `case`, `endcase` never do. Whitespace and
indentation are not meaningful to the compiler (unlike Python) — this
course's indentation is purely for human readability, matching what you'll
see in essentially all real-world Verilog.

### 1.7 Reading a testbench (you won't need to write these, but you'll want to read them)

Every exercise's `test/*.v` file is itself a Verilog module — the "device
under test" (DUT) instantiated inside it, with the testbench driving its
inputs and checking its outputs. A few constructs are testbench-only
(never used in synthesizable design code):

- `initial begin ... end` — a block that runs *once*, starting at
  simulation time 0 (as opposed to `always`, which keeps re-triggering).
  This is where testbenches set up stimulus and run checks, since a
  testbench needs to run its sequence exactly once, not repeat forever.
- `#5` — a delay statement: "wait 5 time units before continuing to the
  next statement." Real hardware has no such concept (it doesn't "wait");
  this only makes sense inside a simulation.
- `$display("format string", args...)` — prints to the console, using
  C-`printf`-style format specifiers: `%b` binary, `%d` decimal, `%h` hex,
  `%0d`/`%0b` (the `0` means "no leading padding"), `%s` for a
  string/label.
- `$dumpfile(...)` / `$dumpvars(...)` — tell the simulator to record signal
  waveforms to a `.vcd` file, viewable in GTKWave.
- `$finish` — ends the simulation.
- `$random` — returns a pseudo-random 32-bit value, used for the randomized
  test vectors you'll see in several exercises.

You now have enough syntax to read (and, with the TODO comments in each
skeleton file, to write) every exercise in this course. The rest of this
lecture is the conceptual model — read it once now, but expect it to click
more fully once you're actually looking at gates in Lecture 2.

## 2. Verilog is not a programming language

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

## 3. Two fundamentally different kinds of logic

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

## 4. From transistors to gates (why this isn't just abstract)

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

## 5. Structural vs. behavioral modeling

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

## 6. Where MIPS fits in

Throughout this course, every new construct gets tied to a piece of a real
CPU: the classic 5-stage MIPS pipeline from Patterson & Hennessy's *Computer
Organization and Design* (if you have access to that book, it's an excellent
companion to this course — this course builds a simplified version of
exactly the CPU it describes). By Lecture 9 you'll have a register file and
an ALU. By Lecture 13 you'll have wired them, plus a control unit and
memory, into a running CPU that executes real machine code. Nothing here is
hypothetical "toy" logic disconnected from why it matters.

## 7. Toolchain

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

## 8. How grading works in this course

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

# Getting Started with BASIC6502

## Prerequisites

- **Godot 4.x** (4.0 or later) — Download from [godotengine.org](https://godotengine.org/download)
- Works on **macOS**, **Windows**, and **Linux**

## Installation

1. Install Godot (via Homebrew on Mac: `brew install --cask godot`, or download directly)
2. Clone or download this project
3. Open the Godot editor
4. Click **Import** and select the `project.godot` file in this directory
5. Click **Import & Edit**

## Running the Project

### From the Godot Editor
1. Open the project in Godot
2. Press **F5** (or click the Play button) to run

The application starts in **fullscreen** with a retro CRT terminal. The mouse cursor is hidden by default — move the mouse to reveal it, and it hides again after 3 seconds.

### From the Command Line
```bash
godot /path/to/mygodot/project.godot
```

## Running the Regression Tests

The project includes a comprehensive test suite. To run it:

```bash
godot --headless --script res://tests/test_regression.gd /path/to/mygodot/project.godot
```

The test suite validates:
- **Memory Bus**: Read/write, word operations, I/O ports, reset
- **6502 CPU**: All addressing modes, load/store, arithmetic (ADC/SBC), logical (AND/OR/EOR), shifts (ASL/LSR/ROL/ROR), comparisons (CMP/CPX/CPY), branches, stack operations, jumps/subroutines, transfers, flag instructions, overflow detection, page boundary bugs
- **BASIC Interpreter**: PRINT, variables, arithmetic, IF/THEN/ELSE, FOR/NEXT (including nested loops with GOTO), GOSUB/RETURN, built-in functions (INT, ABS, SQR, SGN, SIN, COS), string functions (LEFT$, RIGHT$, MID$, LEN), arrays, READ/DATA, POKE/PEEK, boolean logic, comparison operators, ON GOTO, colon statement separator
- **Computer Integration**: End-to-end BASIC program execution with 6502 CPU

## Your First BASIC Program

When the terminal opens, type directly:

```
PRINT "HELLO WORLD"
```

Press Enter. You should see `HELLO WORLD` printed on screen.

### Entering a Program

Type lines with line numbers to build a program:

```
10 PRINT "HELLO"
20 PRINT "WORLD"
30 END
```

Type `LIST` to see your program, `RUN` to execute it.

### Running with Parameters

```
RUN              → start from first line
RUN 20           → start at line 20
RUN N=10         → set N=10, then run
RUN 20, N=10     → start at line 20, set N=10
```

### Loading a Demo

```
DEMO                     → lists all demos
DEMO mandelbrot          → loads the Mandelbrot set demo
DEMO PRIMENUMS 100       → finds first 100 primes
DEMO PI 1000             → calculates pi with 1000 terms
RUN                      → runs the loaded demo
```

### Saving and Loading Programs

```
SAVE MYPROG              → save program as MYPROG.bas
LOAD MYPROG              → load MYPROG.bas
DIR                      → list saved programs with sizes
SCRATCH MYPROG           → delete MYPROG.bas (or DELETE MYPROG)
RENAME OLD NEW           → rename a saved file
```

### Deleting a Program Line

Type the line number alone to delete it: `10` deletes line 10.

### Listing Specific Lines

```
LIST                     → show all lines
LIST 30                  → show only line 30
LIST 10 100              → show lines 10 through 100
```

### Using the 6502 CPU Directly

You can write values to memory and read them back:

```
POKE 1000, 42
PRINT PEEK(1000)
```

Type `CPU` to see the current state of the 6502 processor registers.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| F1 | Show help |
| F3 | Toggle System Settings panel |
| F4 | Cycle CPU clock (0.5/1/10 MHz) |
| F5 | Run program |
| F6 | Start/stop video recording |
| F7 | Cycle baud rate (300/1200/2400/9600/14400) |
| F8 | Cycle font |
| F9 | Take screenshot |
| F10 | Full system reset |
| Up Arrow | Previous command in history |
| Down Arrow | Next command in history |
| Escape | Exit monitor mode |

## What You'll See

- A retro green-on-black terminal interface with CRT effects
- A "Hacker Computer Company" boot animation with BIOS POST
- CRT warm-up: screen starts dim and distorted, gradually settling over ~2 minutes
- A status bar showing live 6502 CPU register values (A, X, Y, SP, PC, flags)
- A text input area at the bottom for entering BASIC commands
- The mouse cursor is hidden; move the mouse to show it
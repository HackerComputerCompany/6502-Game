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

### From the Command Line
```bash
godot /path/to/mygodot/project.godot
```

## Running the Regression Tests

The project includes a comprehensive test suite. To run it:

1. In the Godot editor, go to **Project > Project Settings > Autoload**
2. Add `res://tests/test_regression.gd` as an autoload (optional, for editor testing)
   
Or run from the command line:
```bash
godot --headless --script res://tests/test_regression.gd /path/to/mygodot/project.godot
```

The test suite validates:
- **Memory Bus**: Read/write, word operations, I/O ports, reset
- **6502 CPU**: All addressing modes, load/store, arithmetic (ADC/SBC), logical (AND/OR/EOR), shifts (ASL/LSR/ROL/ROR), comparisons (CMP/CPX/CPY), branches, stack operations, jumps/subroutines, transfers, flag instructions, overflow detection, page boundary bugs
- **BASIC Interpreter**: PRINT, variables, arithmetic, IF/THEN, FOR/NEXT loops, GOSUB/RETURN, built-in functions (INT, ABS, SQR, SGN, SIN, COS), string functions (LEFT$, RIGHT$, MID$, LEN), arrays, READ/DATA, POKE/PEEK, boolean logic, comparison operators, ON GOTO
- **Computer Integration**: End-to-end BASIC program execution with 6502 CPU

## Your First BASIC Program

When the terminal opens, type directly:

```
PRINT "HELLO WORLD"
```

Press Enter. You should see `HELLO WORLD` printed.

### A More Complex Example

Enter a program with line numbers:

```
10 FOR I = 1 TO 10
20 PRINT I; " SQUARED IS "; I * I
30 NEXT I
40 END
```

Then type `RUN` and press Enter.

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
| Up Arrow | Cycle through command history |
| Down Arrow | Cycle forward through command history |

## What You'll See

- A retro green-on-black terminal interface
- A status bar showing live 6502 CPU register values (A, X, Y, SP, PC, flags)
- A text input area at the bottom for entering BASIC commands
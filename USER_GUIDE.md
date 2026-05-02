# BASIC6502 User Guide

## Overview

BASIC6502 is a retro computing environment that combines a **BASIC programming language interpreter** with a fully simulated **MOS 6502 microprocessor**. It recreates the experience of classic 8-bit computers like the Commodore 64, Apple II, and BBC Micro, all running inside the Godot game engine.

## Architecture

### The 6502 CPU

The MOS 6502 is the legendary 8-bit processor that powered the Apple II, Commodore 64, NES, and many other classic systems. Our simulation includes:

- **Registers**: A (accumulator), X (index), Y (index), SP (stack pointer), PC (program counter)
- **Status Flags**: Carry (C), Zero (Z), Interrupt Disable (I), Decimal (D), Break (B), Overflow (V), Negative (N)
- **Addressing Modes**: Immediate, Zero Page, Zero Page X/Y, Absolute, Absolute X/Y, Indirect, Indexed Indirect, Indirect Indexed, Relative, Implied, Accumulator
- **Full instruction set**: 56 official opcodes with all addressing mode variants

### Memory Map

| Range | Purpose |
|-------|---------|
| $0000-$00FF | Zero Page (fast 6502 access) |
| $0100-$01FF | Stack |
| $0200-$7FFF | General purpose RAM |
| $0800+ | BASIC program area |
| $C000-$C001 | Keyboard I/O |
| $C002-$C003 | Screen output I/O |
| $C010-$C011 | Cursor position |
| $C020 | Random number seed |
| $C030 | System call |
| $FFFA-$FFFF | CPU vectors (NMI, Reset, IRQ) |

### Memory Bus I/O Ports

The simulated system uses memory-mapped I/O:

- **$C000** (Keyboard Data): Read to get next character from input buffer
- **$C001** (Keyboard Status): 1 if data available, 0 if empty
- **$C002** (Screen Output): Write a character (ASCII) to display
- **$C003** (Screen Control): 0x0C = clear screen, 0x0D = flush/newline, 0x08 = backspace

## BASIC Language Reference

### Statements

| Statement | Description | Example |
|-----------|-------------|---------|
| `PRINT` | Output text/values | `PRINT "HELLO"; X` |
| `INPUT` | Get user input | `INPUT "NAME? "; N$` |
| `LET` | Assign variable (optional) | `LET A = 10` or `A = 10` |
| `IF...THEN` | Conditional execution | `IF A > 5 THEN PRINT "BIG"` |
| `FOR...TO...STEP...NEXT` | Loop | `FOR I = 1 TO 10 STEP 2` |
| `GOTO` | Jump to line number | `GOTO 100` |
| `GOSUB` | Call subroutine | `GOSUB 500` |
| `RETURN` | Return from subroutine | `RETURN` |
| `ON...GOTO/GOSUB` | Computed branch | `ON X GOTO 100, 200, 300` |
| `DIM` | Declare array | `DIM A(10)` |
| `READ` | Read from DATA list | `READ A, B` |
| `DATA` | Define data values | `DATA 10, 20, 30` |
| `RESTORE` | Reset DATA pointer | `RESTORE` |
| `POKE` | Write to memory | `POKE 1000, 42` |
| `END` / `STOP` | End program | `END` |
| `REM` | Comment | `REM THIS IS A COMMENT` |
| `CLR` | Clear variables | `CLR` |
| `NEW` | Clear program & variables | `NEW` |
| `LIST` | List program | `LIST` |
| `RUN` | Run program | `RUN` |

### Functions

| Function | Description | Example |
|----------|-------------|---------|
| `INT(x)` | Integer part | `INT(3.7)` → 3 |
| `RND(x)` | Random number 0-1 | `RND(1)` |
| `ABS(x)` | Absolute value | `ABS(-5)` → 5 |
| `SQR(x)` | Square root | `SQR(16)` → 4 |
| `SIN(x)` | Sine (radians) | `SIN(3.14)` |
| `COS(x)` | Cosine (radians) | `COS(0)` → 1 |
| `TAN(x)` | Tangent (radians) | `TAN(0.78)` |
| `ATN(x)` | Arctangent (radians) | `ATN(1)` |
| `LOG(x)` | Natural log | `LOG(2.71)` |
| `EXP(x)` | e^x | `EXP(1)` |
| `SGN(x)` | Sign: -1, 0, or 1 | `SGN(-10)` → -1 |
| `LEN(s$)` | String length | `LEN("HELLO")` → 5 |
| `CHR$(n)` | Character from ASCII | `CHR$(65)` → "A" |
| `ASC(s$)` | ASCII value of char | `ASC("A")` → 65 |
| `LEFT$(s$, n)` | Left substring | `LEFT$("HELLO",3)` → "HEL" |
| `RIGHT$(s$, n)` | Right substring | `RIGHT$("HELLO",3)` → "LLO" |
| `MID$(s$, start, len)` | Middle substring | `MID$("HELLO",2,3)` → "ELL" |
| `STR$(n)` | Number to string | `STR$(42)` → "42" |
| `VAL(s$)` | String to number | `VAL("42")` → 42 |
| `PEEK(addr)` | Read memory byte | `PEEK(1000)` |
| `TAB(n)` | Print tab spacing | `PRINT TAB(10); "X"` |

### Operators

| Category | Operators |
|----------|-----------|
| Arithmetic | `+ - * / ^` |
| Comparison | `= < > <= >= <>` |
| Logical | `AND OR NOT` |

### Variable Types

- **Numeric**: `A`, `COUNT`, `X1` (default to 0)
- **String**: `A$`, `NAME$` (default to empty string)

### String Concatenation
Use `+` to concatenate strings:
```
A$ = "HELLO" + " " + "WORLD"
```

## Commands

| Command | Description |
|---------|-------------|
| `HELP` | Show available commands |
| `RUN` | Execute the current program |
| `LIST` | Display the current program |
| `NEW` | Clear program and variables |
| `CLEAR` | Clear the screen |
| `RESET` | Full system reset (CPU + memory + BASIC) |
| `CPU` | Display 6502 CPU register state |
| `SAVE name` | Save program to disk |
| `LOAD name` | Load program from disk |
| `DIR` | List saved programs |
| `SYS addr` | Execute 6502 code at address |

## Example Programs

### Hello World
```
10 PRINT "HELLO, WORLD!"
20 END
```

### Guess the Number
```
10 N = INT(RND(1) * 100) + 1
20 G = 0
30 G = G + 1
40 INPUT "GUESS? "; G
50 IF G < N THEN PRINT "TOO LOW" : GOTO 30
60 IF G > N THEN PRINT "TOO HIGH" : GOTO 30
70 PRINT "YOU GOT IT IN"; G; "GUESSES!"
80 END
```

### Fibonacci Sequence
```
10 A = 0
20 B = 1
30 FOR I = 1 TO 20
40 PRINT A
50 C = A + B
60 A = B
70 B = C
80 NEXT I
90 END
```

### 6502 Machine Code Demo
```
10 POKE 768, 169
20 POKE 769, 65
30 POKE 770, 141
40 POKE 771, 0
50 POKE 772, 4
60 POKE 773, 8
70 SYS 768
80 PRINT PEEK(2048)
90 END
```

This stores LDA #$41, STA $0800 at address 768 ($0300), then calls SYS 768 to execute it and reads the result from memory address 2048 ($0800).

### Multiplication Table
```
10 FOR I = 1 TO 9
20 FOR J = 1 TO 9
30 PRINT I * J; " ";
40 NEXT J
50 PRINT ""
60 NEXT I
70 END
```

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| F1 | Show help |
| F3 | Toggle CRT settings panel |
| F5 | Run program |
| F6 | Start/stop video recording |
| F7 | Cycle baud rate (300/1200/2400/9600/14400) |
| F8 | Cycle font |
| F9 | Take screenshot |
| F10 | Full system reset |
| Up/Down | Command history |

## CRT Settings Panel

Press **F3** to open the real-time CRT settings panel on the right side of the screen. Adjust any parameter with the sliders — changes are applied immediately.

| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| Curvature | 0.15 | 0.0–1.0 | Barrel distortion (0=flat screen, 1=extreme curve) |
| Scanlines | 0.04 | 0.0–0.3 | Horizontal scanline darkness |
| Vignette | 0.18 | 0.0–1.0 | Edge darkening intensity |
| Glow | 0.18 | 0.0–1.0 | Phosphor bloom brightness |
| Flicker | 0.005 | 0.0–0.05 | Random brightness flicker |

Click **Reset to Defaults** to restore all values. Press **F3** again to close.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Program won't run | Check line numbers are in order; type `LIST` to verify |
| "LINE NOT FOUND" error | Ensure the GOTO/GOSUB target line exists |
| "NEXT WITHOUT FOR" | Make sure every NEXT has a matching FOR |
| "OUT OF DATA" | Not enough DATA statements for READ |
| Screen looks wrong | Type `CLEAR` to reset the display |
| CPU shows wrong values | Type `RESET` for full system reset |

## Technical Notes

- The 6502 emulation is cycle-accurate for all official opcodes
- Decimal mode (BCD) is not implemented in the ALU but the flag is preserved
- Unofficial opcodes are not supported (will halt the CPU)
- The BASIC interpreter uses floating-point numbers internally
- String variables are suffixed with `$`
- Arrays are dynamically sized via DIM or auto-sized on first use
- The memory bus intercepts reads/writes to the $C0xx I/O range
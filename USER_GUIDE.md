# BASIC6502 User Guide

## Overview

BASIC6502 is a retro computing environment from **Hacker Computer Company** that combines a **BASIC programming language interpreter** with a fully simulated **MOS 6502 microprocessor**. It recreates the experience of classic 8-bit computers like the Commodore 64, Apple II, and BBC Micro, all running inside the Godot game engine.

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
| $C030 | Cart select register (cartridge banking) |
| $E000-$EFFF | Cart workspace (per-cartridge, cleared on swap) |
| $F000-$F1FF | ROM routines |
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
| `IF...THEN...ELSE` | Conditional execution | `IF A > 5 THEN PRINT "BIG" ELSE PRINT "SMALL"` |
| `FOR...TO...STEP...NEXT` | Loop | `FOR I = 1 TO 10 STEP 2` / `NEXT I` |
| `GOTO` | Jump to line number | `GOTO 100` |
| `GOSUB` | Call subroutine | `GOSUB 500` |
| `RETURN` | Return from subroutine | `RETURN` |
| `ON...GOTO/GOSUB` | Computed branch | `ON X GOTO 100, 200, 300` |
| `DIM` | Declare array | `DIM A(10)` |
| `READ` | Read from DATA list | `READ A, B` |
| `DATA` | Define data values | `DATA 10, 20, 30` |
| `RESTORE` | Reset DATA pointer | `RESTORE` |
| `POKE` | Write to memory | `POKE 1000, 42` |
| `BSAVE` | Save memory to binary file | `BSAVE "screen.bin", $2000, 2048` |
| `BLOAD` | Load binary file to memory | `BLOAD "screen.bin", $4000` |
| `LOADOBJ` | Load **HC65** `.obj` from disk; register a callable name | `LOADOBJ "mylib.obj", PRIMEGEN` then `PRIMEGEN` |
| `SYS` | Run 6502 at address (see ROM table) | `SYS $F040` |
| `WRITE` | Write text to file | `WRITE "log.txt", "hello"` |
| `READFILE` | Read file into string | `READFILE "log.txt", MSG$` |
| `END` / `STOP` / `BREAK` | End program | `END` or `STOP` or `BREAK` |
| `REM` | Comment | `REM THIS IS A COMMENT` |
| `CLR` | Clear variables | `CLR` |
| `NEW` | Clear program & variables | `NEW` |
| `:` (colon) | Separate statements on one line | `10 A = 1 : PRINT A : GOTO 20` |

### Functions

| Function | Description | Example |
|----------|-------------|---------|
| `INT(x)` | Integer part (truncate toward zero) | `INT(3.7)` → 3 |
| `RND(x)` | Random number 0-1 | `RND(1)` |
| `ABS(x)` | Absolute value | `ABS(-5)` → 5 |
| `SQR(x)` | Square root | `SQR(16)` → 4 |
| `SIN(x)` | Sine (radians) | `SIN(3.14)` |
| `COS(x)` | Cosine (radians) | `COS(0)` → 1 |
| `TAN(x)` | Tangent (radians) | `TAN(0.78)` |
| `ATN(x)` | Arctangent (radians) | `ATN(1)` → 0.785 |
| `LOG(x)` | Natural log | `LOG(2.71)` |
| `EXP(x)` | e^x | `EXP(1)` |
| `SGN(x)` | Sign: -1, 0, or 1 | `SGN(-10)` → -1 |
| `LEN(s$)` | String length | `LEN("HELLO")` → 5 |
| `CHR$(n)` | Character from ASCII | `CHR$(65)` → "A" |
| `ASC(s$)` | ASCII value of char | `ASC("A")` → 65 |
| `LEFT$(s$, n)` | Left substring | `LEFT$("HELLO",3)` → "HEL" |
| `RIGHT$(s$, n)` | Right substring | `RIGHT$("HELLO",3)` → "LLO" |
| `MID$(s$, start, len)` | Middle substring | `MID$("HELLO",2,3)` → "ELL" |
| `STR$(n)` | Number to string | `STR$(42)` → " 42" |
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

### Hexadecimal Numbers

Numbers can be written in hexadecimal by prefixing with `$`:

```
PRINT $FF       → 255
POKE $C002, 65  → same as POKE 49154, 65
BLOAD "file", $2000
```

Hex digits are case-insensitive: `$dead` and `$DEAD` are equivalent.

### String Concatenation
Use `+` to concatenate strings:
```
A$ = "HELLO" + " " + "WORLD"
```

## Commands

| Command | Description |
|---------|-------------|
| `HELP` | Show available commands |
| `HELP topic` | Show detailed help for a topic (e.g., `HELP PRINT`) |
| `RUN` | Execute the current program from the first line |
| `RUN 100` | Start execution at line 100 |
| `RUN N=10` | Set variable N=10 then run from start |
| `RUN 100, N=10, S$="hi"` | Start at line 100, set N and S$ |
| `LIST` | Display all program lines |
| `LIST 30` | Display only line 30 |
| `LIST 10 100` | Display lines 10 through 100 |
| `NEW` | Clear program and variables |
| `CLEAR` or `CLS` | Clear the screen |
| `RESET` | Full system reset (CPU + memory + BASIC) |
| `CPU` | Display 6502 CPU register state |
| `STOP` or `BREAK` | Break running program |
| `HALT` | Halt the CPU |
| `STEP` | Single-step one CPU instruction |
| `MONITOR` or `MON` | Enter system monitor (Apple II style) |
| `POWEROFF` | Shut down |
| `SAVE name` | Save program to disk |
| `LOAD name` | Load program from disk |
| `DIR` or `CATALOG` | List saved programs (with sizes) |
| `SCRATCH name` or `DELETE name` | Delete a saved program |
| `RENAME old new` | Rename a saved program |
| `DEMO` | List built-in demo programs |
| `DEMO name` | Load a demo program |
| `DEMO name N` | Load a demo with parameter (e.g., `DEMO PRIMENUMS 100`) |
| `SYS addr` | Execute 6502 code at address |
| `CART` | List available ROM cartridges |
| `CART name` | Switch to a cartridge (e.g., `CART TEXT`, `CART BASIC`) |

### ROM Cartridges

The system supports switchable ROM cartridges. Each cart provides its own command set and prompt:

| Cart | Prompt | Description |
|------|--------|-------------|
| BASIC | `READY.` | Default BASIC interpreter with demos and 6502 ROM routines |
| TEXT | `EDIT>` | Line-numbered text buffer editor with SAVE/LOAD as `.txt` |
| ASM | `ASM>` | **6502 assembler** editor: `ASM` / `RUN`, `DEMO`, `SAVE`/`LOAD` **`.asm`**, **`SAVEOBJ`**/**`SAVEBIN`** (HC65 `.obj` or raw binary) |

Switch carts with `CART name` (e.g., `CART TEXT`, `CART ASM`). Cart switching preserves main RAM (`$0000-$DFFF`) but clears cart workspace (`$E000-$EFFF`). The active cart is saved and restored with system state.

### Hands-on tutorial: assemble 6502 code, save it to disk, call it from BASIC

This walkthrough uses the **ASM** cart with **`BSAVE` / `BLOAD`** and **`SYS`**. See **§8b** for the **HC65** path (**`SAVEOBJ`** on the ASM cart, **`LOADOBJ`** in BASIC) — same idea, richer metadata.

**What you will do:** write a tiny routine that prints **`A`** and a newline, assemble it at **`$0800`**, save the machine code with **`BSAVE`**, then from BASIC **`BLOAD`** it back and **`SYS`** to it.

#### 1. Open the assembler cart

At the `READY.` prompt:

```
CART ASM
```

You should see the **`ASM>`** prompt (and a short banner). If unsure, type **`HELP`** for editor commands.

#### 2. Enter source lines

Clear any old source, then type these lines **exactly** (press Enter after each). Line numbers are the editor’s line IDs, not BASIC.

```
NEW
10 LDA #$41
20 STA $C002
30 LDA #$0D
40 STA $C003
50 RTS
```

- **`$C002`** is the screen character port; **`$C003`** with **`$0D`** sends a newline so the terminal flushes output reliably.

#### 3. Assemble

```
ASM
```

You should see a success message and a line like **`Object $0800-$080A`**. That means code occupies **`$0800`** through **`$080A`** inclusive.

**Byte count for `BSAVE`:**  
`length = (last address − $0800) + 1` → here **`$080A − $0800 + 1 = 11`** (decimal **11**).

If you use a different program, use **`HEX`** on the ASM cart to confirm bytes, or read the **`Object $xxxx-$yyyy`** line and compute **`yyyy - xxxx + 1`** in decimal for the length.

#### 4. Switch back to BASIC

```
CART BASIC
```

#### 5. Save the machine code from RAM

Still at `READY.`, type (one line):

```
BSAVE "mychr", $0800, 11
```

- **`BSAVE`** writes `user://mychr` with a **2-byte header** (load address, LSB first) followed by **`11`** bytes copied from RAM starting at **`$0800`**.

You should see a confirmation like **`SAVED …`**.

#### 6. (Optional) Prove reload works

You can clear that RAM region with **`POKE`** if you like, then:

```
BLOAD "mychr"
```

With **no second argument**, **`BLOAD`** reads the **first two bytes** as the load address and puts the rest of the file there (here, back to **`$0800`**). The interpreter prints the address it used—confirm **`$0800`**.

#### 7. Run the routine from BASIC

```
SYS $0800
```

You should see **`A`** on its own line (your code prints **`A`**, then newline).

#### 8b. Optional: HC65 `.obj` from the ASM cart (`SAVEOBJ` + `LOADOBJ`)

If you use the **ASM** cart, you can emit a structured **HC65** object (magic `HC65`, load address, entry, optional **`.EXPORT`** / **`.HELP_*`** metadata) instead of hand-counting bytes:

1. After **`ASM`**, type **`SAVEOBJ mylib`** → creates **`user://mylib.obj`**.
2. In BASIC: **`LOADOBJ "mylib.obj", PRIMEGEN`** (or omit **`, NAME`** if the object includes **`.EXPORT`** in its source).
3. Run **`PRIMEGEN`** as its **own statement** (v1: **no arguments** — same cycle budget idea as **`SYS`**).
4. **`HELP PRIMEGEN`** shows embedded help if the assembler source used **`.HELP_SYNTAX`**, **`.HELP_DESC`**, **`.HELP_EXAMPLE`**.

Assembler directives (non-emitting, for metadata only): **`.EXPORT NAME`**, **`.ENTRY LABEL`**, **`.HELP_SYNTAX "..."`**, **`.HELP_DESC "..."`**, **`.HELP_EXAMPLE "..."`** (repeatable).

#### 9. Typical “ship it” BASIC program pattern

You can keep a tiny BASIC loader next to your binary:

```
10 REM LOAD NATIVE ROUTINE THEN CALL IT
20 BLOAD "mychr"
30 SYS $0800
40 END
```

Use the **same** **`SYS`** address as your assembly **origin** (here **`$0800`**). If you use **`.ORG $0900`** in ASM, assemble, then **`BSAVE`** with **`$0900`** and the new length, and **`SYS $0900`** accordingly.

With **HC65**, the equivalent pattern is **`LOADOBJ "mychr.obj", TST`** then **`TST`** instead of **`BLOAD` + `SYS`**, as long as the object was built with **`SAVEOBJ`** from the same origin.

#### Troubleshooting

| Problem | Things to check |
|---------|------------------|
| `ASM` fails | **`HELP`** on ASM cart; every label needs a **`:`** (e.g. **`LOOP:`**); use **`DEMO hello`** to compare with a known-good source. |
| Wrong or garbage after **`SYS`** | **`BSAVE`** length too short/long; **`BLOAD`** address mismatch; routine clobbered RAM your BASIC program needs. |
| Nothing prints | Include **`STA $C003`** with **`$0D`** after character output so the terminal finishes the line. |
| **`BLOAD` / `BSAVE` errors** | Filename is under **`user://`**; path is the **name** you passed (no `.bas` suffix for these commands—same pattern as existing **`BSAVE`** docs above). |

---

### Program Line Entry

- Type a line number followed by a statement to add or replace it: `10 PRINT "HELLO"`
- Type a line number alone to delete that line: `10`
- Use colon (`:`) to put multiple statements on one line: `10 A = 1 : PRINT A`

## Demo Programs

| Name | Description | Parameter |
|------|-------------|-----------|
| hello | Hello World | — |
| counter | Count 1-10 | — |
| fibonacci | Fibonacci Sequence | — |
| guess | Number Guessing Game | — |
| times | Multiplication Table | — |
| mandelbrot | ASCII Mandelbrot Set | — |
| primenums | Prime Numbers | `DEMO PRIMENUMS 100` finds first 100 primes |
| pi | Calculate Pi | `DEMO PI 1000` uses 1000 terms of Gregory-Leibniz |
| sys_counter | 6502 Counter ($F040) | — |
| sys_fib | 6502 Fibonacci ($F080) | — |
| sys_add2 | 6502 Add 2 ($F060) | — |
| sys_6502 | Manual 6502 Code Demo | — |

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

### Prime Numbers (parameterized)
```
DEMO PRIMENUMS 50
RUN
```
This finds the first 50 prime numbers using trial division. Change the number to find more or fewer.

### Calculate Pi
```
DEMO PI 1000
RUN
```
Uses the Gregory-Leibniz series with 1000 terms. More terms = more accuracy.

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

### Multiplication Table
```
10 FOR I = 1 TO 9
20 FOR J = 1 TO 9
30 IF I * J < 10 THEN PRINT " ";
40 PRINT I * J; " ";
50 NEXT J
60 PRINT ""
70 NEXT I
80 END
```

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
| Up/Down | Command history |
| Escape | Exit monitor mode |

The mouse cursor is hidden by default and appears when you move the mouse, disappearing after 3 seconds of inactivity.

## System Settings Panel

Press **F3** to open the System Settings panel on the right side of the screen. Adjust any parameter with the sliders — changes are applied immediately.

| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| Curvature | 0.01 | 0.0–1.0 | Barrel distortion (0=flat screen, 1=extreme curve) |
| Scanlines | 0.04 | 0.0–0.3 | Horizontal scanline darkness |
| Vignette | 0.18 | 0.0–1.0 | Edge darkening intensity |
| Glow | 0.18 | 0.0–1.0 | Phosphor bloom brightness |
| Flicker | 0.005 | 0.0–0.05 | Random brightness flicker |

### CRT Warm-Up & Boot

On a fresh launch, the terminal simulates a **5-second boot sequence** with "Hacker Computer Company" branding and BIOS POST (RAM test, CPU check, ROM detect). A CRT static crackle sound plays during boot.

The CRT also **warms up** over ~2 minutes — on cold start, values start high and settle down:
- Curvature: 0.10 → slider value
- Vignette: 1.0 → slider value
- Flicker: 0.05 → slider value
- Scanlines: 0.15 → slider value
- Glow: 0.6 → slider value
- Brightness: 0 → 1 (4-second fade-in during boot)

The warm-up uses a cubic ease-out curve. When a saved state is loaded on startup, the warm-up is skipped entirely.

### Save / Load State

The System Settings panel has **Save State** and **Load State** buttons. Saving writes the full system state to `user://savestate.json`, including:

- All CRT slider settings
- Font and baud rate selection
- 64KB memory (programs, variables, ROM, I/O)
- CPU registers
- BASIC program lines and variables
- Command history

On startup, if a save file exists it is **automatically loaded**, letting you resume exactly where you left off.

## System Monitor

Type `MONITOR` or `MON` to enter the Apple II-style system monitor. Commands include:

| Command | Description |
|---------|-------------|
| `addr` | Examine memory at address |
| `addr.value` | Write byte to address |
| `addr1.addr2` | Examine memory range |
| `R` | Show CPU registers |
| `D addr` | Disassemble at address |
| `G addr` | Run 6502 code at address |
| `S` | Single-step one instruction |
| `H` | Show monitor help |
| `ESC` or `Q` | Exit monitor |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Program won't run | Check line numbers are in order; type `LIST` to verify |
| "LINE NOT FOUND" error | Ensure the GOTO/GOSUB target line exists |
| "NEXT WITHOUT FOR" error | Every NEXT must have a matching FOR |
| "OUT OF DATA" | Not enough DATA statements for READ |
| Program seems to skip lines | GOTO/IF-THEN now support colon statement separators |
| Screen looks wrong | Type `CLEAR` to reset the display |
| CPU shows wrong values | Type `RESET` for full system reset |
| Can't see mouse | Move the mouse to show cursor; it hides after 3 seconds |

## Technical Notes

- The 6502 emulation supports all official opcodes and addressing modes
- GOTO, IF-THEN with line numbers, GOSUB, and NEXT all work correctly with nested/jumped loops
- Colon (`:`) separates multiple statements on one line
- `RUN 100` starts at line 100; `RUN N=10` sets variables before running
- BREAK and STOP are equivalent — both halt program execution
- LIST supports ranges: `LIST 30` or `LIST 10 100`
- SCRATCH/DELETE removes saved .bas files; RENAME renames them
- The BASIC interpreter uses floating-point numbers internally
- String variables are suffixed with `$`
- Arrays are dynamically sized via DIM or auto-sized on first use
- The memory bus intercepts reads/writes to the $C0xx I/O range
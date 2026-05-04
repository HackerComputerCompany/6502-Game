# Hacker Computer Model 6502

## Technical Reference Manual

---

> *"The power of a real 6502, the soul of a terminal."*

---

## 1. Overview

The **Hacker Computer Model 6502** is an 8-bit microcomputer built around the legendary **MOS Technology 6502** microprocessor. Designed for programmers, hobbyists, and tinkerers, it combines a full 6502 CPU, 64KB of addressable memory, memory-mapped I/O, a built-in BASIC interpreter, and a ROM cartridge expansion system — all simulated in software.

Despite being a virtual machine, every aspect of the hardware behaves identically to a real 6502-based system: the CPU executes real 6502 opcodes, memory-mapped I/O ports respond to reads and writes exactly as discrete logic would, and the ROM cartridge system mimics physical bank-switching.

---

## 2. System Specifications

| Parameter | Specification |
|-----------|---------------|
| **CPU** | MOS Technology 6502 @ 1 MHz (simulated, adjustable: 0.5/1/10 MHz) |
| **RAM** | 64KB unified address space ($0000–$FFFF) |
| **ROM** | 3KB banked ROM area ($F000–$FBFF) + 1KB fixed boot ROM ($FC00–$FFFF) |
| **I/O Ports** | 4 memory-mapped ports at $C000–$C003 |
| **Expansion** | ROM cartridge slots via bank-switching at $C030 |
| **BASIC** | Hacker BASIC v1.0 (resident in ROM Cart 0) |
| **Storage** | User filesystem (simulated disk, no byte limit in current firmware) |
| **Display** | CRT terminal, 80-column text, VT102-compatible |
| **Sound** | Procedural audio: key click, bell, carriage return, CRT crackle |

---

## 3. CPU — MOS Technology 6502

The heart of the system is a complete, cycle-accurate emulation of the **MOS 6502**, the same 8-bit processor that powered the Apple II, Commodore 64, Nintendo Entertainment System, Atari 2600, and BBC Micro.

### 3.1 Registers

| Register | Width | Description |
|----------|-------|-------------|
| **A** | 8-bit | Accumulator — primary arithmetic/logic register |
| **X** | 8-bit | Index register X — addressing and loops |
| **Y** | 8-bit | Index register Y — addressing and loops |
| **SP** | 8-bit | Stack pointer — points into $0100–$01FF |
| **PC** | 16-bit | Program counter — next instruction address |
| **P** | 8-bit | Processor status flags |

### 3.2 Status Flags

| Bit | Flag | Name | Description |
|-----|------|------|-------------|
| 0 | C | Carry | Set on arithmetic carry/borrow; used by shifts |
| 1 | Z | Zero | Set when result is zero |
| 2 | I | Interrupt Disable | Set = IRQs masked |
| 3 | D | Decimal Mode | Set = BCD arithmetic (not implemented in hardware) |
| 4 | B | Break | Set when BRK instruction executes |
| 5 | — | Unused | Always reads as 1 |
| 6 | V | Overflow | Set on signed arithmetic overflow |
| 7 | N | Negative | Set when result bit 7 = 1 |

### 3.3 Instruction Set

All **56 official 6502 opcodes** are implemented, covering:

- **Load/Store**: LDA, LDX, LDY, STA, STX, STY
- **Arithmetic**: ADC, SBC
- **Logic**: AND, ORA, EOR
- **Shifts/Rotates**: ASL, LSR, ROL, ROR
- **Increments/Decrements**: INC, DEC, INX, INY, DEX, DEY
- **Comparisons**: CMP, CPX, CPY
- **Branches**: BCC, BCS, BEQ, BNE, BMI, BPL, BVS, BVC
- **Jumps/Subroutines**: JMP, JSR, RTS, RTI
- **Stack**: PHA, PHP, PLA, PLP
- **Transfers**: TAX, TXA, TAY, TYA, TXS, TSX
- **Flags**: CLC, SEC, CLD, SED, CLI, SEI, CLV
- **Special**: NOP, BRK, BIT

### 3.4 Addressing Modes

| Mode | Syntax | Example | Bytes |
|------|--------|---------|-------|
| Immediate | `#nn` | `LDA #$42` | 2 |
| Zero Page | `nn` | `LDA $10` | 2 |
| Zero Page,X | `nn,X` | `LDA $10,X` | 2 |
| Zero Page,Y | `nn,Y` | `LDX $10,Y` | 2 |
| Absolute | `nnnn` | `LDA $C002` | 3 |
| Absolute,X | `nnnn,X` | `LDA $2000,X` | 3 |
| Absolute,Y | `nnnn,Y` | `LDA $2000,Y` | 3 |
| Indirect | `(nnnn)` | `JMP ($FFFC)` | 3 |
| Indexed Indirect | `(nn,X)` | `LDA ($10,X)` | 2 |
| Indirect Indexed | `(nn),Y` | `LDA ($10),Y` | 2 |
| Relative | `nn` (offset) | `BNE $0810` | 2 |
| Implied | — | `NOP`, `RTS` | 1 |
| Accumulator | — | `ASL A` | 1 |

### 3.5 Reset Vectors

| Vector | Address | Points To |
|--------|---------|-----------|
| **NMI** | $FFFA–$FFFB | $0800 (reserved for user code) |
| **Reset** | $FFFC–$FFFD | $FC00 (boot stub) |
| **IRQ/BRK** | $FFFE–$FFFF | $0800 (reserved for user code) |

On power-up, the CPU fetches the reset vector at $FFFC/$FFFD, which points to **$FC00** — the fixed boot ROM. The boot stub selects cart 0 (BASIC) and jumps to $F000, the entry point of the banked ROM.

---

## 4. Memory Map

The 6502's 16-bit address bus provides access to a full **65,536 bytes** of unified address space.

```
$0000 ┌──────────────────────────────────┐
      │  Zero Page                        │  256 bytes — fastest access
      │  (used by 6502 indexed ops)       │
$00FF ├──────────────────────────────────┤
      │  Stack                            │  256 bytes — grows downward
      │  (PHA, JSR, interrupts use this)  │
$01FF ├──────────────────────────────────┤
      │                                   │
      │  General Purpose RAM              │
      │  ($0200–$DFFF = 56KB)             │
      │                                   │
      │  User programs load at $0800+     │
      │                                   │
$DFFF ├──────────────────────────────────┤
      │  Cart Workspace                   │  4KB — per-cartridge scratch area
      │  (cleared on cart switch)         │  Written to $E000–$EFFF
$EFFF ├──────────────────────────────────┤
      │  Banked ROM Area                  │  3KB — swapped per cartridge
      │  (ROM routines, BASIC, ASM, etc.) │  $F000–$FBFF
$FBFF ├──────────────────────────────────┤
      │  Fixed Boot ROM                   │  1KB — always present, never swapped
      │  (boot stub, always at $FC00+)    │  $FC00–$FFFF
$FFFF └──────────────────────────────────┘
```

### 4.1 I/O Ports ($C000–$C03F)

The system uses **memory-mapped I/O** — special addresses in the $C000 range are decoded by custom hardware and do not access RAM.

| Address | Name | R/W | Description |
|---------|------|-----|-------------|
| **$C000** | KBDATA | Read | Keyboard data — next character from input buffer. Returns 0 if empty. |
| **$C001** | KBSTAT | Read | Keyboard status — returns 1 if data available, 0 if empty. |
| **$C002** | SCREEN | Write | Screen output — write an ASCII character to display. |
| **$C003** | SCRCTL | Write | Screen control: `$0C` = clear screen, `$0D` = flush/newline, `$08` = backspace. |
| **$C010** | CURSORX | R/W | Cursor X position (0–79). |
| **$C011** | CURSORY | R/W | Cursor Y position (0–23). |
| **$C020** | RNGSEED | R/W | Random number seed register. Write a value to reseed. |
| **$C030** | CARTSEL | R/W | Cartridge select register. Write cart ID (0–255) to switch. Read returns current cart ID. |

### 4.2 I/O Programming Example

Writing "HELLO" to the screen from assembly:

```assembly
        LDX #$00        ; X = 0 (index into string)
LOOP    LDA MSG,X       ; load character
        BEQ DONE        ; zero = end of string
        STA $C002       ; write to screen port
        INX
        BNE LOOP
DONE    RTS

MSG     .BYTE "HELLO",0
```

Reading a keypress:

```assembly
WAIT    LDA $C001       ; check keyboard status
        BEQ WAIT        ; loop until key pressed
        LDA $C000       ; read character
        RTS             ; A now holds the key
```

---

## 5. ROM Cartridge System

The Hacker Computer supports **switchable ROM cartridges**, similar to the Atari 2600, ColecoVision, or Commodore VIC-20 cartridge ports. Each cart provides its own ROM code, workspace, and command set.

### 5.1 Cartridge Architecture

| Region | Size | Purpose |
|--------|------|---------|
| $E000–$EFFF | 4KB | Cart workspace — cleared on every cart switch |
| $F000–$FBFF | 3KB | Banked ROM — contains the active cart's code |
| $FC00–$FFFF | 1KB | Fixed boot ROM — always present, never banked |

### 5.2 Cart Switching

Writing a cart ID to **$C030** triggers a hot swap:

1. Current cart's `uninstall()` routine runs
2. Cart workspace ($E000–$EFFF) is zeroed
3. New cart's ROM is copied into $F000–$FBFF
4. New cart's `install()` routine runs
5. CPU is reset; PC jumps to $F000

Reading **$C030** returns the currently active cart ID.

### 5.3 Available Cartridges

| ID | Name | Prompt | Description |
|----|------|--------|-------------|
| **0** | BASIC | `READY.` | Default cartridge. Hacker BASIC v1.0 interpreter, 12 demo programs, and 6502 ROM routines at $F000. |
| **1** | TEXT | `EDIT>` | Line-numbered text editor. Supports LIST, SAVE, LOAD, NEW. Workspace at $E000–$EFFF stores null-terminated lines. |

Switch cartridges from the command line:

```
CART                → list available carts
CART TEXT           → switch to TEXT editor
CART BASIC          → return to BASIC
```

Or from 6502 assembly:

```assembly
        LDA #$01        ; cart ID 1 = TEXT
        STA $C030       ; trigger switch
        ; CPU resets, jumps to $F000 of new cart
```

---

## 6. ROM Routines (Cart 0 — BASIC)

When the BASIC cartridge is active, the ROM at **$F000–$F1FF** contains useful machine code routines callable via `SYS` from BASIC or `JSR` from assembly.

| Address | Routine | Description |
|---------|---------|-------------|
| **$F000** | Warm Boot | Prints welcome banner to screen via $C002 port |
| **$F020** | Char Out | Prints the A register to screen port $C002 |
| **$F030** | String Out | Prints null-terminated string at $1C/$1D (little-endian pointer) |
| **$F040** | Counter | Prints digits 0–9 with delay loop between each |
| **$F060** | Add Two | Adds 2 to accumulator (A = A + 2) |
| **$F080** | Fibonacci | Computes and prints 8 Fibonacci numbers |
| **$F0C0** | Scroll | Prints alternating `*/` animation with delay |
| **$F100** | Hex Out | Prints A register as two hex digits via $C002 |

### 6.1 Calling ROM from BASIC

```basic
SYS 64512     → prints welcome banner ($F000)
SYS 64544     → prints A register as hex ($F100)
```

### 6.2 Calling ROM from Assembly

```assembly
        LDA #$5A        ; value to print as hex
        JSR $F100       ; call Hex Out routine
        RTS
```

---

## 7. Hacker BASIC v1.0

The default cartridge includes a full **BASIC interpreter** resident in the banked ROM area. BASIC programs are stored in RAM starting at **$0800** and executed by the interpreter.

### 7.1 BASIC Memory Layout

```
$0800  BASIC program lines (stored internally, not raw text)
$0A00  (varies) BASIC variables
$0C00  (varies) BASIC arrays
```

### 7.2 Statements

| Statement | Description |
|-----------|-------------|
| `PRINT` | Output text/values to screen. Use `;` for no newline, `,` for tab. |
| `INPUT` | Prompt for user input. `INPUT "NAME? "; N$` |
| `LET` | Variable assignment. `LET` keyword is optional. |
| `IF...THEN...ELSE` | Conditional execution. `IF X > 5 THEN PRINT "BIG" ELSE PRINT "SMALL"` |
| `FOR...TO...STEP...NEXT` | Loop with optional step (supports negative for countdown). |
| `GOTO` | Unconditional branch to line number. |
| `GOSUB` / `RETURN` | Call and return from subroutines. |
| `ON...GOTO/GOSUB` | Computed branch. `ON X GOTO 100, 200, 300` |
| `DIM` | Dimension arrays. `DIM A(20)` |
| `READ` / `DATA` / `RESTORE` | Read predefined data values. |
| `POKE` / `PEEK` | Write/read memory bytes. |
| `BSAVE` / `BLOAD` | Binary file save/load (2-byte load address header). |
| `WRITE` / `READFILE` | Text file write/read. |
| `SYS` | Execute 6502 machine code at address. |
| `END` / `STOP` / `BREAK` | Terminate program execution. |
| `REM` | Comment (ignored by interpreter). |
| `CLR` | Clear all variables and arrays. |
| `NEW` | Clear program and variables. |
| `:` | Colon — multiple statements on one line. |

### 7.3 Functions

| Function | Returns | Example |
|----------|---------|---------|
| `INT(x)` | Integer (floor) | `INT(3.7)` → 3 |
| `RND(x)` | Random 0–1 | `RND(1)` |
| `ABS(x)` | Absolute value | `ABS(-5)` → 5 |
| `SQR(x)` | Square root | `SQR(16)` → 4 |
| `SIN/COS/TAN/ATN(x)` | Trig (radians) | `SIN(1.57)` |
| `LOG(x)` | Natural log | `LOG(2.718)` |
| `EXP(x)` | e^x | `EXP(1)` |
| `SGN(x)` | Sign: -1, 0, 1 | `SGN(-10)` → -1 |
| `LEN(s$)` | String length | `LEN("HELLO")` → 5 |
| `CHR$(n)` | ASCII character | `CHR$(65)` → "A" |
| `ASC(s$)` | ASCII value | `ASC("A")` → 65 |
| `LEFT$(s$, n)` | Left substring | `LEFT$("HELLO", 3)` → "HEL" |
| `RIGHT$(s$, n)` | Right substring | `RIGHT$("HELLO", 3)` → "LLO" |
| `MID$(s$, start, len)` | Middle substring | `MID$("HELLO", 2, 3)` → "ELL" |
| `STR$(n)` | Number to string | `STR$(42)` → " 42" |
| `VAL(s$)` | String to number | `VAL("42")` → 42 |
| `PEEK(addr)` | Memory byte | `PEEK($C001)` |
| `TAB(n)` | Print tab position | `PRINT TAB(10); "X"` |

### 7.4 Operators

| Category | Operators |
|----------|-----------|
| Arithmetic | `+` `-` `*` `/` `^` |
| Comparison | `=` `<` `>` `<=` `>=` `<>` |
| Logical | `AND` `OR` `NOT` |

### 7.5 Number Formats

BASIC supports **decimal** and **hexadecimal** numbers:

```basic
PRINT 255       → 255
PRINT $FF       → 255
POKE $C002, 65  → same as POKE 49154, 65
PRINT $DEAD     → 57005
```

Hex digits are case-insensitive. The `$` prefix follows the convention of the MOS Technology assembler, Commodore BASIC, and Woz Monitor.

### 7.6 Variable Types

| Type | Suffix | Default | Example |
|------|--------|---------|---------|
| Numeric | none | 0 | `X = 42`, `COUNT = 0` |
| String | `$` | `""` | `NAME$ = "HELLO"` |

Variables persist across `RUN` commands. Use `NEW` or `CLR` to reset them.

### 7.7 File I/O

#### Binary Files (BSAVE / BLOAD)

```basic
BSAVE "screen.bin", $2000, 2048   → save 2KB from $2000 to file
BLOAD "screen.bin", $4000         → load file to $4000
BLOAD "screen.bin"                → load to address in file header
```

Binary files use a **Commodore-style format**: 2-byte little-endian load address header followed by data bytes.

#### Text Files (WRITE / READFILE)

```basic
WRITE "log.txt", "hello world"    → write text to file
READFILE "log.txt", MSG$          → read file content into string variable
```

### 7.8 Program Control

```
RUN               → execute from first line
RUN 100           → execute from line 100
RUN N=10          → set N=10, then run
RUN 100, N=10     → start at line 100, set N=10
LIST              → display all program lines
LIST 30           → display line 30
LIST 10 100       → display lines 10 through 100
NEW               → clear program and variables
SAVE name         → save program to disk
LOAD name         → load program from disk
DIR               → list saved programs with sizes
SCRATCH name      → delete a saved program
RENAME old new    → rename a saved program
```

---

## 8. TEXT Cartridge (Cart 1)

The **TEXT** cartridge provides a line-numbered text editor, useful for writing source code, notes, or data files.

### 8.1 Commands

| Command | Description |
|---------|-------------|
| `n text` | Add or replace line `n` |
| `n` | Delete line `n` |
| `LIST` | Display all lines |
| `LIST n [m]` | Display line `n` or range `n`–`m` |
| `DEL n` | Delete line `n` |
| `NEW` | Clear buffer |
| `PRINT` | Dump all lines as plain text |
| `SAVE name` | Save to `user://name.txt` |
| `LOAD name` | Load from `user://name.txt` |
| `DIR` | List `.txt` files on disk |
| `CART BASIC` | Return to BASIC cartridge |

### 8.2 Workspace

The TEXT cartridge mirrors its line buffer into RAM at **$E000–$EFFF** as null-terminated strings. This allows 6502 machine code to access the editor's content directly.

### 8.3 ROM Routine

`SYS $F000` from the TEXT cartridge prints the "TEXT EDITOR v1.0" banner via the screen port.

---

## 9. System Monitor

Type `MONITOR` or `MON` to enter the **Apple II-style system monitor**, providing direct access to memory and CPU state.

### 9.1 Monitor Commands

| Command | Description |
|---------|-------------|
| `addr` | Examine memory at address (hex display) |
| `addr.value` | Write byte `value` to address `addr` |
| `addr1.addr2` | Examine memory range from `addr1` to `addr2` |
| `R` | Display CPU registers (A, X, Y, SP, PC, flags) |
| `D addr` | Disassemble 6502 code starting at `addr` |
| `G addr` | Execute 6502 code at `addr` |
| `S` | Single-step one CPU instruction |
| `H` | Display monitor help |
| `ESC` / `Q` | Exit monitor |

All addresses in the monitor are **hexadecimal** (no `$` prefix needed).

### 9.2 Example Session

```
]R
PC  AC  XR  YR  SP  NV-BDIZC
0800 00  00  00  FD  00100100

]D 0800
0800  A9 00     LDA #$00
0802  8D 02 C0  STA $C002
0805  60        RTS

]0800.42
0800: 42

]G 0800
```

---

## 10. Keyboard and Display

### 10.1 Keyboard

The keyboard interface is memory-mapped at **$C000** (data) and **$C001** (status). Characters are buffered and delivered as ASCII values. The status register returns `1` when data is available, `0` when the buffer is empty.

The terminal supports:
- Full command history (Up/Down arrows)
- VT102-style inline input with blinking cursor
- Backspace, Delete, Home, End, Left/Right arrows
- ESC to cancel current input

### 10.2 Display

The display is an **80-column CRT terminal** with simulated phosphor effects:

- **Scanlines** — horizontal line pattern
- **Vignette** — edge darkening
- **Glow** — phosphor bloom
- **Flicker** — subtle brightness variation
- **Barrel distortion** — CRT curvature
- **Brightness** — overall intensity

On cold boot, the CRT simulates a **warm-up period** (~2 minutes) where curvature, vignette, flicker, and scanlines gradually settle from cold-start values to their configured settings. Brightness fades in over 4 seconds during the boot sequence.

### 10.3 CRT Warm-Up Values

| Parameter | Cold Start | Settled |
|-----------|------------|---------|
| Curvature | 0.10 | user setting (default 0.01) |
| Vignette | 1.0 | user setting (default 0.18) |
| Flicker | 0.05 | user setting (default 0.005) |
| Scanlines | 0.15 | user setting (default 0.04) |
| Glow | 0.6 | user setting (default 0.18) |
| Brightness | 0 → 1 (4-sec fade) | 1.0 |

### 10.4 Fonts

Four fonts are available, cycled with **F8**:

| Font | Style |
|------|-------|
| VT323 | Retro terminal (default) |
| Press Start 2P | 8-bit pixel |
| Share Tech Mono | Sci-fi mono |
| IBM Plex Mono | Clean corporate mono |

---

## 11. Sound

All sounds are **generated procedurally** at runtime — no audio files are stored. Each sound is synthesized as a 44.1kHz 16-bit mono `AudioStreamWAV`.

| Sound | Frequency | Duration | Character |
|-------|-----------|----------|-----------|
| Key click | 400Hz sine + noise | 25ms | Tight, percussive |
| Bell | 800/1600/2400Hz harmonics | 300ms | Warm, physical bell tone |
| Line feed | 300Hz sine + noise | 60ms | Soft mechanical thud |
| Carriage return | 120Hz + noise | 150ms | Heavy mechanical sweep |
| CRT crackle | Random pops + hiss | 1.5s | Power-on static discharge |
| Error | 200Hz sine + noise | 80ms | Low buzz |

The default volume is **-6dB**. The bell is triggered by:
- `PRINT CHR$(7)` (ASCII bell character)
- Terminal alert conditions
- Cart-specific events

---

## 12. Boot Sequence

On power-up (cold boot with no saved state):

1. **CRT warm-up** begins — screen is dark, curvature at maximum
2. **Boot stub** at $FC00 executes: selects cart 0 (BASIC), jumps to $F000
3. **BIOS POST** animation displays:
   - "HACKER COMPUTER COMPANY" branding
   - RAM test
   - CPU check
   - ROM detect
4. **CRT static crackle** sound plays (~3 seconds, fading)
5. **Brightness** fades in over 4 seconds
6. Welcome message prints
7. `READY.` prompt appears

If a **saved state** exists, the boot sequence is skipped entirely and the system resumes from the saved point.

---

## 13. System Control Panel

Press **F3** to open the System Settings panel with real-time CRT controls.

| Slider | Default | Range | Effect |
|--------|---------|-------|--------|
| Curvature | 0.01 | 0.0–1.0 | Barrel distortion |
| Scanlines | 0.04 | 0.0–0.3 | Horizontal scanline darkness |
| Vignette | 0.18 | 0.0–1.0 | Edge darkening |
| Glow | 0.18 | 0.0–1.0 | Phosphor bloom intensity |
| Flicker | 0.005 | 0.0–0.05 | Random brightness variation |

### 13.1 Save/Load State

The **Save State** button writes the complete system state to `user://savestate.json`:

- All CRT slider settings
- Font selection and baud rate
- Full 64KB memory contents (RAM, ROM, I/O state)
- CPU registers (A, X, Y, SP, PC, flags)
- BASIC program, variables, and arrays
- Active cartridge and cart state
- Command history

State is **automatically loaded on startup** if a save file exists.

---

## 14. Keyboard Shortcuts

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
| Escape | Exit monitor / cancel input |

---

## 15. Baud Rate Simulation

Characters are output through a simulated serial queue at the selected baud rate. The effective characters per second = baud rate ÷ 10.

| Baud | Chars/sec | Feel |
|------|-----------|------|
| 300 | 30 | Teletype — painfully slow |
| 1200 | 120 | Early modem era |
| 2400 | 240 | Moderate (default) |
| 9600 | 960 | Late 1980s |
| 14400 | 1440 | Near-instant |

---

## 16. 6502 Programming Examples

### 16.1 Hello World

```assembly
        ORG $0800

START   LDX #$00        ; X = string index
LOOP    LDA MSG,X       ; load character
        BEQ DONE        ; 0 = end of string
        STA $C002       ; write to screen
        INX
        BNE LOOP
DONE    RTS             ; return to monitor

MSG     .BYTE "HELLO, WORLD!",0
```

Assemble and run:
```
POKE 2048, 162   : REM LDA #$00 → LDX #$00 = $A2 $00
POKE 2049, 0
POKE 2050, 189   : REM LDA MSG,X = $BD
POKE 2051, 32    : REM low byte of MSG ($0820)
POKE 2052, 8     : REM high byte
POKE 2053, 240   : REM BEQ = $F0
POKE 2054, 10    : REM branch offset
POKE 2055, 141   : REM STA $C002 = $8D
POKE 2056, 2     : REM low byte of $C002
POKE 2057, 192   : REM high byte
POKE 2058, 232   : REM INX = $E8
POKE 2059, 208   : REM BNE = $D0
POKE 2060, 244   : REM branch offset (back to LOOP)
POKE 2061, 96    : REM RTS = $60
SYS 2048
```

### 16.2 Fibonacci Numbers

```assembly
        ORG $0800

        LDA #$00        ; A = 0 (first number)
        STA $10         ; store in zero page
        LDA #$01        ; A = 1 (second number)
        STA $11

        LDX #$08        ; print 8 numbers
FIB     LDA $10
        JSR $F100       ; print as hex
        LDA #' '
        STA $C002       ; print space
        LDA $10
        CLC
        ADC $11         ; A = A + B
        STA $12         ; temp = A + B
        LDA $11
        STA $10         ; A = B
        LDA $12
        STA $11         ; B = A + B
        DEX
        BNE FIB

        RTS
```

### 16.3 Keyboard Echo

```assembly
        ORG $0800

ECHO    LDA $C001       ; check keyboard
        BEQ ECHO        ; wait for key
        LDA $C000       ; read character
        STA $C002       ; echo to screen
        JMP ECHO        ; loop forever
```

---

## 17. Debugging & Recording

### 17.1 Screenshots (F9)

Press **F9** to save a screenshot. Files are saved to the platform-specific user data directory under `debug/screenshots/`.

### 17.2 Video Recording (F6)

Press **F6** to start recording individual frames. Press **F6** again to stop. Frames are saved as sequential PNGs and can be converted to video:

```bash
ffmpeg -framerate 30 -i frame_%05d.png -c:v libx264 -pix_fmt yuv420p output.mp4
```

---

## 18. Memory Bus Technical Details

### 18.1 Address Decoding

The memory bus performs the following decode on every access:

1. Address is masked to 16 bits (`addr & 0xFFFF`) — any access above $FFFF wraps.
2. If address is in the I/O range ($C000–$C03F), the appropriate port handler is invoked.
3. Otherwise, the access goes to RAM.

### 18.2 Address Wraparound

The 6502's 16-bit address bus naturally wraps at $FFFF. The memory bus enforces this by masking all addresses:

```
POKE 65536, 42  → writes to $0000
PEEK(65536)     → reads from $0000
```

### 18.3 Zero Page Behavior

The 6502's zero-page addressing modes (opcodes $00–$FF) only use the low byte of addresses. The hardware automatically wraps:

```
LDA $FF,X   where X = 1  → reads from $00 (not $100)
```

This wraparound is a documented feature of the 6502 and is fully emulated.

---

## 19. Known Limitations

| Feature | Status | Notes |
|---------|--------|-------|
| Decimal mode (BCD) | Not implemented | SED/CLD instructions exist but have no effect |
| IRQ/NMI handling | Partial | Vectors point to $0800 but no interrupt controller exists |
| Cycle-accurate timing | Approximate | Instruction timing is not cycle-exact |
| DMA | Not implemented | No direct memory access hardware |
| Disk controller | Simulated | File I/O uses host filesystem, not a simulated disk controller |
| 420KB disk limit | Planned | Future firmware will enforce a simulated floppy disk capacity |

---

## 20. Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│  HACKER COMPUTER MODEL 6502 — QUICK REFERENCE                   │
├─────────────────────────────────────────────────────────────────┤
│  CPU: 6502 @ 1MHz  |  RAM: 64KB  |  ROM: 4KB (3KB banked + 1KB fixed)  │
├─────────────────────────────────────────────────────────────────┤
│  I/O PORTS:                                                     │
│    $C000  KBDATA  (R)  Keyboard character                       │
│    $C001  KBSTAT  (R)  Keyboard status (1=ready, 0=empty)       │
│    $C002  SCREEN   (W)  Screen output (ASCII)                   │
│    $C003  SCRCTL   (W)  Screen ctrl ($0C=clr, $0D=flush)        │
│    $C030  CARTSEL (RW) Cartridge select/readback                │
├─────────────────────────────────────────────────────────────────┤
│  CARTS:  0=BASIC (READY.)  |  1=TEXT (EDIT>)                    │
│  VECTORS:  Reset=$FC00  |  IRQ=$0800  |  NMI=$0800              │
├─────────────────────────────────────────────────────────────────┤
│  F1=Help  F3=Settings  F4=Clock  F5=Run  F6=Record              │
│  F7=Baud  F8=Font  F9=Screenshot  F10=Reset                     │
└─────────────────────────────────────────────────────────────────┘
```

---

*Hacker Computer Company — Model 6502 Technical Reference Manual*
*Firmware v1.0 — All specifications subject to change without notice.*

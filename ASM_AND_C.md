# ROM Cartridge Expansion Plan: 6502 Assembler & Small-C Compiler

## Architecture Overview

The current system has a single ROM at `$F000-$F1FF` with a few demo routines. This plan expands it into a **cartridge system** where different ROM carts can be loaded, each providing a different programming environment on top of the 6502 CPU.

```
┌─────────────────────────────────────────────┐
│              BASIC6502 System                │
│                                             │
│  $0000-$00FF  Zero Page                    │
│  $0100-$01FF  Stack                        │
│  $0200-$7FFF  User RAM                    │
│  $0800+       Program area                  │
│  $C000-$C030  I/O ports                    │
│  $E000-$EFFF  Cart workspace (4KB)          │
│  $F000-$FFFF  ROM / Cart code (8KB)         │
│                                             │
│  Cartridges:                                │
│    cart_basic    → current BASIC + demos     │
│    cart_asm      → 6502 Assembler + Editor   │
│    cart_c        → Small-C Compiler          │
└─────────────────────────────────────────────┘
```

---

## Phase 1: Cartridge Loader System

**Goal:** Infrastructure to hot-swap ROM carts.

### Cartridge format

- Each cart is a GDScript class extending `ROMCart`
- Stored as `res://carts/cart_<name>.gd`
- Provides: `name`, `description`, memory map, entry points
- `CART` command lists available carts, `CART <name>` loads one
- Loading a cart: writes cart ROM to `$F000+`, resets I/O vectors, clears cart workspace at `$E000-$EFFF`
- Cart can define custom commands that hook into the terminal input handler

### Cart interface

```gdscript
class_name ROMCart
extends RefCounted

var name: String          # e.g. "ASM6502"
var description: String  # e.g. "6502 Assembler & Editor"
var memory: MemoryBus     # reference to system memory

func install() -> void:    # write ROM to $F000+, set vectors
func uninstall() -> void:  # called when swapping carts
func handle_command(text: String) -> bool:  # return true if handled
func help_text() -> String:  # cart-specific help
```

### Memory map for carts

```
$E000-$EFFF  Cart workspace (4KB — symbol tables, source buffers, object code)
$F000-$FFFF  Cart ROM (8KB — assembled code, runtime library)
```

**Estimated effort:** ~2 sessions.

---

## Phase 2: 6502 Assembly Editor & Assembler

**Goal:** A two-pass assembler with an integrated line editor, inspired by the Apple II Monitor + Merlin assembler.

### Editor (the "ASM" cart)

The editor is a line-number-based editor (like BASIC's LIST) but for assembly source:

```
ASM> NEW
ASM> 10 LDA #$41
ASM> 20 STA $C002
ASM> 30 RTS
ASM> LIST
  10  LDA #$41
  20  STA $C002
  30  RTS
ASM> ASM
Assembling... 3 lines, 6 bytes
Object at $0800-$0805
ASM> RUN
A
ASM> 
```

### Editor commands

| Command | Description |
|---------|-------------|
| `NEW` | Clear source buffer |
| `LIST` / `LIST n` | Show source lines |
| `n <instruction>` | Add/replace line n |
| `DEL n` | Delete line n |
| `ASM` | Assemble source to memory |
| `RUN` | Execute assembled code via SYS |
| `SAVE name` | Save source to disk |
| `LOAD name` | Load source from disk |
| `SYM` | Show symbol table |
| `HEX` | Show hex dump of assembled output |

### Assembler design

**Two-pass assembler:**

- **Pass 1:** Scan all lines, build symbol table (labels → addresses), calculate instruction sizes
- **Pass 2:** Resolve all forward references, emit machine code

**Addressing modes supported** (all 13 6502 modes):

```
IMP  (implied)         RTS
ACC  (accumulator)     ASL A
IMM  (immediate)       LDA #$41
ZPG  (zero page)       LDA $20
ZPX  (zero page,X)    LDA $20,X
ZPY  (zero page,Y)    LDX $20,Y
ABS  (absolute)        LDA $C002
ABX  (absolute,X)     LDA $C002,X
ABY  (absolute,Y)     LDA $C002,Y
IND  (indirect)        JMP ($F000)
IZX  (indirect,X)     LDA ($20,X)
IZY  (indirect,Y)     LDA ($20),Y
REL  (relative)        BEQ label
```

**Syntax:**

```
label:                  ; labels end with colon
  LDA #$41              ; immediate
  STA $C002              ; absolute
  BEQ loop               ; relative branch to label
  .BYTE $48,$65,$6C      ; data directive
  .WORD $0800            ; 2-byte word
  .ORG $0800             ; set origin
```

**Directives:**

- `.ORG addr` — set output origin
- `.BYTE val, val, ...` — emit raw bytes
- `.WORD addr, addr, ...` — emit 16-bit words
- `.DB "string"` — emit string as bytes
- `.EQU label value` — define constant

**Symbol table:** Maps labels to addresses. Stored in GDScript-side dictionary (not in 6502 memory — the source is a GDScript-side data structure, only the assembled output goes to 6502 memory).

**Assembly output:** Written to `$0800+` (or wherever `.ORG` directs). Up to ~30KB of object code.

**Opcode table:** Reuse the existing `_opcode_table` from `cpu_6502.gd` but inverted — map `"LDA" + "IMM"` → `0xA9`, etc.

### File structure

```
scripts/
  cart_asm.gd       — ROMCart subclass, editor + command handler
  assembler.gd      — two-pass assembler engine
```

**Estimated effort:** ~3-4 sessions.

---

## Phase 3: Small-C Compiler (Based on Ron Cain's Small-C)

**Goal:** A C compiler targeting the 6502, directly adapted from Ron Cain's original Small-C (1980). Small-C was a seminal subset of C that ran on 8080/CPM and was later ported to the 6502 by James Hendrix. We use the same language subset but implement our own lexer, parser, and 6502 code generator in GDScript.

**Key references from Cain's original work:**

- Single-pass compilation (no separate preprocessing stage beyond `#define` and `#include`)
- All arithmetic is 16-bit (int) or 8-bit (char); no floating point
- Functions must be defined before use (or forward-declared)
- Expression evaluation is stack-based, matching the 6502's limited register set
- The compiler itself is small enough to understand in a weekend — that's the point

### The "C" cart

```
C> NEW
C> 1: main() {
C> 2:   int i;
C> 3:   for (i = 0; i < 10; i = i + 1)
C> 4:     putc(48 + i);
C> 5:   putc(13);
C> 6: }
C> COMPILE
Compiling... 6 lines
Generated 42 bytes at $0800
C> RUN
0123456789
C>
```

### C language subset (Small-C)

Following Cain's Small-C closely — a usable C subset that a beginner can learn completely in a few sessions:

**Supported:**

- `int` (16-bit) and `char` (8-bit) — all arithmetic is integer
- Global and local variables (locals on a stack frame)
- Functions with parameters, returned via A/X registers
- `if/else`, `while`, `for`, `return`, `break`
- `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`, `~`, `<<`, `>>`
- `==`, `!=`, `<`, `>`, `<=`, `>=`, `&&`, `||`, `!`
- One-dimensional arrays and basic pointer dereferencing (`*p`, `p[n]`)
- String literals (stored as null-terminated in ROM)
- `#define` for simple constants
- `//` and `/* */` comments
- Built-in functions: `putc(c)`, `getc()`, `peek(addr)`, `poke(addr, val)`

**Not supported** (excluded deliberately, as in Cain's original):

- Structs, unions, enums
- Float/double
- Multi-file compilation or `#include` (for now)
- `switch/case`
- `goto`
- `sizeof`, typedef, explicit casting
- Function pointers, struct pointers
- Preprocessor beyond `#define`

**Calling convention** (Cain's model, adapted for 6502):

- First two params in A (low) and X (high)
- Additional params pushed right-to-left on stack
- Return value in A (low byte) / X (high byte)
- Callee saves/restores registers it modifies
- Stack frame pointer in `$F0-$F1` (zero page)

### File structure

```
scripts/
  cart_c.gd         — ROMCart subclass, C editor + command handler
  c_lexer.gd        — tokenizer
  c_parser.gd        — recursive descent → AST
  c_codegen.gd       — AST → 6502 assembly
  c_runtime.asm      — pre-assembled runtime library (putc, getc, mul, div)
```

**Estimated effort:** ~6-8 sessions.

---

## Phase 4: ROM Cart Integration & Polish

### Cart switching

```
CART          → lists available carts
CART BASIC    → load BASIC cart (default)
CART ASM      → load 6502 Assembler
CART C        → load Small-C Compiler
```

Each cart:

- Installs its ROM at `$F000`
- Sets its prompt (`ASM>`, `C>`, `READY.`)
- Registers command handlers
- Can call into the existing `Computer` / `CPU6502` / `MemoryBus`

### Shared subsystems

All carts share:

- The 6502 CPU emulator
- Memory bus with I/O ports
- Terminal output (baud-rate streaming)
- Save/load state (includes cart name)
- Sound system
- System monitor (available from all carts)

### Cart-specific state persistence

Save file gains a `"cart"` field:

```json
{
  "cart": "asm",
  "source_lines": ["10 LDA #$41", "20 STA $C002"],
  "symbol_table": {"loop": 1280},
  "computer": { ... },
  "crt": { ... }
}
```

---

## Phase 5: Documentation — Small-C Manual & Getting Started Guide

### Two deliverables:

1. **SMALL_C_MANUAL.md** — Complete language reference, compiler internals, calling convention, runtime library API, memory map, and appendix of error messages
2. **GETTING_STARTED_C.md** — "Getting Started with C in 10 Lessons", a progressive tutorial guide

### SMALL_C_MANUAL.md outline

```
1. Introduction
   - What Small-C is (and isn't)
   - Ron Cain's original design philosophy
   - How it fits on a 6502

2. Language Reference
   - Types (int, char)
   - Variables (global, local, scope rules)
   - Operators (arithmetic, bitwise, comparison, logical)
   - Control flow (if/else, while, for, return, break)
   - Functions (declaration, parameters, return values)
   - Arrays and pointers
   - String literals
   - #define
   - Comments

3. Built-in Functions
   - putc(c)        — output character
   - getc()          — read character
   - peek(addr)      — read memory byte
   - poke(addr, val) — write memory byte

4. Memory Map & Calling Convention
   - Zero page usage ($F0-$FF)
   - Stack frame layout
   - Parameter passing (A/X + stack)
   - Return values (A/X)
   - Register preservation contract

5. Compiler Errors
   - Each error message, cause, and fix

6. Compatibility Notes
   - What differs from K&R C, ANSI C
   - Known limitations
   - Debugging tips (using STEP, MONITOR)
```

### GETTING_STARTED_C.md — "Getting Started with C in 10 Lessons"

#### Lesson 1: Hello, World!
- Loading the C cart (`CART C`)
- The `main()` function
- `putc()` and character output
- Compile and RUN
- Exercise: Print your initials

#### Lesson 2: Variables and Arithmetic
- `int` and `char` types
- Declaration, assignment, operators
- `+`, `-`, `*`, `/`, `%`
- Exercise: Fahrenheit to Celsius converter

#### Lesson 3: Loops — for and while
- `for` loop syntax and patterns
- `while` loop
- Building a counting program
- Exercise: Print a multiplication table

#### Lesson 4: Conditionals — if/else
- Comparison operators
- Logical operators
- Nested conditions
- Exercise: Number guessing game

#### Lesson 5: Functions
- Defining your own functions
- Parameters and return values
- Calling convention on the 6502
- Exercise: Write `max(a, b)` and `abs(x)` functions

#### Lesson 6: Arrays and Strings
- One-dimensional arrays
- String literals as char arrays
- Null-terminated strings
- Exercise: Reverse a string

#### Lesson 7: Pointers and Memory
- Pointer basics (`*p`, `&x`)
- `peek()` and `poke()` for hardware access
- Walking through memory with the monitor
- Exercise: Read and display memory at $C000

#### Lesson 8: Bitwise Operations
- `&`, `|`, `^`, `~`, `<<`, `>>`
- Masks and flags
- Real 6502 I/O: reading keyboard status at $C001
- Exercise: Binary display of a number

#### Lesson 9: Interfacing with BASIC and Assembly
- C functions callable from BASIC via SYS
- Sharing memory between C and BASIC programs
- Inline assembly with the assembler cart
- Exercise: Write a C function, call it from BASIC

#### Lesson 10: Full Project — A Simple Game
- Putting it all together
- Keyboard input with `getc()`
- Game loop: input → update → display
- Exercise: Number guessing game with persistent high score in memory

---

## Implementation Order

| Phase | Description | Sessions |
|-------|-------------|----------|
| 1 | Cart loader system + CART command | 2 |
| 2 | ASM editor + two-pass assembler | 3-4 |
| 3 | Small-C compiler (lexer → parser → codegen) | 6-8 |
| 4 | Cart integration, switching, persistence | 2 |
| 5 | Small-C manual + 10-lesson getting started guide | 3-4 |
| **Total** | | **16-20 sessions** |

### Dependencies

- Phase 2 depends on Phase 1 (cart loader)
- Phase 3 depends on Phase 2 (C compiler emits assembly that the assembler assembles)
- Phase 4 depends on 1-3 all being done

### Prior art / references

- **Ron Cain's Small-C** (1980) — the original C subset compiler targeting 8080/CPM, published in Dr. Dobb's Journal #45 (May 1980). Our implementation follows Cain's language subset and single-pass compilation model, targeting 6502 instead of 8080. The defining characteristic: all arithmetic is 16-bit integer, functions defined before use, stack-based expression evaluation.
- **James Hendrix's Small-C port to 6502** (1982) — proved Cain's compiler could target the 6502 with a different code generator. Our calling convention is simplified from Hendrix's.
- **cc65** — modern 6502 C compiler (too complex for our scope, but good ABI reference for advanced features we may add later)
- **Merlin Assembler** — Apple II macro assembler (editor UX reference for Phase 2)
- **Apple II Monitor** — already implemented, UX model for our monitor mode
- **Fabrice Bellard's OTCC** — tiny C compiler in ~1500 lines (good minimal reference for parser/codegen techniques)
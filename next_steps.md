# `next_steps.md` — Roadmap: ROM carts, ASM, Small-C, and **object ↔ BASIC** linkage

This file is the **single living roadmap** for cartridge expansion, the assembler/C compiler vision, and **next work** (binary object files, `LOADOBJ`, embedded help, and BASIC “native” commands). Earlier drafts lived in `ASM_AND_C.md` and `ASM_SAVE_BASIC_PLAN.md` (merged here).

---

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

*Current tree also has HELP, DEMO, DIR, etc. **Phase 2.x** (below) adds **`SAVEOBJ`** / **HC65 `.obj`** and BASIC **`LOADOBJ`**.*

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

## Phase 2.x (planned): Object files, `LOADOBJ`, and BASIC command extensions

This phase answers: **save compiled ASM**, **load it from BASIC**, and optionally **call it like a new statement** (e.g. `PRIMEGEN`) with **machine-readable help** for `HELP PRIMEGEN`.

### Design principle: *no dynamic lexer keywords*

We are **not** proposing to mutate the tokenizer’s static keyword table at runtime in a fragile way. Instead:

1. **`PRIMEGEN` stays a normal identifier** in the lexer (`TT.IDENT`).
2. The interpreter gains a **`_native_extensions` (name → descriptor)** table, populated only by **`LOADOBJ`** (or equivalent).
3. In `_execute_single`, **before** the existing `IDENT` assignment / “bare expression” paths, check: if `toks[0]` is `IDENT` and the name exists in `_native_extensions`, dispatch **`_exec_native_call(name, toks)`** (statement form: optional args later).

That gives the *user experience* of “a new BASIC keyword” without recompiling the keyword trie or risking clashes with variables (see **Name resolution** below).

### User-facing options (both in spec)

| Mode | User action | Result |
|------|-------------|--------|
| **Explicit registration** | `LOADOBJ "primegen.obj", PRIMEGEN` | Loads bytes into RAM per file header; registers **`PRIMEGEN`** as a callable native statement. |
| **Embedded default name** | Optional object metadata includes `export_name`. Then `LOADOBJ "primegen.obj"` alone can register that default (if unique). Still recommend explicit name in docs for clarity. |
| **Source-time export** (assembler) | Directives at top of `.asm`, e.g. `.EXPORT PRIMEGEN`, feed the **metadata** section when emitting `.obj` so the binary carries the preferred name without a second file. |

### `LOADOBJ` — BASIC statement (normative sketch)

```
LOADOBJ "filename" [, symbolic_name]
```

- **`filename`**: string, under `user://` (same rules as `BLOAD` / `READFILE` style paths; exact sanitization TBD).
- **`symbolic_name`**: optional identifier. If omitted: use **`export_name`** from object metadata; if missing → **error** (no silent guess).
- **Actions** (in order):
  1. Read and validate container (see **`.obj` / HC65 container** below); reject unknown versions.
  2. **Load** code bytes into **`load_addr`** from header (poking `MemoryBus`).
  3. **Register** `symbolic_name` → `{ entry_addr, flags, help_refs, max_cycles_policy }`.
  4. If the name was already registered: **replace** or **error** — pick one in implementation (spec recommendation: **`ERROR: DUPLICATE NATIVE`** unless a future `LOADOBJ ... REPLACE` flag exists).

**Invocation**

```
PRIMEGEN           : REM v1: no args; runs 6502 at entry_addr (same cycle budget policy as SYS)
PRIMEGEN 10, 20    : REM reserved for v2 calling convention (see below)
```

### Calling convention (versioned)

| Version | Semantics |
|---------|-----------|
| **v1** | Statement with **no arguments**: run from **`entry_addr`**, same practical limits as **`SYS`** today (e.g. 10 000 cycles), **no return value** to BASIC. |
| **v2 (future)** | Optional typed args / return via agreed **zero page** or **pseudo-registers** in BASIC; must be opt-in via object **flags** so old objects keep v1 behavior. |

Routines must preserve or document clobbering of **A/X/Y/flags** if they coexist with BASIC expectations.

### Assembler directives (source → metadata, planned)

These are **not** 6502 opcodes; the assembler records them and emits into the **metadata / help** sections of `.obj` (never into 6502 code unless a future `.EMIT` says so).

| Directive | Purpose |
|-----------|---------|
| **`.EXPORT NAME`** | Default export symbol for `LOADOBJ` (must be valid BASIC identifier rules). |
| **`.ENTRY LABEL`** | If code entry ≠ load start, specify label for **`entry_addr`** (defaults to load start). |
| **`.HELP_SYNTAX "text"`** | Short syntax line for `HELP` topic. |
| **`.HELP_DESC "text"`** | One paragraph description (escaping / multiline rules TBD). |
| **`.HELP_EXAMPLE "line"`** | Repeatable; each becomes one example line in HELP output. |

**ASM cart** would gain **`SAVEOBJ name`** (or rename from earlier **`SAVEBIN`** idea) that writes **HC65 container** after successful **`ASM`**, merging in directive metadata.

### `.obj` file format — **HC65 container v1** (normative sketch)

Goals: **one file**, **self-describing**, **optional help**, **backward-friendly** to raw `BSAVE` payloads for simple tooling.

#### Overall layout (little-endian unless noted)

| Offset | Size | Field |
|--------|------|--------|
| `0` | `4` | **Magic** ASCII `HC65` (`0x48 0x43 0x36 0x35`) |
| `4` | `2` | **Format version** `u16`, value `1` |
| `6` | `2` | **Flags** `u16`: bit0 = metadata present, bit1 = help bundle present, bit2 = entry ≠ load (redundant if entry stored anyway) |
| `8` | `2` | **`load_addr`** — first byte of **code** is poked here |
| `10` | `2` | **`entry_addr`** — `SYS` / native call PC |
| `12` | `4` | **`code_len`** `u32` (v1 practical max e.g. 64K−16) |
| `16` | `code_len` | **Raw object code** |
| *var* | *var* | **Metadata block** (if flag bit0): length-prefixed UTF-8 fields (`export_name`, optional `build_id`, optional `source_hash` TBD) |
| *var* | *var* | **Help bundle** (if flag bit1): see below |

**Legacy note:** A bare **`BSAVE`** file (2-byte load + bytes) remains valid for **`BLOAD` + `SYS`** workflows; the HC65 wrapper is the **rich** path for **`LOADOBJ`** and HELP integration.

#### Help bundle (when flag bit1 set)

Structured as a **tiny TLV** stream for easy parsing without JSON in BASIC:

```
TAG u8 (1=syntax, 2=description, 3=example_line)
LEN u16  (byte length of payload)
PAYLOAD len bytes UTF-8
... repeat ...
TAG 0 = end of help bundle
```

- **TAG 1** — single payload: syntax string (e.g. `PRIMEGEN [n]`).
- **TAG 2** — single payload: description paragraph.
- **TAG 3** — **repeatable**; each payload is one **example line** (plain text, not a full BASIC program unless you embed newlines escaped — TBD).

`HELP PRIMEGEN` in BASIC would print these sections if the name was registered via **`LOADOBJ`** (interpreter looks up descriptor help; if empty, fall back to static HELP topics only).

### ASM cart commands (planned; complements existing)

| Command | Role |
|---------|------|
| **`SAVEOBJ name`** | After successful **`ASM`**, write `user://name.obj` as **HC65** including directive-sourced metadata/help. |
| **`SAVEBIN name`** (optional compat) | Write **raw `BSAVE`-compatible** file only (2-byte load + bytes) — no HELP. |
| **`DIR`** extension | Also list **`*.obj`** alongside **`*.asm`**. |

### Relationship to existing **`BSAVE` / `BLOAD` / `SYS`**

- **`BSAVE addr,len`** and **`BLOAD`** remain the **low-level** byte tools.
- **`SAVEOBJ` / `LOADOBJ`** are the **high-level** “shippable routine + name + docs” path.
- **`SYS addr`** remains valid forever; **`LOADOBJ`** is sugar that also **registers** a callable name.

### Merged notes from the earlier binary-save plan

- After **`ASM`**, `Assembler6502` already tracks **`last_start`** / **`last_end`** — the object payload is contiguous in RAM for the HC65 **`code_len`** slice.
- **`BLOAD "f"`** without address uses the file’s first two bytes as the poke base — same idea as HC65’s explicit **`load_addr`**, but HC65 adds magic + entry + optional metadata.
- Edge cases: RAM overlap with BASIC program space, **`SYS`** using a disposable CPU instance (current code) — still OK if memory is shared.

### Implementation sub-phases (suggested)

| Sub | Work |
|-----|------|
| **2.x-a** | HC65 write/read in GDScript; **`SAVEOBJ`** in ASM cart; tests round-trip bytes + header. |
| **2.x-b** | Assembler directives **`.EXPORT`**, **`.ENTRY`**, help tags → metadata writer. |
| **2.x-c** | BASIC **`LOADOBJ`**, `_native_extensions`, **`_exec_native_call`**, `HELP` merge for registered names. |
| **2.x-d** | Optional **`SAVEBIN`**, **`DIR`** polish, USER_GUIDE examples. |

### Open decisions (capture in issues when coding)

1. **Identifier vs variable clash**: if user `LOADOBJ ..., FOO` then `LET FOO = 1` — spec recommendation: **native names are reserved in the statement position only**; **`LET FOO`** still creates a variable (separate namespace) *or* error on conflict — pick one and document.
2. **Case rules**: export names **UPPERCASE** normalized to match BASIC style.
3. **Magic / version bump** when adding **v2 args** to the container or call ABI.

### Documentation (shipped with repo)

**Implemented:** **`scripts/hc65_object.gd`**, ASM **`SAVEOBJ` / `SAVEBIN`**, BASIC **`LOADOBJ`**, assembler **`.EXPORT` / `.ENTRY` / `.HELP_*`**, **`HELP <native>`** via `BasicInterpreter.format_native_help`. Regression coverage: **`test_hc65_round_trip`**, **`test_assembler_meta_directives`**, **`test_cart_asm_saveobj_all_demos`**, **`test_basic_loadobj_native_call`**, plus existing demo assemble tests.

The **BSAVE + SYS** walkthrough remains in **`USER_GUIDE.md`** (*Hands-on tutorial…*). **`GETTING_STARTED.md`** summarizes both paths.

---

## Implementation Order

| Phase | Description | Sessions |
|-------|-------------|----------|
| 1 | Cart loader system + CART command | 2 |
| 2 | ASM editor + two-pass assembler | 3-4 |
| **2.x** | **HC65 `.obj`, `SAVEOBJ`, directives, `LOADOBJ`, native HELP** | **4-6** |
| 3 | Small-C compiler (lexer → parser → codegen) | 6-8 |
| 4 | Cart integration, switching, persistence | 2 |
| 5 | Small-C manual + 10-lesson getting started guide | 3-4 |
| **Total** | | **~20-26 sessions** |

### Dependencies

- Phase 2 depends on Phase 1 (cart loader)
- Phase **2.x** depends on Phase 2 assembler + ASM cart (emit + load + BASIC hooks)
- Phase 3 depends on Phase 2 (C compiler emits assembly that the assembler assembles); may optionally depend on **2.x** if the C cart emits **HC65 objects** instead of only in-memory assemble
- Phase 4 depends on 1–3 (and **2.x** if shipped) being done

### Prior art / references

- **Ron Cain's Small-C** (1980) — the original C subset compiler targeting 8080/CPM, published in Dr. Dobb's Journal #45 (May 1980). Our implementation follows Cain's language subset and single-pass compilation model, targeting 6502 instead of 8080. The defining characteristic: all arithmetic is 16-bit integer, functions defined before use, stack-based expression evaluation.
- **James Hendrix's Small-C port to 6502** (1982) — proved Cain's compiler could target the 6502 with a different code generator. Our calling convention is simplified from Hendrix's.
- **cc65** — modern 6502 C compiler (too complex for our scope, but good ABI reference for advanced features we may add later)
- **Merlin Assembler** — Apple II macro assembler (editor UX reference for Phase 2)
- **Apple II Monitor** — already implemented, UX model for our monitor mode
- **Fabrice Bellard's OTCC** — tiny C compiler in ~1500 lines (good minimal reference for parser/codegen techniques)
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

## Phase 3: Small-C Compiler

**Goal:** A simplified C compiler targeting the 6502, inspired by Ron Cain's original Small-C and Fabrice Bellard's OTCC. Not standard C — a pragmatic subset.

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

### C language subset

Keeping it as small as possible while being useful:

**Supported:**

- `int` and `char` types (1-byte char, 2-byte int)
- Global and local variables
- Functions with parameters (up to 4, passed in A/X or on stack)
- `if/else`, `while`, `for`, `return`
- `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`, `~`, `<<`, `>>`
- `==`, `!=`, `<`, `>`, `<=`, `>=`, `&&`, `||`
- Arrays (1D), pointers (basic dereference)
- `putc(c)` — output character to `$C002`
- `getc()` — read character from `$C000`
- String literals in double quotes
- `#define` for simple text replacement constants
- Comments `//` and `/* */`

**Not supported** (to keep it small):

- Structs, unions, enums
- Float/double
- Preprocessor beyond `#define`
- `switch/case`
- `goto`
- Multi-file compilation
- `sizeof`, typedef, casting
- Struct pointers, function pointers

### Compiler architecture

A classic three-stage compiler:

```
Source → [Lexer] → Tokens → [Parser] → AST → [Codegen] → 6502 assembly → [Assembler] → machine code
```

**Stage 1: Lexer** (`c_lexer.gd`)

- Tokenize into: NUMBER, STRING, IDENT, KEYWORD, OP, PUNCT
- Simple character-by-character scanner

**Stage 2: Parser** (`c_parser.gd`)

- Recursive descent parser producing an AST
- Nodes: `Program`, `Function`, `VarDecl`, `If`, `While`, `For`, `Return`, `BinOp`, `Call`, `Assign`, `Deref`, `Index`, etc.

**Stage 3: Code Generator** (`c_codegen.gd`)

- Walks the AST and emits 6502 assembly mnemonics
- Uses a simple stack-based calling convention:
  - Params passed in A (low byte) / X (high byte) or pushed to stack
  - Return value in A (low byte) / X (high byte for int)
  - Local variables on a frame pointer stack at `$0100+`
- Emits assembly text that feeds into the Phase 2 assembler

**Runtime library** (included in the cart ROM at `$F000+`):

```
putc    — write A to $C002 (1 byte to screen)
getc    — read from $C000 (1 byte from keyboard)
mul16   — 16-bit multiply
div16   — 16-bit divide
mod16   — 16-bit modulo
```

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

## Implementation Order

| Phase | Description | Sessions |
|-------|-------------|----------|
| 1 | Cart loader system + CART command | 2 |
| 2 | ASM editor + two-pass assembler | 3-4 |
| 3 | Small-C compiler (lexer → parser → codegen) | 6-8 |
| 4 | Cart integration, switching, persistence | 2 |
| **Total** | | **13-16 sessions** |

### Dependencies

- Phase 2 depends on Phase 1 (cart loader)
- Phase 3 depends on Phase 2 (C compiler emits assembly that the assembler assembles)
- Phase 4 depends on 1-3 all being done

### Prior art / references

- **Ron Cain's Small-C** (1980) — the original C subset compiler targeting 8080, later ported to 6502
- **cc65** — modern 6502 C compiler (too complex, but good ABI reference)
- **Merlin Assembler** — Apple II macro assembler (editor UX reference)
- **Apple II Monitor** — already implemented, UX model for our monitor mode
- **Fabrice Bellard's OTCC** — tiny C compiler in ~1500 lines (minimal parser/codegen reference)
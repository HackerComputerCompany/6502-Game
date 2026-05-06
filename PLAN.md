# BASIC6502 — Architecture & Development Plan

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    terminal.gd                       │
│              (Godot Control / UI layer)              │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │ RichTextLabel│ │RichTextLabel │ │  SoundManager │  │
│  │  (Screen)    │ │(CommandLine) │ │  (Key/Bell/  │  │
│  │             │ │  + cursor    │ │   Crackle)    │  │
│  └──────┬───────┘ └──────┬───────┘ └──────────────┘  │
│         │                │                           │
│         ▼                ▼                           │
│  ┌──────────────────────────────────────────────┐    │
│  │              computer.gd                     │    │
│  │    (Orchestrator: CPU + Memory + BASIC)      │    │
│  │  ┌──────────┐ ┌───────────┐ ┌─────────────┐ │    │
│  │  │ cpu_6502 │ │ memory_bus│ │basic_interp. │ │    │
│  │  │          │ │           │ │             │ │    │
│  │  │  A X Y  │ │ 64KB RAM  │ │  Tokenizer  │ │    │
│  │  │  SP PC  │ │ + I/O ports│ │  Parser     │ │    │
│  │  │  Flags  │ │ + ROM area │ │  Evaluator  │ │    │
│  │  │  Step() │ │ + cart     │ │  Executor   │ │    │
│  │  │  Disasm │ │  banking   │ │             │ │    │
│  │  └──────────┘ └───────────┘ └─────────────┘ │    │
│  ┌──────────────────────────────────────────────┐    │
│  │           cart_manager.gd                     │    │
│  │  ┌──────────────┐  ┌──────────────┐          │    │
│  │  │ cart_basic   │  │ cart_text    │          │    │
│  │  │ (BASIC IDE)  │  │ (Line Editor)│          │    │
│  │  └──────────────┘  └──────────────┘          │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │                rom.gd                          │    │
│  │  (Pre-loaded 6502 routines at $F000-$F1FF)    │    │
│  │  Warm Boot / Char Out / String Out / Counter   │    │
│  │  Add Two / Fibonacci / Scroll / Hex Out        │    │
│  │  + 12 BASIC demo programs (incl. primes, pi)   │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │            debug_manager.gd                    │    │
│  │  (Screenshots, video recording)               │    │
│  └──────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘

          ┌───────────────────────┐
          │    crt_overlay.gdshader │
          │  (Scanlines, vignette,  │
          │   glow, flicker, curve,  │
          │   brightness, static)    │
          └───────────────────────┘
```

## Data Flow

```
User types command → terminal._handle_command()
    │
    ├── Direct commands (HELP, CLEAR, DEMO, CPU, etc.)
    │   → handled in terminal.gd
    │
    ├── BASIC with line numbers (e.g., "10 PRINT ...")
    │   → _add_program_line() — stored/updated in basic._program
    │   → line number alone deletes that line
    │   → LIST/LIST n/LIST n m shows lines
    │   → executed on RUN
    │
    └── Immediate mode (e.g., "PRINT 2+2")
        → basic.execute_line()
        → tokenizer → parser → evaluator
        → output via _output_callback → terminal._on_output()
        → baud-rate queue → character-by-character display
```

## Memory Bus I/O

The memory bus intercepts reads/writes to the `$C0xx` range:

- **Write** to `$C002`: character sent to screen output
- **Write** to `$C003`: control (`$0C`=clear, `$0D`=newline/flush, `$08`=backspace)
- **Read** from `$C000`: next keyboard character
- **Read** from `$C001`: 1 if keyboard data available

BASIC's `POKE addr, val` and `PEEK(addr)` map directly to memory bus operations, and `SYS addr` executes 6502 code at that address.

## ROM Region

The ROM is loaded into memory at init time by `rom.gd`. It writes machine code bytes directly into the memory bus at `$F000-$F1FF`. Reset recreates the ROM since `memory.reset()` clears all RAM (but `ROM._init()` re-populates it via `Computer.reset()`).

## Key Features (Current)

### BASIC Interpreter
- Full statement set: PRINT, INPUT, FOR/NEXT, IF/THEN/ELSE, GOSUB/RETURN, DIM, READ/DATA, POKE/PEEK, ON GOTO/GOSUB
- Binary file I/O: BSAVE (memory → binary file), BLOAD (binary file → memory, with optional dest address)
- Text file I/O: WRITE (create text files), READFILE (load text into string variables)
- Hexadecimal numbers: prefix with `$` (e.g., `$FF`, `$C000`)
- Colon (`:`) statement separator on program lines
- BREAK/STOP as program breakpoints
- Program line entry: `10 PRINT "HI"` adds/replaces, `10` deletes
- LIST with ranges: `LIST 30`, `LIST 10 100`
- RUN with parameters: `RUN 100, N=10`
- Context-sensitive HELP: `HELP PRINT`, `HELP FOR`, etc. (40+ topics)
- 40+ built-in functions: INT, RND, ABS, SQR, SIN, COS, TAN, ATN, LOG, EXP, SGN, LEN, CHR$, ASC, LEFT$, RIGHT$, MID$, STR$, VAL, PEEK, TAB
- Safety limits: execution capped at `program_size * 1000 + 10000` steps to prevent infinite hangs

### ROM Cartridge System
- `CartManager` handles cartridge switching via `CART` command or `$C030` I/O port
- `ROMCart` base class: `install()`, `uninstall()`, `handle_command()`, `serialize()`/`deserialize()`
- **Cart 0 — BASIC**: Default BASIC interpreter, creates ROM routines on install
- **Cart 1 — TEXT**: Line-numbered text buffer editor with SAVE/LOAD as `.txt`, workspace at `$E000-$EFFF`
- Cart switching preserves main RAM (`$0000-$DFFF`), clears cart workspace (`$E000-$EFFF`)
- Active cart is saved/restored with system state

### Demo Programs
- 12 built-in demos including ASCII Mandelbrot, prime numbers, pi calculation
- Parameterized demos: `DEMO PRIMENUMS 100`, `DEMO PI 1000`

### Terminal & CRT
- CRT effects: scanlines, vignette, glow, flicker, barrel distortion, brightness, static
- CRT warm-up animation (~2 min): curvature, vignette, flicker, scanlines all ease from cold-start values
- Boot sequence: 5-second BIOS POST with "Hacker Computer Company" branding
- CRT static crackle sound on cold boot
- 4 switchable retro fonts (F8), 5 baud rates (F7), 3 CPU clock speeds (F4)
- Fullscreen by default, mouse auto-hides after 3 seconds
- Dynamic prompt per active cart (`READY.` for BASIC, `EDIT>` for TEXT)
- RichText output path for cart messages (bypasses baud-rate streaming)

### File Management
- SAVE, LOAD, DIR (with file sizes), SCRATCH/DELETE, RENAME
- BSAVE/BLOAD for binary files (Commodore-style 2-byte load address header)
- WRITE/READFILE for text files
- **System Settings panel (F3)** — CRT sliders, save/load state, reset to defaults

### System Monitor
- Apple II-style monitor: memory examine/modify, disassembly, register display
- Single-step (STEP), run (G), halt (HALT)

### Sound Generation
All sounds are generated procedally at runtime via `AudioStreamWAV` — no audio files needed:

| Sound | Generation |
|-------|-----------|
| Key click | 400Hz sine + noise, 25ms, tight decay |
| Bell | 800/1600/2400Hz harmonics, 300ms, exponential decay (warm tone) |
| Line feed | 300Hz sine + noise, 60ms |
| Carriage return | 120Hz + noise, 150ms, fast decay |
| CRT crackle | Random pops + hiss, 1.5s, exponential envelope |
| Error | 200Hz sine + noise, 80ms |

### Testing
- **`TESTING.md`** — inventory of every regression block, CLI battery case, **65x02** JSON step suite, and fuzz rounds
- **`scripts/run_all_tests.sh`** — regression → `test_processor_step_tests.gd` → `test_cli.gd` → `test_fuzz_smoke.gd` (optional `GODOT`, `FUZZ_ITERS`, `FUZZ_SEED`)
- **`tests/test_regression.gd`** — memory, CPU, BASIC, `Computer`, carts (BASIC / TEXT / ASM / C / NATIVE), assembler / HC65, files, serialization
- **`tests/test_processor_step_tests.gd`** — vendored **[SingleStepTests / 65x02](https://github.com/SingleStepTests/65x02)** subset (MIT; see `tests/fixtures/processor_tests/README.md`)
- **`tests/test_cli.gd`** — lighter headless battery; invoke `godot --path . --headless -s tests/test_cli.gd`
- **`tests/test_fuzz_smoke.gd`** — BASIC / assembler / CPU / TEXT / C fuzz smoke (whitelist; ~120s global budget); `--fuzz-iters` / `--fuzz-seed` after `--`
- **`CPU_Emulator_Bugs.md`** — mostly **historical** notes from an older regression snapshot; core opcode coverage is reinforced by internal regression + **65x02** JSON tests
- **`cart_native.gd`** + **`native_basic_softfloat.gd`**: BASIC **HYBRID** vs **NATIVE** IEEE754 soft-float for **`+ − × ÷`** (GDScript today); load **`~$6800`** **6502** routines later using the same bit patterns / calling convention.

## Font System

Four fonts are bundled and switchable with F8:

| Font | Style | Size adjustment |
|------|-------|----------------|
| VT323 | Retro terminal | Base size (default) |
| Press Start 2P | 8-bit pixel | Base - 4px |
| Share Tech Mono | Sci-fi mono | Base size |
| IBM Plex Mono | Clean mono | Base size |

## Development Roadmap

- [x] Full 6502 CPU emulation (all 56 opcodes, all addressing modes)
- [x] Complete BASIC interpreter (40+ keywords, 40+ functions)
- [x] CRT effects with real-time controls
- [x] Boot sequence and CRT warm-up animation
- [x] System monitor (Apple II style)
- [x] SAVE/LOAD/DIR/SCRATCH/RENAME file management
- [x] DEMO programs (12 including primes, pi, mandelbrot)
- [x] RUN with parameters and line number
- [x] Colon statement separator
- [x] BREAK/STOP
- [x] LIST with ranges
- [x] Hexadecimal number notation (`$FF`, `$C000`)
- [x] Binary file I/O (BSAVE/BLOAD)
- [x] Text file I/O (WRITE/READFILE)
- [x] ROM cartridge system (CartManager, ROMCart base, CART command)
- [x] TEXT cartridge (line editor)
- [x] Safety limits to prevent infinite execution hangs
- [x] Headless CLI test runner (test_cli.gd)
- [ ] Boot loader menu (see TODO.md)
- [ ] Disk storage with **140 KiB per floppy side** (Side A / Side B); **280 KiB** per double-sided disk (see TODO.md and `archives/basic_games_disk_catalog.md`)
- [ ] Cartridge hot-swap from within running programs
- [x] 6502 assembler editor + two-pass assembler (`cart_asm.gd`, `assembler6502.gd`)
- [x] Small-C compiler cart (`cart_c.gd`; regression + fuzz whitelist coverage)
- [ ] Audit remaining items in **CPU_Emulator_Bugs.md** (historical doc; cross-check vs **65x02** + regression)
- [ ] Screen editor mode (edit previously typed lines)
- [ ] Color support (PETSCII-style color codes)
- [ ] Web export compatibility
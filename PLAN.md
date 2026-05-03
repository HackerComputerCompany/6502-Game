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
│  │  │  Step() │ │            │ │  Executor   │ │    │
│  │  │  Disasm │ │            │ │  Colon :sep │ │    │
│  │  └──────────┘ └───────────┘ └─────────────┘ │    │
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
- Colon (`:`) statement separator on program lines
- BREAK/STOP as program breakpoints
- Program line entry: `10 PRINT "HI"` adds/replaces, `10` deletes
- LIST with ranges: `LIST 30`, `LIST 10 100`
- RUN with parameters: `RUN 100, N=10`
- Context-sensitive HELP: `HELP PRINT`, `HELP FOR`, etc. (40+ topics)
- 40+ built-in functions: INT, RND, ABS, SQR, SIN, COS, TAN, ATN, LOG, EXP, SGN, LEN, CHR$, ASC, LEFT$, RIGHT$, MID$, STR$, VAL, PEEK, TAB

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

### File Management
- SAVE, LOAD, DIR (with file sizes), SCRATCH/DELETE, RENAME
- **System Settings panel (F3)** — CRT sliders, save/load state, reset to defaults

### System Monitor
- Apple II-style monitor: memory examine/modify, disassembly, register display
- Single-step (STEP), run (G), halt (HALT)

## Sound Generation

All sounds are generated procedally at runtime via `AudioStreamWAV` — no audio files needed:

| Sound | Generation |
|-------|-----------|
| Key click | 400Hz sine + noise, 25ms, tight decay |
| Bell | 2000/3500/5500Hz harmonics, 500ms, exponential decay |
| Line feed | 300Hz sine + noise, 60ms |
| Carriage return | 120Hz + noise, 150ms, fast decay |
| CRT crackle | Random pops + hiss, 1.5s, exponential envelope |
| Error | 200Hz sine + noise, 80ms |

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
- [ ] Boot loader / ROM banking system (see TODO.md)
- [ ] 6502 assembler editor + two-pass assembler (see ASM_AND_C.md)
- [ ] Small-C compiler (see ASM_AND_C.md)
- [ ] Screen editor mode (edit previously typed lines)
- [ ] Color support (PETSCII-style color codes)
- [ ] More CPU tests (all addressing modes, decimal mode)
- [ ] Web export compatibility
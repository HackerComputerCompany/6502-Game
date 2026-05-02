# BASIC6502 — Architecture & Development Plan

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    terminal.gd                       │
│              (Godot Control / UI layer)              │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │ RichTextLabel│ │  LineEdit    │ │  SoundManager │  │
│  │  (Screen)    │ │ (InputLine)  │ │  (Key/Bell)   │  │
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
│  │  └──────────┘ └───────────┘ └─────────────┘ │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │                rom.gd                          │    │
│  │  (Pre-loaded 6502 routines at $F000-$F1FF)    │    │
│  │  Warm Boot / Char Out / String Out / Counter   │    │
│  │  Add Two / Fibonacci / Scroll / Hex Out        │    │
│  │  + 10 BASIC demo programs                      │    │
│  └──────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘

         ┌───────────────────────┐
         │    crt_overlay.gdshader │
         │  (Scanlines, vignette,  │
         │   glow, flicker, curve)  │
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
    │   → stored in basic._program
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

BASIC's `POKE addr, val` and `PEEK(addr)` map directly to memory bus operations, and `SYS addr` creates a temporary CPU instance to execute 6502 code at that address.

## ROM Region

The ROM is loaded into memory at init time by `rom.gd`. It writes machine code bytes directly into the memory bus at `$F000-$F1FF`. Reset recreates the ROM since `memory.reset()` clears all RAM (but the `ROM._init()` re-populates it via `Computer.reset()`).

## CRT Bezel System

The terminal is framed by a `PanelContainer` with a `StyleBoxFlat` that creates the CRT bezel:

```
┌──────────────────────────────────────┐
│  Dark bezel (20px border, #1a1a1f)   │
│  ┌────────────────────────────────┐  │
│  │  Title bar (BASIC6502 | baud) │  │
│  │  Screen (RichTextLabel)        │  │
│  │  Input line (LineEdit)         │  │
│  │  Status bar (CPU registers)    │  │
│  └────────────────────────────────┘  │
│  Shadow (20px)                       │
└──────────────────────────────────────┘
```

### Custom Bezel Image

Users can replace the `StyleBoxFlat` with a `StyleBoxTexture` pointing to a custom PNG. The image spec:

- **4:3 aspect ratio** (e.g., 1920x1440 for Retina, 960x720 for 1x)
- **PNG with alpha**: transparent center cutout for the terminal
- **Inner margin**: match the VBoxContainer offsets (currently 28px all sides)
- **Outer shadow**: the StyleBox supports `shadow_size` and `shadow_color`
- **Corner radius**: screen cutout should have 4-8px radius

To swap: edit `main.tscn`, find `BezelPanel`, change its `theme_override_styles/panel` from `StyleBoxFlat_2` to a new `StyleBoxTexture` resource.

## Baud Rate Simulation

Output characters are queued and released per frame based on the selected baud rate:

```
chars_per_second = baud_rate / 10
chars_this_frame = max(1, int(chars_per_second * delta))
```

At 300 baud: 30 chars/sec (teletype feel)
At 14400 baud: 1440 chars/sec (effectively instant)

Each character triggers a procedural sound effect via `SoundManager`:
- Regular chars → key click
- Newlines → line feed sound
- Bell char (`\a`) → bell
- Enter → carriage return sound

## Sound Generation

All sounds are generated procedurally at runtime via `AudioStreamWAV` — no audio files needed:

| Sound | Generation |
|-------|-----------|
| Key click | 800Hz sine + noise, 40ms, exponential decay |
| Bell | 2000/3500/5500Hz harmonics, 500ms, exponential decay |
| Line feed | 300Hz sine + noise, 60ms |
| Carriage return | 120Hz + noise, 150ms, fast decay |
| Error | 200Hz sine + noise, 80ms |

## Font System

Four fonts are bundled and switchable with F8:

| Font | Style | Size adjustment |
|------|-------|----------------|
| VT323 | Retro terminal | Base size (default) |
| Press Start 2P | 8-bit pixel | Base - 4px |
| Share Tech Mono | Sci-fi mono | Base size |
| IBM Plex Mono | Clean mono | Base size |

Fonts are loaded via `ResourceLoader.load()` and applied to all UI elements dynamically. Base font size scales with window size.

## Regression Tests

`tests/test_regression.gd` covers:

- **Memory Bus**: read/write, word operations, I/O ports, reset, reset vectors
- **CPU 6502**: load/store, ADC/SBC, AND/OR/EOR, shifts, comparisons, branches, stack, jumps, flags, transfers, NOP/BRK
- **BASIC**: PRINT, variables, arithmetic, IF/THEN, FOR/NEXT, GOSUB/RETURN, functions, strings, arrays, READ/DATA, POKE/PEEK, ON GOTO
- **Integration**: end-to-end BASIC program execution

Run: `godot --headless --script res://tests/test_regression.gd`

## Development Roadmap

- [ ] More CPU tests (all addressing modes, decimal mode flag)
- [ ] INPUT command with actual user interaction
- [ ] SAVE/LOAD to user directory
- [ ] Custom bezel image support (StyleBoxTexture)
- [ ] Full 6502 decimal mode (BCD arithmetic)
- [ ] More ROM routines (multiply, divide, string compare)
- [ ] Additional demo programs (snake game, life, sort)
- [ ] Screen editor mode (edit previously typed lines)
- [ ] Color support (PETSCII-style color codes)
- [ ] Web export compatibility
# BASIC6502

A retro computing environment combining a **BASIC programming language interpreter** with a fully simulated **MOS 6502 microprocessor**, running inside the Godot game engine. Inspired by the Commodore 64, Apple II, and BBC Micro — with a dash of the Typewrite project's typewriter aesthetic.

## Features

- **Full MOS 6502 CPU emulation** — all 56 official opcodes, all addressing modes (immediate, zero page, absolute, indirect, indexed, etc.)
- **Complete BASIC interpreter** — PRINT, INPUT, FOR/NEXT, IF/THEN, GOSUB/RETURN, DIM, READ/DATA, POKE/PEEK, string functions, math functions, ON GOTO/GOSUB
- **64KB memory bus** with memory-mapped I/O ports at `$C000-$C030`
- **Pre-loaded ROM** at `$F000-$F1FF` with working 6502 machine code routines
- **Retro terminal UI** with CRT effects (scanlines, vignette, glow, flicker)
- **Baud rate simulation** — characters stream in at 300/1200/2400/9600/14400 baud (F7 to cycle)
- **4 switchable retro fonts** — VT323, Press Start 2P, Share Tech Mono, IBM Plex Mono (F8 to cycle)
- **Procedural sound effects** — key clicks, carriage returns, bell, line feed
- **10 built-in demo programs** including an ASCII Mandelbrot set
- **Cross-platform** — runs on macOS, Windows, and Linux via Godot 4

## Quick Start

### Prerequisites

- **Godot 4.x** (4.0 or later) — [Download here](https://godotengine.org/download)

### Running

1. Open Godot and click **Import**
2. Select the `project.godot` file from this directory
3. Press **F5** to run

### First Steps

```
PRINT "HELLO WORLD"
```

Type `HELP` for a full command reference, or `DEMO` to see built-in programs.

```
DEMO          → lists all demos
DEMO mandelbrot → loads the Mandelbrot demo
RUN           → runs the loaded program
```

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| F1 | Show help |
| F5 | Run program |
| F7 | Cycle baud rate (300/1200/2400/9600/14400) |
| F8 | Cycle font |
| F10 | Full system reset |
| Up/Down | Command history |

## Project Structure

```
mygodot/
  project.godot          # Godot project configuration (4:3 aspect, GL compat renderer)
  main.tscn              # Main scene with CRT bezel frame
  scripts/
    basic_interpreter.gd  # BASIC language interpreter
    computer.gd           # Ties CPU + memory + BASIC together
    cpu_6502.gd           # Full MOS 6502 CPU emulator
    memory_bus.gd         # 64KB RAM with I/O port mapping
    rom.gd                # ROM routines at $F000+ and demo programs
    sound_manager.gd      # Procedural audio (key click, bell, carriage, etc.)
    terminal.gd           # Terminal UI controller (baud queue, fonts, CRT)
  shaders/
    crt_overlay.gdshader  # Scanline, vignette, curvature, glow shader
  fonts/
    vt323.ttf             # Retro terminal font (default)
    pressstart2p.ttf      # 8-bit pixel font
    sharetechmono.ttf     # Retro sci-fi mono
    ibmplexmono.ttf       # Clean corporate mono
  tests/
    test_regression.gd    # Full regression test suite
  GETTING_STARTED.md     # Installation and first steps
  USER_GUIDE.md           # Complete language and command reference
  PLAN.md                 # Architecture and development plan
```

## Memory Map

| Range | Purpose |
|-------|---------|
| `$0000-$00FF` | Zero Page (fast 6502 access) |
| `$0100-$01FF` | Stack |
| `$0200-$7FFF` | General purpose RAM |
| `$0800+` | BASIC program area |
| `$C000` | Keyboard data (read) |
| `$C001` | Keyboard status (1=data avail) |
| `$C002` | Screen output (write char) |
| `$C003` | Screen control ($0C=clear, $0D=newline) |
| `$F000-$F1FF` | ROM routines |
| `$FFFA-$FFFF` | CPU vectors (NMI, Reset, IRQ) |

## ROM Routines

The ROM is loaded automatically at startup. Use with `SYS` from BASIC:

| Address | Routine | Description |
|---------|---------|-------------|
| `$F000` | Warm Boot | Prints welcome message to screen |
| `$F020` | Char Out | Prints A register to screen port |
| `$F030` | String Out | Prints null-terminated string at $1C/$1D |
| `$F040` | Counter | Prints digits 0-9 with delay |
| `$F060` | Add Two | Adds 2 to accumulator |
| `$F080` | Fibonacci | Computes 8 Fibonacci numbers |
| `$F0C0` | Scroll | Alternating `*/` animation with delay |
| `$F100` | Hex Out | Prints A register as 2 hex digits |

## Configuration

### Window and Display

The project is configured for a **4:3 aspect ratio** (960x720) to match classic CRT monitors. Settings are in `project.godot`:

```
[display]
window/size/viewport_width=960
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
```

### CRT Bezel / Border Image

The terminal is wrapped in a `PanelContainer` with a `StyleBoxFlat` that provides the dark CRT bezel frame. To use a custom image:

1. Create a **4:3 aspect ratio** image (e.g., 960x720 or 1920x1440)
2. The image should represent a CRT monitor bezel — the center area will be transparent/cut-out for the terminal
3. Place it in `res://assets/bezel.png`
4. Edit `main.tscn` and replace `BezelPanel`'s style with a `StyleBoxTexture` pointing to your image
5. Adjust `VBoxContainer` margins to match the cutout area in your bezel image

**Bezel image specification:**
- **Aspect ratio**: 4:3 (width:height) — e.g., 1920x1440 for high-DPI
- **Format**: PNG with alpha channel
- **Center cutout**: Leave the terminal area transparent so the green text shows through
- **Outer area**: The bezel/body of the CRT monitor — can be any retro aesthetic (beige plastic, wood grain, metal, etc.)
- **Inner shadow**: Add a subtle inner shadow around the cutout to simulate screen depth
- **Corner radius**: The screen cutout should have ~4-8px radius to match the scene's StyleBox corner radius

### Baud Rate

Characters are output at the selected baud rate ÷ 10 characters per second. Cycle through rates with **F7**:

| Baud | Chars/sec | Feel |
|------|-----------|------|
| 300 | 30 | Extremely slow — teletype |
| 1200 | 120 | Slow — 1980s modem |
| 2400 | 240 | Moderate — default |
| 9600 | 960 | Fast — late 1980s |
| 14400 | 1440 | Instant — modern feel |

## Running Tests

From the command line:

```bash
godot --headless --script res://tests/test_regression.gd
```

Tests cover: Memory Bus, CPU (all opcodes, addressing modes, flags, stack, branches), BASIC (PRINT, variables, arithmetic, loops, GOSUB, functions, strings, arrays, POKE/PEEK), and Computer integration.

## License

This project is provided as-is for educational and recreational purposes. The included fonts are from Google Fonts (SIL Open Font License / Apache License).
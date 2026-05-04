# BASIC6502

A retro computing environment combining a **BASIC programming language interpreter** with a fully simulated **MOS 6502 microprocessor**, running inside the Godot game engine. Inspired by the Commodore 64, Apple II, and BBC Micro — with a dash of the Typewrite project's typewriter aesthetic.

## Features

- **Full MOS 6502 CPU emulation** — all 56 official opcodes, all addressing modes (immediate, zero page, absolute, indirect, indexed, etc.)
- **Complete BASIC interpreter** — PRINT, INPUT, FOR/NEXT, IF/THEN/ELSE, GOSUB/RETURN, DIM, READ/DATA, POKE/PEEK, string functions, math functions, ON GOTO/GOSUB, colon (`:`) statement separator, BREAK
- **Hex number notation** — prefix with `$` (e.g., `$FF`, `$C000`, `$DEAD`)
- **Binary file I/O** — `BSAVE` saves memory ranges, `BLOAD` loads binary files with optional destination address
- **Text file I/O** — `WRITE` creates text files, `READFILE` loads text into string variables
- **ROM cartridge system** — switchable carts via `CART` command; current carts: BASIC (default), TEXT (line editor), ASM (6502 assembler + HC65 `SAVEOBJ` / `LOADOBJ`)
- **64KB memory bus** with memory-mapped I/O ports at `$C000-$C030` and cart banking at `$E000-$EFFF`
- **Pre-loaded ROM** at `$F000-$F1FF` with working 6502 machine code routines
- **Retro terminal UI** with CRT effects (scanlines, vignette, glow, flicker, barrel distortion)
- **CRT warm-up simulation** — screen starts distorted and flickery, gradually settling over ~2 minutes; cold boot plays CRT static crackle sound
- **Boot sequence** — 5-second BIOS POST animation with "Hacker Computer Company" branding
- **System Settings panel** — press F3 to adjust curvature, scanlines, vignette, glow, and flicker with sliders, plus save/load state
- **Baud rate simulation** — characters stream in at 300/1200/2400/9600/14400 baud (F7 to cycle)
- **4 switchable retro fonts** — VT323, Press Start 2P, Share Tech Mono, IBM Plex Mono (F8 to cycle)
- **Procedural sound effects** — key clicks, warm bell (800Hz), line feed, carriage return, CRT crackle
- **Fullscreen by default** — immersive retro experience, mouse hidden until moved
- **12 built-in demo programs** including ASCII Mandelbrot, prime numbers, and pi calculation
- **Program line entry** — type `10 PRINT "HELLO"` to add/replace lines, type `10` alone to delete a line
- **LIST with ranges** — `LIST 30` shows one line, `LIST 10 100` shows a range
- **RUN with parameters** — `RUN N=10` sets variables before running; `RUN 100` starts at line 100
- **File management** — SAVE, LOAD, DIR, SCRATCH (delete), RENAME
- **System monitor** — Apple II-style hex editor, disassembler, register display, single-step
- **CPU clock simulation** — 0.5/1/10 MHz (F4 to cycle)
- **Save/load state** — full system persistence including memory, CPU, BASIC program, variables, CRT settings, and active cart
- **Context-sensitive HELP** — `HELP PRINT`, `HELP FOR`, etc. for detailed syntax and examples
- **Changelog** — see [CHANGELOG.md](CHANGELOG.md) for notable fixes and features by release
- **CLI test runner** — headless tests via `godot --headless -s test_cli.gd`; fuzz/strategy design in **`fuzz_testing_design.md`**
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
DEMO                → lists all demos
DEMO mandelbrot     → loads the Mandelbrot demo
DEMO primenums 100  → finds first 100 primes
DEMO pi 1000        → calculates pi with 1000 terms
RUN                 → runs the loaded program
```

### Entering Programs

Type a line number followed by a statement to add it to the program:

```
10 PRINT "HELLO"
20 END
LIST
RUN
```

Type a line number alone to delete it: `10` (deletes line 10).  
Use `:` to put multiple statements on one line: `10 A = 1 : PRINT A`

### Running with Parameters

```
RUN              → start from first line
RUN 100          → start at line 100
RUN N=10         → set N=10, then run
RUN 100, N=10    → start at line 100, set N=10
```

### File Management

```
SAVE MYPROG      → save program to disk
LOAD MYPROG      → load program from disk
DIR              → list saved programs (with sizes)
SCRATCH MYPROG   → delete a saved program (or DELETE)
RENAME OLD NEW   → rename a saved program
```

### Keyboard Shortcuts

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

## Project Structure

```
mygodot/
  project.godot          # Godot project configuration (4:3, fullscreen, GL compat)
  main.tscn              # Main scene with CRT bezel frame
  scripts/
    basic_interpreter.gd  # BASIC language interpreter (tokenizer, parser, evaluator)
    computer.gd           # Ties CPU + memory + BASIC + carts together
    cpu_6502.gd           # Full MOS 6502 CPU emulator with disassembler
    memory_bus.gd         # 64KB RAM with I/O port mapping and cart banking
    rom.gd                # ROM routines at $F000+ and demo programs
    sound_manager.gd      # Procedural audio (key click, bell, carriage, crackle)
    terminal.gd           # Terminal UI controller (baud queue, fonts, CRT, monitor)
    debug_manager.gd      # Screenshot and video recording
    cart_manager.gd       # ROM cartridge switching system
    rom_cart.gd           # Base class for banked ROM cartridges
    cart_basic.gd         # BASIC6502 cartridge (default)
    cart_text.gd          # Line editor cartridge
    cart_asm.gd           # 6502 assembler cart (ASM, RUN, DEMO, SAVE/LOAD .asm)
    assembler6502.gd      # Two-pass assembler used by cart_asm
    hc65_object.gd        # HC65 .obj encode/decode (SAVEOBJ / LOADOBJ)
  shaders/
    crt_overlay.gdshader   # Scanline, vignette, curvature, glow, flicker, brightness, static
  fonts/
    vt323.ttf              # Retro terminal font (default)
    pressstart2p.ttf       # 8-bit pixel font
    sharetechmono.ttf      # Retro sci-fi mono
    ibmplexmono.ttf        # Clean corporate mono
  archives/
    basic_games_disk_catalog.md  # Text-only vintage BASIC games; 140 KiB/side (A/B) floppy concept
  tests/
    test_regression.gd     # Full regression test suite (BASIC + CPU)
    test_cli.gd            # Headless CLI test runner
  CHANGELOG.md             # Notable changes (Keep a Changelog style)
  GETTING_STARTED.md      # Installation and first steps
  USER_GUIDE.md            # Language + commands + **hands-on ASM→BSAVE→SYS tutorial**
  PLAN.md                  # Architecture and development plan
  TODO.md                  # Boot loader & ROM banking plans
  next_steps.md            # Roadmap: carts, ASM, Small-C, HC65 objects / LOADOBJ
  trainer.md               # Plan: Trainer cart — teach BASIC + ASM in-game
  fuzz_testing_design.md   # Plan: fuzz testing + fixture-based BASIC/ASM CLI tests
  CPU_Emulator_Bugs.md     # Known CPU emulator bugs and fix suggestions
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

The project starts in **fullscreen** mode for an immersive retro experience. The internal resolution is **960x720** (4:3 aspect ratio) matching classic CRT monitors. Settings are in `project.godot`:

```
[display]
window/size/viewport_width=960
window/size/viewport_height=720
window/size/mode=3          # 3 = fullscreen
window/stretch/mode="canvas_items"
window/resizable=true
```

The mouse cursor is hidden by default and appears when you move the mouse, disappearing after 3 seconds of inactivity.

### CRT Bezel / Border Image

The terminal is wrapped in a `PanelContainer` with a `StyleBoxFlat` that provides the dark CRT bezel frame. To use a custom image:

1. Create a **4:3 aspect ratio** image (e.g., 960x720 or 1920x1440)
2. The image should represent a CRT monitor bezel — the center area will be transparent/cut-out for the terminal
3. Place it in `res://assets/bezel.png`
4. Edit `main.tscn` and replace `BezelPanel`'s style with a `StyleBoxTexture` pointing to your image
5. Adjust `VBoxContainer` margins to match the cutout area in your bezel image

### System Settings Panel (F3)

Press **F3** to open the System Settings panel on the right side of the screen. Five sliders control the CRT effect in real-time:

| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| Curvature | 0.01 | 0.0–1.0 | Barrel distortion (0=flat, 0.01=subtle, 1.0=extreme) |
| Scanlines | 0.04 | 0.0–0.3 | Horizontal scanline darkness |
| Vignette | 0.18 | 0.0–1.0 | Edge darkening |
| Glow | 0.18 | 0.0–1.0 | Phosphor bloom intensity |
| Flicker | 0.005 | 0.0–0.05 | Random brightness variation |

### CRT Warm-Up & Boot Sequence

On a fresh launch (no saved state), the terminal plays a **5-second boot sequence** simulating a BIOS POST with "Hacker Computer Company" branding, then shows the `READY.` prompt.

The CRT also simulates **warm-up** over ~2 minutes. On cold start:
- **Curvature** starts at 0.10 and decays to the slider value
- **Vignette** starts at 1.0 (full) and decays to its setting
- **Flicker** starts at 0.05 (maximum) and decays down
- **Scanlines** start at 0.15 and settle to their setting
- **Glow** starts at 0.6 and settles
- **Brightness** fades from 0 to 1 over 4 seconds during boot
- **Static** crackle sound plays during boot, fading out over ~3 seconds

All values ease out with a cubic curve. When a saved state is loaded, the warm-up is skipped.

### Save / Load State

The **Save State** button in the System Settings panel saves the complete system state to `user://savestate.json`:

- All CRT settings (curvature, scanlines, vignette, glow, flicker)
- Selected font and baud rate
- 64KB memory contents (RAM, ROM, I/O state)
- CPU registers (A, X, Y, SP, PC, flags)
- BASIC program, variables, and arrays
- Command history

The state is **automatically loaded on startup** if a save file exists. Use **Load State** to manually reload, or **Save State** to update the file.

### Baud Rate

Characters are output at the selected baud rate ÷ 10 characters per second. Cycle through rates with **F7**:

| Baud | Chars/sec | Feel |
|------|-----------|------|
| 300 | 30 | Extremely slow — teletype |
| 1200 | 120 | Slow — 1980s modem |
| 2400 | 240 | Moderate — default |
| 9600 | 960 | Fast — late 1980s |
| 14400 | 1440 | Instant — modern feel |

## Debug & Recording

### Screenshots (F9)

Press **F9** at any time to save a screenshot. Files are saved to:
- **macOS**: `~/Library/Application Support/Godot/app_userdata/BASIC6502/debug/screenshots/`
- **Linux**: `~/.local/share/godot/app_userdata/BASIC6502/debug/screenshots/`
- **Windows**: `%APPDATA%/Godot/app_userdata/BASIC6502/debug/screenshots/`

### Video Recording (F6)

Press **F6** to start recording. The status bar shows `[REC]` and a frame counter. Press **F6** again to stop. Frames are saved as sequential PNGs to `debug/video/frames_<timestamp>/`.

Convert to MP4 with ffmpeg:
```bash
ffmpeg -framerate 30 -i frame_%05d.png -c:v libx264 -pix_fmt yuv420p output.mp4
```

### Scriptable Debug API

The `DebugManager` is accessible from other GDScript via `debug`:
```gdscript
debug.take_screenshot()           # Returns file path
debug.start_recording()            # Begin frame capture
debug.stop_recording()              # Stop and save frames, returns dir path
debug.toggle_recording()            # Toggle on/off
debug.is_recording()                # Check state
debug.get_frame_count()             # Current frame count
debug.execute_command("screenshot") # Command interface
debug.execute_command("record")     # Start recording via string
debug.execute_command("stop")       # Stop recording via string
debug.execute_command("status")     # Get current state
```

## Running Tests

From the command line:

```bash
godot --path . --headless -s tests/test_regression.gd
godot --path . --headless -s tests/test_cli.gd
```

Tests cover: Memory Bus, CPU (all opcodes, addressing modes, flags, stack, branches), BASIC (PRINT, variables, arithmetic, loops, GOSUB, functions, strings, arrays, POKE/PEEK, colon separator), carts, assembler/HC65, and Computer integration.

Planned fuzz / expanded CLI suites are described in **`fuzz_testing_design.md`** (random BASIC & ASM generation, timeouts, fixture `.bas` files, CI hooks).

## License

This project is provided as-is for educational and recreational purposes. The included fonts are from Google Fonts (SIL Open Font License / Apache License).
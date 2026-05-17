# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
where versioning applies.

## [Unreleased]

### Added

- **`GDD.md` — Game Design Document for "signal.zero"**: full 300-line GDD for an open-world hacking simulator RPG with three gameplay modes (Keyboard Time = existing teaching lab; Hands On Hardware = circuit puzzle mode; Overworld = Earth Bound–style top-down adventure). Covers vision, narrative, progression loop, inventory, art/audio direction, dev phases, and monetization.

- **GPU Phase 9a — Initial GPU device** (pluggable `gpu_base.gd` abstract class + `gpu_device.gd`): memory-mapped at $E000-$EFFF, 40×25 text mode + 160×120 bitmap mode, 16-color CGA palette, 5×7 pixel font, pixel-plot via control registers. Draw commands via command register at $EFFF: PLOT(1), LINE(2), RECT(3), RECT_OUT(4), HLINE(5), VLINE(6), CIRCLE(7), CIRCLE_FILL(8), CLS(9). Bresenham line/circle algorithms. GPU panel (TextureRect, 640×480, nearest-neighbor scaling) toggled via F12 or `GRAPHICS` command. 17 GPU-specific regression tests.

- **GPU Phase 9b — GPU expansion**: tile/map overlay mode (MODE_TEXT_BITMAP=3) with both layers, transparent text background so bitmap shows through. Blit command (CMD_BLIT=10) framebuffer copy. New demos GPU_OVERLAY and GPU_BLIT. Cursor registers changed to 8-bit raw storage for blit destination. 4 new regression tests.

- **Trainer Cart P0 — Spike** (`cart_trainer.gd`, id=5): HELP, MENU, OPEN, NEXT, BACK, QUIZ, ANSWER, PROGRESS commands. 3 lessons (Hello BASIC, Variables, IF/THEN/ELSE). MC quiz type with hint feedback. Curriculum loaded from `trainer/curriculum.json`. Progress in serialized cart state.

- **Trainer Cart P1 — Expansion**: 3 new BASIC lessons (FOR/NEXT, GOSUB/RETURN, INPUT/GET). GPU Graphics module with 3 lessons (GPU Basics, Drawing Shapes, Animation). FILL quiz type (text-based answer with alternatives). 10+ new MC quizzes, 3 FILL quizzes. Curriculum version 2.

- **Segment clock** (`segment_clock.gd`): 7-segment LED-style clock display replacing BaudLabel/FontLabel in the top bar. Three modes: green, red, off.

- **Page/more system**: output pauses after 25 lines with `-- MORE --` prompt; any keypress resumes the stream.

- **BASIC `GRAPHICS`/`GPU` and `EXEC` commands**: `GRAPHICS` toggles GPU panel; `EXEC "command"` routes string to terminal via signals.

- **Higher baud rates**: 57600 and 115200 added (default changed to 115200).

### Changed

- **terminal.gd major refactor**: debug panel moved from inline to DebugManager (widgets stored as terminal members, not panel children). GPU panel added as TextureRect. Segment clock replaces top-bar baud/font labels. Page-pause system integrated into `_stream_char_by_char`. GPU framebuffer polled in `_process()` via `_dirty` flag. `_page_lines`/`_page_paused`/`_page_saved_text` for MORE paging.

- **computer.gd**: GPU instance wired from `memory_bus_6502._gpu`. `graphics_requested` and `command_requested` signals added. Trainer cart registered in `CartManager`. Serialization order fixed: cart switch before memory/cpu restore.

- **memory_bus_6502.gd**: GPU device registered as I/O device at $E000-$EFFF in peek/poke/reset chain. GPU serialized/deserialized in save state.

- **backlog.md**: GPU phases 9a/9b and Trainer P0/P1 marked done. Priority order updated. Phase 9a/9b and P0/P1 detailed done sections added. Trainer user stories (US-T.1–T.10) and LOAD stories added. All ~3877 checks referenced.

- **trainer.md**: Updated to reflect P1 done (BASIC+GPU lessons, FILL quiz type). Added G6 (voice/tone — hacker-culture, conspiratorial). GPU lesson examples added. Implementation sections updated from speculative to completed. Version bumped to 1.2.

### Fixed

- **native_basic_softfloat.gd**: `div_bits` integer division changed from `int(num / mb)` to `int(float(num) / mb)` to avoid 64-bit integer edge cases. `_combine` parameter renamed from `sign`→`s` to avoid shadowing built-in.

- **GPU cursor clamping removed**: cursor registers ($EFF3-4) changed from modulo-clamped (to 40/25) to 8-bit raw storage, needed for blit destination in bitmap mode.

- **Serialization order**: `computer.gd` deserialize now switches cart *before* restoring memory/cpu state, preventing stale state mismatches.

### Added

- **`cart_native.gd`** (**`NATIVE`** cart, id **4**): **`HYBRID`** / **`NATIVE`** / **`STATUS`** toggles **`BasicInterpreter.basic_runtime_mode`**; **`native_basic_softfloat.gd`** implements IEEE754 binary32 **`+ − × ÷`** (and comparisons via decode) for **NATIVE** mode — groundwork for a future **6502** soft-float pack callable from the emulator.
- **`TESTING.md`**: single reference for **all headless suites** (regression blocks, CLI battery, **65x02** step tests, fuzz rounds, CLI flags, `run_all_tests.sh`).
- **`scripts/run_all_tests.sh`**: runs regression → **`test_processor_step_tests.gd`** → CLI → fuzz (optional **`GODOT`**, **`FUZZ_ITERS`**, **`FUZZ_SEED`**).
- **`tests/test_processor_step_tests.gd`** plus **`tests/fixtures/processor_tests/`**: vendored subset of **[SingleStepTests / 65x02](https://github.com/SingleStepTests/65x02)** (MIT, **Thomas Harte et al.**); **`build_subset.py`** regenerates JSON from upstream; see **`tests/fixtures/processor_tests/README.md`**.
- **Regression**: TEXT cart — **`LIST`** range + **`PRINT`**, **`SAVE`/`LOAD`** `.txt` round-trip, **`CATALOG`** + **`SCRATCH`** missing file. C cart — **`BUILD`** alias, **`DEL`** line, **`DEMO`/`DEMOS`** list + unknown demo, **`SAVE`/`LOAD`** `.c` then **`COMPILE`**.
- **Fuzz smoke**: **`TEXT`** and **`C`** cart command batches (whitelist; omit random **`COMPILE`/`BUILD`/`RUN`** on garbage C to avoid stalls); global budget **120s**, **5 × iterations** pass checks by default.
- **`CartManager.release_cart_backrefs()`**, **`MemoryBus.disconnect_all_signal_links()`**, **`Computer.disconnect_memory_signal_links()`**: break **`RefCounted`** cycles so headless tests exit without Godot **ObjectDB / resources still in use** warnings (CLI/dispose helpers updated).
- **`REBOOT`** command (handled in **`CartManager`** so it works from BASIC, ASM, TEXT, and C carts): deep reset clears **all** cart editor buffers (**`ROMCart.reboot_clear_state()`**), RAM, BASIC interpreter, returns to BASIC cart; **`Computer.request_full_reboot()`** runs that logic even headless. Terminal listens for **`full_reboot_requested`** to replay **BIOS POST** CRT sequence (`_boot_done` / `_boot_phase` reset). **`RESET`** remains a faster path without POST and without clearing ASM/TEXT/C line buffers.
- **`tests/test_fuzz_smoke.gd`**: headless fuzz — whitelist BASIC **`execute_line`**, random assembler **`editor_lines`**, **`CPU6502.run`** at **`$0800`**, plus **TEXT** / **C** cart commands; CLI **`--fuzz-iters`** / **`--fuzz-seed`** (see **`fuzz_testing_design.md`** and **`TESTING.md`**).
- **`fuzz_testing_design.md`**: design for **fuzz testing** (BASIC, assembler, CPU, memory, carts), **hang detection**, CLI **`--fuzz-seed`** / iteration hooks, **`tests/fixtures/`** BASIC/ASM expansion, and CI staging—complements **`test_regression.gd`** / **`test_cli.gd`**.
- **`archives/basic_games_disk_catalog.md`**: curated **text-only** classic BASIC games (Ahl anthology + magazine lineage), selection criteria, **Side A / B** placement notes, and **`§ Virtual floppy`** (**140 KiB** per side, **280 KiB** double-sided disk).
- **`trainer.md`**: design plan for a future **Trainer** ROM cart — in-game BASIC + ASM curriculum (keywords, operators, mnemonics, interactive quizzes), pedagogy, and engineering requirements.
- **HC65 object module** (`scripts/hc65_object.gd`): encode/decode for `.obj` blobs used by `SAVEOBJ` / `LOADOBJ`.
- **BASIC `LOADOBJ`**: load a HC65 object from `user://`, optional `, NAME` to register a **native-style statement** (callable like a BASIC keyword after load).
- **Assembler directives** for HC65 metadata: `.EXPORT`, `.ENTRY`, `.HELP_SYNTAX`, `.HELP_DESC`, `.HELP_EXAMPLE` (see assembler source and user guide).
- **`MemoryBus.prepare_cpu_stack_for_user_rts()`**: shared setup so short 6502 programs that end in **`RTS`** without a prior **`JSR`** return cleanly (halt at `$FFF0` via undefined opcode `$FF`).
- **ASM cart HELP**: section **“6502 instructions (what the assembler accepts)”** listing supported mnemonics, operand forms, and simulator I/O (`$C002` / `$C003` / `$C030`).
- **Regression tests**: assembled **stars** demo run (exactly ten `*`), **hello**-style object run (single `A` + halt), and extended coverage for carts / HC65 where applicable.

### Fixed

- **6502 `BRK`**: stack now receives **PC + 2** (NMOS: opcode + phantom byte); matches external step tests (**65x02** corpus).
- **Opcode `$D6`**: **`DEC` zero-page,X** — decoding wrongly used **ZPY**; corrected (**-assembler opcode table was already correct**).
- **Bare `RTS` runaway**: `ASM` cart **RUN**, BASIC **`SYS`**, and **LOADOBJ**-registered native calls each seed the stack before `cpu.run`, so execution no longer loops via empty-stack `RTS` → low memory → **`BRK`** → IRQ vector at **`$0800`** (which caused floods of `*` / `A` / stray output).

### Changed

- **Virtual floppy model**: dropped the single **~420K** byte-budget sketch in favor of **140 KiB per side** (**143,360 B**, Apple II–style sector arithmetic), **Side A / Side B**, and **280 KiB** per double-sided disk (`TODO.md`, `PLAN.md`, `HACKER_COMPUTER_6502.md`, `README.md`, `archives/basic_games_disk_catalog.md`).
- **User-facing docs** (`README.md`, `GETTING_STARTED.md`, `USER_GUIDE.md`, `PLAN.md`, `TODO.md`): aligned with ROM carts, `CART` switching, ASM editor, HC65 workflow, and `SYS` / memory map notes.
- **`terminal.gd`**: help and command text updates where carts and `SYS` / `LOADOBJ` are described.

### Removed

- **`ASM_AND_C.md`**: removed as a standalone doc; material superseded by **`next_steps.md`** (roadmap) and by **`USER_GUIDE.md`** / README updates.

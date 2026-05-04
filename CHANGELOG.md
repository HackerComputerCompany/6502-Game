# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
where versioning applies.

## [Unreleased]

### Added

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

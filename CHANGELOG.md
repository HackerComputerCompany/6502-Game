# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
where versioning applies.

## [Unreleased]

### Added

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

- **Bare `RTS` runaway**: `ASM` cart **RUN**, BASIC **`SYS`**, and **LOADOBJ**-registered native calls each seed the stack before `cpu.run`, so execution no longer loops via empty-stack `RTS` → low memory → **`BRK`** → IRQ vector at **`$0800`** (which caused floods of `*` / `A` / stray output).

### Changed

- **Virtual floppy model**: dropped the single **~420K** byte-budget sketch in favor of **140 KiB per side** (**143,360 B**, Apple II–style sector arithmetic), **Side A / Side B**, and **280 KiB** per double-sided disk (`TODO.md`, `PLAN.md`, `HACKER_COMPUTER_6502.md`, `README.md`, `archives/basic_games_disk_catalog.md`).
- **User-facing docs** (`README.md`, `GETTING_STARTED.md`, `USER_GUIDE.md`, `PLAN.md`, `TODO.md`): aligned with ROM carts, `CART` switching, ASM editor, HC65 workflow, and `SYS` / memory map notes.
- **`terminal.gd`**: help and command text updates where carts and `SYS` / `LOADOBJ` are described.

### Removed

- **`ASM_AND_C.md`**: removed as a standalone doc; material superseded by **`next_steps.md`** (roadmap) and by **`USER_GUIDE.md`** / README updates.

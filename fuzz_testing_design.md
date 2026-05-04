# Fuzz testing design — BASIC6502

This document specifies **how to add fuzzing and expanded automated testing** so we find **crashes**, **infinite loops**, **panics**, and **silent invariant violations** in the interpreter, assembler, CPU, memory layer, and carts—using the existing **Godot headless** workflow (`godot --path . --headless -s …` from the repo root).

**What runs today:** **[TESTING.md](TESTING.md)** lists every regression block, CLI case, and the implemented fuzz smoke rounds (`tests/test_fuzz_smoke.gd`), plus `./scripts/run_all_tests.sh`. Below sections remain the **design / roadmap** for corpus, fixtures, heavier fuzz workers, and CI.

---

## 1. Goals and non-goals

### Goals

| ID | Goal |
|----|------|
| **G1** | **No hard crashes** when fed arbitrary **UTF-8-ish terminal input**, **BASIC source**, **ASM lines**, or **binary blobs** at CPU boundaries—within documented limits. |
| **G2** | **Bounded execution**: BASIC runs and CPU `run()` never exceed a **wall-clock or step budget** (detect hangs). |
| **G3** | **Reproducibility**: every fuzz finding has a **seed** + **minimal input** checked into `tests/fuzz_corpus/` or issue tracker. |
| **G4** | **CLI-first**: fuzz smoke and unit batches run in **headless** mode suitable for **CI** (no GPU, no manual clicks). |
| **G5** | Grow **structured BASIC + ASM unit tests** (tables, fixtures, parametrized cases) alongside dumb fuzz—**coverage** + **regression**. |

### Non-goals (initial)

- Bit-exact cross-engine comparison with Applesoft or MS BASIC.
- Native **AFL++/libFuzzer** binaries against Godot **without** subprocess wrapping (possible later; heavier ops).
- Formal proofs of correctness.

---

## 2. Bug classes to hunt

| Class | Symptom | Typical causes |
|-------|---------|----------------|
| **Crash** | Process exit / Godot fatal | Null deref, index OOB on `PackedByteArray`, infinite recursion |
| **Hang** | No progress past budget | `FOR`/`NEXT` mismatch, runaway `GOTO`, CPU spin |
| **Assertion / engine error** | Red stderr, test failure | `push_error`, failed `_assert` in debug |
| **Memory corruption** | Later test flakes | Aliasing RAM, wrong poke side effects |
| **Spec drift** | Accepted invalid program | Tokenizer too permissive |

---

## 3. Existing harness (do not reinvent)

| Asset | Role |
|-------|------|
| **`tests/test_regression.gd`** | Main suite: `extends SceneTree`, `_init()` runs tests then quits. Memory, CPU, BASIC, carts, assembler, HC65, files. See **[TESTING.md](TESTING.md) §1**. |
| **`tests/test_processor_step_tests.gd`** | Vendored **[SingleStepTests/65x02](https://github.com/SingleStepTests/65x02)** JSON subset — single **`CPU6502.step()`** oracle vs **`final`** state (**Thomas Harte et al.**, MIT). Attribution under **`tests/fixtures/processor_tests/`**. See **[TESTING.md](TESTING.md) §2**. |
| **`tests/test_cli.gd`** | `Computer.new()` battery: loops, **BSAVE/BLOAD**, **WRITE/READFILE**, arithmetic/IF/GOSUB/arrays; optional **`godot --path . --headless -s tests/test_cli.gd res://path/to/file.bas`**. See **[TESTING.md](TESTING.md) §3**. |
| **`tests/test_fuzz_smoke.gd`** | **Shipped** P0 fuzz smoke: **five rounds** × **`--fuzz-iters`** — BASIC **`execute_line`**, **`assemble`** line bundles, **`CPU6502.run`** at **`$0800`** with **`prepare_cpu_stack_for_user_rts`**, **TEXT** cart commands, **C** cart commands (no random **`COMPILE`/`BUILD`/`RUN`**); **`--fuzz-iters`** / **`--fuzz-seed`**; global **~120s** wall-clock budget; **`quit(1)`** on failure. See **[TESTING.md](TESTING.md)** fuzz section. |
| **`Computer`**, **`BasicInterpreter`**, **`Assembler6502`**, **`CPU6502`**, **`MemoryBus`** | Fuzz targets and **oracles**. |

**Convention:** new fuzz drivers live under **`tests/`** as `test_fuzz_*.gd` (SceneTree scripts) so CI invokes them like regression tests.

---

## 4. Fuzz strategies by subsystem

### 4.1 BASIC — generation + mutation

**Inputs:** multi-line programs (line numbers + statements), single **`execute_line`** strings, **`INPUT`** continuation paths.

**Generators (random composition):**

- **Token soup:** keywords from `_keywords` (`basic_interpreter.gd`), identifiers, numbers, `$hex`, operators `+-*/^=<>`, strings with escapes, `:` separators, `REM` tails.
- **Structure-aware:** templates with holes: `IF _ THEN _ ELSE _`, `FOR I = _ TO _ STEP _`, `ON X GOTO _,_,_`, `READ`/`DATA` arity mismatches on purpose.
- **Mutations:** start from **seed corpus** (demos from `rom.gd`, minimal regressions) → delete/duplicate/replace line, flip operator, strip closing quote.

**Oracle / checks:**

- Run inside **`Computer.run_basic_sync`** or manual loop with **`step_basic(max_lines)`** + **iteration cap**.
- **Timeout:** `Time.get_ticks_msec()` guard; exceed → fail test, dump program hex or base64 to log.
- **Properties:** stack depths **`_gosub_stack`**, **`_for_stack`** bounded by program size (expose read-only getters if needed for tests only).

**Crash isolation:** Godot GDScript rarely segfaults from script alone; **engine bugs** may still abort. Optional: **outer shell loop** re-invokes `godot --headless -s tests/test_fuzz_basic.gd -- --seed=N` per seed in CI for process-level isolation.

### 4.2 Assembler — fuzz lines + two-pass stress

**Inputs:** single **`assemble(memory, editor_lines)`** calls with arrays of `[line_no, text]`.

**Generators:**

- Mnemonic + random operand: `LDA #$XX`, `STA $XXXX`, `BNE LABEL`, illegal combos (branch out of range).
- Label chaos: duplicate labels, missing labels, `LOOP:` without target.
- Directives: `.ORG`, `.EQU`, `.BYTE` garbage, `.HELP_*` quoting edge cases.

**Oracle:**

- Must get **`errors.size() >= 0`** without throwing; **`assemble` returns bool**—never assume success.
- Optionally **disassemble** emitted range and ensure **`last_start..last_end`** inside `[0x0800, 0xFFFF]` and object contiguous.

### 4.3 CPU — random opcode streams

**Inputs:** random bytes at **`PC`**, or execute from **`0x0800`** after random **`poke`** fill.

**Strategy:**

- **`cpu.step()`** in a loop with **`max_steps`** (e.g. 10⁴–10⁶); **`halted`** stops early.
- Track **`PC`** diversity—detect tight **two-byte infinite loops** as hang if PC repeats > K times with same SP.

**Oracle:**

- No uncaught engine crash; SP stays in **`[0x00, 0xFF]`**; optional invariant **`cycles`** monotonic.

### 4.4 MemoryBus — poke/peek fuzz

**Inputs:** random **`addr`**, **`val`** pairs.

**Oracle:**

- **`peek(poke(x))`** consistency for **RAM-backed** addresses; I/O ports **`$C002/$C003`** never throw; **`cart_switch_requested`** may fire—fuzz driver should **disconnect** signal or use fresh **`Computer`** per iteration to avoid side effects.

### 4.5 Terminal / carts — command fuzz

**Inputs:** strings fed to **`cart_manager.handle_command`** or **`terminal`** parsing paths.

**Strategy:**

- Random **`CART`**, **`ASM`**, **`LIST`**, **`10 PRINT …`** mix when cart is BASIC vs ASM.
- Max length cap (e.g. 4 KiB) to mimic realistic typing.

**Oracle:**

- Returns **`handled` bool** without crash; screen buffer bounded.

---

## 5. Structured unit tests (BASIC + ASM)

Fuzz complements **deterministic** tests. Plan explicit suites:

### 5.1 BASIC fixture files

- Directory **`tests/fixtures/basic/`**: `print_echo.bas`, `for_nested.bas`, `on_gosub_edge.bas`, …
- Runner: extend **`test_cli.gd`** or add **`tests/test_basic_fixtures.gd`** that **`DirAccess.open("res://tests/fixtures/basic/")`**, runs each file, compares **snapshot** or **substring** expectations.
- One **keyword-focused** file per cluster (aligned with **`trainer.md`** inventory later).

### 5.2 ASM fixture tables

- **`tests/fixtures/asm/`**: `.asm` as line-array JSON or raw multi-line text parsed into **`editor_lines`**.
- Assert **`assemble` ok**, **`hex`** fingerprint of object bytes, optional **`cpu.run`** with **`prepare_cpu_stack_for_user_rts`**.

### 5.3 Parametric tests (GDScript)

Table-driven arrays:

```gdscript
var cases := [
    ["10 PRINT 1+2*3", "7"],
    ["10 IF 1 THEN PRINT \"OK\"", "OK"],
]
for c in cases:
    assert_output(c[0], c[1])
```

Keeps **`test_regression.gd`** readable while growing coverage.

---

## 6. CLI / CI integration

### 6.1 Commands

```bash
# All suites (regression + CLI + fuzz smoke); env: GODOT, FUZZ_ITERS, FUZZ_SEED
./scripts/run_all_tests.sh

# Regression
godot --path . --headless -s tests/test_regression.gd

# 65x02 JSON step subset (external corpus)
godot --path . --headless -s tests/test_processor_step_tests.gd

# CLI battery (optional path to .bas / .txt / .bin)
godot --path . --headless -s tests/test_cli.gd

# Fuzz smoke (deterministic seed / iteration count)
godot --path . --headless -s tests/test_fuzz_smoke.gd -- --fuzz-seed=12345 --fuzz-iters=500

# Planned: long-running BASIC-only fuzz worker (nightly / optional)
godot --path . --headless -s tests/test_fuzz_basic.gd -- --fuzz-seed=$SEED --fuzz-iters=200000
```

**`test_fuzz_smoke.gd`** parses **`OS.get_cmdline_user_args()`** (arguments after `--`) for **`--fuzz-seed`** / **`--fuzz-iters`** (minimum iterations enforced in harness).

### 6.2 CI matrix

| Job | Frequency | Command |
|-----|-----------|---------|
| **PR** | Every push | `./scripts/run_all_tests.sh` or `test_regression.gd` + `test_cli.gd` (+ optional fuzz)
| **Nightly** | Daily | Above with **`test_fuzz_smoke.gd`** at higher **`--fuzz-iters`** or multi-seed loop |
| **Weekly** | Low priority | Multi-seed loop shell script × subprocess |

### 6.3 Exit codes

- Tests **`quit(exit_code)`** with **0** pass, **1** any failure—document for Actions.

---

## 7. Corpus and seeds

| Corpus | Contents |
|--------|----------|
| **`tests/fuzz_corpus/basic/`** | Minimal valid programs + historical crash reproducers |
| **`tests/fuzz_corpus/asm/`** | Label/branch edge cases |
| **`tests/fuzz_corpus/terminal/`** | Weird but typed commands |

**Rule:** any bug fixed via fuzz gets a **regression .bas or .asm** file committed.

---

## 8. Roadmap

| Phase | Deliverable |
|-------|-------------|
| **P0** | **`tests/test_fuzz_smoke.gd`** (landed): five rounds — BASIC **`execute_line`**, **`assemble`** fuzz, **`CPU.run`** at **`$0800`**, **TEXT** cart, **C** cart (whitelist; omit random compile/run); **`--fuzz-iters`** / **`--fuzz-seed`**; **~120s** global budget + per-call stall caps; nonzero exit on failure. |
| **P1** | Fixture runner + **`tests/fixtures/basic/`** (10–20 files). |
| **P2** | Mutation engine from corpus + **`--fuzz-seed`**. |
| **P3** | Heavier cart command fuzz + memory poke fuzz (beyond shipped TEXT/C whitelist rounds). |
| **P4** | CI nightly workflow YAML + artifact upload of failing input. |
| **P5** | Optional **Rust/C++** grammar fuzzer **out-of-process** feeding `.bas` files if GDScript throughput insufficient (stretch). |

---

## 9. Risks

| Risk | Mitigation |
|------|------------|
| False-positive hangs | Tune **`step_basic`** limits vs legitimate long loops |
| Slow CI | Keep PR fuzz **small**; heavy fuzz nightly |
| Non-deterministic `RND` | Seed **`RandomNumberGenerator`** in BASIC tests explicitly |
| Flaky cart state | **`Computer.new()`** per iteration or explicit **`reset()`** |

---

## 10. Related docs

- **`TESTING.md`** — authoritative list of regression blocks, CLI tests, fuzz smoke behavior, and flags.
- **`CHANGELOG.md`** — notable harness changes.
- **`trainer.md`** — future lesson on “why we fuzz inputs.”
- **`CPU_Emulator_Bugs.md`** — historical bug notes; use **65x02** JSON + regression as primary oracles for CPU changes.

---

*Document version: 1.2 — BASIC6502 / 6502-Game. See TESTING.md for suite inventory.*

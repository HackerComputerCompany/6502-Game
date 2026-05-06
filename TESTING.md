# Automated testing — BASIC6502

All suites run **headless** (no GPU window): they extend `SceneTree`, execute in `_init()`, print results, then `quit()` with exit code **0** on success. Failures increment internal counters and may call `quit(1)` (fuzz) or still exit **0** but print `FAILED > 0` (regression/CLI — check stdout).

For design goals, future corpus/fixtures, and CI ideas, see [fuzz_testing_design.md](fuzz_testing_design.md).

---

## Run everything

From the repository root:

```bash
./scripts/run_all_tests.sh
```

This runs **regression**, **65x02 JSON step tests**, **CLI**, then **fuzz smoke** (default `FUZZ_ITERS=400`, `FUZZ_SEED=42`). Overrides:

| Variable | Meaning |
|----------|---------|
| `GODOT` | Path to Godot binary (default: `godot` on `PATH`) |
| `FUZZ_ITERS` | Iterations per fuzz round (minimum **10** enforced in script target) |
| `FUZZ_SEED` | Unsigned seed passed to `--fuzz-seed` |

---

## 1. Regression suite — `tests/test_regression.gd`

Single-process **deterministic** checks: memory bus, CPU opcodes and flows, BASIC language features, `Computer` wiring, cartridges, assembler/HC65, and file helpers. Each logical block prints `Running: <name>` and uses internal `_assert` calls (counts toward PASSED/FAILED).

### Memory and boot layout

| Block | What it checks |
|-------|----------------|
| **MemoryBus** | `peek`/`poke`, word helpers, 16-bit wrap, `reset`, `load_bytes` |
| **Memory Reset Vectors** | Reset/IRQ vectors and `$FC00` boot stub bytes |

### CPU (isolated `CPU6502` + `MemoryBus`)

| Block | What it checks |
|-------|----------------|
| **CPU Load/Store** | LDA/LDX/LDY, STA/STX/STY across addressing modes |
| **CPU Arithmetic** | ADC/SBC/INC/DEC (decimal mode off), flags |
| **CPU Logical** | AND/OR/EOR |
| **CPU Shift/Rotate** | ASL/LSR/ROL/ROR |
| **CPU Comparisons** | CMP/CPX/CPY |
| **CPU Branches** | BEQ/BNE/etc. |
| **CPU Stack** | PHA/PHP/PLA/PLP/TSX/TXS |
| **CPU Jumps/Subroutines** | JMP/JSR/RTS |
| **CPU Flag Instructions** | CLC/SEC/CLV/etc. |
| **CPU Transfers** | TAX/TAY/TXA/TYA/TXS |
| **CPU NOP/BRK** | NOP and BRK behavior |

### BASIC (via interpreter / computer paths as coded)

| Block | What it checks |
|-------|----------------|
| **BASIC PRINT** | Literal and expression output |
| **BASIC Variables** | LET and numeric storage |
| **BASIC Arithmetic** | Expressions and precedence |
| **BASIC IF/THEN** | Conditional execution |
| **BASIC FOR/NEXT** | Loops |
| **BASIC GOSUB/RETURN** | Subroutines |
| **BASIC Built-in Functions** | Selected builtins |
| **BASIC String Functions** | String ops |
| **BASIC Arrays** | DIM and indexing |
| **BASIC READ/DATA** | Data statements |
| **BASIC POKE/PEEK** | Memory from BASIC |
| **BASIC ON GOSUB** | Computed dispatch |
| **BASIC Nested FOR/NEXT** | Nested loops |
| **BASIC FOR STEP** | STEP > 1 |
| **BASIC FOR Reverse Step** | Negative STEP |

### Computer integration

| Block | What it checks |
|-------|----------------|
| **Computer Integration** | CPU + BASIC + I/O path coherence |
| **Computer Variable Persistence Across RUN** | Variables survive as expected across runs |

### ROM carts and memory-mapped cart select

| Block | What it checks |
|-------|----------------|
| **Memory Cart Select $C030** | Cart switch register behavior |
| **Main RAM high-water** | Sanity around RAM layout / bounds |
| **Cart Loader Workspace** | Workspace cleared/invariants on cart switch |
| **Cart Loader POKE $C030** | Switch via POKE |
| **TEXT Cart Editor** | Line editor commands (`NEW`, line insert, `LIST`, etc.) |
| **TEXT Cart LIST range and PRINT** | `LIST lo hi` filtering and `PRINT` dumps |
| **TEXT Cart SAVE/LOAD round-trip** | `user://` `.txt` save/load restores lines |
| **TEXT Cart CATALOG and SCRATCH missing file** | `CATALOG` label path and missing-file scratch |
| **REBOOT deep clears ASM buffer** | `REBOOT` clears cart editor state (e.g. ASM source) |

### NATIVE runtime cart (`cart_native.gd`, id **4**, name **`NATIVE`**)

Switch cart with **`CART NATIVE`**, then **`HYBRID`** / **`NATIVE`** / **`STATUS`** / **`HELP`**. **`NATIVE`** selects **`BasicInterpreter`** soft-float path for **`+ − × ÷`** and unary **`−`** (still IEEE754 binary32 in GDScript today; intended for a future 6502 blob). **`CART BASIC`** returns to the interpreter cart.

| Block | What it checks |
|-------|----------------|
| **Native IEEE soft-float primitives** | `float_bits` / `add_bits` / `sub_bits` / `mul_bits` / `div_bits` smoke |
| **BASIC NATIVE runtime arithmetic** | `PRINT` using soft-float vs hybrid; `/ 0` → `0` matches BASIC rule |
| **Basic runtime mode serialize** | `basic_runtime_mode` survives `Computer.serialize` / `deserialize` |
| **Cart NATIVE registered** | `CART NATIVE` / back to BASIC |

### Assembler6502 and ASM cart

| Block | What it checks |
|-------|----------------|
| **Assembler6502 hello snippet** | Small fixed program assembles |
| **hello-style object run…** | Demo snippet runs and prints expected character |
| **stars demo RUN…** | Stars demo output length/content |
| **ASM cart assemble** | Cart assembly path |
| **ASM cart DEMO sources assemble** | Bundled demos assemble |
| **Assembler .EXPORT .ENTRY .HELP** | Meta directives |
| **ASM SAVEOBJ HC65 for all demos** | Object encoding for demos |

### C cart

| Block | What it checks |
|-------|----------------|
| **C cart compile hello** | Hello compiles |
| **C cart compile and run** | Compile + run path |
| **C cart DEMO sources compile** | Demo sources |
| **C cart BUILD alias compiles** | `BUILD` matches `COMPILE`; empty buffer error |
| **C cart DEL removes line** | `DEL n` removes one numbered source line |
| **C cart DEMO list and unknown demo** | `DEMOS` banner / unknown demo name |
| **C cart SAVE/LOAD round-trip** | `.c` disk round-trip then `COMPILE` |

### HC65 objects and BASIC `LOADOBJ`

| Block | What it checks |
|-------|----------------|
| **HC65 encode/decode** | Round-trip `.obj` format |
| **BASIC LOADOBJ + native call** | Load object and call into native code |

### Serialization

| Block | What it checks |
|-------|----------------|
| **Computer Cart Serialize** | Save/restore cart id and per-cart state |

### Binary and text file helpers

| Block | What it checks |
|-------|----------------|
| **BSAVE/BLOAD Binary** | Save/load binary regions |
| **WRITE/READFILE Text** | Text file write/read from BASIC |

Headless tests disconnect **`MemoryBus`** signals and release cart backrefs (`CartManager.release_cart_backrefs`) so a normal teardown should **not** leave **ObjectDB / resources still in use** warnings; if they appear after custom harness code, check for lingering **`RefCounted`** cycles or lambdas still subscribed to **`memory.output_ready`**.

### Execution order (matches `_init()` in `test_regression.gd`)

`Running:` lines appear in this sequence:

MemoryBus → Memory Reset Vectors → CPU Load/Store → CPU Arithmetic → CPU Logical → CPU Shift/Rotate → CPU Comparisons → CPU Branches → CPU Stack → CPU Jumps/Subroutines → CPU Flag Instructions → CPU Transfers → CPU NOP/BRK → BASIC PRINT → BASIC Variables → BASIC Arithmetic → BASIC IF/THEN → BASIC FOR/NEXT → BASIC GOSUB/RETURN → BASIC Built-in Functions → BASIC String Functions → BASIC Arrays → BASIC READ/DATA → BASIC POKE/PEEK → BASIC ON GOSUB → Computer Integration → Computer Variable Persistence Across RUN → Memory Cart Select $C030 → Main RAM high-water → Cart Loader Workspace → Cart Loader POKE $C030 → TEXT Cart Editor → TEXT Cart LIST range and PRINT → TEXT Cart SAVE/LOAD round-trip → TEXT Cart CATALOG and SCRATCH missing file → REBOOT deep clears ASM buffer → Assembler6502 hello snippet → hello-style object run prints one A then halts → stars demo RUN prints exactly ten asterisks → ASM cart assemble → ASM cart DEMO sources assemble → C cart compile hello → C cart compile and run → C cart DEMO sources compile → C cart BUILD alias compiles → C cart DEL removes line → C cart DEMO list and unknown demo → C cart SAVE/LOAD round-trip and COMPILE → HC65 encode/decode → Assembler .EXPORT .ENTRY .HELP → ASM SAVEOBJ HC65 for all demos → BASIC LOADOBJ + native call → Computer Cart Serialize → Native IEEE soft-float primitives → BASIC NATIVE runtime arithmetic → Basic runtime mode serialize → Cart NATIVE registered → BASIC Nested FOR/NEXT → BASIC FOR STEP → BASIC FOR Reverse Step → BSAVE/BLOAD Binary → WRITE/READFILE Text

---

## 2. External 65x02 step tests — `tests/test_processor_step_tests.gd`

Large **instruction-by-instruction** regression using vendored JSON from **[SingleStepTests / 65x02](https://github.com/SingleStepTests/65x02)** (MIT). Original work by **Thomas Harte et al.** — full attribution, license copy, and rebuild instructions: **[tests/fixtures/processor_tests/README.md](tests/fixtures/processor_tests/README.md)**.

### What it does

- Loads `res://tests/fixtures/processor_tests/v1/*.json` (one opcode byte per file our CPU implements).
- For each case: apply sparse RAM, set `PC` / registers / `P` from `initial`, run **`CPU6502.step()`** once, compare **`final`** registers and every listed RAM cell.

### Subset and limits

- **10 cases per opcode** in-repo (~676 KiB total); regenerate with `python3 tests/fixtures/processor_tests/build_subset.py` (network required).
- Exporter **skips ADC/SBC when decimal (`P.D`) is set** — this emulator’s ADC/SBC are **binary only**; extending decimal mode would allow importing those rows too.

### Exit code

**`quit(1)`** on any mismatch; summary prints **PASSED** / **FAILED** counts.

---

## 3. CLI suite — `tests/test_cli.gd`

Headless **`Computer.new()`** runner focused on **multi-statement BASIC programs** and **user:// file I/O**, overlapping regression on loops/files but keeping a lighter second harness for quick CLI-style checks.

### Modes

| Invocation | Behavior |
|------------|----------|
| No script path argument | Runs the built-in test battery (`run_tests()`) |
| Path to `.bas` / `.txt` / `.bin` | Loads and runs that file via `_run_file()` (optional manual smoke) |

*(Banner prints the same `-s tests/test_cli.gd` invocation from repo root.)*

### Built-in battery (`run_tests`)

| Test name | What it checks |
|-----------|----------------|
| **FOR/NEXT Basic** | Counts 1…5 from a simple loop |
| **Nested FOR/NEXT** | 3×3 nested output shape |
| **FOR STEP** | STEP 2, even values 0…10 |
| **FOR Reverse Step** | Countdown 5…1 with STEP −1 |
| **BSAVE/BLOAD Binary** | Writes `user://test.bin`, checks header and bytes; **BLOAD** to `$2000` and **PEEK** |
| **WRITE/READFILE Text** | Writes `user://test.txt`, **READFILE** into string, **PRINT** |
| **BASIC Arithmetic** | Precedence: `2+3*4` vs `(2+3)*4` |
| **BASIC IF/THEN** | Comparisons and string branches |
| **BASIC GOSUB/RETURN** | Subroutine call and return order |
| **BASIC Arrays** | **DIM**, fill loop, single element print |

Exit code is **0** even if some asserts fail; inspect **FAILED** in the summary line.

---

## 4. Fuzz smoke — `tests/test_fuzz_smoke.gd`

Short **randomized stress** pass over BASIC single-line execution, assembler input, and CPU stepping. Intended to catch crashes, exceptions, and **long stalls** without hanging CI.

### Command-line arguments

Parsed from **`OS.get_cmdline_user_args()`** (after `--`):

| Argument | Default | Meaning |
|----------|---------|---------|
| `--fuzz-iters=N` | **400** | Iterations **per round** (minimum **10** in harness) |
| `--fuzz-seed=N` | Pseudorandom from time | Seed for `RandomNumberGenerator` |

Example:

```bash
godot --path . --headless -s tests/test_fuzz_smoke.gd -- --fuzz-iters=800 --fuzz-seed=12345
```

### Five rounds (× iterations each)

1. **BASIC `execute_line` fuzz** — Fresh `Computer` each iteration; random **whitelist** one-liners only (`REM`, `PRINT`, `LET`, `IF…THEN`, `CLR`, `LIST`, `LEN`, `RND`, `CHR$`, …). Unrestricted random tokens were avoided because they could hang the tokenizer/parser.
2. **Assembler6502 fuzz** — Random multi-line “editor” arrays (1–12 lines of concatenated mnemonic/operand fragments from a fixed chunk alphabet); **`assemble()` must finish** without multi-second stall.
3. **CPU random RAM fuzz** — Random bytes at `$0800+`, random registers/stack prep via **`MemoryBus.prepare_cpu_stack_for_user_rts()`**, then **`cpu.run(steps)`** for a random step budget; detects **stall > 8s**.
4. **TEXT cart fuzz** — **`Computer.new()`**, switch to **TEXT** (`id=1`), run **2–7** random **whitelist** editor commands per iteration (`NEW`, `HELP`, `LIST` / ranges, `PRINT`, `DIR`, `CATALOG`, `SAVE`/`LOAD`/`SCRATCH`/`DELETE` with synthetic names, numbered lines with short ASCII bodies, bare line numbers for delete). Stall limit **8s** per iteration.
5. **C cart fuzz** — Switch to **C** (`id=3`), **2–6** commands per iteration (`NEW`, `HELP`, `LIST`, `DIR`, `DEMO`/`DEMOS` including known demo names and bogus names, `DEL`, `SAVE`/`LOAD`, bare line delete, **`//` comment** line entries only). **COMPILE / BUILD / RUN** are **not** fuzzed with random fragments (Small-C could stall); those paths are covered by **`test_regression.gd`**. Stall limit **6s** per iteration.

### Global limits

- **~120s** wall-clock budget across all rounds (early exit → failure).
- Per-call stall thresholds: **5s** for BASIC and assembler, **8s** for CPU batch.

### Exit code

**`quit(1)`** if any failure; **`quit(0)`** if all checks pass. Printed summary: **PASSED checks** / **FAILED checks** (one pass per iteration per round → **5 × iterations** checks when nothing fails early).

---

## Quick reference (individual commands)

```bash
godot --path . --headless -s tests/test_regression.gd
godot --path . --headless -s tests/test_processor_step_tests.gd
godot --path . --headless -s tests/test_cli.gd
godot --path . --headless -s tests/test_fuzz_smoke.gd -- --fuzz-iters=400 --fuzz-seed=42
```

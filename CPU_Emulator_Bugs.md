# CPU Emulator Bugs — Pre-existing Issues

> **Note:** This file describes problems observed against an **older** regression snapshot (counts like “12 failing CPU tests” / “71 BASIC tests” are **not** current). Today, opcode-level coverage is reinforced by **`tests/test_processor_step_tests.gd`** (vendored **[65x02](https://github.com/SingleStepTests/65x02)** JSON, MIT) plus the CPU sections of **`tests/test_regression.gd`**. Treat the sections below as **historical debugging notes**, not an up-to-date failure list.

Below is a breakdown of each bug as originally analyzed, its suspected root cause, and a suggested fix.

---

## 1. STA / LDA Zero Page (4 failures)

**File:** `cpu_6502.gd:124-136` — `step()`
**Tests:** `test_cpu_load_store` lines 98-125

### Problem

`step()` computes `addr = _get_addr(mode)` on line 135 **before** the instruction match block. For STA zero page (`0x85`), `_get_addr("ZPG")` reads the operand byte from `PC` and returns the effective address `0x0010`. That part is correct.

However, the `LDA` zero path (`0xA5`) reads from `_read_byte(addr)` (line 144), not from `PC + 1`. This should also be correct since `addr` is already the zero-page address.

**Actual root cause:** The tests reuse the **same CPU instance** across sub-steps without resetting `halted`. After the first step, `halted` is still `false`, but the opcode table lookup or memory state may carry over garbage. More likely: the tests manually set `cpu.PC` between steps but the CPU was never halted — this should work.

**Likely cause:** `MemoryBus.peek()` returns stale data. The memory bus may not be zeroing on construction, or the `_fresh_mem()` helper in tests doesn't fully reset. The tests at lines 104-105 write the opcode at `0x0800`, and lines 108-112 write a second opcode at `0x0810`. These don't overlap, so memory should be fine.

### Suggested Fix

Add a debug test that prints `addr`, the opcode byte, and the memory contents before/after each step to identify the exact mismatch. The implementation at lines 158-145 looks structurally correct for zero-page STA/LDA.

---

## 2. ROR Accumulator with Carry (2 failures)

**File:** `cpu_6502.gd:227-239` — ROR in `step()`
**Tests:** `test_cpu_shifts` lines 200-206

### Problem

Test setup: `A = 0x80`, carry = 1, opcode `0x6A` (ROR A).

Expected by test: `A = 0x40`, carry = 1
Correct 6502 behavior: `A = 0xC0`, carry = 0

ROR of `0x80` (`1000_0000`):
- Bit 0 is `0` → carry out = 0
- Shift right: `0100_0000` = `0x40`
- Old carry (1) → bit 7: `1100_0000` = `0xC0`

**The test expectation is wrong.** The correct result is `A = 0xC0`, carry = 0.

### Suggested Fix

Update the test assertions:
```gdscript
_assert(cpu.A == 0xC0, "ROR accumulator with carry in")
_assert(cpu.get_flag(CPU6502.Flag.C) == false, "ROR carry out")
```

The implementation in `cpu_6502.gd` is correct.

---

## 3. INC Zero Page (1 failure)

**File:** `cpu_6502.gd:240-243` — INC in `step()`
**Tests:** `test_cpu_shifts` lines 207-212

### Problem

Test sets `mem[0x0050] = 0x10`, places `0xE6 0x50` at `0x0840`, sets `PC = 0x0840`, steps. Expects `mem[0x0050] == 0x11`.

The INC implementation reads from `addr`, increments, writes back. This should work.

**Likely cause:** Same issue as #1 — the CPU instance is reused from prior tests (ROR test). `halted` may have been set to `true` by a previous failed step or unknown opcode execution, causing `step()` to early-return at line 125.

### Suggested Fix

Check if `halted` is `true` before the INC step in the test. If so, reset `halted = false` or create a fresh CPU for each sub-test.

---

## 4. BNE Branch Not Taken (1 failure)

**File:** `cpu_6502.gd:284-286` — BNE in `step()`
**Tests:** `test_cpu_branches` lines 241-246

### Problem

Test: `Z = 0`, opcode `0xD0` (BNE), offset `0x05`. Expects `PC = 0x0817`.

`_get_addr("REL")` at line 107-111 computes the target correctly. The branch condition `not get_flag(Flag.Z)` is true (Z=0), so `next_pc = addr`.

**Likely cause:** Same `halted` state pollution from prior tests. The branch tests run after shift tests which may have left the CPU halted.

### Suggested Fix

Reset `halted = false` between sub-tests, or create a fresh CPU per sub-test.

---

## 5. BCS Branch Not Taken (1 failure)

**File:** `cpu_6502.gd:278-280` — BCS in `step()`
**Tests:** `test_cpu_branches` lines 247-252

### Problem

Same pattern as #4. Test: `C = 1`, opcode `0xB0` (BCS), offset `0x05`. Expects `PC = 0x0827`.

Implementation looks correct. Likely `halted` pollution.

### Suggested Fix

Same as #4.

---

## 6. PHA Push to Stack (1 failure)

**File:** `cpu_6502.gd:322-323` — PHA in `step()`
**Tests:** `test_cpu_stack` lines 254-264

### Problem

Test: `A = 0x42`, `SP = 0xFD`, opcode `0x48` (PHA). Expects `mem[0x01FF] = 0x42`, `SP = 0xFC`.

`_push()` at line 65-67:
```gdscript
memory.poke(0x0100 | SP, val & 0xFF)
SP = (SP - 1) & 0xFF
```

`0x0100 | 0xFD = 0x01FD`, not `0x01FF`!

**Root cause:** `_push()` writes BEFORE decrementing. On 6502, the stack grows downward from `0x01FF`. With `SP = 0xFD`, the next push should go to `0x01FD` (correct), but the test expects `0x01FF` with `SP = 0xFD` meaning the push should go to `SP` first then decrement.

Actually, the test expects `mem[0x01FF] == 0x42` when `SP = 0xFD`. This means the test expects SP to be decremented **first** (0xFD → 0xFC), then push to `0x01FC`... but the expected address is `0x01FF`. The test itself seems to expect `SP = 0xFF` before the push.

**The test is wrong.** With `SP = 0xFD`, the push goes to `0x01FD`, then SP becomes `0xFC`. The test should expect `mem[0x01FD] == 0x42`.

### Suggested Fix

Either fix the test to match correct 6502 behavior, or change the test setup to `SP = 0xFF`:
```gdscript
cpu.SP = 0xFF
cpu.step()
_assert(mem.peek(0x01FF) == 0x42, "PHA push to stack")
_assert(cpu.SP == 0xFE, "PHA SP decremented")
```

---

## 7. JMP Absolute (1 failure)

**File:** `cpu_6502.gd:299-300` — JMP in `step()`
**Tests:** `test_cpu_jumps_subroutines` lines 271-280

### Problem

Test: opcode `0x4C` at `0x0800`, address bytes `0x34 0x12`. Expects `PC = 0x1234`.

`_get_addr("ABS")` reads `_read_word(PC)` = `mem[0x0800] | (mem[0x0801] << 8)` = `0x4C | (0x34 << 8)` = `0x344C`.

**Root cause:** `_get_addr("ABS")` is called with `PC = 0x0800`, which points at the **opcode byte** (`0x4C`), not the operand bytes. The operand bytes start at `PC + 1`. So it reads `0x4C` as low byte and `0x34` as high byte, getting `0x344C` instead of `0x1234`.

All addressing modes in `_get_addr()` read from `PC` directly, but they should read from `PC + 1` (skipping the opcode). This affects **all non-immediate, non-implied instructions**.

### Suggested Fix

Change `_get_addr()` to read from `PC + 1`:

```gdscript
func _get_addr(mode: String) -> int:
    match mode:
        "ZPG":
            return _read_byte(PC + 1)
        "ZPX":
            return (_read_byte(PC + 1) + X) & 0xFF
        "ZPY":
            return (_read_byte(PC + 1) + Y) & 0xFF
        "ABS":
            return _read_word(PC + 1)
        # ... etc for all modes that read operand bytes
```

Alternatively, increment `PC` before calling `_get_addr()` in `step()`.

**This is the most critical bug** — it explains failures #1, #3, #4, #5, #7, and #8 because STA/LDA, INC, branches, and JSR all depend on correct operand address resolution.

---

## 8. JSR Sets PC (1 failure)

**File:** `cpu_6502.gd:301-303` — JSR in `step()`
**Tests:** `test_cpu_jumps_subroutines` lines 281-291

### Problem

Test: `SP = 0xFD`, opcode `0x20` at `0x0900`, address `0x00 0x10`. Expects `PC = 0x1000`.

Same root cause as #7 — `_get_addr("ABS")` reads from `PC` (opcode) instead of `PC + 1`. Additionally, `_push_word(PC + 2)` pushes the return address, which is correct.

### Suggested Fix

Same as #7.

---

## Summary & Priority

| # | Bug | Cause | Impact | Priority |
|---|-----|-------|--------|----------|
| 7,8 | `_get_addr()` reads from `PC` not `PC+1` | Off-by-one in operand fetch | Breaks STA/LDA, INC, JMP, JSR, branches, all memory-mode ops | **Critical** |
| 2 | ROR test expectation wrong | Test expects `A=0x40` instead of `A=0xC0` | 1 test | Low |
| 6 | PHA test expectation wrong | Test expects push at `0x01FF` with `SP=0xFD` | 1 test | Low |
| 3 | `halted` state pollution | Reused CPU instance in tests | Multiple tests | Medium |

## Recommended Fix Order

1. **Fix `_get_addr()` first** — change all `_read_byte(PC)` → `_read_byte(PC + 1)` and `_read_word(PC)` → `_read_word(PC + 1)`. This single fix will resolve ~8 of the 12 failures.
2. **Fix ROR test expectations** — the implementation is correct.
3. **Fix PHA test setup** — set `SP = 0xFF` or change expected address.
4. **Add `halted = false` reset** between sub-tests in `test_regression.gd` (or create fresh CPU per sub-test) to prevent state pollution.

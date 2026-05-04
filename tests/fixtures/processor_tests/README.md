# External 6502 processor step tests (subset)

This folder vendors a **small subset** of the **[SingleStepTests / 65x02](https://github.com/SingleStepTests/65x02)** JSON corpus — single-instruction tests with full CPU and sparse RAM state before and after each step.

## Credit

- **Author / copyright:** Copyright (c) 2024 **Thomas Harte et al.** ([MIT License](https://github.com/SingleStepTests/65x02/blob/main/LICENSE), reproduced here as `LICENSE.processor_tests`).
- **Upstream repository:** [https://github.com/SingleStepTests/65x02](https://github.com/SingleStepTests/65x02)
- **Related umbrella project:** the broader **[ProcessorTests](https://github.com/SingleStepTests/ProcessorTests)** effort (archived as a monorepo; 6502 coverage continues in **65x02**).

The methodology write-up in upstream README describes randomly generated scenarios validated against documentation and other published suites.

## What we ship here

- `v1/*.json` — one file per official opcode byte our emulator implements (`scripts/cpu_6502.gd`), **10 cases each** (minified JSON).
- Cases where **decimal mode (`P.D`) is set** and the opcode is **ADC or SBC** are **omitted** during export; BASIC6502’s core implements **binary** ADC/SBC only (see also `CPU_Emulator_Bugs.md`).

## Regenerating from upstream

Requires network:

```bash
python3 tests/fixtures/processor_tests/build_subset.py
```

This refreshes `v1/` and `LICENSE.processor_tests`.

# Teaching Lab - Backlog

## Vision
A multi-CPU emulator "teaching lab" where students can interact with and program 6502, 4004, 8080, Z80, 8086 and other processors. Processors can communicate with each other for cross-development scenarios.

---

## Epics

### Epic 1: CPU Abstraction Layer
Abstract the CPU so multiple implementations can be swapped at runtime.

### Epic 2: Memory Architecture Refactor
Separate memory management from CPU-specific concerns, allowing each CPU to have its own memory model.

### Epic 3: Cartridge/ROM System Evolution
Carts declare which CPUs they support; system validates compatibility at load time.

### Epic 4: I/O Device Abstraction
Standardize I/O across CPUs with a unified device framework.

### Epic 5: Cross-CPU Communication
Allow one CPU to interact with another (e.g., 6502 dev machine → Z80 target).

### Epic 6: Debugging Tools per CPU
CPU-aware disassemblers, register viewers, memory viewers, breakpoints.

### Epic 7: Computer Profiles
Define complete system configurations (CPU + Memory + I/O + ROMs) as loadable profiles.

### Epic 8: New CPU Implementations
Implement 4004, 8080, Z80, and 8086.

### Epic 9: Hardware Manager GUI
Visual GUI for managing CPUs, ROMs, Carts, Disks, and I/O devices. A "shelf" of common reference I/O devices (terminals, disk drives, serial ports, etc.) that can be dragged onto a system.

---

## User Stories

### CPU Abstraction [Phase 1 ✓]
- [x] **US-1.1**: As a developer, I want a `CPU` base class with `step()`, `reset()`, `get_state()`, `disassemble()`, `run()`, `serialize()`, `deserialize()` so I can implement multiple CPUs uniformly.
- [x] **US-1.2**: As a developer, I want `CPU6502` to inherit from `CPU` without breaking existing functionality.
- [ ] **US-1.3**: As a user, I want to select which CPU to use when creating a new machine configuration.

### Memory Architecture
- [ ] **US-2.1**: As a developer, I want a `MemoryBus` interface that each CPU subclass can implement with its own addressing scheme.
- [ ] **US-2.2**: As a developer, I want 6502's current memory implementation to work unchanged as `6502MemoryBus`.
- [ ] **US-2.3**: As a developer, I want memory-mapped I/O to work per-CPU (different addresses for different CPUs).

### Cartridge System
- [ ] **US-3.1**: As a developer, I want carts to have a `manifest` declaring supported CPUs (e.g., `["6502"]` or `["6502", "8080"]`).
- [ ] **US-3.2**: As a system, I want to reject loading a cart if the current CPU isn't in its manifest.
- [ ] **US-3.3**: As a developer, I want carts to have CPU-specific handlers (e.g., 6502 BASIC vs Z80 BASIC are different code).

### I/O Abstraction
- [ ] **US-4.1**: As a developer, I want an `IODevice` base class with `read()`, `write()` methods.
- [ ] **US-4.2**: As a system, I want devices to be mapped to port ranges that vary per CPU.
- [ ] **US-4.3**: As a user, I want to configure which devices are attached to a system.

### Cross-CPU Communication
- [ ] **US-5.1**: As a user, I want to connect two CPU instances via a shared memory buffer for data exchange.
- [ ] **US-5.2**: As a user, I want one CPU to trigger interrupts on another CPU.
- [ ] **US-5.3**: As a developer, I want a `InterCPUBridge` class to manage these connections.

### Debugging
- [ ] **US-6.1**: As a user, I want a disassembler that knows the instruction set of the current CPU.
- [ ] **US-6.2**: As a user, I want a register viewer showing CPU-specific registers (A/X/Y/PS for 6502; A/B/C/D/E/H/L/PSW for Z80).
- [ ] **US-6.3**: As a user, I want step-by-step execution that works per CPU.

### Computer Profiles
- [ ] **US-7.1**: As a user, I want to save/load a complete machine configuration (CPU + memory size + devices + carts).
- [ ] **US-7.2**: As a user, I want preset profiles like "6502 Trainer", "CP/M 8080", "IBM PC 8086".

### New CPUs
- [ ] **US-8.1**: As a system, I want a working Intel 4004 implementation.
- [ ] **US-8.2**: As a system, I want a working Intel 8080 implementation.
- [ ] **US-8.3**: As a system, I want a working Zilog Z80 implementation.
- [ ] **US-8.4**: As a system, I want a working Intel 8086 implementation.
- [ ] **US-8.5**: As a user, I want CP/M-like functionality on 8080/Z80.

---

## Additional Considerations

1. **Save States** — Each CPU has different state; need CPU-aware serialization
2. **Performance** — Different CPUs have different clock speeds; need CPU-specific timing
3. **Documentation** — Each CPU needs architecture docs for teaching
4. **Peripheral Hot-Swap** — Allow adding/removing devices at runtime
5. **Audio** — Different CPUs may have different sound capabilities
6. **Expansion Slots** — Define a slot system for adding expansion cards

## C++ / GDExtension Strategy

For performance-critical emulation cores and I/O devices, consider GDExtension (C++):

- **CPU emulation cores** — 8080/Z80/8086 cycle-accurate emulation benefits from C++ speed
- **Prior art to reference**:
  - [fake86](https://github.com/ohnoimdead/fake86) — 8086 emulator in C
  - [8080emu](https://github.com/jblang/8080emu) — Altair 8800 CP/M emulator
  - [MAME](https://github.com/mamedev/mame) — reference implementations for virtually all CPUs
  - [SameBoy](https://github.com/LIJI32/SameBoy) — cycle-accurate Game Boy (Z80-like), clean C codebase
  - [SingleStepTests](https://github.com/SingleStepTests) — JSON test suites for 6502, 8080, Z80
- 6502 core can stay in GDScript (already proven performant)
- Start with GDScript prototypes; profile, then hot-path to C++ if needed

## Open Source Test Suites per CPU

Following the existing pattern (`test_processor_step_tests.gd` / 65x02 JSON):

| CPU | Test Suite | Approach |
|-----|-----------|----------|
| 6502 | [SingleStepTests/65x02](https://github.com/SingleStepTests/65x02) | Already vendored (MIT) |
| 8080 | [SingleStepTests/8080](https://github.com/SingleStepTests/8080) | JSON step tests (MIT) |
| Z80 | [SingleStepTests/Z80](https://github.com/SingleStepTests/Z80) | JSON step tests (MIT) |
| Z80 | [z80-tests](https://github.com/retroudhb/z80-tests) / [Z80Test](https://github.com/raxoft/z80test) | Assembled ROM binaries run in emulator, compare register state |
| 8086 | [8086-test-suite](https://github.com/barotto/8086-test-suite) | Instruction-level tests |
| 4004 | [4004-test](https://github.com/wjak/4004-test) | Basic opcode validation |

Each new CPU gets a `test_processor_step_tests_<cpu>.gd` following the existing fixture pattern.

---

## Priority Order (Suggested)

1. **Phase 1**: US-1.1, US-1.2, US-2.1, US-2.2 (CPU + Memory base)
2. **Phase 2**: US-3.1, US-3.2, US-3.3 (Cartridge manifest)
3. **Phase 3**: US-4.1, US-4.2 (I/O abstraction)
4. **Phase 4**: US-6.1, US-6.2, US-6.3 (Debugging tools)
5. **Phase 5**: US-7.1, US-7.2 (Profiles)
6. **Phase 6**: US-5.1, US-5.2, US-5.3 (Cross-CPU)
7. **Phase 7**: US-8.1, US-8.2, US-8.3, US-8.4 (New CPUs)

---

*Created: 2026-05-10*  
*Branch: exp/teaching-lab*
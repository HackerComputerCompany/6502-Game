# Teaching Lab - Backlog

## Vision
A multi-CPU emulator "teaching lab" where students can interact with and program 6502, 4004, 8080, Z80, 8086, and synthetic teaching CPUs. Processors can communicate with each other for cross-development scenarios. Future target: deploy to custom FPGA-based hardware (inspired by MiSTer) for a physical "learning lab" appliance with dedicated display, USB, and I/O.

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

### Epic 10: Synthetic Teaching CPU
A clean, minimal CPU designed specifically for teaching. Inspired by IMSI/ALRAR front-panel machines where programs are deposited directly into memory via hex switches. Available in 8, 16, 32, and 64-bit word size variants to teach the concept of word width. Uses hex (not octal like early machines). Teaches: fetch-execute cycle, registers, ALU, addressing modes, memory layout — without the historical baggage of real ISAs.

### Epic 11: Graphics Subsystem & GPU
Display modes (text, bitmap, tile) and a pluggable "graphics card" device. Required for implementing Logo (turtle graphics) and Lisp (graphical environments) in the future. Each CPU/machine profile selects a graphics card, which provides a framebuffer and display registers.

### Epic 12: FPGA / Hardware Target
Architect the entire Learning Lab so it can eventually run on custom FPGA hardware (inspired by MiSTer). The software emulator is the proving ground / reference design. Each component maps cleanly to hardware: CPU → soft-core, MemoryBus → bus fabric, I/O controllers → peripheral chips (VGA, USB, audio). MiSTer is the primary prototyping platform for hardware validation; long-term goal is a custom PCB appliance for classrooms.

---

## User Stories

### CPU Abstraction [Phase 1 ✓]
- [x] **US-1.1**: As a developer, I want a `CPU` base class with `step()`, `reset()`, `get_state()`, `disassemble()`, `run()`, `serialize()`, `deserialize()` so I can implement multiple CPUs uniformly.
- [x] **US-1.2**: As a developer, I want `CPU6502` to inherit from `CPU` without breaking existing functionality.
- [ ] **US-1.3**: As a user, I want to select which CPU to use when creating a new machine configuration.

### Memory Architecture [Phase 2 ✓]
- [x] **US-2.1**: As a developer, I want a `MemoryBus` interface that each CPU subclass can implement with its own addressing scheme.
- [x] **US-2.2**: As a developer, I want 6502's current memory implementation to work unchanged as `6502MemoryBus`.
- [ ] **US-2.3**: As a developer, I want memory-mapped I/O to work per-CPU (different addresses for different CPUs).

### Cartridge System [Phase 3 ✓]
- [x] **US-3.1**: As a developer, I want carts to have a `manifest` declaring supported CPUs (e.g., `["6502"]` or `["6502", "8080"]`).
- [x] **US-3.2**: As a system, I want to reject loading a cart if the current CPU isn't in its manifest.
- [ ] **US-3.3**: As a developer, I want carts to have CPU-specific handlers (e.g., 6502 BASIC vs Z80 BASIC are different code).

### I/O Abstraction [Phase 4 ✓]
- [x] **US-4.1**: As a developer, I want an `IODevice` base class with `read()`, `write()` methods.
- [x] **US-4.2**: As a system, I want devices to be mapped to port ranges that vary per CPU.
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

### Synthetic Teaching CPU
- [ ] **US-10.1**: As a user, I want a synthetic CPU with a minimal ISA (load/store/add/sub/branch/halt) so I can understand the fetch-execute cycle.
- [ ] **US-10.2**: As a user, I want to deposit programs directly into memory using hex values (front-panel style).
- [ ] **US-10.3**: As a user, I want to choose between 8, 16, 32, and 64-bit word size variants of the same ISA to see how word width affects memory, registers, and ALU.
- [ ] **US-10.4**: As a user, I want a step-by-step visual of each instruction's execution (register changes, memory access).

### Graphics / GPU
- [ ] **US-11.1**: As a system, I want a framebuffer device that can be mapped into any CPU's memory space.
- [ ] **US-11.2**: As a user, I want text mode (80x25 character grid) for terminal-like output.
- [ ] **US-11.3**: As a user, I want bitmap graphics mode for pixel-level drawing (turtle graphics).
- [ ] **US-11.4**: As a developer, I want a pluggable GPU interface so different graphics cards can be swapped.
- [ ] **US-11.5**: As a user, I want to draw lines, shapes, and sprites via memory-mapped GPU registers.
- [ ] **US-11.6**: As a user, I want multiple display layers (text + graphics overlay).

### FPGA / Hardware Target
- [ ] **US-12.1**: As a developer, I want each CPU core to have a documented hardware interface (signals, bus width, timings) so it can be implemented as an FPGA soft-core.
- [ ] **US-12.2**: As a developer, I want the MemoryBus design to map to a hardware bus fabric (address decoding, wait states, arbitration).
- [ ] **US-12.3**: As a developer, I want I/O devices to have abstracted hardware interfaces (register maps, interrupts) so they can be swapped between emulation and real hardware.
- [ ] **US-12.4**: As a developer, I want the software emulator to output cycle-accurate trace logs for validating FPGA core behavior.
- [ ] **US-12.5**: As a developer, I want to run the same ROM/cartridge images in both the software emulator and on MiSTer to validate correctness.
- [ ] **US-12.6**: As a user, I want a MiSTer core that can load and run the Learning Lab's cartridge format.

---

## Additional Considerations

1. **Save States** — Each CPU has different state; need CPU-aware serialization
2. **Performance** — Different CPUs have different clock speeds; need CPU-specific timing
3. **Documentation** — Each CPU needs architecture docs for teaching
4. **Peripheral Hot-Swap** — Allow adding/removing devices at runtime
5. **Audio** — Different CPUs may have different sound capabilities
6. **Expansion Slots** — Define a slot system for adding expansion cards

## FPGA / Hardware Strategy

The software emulator is the **reference design** for eventual FPGA hardware:

- **Right-size by prototyping** — Simulate the hardware architecture in software first to measure gate/bram/dsp requirements before committing to specific FPGA silicon. Lets us target cheap FPGAs (e.g. Cyclone IV / ECP5) instead of jumping to DE10-Nano
- **MiSTer as proving ground** — Develop MiSTer cores that match the emulator's component architecture; validate correctness by running identical cartridge images
- **HDL languages** — Verilog / SystemVerilog for FPGA soft-cores; each CPU core becomes a separate module
- **Bus fabric** — MemoryBus maps to a Wishbone or AXI bus; address decoding, wait states, DMA
- **Open-source FPGA tooling** — Evaluate [Project Trellis](https://github.com/YosysHQ/prjtrellis) (ECP5), [nextpnr](https://github.com/YosysHQ/nextpnr), [Yosys](https://github.com/YosysHQ/yosys) for open-source synthesis; avoid vendor lock-in. Reference open [MiSTer](https://github.com/MiSTer-devel) and [MegaDrive/Genesis core](https://github.com/MiSTer-devel/Genesis_MiSTer) designs for architecture patterns
- **Peripheral chips** — Display controller, USB host, audio DAC mapped as I/O devices on the bus
- **Cartridge format** — Shared ROM image format (flat binary + header) that loads identically in emulator and on hardware
- **Long-term goal** — Custom PCB "Learning Lab appliance" with low-cost FPGA, VGA/HDMI out, USB in, audio jack

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

1. **Phase 1 ✓**: US-1.1, US-1.2, US-2.1, US-2.2 (CPU + Memory base)
2. **Phase 2 ✓**: Memory architecture split (base MemoryBus + MemoryBus6502)
3. **Phase 3 ✓**: US-3.1, US-3.2, US-3.3 (Cartridge manifest)
4. **Phase 4 ✓**: US-4.1, US-4.2 (I/O abstraction)
5. **Phase 5**: US-6.1, US-6.2, US-6.3 (Debugging tools)
6. **Phase 6**: US-7.1, US-7.2 (Profiles)
7. **Phase 7**: US-5.1, US-5.2, US-5.3 (Cross-CPU)
8. **Phase 8**: US-10.1, US-10.2, US-10.3, US-10.4 (Synthetic CPU)
9. **Phase 9**: US-11.1, US-11.2, US-11.3, US-11.4, US-11.5, US-11.6 (Graphics/GPU)
10. **Phase 10**: US-8.1, US-8.2, US-8.3, US-8.4 (New CPUs 4004/8080/Z80/8086)
11. **Phase 11**: US-12.1, US-12.2, US-12.3, US-12.4, US-12.5, US-12.6 (FPGA/Hardware target)

---

*Created: 2026-05-10*  
*Branch: exp/teaching-lab*
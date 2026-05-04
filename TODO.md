# TODO

## Boot Loader & ROM Banking System

### Core Concept
The system currently boots directly into BASIC6502 ROM at `$F000-$FFFF`. A boot loader would sit at `$FC00-$FFFF` (the top 1KB of the ROM space) and allow the user to select which ROM/cart to load into the lower 7KB (`$F000-$FBFF`) before handing over control. This is modeled after real 8-bit computers like the Apple II, C64, and TSR/Tandy systems that had bank-switching ROM cartridges.

### Boot Loader Flow
1. Power on → CRT warm-up animation (existing)
2. Boot loader at `$FC00` runs first
3. Displays a menu:
   ```
   HACKER COMPUTER COMPANY
   BASIC6502 BOOT LOADER v1.0

   SELECT ROM CART:

   1. BASIC6502    (default)
   2. ASM6502      (assembler)
   3. SMALL-C      (C compiler)
   4. DISK          (load from user disk)
   5. MONITOR       (raw 6502 monitor)

   BOOT: _
   ```
4. User types a number or name, boot loader copies selected ROM into `$F000-$FBFF` and jumps to `$F000`
5. If no selection within 5 seconds, boots default (BASIC6502)

### ROM Banking Architecture
- `$FC00-$FFFF` — Fixed boot loader ROM (1KB, always present, never banked out)
- `$F000-$FBFF` — Banked ROM area (3KB), swapped per cart
- `$E000-$EFFF` — Cart workspace (4KB RAM per cart, for symbol tables, source buffers, object code)
- Each cart is responsible for its own workspace layout within `$E000-$EFFF`

### Banking Mechanism
- I/O port `$C030` (previously unused) → Cart select register
  - Write `0` → BASIC6502 cart
  - Write `1` → ASM6502 cart  
  - Write `2` → SMALL-C cart
  - Write `3` → Disk-loaded cart
  - Write `255` → Eject (no cart)
- Reading `$C030` returns current cart number
- Bank switch takes ~1 frame (simulated), boot loader waits for it
- When switching carts, the boot loader:
  1. Clears `$E000-$EFFF` (cart workspace)
  2. Copies new cart ROM into `$F000-$FBFF`
  3. Jumps to `$F000` (cart entry point)

### Cartridge Switching While Running (Hot Swap)
- `CART` command (already planned in next_steps.md) lists available carts
- `CART BASIC` / `CART ASM` / `CART C` swaps the active cart
- Hot swap procedure:
  1. Saves current cart workspace to GDScript-side dict (not limited by 420KB disk)
  2. Clears `$E000-$EFFF` and `$F000-$FBFF`
  3. Loads new cart ROM into `$F000-$FBFF`
  4. Resets cart workspace from saved state (or fresh if new)
  5. Resets CPU registers, stack pointer
  6. Sets `_mode` in terminal to new cart's mode (BASIC, ASM, C)
  7. New cart's prompt appears
- Hot swap preserves: the 64KB main RAM (`$0000-$DFFF`), CPU registers are reset
- Hot swap does NOT preserve: cart workspace (`$E000-$EFFF`) unless same cart type
- Warning displayed if program is running: "PROGRAM RUNNING - OK TO SWITCH? (Y/N)"

### Disk Storage (420KB Limit)
The simulated disk drive has exactly 420KB of storage, mimicking a real 8-bit floppy (a single-sided 40-track floppy like the Apple II had ~140KB; our 420KB is more like a C64 1541 double-sided or a TRS-80 double-density). This constraint applies to:

- **BASIC programs** saved with `SAVE` — stored as `.bas` files
- **Assembly source** saved from the ASM cart — stored as `.asm` files
- **C source** saved from the SMALL-C cart — stored as `.c` files
- **Cart RAM dumps** saved with `SAVE` — stored as `.bin` files (up to 4KB each)
- **State saves** (F3 System Settings) — these are GDScript-side JSON files, NOT counted against 420KB

#### Disk Layout
```
DISK: 420 KB TOTAL

Volume: BASIC6502
  420 KB free

Files:
  HELLO.BAS       128 bytes
  MANDEL.ASM     1,024 bytes
  PRIMES.BAS       512 bytes
  ─────────────────────────
  3 files, 1,664 bytes used
  418,336 bytes free
```

#### Disk Commands
- `DIR` / `CATALOG` — show file listing with sizes, free space
- `SAVE filename` — save to disk (error if not enough space)
- `LOAD filename` — load from disk
- `SCRATCH filename` — delete a file
- `DISK` — show disk info (total/free space, file count)

#### Space Calculation
- Each BASIC program: stored as text, ~100 bytes to ~10KB
- Each ASM source: stored as text, ~500 bytes to ~20KB
- Each C source: stored as text, ~1KB to ~30KB
- Each binary dump: fixed 4KB (`$E000-$EFFF`)
- Track total used bytes; refuse writes that would exceed 420KB

### Implementation Phases

#### Phase 1: Boot Loader (2 sessions)
- Write `boot_loader.gd` with menu display and cart selection
- Modify boot sequence to show boot loader before BASIC
- Add 5-second timeout to auto-boot default
- New I/O port `$C030` for cart select register
- Test: power on → see menu → select cart → boots correctly

#### Phase 2: Disk Storage System (2 sessions)
- Implement `disk_manager.gd` with 420KB limit
- Track file sizes, enforce space limits
- Update `SAVE`/`LOAD`/`DIR` to use disk manager
- Add `SCRATCH` command
- Add `DISK` command
- Test: fill disk, get error; delete files, free space; save/load cycle

#### Phase 3: Cartridge Hot-Swap (2 sessions)
- Implement `ROMCart` base class with `install()`, `uninstall()`, `handle_command()`
- `CART` command lists available carts, `CART <name>` loads one
- Cart switching preserves main RAM, resets cart workspace
- Each cart has its own prompt, help text, command handler
- Test: BASIC → CART ASM → works → CART BASIC → works → run basic program

#### Phase 4: Integrating Existing Carts (1 session)
- Wrap current BASIC interpreter as `cart_basic.gd`
- Test regression: all existing demos, programs, save/load still work
- Boot loader defaults to cart 0 (BASIC)

### Priority
Medium — adds architectural foundation for ASM and C carts, but not blocking current work. Start after BASIC interpreter bugs are stable.
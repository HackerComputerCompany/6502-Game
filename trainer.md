# Trainer cart — design plan

This document describes the **design**, **approach**, and **requirements** for an **in-game ROM cartridge** (“Trainer” cart) that teaches **BASIC6502 BASIC** and **assembly language** used by the existing **ASM cart**, using **plain-language explanations**, **short examples**, and **interactive checks** suitable for a motivated **~10th-grade** reader (roughly ages 15–16: comfortable with variables, order of operations, light logic; no prior assembly required).

Implementation is **out of scope** for this file; this is the **product + curriculum + engineering plan** to build against.

---

## 1. Goals

| Goal | Description |
|------|-------------|
| **G1 — Coverage** | Every **BASIC keyword** and **operator** supported by `BasicInterpreter` gets at least one **lesson slice**: explanation + minimal example + **interactive** check. Same for every **assembler-accepted 6502 mnemonic** and **assembler directive** documented for the ASM cart. |
| **G2 — Progression** | Content is **ordered** from first programs (“Hello”) through control flow, data, files, memory, then **ASM** (registers → loads/stores → branches → subroutines → I/O map). |
| **G3 — In-world** | The learner stays **inside the terminal**: the Trainer cart is selected with `CART TRAINER`, same CRT/keyboard metaphors as today. |
| **G4 — Accessibility** | Reading level targets **grades 9–10**; jargon is introduced **with definitions**; examples are **short** (ideally ≤ 8 lines of BASIC or ≤ 12 lines of ASM source). |
| **G5 — Honesty** | Teach the **actual dialect** of this project (keywords from `basic_interpreter.gd`, asm rules from `assembler6502.gd` / `cart_asm.gd`), not a generic “6502/BASIC” superset. |
| **G6 — Voice** | Clever, inclusive, conspiratorial tone. Assume the learner is sharp and let them in on the joke. Hacker culture references (GOSUB stack, the 2600 Hz whistle, demoscene history, Grace Hopper's moth) woven throughout. Not loud — clever. The machine is confiding in you. |

## 2. Non-goals (initial releases)

- Replacing **USER_GUIDE.md** or **HELP** text (Trainer **complements** them).
- A full **Small-C** or **high school CS curriculum** beyond BASIC + this assembler.
- **Spaced repetition** or **accounts** (offline single-player is enough at first).
- **Automatic grading** of arbitrary user programs beyond **structured** quizzes (phase 2+).

---

## 3. Pedagogical approach

### 3.1 Lesson unit template

Each **unit** should follow a fixed rhythm (reduces cognitive load):

1. **Idea** — One sentence: what problem this solves.  
2. **Vocabulary** — 2–5 terms with plain definitions.  
3. **See it** — One **worked example** (copy-paste safe).  
4. **Try it** — **Interactive**: predict output, fill-in-the-blank line, or “fix this bug.”  
5. **Sandbox** (optional) — “Open scratch BASIC/ASM” with suggested experiment.  
6. **Next** — Link to the next unit ID.

### 3.2 Scaffolding BASIC → ASM

- **Phase A (BASIC-only):** variables, `PRINT`, `IF`, loops, `GOSUB`, arrays, `READ`/`DATA`, `PEEK`/`POKE`, files — then introduce **why** machine code exists (speed, hardware).  
- **Phase B (bridge):** `SYS`, `BSAVE`/`BLOAD`, **hex** (`$` notation), **memory map** table from USER_GUIDE.  
- **Phase C (ASM):** line-numbered ASM on the **ASM cart** is already familiar; Trainer either **embeds** mini-assembler lessons or **deep-links** (“type `CART ASM` and paste this block”). Prefer **Trainer-owned copy** of tiny listings so the user is not bounced without context.  
- **Phase D (integration):** `LOADOBJ`, **native-style calls**, one capstone project (e.g. “print primes” BASIC vs tiny ASM routine).

### 3.3 Interactive test types (requirements)

| Type | ID | Behavior | Status |
|------|-----|----------|--------|
| **Multiple choice** | `MC` | 3–4 options; one correct. | ✓ P0 |
| **Fill in the blank** | `FILL` | Partial line with `___`; user fills; normalize spaces/case before compare. | ✓ P1 |
| **Predict output** | `OUT` | Show program; user picks exact line of output (or types a number/string). | Planned P2 |
| **Find the bug** | `BUG` | Intentionally wrong line; user selects which line or types correction. | Planned P2 |
| **Assembler truth** | `ASM` | Given listing, user predicts byte size or branch target (advanced). | Planned P3 |

**R7 — Feedback:** Every wrong answer gets a **short** hint, not only “incorrect.” ✓  
**R8 — Retry:** User can retry without losing progress; optional “show solution.” ✓  
**R9 — No blocking:** Tests should run in **O(1)** time; no arbitrary `SYS` in autograder unless sandboxed. ✓

---

## 4. Technical concept — Trainer ROM cart

### 4.1 Cart identity

- **Class:** `CartTrainer` extends `ROMCart` (same pattern as `CartAsm`, `CartText`).  
- **Id / name:** `id=5`, name `TRAINER`, prompt `LEARN>`.  
- **Registered in:** `Computer._init()` alongside BASIC(0), TEXT(1), ASM(2), C(3), NATIVE(4).

### 4.2 Command surface

| Command | Purpose |
|---------|---------|
| `HELP` | Overview + command list. |
| `MENU` / `TOPICS` | List modules (BASIC / ASM / Bridge). |
| `OPEN n` / `LESSON n` | Open lesson `n` (numeric id). |
| `NEXT` / `BACK` | Navigate within module. |
| `QUIZ` | Start/re-run interactive block for current lesson. |
| `ANSWER ...` | Submit answer for last shown question (or use lettered prompts `A`/`B`/`C`, or type answer for FILL). |
| `PROGRESS` / `STATUS` | Show % complete (stored in cart state). |
| `CART BASIC` | Exit to practice. |

### 4.3 Where content lives

`res://trainer/curriculum.json` — curriculum outline with inline BBCode lesson bodies and quiz definitions. Loaded at runtime via `FileAccess` in `install()`.

### 4.4 State and persistence

`ROMCart.serialize()` / `deserialize()` — saves `completed` array, `scores` dict, `module_idx`, `lesson_idx`. F3 save state round-trips cart state.

### 4.5 Integration points

| System | Use |
|--------|-----|
| `CartManager` | Registered as id=5; `switch_to` clears $E000-$EFFF workspace. |
| `Computer.emit_richtext` | All lesson text uses same BBCode pipeline as ASM HELP. |
| `BasicInterpreter` | Optional: future OUT-style quizzes via disposable interpreter. |
| `Assembler6502` | Optional: future ASM quizzes via throwaway MemoryBus. |

---

## 5. Curriculum inventory (must cover)

Below lists are **authoritative checklists** derived from current code (`basic_interpreter.gd` keywords; ASM from `assembler6502.gd` / HELP). Any future keyword addition **updates this plan**.

### 5.1 BASIC — statements & flow (`_keywords` that are statements / meta)

Each gets: **explanation**, **1 example**, **1 quiz**.

`PRINT`, `INPUT`, `LET` (optional keyword), `IF`/`THEN`/`ELSE`, `GOTO`, `GOSUB`, `RETURN`, `FOR`/`TO`/`STEP`/`NEXT`, `REM`, `END`, `STOP`, `BREAK`, `DIM`, `READ`, `DATA`, `RESTORE`, `ON` (with `GOTO` / `GOSUB`), `DEF`/`FN`, `CLR`, `NEW`, `LIST`, `RUN`, `CONT`, `LOAD`, `SAVE`, `MEM`, `POKE`, `PEEK`, `SYS`, `WAIT`, `BSAVE`, `BLOAD`, `LOADOBJ`, `WRITE`, `READFILE`.

**Note:** `LIST`/`RUN`/`NEW` interact with the **live** program; Trainer lessons should use **scratch programs** or warn before `NEW`. Requirement **R10:** destructive commands in examples must be **sandboxed** or **prefaced** with “this clears your program.”

### 5.2 BASIC — functions (parsed as keywords + calls)

Each function: syntax, types (string vs number), **one example**, **one quiz**.

`INT`, `RND`, `ABS`, `SQR`, `SIN`, `COS`, `TAN`, `ATN`, `LOG`, `EXP`, `SGN`, `LEN`, `CHR$`, `ASC`, `LEFT$`, `RIGHT$`, `MID$`, `STR$`, `VAL`, `TAB`, `PEEK` (also statement-like in expressions).

### 5.3 BASIC — operators & punctuation

Teach as **groups** plus one **corner-case** example each:

| Group | Symbols / forms |
|-------|------------------|
| Arithmetic | `+`, `-`, `*`, `/`, `^` (power), unary `-` |
| Comparison | `=`, `<`, `>`, `<=`, `>=`, `<>` |
| Logical | `AND`, `OR`, `NOT` |
| Grouping / separators | `( )`, `,`, `;`, `:`, string `"..."`, hex `$FF` |

**R11:** Explain **string vs numeric** context (`PRINT "A" + "B"` vs `PRINT 1 + 2` per actual interpreter rules).

### 5.4 BASIC — line numbers & program model

Dedicated early units:

- How a **program** is a list of numbered lines.  
- Adding, replacing, deleting a line.  
- **Colon** `:` to put multiple statements on one line.

### 5.5 ASM — mnemonics (assembler-supported)

Mirror **cart ASM HELP** grouping; one lesson per **family**, plus one “mixed” review per phase:

- **Load/store / transfer:** `LDA`, `LDX`, `LDY`, `STA`, `STX`, `STY`, `TAX`, `TXA`, `TAY`, `TYA`, `TXS`, `TSX`  
- **Arithmetic / logic:** `ADC`, `SBC`, `AND`, `ORA`, `EOR`, `ASL`, `LSR`, `ROL`, `ROR` (memory and `A`)  
- **Inc/dec:** `INC`, `DEC`, `INX`, `DEX`, `INY`, `DEY`  
- **Compare:** `CMP`, `CPX`, `CPY`  
- **Branches:** `BCC`, `BCS`, `BEQ`, `BNE`, `BMI`, `BPL`, `BVC`, `BVS`  
- **Jump / control:** `JMP`, `JMP ()`, `JSR`, `RTS`, `RTI`, `BRK`  
- **Stack:** `PHA`, `PHP`, `PLA`, `PLP`  
- **Flags:** `CLC`, `SEC`, `CLD`, `SED`, `CLI`, `SEI`, `CLV`  
- **Other:** `NOP`, `BIT`

**R12:** For each addressing mode the assembler accepts, include **one** line of source showing it (`#imm`, zp vs abs, `,X` / `,Y`, `(zp,X)`, `(zp),Y`).

### 5.6 ASM — directives & tooling

`.ORG`, `.EQU`, `.BYTE`, `.WORD`, `.DB`, `.EXPORT`, `.ENTRY`, `.HELP_SYNTAX`, `.HELP_DESC`, `.HELP_EXAMPLE` (as implemented), **labels** (`LABEL:`), **comments** (`;`), **line-numbered editor** mental model.

### 5.7 ASM — environment concepts (no single “keyword”)

Separate narrative units + quizzes:

- **Registers** A, X, Y, PC, SP, flags **NZCIDV** (simplified charts).  
- **Memory map** for this sim: `$C000` keyboard, `$C002`/`$C003` screen, `$C030` cart, `$0800` default code, stack `$0100–$01FF`.  
- **`RUN` vs `SYS` vs `LOADOBJ`**: stack / RTS behavior (high level: “return address must make sense”).  
- **Two-pass assembler** idea in one paragraph + diagram.  
- **Hex** and **why** `$`.

---

## 6. Example lesson stubs (spec level)

### 6.1 BASIC example — `FOR` / `NEXT`

- **Idea:** Repeat code a counted number of times.  
- **Example:**

```text
10 FOR I = 1 TO 3
20 PRINT I
30 NEXT I
```

- **Quiz (`MC`):** “How many times does HELLO print? 10 FOR I=1 TO 4 ...” → correct: 4

### 6.2 ASM example — `BNE` + label

- **Idea:** Jump backward while a counter is not zero.  
- **Example:** (reuse **stars** demo structure from `cart_asm.gd`, 6–8 lines.)  
- **Quiz (`FILL`):** “What immediate value loads 10 into X?” → `#10` or `#$0A`

### 6.3 GPU example — drawing a line

- **Idea:** Use POKE to set registers and draw shapes.  
- **Example:**

```text
10 POKE 61424, 1    :REM bitmap mode
20 POKE 61429, 10   :REM X1
30 POKE 61431, 20   :REM Y1
40 POKE 61435, 150  :REM X2
50 POKE 61437, 100  :REM Y2
60 POKE 61433, 15   :REM white
70 POKE 61439, 2    :REM LINE command
```

- **Quiz (`FILL`):** “What command number draws a horizontal line?” → 5

---

## 7. Requirements summary (traceable)

| ID | Requirement |
|----|-------------|
| R1 | Trainer cart registered in `CartManager`; discoverable via `CART`. |
| R2 | `HELP` lists pedagogy and commands. |
| R3 | 100% coverage of §5.1–§5.7 over **released** curriculum versions (track % in `PROGRESS`). |
| R4 | All student-facing prose **grade-targeted** (Flesch-Kincaid ~8–10 where possible) + glossary. |
| R5 | Every interactive item has **correct answer**, **distractors**, **hint**, **explanation after submit**. |
| R6 | Serialize progress with **cart state** / F3 saves. |
| R7–R9 | See §3.3. |
| R10 | Safe handling of destructive BASIC commands in examples. |
| R11 | Explicit string vs numeric teaching. |
| R12 | ASM addressing modes represented once each. |

---

## 8. Phased delivery roadmap

| Phase | Scope | Exit criteria | Status |
|-------|--------|----------------|--------|
| **P0 — Spike** | Static `HELP` + 3 hand-written lessons + `MC` quiz type | Proof of BBCode + input parsing | ✓ Done |
| **P1 — BASIC core** | Variables through `GOSUB`/`RETURN`, all operators. GPU module. `FILL` quiz type. | 6 BASIC + 3 GPU lessons | ✓ Done |
| **P2 — BASIC full** | Files, `PEEK`/`POKE`, `SYS`, `LOADOBJ`. `OUT` quiz type. | §5.1–§5.4 complete | Planned |
| **P3 — ASM core** | LDA/STA/branches/subroutines + map. `BUG` quiz type. | §5.5 subset | Planned |
| **P4 — ASM full** | All mnemonics + directives. `ASM` quiz type. | §5.5–§5.6 complete | Planned |
| **P5 — Capstone** | One multi-part project + certificate text | Player can explain BASIC vs ASM tradeoffs | Planned |

---

## 9. Authoring workflow

1. Add unit to `curriculum.json` with `id`, `title`, `prereq`, `body`, `quizzes[]`.  
2. Write `body` inline as BBCode (in `curriculum.json`).  
3. Peer review for **accuracy** against interpreter.  
4. Add **automated** test: load JSON, assert every `id` is unique, every `prereq` exists, every quiz has answer key.

---

## 10. Risks & open questions

| Risk | Mitigation |
|------|------------|
| Interpreter drift | CI test: generated list of `_keywords` keys matches `curriculum.json` keyword list. |
| Quiz ambiguity | Prefer `MC` over free-text; normalize `FILL` answers aggressively. |
| Wall of text | Cap **body** at ~400 words per lesson; split into A/B parts. |
| ASM cart duplication | Single **source of truth** for mnemonic list: export from script or generate in CI from `assembler6502.gd`. |

**Open questions**

- Should Trainer **auto-switch** to BASIC cart for “Try in BASIC” buttons, or only **instruct** the user? (Recommendation: **instruct** in v1 to avoid surprising context loss.)  
- Localization (non-English) — **out of scope** until English v1 ships.

---

## 11. Maintenance

- When **`basic_interpreter.gd`** `_keywords` or expression grammar changes, update **§5** and bump curriculum **version** field.  
- When **`assembler6502.gd`** opcode table changes, update ASM checklist and re-run capstone labs.  
- Keep **`trainer.md`** as the **vision doc**; detailed lesson text lives under `res://trainer/curriculum.json` once implementation starts.

---

*Document version: 1.2 — P1 expansion with GPU module, FILL quiz type, hacker-culture tone (G6)*  
*Updated: 2026-05-12*

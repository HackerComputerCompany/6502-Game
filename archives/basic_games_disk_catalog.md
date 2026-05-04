# BASIC games archive — text-only floppy catalog

This document **curates** classic **early BASIC** games that need **no bitmap graphics**: play happens in **PRINT / INPUT** text, ASCII art, or simple numeric grids. The goal is a future **in-game floppy** library—typed listings you **LOAD**, **RUN**, and study—using a **two-sided, 140 KiB-per-side** metaphor rooted in real **late-1970s / early-1980s** hardware.

---

## Virtual floppy: **140 KiB × Side A / Side B**

### Why this geometry?

Single-sided **5.25″ DOS 3.3–style** layouts on the **Apple II** are famously about **140 KiB per surface**: **35 tracks × 16 sectors × 256 bytes = 143,360 bytes**, which is exactly **140 × 1024 = 140 KiB**. Learners who read Apple II or Applesoft histories already bump into this number.

We adopt it deliberately:

| Idea | Detail |
|------|--------|
| **One floppy disk** | Two independent **surfaces**: **Side A** and **Side B**. |
| **Capacity per side** | **140 KiB** (143,360 bytes) — hard budget for files catalogued on that side. |
| **Total on the plastic** | Up to **280 KiB** if **both** sides are formatted and used (double-sided disk). |
| **Pedagogy** | **Flip the disk** to reach the other catalog; **SIDE FULL** errors; planning where big listings live. |

This replaces an earlier **single lump-sum “420K”** sketch. **280 KiB** (both sides) is still modest—forcing curation—but **Side A / Side B** matches **physical intuition** and classroom explanations better than one opaque quota.

### Conceptual layers (no code yet)

1. **Physical metaphor** — The user imagines a **5.25″ floppy**: label facing up → **Side A**; flip → **Side B**. Some drives were **single-sided** (only Side A existed on early media); we can simulate “double-sided only” for simplicity.

2. **Volume vs side** — Each **side** is its own **small filesystem view**: `DIR` lists files **on the active side only**, or `DIR A:` / `DIR B:` if we expose explicit paths.

3. **Active side** — Commands like **`USE A`** / **`USE B`**, **`FLIP`**, or **`MOUNT SIDE=B`** switch context. **SAVE** writes to the active side; refuse if **remaining free bytes are less than the file size**.

4. **Catalog spanning** — This markdown catalog lists **more games than fit one side**; implementation assigns each shipped `.bas` to **Side A**, **Side B**, or **needs second disk** (future **Disk 2**).

5. **Not RAM** — Same teaching as before: **disk** persists across sessions (within **user://**); **RAM** is volatile unless **SAVEd**.

6. **State saves (F3)** — Still **host JSON**, **not** charged against floppy KiB (keeps saves reliable).

### UX snippets (future)

```
DISK STATUS
  Medium: 5.25" DS/DD (conceptual)
  Side A:  87,040 / 140 KiB bytes used (62%)   22 files
  Side B: 140 KiB free                         READY
  Active side: A

FLIP
  Now using SIDE B.
```

### Implementation sketch (folders)

Binary-accurate sector images are **optional** later; **v1** can enforce quotas on folders:

```
user://floppy0/
  side_a/       # ≤ 140 KiB total file bytes
  side_b/       # ≤ 140 KiB total file bytes
  manifest.json # optional: label, volume name, assignment table
```

Shipped read-only content: **`res://archives/floppy0_side_a/`** etc., with **user://** overlay for saves.

---

## Selection criteria

1. **No graphics hardware** — no `POKE` to video RAM for pixels; **ASCII / text** only (lines of stars, coarse maps, etc. are OK).  
2. **Actually a game** — goal, rules, replay value (not only a demo).  
3. **BASIC-sized** — many listings **under ~8 KiB**; several fit **per side** with room for docs.  
4. **Reasonable port** — runs or **almost runs** on **Microsoft-style BASIC** with `PRINT`, `INPUT`, `GOTO`, `FOR`/`NEXT`, `IF`/`THEN`, `RND`, strings; flag heavy **machine-specific** calls.

**BASIC6502 notes:** See **USER_GUIDE.md**. Watch for **`TAB`**, **`RND`**, **`INT`**, string functions, **`ON ... GOTO`**, **`PEEK`/`POKE`** (non-graphical only), **`DATA`/`READ`**, **`GOSUB`**, **`DEF FN`**. Games using **INKEY$**, **GET**, **hardware CLS**, or **PETSCII-only** art may need edits.

---

## Primary source anthology

| Resource | Notes |
|----------|--------|
| **David H. Ahl, *BASIC Computer Games* (1978, Microcomputer Edition)** | ~**101** listings; many text-only; [Wikipedia](https://en.wikipedia.org/wiki/BASIC_Computer_Games). |
| **Creative Computing** | Mixed; cherry-pick text titles. |
| **DEC “101 BASIC Computer Games” (1973)** | Overlaps Ahl 1978. |

When **vendoring** `.bas` files: **attribution** + **license** note per file; book scans may still be **copyright**—legal review before verbatim ship.

---

## Catalog — curated text-only games

Legend: **★** = strong for teaching; **Port** = friction for BASIC6502.

| # | Title | Era / book | Genre | Why it fits (no gfx) | Port notes |
|---|--------|--------------|-------|----------------------|------------|
| 1 | **Acey Ducey** | Ahl | Card / gambling | Text cards & stakes | Simple |
| 2 | **Amazing** | Ahl | Maze | ASCII maze generation | Loops + arrays |
| 3 | **Animal** | Ahl | Guessing / learning | Binary tree of questions | Strings |
| 4 | **Awari** | Ahl | Mancala-style | Board as numbers | Array indexing |
| 5 | **Bagels** / **Digits** family | Ahl / variants | Logic puzzle | Digits & clues | String compare |
| 6 | **Banner** | Ahl | Toy | Big letters from `*` | Loops only |
| 7 | **Blackjack** | Ahl | Card | Text hand totals | Moderate length |
| 8 | **Bombs Away** | Ahl | War sim | Text stats | `RND` heavy |
| 9 | **Bowling** | Ahl | Sports | Score table | Simple |
| 10 | **Bullseye** | Ahl | Darts | Numeric targets | `RND` |
| 11 | **Buzzword** | Ahl | Humor | Mad-libs style | Strings |
| 12 | **Calendar** | Ahl | Utility / puzzle | Month layout text | `FOR` loops |
| 13 | **Change** | Ahl | Math / cashier | Coins | Integer math |
| 14 | **Checkers** | Ahl | Board | Text board print | 2D grid ASCII |
| 15 | **Chemist** | Ahl | Puzzle | Mixing beakers text | If/else chains |
| 16 | **Chomp** | Ahl | Grid take-away | ASCII grid | 2 loops |
| 17 | **Civil War** | Ahl | Battle sim | Narrative + numbers | Long but text |
| 18 | **Combat** | Ahl | Artillery | Angle & velocity text | Physics intro |
| 19 | **Craps** | Ahl | Dice | Dice totals | `RND` |
| 20 | **Cube** | Ahl | Puzzle | 3D wireframe-ish ASCII | Math |
| 21 | **Depth Charge** | Ahl | Hunt | Sonar “distance” text | Search game |
| 22 | **Dice** | Ahl | Dice | Frequencies | Arrays + `RND` |
| 23 | **Even Wins** | Ahl | Nim variant | Take stones | Math strategy |
| 24 | **Flip Flop** | Ahl | Puzzle | Flip bits / pattern | Logic |
| 25 | **Football** | Ahl | Sports sim | Play-by-play text | Long |
| 26 | **Fur Trader** | Ahl | Econ sim | Seasons & pelts | Resource mgmt ★ |
| 27 | **Golf** | Ahl | Sports | Text shots | `RND` |
| 28 | **Gomoku** | Ahl | Board | 15-in-row ASCII | 2D |
| 29 | **Guess** | Ahl | Number guess | Classic | Beginner ★ |
| 30 | **Gunner** | Ahl | Artillery | Shell trajectory text | Angles |
| 31 | **Hi-Lo** | Ahl | Price is Right spoof | High/low | `RND` |
| 32 | **High-Q** (quiz) | Ahl | Trivia | Q&A text | `DATA`/`READ` ★ |
| 33 | **Hammurabi** / **King** | Ahl | Resource / kingdom | Grain & people | Classic econ ★ |
| 34 | **Hurkle** | Ahl | Hide & seek grid | “NW” hints on grid | Coordinates ★ |
| 35 | **Kinema** | Ahl | Physics quiz | Word problems | Education |
| 36 | **Letter** | Ahl | Word ladder | Transform word | Strings |
| 37 | **Life** (text board) | many ports | Cellular automaton | ASCII generation | Pick text-only ports |
| 38 | **Lunar / Rocket** | Ahl | Lander | Fuel & thrust numbers | Physics ★ |
| 39 | **Master Mind** | Ahl | Code breaking | Bulls & cows style | Logic ★ |
| 40 | **Math Dice** | Ahl | Drill | Arithmetic speed | Teaching |
| 41 | **Mugwump** | Ahl | Hide 4 creatures | Distance on grid | Fun search ★ |
| 42 | **Nim** | Ahl | Take-away | Perfect-play teaching | Math |
| 43 | **Number** | Ahl | Puzzle | Digit puzzles | Logic |
| 44 | **One Check** | Ahl | Solitaire card | Text piles | Moderate |
| 45 | **Orbit** | Ahl | Orbit sim | Text telemetry | Science |
| 46 | **Pizza** | Ahl | Fractions | Word problems | Education |
| 47 | **Poetry** | Ahl | Random poem | Templates | Strings |
| 48 | **Poker** | Ahl | Card | Text hands | Long |
| 49 | **Prime** / **Prime Tester** | Ahl / magazines | Math | Primes | Loops |
| 50 | **Queen** | Ahl | Chess puzzle | Text board | Rare moves |
| 51 | **Reverse** | Ahl | List reorder puzzle | Sort challenge | Arrays ★ |
| 52 | **Rock Sissors Paper** | Ahl | Hand game | vs computer | `RND` beginner |
| 53 | **Roulette** | Ahl | Casino | Text wheel | `RND` |
| 54 | **Salvo** | Ahl | Battleship-like | Grid + reports | May be long |
| 55 | **Sine Wave** | Ahl | Demo | `*` across screen | ASCII OK |
| 56 | **Slots** | Ahl | Casino | Reels as text | `RND` |
| 57 | **Stars** (number guessing) | Ahl | “Thermometer” stars | `*` distance hint | Beginner ★ |
| 58 | **Stock Market** | Ahl | Sim | Portfolio text | Econ ★ |
| 59 | **Synonym** | Ahl | Vocab drill | Thesaurus quiz | `DATA` |
| 60 | **Target** | Ahl | Shooting | Numeric scoring | Simple |
| 61 | **3-D Plot** / **Cube** family | Ahl | Math viz | ASCII projection | Math club |
| 62 | **Tic-Tac-Toe** | everywhere | Board | 3×3 ASCII | Classic ★ |
| 63 | **Tower** | Ahl | Hanoi | Disk moves text | Stacks idea |
| 64 | **War** (card war) | Ahl | Card | Compare piles | Simple |
| 65 | **Word** | Ahl | Hangman-like | Guess letters | Strings ★ |
| 66 | **Yahtzee**-style dice | magazines | Dice | Categories | Arrays |
| 67 | **Super Star Trek** | Ahl | Space sim | All-text map & phasers | Long ★ |
| 68 | **Star Trek** (short variants) | magazines | Space | Lighter than Super | Shorter |
| 69 | **Wumpus** / **Hunt the Wumpus** | many BASIC ports | Cave hunt | Text dodecahedron map | Graph ★ |
| 70 | **Eliza** (tiny ELIZA) | Weizenbaum ports | Chatbot | Conversation | Strings; length |
| 71 | **Hangman** | school listings | Word game | ASCII gallows optional | Common |
| 72 | **Concentration** | listings | Memory | Paired numbers | Text match |
| 73 | **Battleship** (text) | many | Grid game | Row/column fire | I/O heavy |
| 74 | **Oregon Trail**-style (lite) | inspired listings | Trek | Text choices | Often trim |
| 75 | **Camel** / **Lunar** variants | Creative Computing | Resource trek | Numbers | Short fun |

**Excluded:** sprite graphics, joystick arcade ports; **PETSCII-only** may need ASCII translation.

---

## Suggested placement on **Side A / Side B**

Rough split for **Disk 1** (both sides = **280 KiB** games+demos budget):

| Side | Role | Starter contents |
|------|------|------------------|
| **A** | **Learn + tiny games** | Tutorial snippets, **Guess**, **Stars**, **Rock Scissors Paper**, **Tic-Tac-Toe**, **Nim**, **High-Q** samples |
| **B** | **Play + longer listings** | **Hammurabi**, **Fur Trader**, **Master Mind**, **Reverse**, **Word**, **Mugwump**, **Lunar** |

Heavy titles (**Super Star Trek**, **Civil War**) may **consume much of one side alone**—either ship **trimmed ports**, **split chapters**, or **Disk 2**.

---

## Next steps (engineering)

- [ ] **`disk_manager.gd`**: track **`bytes_used_side_a`**, **`bytes_used_side_b`**, **cap = 143_360** each.  
- [ ] **`USE A` / `USE B` / `FLIP`** (or equivalent) in terminal / BASIC.  
- [ ] **`DISK`** status line: active side + both utilizations.  
- [ ] **`SAVE`**: refuse if active side over quota (“SIDE FULL — FLIP DISK OR DELETE”).  
- [ ] Ship **`res://archives/floppy0/`** with manifest mapping catalog rows → filenames → side.  
- [ ] **Trainer cart**: quizzes referencing “load from Side B slot 3,” etc.

---

## Changelog of *this* catalog

| Version | Date | Changes |
|---------|------|---------|
| 0.1 | 2026-05-03 | Initial curation; 75-row catalog; starter pack. |
| 0.2 | 2026-05-03 | **140 KiB per side**, **Side A / Side B** model; removed single **420K** volume concept; added UX + folder sketches; A/B placement table. |

---

*Maintainers: when assigning files to sides, append columns **Side** and **Bytes** to this doc or to `manifest.json`.*

# BASIC games archive — text-only disk catalog

This document **curates** classic **early BASIC** games that need **no bitmap graphics**: play happens in **PRINT / INPUT** text, ASCII art, or simple numeric grids. The goal is a future **in-game “disk”** library for BASIC6502—typed listings you can **LOAD**, **RUN**, and study—while teaching the **disk metaphor** (files live on a volume, not only in RAM).

---

## Virtual “420K” floppy (concept)

Home computers of the late 1970s–1980s often used **5.25″ floppy drives**. Capacities varied by machine and format (Apple DOS ~**140 KiB** per disk side, PC-DOS **360 KiB** double-density, etc.). For BASIC6502 we adopt a **fictional but memorable** label:

| Name (working) | Size | Role |
|----------------|------|------|
| **HCC 420K Disk** | **~420 KiB** nominal | One **virtual floppy** image (`user://` or bundled `res://`) holding **many short `.bas` listings** + this catalog. |

**Why 420 KiB?** It is in the same ballpark as a **single-sided, double-density 5.25″** PC-class disk in some formulations, rounds nicely for teaching, and reads as a **product name** (“four-twenty-K disk”) without tying us to one historic geometry. Implementation can map it to **ZIP of text files**, a **folder manifest**, or a **packed archive** later.

**This phase:** catalog and source pointers only—**no drive emulation code yet**.

---

## Selection criteria

1. **No graphics hardware** — no `POKE` to video RAM for pixels; **ASCII / text** only (lines of stars, coarse maps, etc. are OK).  
2. **Actually a game** — goal, rules, replay value (not only a demo).  
3. **BASIC-sized** — typically **under ~8 KiB** source; fits many titles on one “420K” volume.  
4. **Reasonable port** — runs or **almost runs** on **Microsoft-style BASIC** with `PRINT`, `INPUT`, `GOTO`, `FOR`/`NEXT`, `IF`/`THEN`, `RND`, strings; flag heavy **machine-specific** calls.

**BASIC6502 notes:** Our dialect is documented in **USER_GUIDE.md**. Watch for: **`TAB`**, **`RND`**, **`INT`**, **`LEFT$`/`MID$`/`RIGHT$`**, **`ON ... GOTO`**, **`PEEK`/`POKE`** (only if game uses them for **non-graphical** I/O), **`DATA`/`READ`**, **`GOSUB`**, **`DEF FN`** (if used). Games that assume **INKEY$**, **GET**, **sound**, or **CLS** as hardware opcodes may need tiny edits.

---

## Primary source anthology

| Resource | Notes |
|----------|--------|
| **David H. Ahl, *BASIC Computer Games* (1978, Microcomputer Edition)** | ~**101** listings; many are text-only; widely reprinted; **Internet Archive** hosts scans and sometimes OCR text. [Wikipedia overview](https://en.wikipedia.org/wiki/BASIC_Computer_Games). |
| **Creative Computing** magazine listings | Short games in **BASIC**; mixed graphics—**cherry-pick** text titles. |
| **DEC “101 BASIC Computer Games” (1973)** | Earlier edition; subset overlaps Ahl 1978. |

When we **vendor** `.bas` files into the repo, prefer **typed clean listings** with **attribution** (author name from the book where given) and a **one-line license** note (many community retypes are **MIT** or **CC0**; book text itself may still be **copyright**—legal review before shipping verbatim scans).

---

## Catalog — curated text-only games

Legend: **★** = especially strong for teaching; **Port** = typical friction for BASIC6502.

| # | Title | Era / book | Genre | Why it fits (no gfx) | Port notes |
|---|--------|--------------|-------|----------------------|------------|
| 1 | **Acey Ducey** | Ahl | Card / gambling | Text cards & stakes | Simple |
| 2 | **Amazing** | Ahl | Maze | ASCII maze generation | Loops + arrays |
| 3 | **Animal** | Ahl | Guessing / learning | Binary tree of questions | Strings; teach AI idea |
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
| 37 | **Life** (text board) | many ports | Cellular automaton | ASCII generation | Some ports use gfx—**pick text-only** |
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
| 55 | **Sine Wave** | Ahl | Demo | `*` across screen | **ASCII only** OK |
| 56 | **Slots** | Ahl | Casino | Reels as text | `RND` |
| 57 | **Stars** (number guessing) | Ahl | “Thermometer” stars | `*` distance hint | Beginner ★ |
| 58 | **Stock Market** | Ahl | Sim | Portfolio text | Econ ★ |
| 59 | **Synonym** | Ahl | Vocab drill | Thesaurus quiz | `DATA` |
| 60 | **Target** | Ahl | Shooting | Numeric scoring | Simple |
| 61 | **3-D Plot** / **Cube** family | Ahl | Math viz | ASCII projection | Math club |
| 62 | **Tic-Tac-Toe** | everywhere | Board | 3×3 ASCII | Classic port ★ |
| 63 | **Tower** | Ahl | Hanoi | Disk moves text | Recursion / stacks idea |
| 64 | **War** (card war) | Ahl | Card | Compare piles | Simple |
| 65 | **Word** | Ahl | Hangman-like | Guess letters | Strings ★ |
| 66 | **Yahtzee**-style dice | magazines | Dice | Categories | Arrays |
| 67 | **Super Star Trek** | Ahl | Space sim | **All text** map & phasers | **Long**; iconic ★ |
| 68 | **Star Trek** (short variants) | magazines | Space | Lighter than Super | Shorter port |
| 69 | **Wumpus** / **Hunt the Wumpus** | many BASIC ports | Cave hunt | Text dodecahedron map | Graph traversal ★ |
| 70 | **Eliza** (tiny ELIZA) | Weizenbaum ports | Chatbot | Conversation | Strings; length |
| 71 | **Hangman** | school listings | Word game | ASCII gallows optional | Very common |
| 72 | **Concentration** | listings | Memory | Paired numbers | Text match |
| 73 | **Battleship** (text) | many | Grid game | Row/column fire | I/O heavy |
| 74 | **Oregon Trail**-style (lite) | inspired listings | Trek | Text choices | Often multi-file—**trim** |
| 75 | **Camel** / **Lunar** variants | Creative Computing lineage | Resource trek | Numbers | Short fun |

**Excluded (for this disk):** games whose **primary fun** is **moving sprites**, **PSET/DRAW**, **joystick** (e.g. many **action** arcade ports). **Screen codes** (C64 PETSCII) that are **not** plain ASCII may need a **translation pass**.

---

## Suggested “Disk 1” starter pack (priority order)

First wave to type-check against BASIC6502 (smallest + highest teaching value):

1. **Guess** / **Stars** (number games)  
2. **Rock Scissors Paper**  
3. **Tic-Tac-Toe**  
4. **Hurkle** or **Mugwump**  
5. **Nim** or **Even Wins**  
6. **Master Mind**  
7. **Hammurabi** / **King**  
8. **Fur Trader**  
9. **Reverse**  
10. **Word** / **Hangman**  

Then medium: **Lunar**, **Combat**, **Civil War**, **Super Star Trek** (split into chapters if needed).

---

## File layout (future implementation)

```
user://disk420/
  CATALOG.md          # copy of or symlink to this catalog
  games/
    guess.bas
    stars.bas
    ...
```

Or **`res://archives/disk420/`** for read-only shipped games + **`user://`** overlay for saves.

---

## Next steps (engineering, later)

- [ ] Pick **license-clean** `.bas` sources (typed from PD listings or contributor originals).  
- [ ] Add **`DIR`/`LOAD`** integration or **`DISK`** command to **mount** `disk420` volume.  
- [ ] Byte budget: enforce **~420 KiB** total for teaching moment (“disk full”).  
- [ ] **Trainer cart** (`trainer.md`) cross-link: “Load `games/reverse.bas` and predict output.”

---

## Changelog of *this* catalog

| Version | Date | Changes |
|---------|------|---------|
| 0.1 | 2026-05-03 | Initial curation: criteria, 420K concept, 75-row catalog, starter pack, future layout. |

---

*Maintainers: append rows as you vet each listing; keep “text-only” column honest.*

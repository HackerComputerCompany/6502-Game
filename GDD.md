# Open World Hacking Simulator — Game Design Document

**Codename:** signal.zero  
**Genre:** Open-world hacker RPG / Educational simulator  
**Target platforms:** Desktop (Godot 4), eventual console/portable  
**Art style:** SNES Earth Bound (Mother 2) — 16-bit cartoony pixel art, expressive sprites, charming chibi proportions, warm color palette  
**Timeframe:** Mid 1980s through late 1990s  
**Tone:** Clever, conspiratorial, inclusive. Same voice as the trainer cart — the game confides in you, never talks down. Humor is dry, references are deep, in-jokes reward curiosity.  
**Rating target:** Teen (mild language, thematic hacking, period-appropriate tech noir)

---

## 1. Vision Statement

You are a teenager in the 80s and 90s who discovers that the world is made of systems — phone networks, computer networks, vending machines, traffic lights, ATMs, pinball high-score tables, cellular radio — and systems can be understood, manipulated, and sometimes broken. You learn by doing: reading old computer manuals in library basements, dumpster-diving behind electronics shops, wiretapping payphones, cloning cell phones from captured ESN/MIN pairs, trading BBS secrets with strangers who use cryptic handles and call themselves "sysop," "root," and "phantom." The game teaches real electronics, real programming, and real systems thinking wrapped in an Earth Bound–style adventure.

---

## 2. Three Gameplay Modes

### 2.1 Keyboard Time (Existing Teaching Lab)

The "computer simulation" mode. This is the existing 6502 teaching lab project, integrated as a first-class game mechanic.

**What you do:** Sit at in-game computer terminals (your bedroom Vector 64, a school Scholar II, a library Lab-80, a workbench Omni PC) and actually program. The terminal/graphics UI, BASIC6502 interpreter, assembler, trainer cart, and GPU system are the game.

**How it fits the game:**
- Progress in the overworld unlocks new Keyboard Time abilities
- Solving Keyboard Time challenges gives you items, passwords, phone numbers, and data files for the overworld
- The trainer cart is the in-game tutorial — someone left a pirated copy of "HACKER TRAINER" on a floppy at the dumpster
- Later terminals support more CPUs (8080/Z80/8086) matching later time periods
- The GPU display appears in-game as the monitor connected to each terminal

**In-world framing:** You found an old computer at a garage sale. The previous owner was a phreaker who left his notes on the hard drive. As you learn, you unlock his old contacts, tools, and targets.

---

### 2.2 Hands On Hardware (Puzzle Mode)

Top-down or first-person puzzle scenes rendered in Earth Bound pixel art. You manipulate hardware at close range — circuit boards, phone punchdown blocks, soldering irons, oscilloscopes, EPROM programmers, cable crimpers.

**Art style:** Earth Bound's detailed close-up item screens but interactive. Wires, chips, screws, and switches rendered as 16-bit sprites with animation.

**What you do:**
- Identify components on a circuit board (resistor color codes, capacitor markings, IC part numbers)
- Solder wires to the right pins on a 555 timer to make an LED blinker
- Punch down phone lines on a 66 block to create a bridge tap
- Use a multimeter to find broken traces
- Decode DTMF tones from a recorded payphone call
- Program an EPROM with a hex file you wrote in Keyboard Time
- Build a serial cable pinout (DB-9 / DB-25 null modem)
- Configure a dial-up modem's jumpers for the right IRQ/COM port
- Capture ESN/MIN pairs from analog cellular traffic using a radio scanner
- Program cloned ESN/MIN into a bag phone via serial cable and programming software
- Repair a floppy drive by replacing the spindle motor

**Progression:**
- Early puzzles teach passive observation (identify parts, read schematics)
- Mid puzzles teach modification (add a capacitor, change a jumper)
- Late puzzles teach creation (build a blue box from a ChipMart tone dialer)
- Master puzzles require knowledge from both Keyboard Time and Overworld exploration

**Teaching philosophy (same as trainer cart):** Real hardware, real skills. The 2600 Hz whistle from a cereal box is a historical fact, not a game abstraction. When you learn how a transistor works, it maps to a real 2N2222 you can buy today.

---

### 2.3 Overworld (Adventure Mode)

Earth Bound–style top-down 16-bit RPG. The game opens in your bedroom — a cramped, lived-in space in the Mitchell family house. A bed against one wall, a window overlooking the street, a desk cluttered with computer gear. Clothes scattered on the floor. It's summer 1985. Your dad is Colonel Bob Mitchell, stationed at Fort Stirling — a war college on the edge of town. The family lives off-base in the subdivision. You just returned from a garage sale where you bought a used Vector 64 computer for $15. The previous owner left a box of floppy disks in the bottom of the box.

Your sister Jessica thinks you're a nerd. Your mom Linda tolerates the computer because "it must be good for job skills." Your dad brings home surplus electronics occasionally and hopes you'll go to college. You've got $3.25 in your pocket and a $5 weekly allowance if you keep up with your chores.

From here you move through a small city and surrounding areas — your school, library, ChipMart electronics shop, phone company building, junkyard, the lazer tag arcade, BBS meetup spots, the "rich kid" neighborhood with better equipment, and the church on the square where not everything is as pious as it seems.

**Art style:** Direct Earth Bound homage:
- Chibi 16×24 NPC sprites with expressive idle animations
- Warm, saturated 16-bit color palette (green grass, brown dirt, teal buildings)
- Suburban / small-city America mid-80s to late-90s
- Day/night cycle with different NPC schedules
- Interior/exterior transitions (Earth Bound style — walk into a door, cut to interior)

**What you do:**
- Walk around town, talk to NPCs (other hackers, electronics store clerks, phone company employees, librarians, cops, FBI agents)
- Dumpster dive behind ChipMart for components and discarded equipment
- Wiretap payphones by physically accessing the telco box (requires Hands On skills)
- Break into the school computer lab after hours (requires lockpicking? or social engineering?)
- Trade floppy disks with other kids in the schoolyard
- Read zines and BBS text files for clues and phone numbers
- Get caught by police → mini-game evasion sequence (Earth Bound–style "run away" screen)
- Buy equipment at the electronics store (multimeter, soldering iron, EPROM eraser, etc.)
- Run war dialers from your bedroom computer — scan blocks of phone numbers for modems, PBX tones, and carrier loops
- Social-engineer your way into the water reclamation department by posing as a contractor from the control system vendor
- Break into OmniStor Technologies' sales order system using a phone number found in a dumpstered sales manual and a default password you guessed
- Find hidden "easter egg" locations: the phone company switching office, the university computer room, a pirate radio station
- Get a part-time job repairing lazer tag equipment at the arcade — honest work until the owner shows you the back room and asks if you "know anything about cell phones"

**Town layout ("IntRural," population ~4,000):**

| Quadrant | Location | Notes |
|----------|----------|-------|
| NW | Library | Gray walls, gray roof — librarian has SCADA manual |
| NW | School | Brown walls, red roof — large building |
| NW | Church | Gray walls, gray roof — PBX in basement |
| W (NW block) | Thrift Store | Brown walls, red roof |
| W (NW block) | Post Office | Gray walls, gray roof |
| W (NW block) | Bank | Beige walls, red roof |
| W (NW block) | Fire Department | Gray walls, red roof |
| W (NW block) | Police Department | Beige walls, gray roof |
| NE | ChipMart | Brown walls, red roof — electronics parts store, dumpster out back |
| NE | Phone Co. Central Office | Gray walls, gray roof |
| NE | Lazer Arcade | Gray walls, gray roof |
| NE | Grocery Store | Brown walls, red roof |
| NE | Diner | Brown walls, red roof |
| NE | Hospital | Gray walls, gray roof — large building |
| NE | Radio Station | Brown walls, red roof |
| NE | Auto Repair | Gray walls, gray roof |
| NE | Barber Shop | Beige walls, red roof |
| W Subdivision | Miller House | Beige walls, red roof |
| W Subdivision | Player's House | Beige walls, red roof — double door, garage + workshop, family home |
| W Subdivision | Garcia House | Brown walls, red roof |
| W Subdivision | Johnson House | Gray walls, gray roof |
| W Subdivision | Patel House | Brown walls, red roof |
| W Subdivision | Williams House | Beige walls, red roof |
| W Far | Rich Kid House | Beige walls, red roof — fenced, bigger lot |
| E | Burger Barn | Brown walls, red roof — fast food |
| SE | OmniStor Technologies | Gray walls, gray roof — large building |
| SE | Office Building 2 | Beige walls, red roof |
| SE | Pharmacy | Gray walls, red roof |
| SE | Water Reclamation Dept | Gray walls, gray roof — SCADA target, next to lake |
| SW | Power Substation | Fenced, brown walls, gray roof |
| S | Junkyard | Fenced area |
| Far SE | Lake | Water tiles, not passable |
| Out of town | **Fort Stirling (military base)** | Not yet mapped — war college, Dad's posting, off-base commuting family |

**Map scale:** 100×82 tiles (expanded from 60×55). Sidewalk tiles line major roads. 3-wide Main Street and Boulevard, 2-wide secondary roads. All buildings have proper clearance from roads via sidewalks and green space.

**House interior layout (48×21 tiles):**
- Garage/Workshop (left) with bench, tools
- 4 bedrooms in a row (Your Room is bedroom 1, bed + desk with computer)
- Hallway connecting all rooms
- Bathroom, Living Room, and Kitchen in southern half
- Kitchen has trash can (interactive — take out garbage chore)
- Desk and bed are interactive furniture (yellow flash, Space to use)
- Mom, Dad, and Jessica spawn in living room / kitchen / hallway respectively

**House interior layout (48×21 tiles):**
- Garage/Workshop (left) with bench, tools
- 4 bedrooms in a row (Your Room is bedroom 1, bed + desk with computer)
- Hallway connecting all rooms
- Bathroom, Living Room, and Kitchen in southern half
- Desk and bed are interactive furniture (yellow flash, Space to use)

**Target systems (the "gems"):**
Each target is a real-world system you research, locate, and penetrate using a mix of social engineering, dumpster diving, and technical skill:

- **Water Reclamation Department** — The city's wastewater treatment plant runs on a SCADA system accessible via dial-up. Getting in means: finding the plant's phone number (dumpster diving for an old invoice or emergency contact list), calling the control room modem, and navigating a menu-driven terminal interface that assumes you're an operator. Once inside, you can read tank levels, valve status, and error logs — and maybe change a setpoint. No hack is complete without leaving a "FLUSHED" message on the operator console.
- **OmniStor Technologies Sales System** — OmniStor is a mid-90s storage peripheral manufacturer (Zip drives, tape backups). Their sales order system is a text-based ERP portal accessible via a dial-up number that changes quarterly. Getting the current number requires: making friends with a sales rep on a BBS, finding a discarded sales manual in the dumpster behind their office park, or calling the main switchboard and bluffing your way past the receptionist ("Hi, this is Bob from IT — we're updating the remote access list and I need to verify the modem pool numbers"). Once in, you can browse order histories, check inventory, and maybe reroute a shipment.
- **Lazer Tag Arcade (back room)** — What starts as an honest job repairing phaser packs and servo motors turns into something darker. The arcade owner runs a side business pre-programming cloned cell phones for local dealers and criminals. You're brought in because you understand ESN/MIN programming from first principles, not just a script from a zine. This is where the game gets dangerous: the people you're programming for are violent, the FBI is already watching the payphone outside, and every phone you flash could be traced back to the workbench. One wrong number and you're not just grounded — you're evidence.
- **Church** — The First IntRural Church sits on the town square. The congregation is respectable, the potlucks are legendary, and the basement houses a PBX that the deacon doesn't know is reachable from the utility closet phone jack. The pastor's study has a computer — a Vector 64, same as yours — and the youth group leader keeps a BBS node running off the church's second phone line. Story-critical location: the church is where you learn that information wants to be free, even when someone tries to lock it up.
- *More targets discovered through exploration, BBS rumors, and NPC dialogue.*

**Social systems (inspired by Earth Bound's phone calls):**
- Your home phone receives calls with tips, taunts, and mission briefings
- Call other hackers via payphones using phone numbers found in Keyboard Time
- Leave messages on BBS systems (which you access via Keyboard Time)
- NPCs have daily routines — the librarian is only at the library 9 AM–5 PM

**Time progression:**
- The game world advances in chapters / years: 1985 → 1990 → 1995
- Each time skip changes available technology, NPCs, locations, and the law
- Your character ages visually (shorter sprite in 1985, taller in 1995)
- Early chapters are innocent (learning BASIC, exploring BBSes)
- Mid chapters introduce phreaking, war dialing, and real security concepts
- Late chapters deal with early internet, hacked credit bureaus, and the FBI showing up

---

## 3. Player Progression

### 3.1 Skill System (XP-based)

Each skill is 0–100, earned through gameplay actions. Skills unlock abilities, dialogue options, and permit access to harder content.

| Skill | Key | What it tracks | XP sources |
|-------|-----|----------------|------------|
| Code Fu | `basic_programming` | Writing BASIC, solving puzzles at terminals | +3 per program run, +10 per challenge completed, +15 per new language learned |
| Hex Sense | `assembly` | Reading/writing machine code | +5 per disassembly, +10 per ROM hack, +20 per new CPU mastered |
| Solder Finger | `electronics` | Building and fixing hardware | +3 per component identified, +5 per solder joint, +15 per circuit built |
| Phone Phreak | `phreaking` | Phone system manipulation, war dialing | +5 per successful dial, +10 per PBX hack, +15 per blue box use |
| Moxie | `social_engineering` | Talking your way in/out, reading people | +3 per new NPC conversation, +10 per successful bluff, +15 per con pulled off |

**Derived stats:**
- **Hacker Level** = weighted average of all skills, displayed as a rank name
- Ranks: `Script Kiddie` (0–15) → `Novice` (16–30) → `Hacker` (31–50) → `Elite` (51–70) → `Guru` (71–90) → `Legend` (91–100)
- **Rep** (reputation) — modifies NPC reactions, based on Moxie + quest flags

Progression is still **doing real things**: the XP system is a thin layer on top of the existing keyboard/hardware/overworld loops. You don't grind — you just get better by actually performing.

**Progression loop:**
1. Overworld exploration → find a clue (phone number, address, floppy disk, discarded manual)
2. Social engineering → bluff your way past a receptionist or pose as a contractor to get more info
3. Keyboard Time → crack the clue (dial the number, read the disk, decode the file, war dial a range)
4. Discover a hardware need → Hands On puzzle → build a tool (cable, blue box, serial adapter, scanner)
5. Use the tool + all gathered intel → penetrate the target system → extract data, loot, or access codes
6. Repeat

**Milestones (example):**

| Year | Keyboard Time Goal | Hardware Goal | Overworld Goal |
|------|-------------------|---------------|----------------|
| 1985 | Write first BASIC program | Identify resistor color codes | Explore neighborhood, meet NPCs |
| 1986 | Learn POKE/PEEK, SYS | Solder a simple circuit | Break into school computer lab |
| 1987 | Master assembler, build a demo | Build a serial cable | Find the BBS node number |
| 1988 | GPU programming, create a crack intro | Program an EPROM | Join a hacker crew, meet at arcade |
| 1989 | Cross-CPU development (6502→Z80) | Build a blue box | War dial the phone company |
| 1990 | Write a terminal emulator | Tap a 66 block | Access the CO (central office) |
| 1991 | Write a scanner control program in BASIC | Capture ESN/MIN pairs, clone a bag phone | Meet the phreaker crew at the electronics flea market |
| 1992 | Automate login scripts | Crack a default password on a legacy terminal server | Social-engineer into water reclamation plant |
| 1993 | Write a war dialer in BASIC | Build a modem snooper (LED gaggle) | Social-engineer into the OmniStor sales system |
| 1995 | Internet: TCP/IP basics | Build a dial-up modem from parts | Leave the city, go online |

### 3.2 Money & Allowance

- Start: **$3.25** in pocket
- **Allowance:** $5/week from parents (paid Monday morning when you sleep)
- Condition: garbage taken out + room clean (both tracked as daily chores)
- If chores not done → no allowance that week + parent NPC gripes at you
- Earn extra cash: odd jobs (ChipMart stock room, arcade repair), selling scavenged parts, BBS bounties later

**Chore system:**
| Chore | How to complete | Resets |
|-------|----------------|--------|
| Take out garbage | Interact with kitchen trash can (house_map) | Each morning |
| Clean room | Interact with bed (separate from sleeping — "Tidy up" option) | Each morning |

Both chores reset at midnight (game time). If both are `true` when you sleep through Sunday night, parents give you $5 on Monday morning. If either is incomplete, no allowance + parent dialogue.

### 3.3 Family & NPCs

You are **Alex**, a 13-year-old kid whose dad is **Colonel Robert "Bob" Mitchell**, an officer stationed at **Fort Stirling** — a war college and military installation on the edge of town. The family lives off-base in the subdivision (the player's house).

**Dad (Colonel Bob Mitchell, age 42)**
- Career military, currently at the Army War College for a 2-year posting
- Proud of his service but rarely talks about specifics
- Uneasy about computers — "they're good for job skills, right?" — but tolerates your interest because he thinks it means you'll get a "real job"
- Periodically brings home "surplus" from the base: old printers, character terminals, one time a whole crate of 5.25" floppies
- Key dialogue: encourages you, doesn't understand what you're doing, occasionally drops useful intel ("one of the sergeants says they're putting in a new computer system over at the base")
- **Gives allowance** (enforces chore requirements)

**Mom (Linda Mitchell, age 39)**
- Works part-time at the school district office
- The organized one — if your room isn't clean, she notices
- Less comfortable with technology than Dad, but she's the one who drives you to ChipMart when you need parts
- Key dialogue: warm but practical. "That's nice, honey" when you explain what you built, genuinely impressed when it works
- Worries about you spending too much time in your room
- **Checks chores** — if room isn't clean, you hear about it

**Sister (Jessica, age 15)**
- The opposite of you in every way — she's into cheerleading, makeup, and the phone (the social kind, not the phreaking kind)
- Thinks computers are "nerd stuff" but is surprisingly good at remembering phone numbers
- Key dialogue: dismissive one-liners, but occasionally useful — she overhears conversations at school you'd never catch, and she knows everyone's phone number
- Will give you useful intel if you help her with something first (side quest hook)
- Playful rivalry energy, not mean — she's protective of her little brother even if she won't admit it

**Family dynamics drive the chores/allowance system:**
- Dad gives allowance Monday morning (escapable chore loop)
- Mom checks room cleanliness (you can fake it with a quick "Tidy up" before bed)
- Jessica hogs the family phone line in the evening (why you need your own modem)
- Dad occasionally brings home surplus hardware (quest reward / item source)

**Military base (Fort Stirling) — story context:**
- Located just outside town; the family lives off-base in the subdivision
- The base is a major employer in town — many NPCs have connections to it
- Dad's work means the family moves every few years; this posting is temporary
- The base has its own phone system (PBX), computer networks, and restricted areas
- **Not currently accessible** as a map location (Chapter 2+), but referenced in NPC dialogue
- NPCs mention the base casually: the librarian's husband works there, the auto shop owner fixes military vehicles, the burger joint delivers to the gates
- Future: the base becomes a major target for late-game phreaking and social engineering

### 3.4 NPC Visibility & Quest Gating

NPCs can be gated by quest flags:

| NPC | Visibility | Gating |
|-----|-----------|--------|
| Dad | House (kitchen/living room) | Always present, schedule-based position |
| Mom | House (kitchen/office) | Always present, schedule-based position |
| Jessica | House (hallway/her room) or town | Always present, moves on schedule |
| Mike | Town (near your house) | Always visible, sets `met_mike` |
| Librarian | Town (Library) | Only appears after `met_mike` |
| Clerk | Town (ChipMart) | Always visible, extra dialogue after `got_manual` |
| Girl | Town (Phone Co area) | Always visible, extra dialogue after `met_mike` |
| Old Man | Town (bench near Barber Shop) | Always visible |

When an NPC has `quest_req` set and the flag isn't yet true, the NPC should not be placed on the map. Currently this is partially working — the dialogue filters lines by `require_flag`, but the NPC is still physically present with potentially empty dialogue. Needs fix: gate NPC spawn on `quest_req` OR show NPC with a "…" float icon when they have nothing to say yet.

---

## 4. Narrative Themes

- **The Phone System is a Computer** — The 2600 Hz revelation. The entire game flows from this moment.
- **Information wants to be free** — Early internet idealism, BBS culture, the hacker ethic (Steven Levy's five tenets woven into dialogue).
- **Paranoia is a feature, not a bug** — The FBI is real. Payphones are not safe. Your BBS posts are logged. The game doesn't hide this.
- **Competence is the only status** — You are not a "1337 hax0r" because you say you are. You earn respect by understanding how a NAND gate works.
- **Social engineering is the oldest exploit** — The receptionist doesn't know the modem pool numbers, but Bob from IT does. A confident voice and a plausible story will get you further than a stack of exploit code. The phone is a vector, but so is the human holding it.
- **The world is made of systems** — Traffic lights, vending machines, ATMs, PBXes, voicemail boxes, credit card terminals. Every system is a puzzle.
- **Cellular is just radio with billing** — An analog phone is a radio transmitter. The ESN/MIN are just numbers in a database. If you can read the numbers, you can claim that minute of airtime.

---

## 5. Inventory & Items

Inspirations: Earth Bound's inventory screen, but themed for a teenage hacker.

**Key items:**
- **Floppy disks** (5.25" and 3.5" variants) containing programs, data, and secrets
- **Blue box** (2600 Hz tone dialer) — built via Hands On puzzle, used on payphones
- **Soldering iron + solder** — required for hardware puzzles
- **Multimeter** — required to debug circuits
- **Logic probe** — advanced debugging tool
- **EPROM eraser** (UV light box) — required to reprogram chips
- **Blank EPROMs** — write your own 6502 code to physical chips
- **Serial cable** (null modem, various pinouts) — connect two machines
- **Modem** (300, 1200, 2400 baud variants found/upgraded) — connect to BBSes
- **Phone tap** (inductive coil) — listen in on analog lines
- **Walkie talkies** — communicate with nearby hacker friends
- **Notebook** (physical) — auto-logged clues, passwords, phone numbers found in game
- **Zines** (2600, Phrack, Cult of the Dead Cow) — found items containing lore, tips, and phone numbers
- **Bus pass** — required to reach remote parts of the city
- **Fake ID** — required to buy alcohol for social engineering or to access adult locations
- **Bag phone** (transportable analog cellular phone) — useless until cloned, then makes free calls
- **Radio scanner** — captures ESN/MIN pairs from analog cellular traffic when near active phones
- **Programming cable + software** — writes captured ESN/MIN to a blank bag phone via serial port

---

## 6. Art & Audio

### Art Direction
- **Overworld:** 16×16 tile grid, 16×24 character sprites, 4-color-per-tile SNES constraints (for authenticity), 256×224 internal resolution upscaled 3× to 768×672
- **Hands On puzzles:** Zoomed-in 2× to 4× view of circuit boards / phone blocks / component trays, same pixel art style, detailed enough to read resistor bands and IC part numbers
- **Keyboard Time:** The existing terminal UI, but re-skinned per location (green phosphor for the old terminal, amber for the Omni PC, white-on-blue for the school Scholar)
- **GUI:** Earth Bound–style menu windows (cream parchment borders, blue gradient backgrounds, serif font for dialogue)

### Audio Direction
- **Overworld:** Earth Bound–inspired chiptune soundtrack. Each area has a looping theme. Time of day changes instrumentation (day = bright NES-ish, night = moody filtered). Composers to study: Keiichi Suzuki, Hirokazu Tanaka.
- **Hands On:** Minimal ambient — the hum of a soldering iron, the beep of a multimeter, the whir of a floppy drive. Puzzle solved plays a rising arpeggio.
- **Keyboard Time:** The existing SoundManager sounds (key clicks, bell, line feed, error buzz) plus new ones: floppy seek noise when SAVE/LOAD, modem handshake when dialing a BBS.
- **Phone sounds:** Real DTMF tones generated procedurally. Busy signal, dial tone, ringing, modem handshake (the full 110/300/1200/2400 baud sequence).

---

## 7. Technical Architecture

### Codebase Strategy
The existing teaching lab (`scripts/`, `tests/`, `trainer/`) becomes **one subsystem** of the larger game:

```
/Users/handy/projects/mygodot/
  ├── GDD.md                    ← This file
  ├── backlog.md                ← Updated with game epics
  ├── PLAN.md                   ← Updated roadmap
  ├── scripts/                  ← Keyboard Time (existing)
  │   ├── terminal.gd
  │   ├── computer.gd
  │   ├── gpu_device.gd
  │   ├── cart_trainer.gd
  │   └── ...
  ├── overworld/                ← Adventure mode (new)
  │   ├── world.gd
  │   ├── player.gd
  │   ├── npc.gd
  │   ├── maps/
  │   ├── items/
  │   └── dialogue/
  ├── hardware/                 ← Hands On puzzles (new)
  │   ├── puzzle_manager.gd
  │   ├── circuits/
  │   ├── tools/
  │   └── schematics/
  ├── audio/
  │   ├── soundtrack/
  │   └── sfx/
  ├── tests/                    ← Tests for all three modes
  └── docs/
      └── phonelosers.txt        ← In-game zine content?
```

### Integration Points
The three modes communicate through a shared **player state** system:

```gdscript
# player_state.gd
var skills: Dictionary = {
    "basic_programming": 0.0,   # Code Fu (0-100)
    "assembly": 0.0,            # Hex Sense (0-100)
    "electronics": 0.0,         # Solder Finger (0-100)
    "phreaking": 0.0,           # Phone Phreak (0-100)
    "social_engineering": 0.0,  # Moxie (0-100)
}
var inventory: Array[Dictionary] = []
var phone_contacts: Dictionary = {}  # name → number
var bbs_accounts: Dictionary = {}    # bbs_name → {user, pass, messages}
var floppy_disks: Dictionary = {}    # label → data (from Keyboard Time)
var quest_flags: Dictionary = {}
var cash: float = 3.25               # money in pocket ($)
var day_count: int = 0               # total days elapsed
var garbage_taken_out: bool = false  # daily chore
var room_clean: bool = false         # daily chore
var allowance_collected: bool = false # per-week flag
var current_objective: String = ""   # shown on HUD quest tracker

- Keyboard Time quiz completion → unlocks overworld dialogue options
- Hands On puzzle completion → grants items used in overworld
- Overworld exploration → reveals floppy disks / phone numbers used in Keyboard Time

### Rendering Strategy
- Overworld and Hands On modes use Godot's native 2D rendering with sub-pixel precision
- Keyboard Time uses the existing terminal UI with TextureRect GPU overlay
- CRT shader is reused as a full-screen option for atmosphere
- Both pixel-art modes target 320×180 internal resolution with integer 3× upscale to 960×540
- The 960×720 project resolution is maintained; pixel art is centered-black-bar or `2d` viewport

---

## 8. Development Phases

### Phase A — GDD & Restructure (current)
- Write this GDD
- Update backlog.md and PLAN.md
- Restructure repo directories for three modes
- No code changes

### Phase B — Keyboard Time Complete (v1.0)
The existing teaching lab is v1.0. Finish remaining features:
- Phase 7: Cross-CPU communication
- Phase 8: Synthetic teaching CPU
- Trainer P2+: ASM lessons, CODE TRACE, capstone
- GPU Phase 9c: tile maps, sprites
- Phase 10: 8080/Z80/8086 CPUs
- Hardware Manager GUI

### Phase C — Overworld Prototype
- Build the world map (one neighborhood block)
- Player movement, collision, NPC dialogue
- Day/night cycle
- One full quest chain: find phone number → Keyboard Time → dial BBS → get clue → overworld payoff

### Phase D — Hands On Prototype
- Circuit puzzle framework
- 3 starter puzzles: resistor ID, LED blinker, multimeter usage
- Tool/item system integration

### Phase E — Integration & Polish
- Connect all three modes through player state
- Full soundtrack
- Full script / dialogue tree
- Testing across all modes

---

## 9. Influences & References

| Influence | What we take |
|-----------|-------------|
| **Earth Bound (Mother 2)** | Art style, tone, UI, open-endedness, humor, phone calls, quirky NPCs |
| **Uplink** | Hacking-as-puzzle, real skills rewarded, the feel of being a digital ghost |
| **Hacknet** | Terminal UI as game UI, command-line storytelling |
| **TIS-100 / Shenzhen I/O** | Real programming puzzles disguised as a game |
| **Pony Island** | Meta-commentary on the player-computer relationship |
| **The Messenger** | Time-jump storytelling, pixel art evolution |
| **2600: The Hacker Quarterly** | Primary source for period-accurate hacker culture, ads, lore |
| **Steven Levy's "Hackers"** | Philosophical foundation — the hacker ethic |
| **Clifford Stoll's "The Cuckoo's Egg"** | The real story of a 1980s hacker hunt — source for FBI/LBNL plot threads |
| **The movie "Hackers" (1995)** | Visual aesthetic, fashion, the "hacker as folk hero" angle (used ironically but lovingly) |
| **The movie "Sneakers" (1992)** | Social engineering, hardware hacking, team dynamics |
| **BBS: The Documentary (Jason Scott)** | Documentary reference for period-accurate BBS culture, hardware, and terminology |

---

## 10. Fictional Brands & Product Lines

All in-world brands are fictional alternatives to real companies, avoiding trademark issues while keeping the period-authentic feel.

### Home Computers & Terminals
- **Vector 64** — Bedroom computer, acquired at a garage sale in 1985. Your first machine.
- **Scholar II** — School computer lab machine. White-on-blue monochrome monitor.
- **Lab-80** — Library public terminal. Green phosphor display.
- **Omni PC** — Workbench computer at the electronics shop. Amber monitor. Used for serious work.

### Workstations (Unix Era)
- **Sol Microsystems** — Unix workstation manufacturer (Sun alternative). Models: Sol SLC, Sol IPC. Runs **Solix OS** (System V derivative).
- **Digital Research Corp (DRC)** — Workstation manufacturer (DEC alternative). Models: DRC V3X, DRC AlphaForce. Runs **DRC/UX**.
- **Crystal Engine** — Graphics workstation manufacturer (SGI alternative). Models: Crystal Iris, Crystal Onyx. Runs **CrystalIX**.

### PC Brands
- **Continental Business Machines (CBM)** — PC/AT clone maker (IBM alternative). Model: CBM Personal System.
- **CompactPro** — Portable PC maker (Compaq alternative). Models: CompactPro 386, CompactPro 486.
- **DirectWay** — Mail-order PC maker (Dell/Gateway alternative). Models: DirectWay 486, DirectWay Pentium.

### Apple / Macintosh Alternative
- **Apricot Computers** — Graphical personal computer maker (Apple alternative). Models: Apricot Prima, Apricot PowerBook. Runs **Prima OS**.

### Operating Systems
- **CommandOS** — Command-line OS for CBM and CompactPro PCs (DOS alternative).
- **Panels** — Graphical OS for CBM and DirectWay PCs (Windows alternative). Versions: Panels 1.0 (1990), Panels 3.0 (1992), Panels 95 (1995).
- **Solix OS** — Unix from Sol Microsystems.
- **DRC/UX** — Unix from Digital Research Corp.
- **CrystalIX** — Unix from Crystal Engine.

### Retail & Manufacturing
- **ChipMart** — Electronics parts store. Dumpster out back is a key early-game resource.
- **OmniStor Technologies** — Storage peripheral manufacturer. Mid-game target.

---

## 11. Monetization & Distribution

- **v1.0 (Keyboard Time only):** Free / open-source (MIT). The teaching lab is a standalone educational tool.
- **Full game (all three modes):** Paid ($15-20) on Steam / Itch.io. Open-source codebase; art assets are proprietary.
- **Demo:** First chapter (1985) free. Covers the neighborhood, BASIC programming, and one hardware puzzle.

---

*Document version: 0.5 — XP/stats system, money/chores, family NPCs, military base, expanded town (100×82), sidewalks, fire/police/hospital, TileMap→TileMapLayer migration*
*Created: 2026-05-16*
*Updated: 2026-05-18*

extends Node

enum Tile {
	GRASS = 0,
	PATH = 1,
	WALL_BROWN = 2,
	WALL_BEIGE = 3,
	WALL_GRAY = 4,
	ROOF_RED = 5,
	ROOF_GRAY = 6,
	DOOR = 7,
	WATER = 8,
	FENCE = 9,
	TREE = 10,
	SIGN = 11,
	BLANK = 12,
	SIDEWALK = 13,
}

const TILE_SIZE := 32
const TILE_TYPES := 14

const INTERACTIVE_FURNITURE := ["desk", "bed", "garbage_can", "garbage_bin", "phone"]

const FURNITURE_COLORS := {
	"desk": Color(0.45, 0.28, 0.12),
	"chair": Color(0.35, 0.2, 0.1),
	"bed": Color(0.0, 0.281, 0.716, 1.0),
	"table": Color(0.5, 0.35, 0.18),
	"stove": Color(0.3, 0.3, 0.35),
	"fridge": Color(0.85, 0.85, 0.9),
	"toilet": Color(0.95, 0.95, 0.95),
	"bathtub": Color(0.9, 0.9, 0.95),
	"shelf": Color(0.55, 0.38, 0.2),
	"workbench": Color(0.5, 0.45, 0.35),
	"tv": Color(0.15, 0.15, 0.15),
	"couch": Color(0.4, 0.55, 0.35),
	"garbage_can": Color(0.35, 0.35, 0.35),
	"garbage_bin": Color(0.45, 0.45, 0.45),
	"phone": Color(0.15, 0.15, 0.2),
	"counter": Color(0.5, 0.35, 0.18),
	"reception": Color(0.6, 0.5, 0.3),
	"bench": Color(0.45, 0.35, 0.2),
	"stanchion": Color(0.3, 0.3, 0.8),
	"vault": Color(0.5, 0.5, 0.55),
	"teller_window": Color(0.7, 0.65, 0.5),
	"transformer": Color(0.3, 0.4, 0.3),
	"controls": Color(0.4, 0.4, 0.45),
	"pipe": Color(0.4, 0.5, 0.6),
	"railing": Color(0.6, 0.6, 0.6),
}

const NPC_INTERACTION_RANGE := 2.0
const NIGHT_OVERLAY_ALPHA := 0.55
const NIGHT_OVERLAY_TINT := Color(0, 0, 0.15)
const DIALOGUE_SPEED := 30.0
const TRANSITION_COOLDOWN := 0.3
const BED_COOLDOWN := 0.5
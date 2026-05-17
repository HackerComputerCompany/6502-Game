extends Node

# Ranch house with garage + workshop on west side, 4 bedrooms, hallway,
# bathroom, living room, kitchen. Player starts in "your room" (bedroom 1).
#
# Layout (48 wide × 21 tall):
#   x=0-10:  Garage/Workshop (west side, garage doors face south)
#   x=11:     Garage/house divider wall (full height)
#   x=12-19:  Bedroom 1 (Your Room)
#   x=20:     Wall divider
#   x=21-28:  Bedroom 2
#   x=29:     Wall divider
#   x=30-37:  Bedroom 3
#   x=38:     Wall divider
#   x=39-46:  Bedroom 4
#   x=47:     East outer wall
#
# Row layout:
#   0:    North outer wall
#   1-5:  Workshop (left), Bedrooms
#   6:    Workshop divider wall (garage side), bedrooms continue
#   7-8:  Garage parking (left), bedrooms continue
#   9:    Bedroom bottom walls + doors
#   10:   Hallway (open, full width)
#   11:   Top walls (bathroom, living room, kitchen doors)
#   12-19: Interior (bathroom walled, LR + kitchen open)
#   20:   South outer wall + front door

const MAP_W := 48
const MAP_H := 21

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const Tile = preload("res://overworld/town_map.gd").Tile

const ENTRY_POINTS := {
	"your_room": Vector2(16, 5),
	"front_door": Vector2(24, 19),
	"garage": Vector2(5, 8),
	"desk": [Vector2i(15, 3), Vector2i(16, 3), Vector2i(17, 3)],
	"bed": [Vector2i(16, 7), Vector2i(16, 8)],
}

const EXITS := {
	Vector2i(24, 20): {"map": "res://overworld/town_map.gd", "entry": "house_door"},
	Vector2i(25, 20): {"map": "res://overworld/town_map.gd", "entry": "house_door"},
}

var labels: Array = []

func _init() -> void:
	collision.resize(MAP_H)
	ground.resize(MAP_H)
	decorations.resize(MAP_H)
	for y in range(MAP_H):
		collision[y] = []
		ground[y] = []
		decorations[y] = []
		collision[y].resize(MAP_W)
		ground[y].resize(MAP_W)
		decorations[y].resize(MAP_W)
		for x in range(MAP_W):
			collision[y][x] = 0
			ground[y][x] = Tile.PATH
			decorations[y][x] = Tile.BLANK
	_build()

func _set_tile(x, y, tile):
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		if tile == Tile.DOOR:
			decorations[y][x] = tile
		else:
			ground[y][x] = tile

func _wall(x, y, w, h):
	for dy in range(h):
		for dx in range(w):
			var px: int = x + dx
			var py: int = y + dy
			if px >= 0 and px < MAP_W and py >= 0 and py < MAP_H:
				ground[py][px] = Tile.WALL_BEIGE
				collision[py][px] = 1

func _door(x, y):
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		collision[y][x] = 0
		ground[y][x] = Tile.PATH
		decorations[y][x] = Tile.DOOR

func _window(x, y):
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		ground[y][x] = Tile.WALL_GRAY

func _build():
	# === OUTER WALLS ===
	_wall(0, 0, MAP_W, 1)
	_wall(0, MAP_H - 1, MAP_W, 1)
	_wall(0, 0, 1, MAP_H)
	_wall(MAP_W - 1, 0, 1, MAP_H)

	# === GARAGE / HOUSE DIVIDER (x=11, full height) ===
	_wall(11, 0, 1, 10)
	_door(11, 10)
	_wall(11, 11, 1, 10)

	# === WORKSHOP DIVIDER inside garage (y=6) ===
	_wall(1, 6, 10, 1)
	_door(4, 6)

	# === BEDROOM DIVIDERS ===
	_wall(20, 0, 1, 10)
	_wall(29, 0, 1, 10)
	_wall(38, 0, 1, 10)

	# === BEDROOM BOTTOM WALL (y=9, house side only) with doors ===
	_wall(12, 9, 36, 1)
	_door(15, 9)
	_door(16, 9)
	_door(24, 9)
	_door(25, 9)
	_door(33, 9)
	_door(34, 9)
	_door(42, 9)
	_door(43, 9)

	# === NORTH WALL WINDOWS ===
	# Workshop
	_window(3, 0)
	_window(4, 0)
	_window(7, 0)
	_window(8, 0)
	# Bedroom 1 (Your Room)
	_window(14, 0)
	_window(15, 0)
	_window(17, 0)
	_window(18, 0)
	# Bedroom 2
	_window(23, 0)
	_window(24, 0)
	_window(26, 0)
	_window(27, 0)
	# Bedroom 3
	_window(31, 0)
	_window(32, 0)
	_window(35, 0)
	_window(36, 0)
	# Bedroom 4
	_window(41, 0)
	_window(42, 0)
	_window(44, 0)
	_window(45, 0)

	# === HALLWAY (y=10) — open, garage door at (11,10) ===

	# === SOUTH WALL WINDOWS (y=20) ===
	# Living room windows
	_window(20, MAP_H - 1)
	_window(21, MAP_H - 1)
	_window(27, MAP_H - 1)
	_window(28, MAP_H - 1)
	# Kitchen windows
	_window(36, MAP_H - 1)
	_window(37, MAP_H - 1)
	_window(40, MAP_H - 1)
	_window(41, MAP_H - 1)
	# Garage windows
	_window(5, MAP_H - 1)
	_window(6, MAP_H - 1)

	# === SOUTH SECTION TOP WALL (y=11) ===
	# Full wall across, then punch doors for bathroom, LR, kitchen
	_wall(12, 11, 35, 1)
	_door(14, 11)
	_door(22, 11)
	_door(23, 11)
	_door(34, 11)
	_door(35, 11)

	# === BATHROOM (x=12-16, y=11-15) ===
	_wall(12, 12, 1, 3)
	_wall(16, 12, 1, 3)
	_wall(12, 15, 5, 1)

	# === LIVING ROOM / KITCHEN DIVIDER (x=33) ===
	_wall(33, 12, 1, 8)

	# === FRONT DOOR (south wall, living room) ===
	collision[MAP_H - 1][24] = 0
	ground[MAP_H - 1][24] = Tile.PATH
	decorations[MAP_H - 1][24] = Tile.DOOR
	collision[MAP_H - 1][25] = 0
	ground[MAP_H - 1][25] = Tile.PATH
	decorations[MAP_H - 1][25] = Tile.DOOR

	# === GARAGE DOORS (south wall) — visual only ===
	ground[MAP_H - 1][2] = Tile.WALL_GRAY
	ground[MAP_H - 1][3] = Tile.WALL_GRAY
	ground[MAP_H - 1][7] = Tile.WALL_GRAY
	ground[MAP_H - 1][8] = Tile.WALL_GRAY

	# === DESK (Your Room, against north wall) ===
	# Desk collision: 3 wide × 2 tall
	for dx in range(3):
		for dy in range(2):
			collision[1 + dy][15 + dx] = 1

	# === BED (Your Room, bottom-right corner) ===
	# Bed collision: 2 wide × 2 tall
	for dx in range(2):
		for dy in range(2):
			collision[7 + dy][17 + dx] = 1

	# === ROOM LABELS ===
	labels = [
		["Workshop", 4, 3],
		["Garage", 5, 8],
		["Your Room", 14, 4],
		["Bedroom", 23, 4],
		["Bedroom", 32, 4],
		["Bedroom", 41, 4],
		["Hallway", 27, 10],
		["Bathroom", 13, 13],
		["Living Room", 24, 15],
		["Kitchen", 38, 15],
	]

func get_labels() -> Array:
	return labels

func get_furniture() -> Array:
	return [
		["desk", 15, 1, 3, true, 3, 2],
		["bed", 17, 7, 2, true, 2, 2],
	]

func is_passable(x, y):
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return false
	if decorations[y][x] == Tile.DOOR:
		return true
	return collision[y][x] == 0

func get_ground(x, y):
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return Tile.PATH
	return ground[y][x]

func get_decoration(x, y):
	if x < 0 or y < 0 or x >= MAP_W or y >= MAP_H:
		return Tile.BLANK
	return decorations[y][x]
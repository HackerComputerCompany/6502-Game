extends Node

# Ranch house with garage + workshop on west side, 4 bedrooms, hallway,
# bathroom, living room. Kitchen is next to garage on west side.
# Workshop has a north exit to the backyard.
#
# Layout (48 wide x 21 tall):
#   x=0-10:  Workshop (top) / Garage (mid) / Kitchen (bottom)
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
#   0:    North outer wall + workshop exit door
#   1-5:  Workshop (left), Bedrooms
#   6:    Workshop divider wall (garage side), bedrooms continue
#   7-8:  Garage parking (left), bedrooms continue
#   9:    Bedroom bottom walls + doors + kitchen top wall + door
#   10:   Hallway (open, full width)
#   11:   Top walls (kitchen, bathroom, living room doors)
#   12-19: Kitchen (left), Bathroom (walled), Living Room
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
	"workshop_exit": Vector2(5, 1),
	"desk": [Vector2i(15, 3), Vector2i(16, 3), Vector2i(17, 3)],
	"bed": [Vector2i(16, 7), Vector2i(16, 8)],
	"garbage_can": Vector2i(3, 16),
	"phone_kitchen": Vector2i(8, 16),
	"phone_living": Vector2i(25, 17),
}

const EXITS := {
	Vector2i(24, 20): {"map": "res://overworld/town_map.gd", "entry": "house_door"},
	Vector2i(25, 20): {"map": "res://overworld/town_map.gd", "entry": "house_door"},
	Vector2i(5, 0): {"map": "res://overworld/town_map.gd", "entry": "workshop_exit"},
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

	# === WORKSHOP NORTH EXIT ===
	_door(5, 0)

	# === GARAGE / HOUSE DIVIDER (x=11, full height) ===
	_wall(11, 0, 1, 10)
	_door(11, 10)
	_wall(11, 11, 1, 10)

	# === WORKSHOP DIVIDER inside garage (y=6) ===
	_wall(1, 6, 10, 1)
	_door(4, 6)
	# === GARAGE DOOR to kitchen (y=9) ===
	_wall(1, 9, 10, 1)
	_door(5, 9)

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
	_window(36, MAP_H - 1)
	_window(37, MAP_H - 1)
	# Kitchen windows (west side)
	_window(1, MAP_H - 1)
	_window(2, MAP_H - 1)
	_window(5, MAP_H - 1)
	_window(6, MAP_H - 1)

	# === KITCHEN TOP WALL (y=11, x=1-10) ===
	_wall(1, 11, 3, 1)
	_door(4, 11)
	_wall(5, 11, 6, 1)

	# === SOUTH SECTION TOP WALL (y=11, house side) ===
	_wall(12, 11, 35, 1)
	_door(14, 11)
	_door(22, 11)
	_door(23, 11)

	# === BATHROOM (x=12-16, y=11-15) ===
	_wall(12, 12, 1, 3)
	_wall(16, 12, 1, 3)
	_wall(12, 15, 5, 1)

	# === KITCHEN FURNITURE ===
	# Stove (west wall, y=13)
	collision[12][1] = 1
	collision[12][2] = 1
	# Fridge (west wall, y=14)
	collision[14][1] = 1
	# Counter (south wall)
	for dx in range(5):
		collision[18][1 + dx] = 1
	# Sink (east wall near divider)
	collision[13][9] = 1
	collision[14][9] = 1
	collision[15][9] = 1

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
	for dx in range(3):
		for dy in range(2):
			collision[1 + dy][15 + dx] = 1

	# === BED (Your Room, bottom-right corner) ===
	for dx in range(2):
		for dy in range(2):
			collision[7 + dy][17 + dx] = 1

	# === ROOM LABELS ===
	labels = [
		["Workshop", 4, 3],
		["Garage", 5, 8],
		["Kitchen", 4, 14],
		["Your Room", 14, 4],
		["Bedroom", 23, 4],
		["Bedroom", 32, 4],
		["Bedroom", 41, 4],
		["Hallway", 27, 10],
		["Bathroom", 13, 13],
		["Living Room", 28, 15],
	]

func get_labels() -> Array:
	return labels

func get_furniture() -> Array:
	return [
		["desk", 15, 1, 3, true, 3, 2],
		["bed", 17, 7, 2, true, 2, 2],
		["garbage_can", 3, 16, 0, false, 1, 1],
		["phone", 8, 16, 19, false, 1, 1],
		["phone", 25, 17, 19, false, 1, 1],
		["stove", 1, 12, 15, true, 2, 1],
		["fridge", 1, 14, 15, true, 1, 1],
		["counter", 1, 18, 18, true, 5, 1],
		["sink", 9, 13, 15, true, 1, 3],
		["couch", 20, 16, 18, true, 3, 2],
		["tv", 17, 13, 16, true, 2, 1],
		["table", 30, 15, 16, true, 2, 1],
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
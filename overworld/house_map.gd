extends Node

## Legacy script-authored map. Runtime uses res://overworld/maps/house.tscn.
## Kept for overworld/tools/build_maps.gd regeneration.
##
## Single-story ranch (street = south):
##   West: workshop (north) + garage + kitchen
##   North wing: your bedroom, bathroom, parents' room, guest room
##   Center: hallway
##   South: living room (front door), kitchen continues on the west side

const MAP_W := 36
const MAP_H := 17

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const Tile = preload("res://overworld/town_map.gd").Tile

const ENTRY_POINTS := {
	"your_room": Vector2(13, 4),
	"front_door": Vector2(22, 15),
	"garage": Vector2(4, 6),
	"workshop_exit": Vector2(4, 1),
	"desk": [Vector2i(11, 3), Vector2i(12, 3), Vector2i(13, 3)],
	"bed": Vector2(12, 6),
	"bed_sleep": [Vector2i(13, 5), Vector2i(14, 5)],
	"garbage_can": Vector2i(6, 13),
	"phone_kitchen": Vector2i(7, 12),
	"phone_living": Vector2i(24, 13),
}

const EXITS := {
	Vector2i(21, 16): {"map": "res://overworld/maps/town.tscn", "entry": "house_door"},
	Vector2i(22, 16): {"map": "res://overworld/maps/town.tscn", "entry": "house_door"},
	Vector2i(4, 0): {"map": "res://overworld/maps/town.tscn", "entry": "workshop_exit"},
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
	# === OUTER SHELL ===
	_wall(0, 0, MAP_W, 1)
	_wall(0, MAP_H - 1, MAP_W, 1)
	_wall(0, 0, 1, MAP_H)
	_wall(MAP_W - 1, 0, 1, MAP_H)

	# Workshop north exit (backyard)
	_door(4, 0)

	# === WEST WING: workshop / garage / kitchen (x 1–8) ===
	# Workshop over garage (y 1–3)
	_wall(1, 4, 8, 1)
	_door(4, 4)
	# Garage (y 5–8)
	_wall(1, 9, 8, 1)
	_door(5, 9)

	# House ↔ garage/kitchen divider (x = 9)
	_wall(9, 0, 1, 9)
	_door(9, 9)
	_wall(9, 10, 1, 7)

	# === BEDROOM WING (y 1–7): your room | bath | parents | guest ===
	_wall(16, 1, 1, 8)
	_wall(23, 1, 1, 8)
	_wall(30, 1, 1, 8)

	# Bathroom (x 17–22, y 2–6)
	_wall(17, 1, 6, 1)
	_wall(17, 7, 6, 1)
	_wall(17, 2, 1, 5)
	_wall(22, 2, 1, 5)

	# Hall doors into each bedroom (y = 8)
	_wall(10, 8, 25, 1)
	_door(12, 8)
	_door(19, 8)
	_door(26, 8)
	_door(32, 8)

	# === HALLWAY (y = 8–9, open east–west) ===

	# === SOUTH LIVING / KITCHEN (y 10–15) ===
	# Kitchen north wall + door to hall
	_wall(10, 10, 7, 1)
	_door(13, 10)
	# Living room partial divider (optional nook) — open plan, one wall segment
	_wall(17, 10, 1, 6)

	# === FRONT DOOR (south, living room) ===
	_door(21, 16)
	_door(22, 16)

	# === WINDOWS ===
	# Workshop (north)
	for wx in [2, 3, 6, 7]:
		_window(wx, 0)
	# Bedrooms (north facade)
	for wx in [12, 13, 21, 22, 28, 29]:
		_window(wx, 0)
	# Living room (south)
	for wx in [19, 20, 25, 26]:
		_window(wx, MAP_H - 1)
	# Kitchen (south-west)
	for wx in [2, 3, 6, 7]:
		_window(wx, MAP_H - 1)
	# Garage doors (south wall, visual)
	ground[MAP_H - 1][2] = Tile.WALL_GRAY
	ground[MAP_H - 1][3] = Tile.WALL_GRAY
	ground[MAP_H - 1][6] = Tile.WALL_GRAY
	ground[MAP_H - 1][7] = Tile.WALL_GRAY

	# === COLLISION: kitchen built-ins ===
	collision[12][11] = 1
	collision[12][12] = 1
	collision[14][11] = 1
	for dx in range(5):
		collision[15][11 + dx] = 1
	collision[13][16] = 1
	collision[14][16] = 1
	collision[15][16] = 1

	# Desk (north wall) + bed (your room)
	for dx in range(3):
		for dy in range(2):
			collision[1 + dy][11 + dx] = 1
	for dx in range(2):
		for dy in range(2):
			collision[5 + dy][13 + dx] = 1

	# === LABELS ===
	labels = [
		["Workshop", 4, 2],
		["Garage", 4, 6],
		["Kitchen", 4, 12],
		["Your Room", 12, 4],
		["Bathroom", 19, 3],
		["Parents' Room", 26, 4],
		["Guest Room", 32, 4],
		["Hallway", 18, 8],
		["Living Room", 24, 12],
	]

func get_labels() -> Array:
	return labels

func get_furniture() -> Array:
	return [
		["desk", 11, 1, 3, true, 3, 2],
		["bed", 13, 5, 2, true, 2, 2],
		["garbage_can", 6, 13, 0, false, 1, 1],
		["phone", 7, 12, 19, false, 1, 1],
		["phone", 24, 13, 19, false, 1, 1],
		["stove", 11, 11, 15, true, 2, 1],
		["fridge", 11, 13, 15, true, 1, 1],
		["counter", 11, 15, 18, true, 5, 1],
		["sink", 16, 12, 15, true, 1, 3],
		["couch", 20, 13, 18, true, 3, 2],
		["tv", 18, 11, 16, true, 2, 1],
		["table", 26, 12, 16, true, 2, 1],
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

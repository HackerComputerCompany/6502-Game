extends Node

# Rich Kid House (14 wide x 12 tall)
# Fancy house with foyer, living room, study, kitchen

const MAP_W := 14
const MAP_H := 12

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const Tile = preload("res://overworld/town_map.gd").Tile

const ENTRY_POINTS := {
	"front_door": Vector2(6, 10),
}

const EXITS := {
	Vector2i(6, 11): {"map": "res://overworld/town_map.gd", "entry": "rich_kid_door"},
	Vector2i(7, 11): {"map": "res://overworld/town_map.gd", "entry": "rich_kid_door"},
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

func _build() -> void:
	_walls_around()
	# Foyer / Living Room divider
	_wall(5, 0, 1, 6, Tile.WALL_BEIGE)
	_door(5, 3)
	# Kitchen divider
	_wall(9, 0, 1, 6, Tile.WALL_BEIGE)
	_door(9, 4)
	# Study divider walls in back
	_wall(5, 6, 1, 5, Tile.WALL_BEIGE)
	_door(5, 8)
	_wall(9, 6, 1, 5, Tile.WALL_BEIGE)
	_door(9, 8)
	# Windows
	_window(1, 0)
	_window(3, 0)
	_window(7, 0)
	_window(11, 0)
	_window(13, 3)
	_window(0, 4)
	_window(13, 7)
	# Foyer furniture
	_furniture_block(1, 1, 1, 1)
	_furniture_block(3, 1, 1, 1)
	# Living Room - tv, couch, bookshelf
	_furniture_block(6, 1, 3, 1)
	_furniture_block(6, 4, 2, 1)
	_furniture_block(8, 4, 1, 1)
	_furniture_block(6, 5, 1, 1)
	# Kitchen - counter, dining table
	_furniture_block(10, 1, 3, 1)
	_furniture_block(12, 3, 1, 1)
	_furniture_block(10, 4, 2, 1)
	# Study - desk, bookshelf
	_furniture_block(6, 7, 2, 1)
	_furniture_block(1, 7, 3, 1)
	_furniture_block(1, 9, 2, 1)
	# Kitchen back area
	_furniture_block(10, 7, 3, 1)
	# Front doors
	_door(6, 11)
	_door(7, 11)
	labels = [
		["Foyer", 2, 2],
		["Living Room", 6, 2],
		["Kitchen", 10, 2],
		["Study", 2, 7],
	]

func _walls_around() -> void:
	for x in range(MAP_W):
		ground[0][x] = Tile.WALL_BEIGE
		collision[0][x] = 1
		ground[MAP_H - 1][x] = Tile.WALL_BEIGE
		collision[MAP_H - 1][x] = 1
	for y in range(MAP_H):
		ground[y][0] = Tile.WALL_BEIGE
		collision[y][0] = 1
		ground[y][MAP_W - 1] = Tile.WALL_BEIGE
		collision[y][MAP_W - 1] = 1

func _wall(x: int, y: int, w: int, h: int, wall_type: int = Tile.WALL_BEIGE) -> void:
	for dy in range(h):
		for dx in range(w):
			var px: int = x + dx
			var py: int = y + dy
			if px >= 0 and px < MAP_W and py >= 0 and py < MAP_H:
				ground[py][px] = wall_type
				collision[py][px] = 1

func _door(x: int, y: int) -> void:
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		collision[y][x] = 0
		ground[y][x] = Tile.PATH
		decorations[y][x] = Tile.DOOR

func _window(x: int, y: int) -> void:
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		ground[y][x] = Tile.WALL_BEIGE

func _furniture_block(x: int, y: int, w: int = 1, h: int = 1) -> void:
	for dy in range(h):
		for dx in range(w):
			var px: int = x + dx
			var py: int = y + dy
			if px >= 0 and px < MAP_W and py >= 0 and py < MAP_H:
				collision[py][px] = 1

func is_passable(x: int, y: int) -> bool:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return false
	if decorations[y][x] == Tile.DOOR:
		return true
	return collision[y][x] == 0

func get_ground(x: int, y: int) -> int:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return Tile.PATH
	return ground[y][x]

func get_decoration(x: int, y: int) -> int:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return Tile.BLANK
	return decorations[y][x]

func get_labels() -> Array:
	return labels

func get_furniture() -> Array:
	return [
		["coat_rack", 1, 1, 4, false, 1, 1],
		["plant", 3, 1, 4, false, 1, 1],
		["tv", 6, 1, 5, true, 3, 1],
		["couch", 6, 4, 4, true, 2, 1],
		["side_table", 8, 4, 4, false, 1, 1],
		["bookshelf", 6, 5, 4, true, 1, 1],
		["counter", 10, 1, 5, true, 3, 1],
		["fridge", 12, 3, 4, false, 1, 1],
		["dining_table", 10, 4, 4, false, 2, 1],
		["desk", 6, 7, 4, true, 2, 1],
		["bookshelf", 1, 7, 4, true, 3, 1],
		["table", 1, 9, 4, false, 2, 1],
		["shelf", 10, 7, 5, true, 3, 1],
	]

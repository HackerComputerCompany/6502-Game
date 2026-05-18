extends Node

# Library (8 wide x 8 tall)
# Wall shelves along north and west walls, reading tables, desk near door

const MAP_W := 8
const MAP_H := 8

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const Tile = preload("res://overworld/town_map.gd").Tile

const ENTRY_POINTS := {
	"front_door": Vector2(4, 7),
}

const EXITS := {
	Vector2i(4, 7): {"map": "res://overworld/town_map.gd", "entry": "library_door"},
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
	_window(2, 0)
	_window(5, 0)
	_window(7, 3)
	# North wall shelves
	_furniture_block(1, 1, 6, 1)
	# West wall shelves
	_furniture_block(1, 2, 1, 4)
	# Reading tables in center
	_furniture_block(3, 3, 2, 1)
	_furniture_block(3, 5, 2, 1)
	# Desk near door
	_furniture_block(5, 6, 2, 1)
	# Front door
	_door(4, 7)
	labels = [
		["Library", 2, 0],
		["Shelves", 1, 1],
		["Reading", 3, 3],
		["Desk", 5, 6],
	]

func _walls_around() -> void:
	for x in range(MAP_W):
		ground[0][x] = Tile.WALL_BROWN
		collision[0][x] = 1
		ground[MAP_H - 1][x] = Tile.WALL_BROWN
		collision[MAP_H - 1][x] = 1
	for y in range(MAP_H):
		ground[y][0] = Tile.WALL_BROWN
		collision[y][0] = 1
		ground[y][MAP_W - 1] = Tile.WALL_BROWN
		collision[y][MAP_W - 1] = 1

func _wall(x: int, y: int, w: int, h: int, wall_type: int = Tile.WALL_GRAY) -> void:
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
		ground[y][x] = Tile.WALL_BROWN

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
		["shelf", 1, 2, 4, false, 1, 4],
		["shelf", 1, 1, 4, true, 6, 1],
		["table", 3, 3, 2, false, 2, 1],
		["table", 3, 5, 2, false, 2, 1],
		["desk", 5, 6, 3, false, 2, 1],
	]

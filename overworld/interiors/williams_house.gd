extends Node

# Williams House (12 wide x 10 tall)
# Medium house with 2 rooms and hallway

const MAP_W := 12
const MAP_H := 10

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const Tile = preload("res://overworld/town_map.gd").Tile

const ENTRY_POINTS := {
	"front_door": Vector2(5, 8),
}

const EXITS := {
	Vector2i(5, 9): {"map": "res://overworld/town_map.gd", "entry": "williams_door"},
	Vector2i(6, 9): {"map": "res://overworld/town_map.gd", "entry": "williams_door"},
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
	_window(6, 0)
	_window(10, 0)
	_window(0, 4)
	_window(11, 4)
	_wall(4, 0, 1, 4, Tile.WALL_BEIGE)
	_door(4, 3)
	_wall(8, 0, 1, 4, Tile.WALL_BEIGE)
	_door(8, 3)
	_furniture_block(1, 1, 2, 1)
	_furniture_block(2, 3, 1, 1)
	_furniture_block(6, 1, 1, 2)
	_furniture_block(9, 1, 2, 1)
	_furniture_block(10, 3, 1, 2)
	_furniture_block(1, 5, 3, 1)
	_furniture_block(8, 6, 2, 1)
	_door(5, 9)
	_door(6, 9)
	labels = [
		["Williams House", 4, 0],
		["Living Room", 1, 2],
		["Kitchen", 9, 2],
		["Hallway", 5, 7],
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
		["sofa", 1, 1, 2, false, 2, 1],
		["coffee_table", 2, 3, 4, false, 1, 1],
		["hall_cabinet", 6, 1, 2, true, 1, 2],
		["kitchen_table", 9, 1, 2, true, 2, 1],
		["counter", 10, 3, 4, true, 1, 2],
		["dining_table", 1, 5, 6, false, 3, 1],
		["armchair", 8, 6, 7, false, 2, 1],
	]

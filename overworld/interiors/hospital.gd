extends Node

# Hospital (14 wide x 12 tall)
# Reception desk, hallway, treatment rooms (walled off), emergency entrance south

const MAP_W := 14
const MAP_H := 12

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const Tile = preload("res://overworld/town_map.gd").Tile

const ENTRY_POINTS := {
	"front_door": Vector2(7, 11),
}

const EXITS := {
	Vector2i(7, 11): {"map": "res://overworld/town_map.gd", "entry": "hospital_door"},
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
	_window(13, 4)
	# Treatment room 1 (northeast)
	_wall(9, 1, 4, 4, Tile.WALL_GRAY)
	_door(9, 3)
	_furniture_block(10, 2, 2, 1)
	# Treatment room 2 (northwest)
	_wall(1, 1, 4, 4, Tile.WALL_GRAY)
	_door(4, 3)
	_furniture_block(2, 2, 2, 1)
	# Central hallway walls
	_wall(1, 6, 4, 1, Tile.WALL_GRAY)
	_door(5, 6)
	_wall(9, 6, 4, 1, Tile.WALL_GRAY)
	_door(9, 6)
	# Reception desk
	_furniture_block(5, 8, 4, 1)
	# Waiting area benches
	_furniture_block(1, 8, 2, 1)
	_furniture_block(1, 9, 2, 1)
	# West room furniture
	_furniture_block(2, 6, 2, 1)
	# East room furniture
	_furniture_block(10, 6, 2, 1)
	_door(7, 11)
	labels = [
		["Hospital", 4, 0],
		["Treatment", 2, 1],
		["Treatment", 10, 1],
		["Reception", 5, 8],
		["Waiting", 1, 8],
	]

func _walls_around() -> void:
	for x in range(MAP_W):
		ground[0][x] = Tile.WALL_GRAY
		collision[0][x] = 1
		ground[MAP_H - 1][x] = Tile.WALL_GRAY
		collision[MAP_H - 1][x] = 1
	for y in range(MAP_H):
		ground[y][0] = Tile.WALL_GRAY
		collision[y][0] = 1
		ground[y][MAP_W - 1] = Tile.WALL_GRAY
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
		ground[y][x] = Tile.WALL_GRAY

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
		["bed", 2, 2, 2, false, 2, 1],
		["bed", 10, 2, 2, true, 2, 1],
		["reception", 5, 8, 3, true, 4, 1],
		["bench", 1, 8, 4, false, 2, 1],
		["bench", 1, 9, 4, true, 2, 1],
		["desk", 2, 6, 2, false, 2, 1],
		["desk", 10, 6, 2, true, 2, 1],
	]

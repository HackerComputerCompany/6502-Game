extends Node

# Water Reclamation (16 wide x 12 tall)
# Control room with terminals, pipes along walls, office in back

const MAP_W := 16
const MAP_H := 12

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const Tile = preload("res://overworld/town_map.gd").Tile

const ENTRY_POINTS := {
	"front_door": Vector2(7, 10),
}

const EXITS := {
	Vector2i(7, 11): {"map": "res://overworld/town_map.gd", "entry": "water_recl_door"},
	Vector2i(8, 11): {"map": "res://overworld/town_map.gd", "entry": "water_recl_door"},
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
	# Office divider wall
	_wall(10, 1, 1, 5, Tile.WALL_GRAY)
	_door(10, 3)
	# Windows
	_window(2, 0)
	_window(5, 0)
	_window(8, 0)
	_window(13, 0)
	_window(15, 4)
	_window(0, 6)
	_window(0, 3)
	# Control terminals
	_furniture_block(2, 2, 3, 1)
	_furniture_block(6, 2, 3, 1)
	# Pipe blocks along walls
	_furniture_block(1, 1, 1, 5)
	_furniture_block(9, 1, 1, 5)
	# Control desk
	_furniture_block(3, 5, 4, 1)
	# Pipe blocks on south side
	_furniture_block(1, 8, 1, 2)
	_furniture_block(9, 8, 1, 2)
	# Large pipe assembly
	_furniture_block(2, 8, 3, 1)
	_furniture_block(6, 8, 3, 1)
	# Office desk and chair
	_furniture_block(12, 2, 3, 1)
	_furniture_block(12, 4, 2, 1)
	# Office filing cabinet
	_furniture_block(14, 1, 1, 1)
	# Front doors
	_door(7, 11)
	_door(8, 11)
	labels = [
		["Control Room", 3, 1],
		["Pipes", 2, 8],
		["Office", 12, 2],
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
		["terminal", 2, 2, 5, true, 3, 1],
		["terminal", 6, 2, 5, true, 3, 1],
		["pipe", 1, 1, 2, false, 1, 5],
		["pipe", 9, 1, 2, false, 1, 5],
		["control_desk", 3, 5, 4, false, 4, 1],
		["pipe", 1, 8, 3, false, 1, 2],
		["pipe", 9, 8, 3, false, 1, 2],
		["pipe_assembly", 2, 8, 4, false, 3, 1],
		["pipe_assembly", 6, 8, 4, false, 3, 1],
		["office_desk", 12, 2, 5, true, 3, 1],
		["filing_cabinet", 14, 1, 4, false, 1, 1],
		["chair", 12, 4, 4, false, 2, 1],
	]

extends Node

# Bank (9 wide x 9 tall)
# Teller windows along back, vault door (wall), marble floor

const MAP_W := 9
const MAP_H := 9

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const Tile = preload("res://overworld/town_map.gd").Tile

const ENTRY_POINTS := {
	"front_door": Vector2(4, 8),
}

const EXITS := {
	Vector2i(4, 8): {"map": "res://overworld/town_map.gd", "entry": "bank_door"},
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
	_window(1, 0)
	_window(4, 0)
	_window(7, 0)
	# Teller windows wall along north
	_wall(1, 1, 7, 1, Tile.WALL_GRAY)
	# Vault door (sealed wall section on north side)
	_wall(7, 1, 1, 2, Tile.WALL_GRAY)
	# Teller counter
	_wall(1, 3, 5, 1, Tile.WALL_BROWN)
	# Rope stanchions (furniture)
	_furniture_block(2, 5, 1, 1)
	_furniture_block(5, 5, 1, 1)
	_furniture_block(2, 7, 1, 1)
	_furniture_block(5, 7, 1, 1)
	_door(4, 8)
	labels = [
		["Bank", 3, 0],
		["Tellers", 1, 3],
		["Vault", 7, 1],
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
		["teller_window", 1, 3, 3, true, 5, 1],
		["stanchion", 2, 5, 4, false, 1, 1],
		["stanchion", 5, 5, 4, false, 1, 1],
		["stanchion", 2, 7, 4, false, 1, 1],
		["stanchion", 5, 7, 4, false, 1, 1],
		["vault", 7, 1, 5, true, 1, 2],
	]

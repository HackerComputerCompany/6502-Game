extends Node

const MAP_W := 12
const MAP_H := 10

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const Tile = preload("res://overworld/town_map.gd").Tile

const ENTRY_POINTS := {
	"door": Vector2(5, 8),
}

const EXITS := {
	Vector2i(5, 9): {"map": "res://overworld/house_map.gd", "entry": "bedroom_door"},
	Vector2i(6, 9): {"map": "res://overworld/house_map.gd", "entry": "bedroom_door"},
}

var furniture: Array = []

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

func _rect(x, y, w, h, tile):
	for dy in range(h):
		for dx in range(w):
			_set_tile(x + dx, y + dy, tile)

func _block(x: int, y: int, w: int, h: int) -> void:
	for dy in range(h):
		for dx in range(w):
			var px: int = x + dx
			var py: int = y + dy
			if px >= 0 and px < MAP_W and py >= 0 and py < MAP_H:
				collision[py][px] = 1

func _unblock(x, y):
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		collision[y][x] = 0

func _build():
	_rect(1, 1, 10, 8, Tile.PATH)

	_rect(0, 0, 12, 1, Tile.WALL_BEIGE)
	_block(0, 0, 12, 1)
	_rect(0, 9, 12, 1, Tile.WALL_BEIGE)
	_block(0, 9, 12, 1)
	_rect(0, 0, 1, 10, Tile.WALL_BEIGE)
	_block(0, 0, 1, 10)
	_rect(11, 0, 1, 10, Tile.WALL_BEIGE)
	_block(11, 0, 1, 10)

	# Door on south wall (2 tiles wide)
	_unblock(5, 9)
	_unblock(6, 9)
	_set_tile(5, 9, Tile.PATH)
	_set_tile(6, 9, Tile.PATH)
	decorations[9][5] = Tile.DOOR

	# Windows on north wall
	_set_tile(3, 0, Tile.WALL_GRAY)
	_set_tile(4, 0, Tile.WALL_GRAY)
	_set_tile(6, 0, Tile.WALL_GRAY)
	_set_tile(7, 0, Tile.WALL_GRAY)

	furniture = []
	labels = [
		["Your Room", 3, 4],
	]

func get_furniture() -> Array:
	return furniture

func get_labels() -> Array:
	return labels

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
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return Tile.BLANK
	return decorations[y][x]

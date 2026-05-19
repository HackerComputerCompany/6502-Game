class_name InteriorMap
extends Node

const Tile = preload("res://overworld/overworld_constants.gd").Tile

var collision: Array = []
var ground: Array = []
var decorations: Array = []

var MAP_W: int = 10
var MAP_H: int = 8
var WALL_COLOR: int = Tile.WALL_GRAY

var _entry_points: Dictionary = {}
var _exits: Dictionary = {}
var _labels: Array = []
var _furniture: Array = []

func setup(w: int, h: int, entries: Dictionary, exits: Dictionary, furniture: Array = []) -> void:
	MAP_W = w
	MAP_H = h
	_entry_points = entries
	_exits = exits
	_furniture = furniture
	_build_room()

func _init() -> void:
	pass

func _build_room() -> void:
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
	_walls_around()
	_doors_from_exits()
	_place_entry_decorations()
	labels = _labels

func _walls_around() -> void:
	for x in range(MAP_W):
		ground[0][x] = WALL_COLOR
		collision[0][x] = 1
		ground[MAP_H - 1][x] = WALL_COLOR
		collision[MAP_H - 1][x] = 1
	for y in range(MAP_H):
		ground[y][0] = WALL_COLOR
		collision[y][0] = 1
		ground[y][MAP_W - 1] = WALL_COLOR
		collision[y][MAP_W - 1] = 1

func _doors_from_exits() -> void:
	for exit_pos in _exits:
		var x: int = exit_pos.x
		var y: int = exit_pos.y
		if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
			collision[y][x] = 0
			ground[y][x] = Tile.PATH
			decorations[y][x] = Tile.DOOR

func _place_entry_decorations() -> void:
	pass

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
		ground[y][x] = WALL_COLOR

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
	return collision[y][x] == 0 and ground[y][x] != Tile.WATER

func get_ground(x: int, y: int) -> int:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return Tile.PATH
	return ground[y][x]

func get_decoration(x: int, y: int) -> int:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return Tile.BLANK
	return decorations[y][x]

var labels: Array = []

func get_labels() -> Array:
	return labels

func get_furniture() -> Array:
	return _furniture
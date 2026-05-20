extends Node

## House — single-story ranch (street = south)
##   West: workshop (north) + garage + kitchen
##   North wing: your bedroom, bathroom, parents' room, guest room
##   Center: hallway
##   South: living room (front door), kitchen continues on the west side

const Tile = preload("res://overworld/overworld_constants.gd").Tile
const RP = preload("res://overworld/room_parser.gd")

##  0         1         2         3
##  0123456789012345678901234567890123456
##  ##==D#==####==#######==#####==######   y=0  north wall, workshop exit
##  #........#.1....########......#....#   y=1  workshop, your room, bath walls
##  #........#......##....##......#....#   y=2
##  #........#......##....##......#....#   y=3
##  ####D#####......##....##......#....#   y=4  workshop/garage divider + door
##  #........#...2..##....##......#....#   y=5  garage, your room (bed), bath
##  #........#......##....##......#....#   y=6
##  #........#......########......#....#   y=7  bathroom bottom wall
##  #........###D######D######D#####D###   y=8  hall wall with 4 doors
##  #####D###D.........................#   y=9  kitchen/garage divider + door
##  #........####D####.................#   y=10 kitchen north wall + door
##  #........#.S.....#V................#   y=11 kitchen stove, living tv
##  #......P.#.XX...K#........T........#   y=12 kitchen X, phone P, sink K, table T
##  #.....G..#.F.....#..H...P..........#   y=13 garage G, fridge F, couch H, phone P
##  #........#.X.....#.................#   y=14
##  #........#.C....X#.................#   y=15 counter C, sink X
##  ##==##==###########==DD##==#########   y=16 south wall, front door, garage

const MAP := """
##==D#==####==#######==#####==######
#........#....................#....#
#.............................#....#
#....1........................#....#
#.............................#....#
#.............................#....#
#.............................#....#
#.........2...................#....#
#.............................#....#
#.............................#....#
#.............................#....#
#........#....................#....#
####D###############################
"""

const LEGEND := {
	'#': {'ground': Tile.WALL_BEIGE, 'collision': true},
	'=': {'ground': Tile.WALL_GRAY, 'collision': true},
	'.': {'ground': Tile.PATH},
	'D': {'ground': Tile.PATH, 'decoration': Tile.DOOR},
	'X': {'ground': Tile.PATH, 'collision': true},
	'1': {'furniture': 'desk', 'fw': 3, 'fh': 2, 'z': 3, 'blocks': true},
	'2': {'furniture': 'bed', 'fw': 2, 'fh': 2, 'z': 2, 'blocks': true},
	'G': {'furniture': 'garbage_can', 'fw': 1, 'fh': 1, 'z': 0, 'blocks': false},
	'P': {'furniture': 'phone', 'fw': 1, 'fh': 1, 'z': 19, 'blocks': false},
	'S': {'furniture': 'stove', 'fw': 2, 'fh': 1, 'z': 15, 'blocks': true},
	'F': {'furniture': 'fridge', 'fw': 1, 'fh': 1, 'z': 15, 'blocks': true},
	'C': {'furniture': 'counter', 'fw': 5, 'fh': 1, 'z': 18, 'blocks': true},
	'K': {'furniture': 'sink', 'fw': 1, 'fh': 3, 'z': 15, 'blocks': true},
	'H': {'furniture': 'couch', 'fw': 3, 'fh': 2, 'z': 18, 'blocks': true},
	'V': {'furniture': 'tv', 'fw': 2, 'fh': 1, 'z': 16, 'blocks': true},
	'T': {'furniture': 'table', 'fw': 2, 'fh': 1, 'z': 16, 'blocks': true},
}

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

const LABELS := [
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

var MAP_W: int = 0
var MAP_H: int = 0
var collision: Array = []
var ground: Array = []
var decorations: Array = []
var _furniture_list: Array = []

func _init() -> void:
	RP.build(self)

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
	if x < 0 or y < 0 or x >= MAP_W or y >= MAP_H:
		return Tile.BLANK
	return decorations[y][x]

func get_furniture() -> Array:
	return _furniture_list

func get_labels() -> Array:
	#return LABELS
	return []

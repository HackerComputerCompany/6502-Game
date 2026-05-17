enum Tile {
	GRASS = 0,
	PATH = 1,
	WALL_BROWN = 2,
	WALL_BEIGE = 3,
	WALL_GRAY = 4,
	ROOF_RED = 5,
	ROOF_GRAY = 6,
	DOOR = 7,
	WATER = 8,
	FENCE = 9,
	TREE = 10,
	SIGN = 11,
	BLANK = 12,
}

# Town layout (60 wide × 55 tall):
#
#   NW: Library, School, Rich Kid houses
#   N:  Main Street — Thrift Store, Post Office, Bank
#   NE: ChipMart, Lazer Arcade, Phone Co, Radio Station
#   C:  Church
#   W:  Subdivision — Elm St, Oak St, 6 houses including player's
#   SW: Industrial Park — Power Substation, Junkyard
#   S:  Main Street South — Grocery, Diner, Auto Repair, Barber, Burger Barn
#   SE: Commercial Park — OmniStor, Office Buildings
#   SE: Water Reclamation (next to lake), Lake

const MAP_W := 60
const MAP_H := 55

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const ENTRY_POINTS := {
	"house_door": Vector2(14, 32),
}

const EXITS := {
	Vector2i(14, 31): {"map": "res://overworld/house_map.gd", "entry": "front_door"},
	Vector2i(15, 31): {"map": "res://overworld/house_map.gd", "entry": "front_door"},
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
			ground[y][x] = Tile.GRASS
			decorations[y][x] = Tile.BLANK
	_build_town()

func _build_town() -> void:
	# ═══════════════════════════════════════════
	# ROADS
	# ═══════════════════════════════════════════

	# Main Street (east-west through center)
	_rect(3, 22, 54, 2, Tile.PATH)
	# North-South Boulevard
	_rect(28, 3, 2, 44, Tile.PATH)
	# Secondary streets
	_rect(14, 7, 2, 24, Tile.PATH)
	_rect(43, 7, 2, 26, Tile.PATH)
	# Top cross street
	_rect(3, 7, 54, 2, Tile.PATH)
	# South cross street
	_rect(3, 35, 16, 2, Tile.PATH)
	_rect(35, 35, 22, 2, Tile.PATH)
	# Bottom road (to lake/industrial)
	_rect(3, 45, 54, 2, Tile.PATH)
	# Connector paths from building doors to streets
	# Thrift Store door (3,12) → secondary street at x=14
	_rect(3, 12, 12, 1, Tile.PATH)
	# Post Office door (24,12) → secondary street at x=14
	_rect(14, 12, 11, 1, Tile.PATH)
	# Bank door (3,19) → secondary street at x=14
	_rect(3, 19, 12, 1, Tile.PATH)
	# Church door (19,19) → path to street
	_rect(19, 19, 10, 1, Tile.PATH)
	# Phone Co door (45,12) → boulevard at x=28
	_rect(28, 12, 18, 1, Tile.PATH)
	# Connector between Diner/Phone Co and Radio Station
	_rect(49, 14, 1, 3, Tile.PATH)
	# Grocery door (40,17) → secondary street at x=43
	_rect(40, 17, 4, 1, Tile.PATH)
	# Diner door (45,17) → boulevard
	_rect(28, 17, 18, 1, Tile.PATH)
	# Auto Repair door (40,25) → secondary street at x=43
	_rect(40, 25, 4, 1, Tile.PATH)
	# Barber Shop door (45,25) → boulevard
	_rect(28, 25, 18, 1, Tile.PATH)
	# Burger Barn door (49,33) → boulevard
	_rect(49, 33, 1, 3, Tile.PATH)
	# Water Recl door (39,45) → road
	_rect(39, 45, 1, 1, Tile.PATH)
	# Residential streets (subdivision grid)
	# Elm Street (east-west)
	_rect(1, 25, 26, 2, Tile.PATH)
	# Oak Street (east-west)
	_rect(1, 32, 26, 2, Tile.PATH)
	# Spruce Lane (north-south)
	_rect(8, 25, 2, 9, Tile.PATH)
	# Cedar Lane (north-south)
	_rect(18, 24, 2, 10, Tile.PATH)

	# ═══════════════════════════════════════════
	# LAKE (southeast)
	# ═══════════════════════════════════════════
	_rect(42, 46, 15, 7, Tile.WATER)

	# ═══════════════════════════════════════════
	# NW QUADRANT
	# ═══════════════════════════════════════════
	# Library (faces south toward top cross street)
	_building(3, 3, 9, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(7, 7)
	# School (faces south toward top cross street)
	_building(16, 3, 10, 4, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(21, 6)

	# ═══════════════════════════════════════════
	# NE QUADRANT
	# ═══════════════════════════════════════════
	# ChipMart (faces south toward top cross street)
	_building(31, 3, 10, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(36, 7)
	# Lazer Arcade (faces south toward top cross street)
	_building(45, 3, 9, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(49, 7)
	# Phone Company Central Office (faces west toward boulevard)
	_building(45, 10, 9, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(45, 12)
	# Radio Station (faces south, south of Phone Co with gap)
	_building(45, 17, 7, 4, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(48, 20)

	# Church (faces south toward connector path)
	_building(16, 15, 7, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(19, 19)

	# ═══════════════════════════════════════════
	# WEST: MAIN STREET (left of boulevard)
	# ═══════════════════════════════════════════
	# Thrift Store (faces west toward secondary street)
	_building(3, 10, 9, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(3, 12)
	# Post Office (faces east toward secondary street)
	_building(16, 10, 9, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(24, 12)
	# Bank (faces west toward secondary street)
	_building(3, 17, 9, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(3, 19)

	# ═══════════════════════════════════════════
	# WEST: SUBDIVISION (player's neighborhood)
	# ═══════════════════════════════════════════
	# --- North row (south of Elm St) ---
	# Miller House
	_building(1, 27, 7, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(4, 31)
	# Player's House
	_building(10, 27, 8, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(14, 31)
	_door(15, 31)
	# Garcia House
	_building(20, 27, 7, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(23, 31)
	# --- South row (south of Oak St) ---
	# Johnson House
	_building(1, 34, 7, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(4, 38)
	# Patel House
	_building(10, 34, 7, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(13, 38)
	# Williams House
	_building(20, 34, 7, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(23, 38)

	# ═══════════════════════════════════════════
	# RICH KID NEIGHBORHOOD (far west, bigger lots)
	# ═══════════════════════════════════════════
	_rect(1, 40, 3, 8, Tile.FENCE)
	_building(2, 41, 6, 4, Tile.WALL_BEIGE, Tile.ROOF_RED)

	# ═══════════════════════════════════════════
	# EAST: MAIN STREET (right of boulevard)
	# ═══════════════════════════════════════════
	# Grocery Store (faces east toward secondary street)
	_building(31, 15, 10, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(40, 17)
	# Diner (faces west toward boulevard)
	_building(45, 15, 8, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(45, 17)
	# Auto Repair (faces east toward secondary street)
	_building(31, 23, 10, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(40, 25)
	# Barber Shop (faces west toward boulevard)
	_building(45, 23, 8, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(45, 25)

	# ═══════════════════════════════════════════
	# FAST FOOD (south of Main St, east side)
	# ═══════════════════════════════════════════
	# Burger Barn
	_building(45, 29, 8, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(49, 33)

	# ═══════════════════════════════════════════
	# SE: COMMERCIAL PARK (office buildings)
	# ═══════════════════════════════════════════
	# OmniStor Technologies
	_building(35, 37, 12, 6, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(41, 42)
	# Office Building 2
	_building(44, 37, 8, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(48, 41)

	# ═══════════════════════════════════════════
	# SW: INDUSTRIAL PARK
	# ═══════════════════════════════════════════
	# Water Reclamation Department (next to lake, door faces east)
	_building(30, 42, 10, 6, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(39, 45)
	# Power Substation (fenced)
	_rect(3, 44, 7, 5, Tile.FENCE)
	_building(4, 45, 5, 3, Tile.WALL_BROWN, Tile.ROOF_GRAY)
	_door(6, 47)
	# Junkyard (fenced area with scattered debris, south edge)
	_rect(14, 46, 12, 7, Tile.FENCE)

	# ═══════════════════════════════════════════
	# TREES
	# ═══════════════════════════════════════════
	_scatter(Tile.TREE, 0, 0, 3, 55)
	_scatter(Tile.TREE, 57, 0, 3, 55)
	_scatter(Tile.TREE, 0, 0, 60, 3)
	_scatter(Tile.TREE, 0, 52, 60, 3)
	_scatter(Tile.TREE, 25, 0, 6, 3)

	# ═══════════════════════════════════════════
	# SIGNS at intersections
	# ═══════════════════════════════════════════
	_set_tile(29, 6, Tile.SIGN)
	_set_tile(29, 21, Tile.SIGN)
	_set_tile(29, 34, Tile.SIGN)

	# ═══════════════════════════════════════════
	# LABELS
	# ═══════════════════════════════════════════
	labels = [
		["Main St", 18, 21],
		["Elm St", 5, 24],
		["Oak St", 6, 31],
		["Your House", 12, 29],
		["Miller", 3, 29],
		["Garcia", 21, 29],
		["Johnson", 3, 36],
		["Patel", 11, 36],
		["Williams", 21, 36],
		["Library", 5, 5],
		["School", 18, 4],
		["ChipMart", 33, 5],
		["Lazer Arcade", 46, 5],
		["Phone Co.", 47, 12],
		["Radio Station", 46, 18],
		["Thrift Store", 5, 12],
		["Post Office", 18, 12],
		["Bank", 5, 17],
		["Church", 17, 17],
		["Grocery", 33, 17],
		["Diner", 47, 17],
		["Auto Repair", 33, 24],
		["Barber Shop", 46, 24],
		["Burger Barn", 46, 31],
		["OmniStor", 38, 39],
		["Office Bldg 2", 46, 39],
		["Water Recl.", 33, 44],
		["Substation", 5, 46],
		["Junkyard", 17, 48],
		["Lake", 47, 49],
	]

func _set_tile(x: int, y: int, tile: int) -> void:
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		if tile == Tile.DOOR:
			decorations[y][x] = tile
		else:
			ground[y][x] = tile

func _rect(x: int, y: int, w: int, h: int, tile: int) -> void:
	for dy in range(h):
		for dx in range(w):
			_set_tile(x + dx, y + dy, tile)

func _building(x: int, y: int, w: int, h: int, wall: int, roof: int) -> void:
	for dy in range(h):
		for dx in range(w):
			var px := x + dx
			var py := y + dy
			if dy == 0:
				_set_tile(px, py, roof)
			else:
				_set_tile(px, py, wall)
			collision[py][px] = 1

func _door(x: int, y: int) -> void:
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		collision[y][x] = 0
		ground[y][x] = Tile.PATH
		decorations[y][x] = Tile.DOOR

func _scatter(tile: int, x: int, y: int, w: int, h: int) -> void:
	for dy in range(h):
		for dx in range(w):
			var px := x + dx
			var py := y + dy
			if px >= 0 and px < MAP_W and py >= 0 and py < MAP_H:
				if ground[py][px] == Tile.GRASS and decorations[py][px] == Tile.BLANK:
					decorations[py][px] = tile
					if tile == Tile.TREE:
						collision[py][px] = 4

func is_passable(x: int, y: int) -> bool:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return false
	if decorations[y][x] == Tile.DOOR:
		return true
	return collision[y][x] == 0 and ground[y][x] != Tile.WATER

func get_ground(x: int, y: int) -> int:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return Tile.GRASS
	return ground[y][x]

func get_decoration(x: int, y: int) -> int:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return Tile.BLANK
	return decorations[y][x]

func get_labels() -> Array:
	return labels
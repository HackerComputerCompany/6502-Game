extends Node

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
	SIDEWALK = 13,
}

const MAP_W := 100
const MAP_H := 82

var collision: Array = []
var ground: Array = []
var decorations: Array = []

const ENTRY_POINTS := {
	"house_door": Vector2(21, 38),
	"library_door": Vector2(9, 9),
	"school_door": Vector2(24, 9),
	"church_door": Vector2(37, 9),
	"chipmart_door": Vector2(55, 9),
	"phone_co_door": Vector2(70, 9),
	"lazer_arcade_door": Vector2(85, 9),
	"thrift_door": Vector2(9, 18),
	"post_office_door": Vector2(21, 18),
	"bank_door": Vector2(37, 18),
	"fire_dept_door": Vector2(9, 27),
	"police_dept_door": Vector2(22, 27),
	"grocery_door": Vector2(54, 18),
	"diner_door": Vector2(69, 18),
	"hospital_door": Vector2(85, 19),
	"radio_door": Vector2(53, 28),
	"auto_repair_door": Vector2(70, 28),
	"barber_door": Vector2(84, 28),
	"miller_door": Vector2(6, 38),
	"garcia_door": Vector2(37, 38),
	"johnson_door": Vector2(6, 47),
	"patel_door": Vector2(20, 47),
	"williams_door": Vector2(37, 47),
	"rich_kid_door": Vector2(9, 58),
	"burger_barn_door": Vector2(53, 39),
	"omnistor_door": Vector2(70, 40),
	"office_bldg2_door": Vector2(85, 40),
	"pharmacy_door": Vector2(53, 47),
	"office_bldg_door": Vector2(69, 47),
	"water_recl_door": Vector2(55, 57),
	"substation_door": Vector2(8, 67),
	"outdoor_bin": Vector2i(20, 37),
}

const EXITS := {
	Vector2i(21, 36): {"map": "res://overworld/house_map.gd", "entry": "front_door"},
	Vector2i(22, 36): {"map": "res://overworld/house_map.gd", "entry": "front_door"},
	Vector2i(9, 7): {"map": "res://overworld/interiors/library.gd", "entry": "front_door"},
	Vector2i(24, 7): {"map": "res://overworld/interiors/school.gd", "entry": "front_door"},
	Vector2i(37, 7): {"map": "res://overworld/interiors/church.gd", "entry": "front_door"},
	Vector2i(55, 7): {"map": "res://overworld/interiors/chipmart.gd", "entry": "front_door"},
	Vector2i(70, 7): {"map": "res://overworld/interiors/phone_co.gd", "entry": "front_door"},
	Vector2i(85, 7): {"map": "res://overworld/interiors/lazer_arcade.gd", "entry": "front_door"},
	Vector2i(9, 16): {"map": "res://overworld/interiors/thrift_store.gd", "entry": "front_door"},
	Vector2i(21, 16): {"map": "res://overworld/interiors/post_office.gd", "entry": "front_door"},
	Vector2i(37, 16): {"map": "res://overworld/interiors/bank.gd", "entry": "front_door"},
	Vector2i(9, 25): {"map": "res://overworld/interiors/fire_dept.gd", "entry": "front_door"},
	Vector2i(22, 25): {"map": "res://overworld/interiors/police_dept.gd", "entry": "front_door"},
	Vector2i(54, 16): {"map": "res://overworld/interiors/grocery.gd", "entry": "front_door"},
	Vector2i(69, 16): {"map": "res://overworld/interiors/diner.gd", "entry": "front_door"},
	Vector2i(85, 17): {"map": "res://overworld/interiors/hospital.gd", "entry": "front_door"},
	Vector2i(53, 26): {"map": "res://overworld/interiors/radio_station.gd", "entry": "front_door"},
	Vector2i(70, 26): {"map": "res://overworld/interiors/auto_repair.gd", "entry": "front_door"},
	Vector2i(84, 26): {"map": "res://overworld/interiors/barber_shop.gd", "entry": "front_door"},
	Vector2i(6, 36): {"map": "res://overworld/interiors/miller_house.gd", "entry": "front_door"},
	Vector2i(37, 36): {"map": "res://overworld/interiors/garcia_house.gd", "entry": "front_door"},
	Vector2i(6, 45): {"map": "res://overworld/interiors/johnson_house.gd", "entry": "front_door"},
	Vector2i(20, 45): {"map": "res://overworld/interiors/patel_house.gd", "entry": "front_door"},
	Vector2i(37, 45): {"map": "res://overworld/interiors/williams_house.gd", "entry": "front_door"},
	Vector2i(9, 56): {"map": "res://overworld/interiors/rich_kid_house.gd", "entry": "front_door"},
	Vector2i(53, 37): {"map": "res://overworld/interiors/burger_barn.gd", "entry": "front_door"},
	Vector2i(70, 38): {"map": "res://overworld/interiors/omnistor.gd", "entry": "front_door"},
	Vector2i(85, 38): {"map": "res://overworld/interiors/office_bldg2.gd", "entry": "front_door"},
	Vector2i(53, 45): {"map": "res://overworld/interiors/pharmacy.gd", "entry": "front_door"},
	Vector2i(69, 45): {"map": "res://overworld/interiors/office_bldg.gd", "entry": "front_door"},
	Vector2i(55, 55): {"map": "res://overworld/interiors/water_recl.gd", "entry": "front_door"},
	Vector2i(8, 66): {"map": "res://overworld/interiors/substation.gd", "entry": "front_door"},
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
	# ROAD GRID
	#
	# North Road:      y=8-9 (2 wide, full width)
	# East Mid Road:   y=19-20 (2 wide, east half)
	# Main Street:     y=29-31 (3 wide, full width)
	# Elm Street:       y=38-39 (2 wide, west half)
	# Oak Street:       y=47-48 (2 wide, west half)
	# East Cross:      y=39-40 (2 wide, east half)
	# South Road:      y=59-60 (2 wide, both halves)
	# Bottom Road:     y=74-75 (2 wide, full width)
	# Boulevard:        x=44-46 (3 wide, full height)
	# West Secondary:  x=14-15 (2 wide, N-S)
	# East Secondary:  x=62-63 (2 wide, N-S)
	# Spruce Lane:     x=10-11 (2 wide, subdivision)
	# Cedar Lane:      x=30-31 (2 wide, subdivision)
	# ═══════════════════════════════════════════

	# --- EAST-WEST ROADS ---
	_rect(3, 8, 94, 2, Tile.PATH)         # North Road
	_rect(49, 19, 48, 2, Tile.PATH)        # East Mid Road
	_rect(3, 29, 94, 3, Tile.PATH)         # Main Street
	_rect(3, 38, 41, 2, Tile.PATH)         # Elm Street
	_rect(3, 47, 41, 2, Tile.PATH)         # Oak Street
	_rect(49, 39, 48, 2, Tile.PATH)        # East Cross
	_rect(3, 59, 41, 2, Tile.PATH)         # South Road (west)
	_rect(49, 59, 48, 2, Tile.PATH)        # South Road (east)
	_rect(3, 74, 94, 2, Tile.PATH)         # Bottom Road

	# --- NORTH-SOUTH ROADS ---
	_rect(44, 3, 3, 74, Tile.PATH)         # Boulevard
	_rect(14, 8, 2, 51, Tile.PATH)          # West Secondary
	_rect(62, 8, 2, 66, Tile.PATH)          # East Secondary
	_rect(10, 29, 2, 20, Tile.PATH)         # Spruce Lane
	_rect(30, 29, 2, 20, Tile.PATH)         # Cedar Lane

	# ═══════════════════════════════════════════
	# SIDEWALKS (1-tile buffers along major roads)
	# ═══════════════════════════════════════════

	# Main Street sidewalks
	_rect(3, 28, 41, 1, Tile.SIDEWALK)
	_rect(3, 32, 41, 1, Tile.SIDEWALK)
	_rect(48, 28, 49, 1, Tile.SIDEWALK)
	_rect(48, 32, 49, 1, Tile.SIDEWALK)
	# Boulevard sidewalks
	_rect(43, 3, 1, 74, Tile.SIDEWALK)
	_rect(47, 3, 1, 74, Tile.SIDEWALK)
	# North Road sidewalks
	_rect(3, 7, 41, 1, Tile.SIDEWALK)
	_rect(3, 10, 41, 1, Tile.SIDEWALK)
	_rect(48, 7, 49, 1, Tile.SIDEWALK)
	_rect(48, 10, 49, 1, Tile.SIDEWALK)
	# West Secondary sidewalks
	_rect(13, 10, 1, 19, Tile.SIDEWALK)
	_rect(16, 10, 1, 19, Tile.SIDEWALK)
	# East Secondary sidewalks
	_rect(61, 7, 1, 22, Tile.SIDEWALK)
	_rect(64, 7, 1, 22, Tile.SIDEWALK)
	# Spruce Lane sidewalks
	_rect(9, 29, 1, 20, Tile.SIDEWALK)
	_rect(12, 29, 1, 20, Tile.SIDEWALK)
	# Cedar Lane sidewalks
	_rect(29, 29, 1, 20, Tile.SIDEWALK)
	_rect(32, 29, 1, 20, Tile.SIDEWALK)
	# Elm Street sidewalks
	_rect(3, 37, 41, 1, Tile.SIDEWALK)
	_rect(3, 40, 41, 1, Tile.SIDEWALK)
	# Oak Street sidewalks
	_rect(3, 46, 41, 1, Tile.SIDEWALK)
	_rect(3, 49, 41, 1, Tile.SIDEWALK)
	# South Road sidewalks
	_rect(3, 58, 41, 1, Tile.SIDEWALK)
	_rect(3, 61, 41, 1, Tile.SIDEWALK)
	_rect(48, 58, 49, 1, Tile.SIDEWALK)
	_rect(48, 61, 49, 1, Tile.SIDEWALK)
	# East Cross sidewalk (north side)
	_rect(48, 38, 49, 1, Tile.SIDEWALK)

	# ═══════════════════════════════════════════
	# CONNECTOR PATHS from building doors to roads
	# ═══════════════════════════════════════════

	# NW row 1 doors → West Secondary or cross streets
	_connect(9, 16, 1, 3)                    # Thrift Store → Main St area
	_connect(21, 16, 1, 3)                   # Post Office → Main St area
	_connect(38, 16, 1, 12)                   # Bank → Main St area
	# NW row 2 doors
	_connect(9, 25, 1, 4)                    # Fire Dept → Main St
	_connect(22, 25, 1, 4)                   # Police Dept → Main St
	# NE row 1 doors → North Road or East Mid
	_connect(54, 16, 1, 3)                   # Grocery → Main St area
	_connect(69, 16, 1, 3)                   # Diner → Main St area
	_connect(85, 17, 1, 2)                   # Hospital → East Mid Road
	# NE row 2 doors
	_connect(53, 26, 1, 3)                   # Radio Station
	_connect(70, 26, 1, 3)                   # Auto Repair
	_connect(84, 26, 1, 3)                   # Barber Shop
	# Subdivision house doors → Elm/Oak
	_connect(6, 36, 1, 2)                    # Miller → Elm
	_connect(21, 36, 1, 2)                   # Player → Elm
	_connect(37, 36, 1, 2)                   # Garcia → Elm
	_connect(6, 45, 1, 2)                    # Johnson → Oak
	_connect(20, 45, 1, 2)                   # Patel → Oak
	_connect(37, 45, 1, 2)                   # Williams → Oak
	_connect(9, 55, 1, 4)                    # Rich Kid
	# SE row 1 doors → East Cross
	_connect(53, 37, 1, 2)                   # Burger Barn
	_connect(70, 38, 1, 2)                   # OmniStor
	_connect(85, 38, 1, 2)                   # Office Bldg 2
	# SE row 2 doors
	_connect(53, 45, 1, 2)                   # Pharmacy
	_connect(69, 45, 1, 2)                   # Office Bldg
	# Water Reclamation door → South Road
	_connect(55, 55, 1, 4)                   # Water Recl

	# ═══════════════════════════════════════════
	# LAKE (south-east)
	# ═══════════════════════════════════════════
	_rect(75, 64, 22, 12, Tile.WATER)

	# ═══════════════════════════════════════════
	# NORTH ROW (y=3-7, facing North Road)
	# ═══════════════════════════════════════════
	_building(5, 3, 8, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(9, 7)
	_building(18, 3, 12, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(24, 7)
	_building(33, 3, 9, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(37, 7)
	_building(49, 3, 12, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(55, 7)
	_building(65, 3, 10, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(70, 7)
	_building(80, 3, 10, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(85, 7)

	# ═══════════════════════════════════════════
	# NW BLOCK (between North Rd and Main St)
	# Row 1 (y=11-16)
	# ═══════════════════════════════════════════
	_building(5, 11, 8, 6, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(9, 16)
	_building(17, 11, 9, 6, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(21, 16)
	_building(33, 11, 9, 6, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(37, 16)

	# Row 2 (y=20-25)
	_building(5, 20, 8, 6, Tile.WALL_GRAY, Tile.ROOF_RED)
	_door(9, 25)
	_building(17, 20, 9, 6, Tile.WALL_BEIGE, Tile.ROOF_GRAY)
	_door(22, 25)

	# ═══════════════════════════════════════════
	# NE BLOCK (between North Rd and Main St, east)
	# Row 1 (y=11-16)
	# ═══════════════════════════════════════════
	_building(49, 11, 11, 6, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(54, 16)
	_building(65, 11, 9, 6, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(69, 16)
	_building(78, 11, 14, 7, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(85, 17)

	# Row 2 (y=21-26)
	_building(49, 21, 9, 6, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(53, 26)
	_building(65, 21, 10, 6, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(70, 26)
	_building(80, 21, 9, 6, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(84, 26)

	# ═══════════════════════════════════════════
	# SUBDIVISION (west, below Main St)
	# Row 1 (y=32-36, north of Elm St)
	# ═══════════════════════════════════════════
	_building(3, 32, 6, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(6, 36)
	_building(17, 32, 8, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(21, 36)
	_door(22, 36)
	_building(33, 32, 8, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(37, 36)

	# Row 2 (y=41-45, north of Oak St)
	_building(3, 41, 6, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(6, 45)
	_building(17, 41, 7, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(20, 45)
	_building(33, 41, 8, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(37, 45)

	# Rich Kid House (fenced, below Oak St)
	_rect(3, 50, 12, 8, Tile.FENCE)
	_building(5, 52, 8, 5, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(9, 56)

	# ═══════════════════════════════════════════
	# SE BLOCK (east of Blvd, below Main St)
	# Row 1 (y=33-37)
	# ═══════════════════════════════════════════
	_building(49, 33, 9, 5, Tile.WALL_BROWN, Tile.ROOF_RED)
	_door(53, 37)
	_building(64, 33, 12, 6, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(70, 38)
	_building(80, 33, 10, 6, Tile.WALL_BEIGE, Tile.ROOF_RED)
	_door(85, 38)

	# Row 2 (y=41-45)
	_building(49, 41, 8, 5, Tile.WALL_GRAY, Tile.ROOF_RED)
	_door(53, 45)
	_building(64, 41, 10, 5, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(69, 45)

	# Water Reclamation (near lake)
	_building(49, 50, 12, 6, Tile.WALL_GRAY, Tile.ROOF_GRAY)
	_door(55, 55)

	# ═══════════════════════════════════════════
	# INDUSTRIAL (SW, below South Rd)
	# ═══════════════════════════════════════════
	_rect(4, 62, 8, 7, Tile.FENCE)
	_building(5, 63, 6, 4, Tile.WALL_BROWN, Tile.ROOF_GRAY)
	_door(8, 66)
	_rect(18, 62, 18, 9, Tile.FENCE)

	# ═══════════════════════════════════════════
	# TREES
	# ═══════════════════════════════════════════
	_scatter(Tile.TREE, 0, 0, 3, 82)
	_scatter(Tile.TREE, 97, 0, 3, 82)
	_scatter(Tile.TREE, 0, 0, 100, 3)
	_scatter(Tile.TREE, 0, 79, 100, 3)

	# ═══════════════════════════════════════════
	# SIGNS
	# ═══════════════════════════════════════════
	_set_tile(45, 28, Tile.SIGN)
	_set_tile(45, 32, Tile.SIGN)
	_set_tile(15, 28, Tile.SIGN)
	_set_tile(15, 32, Tile.SIGN)
	_set_tile(63, 28, Tile.SIGN)
	_set_tile(63, 32, Tile.SIGN)

	# ═══════════════════════════════════════════
	# LABELS
	# ═══════════════════════════════════════════
	labels = [
		["Main St", 22, 28],
		["Main St", 70, 28],
		["Elm St", 6, 37],
		["Oak St", 6, 46],
		["Spruce Ln", 9, 30],
		["Cedar Ln", 28, 30],
		["Your House", 18, 34],
		["Miller", 4, 34],
		["Garcia", 34, 34],
		["Johnson", 4, 42],
		["Patel", 18, 42],
		["Williams", 34, 42],
		["Library", 7, 5],
		["School", 21, 5],
		["Church", 35, 5],
		["ChipMart", 51, 5],
		["Phone Co", 67, 5],
		["Lazer Arcade", 82, 5],
		["Thrift Store", 6, 13],
		["Post Office", 19, 13],
		["Bank", 35, 13],
		["Fire Dept", 6, 22],
		["Police Dept", 19, 22],
		["Grocery", 51, 13],
		["Diner", 67, 13],
		["Hospital", 83, 14],
		["Radio Station", 51, 23],
		["Auto Repair", 68, 23],
		["Barber Shop", 82, 23],
		["Burger Barn", 51, 35],
		["OmniStor", 68, 36],
		["Office Bldg 2", 82, 36],
		["Pharmacy", 51, 43],
		["Office Bldg", 67, 43],
		["Water Recl.", 52, 52],
		["Substation", 6, 64],
		["Junkyard", 23, 65],
		["Lake", 82, 69],
		["Rich Kid", 6, 54],
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

func _connect(x: int, y: int, w: int, h: int) -> void:
	for dy in range(h):
		for dx in range(w):
			var px := x + dx
			var py := y + dy
			if px >= 0 and px < MAP_W and py >= 0 and py < MAP_H:
				if ground[py][px] == Tile.GRASS and collision[py][px] == 0:
					ground[py][px] = Tile.SIDEWALK

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

func get_furniture() -> Array:
	return [
		["garbage_bin", 20, 37, 37, false, 1, 1],
	]
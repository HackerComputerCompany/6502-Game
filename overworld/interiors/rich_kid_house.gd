extends InteriorMap

# Rich Kid House (14 wide x 12 tall)
# Fancy house with foyer, living room, study, kitchen

const MAP_W := 14
const MAP_H := 12
const WALL_COLOR: int = Tile.WALL_BEIGE
const ENTRY_POINTS := {
	"front_door": Vector2(6, 10),
}

const EXITS := {
	Vector2i(6, 11): {"map": "res://overworld/town_map.gd", "entry": "rich_kid_door"},
	Vector2i(7, 11): {"map": "res://overworld/town_map.gd", "entry": "rich_kid_door"},
}

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
	# Foyer / Living Room divider
	_wall(5, 0, 1, 6, Tile.WALL_BEIGE)
	_door(5, 3)
	# Kitchen divider
	_wall(9, 0, 1, 6, Tile.WALL_BEIGE)
	_door(9, 4)
	# Study divider walls in back
	_wall(5, 6, 1, 5, Tile.WALL_BEIGE)
	_door(5, 8)
	_wall(9, 6, 1, 5, Tile.WALL_BEIGE)
	_door(9, 8)
	# Windows
	_window(1, 0)
	_window(3, 0)
	_window(7, 0)
	_window(11, 0)
	_window(13, 3)
	_window(0, 4)
	_window(13, 7)
	# Foyer furniture
	_furniture_block(1, 1, 1, 1)
	_furniture_block(3, 1, 1, 1)
	# Living Room - tv, couch, bookshelf
	_furniture_block(6, 1, 3, 1)
	_furniture_block(6, 4, 2, 1)
	_furniture_block(8, 4, 1, 1)
	_furniture_block(6, 5, 1, 1)
	# Kitchen - counter, dining table
	_furniture_block(10, 1, 3, 1)
	_furniture_block(12, 3, 1, 1)
	_furniture_block(10, 4, 2, 1)
	# Study - desk, bookshelf
	_furniture_block(6, 7, 2, 1)
	_furniture_block(1, 7, 3, 1)
	_furniture_block(1, 9, 2, 1)
	# Kitchen back area
	_furniture_block(10, 7, 3, 1)
	# Front doors
	_door(6, 11)
	_door(7, 11)
	labels = [
		["Foyer", 2, 2],
		["Living Room", 6, 2],
		["Kitchen", 10, 2],
		["Study", 2, 7],
	]

func get_furniture() -> Array:
	return [
		["coat_rack", 1, 1, 4, false, 1, 1],
		["plant", 3, 1, 4, false, 1, 1],
		["tv", 6, 1, 5, true, 3, 1],
		["couch", 6, 4, 4, true, 2, 1],
		["side_table", 8, 4, 4, false, 1, 1],
		["bookshelf", 6, 5, 4, true, 1, 1],
		["counter", 10, 1, 5, true, 3, 1],
		["fridge", 12, 3, 4, false, 1, 1],
		["dining_table", 10, 4, 4, false, 2, 1],
		["desk", 6, 7, 4, true, 2, 1],
		["bookshelf", 1, 7, 4, true, 3, 1],
		["table", 1, 9, 4, false, 2, 1],
		["shelf", 10, 7, 5, true, 3, 1],
	]

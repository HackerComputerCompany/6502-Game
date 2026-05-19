extends InteriorMap

# Grocery Store (11 wide x 8 tall)
# Shelves in rows, deli counter at back, registers near door

const MAP_W := 11
const MAP_H := 8
const WALL_COLOR: int = Tile.WALL_BROWN
const ENTRY_POINTS := {
	"front_door": Vector2(5, 7),
}

const EXITS := {
	Vector2i(5, 7): {"map": "res://overworld/town_map.gd", "entry": "grocery_door"},
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
	_window(2, 0)
	_window(5, 0)
	_window(8, 0)
	# Deli counter at back (north)
	_wall(1, 1, 9, 1, Tile.WALL_BROWN)
	_door(5, 1)
	# Shelf rows
	_furniture_block(1, 3, 2, 1)
	_furniture_block(4, 3, 2, 1)
	_furniture_block(7, 3, 2, 1)
	_furniture_block(1, 4, 2, 1)
	_furniture_block(4, 4, 2, 1)
	_furniture_block(7, 4, 2, 1)
	# Registers near door
	_furniture_block(3, 6, 1, 1)
	_furniture_block(6, 6, 1, 1)
	_door(5, 7)
	labels = [
		["Grocery", 3, 0],
		["Deli", 3, 1],
		["Shelves", 1, 3],
		["Register", 3, 6],
	]

func get_furniture() -> Array:
	return [
		["deli_counter", 1, 1, 3, true, 9, 1],
		["shelf", 1, 3, 4, false, 2, 1],
		["shelf", 4, 3, 4, true, 2, 1],
		["shelf", 7, 3, 4, false, 2, 1],
		["shelf", 1, 4, 4, true, 2, 1],
		["shelf", 4, 4, 4, false, 2, 1],
		["shelf", 7, 4, 4, true, 2, 1],
		["register", 3, 6, 3, false, 1, 1],
		["register", 6, 6, 3, true, 1, 1],
	]

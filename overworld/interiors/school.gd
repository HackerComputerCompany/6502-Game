extends InteriorMap

# School Classroom (14 wide x 10 tall)
# Rows of desks, teacher desk at front (north), chalkboard on north wall, door on south

const MAP_W := 14
const MAP_H := 10
const WALL_COLOR: int = Tile.WALL_BEIGE
const ENTRY_POINTS := {
	"front_door": Vector2(7, 9),
}

const EXITS := {
	Vector2i(7, 9): {"map": "res://overworld/town_map.gd", "entry": "school_door"},
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
	_window(1, 0)
	_window(4, 0)
	_window(8, 0)
	_window(11, 0)
	_window(13, 3)
	_window(13, 6)
	# Teacher desk at front
	_furniture_block(5, 1, 4, 1)
	# Chalkboard on north wall (between windows)
	_wall(3, 0, 2, 1, Tile.WALL_BEIGE)
	# Student desk rows
	_furniture_block(2, 3, 2, 1)
	_furniture_block(5, 3, 2, 1)
	_furniture_block(8, 3, 2, 1)
	_furniture_block(11, 3, 2, 1)
	_furniture_block(2, 5, 2, 1)
	_furniture_block(5, 5, 2, 1)
	_furniture_block(8, 5, 2, 1)
	_furniture_block(11, 5, 2, 1)
	_furniture_block(2, 7, 2, 1)
	_furniture_block(5, 7, 2, 1)
	_furniture_block(8, 7, 2, 1)
	_furniture_block(11, 7, 2, 1)
	_door(7, 9)
	labels = [
		["School", 5, 0],
		["Chalkboard", 3, 0],
		["Teacher", 5, 1],
		["Desks", 2, 3],
	]

func get_furniture() -> Array:
	return [
		["desk", 5, 1, 3, false, 4, 1],
		["desk", 2, 3, 2, false, 2, 1],
		["desk", 5, 3, 2, false, 2, 1],
		["desk", 8, 3, 2, false, 2, 1],
		["desk", 11, 3, 2, false, 2, 1],
		["desk", 2, 5, 2, false, 2, 1],
		["desk", 5, 5, 2, false, 2, 1],
		["desk", 8, 5, 2, false, 2, 1],
		["desk", 11, 5, 2, false, 2, 1],
		["desk", 2, 7, 2, false, 2, 1],
		["desk", 5, 7, 2, false, 2, 1],
		["desk", 8, 7, 2, false, 2, 1],
		["desk", 11, 7, 2, false, 2, 1],
	]

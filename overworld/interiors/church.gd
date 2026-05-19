extends InteriorMap

# Church (10 wide x 12 tall)
# Pews in rows, altar at north, door on south

const MAP_W := 10
const MAP_H := 12
const WALL_COLOR: int = Tile.WALL_BEIGE
const ENTRY_POINTS := {
	"front_door": Vector2(5, 11),
}

const EXITS := {
	Vector2i(5, 11): {"map": "res://overworld/town_map.gd", "entry": "church_door"},
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
	_window(7, 0)
	_window(0, 3)
	_window(0, 6)
	_window(9, 3)
	_window(9, 6)
	# Altar at north
	_furniture_block(4, 1, 2, 1)
	# Pews in rows - left aisle
	_furniture_block(1, 3, 3, 1)
	_furniture_block(1, 5, 3, 1)
	_furniture_block(1, 7, 3, 1)
	# Pews - right aisle
	_furniture_block(6, 3, 3, 1)
	_furniture_block(6, 5, 3, 1)
	_furniture_block(6, 7, 3, 1)
	# Rear pew row
	_furniture_block(2, 9, 3, 1)
	_furniture_block(6, 9, 3, 1)
	_door(5, 11)
	labels = [
		["Church", 3, 0],
		["Altar", 4, 1],
		["Pews", 1, 3],
	]

func get_furniture() -> Array:
	return [
		["altar", 4, 1, 5, false, 2, 1],
		["pew", 1, 3, 6, false, 3, 1],
		["pew", 6, 3, 6, true, 3, 1],
		["pew", 1, 5, 6, false, 3, 1],
		["pew", 6, 5, 6, true, 3, 1],
		["pew", 1, 7, 6, false, 3, 1],
		["pew", 6, 7, 6, true, 3, 1],
		["pew", 2, 9, 6, false, 3, 1],
		["pew", 6, 9, 6, true, 3, 1],
	]

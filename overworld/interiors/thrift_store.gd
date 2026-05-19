extends InteriorMap

# Thrift Store (8 wide x 8 tall)
# Racks and shelves, counter near door

const MAP_W := 8
const MAP_H := 8
const WALL_COLOR: int = Tile.WALL_BROWN
const ENTRY_POINTS := {
	"front_door": Vector2(4, 7),
}

const EXITS := {
	Vector2i(4, 7): {"map": "res://overworld/town_map.gd", "entry": "thrift_door"},
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
	_window(6, 0)
	# Shelves along north wall
	_furniture_block(1, 1, 6, 1)
	# Left wall racks
	_furniture_block(1, 3, 1, 3)
	# Right wall racks
	_furniture_block(6, 3, 1, 3)
	# Center rack row
	_furniture_block(3, 3, 2, 1)
	_furniture_block(3, 5, 2, 1)
	# Counter near door
	_furniture_block(5, 6, 2, 1)
	_door(4, 7)
	labels = [
		["Thrift Store", 1, 0],
		["Shelves", 1, 1],
		["Counter", 5, 6],
	]

func get_furniture() -> Array:
	return [
		["shelf", 1, 1, 4, true, 6, 1],
		["rack", 1, 3, 5, false, 1, 3],
		["rack", 6, 3, 5, true, 1, 3],
		["rack", 3, 3, 5, false, 2, 1],
		["rack", 3, 5, 5, true, 2, 1],
		["counter", 5, 6, 3, true, 2, 1],
	]

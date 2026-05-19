extends InteriorMap

# Patel House (11 wide x 9 tall)
# Modest house, kitchen and living area

const MAP_W := 11
const MAP_H := 9
const WALL_COLOR: int = Tile.WALL_BROWN
const ENTRY_POINTS := {
	"front_door": Vector2(5, 7),
}

const EXITS := {
	Vector2i(5, 8): {"map": "res://overworld/town_map.gd", "entry": "patel_door"},
	Vector2i(6, 8): {"map": "res://overworld/town_map.gd", "entry": "patel_door"},
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
	_window(8, 0)
	_window(0, 3)
	_window(10, 4)
	_wall(5, 0, 1, 3, Tile.WALL_BROWN)
	_door(5, 3)
	_furniture_block(1, 1, 3, 1)
	_furniture_block(8, 0, 2, 1)
	_furniture_block(9, 2, 1, 2)
	_furniture_block(7, 4, 2, 1)
	_furniture_block(1, 4, 2, 1)
	_door(5, 8)
	_door(6, 8)
	labels = [
		["Patel House", 4, 0],
		["Kitchen", 1, 1],
		["Living Room", 7, 2],
	]

func get_furniture() -> Array:
	return [
		["kitchen_table", 1, 1, 2, false, 3, 1],
		["counter", 8, 1, 1, true, 2, 1],
		["fridge", 9, 2, 3, true, 1, 2],
		["sofa", 7, 4, 5, false, 2, 1],
		["bookshelf", 1, 4, 5, true, 2, 1],
	]

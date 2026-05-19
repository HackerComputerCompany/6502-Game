extends InteriorMap

# Garcia House (12 wide x 10 tall)
# Larger house with living room, hallway, kitchen

const MAP_W := 12
const MAP_H := 10
const WALL_COLOR: int = Tile.WALL_BROWN
const ENTRY_POINTS := {
	"front_door": Vector2(5, 8),
}

const EXITS := {
	Vector2i(5, 9): {"map": "res://overworld/town_map.gd", "entry": "garcia_door"},
	Vector2i(6, 9): {"map": "res://overworld/town_map.gd", "entry": "garcia_door"},
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
	_window(6, 0)
	_window(10, 0)
	_window(0, 4)
	_window(11, 4)
	_wall(5, 0, 1, 4, Tile.WALL_BROWN)
	_door(5, 3)
	_wall(9, 0, 1, 4, Tile.WALL_BROWN)
	_door(9, 3)
	_furniture_block(1, 1, 3, 1)
	_furniture_block(2, 3, 2, 1)
	_furniture_block(10, 1, 1, 2)
	_furniture_block(7, 1, 2, 1)
	_furniture_block(7, 3, 1, 1)
	_furniture_block(1, 5, 3, 1)
	_furniture_block(8, 6, 2, 1)
	_door(5, 9)
	_door(6, 9)
	labels = [
		["Garcia House", 4, 0],
		["Living Room", 1, 2],
		["Kitchen", 7, 2],
		["Hallway", 6, 7],
	]

func get_furniture() -> Array:
	return [
		["sofa", 1, 1, 2, false, 3, 1],
		["coffee_table", 2, 3, 4, false, 2, 1],
		["fridge", 10, 1, 2, true, 1, 2],
		["kitchen_table", 7, 1, 2, true, 2, 1],
		["stove", 7, 3, 4, true, 1, 1],
		["hall_table", 1, 5, 6, false, 3, 1],
		["dining_table", 8, 6, 7, true, 2, 1],
	]

extends InteriorMap

# Miller House (10 wide x 8 tall)
# Living room + kitchen with wall divider, small ranch house

const MAP_W := 10
const MAP_H := 8
const WALL_COLOR: int = Tile.WALL_BEIGE
const ENTRY_POINTS := {
	"front_door": Vector2(5, 6),
}

const EXITS := {
	Vector2i(5, 7): {"map": "res://overworld/town_map.gd", "entry": "miller_door"},
	Vector2i(6, 7): {"map": "res://overworld/town_map.gd", "entry": "miller_door"},
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
	_window(7, 0)
	_window(0, 3)
	_window(9, 4)
	_wall(5, 0, 1, 4, Tile.WALL_BEIGE)
	_door(5, 4)
	_furniture_block(1, 1, 3, 1)
	_furniture_block(2, 3, 2, 1)
	_furniture_block(7, 1, 2, 1)
	_furniture_block(8, 3, 1, 3)
	_door(5, 7)
	_door(6, 7)
	labels = [
		["Miller House", 3, 0],
		["Living Room", 1, 2],
		["Kitchen", 7, 2],
	]

func get_furniture() -> Array:
	return [
		["sofa", 1, 1, 2, false, 3, 1],
		["coffee_table", 2, 3, 4, false, 2, 1],
		["kitchen_table", 7, 1, 2, true, 2, 1],
		["counter", 8, 3, 4, true, 1, 3],
	]

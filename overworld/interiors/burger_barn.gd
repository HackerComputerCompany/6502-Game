extends InteriorMap

# Burger Barn (14 wide x 10 tall)
# Counter along back wall, booth seating on sides, kitchen behind divider

const MAP_W := 14
const MAP_H := 10
const WALL_COLOR: int = Tile.WALL_BROWN
const ENTRY_POINTS := {
	"front_door": Vector2(6, 8),
}

const EXITS := {
	Vector2i(6, 9): {"map": "res://overworld/town_map.gd", "entry": "burger_barn_door"},
	Vector2i(7, 9): {"map": "res://overworld/town_map.gd", "entry": "burger_barn_door"},
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
	_window(3, 0)
	_window(7, 0)
	_window(10, 0)
	_wall(1, 5, 12, 1, Tile.WALL_BROWN)
	_door(6, 5)
	_furniture_block(1, 1, 12, 1)
	_furniture_block(2, 3, 3, 1)
	_furniture_block(9, 3, 3, 1)
	_furniture_block(1, 6, 2, 1)
	_furniture_block(1, 8, 2, 1)
	_furniture_block(11, 6, 2, 1)
	_furniture_block(11, 8, 2, 1)
	_furniture_block(5, 7, 2, 1)
	_furniture_block(8, 7, 2, 1)
	_door(6, 9)
	_door(7, 9)
	labels = [
		["Burger Barn", 4, 0],
		["Kitchen", 3, 3],
		["Counter", 1, 1],
		["Booth", 1, 6],
		["Table", 5, 7],
	]

func get_furniture() -> Array:
	return [
		["counter", 1, 1, 3, true, 12, 1],
		["stove", 2, 3, 3, false, 3, 1],
		["prep", 9, 3, 3, true, 3, 1],
		["booth", 1, 6, 6, false, 2, 1],
		["booth", 1, 8, 6, true, 2, 1],
		["booth", 11, 6, 6, false, 2, 1],
		["booth", 11, 8, 6, true, 2, 1],
		["table", 5, 7, 2, false, 2, 1],
		["table", 8, 7, 2, true, 2, 1],
	]

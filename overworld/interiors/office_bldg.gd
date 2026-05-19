extends InteriorMap

# Office Building (14 wide x 10 tall)
# Open plan cubicles, break room with dividing wall

const MAP_W := 14
const MAP_H := 10

const ENTRY_POINTS := {
	"front_door": Vector2(6, 8),
}

const EXITS := {
	Vector2i(6, 9): {"map": "res://overworld/town_map.gd", "entry": "office_bldg_door"},
	Vector2i(7, 9): {"map": "res://overworld/town_map.gd", "entry": "office_bldg_door"},
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
	_window(11, 0)
	_wall(9, 1, 1, 5, Tile.WALL_GRAY)
	_door(9, 4)
	_furniture_block(2, 2, 2, 1)
	_furniture_block(2, 4, 2, 1)
	_furniture_block(2, 6, 2, 1)
	_furniture_block(5, 2, 2, 1)
	_furniture_block(5, 4, 2, 1)
	_furniture_block(5, 6, 2, 1)
	_furniture_block(11, 2, 2, 1)
	_furniture_block(10, 4, 3, 1)
	_door(6, 9)
	_door(7, 9)
	labels = [
		["Office Bldg", 3, 0],
		["Cubicles", 2, 2],
		["Break Room", 10, 1],
	]

func get_furniture() -> Array:
	return [
		["desk", 2, 2, 2, false, 2, 1],
		["desk", 2, 4, 2, true, 2, 1],
		["desk", 2, 6, 2, false, 2, 1],
		["desk", 5, 2, 2, true, 2, 1],
		["desk", 5, 4, 2, false, 2, 1],
		["desk", 5, 6, 2, true, 2, 1],
		["table", 11, 2, 3, false, 2, 1],
		["counter", 10, 4, 3, true, 3, 1],
	]

extends InteriorMap

# Office Building 2 (12 wide x 10 tall)
# Cubicles and boss office with dividing wall

const MAP_W := 12
const MAP_H := 10

const ENTRY_POINTS := {
	"front_door": Vector2(5, 8),
}

const EXITS := {
	Vector2i(5, 9): {"map": "res://overworld/town_map.gd", "entry": "office_bldg2_door"},
	Vector2i(6, 9): {"map": "res://overworld/town_map.gd", "entry": "office_bldg2_door"},
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
	_wall(8, 1, 1, 4, Tile.WALL_GRAY)
	_door(8, 3)
	_furniture_block(1, 2, 2, 1)
	_furniture_block(1, 4, 2, 1)
	_furniture_block(1, 6, 2, 1)
	_furniture_block(4, 2, 2, 1)
	_furniture_block(4, 4, 2, 1)
	_furniture_block(4, 6, 2, 1)
	_furniture_block(9, 2, 2, 1)
	_door(5, 9)
	_door(6, 9)
	labels = [
		["Office Bldg 2", 3, 0],
		["Cubicles", 2, 2],
		["Boss Office", 9, 1],
	]

func get_furniture() -> Array:
	return [
		["desk", 1, 2, 2, false, 2, 1],
		["desk", 1, 4, 2, true, 2, 1],
		["desk", 1, 6, 2, false, 2, 1],
		["desk", 4, 2, 2, true, 2, 1],
		["desk", 4, 4, 2, false, 2, 1],
		["desk", 4, 6, 2, true, 2, 1],
		["boss_desk", 9, 2, 3, true, 2, 1],
	]

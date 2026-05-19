extends InteriorMap

# Lazer Arcade (10 wide x 10 tall)
# Arcade cabinets along walls, prize counter near door

const MAP_W := 10
const MAP_H := 10

const ENTRY_POINTS := {
	"front_door": Vector2(5, 9),
}

const EXITS := {
	Vector2i(5, 9): {"map": "res://overworld/town_map.gd", "entry": "lazer_arcade_door"},
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
	_window(9, 3)
	# Arcade cabinets along north wall
	_furniture_block(1, 1, 2, 1)
	_furniture_block(4, 1, 2, 1)
	_furniture_block(7, 1, 2, 1)
	# Left wall cabinets
	_furniture_block(1, 3, 1, 2)
	_furniture_block(1, 6, 1, 2)
	# Right wall cabinets
	_furniture_block(8, 3, 1, 2)
	_furniture_block(8, 6, 1, 2)
	# Center game cabinets
	_furniture_block(3, 4, 2, 1)
	_furniture_block(3, 6, 2, 1)
	_furniture_block(6, 4, 2, 1)
	_furniture_block(6, 6, 2, 1)
	# Prize counter near door
	_furniture_block(3, 8, 4, 1)
	_door(5, 9)
	labels = [
		["Lazer Arcade", 3, 0],
		["Games", 1, 1],
		["Prizes", 3, 8],
	]

func get_furniture() -> Array:
	return [
		["arcade_cabinet", 1, 1, 4, false, 2, 1],
		["arcade_cabinet", 4, 1, 4, true, 2, 1],
		["arcade_cabinet", 7, 1, 4, false, 2, 1],
		["arcade_cabinet", 1, 3, 4, false, 1, 2],
		["arcade_cabinet", 1, 6, 4, true, 1, 2],
		["arcade_cabinet", 8, 3, 4, true, 1, 2],
		["arcade_cabinet", 8, 6, 4, false, 1, 2],
		["arcade_cabinet", 3, 4, 4, false, 2, 1],
		["arcade_cabinet", 3, 6, 4, true, 2, 1],
		["arcade_cabinet", 6, 4, 4, false, 2, 1],
		["arcade_cabinet", 6, 6, 4, true, 2, 1],
		["counter", 3, 8, 3, true, 4, 1],
	]

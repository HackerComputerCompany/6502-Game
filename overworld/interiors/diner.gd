extends InteriorMap

# Diner (9 wide x 8 tall)
# Counter with stools along north, booths on sides, kitchen door

const MAP_W := 9
const MAP_H := 8
const WALL_COLOR: int = Tile.WALL_BROWN
const ENTRY_POINTS := {
	"front_door": Vector2(4, 7),
}

const EXITS := {
	Vector2i(4, 7): {"map": "res://overworld/town_map.gd", "entry": "diner_door"},
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
	# Counter along north wall
	_wall(1, 1, 7, 1, Tile.WALL_BROWN)
	_door(5, 1)
	# Booths on left side
	_furniture_block(1, 3, 2, 1)
	_furniture_block(1, 5, 2, 1)
	# Booths on right side
	_furniture_block(6, 3, 2, 1)
	_furniture_block(6, 5, 2, 1)
	# Stools along counter
	_furniture_block(3, 2, 1, 1)
	_furniture_block(4, 2, 1, 1)
	_furniture_block(6, 2, 1, 1)
	_furniture_block(7, 2, 1, 1)
	_door(4, 7)
	labels = [
		["Diner", 3, 0],
		["Counter", 2, 1],
		["Kitchen", 5, 1],
		["Booth", 1, 3],
	]

func get_furniture() -> Array:
	return [
		["counter", 1, 1, 3, true, 7, 1],
		["booth", 1, 3, 6, false, 2, 1],
		["booth", 1, 5, 6, true, 2, 1],
		["booth", 6, 3, 6, false, 2, 1],
		["booth", 6, 5, 6, true, 2, 1],
		["stool", 3, 2, 2, false, 1, 1],
		["stool", 4, 2, 2, true, 1, 1],
		["stool", 6, 2, 2, false, 1, 1],
		["stool", 7, 2, 2, true, 1, 1],
	]

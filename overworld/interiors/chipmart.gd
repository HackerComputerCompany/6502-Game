extends InteriorMap

# ChipMart Electronics Store (12 wide x 10 tall)
# Shelves along walls, counter at back, registers near door

const MAP_W := 12
const MAP_H := 10

const ENTRY_POINTS := {
	"front_door": Vector2(5, 8),
}

const EXITS := {
	Vector2i(5, 9): {"map": "res://overworld/town_map.gd", "entry": "chipmart_door"},
	Vector2i(6, 9): {"map": "res://overworld/town_map.gd", "entry": "chipmart_door"},
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
	# Shelf rows (left wall)
	_furniture_block(1, 1, 1, 3)
	_furniture_block(1, 5, 1, 3)
	# Shelf rows (right wall)
	_furniture_block(10, 1, 1, 3)
	_furniture_block(10, 5, 1, 3)
	# Counter at back
	_wall(3, 6, 6, 1, Tile.WALL_BROWN)
	# Door in counter gap (center)
	_door(5, 6)
	# Aisle divider
	_wall(5, 3, 2, 1, Tile.WALL_BROWN)
	_door(6, 3)
	# Front door
	_door(5, 9)
	_door(6, 9)
	labels = [
		["ChipMart", 4, 0],
		["Shelves", 1, 2],
		["Counter", 5, 5],
	]

func get_furniture() -> Array:
	return [
		["shelf", 1, 1, 4, true, 1, 3],
		["shelf", 10, 1, 4, true, 1, 3],
		["shelf", 1, 5, 4, true, 1, 3],
		["shelf", 10, 5, 4, true, 1, 3],
		["counter", 3, 5, 5, true, 6, 1],
	]

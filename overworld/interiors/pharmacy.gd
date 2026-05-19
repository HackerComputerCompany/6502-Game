extends InteriorMap

# Pharmacy (12 wide x 9 tall)
# Shelves along walls, pharmacy counter at back, checkout near front

const MAP_W := 12
const MAP_H := 9
const WALL_COLOR: int = Tile.WALL_BEIGE
const ENTRY_POINTS := {
	"front_door": Vector2(5, 7),
}

const EXITS := {
	Vector2i(5, 8): {"map": "res://overworld/town_map.gd", "entry": "pharmacy_door"},
	Vector2i(6, 8): {"map": "res://overworld/town_map.gd", "entry": "pharmacy_door"},
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
	_window(9, 0)
	_wall(4, 1, 4, 1, Tile.WALL_BEIGE)
	_furniture_block(1, 1, 1, 5)
	_furniture_block(10, 1, 1, 5)
	_furniture_block(3, 6, 2, 1)
	_door(5, 8)
	_door(6, 8)
	labels = [
		["Pharmacy", 4, 0],
		["Counter", 4, 1],
		["Shelves", 1, 1],
		["Register", 3, 6],
	]

func get_furniture() -> Array:
	return [
		["counter", 4, 1, 3, true, 4, 1],
		["shelf", 1, 1, 4, false, 1, 5],
		["shelf", 10, 1, 4, true, 1, 5],
		["register", 3, 6, 3, false, 2, 1],
	]

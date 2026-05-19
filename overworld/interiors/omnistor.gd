extends InteriorMap

# OmniStor (16 wide x 12 tall)
# Big warehouse store with tall shelf rows and checkout counter near door

const MAP_W := 16
const MAP_H := 12

const ENTRY_POINTS := {
	"front_door": Vector2(7, 10),
}

const EXITS := {
	Vector2i(7, 11): {"map": "res://overworld/town_map.gd", "entry": "omnistor_door"},
	Vector2i(8, 11): {"map": "res://overworld/town_map.gd", "entry": "omnistor_door"},
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
	_window(14, 0)
	_furniture_block(1, 1, 1, 8)
	_furniture_block(4, 1, 1, 8)
	_furniture_block(8, 1, 1, 8)
	_furniture_block(12, 1, 1, 8)
	_furniture_block(12, 9, 3, 1)
	_door(7, 11)
	_door(8, 11)
	labels = [
		["OmniStor", 5, 0],
		["Shelves", 1, 1],
		["Checkout", 12, 9],
	]

func get_furniture() -> Array:
	return [
		["shelf", 1, 1, 4, false, 1, 8],
		["shelf", 4, 1, 4, true, 1, 8],
		["shelf", 8, 1, 4, false, 1, 8],
		["shelf", 12, 1, 4, true, 1, 8],
		["checkout", 12, 9, 3, true, 3, 1],
	]

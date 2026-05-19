extends InteriorMap

# Electrical Substation (10 wide x 8 tall)
# Equipment room with large transformers and control panels

const MAP_W := 10
const MAP_H := 8

const ENTRY_POINTS := {
	"front_door": Vector2(4, 6),
}

const EXITS := {
	Vector2i(4, 7): {"map": "res://overworld/town_map.gd", "entry": "substation_door"},
	Vector2i(5, 7): {"map": "res://overworld/town_map.gd", "entry": "substation_door"},
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
	# Windows
	_window(2, 0)
	_window(7, 0)
	_window(0, 3)
	_window(9, 3)
	# Transformer blocks
	_furniture_block(1, 1, 3, 2)
	_furniture_block(5, 1, 3, 2)
	# Control desk
	_furniture_block(4, 5, 2, 1)
	# Safety railing
	_furniture_block(1, 4, 2, 1)
	# Side equipment
	_furniture_block(7, 4, 2, 1)
	# Front doors
	_door(4, 7)
	_door(5, 7)
	labels = [
		["Substation", 3, 0],
		["Transformers", 2, 1],
		["Controls", 4, 5],
	]

func get_furniture() -> Array:
	return [
		["transformer", 1, 1, 3, false, 3, 2],
		["transformer", 5, 1, 3, false, 3, 2],
		["control_desk", 4, 5, 4, false, 2, 1],
		["railing", 1, 4, 3, false, 2, 1],
		["equipment", 7, 4, 4, false, 2, 1],
	]

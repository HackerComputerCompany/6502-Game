extends InteriorMap

# Radio Station (12 wide x 10 tall)
# Broadcast booth, equipment room, front desk

const MAP_W := 12
const MAP_H := 10

const ENTRY_POINTS := {
	"front_door": Vector2(5, 8),
}

const EXITS := {
	Vector2i(5, 9): {"map": "res://overworld/town_map.gd", "entry": "radio_door"},
	Vector2i(6, 9): {"map": "res://overworld/town_map.gd", "entry": "radio_door"},
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
	# Broadcast booth (walled room on left)
	_wall(1, 1, 5, 1, Tile.WALL_GRAY)
	_wall(1, 1, 1, 5, Tile.WALL_GRAY)
	_wall(5, 1, 1, 5, Tile.WALL_GRAY)
	_door(5, 4)
	# Equipment shelves on north wall
	_furniture_block(7, 1, 4, 1)
	# Desk near entrance
	_furniture_block(3, 7, 3, 1)
	# Recording equipment inside booth
	_furniture_block(2, 2, 2, 1)
	_furniture_block(2, 3, 1, 1)
	# Chair in booth
	_furniture_block(4, 3, 1, 1)
	# Broadcast console
	_furniture_block(7, 3, 3, 1)
	_door(5, 9)
	_door(6, 9)
	labels = [
		["Radio Station", 3, 0],
		["Booth", 2, 2],
		["Equipment", 7, 1],
		["Desk", 3, 7],
	]

func get_furniture() -> Array:
	return [
		["desk", 3, 7, 3, true, 3, 1],
		["shelf", 7, 1, 4, true, 4, 1],
		["desk", 2, 2, 3, true, 2, 1],
		["desk", 7, 3, 3, true, 3, 1],
	]

extends InteriorMap

# Barber Shop (9 wide x 8 tall)
# Waiting area near door, 3 barber chairs in middle, mirrors on north wall, back counter

const MAP_W := 9
const MAP_H := 8
const WALL_COLOR: int = Tile.WALL_BEIGE
const ENTRY_POINTS := {
	"front_door": Vector2(4, 6),
}

const EXITS := {
	Vector2i(4, 7): {"map": "res://overworld/town_map.gd", "entry": "barber_door"},
	Vector2i(5, 7): {"map": "res://overworld/town_map.gd", "entry": "barber_door"},
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
	_window(4, 0)
	_window(6, 0)
	# Counter on north side
	_furniture_block(2, 1, 5, 1)
	# Barber chairs in middle
	_furniture_block(2, 3, 1, 1)
	_furniture_block(4, 3, 1, 1)
	_furniture_block(6, 3, 1, 1)
	# Waiting bench near door
	_furniture_block(2, 5, 3, 1)
	# Front doors
	_door(4, 7)
	_door(5, 7)
	labels = [
		["Barber Shop", 3, 0],
		["Chairs", 3, 3],
		["Counter", 3, 1],
	]

func get_furniture() -> Array:
	return [
		["counter", 2, 1, 1, true, 5, 1],
		["chair", 2, 3, 1, false, 1, 1],
		["chair", 4, 3, 1, false, 1, 1],
		["chair", 6, 3, 1, false, 1, 1],
		["bench", 2, 5, 2, false, 3, 1],
	]

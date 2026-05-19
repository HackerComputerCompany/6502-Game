extends InteriorMap

# Phone Company Central Office (10 wide x 10 tall)
# Switchboard equipment along walls, desk near door, equipment racks

const MAP_W := 10
const MAP_H := 10

const ENTRY_POINTS := {
	"front_door": Vector2(5, 9),
}

const EXITS := {
	Vector2i(5, 9): {"map": "res://overworld/town_map.gd", "entry": "phone_co_door"},
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
	_window(9, 3)
	_window(9, 6)
	# Switchboard equipment along north wall
	_furniture_block(1, 1, 3, 1)
	_furniture_block(5, 1, 4, 1)
	# Left wall equipment racks
	_furniture_block(1, 3, 1, 3)
	# Right wall equipment racks
	_furniture_block(8, 3, 1, 3)
	# Center equipment rack
	_furniture_block(4, 4, 2, 2)
	# Desk near door
	_furniture_block(3, 7, 2, 1)
	_door(5, 9)
	labels = [
		["Phone Co.", 3, 0],
		["Switchboard", 1, 1],
		["Equipment", 4, 4],
		["Desk", 3, 7],
	]

func get_furniture() -> Array:
	return [
		["switchboard", 1, 1, 7, true, 3, 1],
		["switchboard", 5, 1, 7, true, 4, 1],
		["rack", 1, 3, 8, false, 1, 3],
		["rack", 8, 3, 8, true, 1, 3],
		["rack", 4, 4, 8, false, 2, 2],
		["desk", 3, 7, 3, false, 2, 1],
	]

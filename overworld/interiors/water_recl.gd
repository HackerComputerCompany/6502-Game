extends InteriorMap

# Water Reclamation (16 wide x 12 tall)
# Control room with terminals, pipes along walls, office in back

const MAP_W := 16
const MAP_H := 12

const ENTRY_POINTS := {
	"front_door": Vector2(7, 10),
}

const EXITS := {
	Vector2i(7, 11): {"map": "res://overworld/town_map.gd", "entry": "water_recl_door"},
	Vector2i(8, 11): {"map": "res://overworld/town_map.gd", "entry": "water_recl_door"},
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
	# Office divider wall
	_wall(10, 1, 1, 5, Tile.WALL_GRAY)
	_door(10, 3)
	# Windows
	_window(2, 0)
	_window(5, 0)
	_window(8, 0)
	_window(13, 0)
	_window(15, 4)
	_window(0, 6)
	_window(0, 3)
	# Control terminals
	_furniture_block(2, 2, 3, 1)
	_furniture_block(6, 2, 3, 1)
	# Pipe blocks along walls
	_furniture_block(1, 1, 1, 5)
	_furniture_block(9, 1, 1, 5)
	# Control desk
	_furniture_block(3, 5, 4, 1)
	# Pipe blocks on south side
	_furniture_block(1, 8, 1, 2)
	_furniture_block(9, 8, 1, 2)
	# Large pipe assembly
	_furniture_block(2, 8, 3, 1)
	_furniture_block(6, 8, 3, 1)
	# Office desk and chair
	_furniture_block(12, 2, 3, 1)
	_furniture_block(12, 4, 2, 1)
	# Office filing cabinet
	_furniture_block(14, 1, 1, 1)
	# Front doors
	_door(7, 11)
	_door(8, 11)
	labels = [
		["Control Room", 3, 1],
		["Pipes", 2, 8],
		["Office", 12, 2],
	]

func get_furniture() -> Array:
	return [
		["terminal", 2, 2, 5, true, 3, 1],
		["terminal", 6, 2, 5, true, 3, 1],
		["pipe", 1, 1, 2, false, 1, 5],
		["pipe", 9, 1, 2, false, 1, 5],
		["control_desk", 3, 5, 4, false, 4, 1],
		["pipe", 1, 8, 3, false, 1, 2],
		["pipe", 9, 8, 3, false, 1, 2],
		["pipe_assembly", 2, 8, 4, false, 3, 1],
		["pipe_assembly", 6, 8, 4, false, 3, 1],
		["office_desk", 12, 2, 5, true, 3, 1],
		["filing_cabinet", 14, 1, 4, false, 1, 1],
		["chair", 12, 4, 4, false, 2, 1],
	]

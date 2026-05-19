extends InteriorMap

# Police Department (9 wide x 9 tall)
# Front desk, holding cell (locked room), office area

const MAP_W := 9
const MAP_H := 9

const ENTRY_POINTS := {
	"front_door": Vector2(4, 8),
}

const EXITS := {
	Vector2i(4, 8): {"map": "res://overworld/town_map.gd", "entry": "police_dept_door"},
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
	_window(0, 4)
	# Front desk near entrance
	_furniture_block(3, 6, 3, 1)
	# Holding cell (walled room in northeast)
	_wall(6, 1, 2, 4, Tile.WALL_GRAY)
	_door(6, 4)
	_furniture_block(7, 2, 1, 2)
	# Office desks
	_furniture_block(1, 2, 2, 1)
	_furniture_block(1, 4, 2, 1)
	_furniture_block(4, 2, 2, 1)
	# Filing cabinets along west wall
	_furniture_block(1, 6, 1, 2)
	_door(4, 8)
	labels = [
		["Police Dept", 2, 0],
		["Cell", 7, 1],
		["Office", 1, 2],
		["Front Desk", 3, 6],
	]

func get_furniture() -> Array:
	return [
		["desk", 3, 6, 3, true, 3, 1],
		["cell_bunk", 7, 2, 6, false, 1, 2],
		["desk", 1, 2, 2, false, 2, 1],
		["desk", 1, 4, 2, false, 2, 1],
		["desk", 4, 2, 2, true, 2, 1],
		["cabinet", 1, 6, 4, false, 1, 2],
	]

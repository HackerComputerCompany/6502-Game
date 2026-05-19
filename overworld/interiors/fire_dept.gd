extends InteriorMap

# Fire Department (8 wide x 8 tall)
# Garage bays on north wall (wall_gray), locker area, desk

const MAP_W := 8
const MAP_H := 8

const ENTRY_POINTS := {
	"front_door": Vector2(4, 7),
}

const EXITS := {
	Vector2i(4, 7): {"map": "res://overworld/town_map.gd", "entry": "fire_dept_door"},
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
	_window(5, 0)
	# Garage bays on north wall (wall_gray)
	_wall(1, 0, 3, 2, Tile.WALL_GRAY)
	# Partition between garage and office
	_wall(1, 3, 6, 1, Tile.WALL_GRAY)
	_door(3, 3)
	# Locker area (left side)
	_furniture_block(1, 4, 1, 2)
	# Desk (right side)
	_furniture_block(5, 4, 2, 1)
	_furniture_block(5, 5, 2, 1)
	# Equipment shelves
	_furniture_block(1, 6, 2, 1)
	_door(4, 7)
	labels = [
		["Fire Dept", 3, 0],
		["Garage", 1, 1],
		["Lockers", 1, 4],
		["Desk", 5, 4],
	]

func get_furniture() -> Array:
	return [
		["garage_bay", 1, 0, 4, false, 3, 2],
		["locker", 1, 4, 4, false, 1, 2],
		["desk", 5, 4, 3, true, 2, 1],
		["desk", 5, 5, 3, true, 2, 1],
		["shelf", 1, 6, 4, false, 2, 1],
	]

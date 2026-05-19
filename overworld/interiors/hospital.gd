extends InteriorMap

# Hospital (14 wide x 12 tall)
# Reception desk, hallway, treatment rooms (walled off), emergency entrance south

const MAP_W := 14
const MAP_H := 12

const ENTRY_POINTS := {
	"front_door": Vector2(7, 11),
}

const EXITS := {
	Vector2i(7, 11): {"map": "res://overworld/town_map.gd", "entry": "hospital_door"},
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
	_window(0, 4)
	_window(13, 4)
	# Treatment room 1 (northeast)
	_wall(9, 1, 4, 4, Tile.WALL_GRAY)
	_door(9, 3)
	_furniture_block(10, 2, 2, 1)
	# Treatment room 2 (northwest)
	_wall(1, 1, 4, 4, Tile.WALL_GRAY)
	_door(4, 3)
	_furniture_block(2, 2, 2, 1)
	# Central hallway walls
	_wall(1, 6, 4, 1, Tile.WALL_GRAY)
	_door(5, 6)
	_wall(9, 6, 4, 1, Tile.WALL_GRAY)
	_door(9, 6)
	# Reception desk
	_furniture_block(5, 8, 4, 1)
	# Waiting area benches
	_furniture_block(1, 8, 2, 1)
	_furniture_block(1, 9, 2, 1)
	# West room furniture
	_furniture_block(2, 6, 2, 1)
	# East room furniture
	_furniture_block(10, 6, 2, 1)
	_door(7, 11)
	labels = [
		["Hospital", 4, 0],
		["Treatment", 2, 1],
		["Treatment", 10, 1],
		["Reception", 5, 8],
		["Waiting", 1, 8],
	]

func get_furniture() -> Array:
	return [
		["bed", 2, 2, 2, false, 2, 1],
		["bed", 10, 2, 2, true, 2, 1],
		["reception", 5, 8, 3, true, 4, 1],
		["bench", 1, 8, 4, false, 2, 1],
		["bench", 1, 9, 4, true, 2, 1],
		["desk", 2, 6, 2, false, 2, 1],
		["desk", 10, 6, 2, true, 2, 1],
	]

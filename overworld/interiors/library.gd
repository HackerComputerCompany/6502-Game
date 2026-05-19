extends InteriorMap

# Library (8 wide x 8 tall)
# Wall shelves along north and west walls, reading tables, desk near door

const MAP_W := 8
const MAP_H := 8
const WALL_COLOR: int = Tile.WALL_BROWN
const ENTRY_POINTS := {
	"front_door": Vector2(4, 7),
}

const EXITS := {
	Vector2i(4, 7): {"map": "res://overworld/maps/town.tscn", "entry": "library_door"},
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
	_window(7, 3)
	# North wall shelves
	_furniture_block(1, 1, 6, 1)
	# West wall shelves
	_furniture_block(1, 2, 1, 4)
	# Reading tables in center
	_furniture_block(3, 3, 2, 1)
	_furniture_block(3, 5, 2, 1)
	# Desk near door
	_furniture_block(5, 6, 2, 1)
	# Front door
	_door(4, 7)
	labels = [
		["Library", 2, 0],
		["Shelves", 1, 1],
		["Reading", 3, 3],
		["Desk", 5, 6],
	]

func get_furniture() -> Array:
	return [
		["shelf", 1, 2, 4, false, 1, 4],
		["shelf", 1, 1, 4, true, 6, 1],
		["table", 3, 3, 2, false, 2, 1],
		["table", 3, 5, 2, false, 2, 1],
		["desk", 5, 6, 3, false, 2, 1],
	]

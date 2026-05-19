extends InteriorMap

# Auto Repair Shop (12 wide x 10 tall)
# Car bay on left, tool shelves on north wall, counter on right, back office

const MAP_W := 12
const MAP_H := 10

const ENTRY_POINTS := {
	"front_door": Vector2(5, 8),
}

const EXITS := {
	Vector2i(5, 9): {"map": "res://overworld/town_map.gd", "entry": "auto_repair_door"},
	Vector2i(6, 9): {"map": "res://overworld/town_map.gd", "entry": "auto_repair_door"},
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
	# Office divider wall
	_wall(7, 1, 1, 4, Tile.WALL_GRAY)
	_door(7, 4)
	# North shelf row
	_furniture_block(1, 1, 5, 1)
	# Counter on right side
	_furniture_block(9, 5, 2, 1)
	# Workbench in office
	_furniture_block(8, 2, 3, 1)
	# Tools shelf in office
	_furniture_block(9, 1, 2, 1)
	# Front doors
	_door(5, 9)
	_door(6, 9)
	labels = [
		["Auto Repair", 3, 0],
		["Bay", 2, 5],
		["Counter", 9, 5],
		["Office", 9, 3],
	]

func get_furniture() -> Array:
	return [
		["shelf", 1, 1, 5, true, 5, 1],
		["workbench", 8, 2, 3, true, 3, 1],
		["shelf", 9, 1, 2, true, 2, 1],
		["counter", 9, 5, 2, false, 2, 1],
	]

extends InteriorMap

# Post Office (9 wide x 8 tall)
# PO boxes along north wall, counter, mail slots

const MAP_W := 9
const MAP_H := 8

const ENTRY_POINTS := {
	"front_door": Vector2(4, 7),
}

const EXITS := {
	Vector2i(4, 7): {"map": "res://overworld/town_map.gd", "entry": "post_office_door"},
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
	_window(8, 3)
	# PO boxes along north wall
	_wall(1, 1, 7, 1, Tile.WALL_GRAY)
	# Counter across middle
	_wall(1, 4, 7, 1, Tile.WALL_BROWN)
	_door(4, 4)
	# Mail slot area (left of counter)
	_furniture_block(1, 5, 2, 1)
	# Scale/desk (right of counter)
	_furniture_block(7, 5, 1, 1)
	_furniture_block(7, 6, 1, 1)
	_door(4, 7)
	labels = [
		["Post Office", 2, 0],
		["PO Boxes", 1, 1],
		["Counter", 2, 4],
		["Mail", 1, 5],
	]

func get_furniture() -> Array:
	return [
		["po_boxes", 1, 1, 4, true, 7, 1],
		["counter", 1, 4, 3, true, 7, 1],
		["mail_slot", 1, 5, 3, false, 2, 1],
		["desk", 7, 5, 3, true, 1, 1],
		["desk", 7, 6, 3, true, 1, 1],
	]

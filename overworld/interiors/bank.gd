extends InteriorMap

# Bank (9 wide x 9 tall)
# Teller windows along back, vault door (wall), marble floor

const MAP_W := 9
const MAP_H := 9

const ENTRY_POINTS := {
	"front_door": Vector2(4, 8),
}

const EXITS := {
	Vector2i(4, 8): {"map": "res://overworld/town_map.gd", "entry": "bank_door"},
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
	_window(1, 0)
	_window(4, 0)
	_window(7, 0)
	# Teller windows wall along north
	_wall(1, 1, 7, 1, Tile.WALL_GRAY)
	# Vault door (sealed wall section on north side)
	_wall(7, 1, 1, 2, Tile.WALL_GRAY)
	# Teller counter
	_wall(1, 3, 5, 1, Tile.WALL_BROWN)
	# Rope stanchions (furniture)
	_furniture_block(2, 5, 1, 1)
	_furniture_block(5, 5, 1, 1)
	_furniture_block(2, 7, 1, 1)
	_furniture_block(5, 7, 1, 1)
	_door(4, 8)
	labels = [
		["Bank", 3, 0],
		["Tellers", 1, 3],
		["Vault", 7, 1],
	]

func get_furniture() -> Array:
	return [
		["teller_window", 1, 3, 3, true, 5, 1],
		["stanchion", 2, 5, 4, false, 1, 1],
		["stanchion", 5, 5, 4, false, 1, 1],
		["stanchion", 2, 7, 4, false, 1, 1],
		["stanchion", 5, 7, 4, false, 1, 1],
		["vault", 7, 1, 5, true, 1, 2],
	]

class_name MapFromScene
extends RefCounted

const _OW = preload("res://overworld/overworld_constants.gd")

## Gameplay adapter for MapRoot scenes — same API as legacy house_map.gd scripts.

var MAP_W: int = 0
var MAP_H: int = 0
var ENTRY_POINTS: Dictionary = {}
var EXITS: Dictionary = {}
var collision: Array = []
var labels: Array = []

var _root: MapRoot
var _tile_enum = preload("res://overworld/town_map.gd").Tile
var _furniture_markers: Array = []

func _init(root: MapRoot) -> void:
	_root = root
	_build_from_scene()

func _build_from_scene() -> void:
	var bounds := _compute_bounds()
	MAP_W = bounds.size.x
	MAP_H = bounds.size.y
	_init_collision_arrays()

	var ground_layer := _root.get_node_or_null("GroundTileMap") as TileMapLayer
	var deco_layer := _root.get_node_or_null("DecorationTileMap") as TileMapLayer
	if ground_layer:
		_fill_collision_from_tilemap(ground_layer)
	if deco_layer:
		_apply_decoration_layer(deco_layer)

	_merge_collision_cache()

	ENTRY_POINTS = _collect_entry_points()
	EXITS = _collect_exits()
	labels = _collect_labels()
	_furniture_markers = _collect_furniture_markers()

func _compute_bounds() -> Rect2i:
	var max_x := 0
	var max_y := 0
	var ground_layer := _root.get_node_or_null("GroundTileMap") as TileMapLayer
	var deco_layer := _root.get_node_or_null("DecorationTileMap") as TileMapLayer
	for layer in [ground_layer, deco_layer]:
		if layer == null:
			continue
		for cell in layer.get_used_cells():
			max_x = maxi(max_x, cell.x + 1)
			max_y = maxi(max_y, cell.y + 1)
	if max_x == 0:
		max_x = 48
	if max_y == 0:
		max_y = 21
	return Rect2i(0, 0, max_x, max_y)

func _merge_collision_cache() -> void:
	var cache := _root.get_node_or_null("CollisionCache") as CollisionCache
	if cache == null or cache.grid.is_empty():
		return
	for y in range(mini(MAP_H, cache.grid.size())):
		for x in range(mini(MAP_W, cache.grid[y].size())):
			if cache.grid[y][x]:
				collision[y][x] = cache.grid[y][x]

func _init_collision_arrays() -> void:
	collision.resize(MAP_H)
	for y in range(MAP_H):
		collision[y] = []
		collision[y].resize(MAP_W)
		for x in range(MAP_W):
			collision[y][x] = 0

func _fill_collision_from_tilemap(layer: TileMapLayer) -> void:
	for cell in layer.get_used_cells():
		var x: int = cell.x
		var y: int = cell.y
		if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
			continue
		if _tile_blocks(layer, cell):
			collision[y][x] = 1

func _apply_decoration_layer(layer: TileMapLayer) -> void:
	for cell in layer.get_used_cells():
		var x: int = cell.x
		var y: int = cell.y
		if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
			continue
		var tid := _get_tile_id(layer, cell)
		if tid == _tile_enum.DOOR:
			collision[y][x] = 0

func _tile_blocks(layer: TileMapLayer, cell: Vector2i) -> bool:
	var tid := _get_tile_id(layer, cell)
	if tid == _tile_enum.DOOR or tid == _tile_enum.BLANK:
		return false
	return tid in [
		_tile_enum.WALL_BROWN, _tile_enum.WALL_BEIGE, _tile_enum.WALL_GRAY,
		_tile_enum.ROOF_RED, _tile_enum.ROOF_GRAY, _tile_enum.WATER,
		_tile_enum.FENCE, _tile_enum.TREE, _tile_enum.SIGN,
	]

func _get_tile_id(layer: TileMapLayer, cell: Vector2i) -> int:
	var src := layer.get_cell_source_id(cell)
	if src < 0:
		return _tile_enum.BLANK
	var atlas := layer.get_cell_atlas_coords(cell)
	return atlas.x

func _collect_entry_points() -> Dictionary:
	var out := {}
	var ep_node := _root.get_node_or_null("EntryPoints")
	if ep_node == null:
		return out
	for child in ep_node.get_children():
		if child is EntryPointMarker:
			var tile := _OW.world_to_tile(child.position)
			var pos := Vector2(tile.x, tile.y)
			if out.has(child.entry_id):
				var existing = out[child.entry_id]
				if existing is Array:
					existing.append(pos)
				else:
					out[child.entry_id] = [existing, pos]
			else:
				out[child.entry_id] = pos
	return out

func _collect_exits() -> Dictionary:
	var out := {}
	var ex_node := _root.get_node_or_null("Exits")
	if ex_node == null:
		return out
	for child in ex_node.get_children():
		if child is ExitMarker:
			out[child.get_exit_key()] = child.get_exit_data()
	return out

func _collect_labels() -> Array:
	var out: Array = []
	var lbl_node := _root.get_node_or_null("Labels")
	if lbl_node == null:
		return out
	for child in lbl_node.get_children():
		if child is Label:
			var lx := _OW.world_to_tile(child.position).x
			var ly := _OW.world_to_tile(child.position).y
			out.append([child.text, lx, ly])
	return out

func _collect_furniture_markers() -> Array:
	var out: Array = []
	var furn_node := _root.get_node_or_null("Furniture")
	if furn_node == null:
		return out
	for child in furn_node.get_children():
		if child is FurnitureMarker:
			out.append(child)
	return out

func get_scene_root() -> MapRoot:
	return _root

func get_furniture() -> Array:
	var out: Array = []
	for m in _furniture_markers:
		out.append(m.to_furniture_array())
	return out

func get_labels() -> Array:
	return labels

func is_passable(x: int, y: int) -> bool:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return false
	if get_decoration(x, y) == _tile_enum.DOOR:
		return true
	return collision[y][x] == 0

func get_ground(x: int, y: int) -> int:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return _tile_enum.PATH
	var ground_layer := _root.get_node_or_null("GroundTileMap") as TileMapLayer
	if ground_layer == null:
		return _tile_enum.PATH
	var src := ground_layer.get_cell_source_id(Vector2i(x, y))
	if src < 0:
		return _tile_enum.PATH
	return ground_layer.get_cell_atlas_coords(Vector2i(x, y)).x

func get_decoration(x: int, y: int) -> int:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return _tile_enum.BLANK
	var deco_layer := _root.get_node_or_null("DecorationTileMap") as TileMapLayer
	if deco_layer == null:
		return _tile_enum.BLANK
	var src := deco_layer.get_cell_source_id(Vector2i(x, y))
	if src < 0:
		return _tile_enum.BLANK
	return deco_layer.get_cell_atlas_coords(Vector2i(x, y)).x

func set_collision_tile(tx: int, ty: int, value: int = 1) -> void:
	if tx >= 0 and tx < MAP_W and ty >= 0 and ty < MAP_H:
		if get_decoration(tx, ty) != _tile_enum.DOOR:
			collision[ty][tx] = value

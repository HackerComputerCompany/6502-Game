extends RefCounted
class_name MapSceneBuilder

## Converts a legacy .gd map script instance into a MapRoot scene tree.

const _OW = preload("res://overworld/overworld_constants.gd")
const TILE_SIZE := _OW.TILE_SIZE

static func build_from_legacy(map_instance: Node, scene_name: String) -> Node2D:
	var Tile := preload("res://overworld/town_map.gd").Tile
	var root := Node2D.new()
	root.name = scene_name
	root.set_script(preload("res://overworld/map_root.gd"))

	var ground := TileMapLayer.new()
	ground.name = "GroundTileMap"
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground.z_index = -10

	var deco := TileMapLayer.new()
	deco.name = "DecorationTileMap"
	deco.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	deco.z_index = -9

	var ts := _load_tileset()
	ground.tile_set = ts
	deco.tile_set = ts

	root.add_child(ground)
	root.add_child(deco)

	var entry_container := Node2D.new()
	entry_container.name = "EntryPoints"
	root.add_child(entry_container)

	var exit_container := Node2D.new()
	exit_container.name = "Exits"
	root.add_child(exit_container)

	var furniture_container := Node2D.new()
	furniture_container.name = "Furniture"
	root.add_child(furniture_container)

	var label_container := Node2D.new()
	label_container.name = "Labels"
	root.add_child(label_container)

	for y in range(map_instance.MAP_H):
		for x in range(map_instance.MAP_W):
			var g: int = map_instance.get_ground(x, y)
			var d: int = map_instance.get_decoration(x, y)
			if g != Tile.BLANK:
				ground.set_cell(Vector2i(x, y), TilesetFactory.SOURCE_ID, Vector2i(g, 0))
			if d != Tile.BLANK:
				deco.set_cell(Vector2i(x, y), TilesetFactory.SOURCE_ID, Vector2i(d, 0))

	if map_instance.get("ENTRY_POINTS"):
		for key in map_instance.ENTRY_POINTS:
			var val = map_instance.ENTRY_POINTS[key]
			if val is Array:
				for pos in val:
					_add_entry_marker(entry_container, "%s_%d_%d" % [key, pos.x, pos.y], key, Vector2i(pos))
			else:
				_add_entry_marker(entry_container, key, key, Vector2i(val))

	if map_instance.get("EXITS"):
		for exit_tile in map_instance.EXITS:
			var data: Dictionary = map_instance.EXITS[exit_tile]
			_add_exit_marker(exit_container, exit_tile, data)

	if map_instance.has_method("get_labels"):
		for label_data in map_instance.get_labels():
			var lbl := Label.new()
			lbl.text = label_data[0]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(1, 1, 0.4))
			lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			lbl.add_theme_constant_override("outline_size", 3)
			lbl.position = Vector2(label_data[1] * TILE_SIZE, label_data[2] * TILE_SIZE)
			label_container.add_child(lbl)

	if map_instance.has_method("get_furniture"):
		for f in map_instance.get_furniture():
			_add_furniture_marker(furniture_container, f)

	var cache := CollisionCache.new()
	cache.name = "CollisionCache"
	cache.copy_from_legacy(map_instance)
	root.add_child(cache)

	return root

static func _load_tileset() -> TileSet:
	var path := "res://overworld/art/tilesets/shared_tileset.tres"
	if ResourceLoader.exists(path):
		return load(path) as TileSet
	return TilesetFactory.build_shared_tileset()

static func _add_entry_marker(parent: Node2D, node_name: String, entry_id: String, tile: Vector2i) -> void:
	var m := EntryPointMarker.new()
	m.name = node_name
	m.entry_id = entry_id
	m.position = _OW.tile_to_world(tile)
	parent.add_child(m)

static func _rewrite_map_path(path: String) -> String:
	match path:
		"res://overworld/house_map.gd":
			return "res://overworld/maps/house.tscn"
		"res://overworld/town_map.gd":
			return "res://overworld/maps/town.tscn"
		"res://overworld/interiors/library.gd":
			return "res://overworld/maps/library.tscn"
	return path

static func _add_exit_marker(parent: Node2D, tile: Vector2i, data: Dictionary) -> void:
	var m := ExitMarker.new()
	m.name = "exit_%d_%d" % [tile.x, tile.y]
	m.tile_x = tile.x
	m.tile_y = tile.y
	m.target_map = _rewrite_map_path(data.get("map", ""))
	m.entry_id = data.get("entry", "")
	m.position = _OW.tile_to_world(tile)
	parent.add_child(m)

static func _add_furniture_marker(parent: Node2D, f: Array) -> void:
	var m := FurnitureMarker.new()
	m.furniture_name = f[0]
	m.position = Vector2(f[1] * TILE_SIZE, f[2] * TILE_SIZE)
	m.z_layer = f[3] if f.size() > 3 else 0
	m.blocks_movement = f[4] if f.size() > 4 else false
	m.tile_width = f[5] if f.size() > 5 else 1
	m.tile_height = f[6] if f.size() > 6 else 1
	m.is_interactive = f[0] in ["desk", "bed", "garbage_can", "garbage_bin", "phone"]
	m.name = "%s_%d_%d" % [f[0], f[1], f[2]]
	parent.add_child(m)

static func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_set_owner_recursive(child, owner)

static func save_scene(root: Node2D, path: String) -> void:
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("pack failed for %s" % path)
		return
	err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("save failed for %s" % path)
	else:
		print("Saved map scene: ", path)

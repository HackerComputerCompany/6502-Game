@tool
extends SceneTree
## Run: godot --path . -s overworld/tools/build_maps.gd
## Generates shared_tileset.tres, house.tscn, library.tscn, town.tscn from legacy scripts.

const TilesetFactoryScript = preload("res://overworld/tileset_factory.gd")
const MapSceneBuilderScript = preload("res://overworld/map_scene_builder.gd")

func _init() -> void:
	print("Building overworld tileset and map scenes...")
	DirAccess.make_dir_recursive_absolute("res://overworld/maps")
	DirAccess.make_dir_recursive_absolute("res://overworld/art/tilesets")

	TilesetFactoryScript.save_shared_tileset()

	_build_map(
		"res://overworld/house_map.gd",
		"House",
		"res://overworld/maps/house.tscn"
	)
	_build_map(
		"res://overworld/interiors/library.gd",
		"Library",
		"res://overworld/maps/library.tscn"
	)
	_build_map(
		"res://overworld/town_map.gd",
		"Town",
		"res://overworld/maps/town.tscn"
	)

	print("Done.")
	quit(0)

func _build_map(script_path: String, scene_name: String, out_path: String) -> void:
	var map_script: GDScript = load(script_path) as GDScript
	var instance: Node = map_script.new()
	var root: Node2D = MapSceneBuilderScript.build_from_legacy(instance, scene_name)
	MapSceneBuilderScript.save_scene(root, out_path)
	instance.free()

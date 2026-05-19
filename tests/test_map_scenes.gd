extends SceneTree

func _init() -> void:
	var passed := 0
	var failed := 0

	# House scene loads and exposes gameplay API
	var house_packed: PackedScene = load("res://overworld/maps/house.tscn") as PackedScene
	if house_packed == null:
		print("FAIL: house.tscn load")
		failed += 1
	else:
		var root: Node2D = house_packed.instantiate() as Node2D
		var adapter = preload("res://overworld/map_from_scene.gd").new(root)
		if adapter.MAP_W != 36 or adapter.MAP_H != 17:
			print("FAIL: house dimensions %dx%d" % [adapter.MAP_W, adapter.MAP_H])
			failed += 1
		elif not adapter.EXITS.has(Vector2i(21, 16)):
			print("FAIL: house front door exit missing")
			failed += 1
		elif adapter.EXITS[Vector2i(21, 16)].map != "res://overworld/maps/town.tscn":
			print("FAIL: house exit target %s" % adapter.EXITS[Vector2i(21, 16)].map)
			failed += 1
		elif not adapter.ENTRY_POINTS.has("your_room"):
			print("FAIL: house your_room entry missing")
			failed += 1
		else:
			print("PASS: house.tscn adapter")
			passed += 1
		root.free()

	# Library template scene
	var lib_packed: PackedScene = load("res://overworld/maps/library.tscn") as PackedScene
	if lib_packed == null:
		print("FAIL: library.tscn load")
		failed += 1
	else:
		var root2: Node2D = lib_packed.instantiate() as Node2D
		var adapter2 = preload("res://overworld/map_from_scene.gd").new(root2)
		if adapter2.MAP_W != 8 or adapter2.MAP_H != 8:
			print("FAIL: library dimensions")
			failed += 1
		else:
			print("PASS: library.tscn adapter")
			passed += 1
		root2.free()

	# Shared tileset exists
	if ResourceLoader.exists("res://overworld/art/tilesets/shared_tileset.tres"):
		print("PASS: shared_tileset.tres exists")
		passed += 1
	else:
		print("FAIL: shared_tileset.tres missing")
		failed += 1

	print("\nMap scene tests: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

extends SceneTree

func _init() -> void:
	print("=== Overworld Scene Load Test ===\n")

	var tscn = load("res://overworld/overworld.tscn")
	if tscn == null:
		print("FAIL: Could not load overworld.tscn")
		quit(1)
		return
	print("OK: overworld.tscn loaded")

	var instance = tscn.instantiate()
	if instance == null:
		print("FAIL: Could not instantiate overworld.tscn")
		quit(1)
		return
	print("OK: overworld.tscn instantiated")

	root.add_child(instance)
	print("OK: overworld added to scene tree")

	print("\nAll checks passed")
	quit(0)

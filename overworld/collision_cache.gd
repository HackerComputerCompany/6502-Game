extends Node
class_name CollisionCache

## Stores legacy per-tile collision grid (furniture blocks, etc.) for scene-based maps.

var grid: Array = []

func copy_from_legacy(map_instance: Node) -> void:
	if not map_instance.get("collision"):
		return
	grid = map_instance.collision.duplicate(true)

@tool
extends Marker2D
class_name ExitMarker

@export var target_map: String = ""
@export var entry_id: String = ""
@export var tile_x: int = 0
@export var tile_y: int = 0

func get_exit_key() -> Vector2i:
	return Vector2i(tile_x, tile_y)

func get_exit_data() -> Dictionary:
	return {"map": target_map, "entry": entry_id}

@tool
extends Marker2D
class_name EntryPointMarker

@export var entry_id: String = ""

func _ready() -> void:
	if entry_id == "":
		entry_id = name

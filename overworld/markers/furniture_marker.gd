@tool
class_name FurnitureMarker
extends Node2D

const _OW = preload("res://overworld/overworld_constants.gd")

@export var furniture_name: String = ""
@export var blocks_movement: bool = false
@export var tile_width: int = 1
@export var tile_height: int = 1
@export var z_layer: int = 0
@export var is_interactive: bool = false

func to_furniture_array() -> Array:
	return [furniture_name, tile_x(), tile_y(), z_layer, blocks_movement, tile_width, tile_height]

func tile_x() -> int:
	return _OW.world_to_tile(position).x

func tile_y() -> int:
	return _OW.world_to_tile(position).y

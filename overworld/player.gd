extends CharacterBody2D

const _OW = preload("res://overworld/overworld_constants.gd")
const _Procgen = preload("res://overworld/procgen_assets.gd")
const SPEED: float = 48.0

var facing: Vector2 = Vector2(0, 1)
var moving: bool = false
var can_move: bool = true

var _sprite: Sprite2D
var _collision: CollisionShape2D
var _input_dir: Vector2 = Vector2.ZERO
var _ps = null
var _facing_flip_h: bool = false

func _get_ps():
	if _ps == null:
		_ps = preload("res://scripts/player_state.gd").resolve()
	return _ps

func _ready() -> void:
	var sw := _OW.SPRITE_W
	var sh := _OW.SPRITE_H

	_collision = CollisionShape2D.new()
	_collision.shape = RectangleShape2D.new()
	_collision.shape.size = Vector2(sw * 0.65, sh * 0.5)
	_collision.position = Vector2(0, -sh * 0.25)
	add_child(_collision)

	_sprite = Sprite2D.new()
	_sprite.name = "PlayerSprite"
	_sprite.texture = _Procgen.player_texture()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position = Vector2(-sw / 2.0, -sh)
	add_child(_sprite)

	position = _OW.tile_to_world(
		Vector2i(int(_get_ps().overworld_position.x), int(_get_ps().overworld_position.y))
	)
	_update_map_pos()

func forward_input(event: InputEvent) -> void:
	if not can_move:
		return
	if event is InputEventKey:
		if event.pressed and not event.echo:
			match event.keycode:
				KEY_LEFT, KEY_A:
					_input_dir.x = -1
				KEY_RIGHT, KEY_D:
					_input_dir.x = 1
				KEY_UP, KEY_W:
					_input_dir.y = -1
				KEY_DOWN, KEY_S:
					_input_dir.y = 1
		elif not event.pressed:
			match event.keycode:
				KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D:
					_input_dir.x = 0
				KEY_UP, KEY_W, KEY_DOWN, KEY_S:
					_input_dir.y = 0

func _physics_process(delta: float) -> void:
	if not can_move:
		moving = false
		return
	if _input_dir != Vector2.ZERO:
		facing = _input_dir
		var target := position + _input_dir.normalized() * SPEED * delta
		if _would_pass(target):
			position = target
		moving = true
	else:
		moving = false
	_update_animation()
	_update_map_pos()

func _would_pass(target: Vector2) -> bool:
	var map = _get_map_data()
	if map == null:
		return true
	var tile := _OW.world_to_tile(target)
	return map.is_passable(tile.x, tile.y)

func _get_map_data():
	var overworld := get_parent()
	if overworld and overworld.has_method("get_map_data"):
		return overworld.get_map_data()
	return null

func _update_animation() -> void:
	if facing.x < 0:
		_facing_flip_h = true
	elif facing.x > 0:
		_facing_flip_h = false
	_sprite.flip_h = _facing_flip_h

func _update_map_pos() -> void:
	var tile := _OW.world_to_tile(position)
	_get_ps().overworld_position = Vector2(tile.x, tile.y)

func interact_front_tile() -> Vector2i:
	var tile := _OW.world_to_tile(position)
	var fx := int(round(facing.x))
	var fy := int(round(facing.y))
	return Vector2i(tile.x + fx, tile.y + fy)
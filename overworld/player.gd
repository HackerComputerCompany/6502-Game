extends CharacterBody2D

const SPEED: float = 144.0
const TILE_SIZE: int = 32
const PLAYER_W: int = 32
const PLAYER_H: int = 64

var facing: Vector2 = Vector2(0, 1)
var moving: bool = false
var can_move: bool = true

var _sprite: Sprite2D
var _anim: AnimationPlayer
var _collision: CollisionShape2D
var _input_dir: Vector2 = Vector2.ZERO
var _ps = null

func _get_ps():
	if _ps == null:
		if Engine.has_singleton("PlayerState"):
			_ps = Engine.get_singleton("PlayerState")
		else:
			_ps = preload("res://scripts/player_state.gd").new()
	return _ps

func _ready() -> void:
	_collision = CollisionShape2D.new()
	_collision.shape = RectangleShape2D.new()
	_collision.shape.size = Vector2(PLAYER_W * 0.75, PLAYER_H * 0.5)
	_collision.position = Vector2(0, PLAYER_H * 0.15)
	add_child(_collision)

	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	var img := Image.create(PLAYER_W, PLAYER_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.9, 0.15, 0.15))
	var tex := ImageTexture.create_from_image(img)
	_sprite.texture = tex
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.offset = Vector2(0, -PLAYER_H * 0.25)
	add_child(_sprite)

	_anim = AnimationPlayer.new()
	_anim.name = "AnimationPlayer"
	add_child(_anim)
	_make_walk_animation()

	position = Vector2(
		_get_ps().overworld_position.x * TILE_SIZE + TILE_SIZE / 2,
		_get_ps().overworld_position.y * TILE_SIZE + TILE_SIZE / 2
	)
	_update_map_pos()

func _make_walk_animation() -> void:
	var anim := Animation.new()
	anim.length = 0.4
	anim.loop_mode = Animation.LOOP_LINEAR
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, "Sprite2D:position:y")
	anim.track_insert_key(track, 0.0, 0.0)
	anim.track_insert_key(track, 0.2, -4.0 * (PLAYER_H / 64.0))
	anim.track_insert_key(track, 0.4, 0.0)
	var lib = AnimationLibrary.new()
	lib.add_animation("walk", anim)
	_anim.add_animation_library("", lib)

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
	var tx := int(target.x / TILE_SIZE)
	var ty := int(target.y / TILE_SIZE)
	return map.is_passable(tx, ty)

func _get_map_data():
	var overworld := get_parent()
	if overworld and overworld.has_method("get_map_data"):
		return overworld.get_map_data()
	return null

func _update_animation() -> void:
	if moving:
		if not _anim.is_playing():
			_anim.play("walk")
	else:
		_anim.stop()
	if facing.x < 0:
		_sprite.flip_h = true
	elif facing.x > 0:
		_sprite.flip_h = false

func _update_map_pos() -> void:
	var tx := int(position.x / TILE_SIZE)
	var ty := int(position.y / TILE_SIZE)
	_get_ps().overworld_position = Vector2(tx, ty)

func interact_front_tile() -> Vector2i:
	var tx := int(position.x / TILE_SIZE)
	var ty := int(position.y / TILE_SIZE)
	var fx := int(round(facing.x))
	var fy := int(round(facing.y))
	return Vector2i(tx + fx, ty + fy)

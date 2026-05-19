extends CharacterBody2D

const _OW = preload("res://overworld/overworld_constants.gd")
const GABE_SHEET := preload(
	"res://overworld/art/tilesets/generic-rpg/generic-rpg-pack_v0.4_(alpha-release)_vacaroxa/rpg-pack/chars/gabe/gabe-idle-run.png"
)
const GABE_FRAME_W := 24
const GABE_FRAME_H := 24
const SPEED: float = 72.0

var facing: Vector2 = Vector2(0, 1)
var moving: bool = false
var can_move: bool = true

var _sprite: AnimatedSprite2D
var _collision: CollisionShape2D
var _input_dir: Vector2 = Vector2.ZERO
var _ps = null
var _facing_flip_h: bool = false

func _get_ps():
	if _ps == null:
		_ps = preload("res://scripts/player_state.gd").resolve()
	return _ps

func _ready() -> void:
	_collision = CollisionShape2D.new()
	_collision.shape = RectangleShape2D.new()
	_collision.shape.size = Vector2(GABE_FRAME_W * 0.65, 8)
	_collision.position = Vector2(0, -4)
	add_child(_collision)

	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.sprite_frames = _build_gabe_sprite_frames()
	_sprite.animation = &"idle"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	_sprite.position = Vector2(-GABE_FRAME_W / 2.0, -GABE_FRAME_H)
	add_child(_sprite)

	position = _OW.tile_to_world(
		Vector2i(int(_get_ps().overworld_position.x), int(_get_ps().overworld_position.y))
	)
	_update_map_pos()

static func _build_gabe_sprite_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation(&"idle")
	sf.set_animation_loop(&"idle", true)
	sf.set_animation_speed(&"idle", 1.0)
	var idle_frame := AtlasTexture.new()
	idle_frame.atlas = GABE_SHEET
	idle_frame.region = Rect2(0, 0, GABE_FRAME_W, GABE_FRAME_H)
	sf.add_frame(&"idle", idle_frame)

	sf.add_animation(&"walk")
	sf.set_animation_loop(&"walk", true)
	sf.set_animation_speed(&"walk", 10.0)
	for i in range(7):
		var frame_tex := AtlasTexture.new()
		frame_tex.atlas = GABE_SHEET
		frame_tex.region = Rect2(i * GABE_FRAME_W, 0, GABE_FRAME_W, GABE_FRAME_H)
		sf.add_frame(&"walk", frame_tex)
	return sf

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
	if moving:
		if _sprite.animation != &"walk":
			_sprite.play(&"walk")
	elif _sprite.animation != &"idle":
		_sprite.play(&"idle")

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

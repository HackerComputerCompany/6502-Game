extends Node2D

const _OW = preload("res://overworld/overworld_constants.gd")
const _PlayerStateScript = preload("res://scripts/player_state.gd")
const _Procgen = preload("res://overworld/procgen_assets.gd")

var npc_name: String = ""
var dialogue: Array = []
var quest_flag_required: String = ""
var quest_flag_set: String = ""
var item_given: String = ""
var appearance: int = 0
var facing_left: bool = false

var _sprite: Sprite2D
var _label: Label
var _bubble: ColorRect
var _bubble_dot1: ColorRect
var _bubble_dot2: ColorRect
var _bubble_dot3: ColorRect
var _player_state = null

func get_player_state():
	if _player_state == null:
		_player_state = _PlayerStateScript.resolve()
	return _player_state

func _ready() -> void:
	var sw := _OW.SPRITE_W
	var sh := _OW.SPRITE_H

	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	_sprite.texture = _Procgen.npc_texture(appearance)
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position = Vector2(-sw / 2, -sh)
	if facing_left:
		_sprite.flip_h = true
	add_child(_sprite)

	_label = Label.new()
	_label.name = "NameLabel"
	_label.text = npc_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(1, 1, 0.4))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 2)
	_label.position = Vector2(-24, -sh - 14)
	_label.size = Vector2(48, 12)
	add_child(_label)

	_bubble = ColorRect.new()
	_bubble.name = "BubbleBg"
	_bubble.size = Vector2(12, 10)
	_bubble.color = Color(1, 1, 1)
	_bubble.position = Vector2(10, -sh - 6)
	add_child(_bubble)

	_bubble_dot1 = ColorRect.new()
	_bubble_dot1.size = Vector2(2, 2)
	_bubble_dot1.color = Color(0, 0, 0)
	_bubble_dot1.position = Vector2(12, -sh - 2)
	add_child(_bubble_dot1)

	_bubble_dot2 = ColorRect.new()
	_bubble_dot2.size = Vector2(2, 2)
	_bubble_dot2.color = Color(0, 0, 0)
	_bubble_dot2.position = Vector2(14, -sh - 2)
	add_child(_bubble_dot2)

	_bubble_dot3 = ColorRect.new()
	_bubble_dot3.size = Vector2(2, 2)
	_bubble_dot3.color = Color(0, 0, 0)
	_bubble_dot3.position = Vector2(16, -sh - 2)
	add_child(_bubble_dot3)

	_bubble.visible = false
	_bubble_dot1.visible = false
	_bubble_dot2.visible = false
	_bubble_dot3.visible = false

func setup(name_str: String, dia: Array, app: int = 0, quest_req: String = "", quest_set: String = "", item: String = "") -> void:
	npc_name = name_str
	dialogue = dia
	appearance = app
	quest_flag_required = quest_req
	quest_flag_set = quest_set
	item_given = item
	if _label:
		_label.text = name_str
	if _sprite:
		_sprite.texture = _Procgen.npc_texture(appearance)

func get_dialogue() -> Array:
	var result: Array = []
	for entry in dialogue:
		var flag = entry.get("require_flag", "")
		var no_flag = entry.get("require_no_flag", "")
		if flag != "" and not get_player_state().get_quest_flag(flag):
			continue
		if no_flag != "" and get_player_state().get_quest_flag(no_flag):
			continue
		result.append(entry)
	return result

func show_bubble(show: bool) -> void:
	if _bubble:
		_bubble.visible = show
		_bubble_dot1.visible = show
		_bubble_dot2.visible = show
		_bubble_dot3.visible = show

func on_interacted(dialogue_box) -> void:
	var active_dialogue := get_dialogue()
	if active_dialogue.is_empty():
		return
	dialogue_box.show_sequence(active_dialogue, _on_dialogue_done)

func _on_dialogue_done() -> void:
	if quest_flag_set != "":
		get_player_state().set_quest_flag(quest_flag_set)
	if item_given != "":
		get_player_state().add_item(item_given)

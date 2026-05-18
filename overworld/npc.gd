extends Node2D

const _PlayerStateScript = preload("res://scripts/player_state.gd")

var npc_name: String = ""
var dialogue: Array = []
var quest_flag_required: String = ""
var quest_flag_set: String = ""
var item_given: String = ""
var appearance: int = 0
var facing_left: bool = false

var _sprite: ColorRect
var _border: ColorRect
var _label: Label
var _bubble: ColorRect
var _bubble_dot1: ColorRect
var _bubble_dot2: ColorRect
var _bubble_dot3: ColorRect
var _player_state = null

const NPC_COLORS := [
	Color(0.6, 0.4, 0.8),
	Color(0.4, 0.6, 0.9),
	Color(0.8, 0.5, 0.3),
	Color(0.5, 0.8, 0.5),
	Color(0.9, 0.4, 0.4),
	Color(0.4, 0.8, 0.8),
	Color(0.9, 0.7, 0.3),
	Color(0.7, 0.3, 0.6),
]

func get_player_state():
	if _player_state == null:
		if Engine.has_singleton("PlayerState"):
			_player_state = Engine.get_singleton("PlayerState")
		else:
			_player_state = _PlayerStateScript.new()
	return _player_state

func _ready() -> void:
	var color: Color = NPC_COLORS[appearance % NPC_COLORS.size()]

	_border = ColorRect.new()
	_border.name = "Border"
	_border.size = Vector2(34, 34)
	_border.color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5)
	_border.position = Vector2(-17, -33)
	add_child(_border)

	_sprite = ColorRect.new()
	_sprite.name = "Sprite2D"
	_sprite.size = Vector2(32, 32)
	_sprite.color = color
	_sprite.position = Vector2(-16, -32)
	add_child(_sprite)

	_label = Label.new()
	_label.name = "NameLabel"
	_label.text = npc_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(1, 1, 0.4))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 2)
	_label.position = Vector2(-24, -46)
	_label.size = Vector2(48, 14)
	add_child(_label)

	_bubble = ColorRect.new()
	_bubble.name = "BubbleBg"
	_bubble.size = Vector2(14, 12)
	_bubble.color = Color(1, 1, 1)
	_bubble.position = Vector2(18, -38)
	add_child(_bubble)

	_bubble_dot1 = ColorRect.new()
	_bubble_dot1.size = Vector2(2, 2)
	_bubble_dot1.color = Color(0, 0, 0)
	_bubble_dot1.position = Vector2(21, -34)
	add_child(_bubble_dot1)

	_bubble_dot2 = ColorRect.new()
	_bubble_dot2.size = Vector2(2, 2)
	_bubble_dot2.color = Color(0, 0, 0)
	_bubble_dot2.position = Vector2(24, -34)
	add_child(_bubble_dot2)

	_bubble_dot3 = ColorRect.new()
	_bubble_dot3.size = Vector2(2, 2)
	_bubble_dot3.color = Color(0, 0, 0)
	_bubble_dot3.position = Vector2(27, -34)
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
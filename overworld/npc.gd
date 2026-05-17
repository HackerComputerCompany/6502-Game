extends Node2D

const _PlayerStateScript = preload("res://scripts/player_state.gd")

var npc_name: String = ""
var dialogue: Array = []
var quest_flag_required: String = ""
var quest_flag_set: String = ""
var item_given: String = ""
var appearance: int = 0
var facing_left: bool = false

var _sprite: Sprite2D
var _player_state = null

const NPC_SPRITES := [
	"res://overworld/characters/soldier_blue_idle16.png",
	"res://overworld/characters/mage_cyan_idle16.png",
	"res://overworld/characters/soldier_yellow_idle16.png",
	"res://overworld/characters/archer_green_idle16.png",
	"res://overworld/characters/character_base_idle16.png",
]

func get_player_state():
	if _player_state == null:
		if Engine.has_singleton("PlayerState"):
			_player_state = Engine.get_singleton("PlayerState")
		else:
			_player_state = _PlayerStateScript.new()
	return _player_state

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	_sprite.texture = load(NPC_SPRITES[appearance % NPC_SPRITES.size()])
	_sprite.centered = true
	_sprite.flip_h = facing_left
	add_child(_sprite)

func setup(name_str: String, dia: Array, app: int = 0, quest_req: String = "", quest_set: String = "", item: String = "") -> void:
	npc_name = name_str
	dialogue = dia
	appearance = app
	quest_flag_required = quest_req
	quest_flag_set = quest_set
	item_given = item

func get_dialogue() -> Array:
	var result: Array = []
	for entry in dialogue:
		var flag = entry.get("require_flag", "")
		var no_flag = entry.get("require_no_flag", "")
		if flag != "" and not 	get_player_state().get_quest_flag(flag):
			continue
		if no_flag != "" and get_player_state().get_quest_flag(no_flag):
			continue
		result.append(entry)
	return result

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

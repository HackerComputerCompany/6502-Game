extends Node

var player_name: String = ""
var player_money: int = 5

var skills: Dictionary = {
	basic_programming = 0.0,
	assembly = 0.0,
	electronics = 0.0,
	phreaking = 0.0,
	social_engineering = 0.0,
}

var inventory: Array[Dictionary] = []
var phone_contacts: Dictionary = {}
var bbs_accounts: Dictionary = {}
var floppy_disks: Dictionary = {}

var quest_flags: Dictionary = {}
var current_chapter: int = 1
var current_year: int = 1985

var game_time_hour: float = 9.0
var game_time_minute: float = 0.0

var overworld_position: Vector2 = Vector2(16, 5)
var overworld_scene: String = "bedroom"
var current_map: String = "res://overworld/house_map.gd"

var terminal_unlocked: bool = true
var current_quest: String = ""

func has_item(item_name: String) -> bool:
	for item in inventory:
		if item.get("name", "") == item_name:
			return true
	return false

func add_item(item_name: String, description: String = "") -> void:
	if not has_item(item_name):
		inventory.append({"name": item_name, "description": description})

func remove_item(item_name: String) -> void:
	for i in range(inventory.size()):
		if inventory[i].get("name", "") == item_name:
			inventory.remove_at(i)
			return

func set_quest_flag(flag: String, value = true) -> void:
	quest_flags[flag] = value

func get_quest_flag(flag: String, default = false):
	return quest_flags.get(flag, default)

func advance_time(hours: float = 0.0) -> void:
	game_time_hour += hours
	if game_time_hour >= 24.0:
		game_time_hour -= 24.0

func get_time_string() -> String:
	var h := int(game_time_hour)
	var m := int(game_time_minute)
	var ampm := "AM"
	var dh := h
	if dh >= 12:
		ampm = "PM"
		if dh > 12:
			dh -= 12
	if dh == 0:
		dh = 12
	return "%d:%02d %s" % [dh, m, ampm]

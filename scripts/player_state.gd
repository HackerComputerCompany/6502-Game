extends Node

var player_name: String = ""
var player_money: float = 3.25

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

const START_YEAR: int = 1985
const START_MONTH: int = 6
const START_DAY: int = 15
const START_WEEKDAY: int = 6
const WEEKDAY_NAMES: Array = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const MONTH_NAMES: Array = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
const DAYS_IN_MONTH: Array = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

var game_time_hour: float = 9.0
var game_time_minute: float = 0.0
var game_day: int = 0

var current_year: int = START_YEAR
var current_month: int = START_MONTH
var current_day_of_month: int = START_DAY
var current_weekday: int = START_WEEKDAY

var overworld_position: Vector2 = Vector2(12, 6)
var overworld_scene: String = "bedroom"
var current_map: String = "res://overworld/maps/house.tscn"

var terminal_unlocked: bool = true
var current_quest: String = ""

var garbage_taken_out: bool = false
var room_clean: bool = false
var allowance_collected: bool = false
var last_allowance_day: int = -1

const GAME_MINUTES_PER_REAL_SECOND: float = 0.6

static func resolve() -> Node:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		var node = tree.root.get_node_or_null("PlayerState")
		if node != null:
			return node
	return load("res://scripts/player_state.gd").new()

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
	while game_time_hour >= 24.0:
		game_time_hour -= 24.0
		_advance_day()

func advance_minutes(minutes: float) -> void:
	game_time_minute += minutes
	while game_time_minute >= 60.0:
		game_time_minute -= 60.0
		game_time_hour += 1.0
	while game_time_hour >= 24.0:
		game_time_hour -= 24.0
		_advance_day()

func tick_game_time(delta: float) -> void:
	game_time_minute += delta * GAME_MINUTES_PER_REAL_SECOND
	while game_time_minute >= 60.0:
		game_time_minute -= 60.0
		game_time_hour += 1.0
	while game_time_hour >= 24.0:
		game_time_hour -= 24.0
		_advance_day()

func _advance_day() -> void:
	game_day += 1
	current_day_of_month += 1
	current_weekday = (current_weekday + 1) % 7
	var dim: int = DAYS_IN_MONTH[current_month - 1]
	if current_month == 2 and _is_leap_year(current_year):
		dim = 29
	if current_day_of_month > dim:
		current_day_of_month = 1
		current_month += 1
		if current_month > 12:
			current_month = 1
			current_year += 1
	_check_allowance()

func _is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

func _check_allowance() -> void:
	if current_weekday == 0 and game_time_hour >= 7.0:
		if last_allowance_day != game_day:
			if garbage_taken_out and room_clean:
				player_money += 5.0
				allowance_collected = true
				last_allowance_day = game_day
	garbage_taken_out = false
	room_clean = false

func get_time_string() -> String:
	var h: int = int(game_time_hour)
	var m: int = int(game_time_minute / 10.0) * 10
	var ampm := "AM"
	var dh := h
	if dh >= 12:
		ampm = "PM"
		if dh > 12:
			dh -= 12
	if dh == 0:
		dh = 12
	return "%d:%02d %s" % [dh, m, ampm]

func get_date_string() -> String:
	return "%s, %s %d, %d" % [WEEKDAY_NAMES[current_weekday], MONTH_NAMES[current_month - 1], current_day_of_month, current_year]

func get_short_date_string() -> String:
	return "%s %d" % [MONTH_NAMES[current_month - 1].left(3), current_day_of_month]

func is_daytime() -> bool:
	return game_time_hour >= 6.0 and game_time_hour < 21.0

func is_nighttime() -> bool:
	return game_time_hour >= 21.0 or game_time_hour < 6.0

func get_daylight_factor() -> float:
	if game_time_hour >= 7.0 and game_time_hour < 18.0:
		return 1.0
	if game_time_hour >= 18.0 and game_time_hour < 21.0:
		return 1.0 - (game_time_hour - 18.0) / 3.0
	if game_time_hour >= 5.0 and game_time_hour < 7.0:
		return (game_time_hour - 5.0) / 2.0
	return 0.0

func add_skill_xp(skill: String, amount: float) -> void:
	if skills.has(skill):
		skills[skill] = min(skills[skill] + amount, 100.0)

func add_money(amount: float) -> void:
	player_money += amount
	if player_money < 0.0:
		player_money = 0.0

func get_hacker_level() -> int:
	var total := 0.0
	for skill in skills:
		total += skills[skill]
	var avg: float = total / float(max(skills.size(), 1))
	return int(avg)

func get_hacker_rank() -> String:
	var level := get_hacker_level()
	if level < 16:
		return "Script Kiddie"
	elif level < 31:
		return "Novice"
	elif level < 51:
		return "Hacker"
	elif level < 71:
		return "Elite"
	elif level < 91:
		return "Guru"
	else:
		return "Legend"

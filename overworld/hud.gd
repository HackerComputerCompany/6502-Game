extends CanvasLayer

var _money_label: Label
var _time_label: Label
var _date_label: Label
var _quest_label: Label
var _skills_label: Label
var _title_label: Label
var _background: ColorRect
var _ps = null

func _get_ps():
	if _ps == null:
		if Engine.has_singleton("PlayerState"):
			_ps = Engine.get_singleton("PlayerState")
		else:
			_ps = preload("res://scripts/player_state.gd").new()
	return _ps

func _ready() -> void:
	_background = ColorRect.new()
	_background.color = Color(0, 0, 0, 0.65)
	_background.size = Vector2(640, 28)
	_background.position = Vector2(0, 0)
	add_child(_background)

	var bar_y := 4.0

	_title_label = Label.new()
	_title_label.text = "SIGNAL.ZERO"
	_title_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title_label.add_theme_constant_override("outline_size", 3)
	_title_label.position = Vector2(8, bar_y)
	_title_label.size = Vector2(140, 22)
	add_child(_title_label)

	_money_label = Label.new()
	_money_label.add_theme_color_override("font_color", Color(1, 1, 0.4))
	_money_label.add_theme_font_size_override("font_size", 16)
	_money_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_money_label.add_theme_constant_override("outline_size", 3)
	_money_label.position = Vector2(150, bar_y)
	_money_label.size = Vector2(100, 22)
	add_child(_money_label)

	_time_label = Label.new()
	_time_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	_time_label.add_theme_font_size_override("font_size", 16)
	_time_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_time_label.add_theme_constant_override("outline_size", 3)
	_time_label.position = Vector2(260, bar_y)
	_time_label.size = Vector2(120, 22)
	add_child(_time_label)

	_date_label = Label.new()
	_date_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_date_label.add_theme_font_size_override("font_size", 16)
	_date_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_date_label.add_theme_constant_override("outline_size", 3)
	_date_label.position = Vector2(380, bar_y)
	_date_label.size = Vector2(120, 22)
	add_child(_date_label)

	_skills_label = Label.new()
	_skills_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_skills_label.add_theme_font_size_override("font_size", 16)
	_skills_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_skills_label.add_theme_constant_override("outline_size", 3)
	_skills_label.position = Vector2(510, bar_y)
	_skills_label.size = Vector2(130, 22)
	add_child(_skills_label)

	_quest_label = Label.new()
	_quest_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	_quest_label.add_theme_font_size_override("font_size", 16)
	_quest_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_quest_label.add_theme_constant_override("outline_size", 3)
	_quest_label.position = Vector2(8, 32)
	_quest_label.size = Vector2(300, 22)
	add_child(_quest_label)

	_quest_label.visible = false

func _process(_delta: float) -> void:
	var ps = _get_ps()
	if ps == null:
		return

	var money: float = ps.player_money
	_money_label.text = "$%.2f" % money
	_time_label.text = ps.get_time_string()
	_date_label.text = ps.get_short_date_string() + " " + ps.WEEKDAY_NAMES[ps.current_weekday].left(3)

	var rank: String = ps.get_hacker_rank()
	var skills: Dictionary = ps.skills
	var top_skill: String = ""
	var top_val: float = -1.0
	for skill_name in skills:
		if skills[skill_name] > top_val:
			top_val = skills[skill_name]
			top_skill = str(skill_name)

	if top_val > 0:
		_skills_label.text = "%s [%s]" % [rank, top_skill.left(4).to_upper()]
	else:
		_skills_label.text = rank

	if ps.current_quest != "":
		_quest_label.text = ps.current_quest
		_quest_label.visible = true
		_background.size = Vector2(640, 54)
	else:
		_quest_label.visible = false
		_background.size = Vector2(640, 28)
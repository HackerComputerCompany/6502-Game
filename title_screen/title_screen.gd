extends Control

const TITLE_FONT := preload("res://fonts/pressstart2p.ttf")

@onready var _start_btn := $VBoxContainer/StartBtn
@onready var _load_btn := $VBoxContainer/LoadBtn
@onready var _title_label := $VBoxContainer/TitleLabel
@onready var _subtitle_label := $VBoxContainer/SubtitleLabel
@onready var _blink := $VBoxContainer/BlinkLabel

func _ready() -> void:
	_title_label.add_theme_font_override("font", TITLE_FONT)
	_subtitle_label.add_theme_font_override("font", TITLE_FONT)
	_start_btn.add_theme_font_override("font", TITLE_FONT)
	_load_btn.add_theme_font_override("font", TITLE_FONT)
	_blink.add_theme_font_override("font", TITLE_FONT)

	_start_btn.grab_focus()
	var tween := create_tween().set_loops()
	tween.tween_property(_blink, "modulate", Color(0.3, 0.3, 0.4, 0.0), 0.5)
	tween.tween_property(_blink, "modulate", Color(0.3, 0.3, 0.4, 1.0), 0.5)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_on_start_pressed()

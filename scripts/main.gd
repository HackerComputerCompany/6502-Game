extends Control

var _program_text: String = ""

func _ready() -> void:
	$VBoxContainer/InputLine.grab_focus()

func _process(_delta: float) -> void:
	pass
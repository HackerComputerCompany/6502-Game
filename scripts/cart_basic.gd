class_name CartBasic
extends ROMCart

func _init() -> void:
	id = 0
	name = "BASIC"
	description = "BASIC6502 interpreter, demos, and 6502 ROM routines"
	prompt = "READY."

func install() -> void:
	computer.rom = ROM.new(memory)

func uninstall() -> void:
	pass

func handle_command(_text: String) -> bool:
	return false

func banner_text() -> String:
	return ""

func serialize() -> Dictionary:
	return {}

func deserialize(_data: Dictionary) -> void:
	pass

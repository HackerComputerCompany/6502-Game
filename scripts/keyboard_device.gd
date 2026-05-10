extends "res://scripts/io_device.gd"

var _input_buffer: String = ""
var _input_pos: int = 0

const ADDR_DATA = 0xC000
const ADDR_STATUS = 0xC001

func _init() -> void:
	name = "Keyboard"

func handles_address(addr: int) -> bool:
	return addr == ADDR_DATA or addr == ADDR_STATUS

func peek(addr: int) -> int:
	if addr == ADDR_STATUS:
		return 1 if _input_pos < _input_buffer.length() else 0
	if addr == ADDR_DATA:
		if _input_pos < _input_buffer.length():
			var ch = _input_buffer.unicode_at(_input_pos)
			_input_pos += 1
			return ch
		return 0
	return 0

func push_input(text: String) -> void:
	_input_buffer += text + "\n"
	_input_pos = 0

func clear_input() -> void:
	_input_buffer = ""
	_input_pos = 0

func reset() -> void:
	_input_buffer = ""
	_input_pos = 0

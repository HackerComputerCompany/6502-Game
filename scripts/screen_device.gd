extends "res://scripts/io_device.gd"

var _output_buffer: String = ""

const ADDR_OUTPUT = 0xC002
const ADDR_CTRL = 0xC003
const ADDR_CURSOR_X = 0xC010
const ADDR_CURSOR_Y = 0xC011

signal char_output(ch: String)
signal output_ready(text: String)

func _init() -> void:
	name = "Screen"

func handles_address(addr: int) -> bool:
	return addr == ADDR_OUTPUT or addr == ADDR_CTRL \
		or addr == ADDR_CURSOR_X or addr == ADDR_CURSOR_Y

func poke(addr: int, val: int) -> void:
	if addr == ADDR_OUTPUT:
		var ch = char(val)
		_output_buffer += ch
		char_output.emit(ch)
	elif addr == ADDR_CTRL:
		if val == 0x0C:
			_output_buffer = ""
			output_ready.emit("[CLR]")
		elif val == 0x0D:
			output_ready.emit(_output_buffer)
			_output_buffer = ""
		elif val == 0x08:
			if _output_buffer.length() > 0:
				_output_buffer = _output_buffer.substr(0, _output_buffer.length() - 1)

func reset() -> void:
	_output_buffer = ""

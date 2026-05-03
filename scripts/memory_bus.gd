class_name MemoryBus
extends RefCounted

var ram: PackedByteArray

var _input_buffer: String = ""
var _input_pos: int = 0
var _output_buffer: String = ""

signal char_output(ch: String)
signal output_ready(text: String)

const ADDR_KEYBOARD_DATA = 0xC000
const ADDR_KEYBOARD_STATUS = 0xC001
const ADDR_SCREEN_OUTPUT = 0xC002
const ADDR_SCREEN_CTRL = 0xC003
const ADDR_CURSOR_X = 0xC010
const ADDR_CURSOR_Y = 0xC011
const ADDR_RNG_SEED = 0xC020
const ADDR_SYS_CALL = 0xC030

func _init() -> void:
	ram = PackedByteArray()
	ram.resize(65536)
	ram.fill(0)
	_write_vectors()

func _write_vectors() -> void:
	poke(0xFFFC, 0x00)
	poke(0xFFFD, 0x08)
	poke(0xFFFE, 0x00)
	poke(0xFFFF, 0x08)
	poke(0xFFFA, 0x00)
	poke(0xFFFB, 0x08)

func reset() -> void:
	ram.fill(0)
	_write_vectors()
	_input_buffer = ""
	_input_pos = 0
	_output_buffer = ""

func peek(addr: int) -> int:
	addr = addr & 0xFFFF
	if addr == ADDR_KEYBOARD_STATUS:
		return 1 if _input_pos < _input_buffer.length() else 0
	if addr == ADDR_KEYBOARD_DATA:
		if _input_pos < _input_buffer.length():
			var ch = _input_buffer.unicode_at(_input_pos)
			_input_pos += 1
			return ch
		return 0
	return ram[addr]

func poke(addr: int, val: int) -> void:
	addr = addr & 0xFFFF
	val = val & 0xFF
	if addr == ADDR_SCREEN_OUTPUT:
		var ch = char(val)
		_output_buffer += ch
		char_output.emit(ch)
		return
	if addr == ADDR_SCREEN_CTRL:
		if val == 0x0C:
			_output_buffer = ""
			output_ready.emit("[CLR]")
		elif val == 0x0D:
			output_ready.emit(_output_buffer)
			_output_buffer = ""
		elif val == 0x08:
			if _output_buffer.length() > 0:
				_output_buffer = _output_buffer.substr(0, _output_buffer.length() - 1)
		return
	ram[addr] = val

func peek_word(addr: int) -> int:
	return peek(addr) | (peek(addr + 1) << 8)

func poke_word(addr: int, val: int) -> void:
	poke(addr, val & 0xFF)
	poke(addr + 1, (val >> 8) & 0xFF)

func push_input(text: String) -> void:
	_input_buffer += text + "\n"
	_input_pos = 0

func clear_input() -> void:
	_input_buffer = ""
	_input_pos = 0

func load_bytes(data: PackedByteArray, start_addr: int) -> void:
	for i in range(data.size()):
		if start_addr + i < 65536:
			ram[start_addr + i] = data[i]

func serialize() -> Dictionary:
	return {"ram": ram.hex_encode()}

func deserialize(data: Dictionary) -> void:
	if data.has("ram"):
		var decoded: PackedByteArray = (data["ram"] as String).hex_decode()
		for i in range(decoded.size()):
			ram[i] = decoded[i]
		ram.resize(65536)
class_name MemoryBus
extends RefCounted

var ram: PackedByteArray

var _input_buffer: String = ""
var _input_pos: int = 0
var _output_buffer: String = ""

## Value returned by peek($C030); updated by CartManager after each swap.
var _cart_id_readback: int = 0

signal char_output(ch: String)
signal output_ready(text: String)
signal cart_switch_requested(cart_id: int)

const ADDR_KEYBOARD_DATA = 0xC000
const ADDR_KEYBOARD_STATUS = 0xC001
const ADDR_SCREEN_OUTPUT = 0xC002
const ADDR_SCREEN_CTRL = 0xC003
const ADDR_CURSOR_X = 0xC010
const ADDR_CURSOR_Y = 0xC011
const ADDR_RNG_SEED = 0xC020
const ADDR_CART_SELECT = 0xC030
## Poked for user routines that end in RTS without a prior JSR (ASM RUN, BASIC SYS, LOADOBJ native).
## Opcode $FF is unimplemented in the 6502 core and halts after RTS returns (pull + 1) here.
const USER_RTS_HALT_ADDR := 0xFFF0

func prepare_cpu_stack_for_user_rts(cpu) -> void:
	var ret_pc := (USER_RTS_HALT_ADDR - 1) & 0xFFFF
	poke(USER_RTS_HALT_ADDR, 0xFF)
	poke(0x01FE, ret_pc & 0xFF)
	poke(0x01FF, (ret_pc >> 8) & 0xFF)
	cpu.SP = 0xFD

func _init() -> void:
	ram = PackedByteArray()
	ram.resize(65536)
	ram.fill(0)
	_write_vectors()

func _write_boot_stub_fc00() -> void:
	## LDA #$00 / STA $C030 / JMP $F000 — selects BASIC cart then jumps to banked ROM entry.
	var boot: Array[int] = [
		0xA9, 0x00,
		0x8D, 0x30, 0xC0,
		0x4C, 0x00, 0xF0,
	]
	for i in range(boot.size()):
		ram[(0xFC00 + i) & 0xFFFF] = boot[i]

func _write_vectors() -> void:
	_write_boot_stub_fc00()
	## Reset -> $FC00 (boot stub). IRQ/NMI stay at $0800 (idle loop / user code).
	_write_byte_raw(0xFFFC, 0x00)
	_write_byte_raw(0xFFFD, 0xFC)
	_write_byte_raw(0xFFFE, 0x00)
	_write_byte_raw(0xFFFF, 0x08)
	_write_byte_raw(0xFFFA, 0x00)
	_write_byte_raw(0xFFFB, 0x08)

func _write_byte_raw(addr: int, val: int) -> void:
	ram[addr & 0xFFFF] = val & 0xFF

func reset() -> void:
	ram.fill(0)
	_write_vectors()
	_input_buffer = ""
	_input_pos = 0
	_output_buffer = ""
	_cart_id_readback = 0

func set_cart_id_readback(id: int) -> void:
	_cart_id_readback = id & 0xFF

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
	if addr == ADDR_CART_SELECT:
		return _cart_id_readback & 0xFF
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
	if addr == ADDR_CART_SELECT:
		cart_switch_requested.emit(val)
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

## Span from $0200 through last non-zero byte in main RAM ($0200-$DFFF). 0 if empty.
func get_main_ram_used_high_water() -> int:
	const MAIN_START := 0x0200
	const MAIN_END_EX := 0xE000
	var last_nz := -1
	for addr in range(MAIN_START, MAIN_END_EX):
		if ram[addr] != 0:
			last_nz = addr
	if last_nz < 0:
		return 0
	return last_nz - MAIN_START + 1

## Remove every outgoing connection (Computer ↔ MemoryBus feedback paths). Safe before dropping Computer.
func disconnect_all_signal_links() -> void:
	for sig_name in [&"char_output", &"output_ready", &"cart_switch_requested"]:
		var conns := get_signal_connection_list(sig_name)
		for conn in conns:
			var cb: Callable = conn["callable"]
			if cb.is_valid():
				disconnect(sig_name, cb)


func serialize() -> Dictionary:
	return {"ram": ram.hex_encode()}

func deserialize(data: Dictionary) -> void:
	if data.has("ram"):
		var decoded: PackedByteArray = (data["ram"] as String).hex_decode()
		for i in range(decoded.size()):
			ram[i] = decoded[i]
		ram.resize(65536)

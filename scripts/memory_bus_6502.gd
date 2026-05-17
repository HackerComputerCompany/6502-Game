extends "res://scripts/memory_bus.gd"

var _keyboard
var _screen
var _cart_select
var _gpu

const ADDR_CART_SELECT = 0xC030
## Poked for user routines that end in RTS without a prior JSR (ASM RUN, BASIC SYS, LOADOBJ native).
## Opcode $FF is unimplemented in 6502 and halts after RTS returns (pull + 1) here.
const USER_RTS_HALT_ADDR := 0xFFF0

func _init() -> void:
	super()
	_keyboard = preload("res://scripts/keyboard_device.gd").new()
	_screen = preload("res://scripts/screen_device.gd").new()
	_cart_select = preload("res://scripts/cart_select_device.gd").new()
	_gpu = preload("res://scripts/gpu_device.gd").new()
	_screen.char_output.connect(_on_screen_char)
	_screen.output_ready.connect(_on_screen_output_ready)
	_cart_select.cart_switch_requested.connect(_on_cart_switch)
	_write_vectors()

func _on_screen_char(ch: String) -> void:
	char_output.emit(ch)

func _on_screen_output_ready(text: String) -> void:
	output_ready.emit(text)

func _on_cart_switch(cart_id: int) -> void:
	cart_switch_requested.emit(cart_id)

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

func prepare_cpu_stack_for_user_rts(cpu) -> void:
	var ret_pc := (USER_RTS_HALT_ADDR - 1) & 0xFFFF
	poke(USER_RTS_HALT_ADDR, 0xFF)
	poke(0x01FE, ret_pc & 0xFF)
	poke(0x01FF, (ret_pc >> 8) & 0xFF)
	cpu.SP = 0xFD

func peek(addr: int) -> int:
	addr = addr & 0xFFFF
	if _keyboard.handles_address(addr):
		return _keyboard.peek(addr)
	if _cart_select.handles_address(addr):
		return _cart_select.peek(addr)
	if _gpu.handles_address(addr):
		return _gpu.peek(addr)
	return ram[addr]

func poke(addr: int, val: int) -> void:
	addr = addr & 0xFFFF
	val = val & 0xFF
	if _screen.handles_address(addr):
		_screen.poke(addr, val)
		return
	if _cart_select.handles_address(addr):
		_cart_select.poke(addr, val)
		return
	if _gpu.handles_address(addr):
		_gpu.poke(addr, val)
		return
	ram[addr] = val

func reset() -> void:
	super()
	_keyboard.reset()
	_screen.reset()
	_cart_select.reset()
	_gpu.reset()
	_write_vectors()

func serialize() -> Dictionary:
	var data := super()
	data["gpu"] = _gpu.serialize()
	return data

func deserialize(data: Dictionary) -> void:
	super(data)
	if data.has("gpu"):
		_gpu.deserialize(data["gpu"] as Dictionary)

func push_input(text: String) -> void:
	_keyboard.push_input(text)

func clear_input() -> void:
	_keyboard.clear_input()

func set_cart_id_readback(id: int) -> void:
	_cart_select.set_readback(id)

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

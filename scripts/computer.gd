class_name Computer
extends RefCounted

const _CartNativeGd := preload("res://scripts/cart_native.gd")
const _MemoryBus6502 := preload("res://scripts/memory_bus_6502.gd")

var memory
var cpu
var basic: BasicInterpreter
var rom: ROM
var cart_manager: CartManager

var _output_buffer: String = ""
var _ready: bool = false

var _program_running: bool = false
var _awaiting_input: bool = false

signal output(text: String)
## BBCode-safe output for RichTextLabel (not streamed through baud escape).
signal output_richtext(text: String)
signal ready_for_input()
signal program_finished()
## Terminal replays BIOS POST and CRT boot; clears all cart editor buffers first.
signal full_reboot_requested()

func emit_richtext(text: String) -> void:
	output_richtext.emit(text)

func _init() -> void:
	memory = _MemoryBus6502.new()
	cpu = CPU6502.new(memory)
	basic = BasicInterpreter.new(memory, _on_output, _on_input)
	cart_manager = CartManager.new(self)
	cart_manager.register(CartBasic.new())
	cart_manager.register(CartText.new())
	cart_manager.register(CartAsm.new())
	cart_manager.register(CartC.new())
	cart_manager.register(_CartNativeGd.new())
	memory.cart_switch_requested.connect(cart_manager._on_cart_switch_requested)
	cart_manager.switch_to(0, true)
	memory.char_output.connect(_on_char_output)
	memory.output_ready.connect(_on_output_ready)
	_ready = true


## Break feedback signals and cart backrefs before releasing the last Computer ref (avoids RefCounted cycles).
func disconnect_memory_signal_links() -> void:
	memory.disconnect_all_signal_links()
	cart_manager.release_cart_backrefs()


func _on_char_output(ch: String) -> void:
	_output_buffer += ch

func _on_output_ready(text: String) -> void:
	if text != "[CLR]":
		if _output_buffer.length() > 0:
			output.emit(_output_buffer)
			_output_buffer = ""
	else:
		output.emit("[CLR]")
		_output_buffer = ""

func _on_output(text: String) -> void:
	output.emit(text)

func _on_input(prompt: String) -> Variant:
	output.emit(prompt)
	ready_for_input.emit()
	return null

func run_basic(program: String, start_line: int = -1) -> void:
	_output_buffer = ""
	## Preserve existing variables and arrays across RUN.
	var saved_vars = basic._variables.duplicate(true)
	var saved_arrays = basic._arrays.duplicate(true)
	basic.load_program(program)
	basic._variables = saved_vars
	basic._arrays = saved_arrays
	basic._running = true
	if start_line >= 0:
		var idx = basic._find_line(start_line)
		if idx >= 0:
			basic._current_line = idx
		else:
			basic._current_line = 0
	else:
		basic._current_line = 0
	basic._data_pointer = 0
	_program_running = true
	_awaiting_input = false

func run_basic_sync(program: String, start_line: int = -1) -> void:
	run_basic(program, start_line)
	while _program_running:
		step_basic(1000)

func step_basic(max_lines: int) -> bool:
	if not _program_running:
		return false
	if not basic._running or basic._current_line >= basic._program.size():
		_program_running = false
		_flush_output()
		program_finished.emit()
		return false
	if _awaiting_input:
		return true
	var lines_executed = 0
	while basic._running and basic._current_line < basic._program.size() and lines_executed < max_lines:
		if basic._awaiting_input:
			_awaiting_input = true
			_flush_output()
			return true
		basic._execute_line(basic._program[basic._current_line])
		if basic._awaiting_input:
			_awaiting_input = true
			_flush_output()
			return true
		lines_executed += 1
	if not basic._running or basic._current_line >= basic._program.size():
		_program_running = false
		_flush_output()
		program_finished.emit()
		return false
	_flush_output()
	return true

func submit_input(text: String) -> void:
	memory.push_input(text)
	if basic._awaiting_input:
		var value = text.strip_edges()
		var parts = value.split(",")
		var values = []
		for p in parts:
			values.append(p.strip_edges())
		basic.provide_input(values)
		_awaiting_input = false

func execute_basic_line(line: String) -> void:
	_output_buffer = ""
	basic.execute_line(line)
	_flush_output()

func _flush_output() -> void:
	if _output_buffer.length() > 0:
		output.emit(_output_buffer)
		_output_buffer = ""

func request_full_reboot() -> void:
	reboot_deep_clear_carts()
	full_reboot_requested.emit()

func reboot_deep_clear_carts() -> void:
	cart_manager.reboot_clear_all_carts()
	reset()

func reset() -> void:
	_program_running = false
	_awaiting_input = false
	memory.reset()
	basic = BasicInterpreter.new(memory, _on_output, _on_input)
	cart_manager.switch_to(0, true)
	_output_buffer = ""
	_ready = true

func break_program() -> void:
	_program_running = false
	_awaiting_input = false
	basic._running = false

func serialize() -> Dictionary:
	return {
		"memory": memory.serialize(),
		"cpu": cpu.serialize(),
		"basic": basic.serialize(),
		"cart_id": cart_manager.get_current_id(),
		"cart_state": cart_manager.serialize_cart_state(),
	}

func deserialize(data: Dictionary) -> void:
	if data.has("memory"):
		memory.deserialize(data["memory"])
	if data.has("cpu"):
		cpu.deserialize(data["cpu"])
	if data.has("basic"):
		basic.deserialize(data["basic"])
	var cid := int(data.get("cart_id", 0))
	cart_manager.set_active_without_swap(cid)
	cart_manager.deserialize_cart_state(data.get("cart_state", {}))

func load_demo(name: String) -> String:
	return rom.load_demo_program(name)

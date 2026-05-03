class_name Computer
extends RefCounted

var memory: MemoryBus
var cpu: CPU6502
var basic: BasicInterpreter
var rom: ROM

var _output_buffer: String = ""
var _ready: bool = false
var _mode: String = "BASIC"

var _program_running: bool = false
var _awaiting_input: bool = false

signal output(text: String)
signal ready_for_input()
signal program_finished()

func _init() -> void:
	memory = MemoryBus.new()
	cpu = CPU6502.new(memory)
	basic = BasicInterpreter.new(memory, _on_output, _on_input)
	rom = ROM.new(memory)
	memory.char_output.connect(_on_char_output)
	memory.output_ready.connect(_on_output_ready)
	_ready = true

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

func run_basic(program: String) -> void:
	_output_buffer = ""
	basic.load_program(program)
	basic._running = true
	basic._current_line = 0
	basic._data_pointer = 0
	_program_running = true
	_awaiting_input = false

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
		basic._execute_line(basic._program[basic._current_line])
		if basic._running:
			basic._current_line += 1
		if basic._sleeping:
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
	if basic._running and basic._sleeping:
		basic._sleeping = false
		_awaiting_input = false

func execute_basic_line(line: String) -> void:
	_output_buffer = ""
	basic.execute_line(line)
	_flush_output()

func _flush_output() -> void:
	if _output_buffer.length() > 0:
		output.emit(_output_buffer)
		_output_buffer = ""

func reset() -> void:
	memory.reset()
	rom = ROM.new(memory)
	cpu.reset()
	basic = BasicInterpreter.new(memory, _on_output, _on_input)
	memory.char_output.connect(_on_char_output)
	memory.output_ready.connect(_on_output_ready)
	_output_buffer = ""
	_ready = true

func serialize() -> Dictionary:
	return {
		"memory": memory.serialize(),
		"cpu": cpu.serialize(),
		"basic": basic.serialize(),
	}

func deserialize(data: Dictionary) -> void:
	if data.has("memory"):
		memory.deserialize(data["memory"])
		rom = ROM.new(memory)
	if data.has("cpu"):
		cpu.deserialize(data["cpu"])
	if data.has("basic"):
		basic.deserialize(data["basic"])

func load_demo(name: String) -> String:
	return rom.load_demo_program(name)
class_name Computer
extends RefCounted

var memory: MemoryBus
var cpu: CPU6502
var basic: BasicInterpreter
var rom: ROM

var _output_buffer: String = ""
var _ready: bool = false
var _mode: String = "BASIC"

signal output(text: String)
signal ready_for_input()

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
	basic.run()
	if _output_buffer.length() > 0:
		output.emit(_output_buffer)
		_output_buffer = ""

func execute_basic_line(line: String) -> void:
	_output_buffer = ""
	basic.execute_line(line)
	if _output_buffer.length() > 0:
		output.emit(_output_buffer)
		_output_buffer = ""

func submit_input(text: String) -> void:
	memory.push_input(text)
	if basic._running and basic._sleeping:
		basic.continue_run()
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

func load_demo(name: String) -> String:
	return rom.load_demo_program(name)
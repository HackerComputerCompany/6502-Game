## Base class for all CPU implementations.
## Subclasses use: extends "res://scripts/cpu.gd"
extends RefCounted

var memory
var PC: int = 0
var halted: bool = false

func _init(mem) -> void:
	memory = mem

func step() -> void:
	pass

func reset() -> void:
	pass

func get_state() -> Dictionary:
	return {}

func disassemble(addr: int, count: int = 1) -> Array:
	return []

func run(cycle_limit: int = 100000) -> void:
	var count = 0
	while not halted and count < cycle_limit:
		step()
		count += 1

func serialize() -> Dictionary:
	return {}

func deserialize(data: Dictionary) -> void:
	pass

signal cpu_halted()

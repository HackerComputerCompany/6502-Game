## Base class for memory-mapped I/O devices.
## Subclasses use: extends "res://scripts/io_device.gd"
extends RefCounted

var name: String = ""

func handles_address(addr: int) -> bool:
	return false

func peek(addr: int) -> int:
	return 0

func poke(addr: int, val: int) -> void:
	pass

func reset() -> void:
	pass

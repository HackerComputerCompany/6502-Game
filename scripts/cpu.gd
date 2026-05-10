## Base class for all CPU implementations in the Teaching Lab.
## Every CPU subclass (CPU6502, CPUZ80, etc.) extends this via:
##     extends "res://scripts/cpu.gd"
##
## Sets the contract: step/reset/get_state/disassemble/run/serialize/deserialize.
## cpu_type is a human-readable string used by CartManager to check
## cartridge compatibility (see ROMCart.manifest).
extends RefCounted

## Reference to the system's memory bus (set in _init).
var memory
## Human-readable CPU identifier, e.g. "6502", "z80", "8086".
## Set by each subclass in its _init. Used by CartManager for manifest checks.
var cpu_type: String = ""
var PC: int = 0
var halted: bool = false

func _init(mem) -> void:
	memory = mem

## Execute one instruction (or one micro-step). Called by run() in a loop.
func step() -> void:
	pass

## Reset CPU to a known initial state. PC, registers, and flags are subclass-specific.
func reset() -> void:
	pass

## Return a Dictionary of current register/flag state for the debug UI.
## Keys are CPU-specific (e.g. "A","X","Y","SP","P" for 6502).
func get_state() -> Dictionary:
	return {}

## Return an Array of register metadata dicts for the debug panel.
## Each entry: {"key": String, "name": String, "desc": String, "group": String}
## Groups: "register" for general-purpose/visible registers,
##         "flag" for individual condition code flags.
func get_register_info() -> Array:
	return []

## Return an Array of {addr, disasm} Dicts for display in the monitor UI.
func disassemble(addr: int, count: int = 1) -> Array:
	return []

## Full register display string (used by the CPU command).
func format_state() -> String:
	return ""

## Compact one-line register string (used by monitor).
func format_state_compact() -> String:
	return ""

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

class_name ROMCart
extends RefCounted

## Banked cartridge id (matches peek/poke $C030)
var id: int = 0
var name: String = ""
var description: String = ""
## Prompt shown after each command (e.g. "READY." or "EDIT>")
var prompt: String = "READY."

## Declares CPU compatibility for this cartridge.
## CartManager checks manifest against computer.cpu.cpu_type before switching.
## Override in subclass to support other CPUs, e.g.:
##     {"cpus": ["6502", "z80"]}
## An empty "cpus" list means "compatible with any CPU".
var manifest: Dictionary = {
	"cpus": ["6502"],
}

var memory: MemoryBus
var computer: Variant

func install() -> void:
	pass

func uninstall() -> void:
	pass

## Return true if this cart consumed the line (no further terminal handling).
func handle_command(_text: String) -> bool:
	return false

func help_text() -> String:
	return ""

func banner_text() -> String:
	return ""

func serialize() -> Dictionary:
	return {}

func deserialize(_data: Dictionary) -> void:
	pass

## Clear editor/session state when user runs REBOOT (deep reset); default no-op.
func reboot_clear_state() -> void:
	pass

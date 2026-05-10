## Base class for memory-mapped I/O devices in the Teaching Lab.
## Each CPU's MemoryBus (e.g. MemoryBus6502) creates devices and
## delegates peek/poke to them. New devices extend this via:
##     extends "res://scripts/io_device.gd"
##
## Devices own their own state (buffers, registers) and can emit
## signals. The parent MemoryBus forwards device signals outward.
extends RefCounted

## Human-readable name shown in the device shelf GUI.
var name: String = ""

## Return true when addr falls in this device's address range.
func handles_address(addr: int) -> bool:
	return false

## Read a byte from this device. Only called after handles_address returns true.
func peek(addr: int) -> int:
	return 0

## Write a byte to this device. Only called after handles_address returns true.
func poke(addr: int, val: int) -> void:
	pass

## Reset device state (called by MemoryBus.reset()).
func reset() -> void:
	pass

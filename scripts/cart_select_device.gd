extends "res://scripts/io_device.gd"

var _cart_id_readback: int = 0

const ADDR_CART_SELECT = 0xC030

signal cart_switch_requested(cart_id: int)

func _init() -> void:
	name = "CartSelect"

func handles_address(addr: int) -> bool:
	return addr == ADDR_CART_SELECT

func peek(addr: int) -> int:
	return _cart_id_readback & 0xFF

func poke(addr: int, val: int) -> void:
	if _cart_id_readback != val:
		cart_switch_requested.emit(val)

func set_readback(id: int) -> void:
	_cart_id_readback = id & 0xFF

func reset() -> void:
	_cart_id_readback = 0

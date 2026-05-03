class_name CartManager
extends RefCounted

signal cart_changed(cart_name: String)

var computer: Computer
var current: ROMCart
var _carts_by_id: Dictionary = {}
var _carts_by_name: Dictionary = {}
var _swap_depth: int = 0

func _init(p_computer: Computer) -> void:
	computer = p_computer

func register(cart: ROMCart) -> void:
	cart.memory = computer.memory
	cart.computer = computer
	_carts_by_id[cart.id] = cart
	_carts_by_name[cart.name.to_upper()] = cart

func get_current_id() -> int:
	return current.id if current != null else 0

func get_prompt() -> String:
	return current.prompt if current != null else "READY."

func get_banner_text() -> String:
	return current.banner_text() if current != null else ""

## After full memory deserialize, only switch the active cart reference (no ROM/workspace/cpu changes).
func set_active_without_swap(cart_id: int) -> void:
	var c: ROMCart = _carts_by_id.get(cart_id & 0xFF, null) as ROMCart
	if c == null:
		c = _carts_by_id.get(0) as ROMCart
	current = c
	computer.memory.set_cart_id_readback(current.id)

func switch_to(key: Variant, force: bool = false) -> bool:
	var new_cart: ROMCart = null
	if key is int:
		new_cart = _carts_by_id.get(key, null) as ROMCart
	elif key is String:
		new_cart = _carts_by_name.get(key.to_upper().strip_edges(), null) as ROMCart
	if new_cart == null:
		return false
	if not force and current != null and current.id == new_cart.id:
		computer.memory.set_cart_id_readback(current.id)
		return true
	_swap_depth += 1
	if current != null:
		current.uninstall()
	_clear_cart_workspace()
	current = new_cart
	current.install()
	computer.memory.set_cart_id_readback(current.id)
	computer.cpu.reset()
	computer._program_running = false
	computer._awaiting_input = false
	computer.basic._running = false
	_swap_depth -= 1
	cart_changed.emit(current.name)
	return true

func _clear_cart_workspace() -> void:
	for a in range(0xE000, 0xF000):
		computer.memory.poke(a, 0)

func _on_cart_switch_requested(cart_id: int) -> void:
	if _swap_depth > 0:
		return
	switch_to(cart_id & 0xFF, false)

func handle_command(text: String) -> bool:
	var stripped = text.strip_edges()
	var upper = stripped.to_upper()
	if upper == "CART" or upper == "CARTS":
		_list_carts()
		return true
	if upper.begins_with("CART "):
		var arg = stripped.substr(5).strip_edges()
		if arg == "":
			_list_carts()
			return true
		if not switch_to(arg, false):
			computer.emit_richtext("[color=red]Unknown cart: %s[/color]\n" % arg)
			return true
		computer.emit_richtext("[color=lime]Switched to cart: %s[/color]\n" % current.name)
		return true
	var handled = false
	if current != null:
		handled = current.handle_command(text)
	return handled

func _list_carts() -> void:
	var buf := ""
	buf += "\n[color=cyan]Available ROM carts:[/color]\n"
	var ids: Array = _carts_by_id.keys()
	ids.sort()
	for cid in ids:
		var c: ROMCart = _carts_by_id[cid] as ROMCart
		buf += "[color=yellow]  %-6s[/color] id=%d - %s\n" % [c.name, c.id, c.description]
	buf += "\n[color=lime]Type CART <name> to switch. Current: %s[/color]\n" % (current.name if current else "?")
	computer.emit_richtext(buf)

func serialize_cart_state() -> Dictionary:
	if current == null:
		return {}
	return current.serialize()

func deserialize_cart_state(data: Variant) -> void:
	if current == null:
		return
	if data is Dictionary:
		current.deserialize(data as Dictionary)

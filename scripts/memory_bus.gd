class_name MemoryBus
extends RefCounted

var ram: PackedByteArray

signal char_output(ch: String)
signal output_ready(text: String)
signal cart_switch_requested(cart_id: int)

func _init() -> void:
	ram = PackedByteArray()
	ram.resize(65536)
	ram.fill(0)

func peek(addr: int) -> int:
	return ram[addr & 0xFFFF]

func poke(addr: int, val: int) -> void:
	ram[addr & 0xFFFF] = val & 0xFF

func peek_word(addr: int) -> int:
	return peek(addr) | (peek(addr + 1) << 8)

func poke_word(addr: int, val: int) -> void:
	poke(addr, val & 0xFF)
	poke(addr + 1, (val >> 8) & 0xFF)

func reset() -> void:
	ram.fill(0)

func push_input(text: String) -> void:
	pass

func clear_input() -> void:
	pass

func load_bytes(data: PackedByteArray, start_addr: int) -> void:
	for i in range(data.size()):
		if start_addr + i < 65536:
			ram[start_addr + i] = data[i]

func disconnect_all_signal_links() -> void:
	for sig_name in [&"char_output", &"output_ready", &"cart_switch_requested"]:
		var conns := get_signal_connection_list(sig_name)
		for conn in conns:
			var cb: Callable = conn["callable"]
			if cb.is_valid():
				disconnect(sig_name, cb)

func serialize() -> Dictionary:
	return {"ram": ram.hex_encode()}

func deserialize(data: Dictionary) -> void:
	if data.has("ram"):
		var decoded: PackedByteArray = (data["ram"] as String).hex_decode()
		for i in range(decoded.size()):
			ram[i] = decoded[i]
		ram.resize(65536)

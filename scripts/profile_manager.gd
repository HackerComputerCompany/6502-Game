class_name ProfileManager
extends RefCounted

const PROFILE_DIR = "user://profiles/"
const PROFILE_EXT = ".json"

const PRESETS = {
	"6502_trainer": {
		"name": "6502 Trainer",
		"description": "Classic 6502 learning system with 64KB RAM, BASIC, ASM, TEXT, C carts. Default configuration.",
		"cpu_type": "6502",
		"memory_bus_type": "MemoryBus6502",
		"memory_size_kb": 64,
		"io_devices": ["KeyboardDevice", "ScreenDevice", "CartSelectDevice"],
		"active_cart_id": 0,
		"default_clock_mhz": 1.0,
	},
	"6502_minimal": {
		"name": "6502 Minimal",
		"description": "Minimal 6502 system with 8KB RAM, no BASIC. For bare-metal machine code experiments.",
		"cpu_type": "6502",
		"memory_bus_type": "MemoryBus6502",
		"memory_size_kb": 8,
		"io_devices": ["KeyboardDevice", "ScreenDevice"],
		"active_cart_id": 0,
		"default_clock_mhz": 1.0,
	},
	"6502_apple_ii_style": {
		"name": "6502 Apple II-style",
		"description": "6502 system inspired by Apple II memory layout: 48KB RAM, ROM at $F000-$FFFF, text/graphics screen holes.",
		"cpu_type": "6502",
		"memory_bus_type": "MemoryBus6502",
		"memory_size_kb": 48,
		"io_devices": ["KeyboardDevice", "ScreenDevice", "CartSelectDevice"],
		"active_cart_id": 0,
		"default_clock_mhz": 1.0,
	},
}

var _computer: Computer

func _init(computer: Computer) -> void:
	_computer = computer
	_ensure_profile_dir()

func _ensure_profile_dir() -> void:
	DirAccess.make_dir_recursive_absolute(PROFILE_DIR)

func list_profiles() -> Array:
	var profiles: Array = []
	var dir = DirAccess.open(PROFILE_DIR)
	if dir == null:
		for key in PRESETS:
			profiles.append(PRESETS[key].duplicate(true))
		return profiles
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if fname.ends_with(PROFILE_EXT):
			var path = PROFILE_DIR.path_join(fname)
			var file = FileAccess.open(path, FileAccess.READ)
			if file != null:
				var text = file.get_as_text()
				var data = JSON.parse_string(text)
				if data is Dictionary and data.has("name"):
					profiles.append(data)
		fname = dir.get_next()
	dir.list_dir_end()
	for key in PRESETS:
		var dupe = PRESETS[key].duplicate(true)
		dupe["_preset"] = true
		profiles.append(dupe)
	return profiles

func get_preset_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for key in PRESETS:
		names.append(key)
	return names

func get_preset(name: String) -> Dictionary:
	if PRESETS.has(name):
		return PRESETS[name].duplicate(true)
	return {}

func save_profile(name: String) -> bool:
	var data = _build_profile_data(name)
	var sanitized = _sanitize_filename(name)
	var path = PROFILE_DIR.path_join(sanitized + PROFILE_EXT)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_line(JSON.stringify(data, "\t"))
	return true

func load_profile(name_or_path: String) -> Dictionary:
	if PRESETS.has(name_or_path):
		return PRESETS[name_or_path].duplicate(true)
	var sanitized = _sanitize_filename(name_or_path)
	var path = PROFILE_DIR.path_join(sanitized + PROFILE_EXT)
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text = file.get_as_text()
	var data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}

func delete_profile(name: String) -> bool:
	if PRESETS.has(name):
		return false
	var sanitized = _sanitize_filename(name)
	var path = PROFILE_DIR.path_join(sanitized + PROFILE_EXT)
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(path) == OK

func apply_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return
	if profile.has("cpu_type") and _computer.cpu != null:
		_computer.cpu.cpu_type = profile["cpu_type"]
	if profile.has("memory_bus_type"):
		pass
	if profile.has("default_clock_mhz"):
		pass
	if profile.has("active_cart_id"):
		var cid = int(profile["active_cart_id"])
		_computer.cart_manager.switch_to(cid, true)

func _build_profile_data(name: String) -> Dictionary:
	return {
		"name": name,
		"description": "User-defined profile",
		"cpu_type": _computer.cpu.cpu_type if _computer.cpu else "6502",
		"memory_bus_type": "MemoryBus6502",
		"memory_size_kb": 64,
		"io_devices": ["KeyboardDevice", "ScreenDevice", "CartSelectDevice"],
		"active_cart_id": _computer.cart_manager.get_current_id(),
		"default_clock_mhz": 1.0,
	}

func _sanitize_filename(name: String) -> String:
	var allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-."
	var result = ""
	for ch in name:
		if ch in allowed:
			result += ch
		else:
			result += "_"
	return result.strip_edges()

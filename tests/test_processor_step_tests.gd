extends SceneTree

## Regression runner for SingleStepTests / 65x02 JSON (Tom Harte et al., MIT).
## See tests/fixtures/processor_tests/README.md for attribution and subset rebuild.

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	print("\n========== 65x02 PROCESSOR STEP TESTS (subset) ==========\n")
	var dir := DirAccess.open("res://tests/fixtures/processor_tests/v1")
	if dir == null:
		push_error("missing res://tests/fixtures/processor_tests/v1 — run build_subset.py")
		quit(1)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	var files: Array[String] = []
	while name != "":
		if name.ends_with(".json"):
			files.append(name)
		name = dir.get_next()
	files.sort()
	print("  JSON files: %d\n" % files.size())
	for fn in files:
		_run_file("res://tests/fixtures/processor_tests/v1/" + fn)
	print("\n========== 65x02 RESULTS ==========")
	print("  PASSED: %d" % _passed)
	print("  FAILED: %d" % _failed)
	print("===================================\n")
	quit(1 if _failed > 0 else 0)


func _run_file(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("cannot open %s" % path)
		_failed += 1
		return
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if data == null or typeof(data) != TYPE_ARRAY:
		push_error("bad JSON: %s" % path)
		_failed += 1
		return
	var short := path.get_file()
	for i in range(data.size()):
		_run_case(short, i, data[i])


func _run_case(src_file: String, idx: int, t: Variant) -> void:
	var ini: Dictionary = t["initial"]
	var fin: Dictionary = t["final"]
	var mem := MemoryBus.new()
	_apply_ram(mem, ini["ram"])
	var cpu := CPU6502.new(mem)
	cpu.PC = int(ini["pc"]) & 0xFFFF
	cpu.SP = int(ini["s"]) & 0xFF
	cpu.A = int(ini["a"]) & 0xFF
	cpu.X = int(ini["x"]) & 0xFF
	cpu.Y = int(ini["y"]) & 0xFF
	cpu.P = int(ini["p"]) & 0xFF
	cpu.halted = false
	cpu.step()
	var ok := true
	var detail := ""
	if cpu.PC != (int(fin["pc"]) & 0xFFFF):
		ok = false
		detail = "PC exp=$%04X got=$%04X" % [int(fin["pc"]) & 0xFFFF, cpu.PC]
	elif cpu.SP != (int(fin["s"]) & 0xFF):
		ok = false
		detail = "SP exp=%02X got=%02X" % [int(fin["s"]) & 0xFF, cpu.SP]
	elif cpu.A != (int(fin["a"]) & 0xFF):
		ok = false
		detail = "A mismatch"
	elif cpu.X != (int(fin["x"]) & 0xFF):
		ok = false
		detail = "X mismatch"
	elif cpu.Y != (int(fin["y"]) & 0xFF):
		ok = false
		detail = "Y mismatch"
	elif (cpu.P & 0xFF) != (int(fin["p"]) & 0xFF):
		ok = false
		detail = "P exp=$%02X got=$%02X" % [int(fin["p"]) & 0xFF, cpu.P & 0xFF]
	else:
		var ram_fin: Array = fin["ram"]
		for pair in ram_fin:
			var addr := int(pair[0]) & 0xFFFF
			var expb := int(pair[1]) & 0xFF
			var got := mem.peek(addr)
			if got != expb:
				ok = false
				detail = "ram[$%04X] exp=$%02X got=$%02X" % [addr, expb, got]
				break
	if ok:
		_passed += 1
	else:
		_failed += 1
		var nm: String = str(t.get("name", "?"))
		print("  FAIL [%s #%d %s] %s" % [src_file, idx, nm, detail])


func _apply_ram(mem: MemoryBus, pairs: Array) -> void:
	for pair in pairs:
		mem.poke(int(pair[0]) & 0xFFFF, int(pair[1]) & 0xFF)

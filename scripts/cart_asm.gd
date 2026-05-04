class_name CartAsm
extends ROMCart

var _lines: Array = []
var _asm := Assembler6502.new()
var _last_ok: bool = false

const WORKSPACE_START = 0xE000
const WORKSPACE_END = 0xF000
const BANK_START = 0xF000
const BANK_END = 0xFC00

func _init() -> void:
	id = 2
	name = "ASM"
	description = "6502 line editor + two-pass assembler (SAVE/LOAD .asm)"
	prompt = "ASM>"

func install() -> void:
	for a in range(BANK_START, BANK_END):
		memory.poke(a, 0)
	_write_banner_rom()
	_sync_workspace()

func uninstall() -> void:
	pass

func _write_banner_rom() -> void:
	var code: Array = [
		0xA0, 0x00,
		0xB9, 0x50, 0xF0,
		0xF0, 0x06,
		0x8D, 0x02, 0xC0,
		0xC8,
		0xD0, 0xF5,
		0x60,
	]
	for i in range(code.size()):
		memory.poke(BANK_START + i, code[i])
	var msg := "ASM EDITOR v1.0"
	var addr := 0xF050
	for j in range(msg.length()):
		memory.poke(addr + j, msg.unicode_at(j))
	memory.poke(addr + msg.length(), 0x0D)
	memory.poke(addr + msg.length() + 1, 0x00)

func _emit(s: String) -> void:
	computer.emit_richtext(s)

func handle_command(text: String) -> bool:
	var t := text.strip_edges()
	if t == "":
		return false
	var upper := t.to_upper()
	if upper == "NEW":
		_lines.clear()
		_last_ok = false
		_sync_workspace()
		_emit("[color=lime]Source cleared.[/color]\n")
		return true
	if upper == "HELP":
		_emit(help_text())
		return true
	if upper == "ASM":
		_cmd_asm()
		return true
	if upper == "RUN":
		_cmd_run()
		return true
	if upper == "SYM":
		_cmd_sym()
		return true
	if upper == "HEX":
		_cmd_hex()
		return true
	if upper == "LIST" or upper.begins_with("LIST "):
		_cmd_list(t)
		return true
	if upper.begins_with("DEL "):
		_cmd_del(t.substr(4).strip_edges())
		return true
	if upper.begins_with("SAVE "):
		_cmd_save(t.substr(5).strip_edges())
		return true
	if upper.begins_with("LOAD "):
		_cmd_load(t.substr(5).strip_edges())
		return true
	if upper == "DIR" or upper == "CATALOG":
		_cmd_dir()
		return true
	if t[0].is_valid_int():
		_cmd_line_entry(t)
		return true
	_emit("[color=red]Unknown command. Type HELP.[/color]\n")
	return true

func help_text() -> String:
	var h := "\n[color=cyan]ASM cart — 6502 source + assembler[/color]\n"
	h += "[color=yellow]  n text[/color]     Add/replace source line n\n"
	h += "[color=yellow]  n[/color]          Delete line n\n"
	h += "[color=yellow]  LIST [n [m]][/color] List lines\n"
	h += "[color=yellow]  DEL n[/color]      Delete line n\n"
	h += "[color=yellow]  NEW[/color]          Clear source\n"
	h += "[color=yellow]  ASM[/color]          Assemble to RAM ($0800+ or .ORG)\n"
	h += "[color=yellow]  RUN[/color]          Run last object (same idea as SYS)\n"
	h += "[color=yellow]  SYM[/color]          Show labels from last ASM\n"
	h += "[color=yellow]  HEX[/color]          Hex dump of last object range\n"
	h += "[color=yellow]  SAVE name[/color]  Save source to user://name.asm\n"
	h += "[color=yellow]  LOAD name[/color]  Load source from user://name.asm\n"
	h += "[color=yellow]  DIR[/color]          List .asm files\n"
	h += "[color=yellow]  CART BASIC[/color] Return to BASIC\n"
	h += "[color=lime]Source mirrored at $E000-$EFFF. SYS $F000 for banner.[/color]\n"
	return h

func banner_text() -> String:
	return "\n[color=green]ASM cart — line editor + 6502 assembler. Type HELP.[/color]\n"

func _cmd_asm() -> void:
	_asm = Assembler6502.new()
	_last_ok = _asm.assemble(memory, _lines)
	if not _last_ok:
		for e in _asm.errors:
			_emit("[color=red]%s[/color]\n" % e)
		_emit("[color=red]Assembly failed.[/color]\n")
		return
	var nlines := _lines.size()
	var nbytes := 0
	if _asm.last_start >= 0 and _asm.last_end >= _asm.last_start:
		nbytes = _asm.last_end - _asm.last_start + 1
	_emit("[color=lime]Assembled %d source line(s), %d byte(s) object.[/color]\n" % [nlines, nbytes])
	if _asm.last_start >= 0:
		_emit("[color=cyan]Object $%04X-$%04X[/color]\n" % [_asm.last_start, _asm.last_end])
	else:
		_emit("[color=yellow](no code emitted — directives only?)[/color]\n")

func _cmd_run() -> void:
	if not _last_ok or _asm.last_start < 0:
		_emit("[color=red]Run ASM first (no object range).[/color]\n")
		return
	var cpu = computer.cpu
	cpu.halted = false
	cpu.PC = _asm.last_start & 0xFFFF
	cpu.run(10000)

func _cmd_sym() -> void:
	if not _last_ok:
		_emit("[color=yellow]No symbol table until a successful ASM.[/color]\n")
		return
	var buf := "\n[color=cyan]Labels:[/color]\n"
	var keys: Array = _asm.symbols.keys()
	keys.sort()
	for k in keys:
		buf += "[color=yellow]  %-12s[/color] $%04X\n" % [str(k), int(_asm.symbols[k]) & 0xFFFF]
	if _asm.equs.is_empty() and keys.is_empty():
		buf += "[color=yellow]  (none)[/color]\n"
	if not _asm.equs.is_empty():
		buf += "[color=cyan].EQU:[/color]\n"
		var ek: Array = _asm.equs.keys()
		ek.sort()
		for k2 in ek:
			buf += "[color=yellow]  %-12s[/color] $%04X\n" % [str(k2), int(_asm.equs[k2]) & 0xFFFF]
	_emit(buf + "\n")

func _cmd_hex() -> void:
	if not _last_ok or _asm.last_start < 0:
		_emit("[color=yellow]Nothing to dump; run ASM first.[/color]\n")
		return
	var a0 := _asm.last_start & 0xFFFF
	var a1 := _asm.last_end & 0xFFFF
	var max_rows := 32
	var addr := a0
	var row := 0
	var out := "\n"
	while addr <= a1 and row < max_rows:
		out += "[color=cyan]%04X:[/color] " % addr
		var chunk := mini(16, a1 - addr + 1)
		for i in range(chunk):
			out += "%02X " % (memory.peek((addr + i) & 0xFFFF) & 0xFF)
		out += "\n"
		addr += chunk
		row += 1
	if addr <= a1:
		out += "[color=yellow]  ... (truncated)[/color]\n"
	_emit(out)

func _cmd_list(arg_line: String) -> void:
	var rest := ""
	if arg_line.to_upper().begins_with("LIST "):
		rest = arg_line.substr(5).strip_edges()
	var lo := -1
	var hi := -1
	if rest != "":
		var parts := rest.split(" ", false)
		if parts.size() >= 1:
			lo = int(parts[0]) if parts[0].is_valid_int() else -1
		if parts.size() >= 2:
			hi = int(parts[1]) if parts[1].is_valid_int() else -1
	if lo >= 0 and hi < 0:
		hi = lo
	_emit("\n")
	for entry in _lines:
		var ln: int = int(entry[0])
		if lo >= 0:
			if ln < lo or ln > hi:
				continue
		_emit("[color=white]%5d  %s[/color]\n" % [ln, str(entry[1])])
	if _lines.is_empty():
		_emit("[color=yellow](empty source)[/color]\n")

func _cmd_del(arg: String) -> void:
	if not arg.is_valid_int():
		_emit("[color=red]Usage: DEL n[/color]\n")
		return
	var ln := int(arg)
	for i in range(_lines.size()):
		if int(_lines[i][0]) == ln:
			_lines.remove_at(i)
			_last_ok = false
			_sync_workspace()
			_emit("[color=lime]Deleted line %d.[/color]\n" % ln)
			return
	_emit("[color=red]No such line %d.[/color]\n" % ln)

func _cmd_line_entry(line: String) -> void:
	var pos := 0
	while pos < line.length() and line[pos] == " ":
		pos += 1
	var num_str := ""
	while pos < line.length() and line[pos].is_valid_int():
		num_str += line[pos]
		pos += 1
	if num_str == "":
		return
	var ln := int(num_str)
	while pos < line.length() and line[pos] == " ":
		pos += 1
	var stmt := line.substr(pos)
	if stmt == "":
		_cmd_del(str(ln))
		return
	var idx := -1
	for i in range(_lines.size()):
		if int(_lines[i][0]) == ln:
			idx = i
			break
	if idx >= 0:
		_lines[idx] = [ln, stmt]
	else:
		_lines.append([ln, stmt])
	_lines.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	_last_ok = false
	_sync_workspace()
	_emit("[color=lime]Line %d stored.[/color]\n" % ln)

func _sanitize_name(raw: String) -> String:
	var s := raw.strip_edges()
	var out := ""
	for i in range(s.length()):
		var c := s[i]
		var u := c.unicode_at(0)
		var ok := (u >= 97 and u <= 122) or (u >= 65 and u <= 90) or (u >= 48 and u <= 57) or u == 95 or u == 45
		if ok:
			out += c
	if out == "":
		out = "source"
	return out

func _cmd_save(raw_name: String) -> void:
	var base := _sanitize_name(raw_name)
	var path := "user://%s.asm" % base
	var body_text := ""
	for i in range(_lines.size()):
		if i > 0:
			body_text += "\n"
		body_text += "%d %s" % [int(_lines[i][0]), str(_lines[i][1])]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(body_text)
		file.close()
		_emit("[color=lime]Saved %d line(s) to %s.asm[/color]\n" % [_lines.size(), base])
	else:
		_emit("[color=red]SAVE failed.[/color]\n")

func _cmd_load(raw_name: String) -> void:
	var base := _sanitize_name(raw_name)
	var path := "user://%s.asm" % base
	if not FileAccess.file_exists(path):
		_emit("[color=red]File not found: %s.asm[/color]\n" % base)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_emit("[color=red]LOAD failed.[/color]\n")
		return
	var content := file.get_as_text()
	file.close()
	_lines.clear()
	_last_ok = false
	for row in content.split("\n"):
		var row_st := row.strip_edges()
		if row_st == "":
			continue
		var p := 0
		while p < row_st.length() and row_st[p] == " ":
			p += 1
		var ns := ""
		while p < row_st.length() and row_st[p].is_valid_int():
			ns += row_st[p]
			p += 1
		if ns == "":
			continue
		while p < row_st.length() and row_st[p] == " ":
			p += 1
		_lines.append([int(ns), row_st.substr(p)])
	_lines.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	_sync_workspace()
	_emit("[color=lime]Loaded %d line(s) from %s.asm[/color]\n" % [_lines.size(), base])

func _cmd_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		_emit("[color=red]Cannot open disk.[/color]\n")
		return
	var buf := "\n[color=cyan].ASM FILES:[/color]\n"
	dir.list_dir_begin()
	var file_name := dir.get_next()
	var count := 0
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".asm"):
			buf += "[color=yellow]  %s[/color]\n" % file_name.trim_suffix(".asm")
			count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	if count == 0:
		buf += "[color=yellow]  (none)[/color]\n"
	buf += "\n"
	_emit(buf)

func _sync_workspace() -> void:
	for a in range(WORKSPACE_START, WORKSPACE_END):
		memory.poke(a, 0)
	var addr := WORKSPACE_START
	for entry in _lines:
		var body: String = str(entry[1])
		if body == "":
			continue
		var chunk := body + char(0)
		for j in range(chunk.length()):
			if addr >= WORKSPACE_END:
				return
			memory.poke(addr, chunk.unicode_at(j) & 0xFF)
			addr += 1
		if addr >= WORKSPACE_END:
			return

func serialize() -> Dictionary:
	var arr: Array = []
	for entry in _lines:
		arr.append({"ln": int(entry[0]), "t": str(entry[1])})
	return {"lines": arr, "last_ok": _last_ok}

func deserialize(data: Dictionary) -> void:
	_lines.clear()
	if data.has("lines"):
		for item in data["lines"]:
			if item is Dictionary:
				var d: Dictionary = item
				if d.has("ln") and d.has("t"):
					_lines.append([int(d["ln"]), str(d["t"])])
	_lines.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	_last_ok = bool(data.get("last_ok", false))
	_sync_workspace()

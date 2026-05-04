class_name CartText
extends ROMCart

## Sorted array of [line_num: int, text: String]
var _lines: Array = []

const WORKSPACE_START = 0xE000
const WORKSPACE_END = 0xF000
const BANK_START = 0xF000
const BANK_END = 0xFC00

func _init() -> void:
	id = 1
	name = "TEXT"
	description = "Line-numbered text buffer (SAVE/LOAD as .txt)"
	prompt = "EDIT>"

func install() -> void:
	for a in range(BANK_START, BANK_END):
		memory.poke(a, 0)
	_write_banner_rom()
	_sync_workspace()

func uninstall() -> void:
	pass

func _write_banner_rom() -> void:
	## SYS $F000 prints banner via screen port (6502 routine).
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
	var msg := "TEXT EDITOR v1.0"
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
		_sync_workspace()
		_emit("[color=lime]Buffer cleared.[/color]\n")
		return true
	if upper == "HELP":
		_emit(help_text())
		return true
	if upper == "PRINT":
		_dump_print()
		return true
	if upper == "LIST" or upper.begins_with("LIST "):
		_cmd_list(t)
		return true
	if upper.begins_with("SCRATCH ") or upper.begins_with("DELETE "):
		var space_pos := t.find(" ")
		_cmd_scratch(t.substr(space_pos + 1).strip_edges())
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
	_emit("[color=red]Unknown command. Type HELP for editor commands.[/color]\n")
	return true

func help_text() -> String:
	var h := "\n[color=cyan]TEXT cart - line editor[/color]\n"
	h += "[color=yellow]  n text[/color]      Add/replace line n\n"
	h += "[color=yellow]  n[/color]           Delete line n\n"
	h += "[color=yellow]  LIST [n [m]] [/color] List lines (optional range)\n"
	h += "[color=yellow]  NEW[/color]           Clear buffer\n"
	h += "[color=yellow]  PRINT[/color]       Print all lines as plain text\n"
	h += "[color=yellow]  SAVE name[/color]   Save to user://name.txt\n"
	h += "[color=yellow]  LOAD name[/color]   Load from user://name.txt\n"
	h += "[color=yellow]  DIR[/color]           List .txt files on disk\n"
	h += "[color=yellow]  SCRATCH name[/color]Delete a .txt file\n"
	h += "[color=lime]Type CART BASIC to return to BASIC. Line buffer at $E000-$EFFF.[/color]\n"
	return h

func banner_text() -> String:
	return "\n[color=green]TEXT cart - line-numbered buffer. Type HELP for commands.[/color]\n"

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
		var body: String = str(entry[1])
		_emit("[color=white]%5d  %s[/color]\n" % [ln, body])
	if _lines.is_empty():
		_emit("[color=yellow](empty buffer)[/color]\n")

func _cmd_scratch(raw_name: String) -> void:
	var base := _sanitize_name(raw_name)
	var path := "user://%s.txt" % base
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		_emit("[color=lime]Deleted %s.txt[/color]\n" % base)
	else:
		_emit("[color=red]File not found: %s.txt[/color]\n" % base)

func _delete_line(ln: int) -> void:
	for i in range(_lines.size()):
		if int(_lines[i][0]) == ln:
			_lines.remove_at(i)
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
		_delete_line(ln)
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
	_sync_workspace()
	_emit("[color=lime]Line %d stored.[/color]\n" % ln)

func _dump_print() -> void:
	for entry in _lines:
		_emit(str(entry[1]) + "\n")
	if _lines.is_empty():
		_emit("[color=yellow](empty)[/color]\n")

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
		out = "buffer"
	return out

func _cmd_save(raw_name: String) -> void:
	var base := _sanitize_name(raw_name)
	var path := "user://%s.txt" % base
	var body_text := ""
	for i in range(_lines.size()):
		if i > 0:
			body_text += "\n"
		body_text += str(_lines[i][1])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(body_text)
		file.close()
		_emit("[color=lime]Saved %d line(s) to %s.txt[/color]\n" % [_lines.size(), base])
	else:
		_emit("[color=red]SAVE failed.[/color]\n")

func _cmd_load(raw_name: String) -> void:
	var base := _sanitize_name(raw_name)
	var path := "user://%s.txt" % base
	if not FileAccess.file_exists(path):
		_emit("[color=red]File not found: %s.txt[/color]\n" % base)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_emit("[color=red]LOAD failed.[/color]\n")
		return
	var content := file.get_as_text()
	file.close()
	_lines.clear()
	var line_num := 10
	for row in content.split("\n"):
		var row_st := row.strip_edges()
		if row_st != "":
			_lines.append([line_num, row_st])
			line_num += 10
	_sync_workspace()
	_emit("[color=lime]Loaded %d line(s) from %s.txt[/color]\n" % [_lines.size(), base])

func _cmd_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		_emit("[color=red]Cannot open disk.[/color]\n")
		return
	var buf := "\n[color=cyan].TXT FILES:[/color]\n"
	dir.list_dir_begin()
	var file_name := dir.get_next()
	var count := 0
	var total_bytes := 0
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".txt"):
			var path := "user://" + file_name
			var sz := 0
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				sz = f.get_length()
				f.close()
			total_bytes += sz
			var show_name := file_name.trim_suffix(".txt")
			buf += "[color=yellow]  %-18s %s[/color]\n" % [show_name, _fmt_file_size(sz)]
			count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	if count == 0:
		buf += "[color=yellow]  (none)[/color]\n"
	buf += "[color=white]  %d file(s), %s total[/color]\n\n" % [count, _fmt_file_size(total_bytes)]
	_emit(buf)

func _fmt_file_size(n: int) -> String:
	if n < 1024:
		return str(n) + " B"
	return "%.1f KB" % (n / 1024.0)

func _sync_workspace() -> void:
	for a in range(WORKSPACE_START, WORKSPACE_END):
		memory.poke(a, 0)
	var addr := WORKSPACE_START
	for entry in _lines:
		var body: String = str(entry[1])
		if body == "":
			continue
		for j in range(body.length()):
			if addr >= WORKSPACE_END:
				return
			memory.poke(addr, body.unicode_at(j) & 0xFF)
			addr += 1
		if addr >= WORKSPACE_END:
			return
		memory.poke(addr, 0)
		addr += 1

func serialize() -> Dictionary:
	var arr: Array = []
	for entry in _lines:
		arr.append({"ln": int(entry[0]), "t": str(entry[1])})
	return {"lines": arr}

func deserialize(data: Dictionary) -> void:
	_lines.clear()
	if not data.has("lines"):
		return
	for item in data["lines"]:
		if item is Dictionary:
			var d: Dictionary = item
			if d.has("ln") and d.has("t"):
				_lines.append([int(d["ln"]), str(d["t"])])
	_lines.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	_sync_workspace()

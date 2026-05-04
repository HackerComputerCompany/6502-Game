class_name CartC
extends ROMCart

var _lines: Array = []
var _last_ok: bool = false
var _last_start: int = -1
var _last_end: int = -1

const WORKSPACE_START = 0xE000
const WORKSPACE_END = 0xF000
const BANK_START = 0xF000
const BANK_END = 0xFC00

func _init() -> void:
	id = 3
	name = "C"
	description = "Small-C compiler; COMPILE, RUN, SAVE/LOAD .c source"
	prompt = "C>"

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
	var msg := "SMALL-C v1.0"
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
	if upper == "COMPILE" or upper == "BUILD":
		_cmd_compile()
		return true
	if upper == "RUN":
		_cmd_run()
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
	if upper == "DEMO" or upper == "DEMOS":
		_cmd_demo_list()
		return true
	if upper.begins_with("DEMO ") or upper.begins_with("DEMOS "):
		_cmd_demo_load(t.substr(5).strip_edges())
		return true
	if t[0].is_valid_int():
		_cmd_line_entry(t)
		return true
	_emit("[color=red]Unknown command. Type HELP.[/color]\n")
	return true

func help_text() -> String:
	var h := "\n[color=cyan]C cart — Small-C compiler[/color]\n"
	h += "[color=white]Quick reference[/color]\n"
	h += "  [color=yellow]n text[/color]       Store/replace line [color=white]n[/color] with C source\n"
	h += "  [color=yellow]n[/color]             Delete line [color=white]n[/color]\n"
	h += "  [color=yellow]LIST[/color] / [color=yellow]LIST lo hi[/color]   List all lines, or only lines [color=white]lo..hi[/color]\n"
	h += "  [color=yellow]DEL n[/color]          Remove line [color=white]n[/color]\n"
	h += "  [color=yellow]NEW[/color]            Clear the whole source buffer\n"
	h += "  [color=yellow]COMPILE[/color]       Compile C source to 6502 machine code\n"
	h += "  [color=yellow]RUN[/color]            Execute last compiled program\n"
	h += "  [color=yellow]SAVE name[/color]      Write source to [color=white]user://name.c[/color]\n"
	h += "  [color=yellow]LOAD name[/color]      Read source from [color=white]user://name.c[/color]\n"
	h += "  [color=yellow]DIR[/color] / [color=yellow]CATALOG[/color]    List [color=white].c[/color] files on disk\n"
	h += "  [color=yellow]DEMO[/color] / [color=yellow]DEMOS[/color]     List built-in C demos\n"
	h += "  [color=yellow]DEMO name[/color]      Load demo source (then COMPILE and RUN)\n"
	h += "  [color=yellow]HELP[/color]           This screen\n"
	h += "\n[color=white]C language subset (Small-C)[/color]\n"
	h += "  Types: [color=white]int[/color] (16-bit), [color=white]char[/color] (8-bit)\n"
	h += "  Control: [color=white]if/else[/color], [color=white]while[/color], [color=white]for[/color], [color=white]return[/color], [color=white]break[/color]\n"
	h += "  Operators: [color=white]+ - * / % & | ^ ~ << >>[/color]\n"
	h += "  Compare:   [color=white]== != < > <= >= && || ![/color]\n"
	h += "  Assign:    [color=white]= += -=[/color]\n"
	h += "  Arrays: one-dimensional, [color=white]int a[10]; char *p;[/color]\n"
	h += "  Builtins: [color=white]putc(c), getc(), peek(addr), poke(addr, val)[/color]\n"
	h += "  Preprocessor: [color=white]#define NAME value[/color]\n"
	h += "  Comments: [color=white]// line[/color] and [color=white]/* block */[/color]\n"
	h += "\n[color=white]Examples — hello world[/color]\n"
	h += "  [color=gray]C> 10 main() {[/color]\n"
	h += "  [color=gray]C> 20   putc(72); putc(101); putc(108);[/color]\n"
	h += "  [color=gray]C> 30   putc(108); putc(111); putc(13);[/color]\n"
	h += "  [color=gray]C> 40 }[/color]\n"
	h += "  [color=gray]C> COMPILE[/color]\n"
	h += "  [color=gray]C> RUN[/color]              [color=gray]; prints Hello[/color]\n"
	h += "\n[color=lime]Source mirrored at $E000-$EFFF. SYS $F000 for banner.[/color]\n"
	return h

func banner_text() -> String:
	return "\n[color=green]C cart — Small-C compiler. Type HELP or DEMO for samples.[/color]\n"

func _demo_definitions() -> Dictionary:
	return {
		"hello": {
			"desc": "Print 'Hello' using putc()",
			"lines": [
				[10, "// Hello World demo for Small-C"],
				[20, "// putc(c) writes a character to the screen"],
				[30, "// ASCII codes: H=72 e=101 l=108 o=111 CR=13"],
				[40, "main() {"],
				[50, "  putc(72); // H"],
				[60, "  putc(101); // e"],
				[70, "  putc(108); // l"],
				[80, "  putc(108); // l"],
				[90, "  putc(111); // o"],
				[100, "  putc(13); // newline"],
				[110, "}"],
			],
		},
		"count": {
			"desc": "Print digits 0-9 with variables",
			"lines": [
				[10, "// Count demo — print digits 0 through 9"],
				[20, "// ASCII '0' is 48, so 48+i gives digit character"],
				[30, "main() {"],
				[40, "  int i;  // loop counter"],
				[50, "  i = 0;"],
				[60, "L1:"],
				[70, "  if (i == 10) return;"],
				[80, "  putc(48 + i);"],
				[90, "  i = i + 1;"],
				[100, "  goto L1;"],
				[110, "}"],
			],
		},
		"fib": {
			"desc": "Print first 10 Fibonacci numbers",
			"lines": [
				[10, "// Fibonacci demo — each number is sum of previous two"],
				[20, "// Sequence: 0, 1, 1, 2, 3"],
				[30, "main() {"],
				[40, "  int a; int b; int t; int i;"],
				[50, "  a = 0; b = 1; i = 0;"],
				[60, "  // print 'F:' header"],
				[70, "  putc(70); putc(58); putc(13);"],
				[80, "L1:"],
				[90, "  if (i == 10) return;"],
				[100, "  // print number followed by comma"],
				[110, "  putc(48 + a);"],
				[120, "  putc(44);  // comma"],
				[130, "  t = a + b; a = b; b = t;"],
				[140, "  i = i + 1;"],
				[150, "  goto L1;"],
				[160, "}"],
			],
		},
		"sum": {
			"desc": "Sum 1 to 10 = 55 using loop",
			"lines": [
				[10, "// Sum demo — compute 1+2+3+...+10 = 55"],
				[20, "main() {"],
				[30, "  int s; int i;"],
				[40, "  s = 0; i = 1;"],
				[50, "L1:"],
				[60, "  if (i == 11) return;"],
				[70, "  s = s + i;"],
				[80, "  i = i + 1;"],
				[90, "  goto L1;"],
				[100, "}"],
			],
		},
		"max": {
			"desc": "Function with parameters and return",
			"lines": [
				[10, "// Max function demo — demonstrates parameters"],
				[20, "// and return values in Small-C"],
				[30, "// Return value goes in A (low) / X (high) registers"],
				[40, "max(int a, int b) {"],
				[50, "  if (a > b) return a;  // a is larger"],
				[60, "  return b;              // b is larger"],
				[70, "}"],
				[80, "main() {"],
				[90, "  // print 'M=' then result of max(3,7)=7"],
				[100, "  putc(77); putc(61);"],
				[110, "  // max(3,7) = 7, ASCII '7' = 55"],
				[120, "  putc(55); putc(13);"],
				[130, "}"],
			],
		},
		"stars": {
			"desc": "Print a triangle of stars",
			"lines": [
				[10, "// Star triangle demo — nested loop pattern"],
				[20, "// Shows how to build up a pattern with putc()"],
				[30, "main() {"],
				[40, "  putc(84); putc(13); // print 'T' header"],
				[50, "  // Row 1: *"],
				[60, "  putc(42); putc(13);"],
				[70, "  // Row 2: **"],
				[80, "  putc(42); putc(42); putc(13);"],
				[90, "  // Row 3: ***"],
				[100, "  putc(42); putc(42); putc(42); putc(13);"],
				[110, "  // Row 4: ****"],
				[120, "  putc(42); putc(42); putc(42); putc(42); putc(13);"],
				[130, "  // Row 5: *****"],
				[140, "  putc(42); putc(42); putc(42); putc(42); putc(42); putc(13);"],
				[150, "}"],
			],
		},
	}

func _cmd_demo_list() -> void:
	var defs: Dictionary = _demo_definitions()
	var keys: Array = defs.keys()
	keys.sort()
	var buf := "\n[color=cyan]BUILT-IN C DEMOS[/color]\n"
	buf += "[color=yellow]  Load with DEMO name, then COMPILE and RUN[/color]\n\n"
	for k in keys:
		var entry: Dictionary = defs[k]
		buf += "[color=yellow]  %-12s[/color] %s\n" % [str(k), str(entry.get("desc", ""))]
	buf += "\n[color=lime]Example:  DEMO hello[/color]\n"
	_emit(buf)

func _cmd_demo_load(arg: String) -> void:
	var name := arg.strip_edges().to_lower()
	if name == "":
		_cmd_demo_list()
		return
	var defs: Dictionary = _demo_definitions()
	if not defs.has(name):
		_emit("[color=red]Unknown demo \"%s\". Type DEMO for a list.[/color]\n" % name)
		return
	var entry: Dictionary = defs[name]
	var raw_lines: Array = entry["lines"]
	_lines.clear()
	for pair in raw_lines:
		if pair is Array and (pair as Array).size() >= 2:
			var p: Array = pair as Array
			_lines.append([int(p[0]), str(p[1])])
	_lines.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	_last_ok = false
	_sync_workspace()
	_emit("[color=lime]Loaded demo \"%s\" (%d lines). Type COMPILE then RUN.[/color]\n" % [name, _lines.size()])

func _cmd_compile() -> void:
	if _lines.is_empty():
		_emit("[color=red]No source to compile.[/color]\n")
		return
	var source := ""
	for entry in _lines:
		source += str(entry[1]) + "\n"
	var lexer := CLexer.new()
	lexer.tokenize(source)
	if not lexer.errors.is_empty():
		for e in lexer.errors:
			_emit("[color=red]Lexer: %s[/color]\n" % e)
		_emit("[color=red]Compilation failed.[/color]\n")
		_last_ok = false
		return
	var parser := CParser.new()
	var ast := parser.parse(lexer.tokens)
	if not parser.errors.is_empty():
		for e in parser.errors:
			_emit("[color=red]Parser: %s[/color]\n" % e)
		_emit("[color=red]Compilation failed.[/color]\n")
		_last_ok = false
		return
	var codegen := CCodeGen.new()
	var ok := codegen.generate(ast, memory)
	if not ok:
		for e in codegen.errors:
			_emit("[color=red]CodeGen: %s[/color]\n" % e)
		_emit("[color=red]Compilation failed.[/color]\n")
		_last_ok = false
		return
	_last_ok = true
	_last_start = codegen.last_start
	_last_end = codegen.last_end
	var nbytes := 0
	if _last_start >= 0 and _last_end >= _last_start:
		nbytes = _last_end - _last_start + 1
	_emit("[color=lime]Compiled %d source line(s), %d byte(s) at $%04X-$%04X.[/color]\n" % [_lines.size(), nbytes, _last_start, _last_end])

func _cmd_run() -> void:
	if not _last_ok or _last_start < 0:
		_emit("[color=red]COMPILE first (no object code).[/color]\n")
		return
	var cpu = computer.cpu
	cpu.halted = false
	cpu.A = 0
	cpu.X = 0
	cpu.Y = 0
	cpu.P = 0x24
	memory.prepare_cpu_stack_for_user_rts(cpu)
	cpu.PC = _last_start & 0xFFFF
	cpu.run(50000)

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
	var path := "user://%s.c" % base
	var body_text := ""
	for i in range(_lines.size()):
		if i > 0:
			body_text += "\n"
		body_text += "%d %s" % [int(_lines[i][0]), str(_lines[i][1])]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(body_text)
		file.close()
		_emit("[color=lime]Saved %d line(s) to %s.c[/color]\n" % [_lines.size(), base])
	else:
		_emit("[color=red]SAVE failed.[/color]\n")

func _cmd_load(raw_name: String) -> void:
	var base := _sanitize_name(raw_name)
	var path := "user://%s.c" % base
	if not FileAccess.file_exists(path):
		_emit("[color=red]File not found: %s.c[/color]\n" % base)
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
	_emit("[color=lime]Loaded %d line(s) from %s.c[/color]\n" % [_lines.size(), base])

func _cmd_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		_emit("[color=red]Cannot open disk.[/color]\n")
		return
	var buf := "\n[color=cyan]user://[/color]\n"
	var exts := [".c"]
	for ext in exts:
		buf += "[color=white]%s[/color]\n" % ext
		dir.list_dir_begin()
		var file_name := dir.get_next()
		var count := 0
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(ext):
				buf += "[color=yellow]  %s[/color]\n" % file_name.trim_suffix(ext)
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
	_last_ok = false
	if data.has("lines"):
		for item in data["lines"]:
			if item is Dictionary:
				var d: Dictionary = item
				if d.has("ln") and d.has("t"):
					_lines.append([int(d["ln"]), str(d["t"])])
	_lines.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	_sync_workspace()

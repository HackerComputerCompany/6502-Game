class_name CartAsm
extends ROMCart

var _lines: Array = []
var _asm: Assembler6502
var _last_ok: bool = false

const WORKSPACE_START = 0xE000
const WORKSPACE_END = 0xF000
const BANK_START = 0xF000
const BANK_END = 0xFC00

func _init() -> void:
	id = 2
	name = "ASM"
	description = "6502 assembler cart; SAVEOBJ/HC65, .asm source, DEMO"
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
	if upper.begins_with("SAVEOBJ "):
		_cmd_save_binary(t.substr(8).strip_edges(), true)
		return true
	if upper.begins_with("SAVEBIN "):
		_cmd_save_binary(t.substr(8).strip_edges(), false)
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
	var h := "\n[color=cyan]ASM cart — 6502 source + two-pass assembler[/color]\n"
	h += "[color=white]Quick reference[/color]\n"
	h += "  [color=yellow]n text[/color]       Store/replace line [color=white]n[/color] with assembly source\n"
	h += "  [color=yellow]n[/color]             Delete line [color=white]n[/color] (same as [color=yellow]DEL n[/color])\n"
	h += "  [color=yellow]LIST[/color] / [color=yellow]LIST lo hi[/color]   List all lines, or only lines [color=white]lo..hi[/color]\n"
	h += "  [color=yellow]DEL n[/color]          Remove line [color=white]n[/color]\n"
	h += "  [color=yellow]NEW[/color]            Clear the whole source buffer\n"
	h += "  [color=yellow]ASM[/color]            Assemble into RAM (default origin [color=white]$0800[/color], or [color=white].ORG[/color])\n"
	h += "  [color=yellow]RUN[/color]            Execute last successful object from [color=white]ASM[/color] (up to 10k cycles)\n"
	h += "  [color=yellow]SYM[/color]            Show labels and [color=white].EQU[/color] names after [color=yellow]ASM[/color]\n"
	h += "  [color=yellow]HEX[/color]            Hex dump of the last assembled byte range\n"
	h += "  [color=yellow]SAVE name[/color]      Write source to [color=white]user://name.asm[/color]\n"
	h += "  [color=yellow]LOAD name[/color]      Read source from [color=white]user://name.asm[/color]\n"
	h += "  [color=yellow]SAVEOBJ name[/color]    HC65 object [color=white]user://name.obj[/color] (after [color=yellow]ASM[/color]; see [color=white].EXPORT[/color] / [color=white].HELP_*[/color])\n"
	h += "  [color=yellow]SAVEBIN name[/color]    Raw [color=white]BSAVE[/color]-style [color=white]user://name.bin[/color] (2-byte addr + bytes)\n"
	h += "  [color=yellow]DIR[/color] / [color=yellow]CATALOG[/color]    List [color=white].asm[/color], [color=white].obj[/color], [color=white].bin[/color] on disk\n"
	h += "  [color=yellow]DEMO[/color] / [color=yellow]DEMOS[/color]     List built-in ASM demos\n"
	h += "  [color=yellow]DEMO name[/color]      Load demo source (then [color=yellow]ASM[/color] and [color=yellow]RUN[/color])\n"
	h += "  [color=yellow]HELP[/color]           This screen\n"
	h += "\n[color=white]BASIC:[/color] [color=gray]LOADOBJ \"f.obj\", MYNAME[/color] then call [color=gray]MYNAME[/color] as a statement; [color=gray]HELP MYNAME[/color] if [color=white].HELP_*[/color] set.\n"
	h += "  [color=yellow]CART BASIC[/color]     Return to BASIC cart\n"
	h += "\n[color=white]Examples — edit / assemble / run[/color]\n"
	h += "  [color=gray]ASM> NEW[/color]\n"
	h += "  [color=gray]ASM> 10 LDA #$41[/color]\n"
	h += "  [color=gray]ASM> 20 STA $C002[/color]     [color=gray]; char to screen[/color]\n"
	h += "  [color=gray]ASM> 30 LDA #$0D[/color]\n"
	h += "  [color=gray]ASM> 40 STA $C003[/color]     [color=gray]; flush line to terminal[/color]\n"
	h += "  [color=gray]ASM> 50 RTS[/color]\n"
	h += "  [color=gray]ASM> LIST[/color]\n"
	h += "  [color=gray]ASM> ASM[/color]\n"
	h += "  [color=gray]ASM> RUN[/color]              [color=gray]; prints A then newline[/color]\n"
	h += "\n[color=white]Examples — labels and branches[/color]\n"
	h += "  [color=gray]ASM> 10 START: LDA #$00[/color]   [color=gray]; label before opcode uses ':'[/color]\n"
	h += "  [color=gray]ASM> 20 BEQ SKIP[/color]        [color=gray]; branch when Z=1[/color]\n"
	h += "  [color=gray]ASM> 30 LDA #$58[/color]         [color=gray]; 'X' if branch not taken[/color]\n"
	h += "  [color=gray]ASM> 40 SKIP: LDA #$59[/color]   [color=gray]; 'Y' when branch taken (label needs ':')[/color]\n"
	h += "  [color=gray]ASM> 50 STA $C002[/color]\n"
	h += "  [color=gray]ASM> 60 RTS[/color]\n"
	h += "\n[color=white]Command details (with examples)[/color]\n"
	h += "  [color=yellow]NEW[/color] — Clears lines and invalidates the last ASM. [color=gray]NEW[/color]\n"
	h += "  [color=yellow]n text[/color] — Store line [color=white]n[/color]. [color=gray]120 LDA #$00[/color]\n"
	h += "  [color=yellow]n[/color] — Delete line [color=white]n[/color]. [color=gray]120[/color]\n"
	h += "  [color=yellow]LIST[/color] — Show all. [color=yellow]LIST 50 200[/color] — only lines 50–200.\n"
	h += "  [color=yellow]DEL n[/color] — Remove one line. [color=gray]DEL 120[/color]\n"
	h += "  [color=yellow]ASM[/color] — Two-pass assemble into RAM; errors print in red.\n"
	h += "  [color=yellow]RUN[/color] — CPU runs from last object start (10k cycles). [color=gray]ASM[/color] first.\n"
	h += "  [color=yellow]SYM[/color] — Labels + [color=white].EQU[/color] constants after a good [color=gray]ASM[/color].\n"
	h += "  [color=yellow]HEX[/color] — Hex dump of last object (first 32 rows max).\n"
	h += "  [color=yellow]SAVE name[/color] — [color=gray]SAVE myprog[/color] → [color=white]user://myprog.asm[/color]\n"
	h += "  [color=yellow]SAVEOBJ name[/color] — [color=gray]SAVEOBJ mylib[/color] → HC65 [color=white]user://mylib.obj[/color] (after [color=gray]ASM[/color])\n"
	h += "  [color=yellow]SAVEBIN name[/color] — Raw 2-byte addr + bytes [color=white]user://mylib.bin[/color] ([color=gray]BSAVE[/color]-compatible)\n"
	h += "  [color=yellow]LOAD name[/color] — [color=gray]LOAD myprog[/color] from [color=white]user://myprog.asm[/color]\n"
	h += "  [color=yellow]DIR[/color] — Lists [color=white].asm[/color] / [color=white].obj[/color] / [color=white].bin[/color] in [color=white]user://[/color].\n"
	h += "  [color=yellow]DEMO[/color] / [color=yellow]DEMO name[/color] — Built-in source; then [color=gray]ASM[/color] + [color=gray]RUN[/color].\n"
	h += "\n[color=white]Directives (mix with instructions by line number)[/color]\n"
	h += "  [color=yellow].EQU NAME expr[/color]   Constant (e.g. [color=gray].EQU PORT $C002[/color] then [color=gray]STA PORT[/color])\n"
	h += "  [color=yellow].ORG addr[/color]        Set PC origin for following object code\n"
	h += "  [color=yellow].BYTE b,b,...[/color]    Raw bytes ([color=gray].BYTE $48,$69[/color]) — often after [color=gray]RTS[/color]\n"
	h += "  [color=yellow].WORD w,w,...[/color]    16-bit words, low byte first\n"
	h += "  [color=yellow].DB \"text\"[/color]       String bytes ([color=gray].DB \"OK\"[/color])\n"
	h += "\n[color=white]6502 instructions (what the assembler accepts)[/color]\n"
	h += "  Mnemonics are case-insensitive. Typical operands: [color=yellow]#[/color][color=white]$hh[/color] or [color=white]#n[/color] immediate; [color=white]$addr[/color] zero page if [color=white]$00..$FF[/color] else absolute; [color=white]$addr,X[/color] / [color=white]$addr,Y[/color]; [color=white](zp,X)[/color] / [color=white](zp),Y[/color].\n"
	h += "  [color=yellow]JMP[/color] [color=white]($addr)[/color] indirect; [color=yellow]ASL A[/color] … [color=yellow]ROR A[/color] for accumulator shifts.\n"
	h += "  [color=yellow]Load / store / transfer:[/color] LDA LDX LDY  STA STX STY  TAX TXA TAY TYA  TXS TSX\n"
	h += "  [color=yellow]Arithmetic / logic:[/color] ADC SBC  AND ORA EOR  ASL LSR ROL ROR  (memory or [color=white]A[/color])\n"
	h += "  [color=yellow]Inc / dec:[/color] INC DEC memory  ·  INX DEX INY DEY registers\n"
	h += "  [color=yellow]Compare:[/color] CMP CPX CPY\n"
	h += "  [color=yellow]Branches (relative, use labels or $expr):[/color] BCC BCS BEQ BNE BMI BPL BVC BVS\n"
	h += "  [color=yellow]Jump / return / interrupt:[/color] JMP JSR RTS RTI BRK\n"
	h += "  [color=yellow]Stack:[/color] PHA PHP PLA PLP\n"
	h += "  [color=yellow]Flags:[/color] CLC SEC CLD SED CLI SEI CLV\n"
	h += "  [color=yellow]Other:[/color] NOP BIT\n"
	h += "  [color=gray]Machine I/O in this sim: STA $C002 writes a character; STA $C003 with $0D flushes a line; $C030 cart select.[/color]\n"
	h += "\n[color=white]Comments[/color]\n"
	h += "  Anything after [color=yellow];[/color] on a line is ignored (e.g. [color=gray]LDA #$01 ; load one[/color]).\n"
	h += "\n[color=white]Demos[/color]\n"
	h += "  [color=gray]ASM> DEMO[/color]              [color=gray]; list names[/color]\n"
	h += "  [color=gray]ASM> DEMO hello[/color]        [color=gray]; load sample, then ASM and RUN[/color]\n"
	h += "\n[color=lime]Source is mirrored at $E000-$EFFF. SYS $F000 runs the cart banner ROM.[/color]\n"
	return h

func banner_text() -> String:
	return "\n[color=green]ASM cart — 6502 editor + assembler. Type HELP or DEMO for samples.[/color]\n"


func _demo_definitions() -> Dictionary:
	## name -> { "desc": String, "lines": Array of [int, String] }
	return {
		"hello": {
			"desc": "Print 'A' and newline (screen $C002 / $C003)",
			"lines": [
				[10, "LDA #$41"],
				[20, "STA $C002"],
				[30, "LDA #$0D"],
				[40, "STA $C003"],
				[50, "RTS"],
			],
		},
		"stars": {
			"desc": "Print ten '*' characters",
			"lines": [
				[10, "LDX #$0A"],
				[20, "LOOP: LDA #$2A"],
				[30, "STA $C002"],
				[40, "DEX"],
				[50, "BNE LOOP"],
				[60, "LDA #$0D"],
				[70, "STA $C003"],
				[80, "RTS"],
			],
		},
		"digits": {
			"desc": "Print digits 0 through 9",
			"lines": [
				[10, "LDX #$00"],
				[20, "LOOP: TXA"],
				[30, "CLC"],
				[40, "ADC #$30"],
				[50, "STA $C002"],
				[60, "INX"],
				[70, "CPX #$0A"],
				[80, "BNE LOOP"],
				[90, "LDA #$0D"],
				[100, "STA $C003"],
				[110, "RTS"],
			],
		},
		"branch": {
			"desc": "BEQ forward to label SKIP (prints 'Y')",
			"lines": [
				[10, "LDA #$00"],
				[20, "BEQ SKIP"],
				[30, "LDA #$58"],
				[40, "STA $C002"],
				[50, "SKIP: LDA #$59"],
				[60, "STA $C002"],
				[70, "LDA #$0D"],
				[80, "STA $C003"],
				[90, "RTS"],
			],
		},
		"equ_star": {
			"desc": ".EQU alias for screen port, print '*'",
			"lines": [
				[5, ".EQU SCREEN $C002"],
				[10, "LDA #$2A"],
				[20, "STA SCREEN"],
				[30, "LDA #$0D"],
				[40, "STA $C003"],
				[50, "RTS"],
			],
		},
		"org_hi": {
			"desc": ".ORG $0900 then code (object not at $0800)",
			"lines": [
				[10, ".ORG $0900"],
				[20, "START: LDA #$48"],
				[30, "STA $C002"],
				[40, "LDA #$0D"],
				[50, "STA $C003"],
				[60, "RTS"],
			],
		},
		"data_end": {
			"desc": "Code then .BYTE padding after RTS",
			"lines": [
				[10, "LDA #$48"],
				[20, "STA $C002"],
				[30, "LDA #$0D"],
				[40, "STA $C003"],
				[50, "RTS"],
				[60, ".BYTE $00,$FF"],
			],
		},
	}


func _cmd_demo_list() -> void:
	var defs: Dictionary = _demo_definitions()
	var keys: Array = defs.keys()
	keys.sort()
	var buf := "\n[color=cyan]BUILT-IN ASM DEMOS[/color]\n"
	buf += "[color=yellow]  Load with DEMO name, then ASM and RUN[/color]\n\n"
	for k in keys:
		var entry: Dictionary = defs[k]
		buf += "[color=yellow]  %-12s[/color] %s\n" % [str(k), str(entry.get("desc", ""))]
	buf += "\n[color=lime]Example:  DEMO hello[/color]\n"
	_emit(buf)


func _cmd_demo_load(arg: String) -> void:
	var demo_name := arg.strip_edges().to_lower()
	if demo_name == "":
		_cmd_demo_list()
		return
	var defs: Dictionary = _demo_definitions()
	if not defs.has(demo_name):
		_emit("[color=red]Unknown demo \"%s\". Type DEMO for a list.[/color]\n" % demo_name)
		return
	var entry: Dictionary = defs[demo_name]
	var raw_lines: Array = entry["lines"]
	_lines.clear()
	for pair in raw_lines:
		if pair is Array and (pair as Array).size() >= 2:
			var p: Array = pair as Array
			_lines.append([int(p[0]), str(p[1])])
	_lines.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	_last_ok = false
	_sync_workspace()
	_emit("[color=lime]Loaded demo \"%s\" (%d lines). Type ASM then RUN.[/color]\n" % [demo_name, _lines.size()])

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
	cpu.A = 0
	cpu.X = 0
	cpu.Y = 0
	cpu.P = 0x24
	memory.prepare_cpu_stack_for_user_rts(cpu)
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

func _cmd_save_binary(raw_name: String, hc65: bool) -> void:
	if not _last_ok or _asm == null or _asm.last_start < 0 or _asm.last_end < _asm.last_start:
		_emit("[color=red]ASM successfully first (no object range).[/color]\n")
		return
	var base := _sanitize_name(raw_name)
	var ext := "obj" if hc65 else "bin"
	var path := "user://%s.%s" % [base, ext]
	var code := PackedByteArray()
	for a in range(_asm.last_start, _asm.last_end + 1):
		code.append(memory.peek(a) & 0xFF)
	var blob: PackedByteArray
	if hc65:
		var entry := _asm.object_entry if _asm.object_entry >= 0 else _asm.last_start
		var exarr: Array = []
		for s in _asm.meta_help_examples:
			exarr.append(str(s))
		blob = HC65Object.encode(
			_asm.last_start & 0xFFFF,
			entry & 0xFFFF,
			code,
			_asm.meta_export,
			_asm.meta_help_syntax,
			_asm.meta_help_desc,
			exarr
		)
	else:
		blob = PackedByteArray()
		blob.append(_asm.last_start & 0xFF)
		blob.append((_asm.last_start >> 8) & 0xFF)
		blob.append_array(code)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_buffer(blob)
		file.close()
		_emit("[color=lime]Wrote %d bytes to %s.%s[/color]\n" % [blob.size(), base, ext])
	else:
		_emit("[color=red]Write failed.[/color]\n")


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
	var buf := "\n[color=cyan]user://[/color]\n"
	var exts := [".asm", ".obj", ".bin"]
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

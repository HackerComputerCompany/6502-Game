class_name Assembler6502
extends RefCounted

var errors: Array[String] = []
var symbols: Dictionary = {} ## label -> int address
var equs: Dictionary = {} ## name -> int constant
var last_start: int = -1
var last_end: int = -1

var _enc: Dictionary = {}

func _init() -> void:
	_build_enc()

func _build_enc() -> void:
	var opcodes := {
		0x69: ["ADC", "IMM"], 0x65: ["ADC", "ZPG"], 0x75: ["ADC", "ZPX"],
		0x6D: ["ADC", "ABS"], 0x7D: ["ADC", "ABX"], 0x79: ["ADC", "ABY"],
		0x61: ["ADC", "IZX"], 0x71: ["ADC", "IZY"],
		0xE9: ["SBC", "IMM"], 0xE5: ["SBC", "ZPG"], 0xF5: ["SBC", "ZPX"],
		0xED: ["SBC", "ABS"], 0xFD: ["SBC", "ABX"], 0xF9: ["SBC", "ABY"],
		0xE1: ["SBC", "IZX"], 0xF1: ["SBC", "IZY"],
		0x29: ["AND", "IMM"], 0x25: ["AND", "ZPG"], 0x35: ["AND", "ZPX"],
		0x2D: ["AND", "ABS"], 0x3D: ["AND", "ABX"], 0x39: ["AND", "ABY"],
		0x21: ["AND", "IZX"], 0x31: ["AND", "IZY"],
		0x09: ["ORA", "IMM"], 0x05: ["ORA", "ZPG"], 0x15: ["ORA", "ZPX"],
		0x0D: ["ORA", "ABS"], 0x1D: ["ORA", "ABX"], 0x19: ["ORA", "ABY"],
		0x01: ["ORA", "IZX"], 0x11: ["ORA", "IZY"],
		0x49: ["EOR", "IMM"], 0x45: ["EOR", "ZPG"], 0x55: ["EOR", "ZPX"],
		0x4D: ["EOR", "ABS"], 0x5D: ["EOR", "ABX"], 0x59: ["EOR", "ABY"],
		0x41: ["EOR", "IZX"], 0x51: ["EOR", "IZY"],
		0x0A: ["ASL", "ACC"], 0x06: ["ASL", "ZPG"], 0x16: ["ASL", "ZPX"],
		0x0E: ["ASL", "ABS"], 0x1E: ["ASL", "ABX"],
		0x4A: ["LSR", "ACC"], 0x46: ["LSR", "ZPG"], 0x56: ["LSR", "ZPX"],
		0x4E: ["LSR", "ABS"], 0x5E: ["LSR", "ABX"],
		0x2A: ["ROL", "ACC"], 0x26: ["ROL", "ZPG"], 0x36: ["ROL", "ZPX"],
		0x2E: ["ROL", "ABS"], 0x3E: ["ROL", "ABX"],
		0x6A: ["ROR", "ACC"], 0x66: ["ROR", "ZPG"], 0x76: ["ROR", "ZPX"],
		0x6E: ["ROR", "ABS"], 0x7E: ["ROR", "ABX"],
		0xE6: ["INC", "ZPG"], 0xF6: ["INC", "ZPX"],
		0xEE: ["INC", "ABS"], 0xFE: ["INC", "ABX"],
		0xC6: ["DEC", "ZPG"], 0xD6: ["DEC", "ZPX"],
		0xCE: ["DEC", "ABS"], 0xDE: ["DEC", "ABX"],
		0xA9: ["LDA", "IMM"], 0xA5: ["LDA", "ZPG"], 0xB5: ["LDA", "ZPX"],
		0xAD: ["LDA", "ABS"], 0xBD: ["LDA", "ABX"], 0xB9: ["LDA", "ABY"],
		0xA1: ["LDA", "IZX"], 0xB1: ["LDA", "IZY"],
		0xA2: ["LDX", "IMM"], 0xA6: ["LDX", "ZPG"], 0xB6: ["LDX", "ZPY"],
		0xAE: ["LDX", "ABS"], 0xBE: ["LDX", "ABY"],
		0xA0: ["LDY", "IMM"], 0xA4: ["LDY", "ZPG"], 0xB4: ["LDY", "ZPX"],
		0xAC: ["LDY", "ABS"], 0xBC: ["LDY", "ABX"],
		0x85: ["STA", "ZPG"], 0x95: ["STA", "ZPX"],
		0x8D: ["STA", "ABS"], 0x9D: ["STA", "ABX"], 0x99: ["STA", "ABY"],
		0x81: ["STA", "IZX"], 0x91: ["STA", "IZY"],
		0x86: ["STX", "ZPG"], 0x96: ["STX", "ZPY"], 0x8E: ["STX", "ABS"],
		0x84: ["STY", "ZPG"], 0x94: ["STY", "ZPX"], 0x8C: ["STY", "ABS"],
		0xC9: ["CMP", "IMM"], 0xC5: ["CMP", "ZPG"], 0xD5: ["CMP", "ZPX"],
		0xCD: ["CMP", "ABS"], 0xDD: ["CMP", "ABX"], 0xD9: ["CMP", "ABY"],
		0xC1: ["CMP", "IZX"], 0xD1: ["CMP", "IZY"],
		0xE0: ["CPX", "IMM"], 0xE4: ["CPX", "ZPG"], 0xEC: ["CPX", "ABS"],
		0xC0: ["CPY", "IMM"], 0xC4: ["CPY", "ZPG"], 0xCC: ["CPY", "ABS"],
		0x90: ["BCC", "REL"], 0xB0: ["BCS", "REL"],
		0xF0: ["BEQ", "REL"], 0xD0: ["BNE", "REL"],
		0x30: ["BMI", "REL"], 0x10: ["BPL", "REL"],
		0x70: ["BVS", "REL"], 0x50: ["BVC", "REL"],
		0x4C: ["JMP", "ABS"], 0x6C: ["JMP", "IND"],
		0x20: ["JSR", "ABS"],
		0x60: ["RTS", "IMP"],
		0x40: ["RTI", "IMP"],
		0x24: ["BIT", "ZPG"], 0x2C: ["BIT", "ABS"],
		0xEA: ["NOP", "IMP"],
		0x00: ["BRK", "IMP"],
		0x48: ["PHA", "IMP"], 0x08: ["PHP", "IMP"],
		0x68: ["PLA", "IMP"], 0x28: ["PLP", "IMP"],
		0xAA: ["TAX", "IMP"], 0x8A: ["TXA", "IMP"],
		0xA8: ["TAY", "IMP"], 0x98: ["TYA", "IMP"],
		0x9A: ["TXS", "IMP"], 0xBA: ["TSX", "IMP"],
		0x18: ["CLC", "IMP"], 0x38: ["SEC", "IMP"],
		0xD8: ["CLD", "IMP"], 0xF8: ["SED", "IMP"],
		0x58: ["CLI", "IMP"], 0x78: ["SEI", "IMP"],
		0xB8: ["CLV", "IMP"],
		0xE8: ["INX", "IMP"], 0xC8: ["INY", "IMP"],
		0xCA: ["DEX", "IMP"], 0x88: ["DEY", "IMP"],
	}
	for opc in opcodes:
		var pair: Array = opcodes[opc]
		_enc["%s|%s" % [pair[0], pair[1]]] = opc

func _err(msg: String) -> void:
	errors.append(msg)

func assemble(memory: MemoryBus, editor_lines: Array) -> bool:
	errors.clear()
	symbols.clear()
	equs.clear()
	last_start = -1
	last_end = -1
	var sorted: Array = editor_lines.duplicate()
	sorted.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	var work: Array = []
	for entry in sorted:
		var raw: String = str(entry[1]).strip_edges()
		if raw == "":
			continue
		var sc := _strip_comment(raw)
		if sc == "":
			continue
		work.append({"ln": int(entry[0]), "text": sc})
	if work.is_empty():
		_err("No source lines.")
		return false
	## Pass 1: assign labels + LC (forward refs use max size for LDA-type = ABS)
	var lc := 0x0800
	for item in work:
		var t: String = item["text"]
		var parsed := _parse_labels_and_body(t)
		var body: String = parsed["body"]
		var labs: Array = parsed["labels"]
		for L in labs:
			symbols[L] = lc
		if body == "":
			continue
		var up := body.to_upper()
		if up.begins_with(".EQU "):
			var rest := body.substr(5).strip_edges()
			var eqp: Variant = _parse_equ(rest)
			if eqp == null:
				return false
			equs[eqp["name"]] = int(eqp["val"])
			continue
		if up.begins_with(".ORG "):
			var v := _parse_expr(body.substr(4).strip_edges(), true)
			if v < 0:
				return false
			lc = v
			continue
		var sz := _line_byte_size(body, lc, true)
		if sz < 0:
			return false
		lc += sz
	## Pass 2: emit
	lc = 0x0800
	var emit_start := -1
	var emit_end := -1
	for item in work:
		var t2: String = item["text"]
		var p2 := _parse_labels_and_body(t2)
		var body2: String = p2["body"]
		if body2 == "":
			continue
		var up2 := body2.to_upper()
		if up2.begins_with(".EQU "):
			continue
		if up2.begins_with(".ORG "):
			var v2 := _parse_expr(body2.substr(4).strip_edges(), true)
			if v2 < 0:
				return false
			lc = v2
			continue
		var bytes: Variant = _emit_line(memory, body2, lc, int(item["ln"]), false)
		if bytes == null:
			return false
		var pb: PackedByteArray = bytes
		if emit_start < 0:
			emit_start = lc
		for i in range(pb.size()):
			memory.poke((lc + i) & 0xFFFF, pb[i])
		lc += pb.size()
		emit_end = lc - 1
	last_start = emit_start
	last_end = emit_end
	return errors.is_empty()

func _strip_comment(s: String) -> String:
	var p := s.find(";")
	if p >= 0:
		return s.substr(0, p).strip_edges()
	return s.strip_edges()

func _parse_labels_and_body(line: String) -> Dictionary:
	var labels: Array = []
	var rest := line.strip_edges()
	while rest.length() > 0:
		var c0 := rest.find(":")
		if c0 < 0:
			break
		var lab := rest.substr(0, c0).strip_edges().to_upper()
		if lab == "" or not _is_label_token(lab):
			break
		labels.append(lab)
		rest = rest.substr(c0 + 1).strip_edges()
	return {"labels": labels, "body": rest}

func _is_label_token(s: String) -> bool:
	if s.is_empty():
		return false
	if not s[0].is_valid_identifier():
		return false
	for i in range(s.length()):
		var ch := s[i]
		if not (ch.is_valid_identifier() or ch == "_" or (ch >= "0" and ch <= "9")):
			return false
	return true

func _parse_equ(rest: String) -> Variant:
	var parts := rest.split(" ", false)
	if parts.size() < 2:
		_err(".EQU needs name and value")
		return null
	var nm := parts[0].strip_edges().to_upper()
	var val := _parse_expr(" ".join(parts.slice(1)).strip_edges(), true)
	if val < 0:
		return null
	return {"name": nm, "val": val}

func _parse_expr(s: String, allow_equ: bool) -> int:
	s = s.strip_edges()
	if s == "":
		return -1
	var u := s.to_upper()
	if allow_equ and equs.has(u):
		return int(equs[u])
	if symbols.has(u):
		return int(symbols[u])
	return _parse_number(s)

func _parse_number(s: String) -> int:
	s = s.strip_edges()
	if s == "":
		return -1
	if s.begins_with("$"):
		return _parse_hex_digits(s.substr(1).strip_edges())
	return _parse_hex_or_dec(s)

func _parse_hex_digits(s: String) -> int:
	## Hex only (after a leading `$` in source).
	s = s.strip_edges()
	if s == "":
		return -1
	var acc := 0
	for i in range(s.length()):
		var c := s[i]
		var d := -1
		if c >= "0" and c <= "9":
			d = c.unicode_at(0) - 48
		elif c >= "A" and c <= "F":
			d = 10 + c.unicode_at(0) - 65
		elif c >= "a" and c <= "f":
			d = 10 + c.unicode_at(0) - 97
		else:
			return -1
		acc = (acc << 4) | d
	return acc

func _parse_hex_or_dec(s: String) -> int:
	s = s.strip_edges()
	if s == "":
		return -1
	if s.is_valid_int():
		return int(s)
	var acc := 0
	for i in range(s.length()):
		var c := s[i]
		var d := -1
		if c >= "0" and c <= "9":
			d = c.unicode_at(0) - 48
		elif c >= "A" and c <= "F":
			d = 10 + c.unicode_at(0) - 65
		elif c >= "a" and c <= "f":
			d = 10 + c.unicode_at(0) - 97
		else:
			return -1
		acc = (acc << 4) | d
	return acc

func _line_byte_size(body: String, at_pc: int, pass1: bool) -> int:
	var b: Variant = _emit_line(null, body, at_pc, -1, pass1)
	if b == null:
		return -1
	return (b as PackedByteArray).size()

func _emit_line(_memory: Variant, body: String, at_pc: int, src_ln: int, pass1: bool) -> Variant:
	var up := body.to_upper().strip_edges()
	var ln_str := str(src_ln) if src_ln >= 0 else "?"
	if up.begins_with(".BYTE "):
		return _emit_byte_list(body.substr(6).strip_edges(), ln_str)
	if up.begins_with(".WORD "):
		return _emit_word_list(body.substr(6).strip_edges(), ln_str)
	if up.begins_with(".DB "):
		return _emit_db(body.substr(4).strip_edges(), ln_str)
	var sp := body.find(" ")
	var mnem := ""
	var oper := ""
	if sp < 0:
		mnem = body.strip_edges().to_upper()
		oper = ""
	else:
		mnem = body.substr(0, sp).strip_edges().to_upper()
		oper = body.substr(sp + 1).strip_edges()
	if mnem == "":
		_err("Line %s: missing mnemonic" % ln_str)
		return null
	if _is_branch(mnem):
		return _emit_branch(mnem, oper, at_pc, ln_str, pass1)
	if mnem == "JMP" and oper.strip_edges().begins_with("("):
		var vi := _parse_indirect_target(oper)
		if vi < 0:
			_err("Line %s: bad JMP ()" % ln_str)
			return null
		return _bytes_opc("JMP", "IND", vi, at_pc, ln_str, pass1)
	return _emit_data_op(mnem, oper, at_pc, ln_str, pass1)

func _emit_byte_list(rest: String, ln_str: String) -> Variant:
	var out := PackedByteArray()
	for part in rest.split(",", false):
		var p := part.strip_edges()
		if p == "":
			continue
		var v := _parse_expr(p, true)
		if v < 0 or v > 0xFFFF:
			_err("Line %s: bad .BYTE '%s'" % [ln_str, p])
			return null
		out.append(v & 0xFF)
	return out

func _emit_word_list(rest: String, ln_str: String) -> Variant:
	var out := PackedByteArray()
	for part in rest.split(",", false):
		var p := part.strip_edges()
		if p == "":
			continue
		var v := _parse_expr(p, true)
		if v < 0 or v > 0xFFFF:
			_err("Line %s: bad .WORD '%s'" % [ln_str, p])
			return null
		out.append(v & 0xFF)
		out.append((v >> 8) & 0xFF)
	return out

func _emit_db(rest: String, ln_str: String) -> Variant:
	var out := PackedByteArray()
	rest = rest.strip_edges()
	if rest.length() >= 2 and rest[0] == "\"" and rest[rest.length() - 1] == "\"":
		var inner := rest.substr(1, rest.length() - 2)
		for i in range(inner.length()):
			out.append(inner.unicode_at(i) & 0xFF)
		return out
	return _emit_byte_list(rest, ln_str)

func _is_branch(m: String) -> bool:
	return m in ["BCC", "BCS", "BEQ", "BNE", "BMI", "BPL", "BVC", "BVS"]

func _emit_branch(mnem: String, oper: String, at_pc: int, ln_str: String, pass1: bool) -> Variant:
	var opc: int = int(_enc.get("%s|REL" % mnem, -1))
	if opc < 0:
		return null
	var target := _parse_expr(oper.strip_edges(), true)
	if target < 0:
		if pass1:
			return PackedByteArray([opc, 0])
		_err("Line %s: unknown branch target" % ln_str)
		return null
	var rel_i := target - (at_pc + 2)
	if rel_i < -128 or rel_i > 127:
		_err("Line %s: branch out of range (%d)" % [ln_str, rel_i])
		return null
	var rel_b := rel_i & 0xFF
	return PackedByteArray([opc, rel_b])

func _bytes_opc(mnem: String, mode: String, oper_or_val, at_pc: int, ln_str: String, pass1: bool) -> Variant:
	var opc_b := int(_enc.get("%s|%s" % [mnem, mode], -1))
	if opc_b < 0:
		_err("Line %s: illegal %s %s" % [ln_str, mnem, mode])
		return null
	match mode:
		"IMP", "ACC":
			return PackedByteArray([opc_b])
		"IMM":
			var v := _parse_expr(str(oper_or_val).substr(1).strip_edges(), true)
			if v < 0 and pass1:
				return PackedByteArray([opc_b, 0])
			if v < 0 or v > 0xFF:
				_err("Line %s: bad #" % ln_str)
				return null
			return PackedByteArray([opc_b, v & 0xFF])
		"ZPG", "ZPX", "ZPY":
			var ad := _parse_addr_plain(str(oper_or_val), mode)
			if ad < 0:
				if pass1 and _is_ident(_strip_indexing(str(oper_or_val), mode)):
					ad = 0
				else:
					return null
			if ad > 0xFF:
				_err("Line %s: ZPG > $FF" % ln_str)
				return null
			return PackedByteArray([opc_b, ad & 0xFF])
		"ABS", "ABX", "ABY":
			var ab := _parse_addr_plain(str(oper_or_val), mode)
			if ab < 0:
				if pass1 and _is_ident(_strip_indexing(str(oper_or_val), mode)):
					ab = 0
				else:
					return null
			return PackedByteArray([opc_b, ab & 0xFF, (ab >> 8) & 0xFF])
		"IND":
			var indv := int(oper_or_val)
			return PackedByteArray([opc_b, indv & 0xFF, (indv >> 8) & 0xFF])
		"IZX", "IZY":
			var zv := int(oper_or_val)
			if zv < 0 or zv > 0xFF:
				_err("Line %s: bad ZP indirect" % ln_str)
				return null
			return PackedByteArray([opc_b, zv & 0xFF])
	return null

func _is_ident(s: String) -> bool:
	s = s.strip_edges().to_upper()
	if s.is_empty():
		return false
	return s[0].is_valid_identifier()

func _strip_indexing(oper: String, mode: String) -> String:
	var u := oper.strip_edges().to_upper()
	if mode == "ABX" or mode == "ZPX":
		if u.ends_with(",X"):
			return oper.strip_edges().substr(0, oper.strip_edges().length() - 2).strip_edges()
	if mode == "ABY" or mode == "ZPY":
		if u.ends_with(",Y"):
			return oper.strip_edges().substr(0, oper.strip_edges().length() - 2).strip_edges()
	return oper.strip_edges()

func _parse_addr_plain(oper: String, mode: String) -> int:
	var base := _strip_indexing(oper, mode)
	return _parse_expr(base, true)

func _infer_mode(mnem: String, oper: String, ln_str: String, pass1: bool) -> String:
	var o := oper.strip_edges()
	var u := o.to_upper()
	if o == "":
		if _enc.has("%s|IMP" % mnem):
			return "IMP"
		_err("Line %s: %s needs operand" % [ln_str, mnem])
		return ""
	if u == "A" and _enc.has("%s|ACC" % mnem):
		return "ACC"
	if u.begins_with("#"):
		if _enc.has("%s|IMM" % mnem):
			return "IMM"
		return ""
	if u.begins_with("(") and u.ends_with("),Y") and _enc.has("%s|IZY" % mnem):
		return "IZY"
	if u.begins_with("(") and u.ends_with(",X)") and _enc.has("%s|IZX" % mnem):
		return "IZX"
	if u.begins_with("(") and u.ends_with(")") and mnem == "JMP":
		return "IND"
	if u.ends_with(",X") and not u.begins_with("("):
		var bx_base := _strip_indexing(o, "ABX")
		var bx := _parse_expr(bx_base, true)
		if bx < 0 and pass1 and _is_ident(bx_base):
			if _enc.has("%s|ABX" % mnem):
				return "ABX"
			return ""
		if bx >= 0 and bx <= 0xFF and _enc.has("%s|ZPX" % mnem):
			return "ZPX"
		if _enc.has("%s|ABX" % mnem):
			return "ABX"
		return ""
	if u.ends_with(",Y") and not u.begins_with("("):
		var by_base := _strip_indexing(o, "ABY")
		var by := _parse_expr(by_base, true)
		if by < 0 and pass1 and _is_ident(by_base):
			if _enc.has("%s|ABY" % mnem):
				return "ABY"
			return ""
		if by >= 0 and by <= 0xFF and _enc.has("%s|ZPY" % mnem):
			return "ZPY"
		if _enc.has("%s|ABY" % mnem):
			return "ABY"
		return ""
	var va := _parse_expr(o, true)
	if va < 0 and pass1 and _is_ident(o):
		if _enc.has("%s|ABS" % mnem):
			return "ABS"
		return ""
	if va < 0:
		_err("Line %s: bad '%s'" % [ln_str, o])
		return ""
	if va <= 0xFF and _enc.has("%s|ZPG" % mnem):
		return "ZPG"
	if _enc.has("%s|ABS" % mnem):
		return "ABS"
	_err("Line %s: no mode for %s" % [ln_str, mnem])
	return ""

func _emit_data_op(mnem: String, oper: String, at_pc: int, ln_str: String, pass1: bool) -> Variant:
	var mode := _infer_mode(mnem, oper, ln_str, pass1)
	if mode == "":
		return null
	match mode:
		"IND":
			var vi := _parse_indirect_target(oper)
			if vi < 0:
				return null
			return _bytes_opc(mnem, "IND", vi, at_pc, ln_str, pass1)
		"IZX":
			var s := oper.strip_edges()
			var lp := s.find("(")
			var comx := s.find(",X)")
			if lp < 0 or comx < lp:
				_err("Line %s: bad (zp,X)" % ln_str)
				return null
			var z := _parse_expr(s.substr(lp + 1, comx - lp - 1).strip_edges(), true)
			if z < 0 and pass1:
				z = 0
			return _bytes_opc(mnem, "IZX", z, at_pc, ln_str, pass1)
		"IZY":
			var s2 := oper.strip_edges()
			var c := s2.find(")")
			var inner := s2.substr(1, c - 1).strip_edges()
			var z2 := _parse_expr(inner, true)
			if z2 < 0 and pass1:
				z2 = 0
			return _bytes_opc(mnem, "IZY", z2, at_pc, ln_str, pass1)
		_:
			return _bytes_opc(mnem, mode, oper, at_pc, ln_str, pass1)

func _parse_indirect_target(oper: String) -> int:
	var s := oper.strip_edges()
	if not s.begins_with("("):
		return -1
	var c := s.find(")")
	if c < 2:
		return -1
	var inner := s.substr(1, c - 1).strip_edges()
	return _parse_expr(inner, true)

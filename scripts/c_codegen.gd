## AST -> 6502 assembly -> machine code (via Assembler6502).
## 16-bit values: low byte in A, high byte in X (AX pair)
class_name CCodeGen
extends RefCounted

var errors: Array[String] = []
var last_start: int = -1
var last_end: int = -1

var _asm_lines: Array = []
var _label_counter: int = 0
var _str_label_counter: int = 0
var _var_map: Dictionary = {}
var _local_offsets: Dictionary = {}
var _string_labels: Dictionary = {}
var _global_offset: int = 0
var _local_sp: int = 0
var _func_name: String = ""
var _break_target: String = ""
var _continue_target: String = ""

const ZP_FP = 0xF0
const ZP_FP_HI = 0xF1
const ZP_TMP = 0xF4
const ZP_TMP_HI = 0xF5
const ZP_TMP2 = 0xF6
const ZP_TMP2_HI = 0xF7
const CODE_ORG = 0x0800

func generate(ast: Dictionary, memory) -> bool:
	errors.clear()
	_asm_lines.clear()
	_label_counter = 0
	_str_label_counter = 0
	_var_map.clear()
	_local_offsets.clear()
	_string_labels.clear()
	_global_offset = 0
	_local_sp = 0
	_func_name = ""
	_break_target = ""
	_continue_target = ""
	last_start = -1
	last_end = -1
	_scan_globals(ast)
	_scan_strings(ast)
	_emit(".ORG $%04X" % CODE_ORG)
	_emit("LDA #0")
	_emit("STA %d" % ZP_FP)
	_emit("STA %d" % ZP_FP_HI)
	for decl in ast["declarations"]:
		if decl["type"] == "FuncDef":
			_gen_func(decl)
	_emit("JMP $FFFF")
	_emit_data()
	var asm := Assembler6502.new()
	var ok := asm.assemble(memory, _asm_lines)
	if not ok:
		for e in asm.errors:
			errors.append(e)
		return false
	last_start = asm.last_start
	last_end = asm.last_end
	return true

func _emit(line: String) -> void:
	_asm_lines.append([_asm_lines.size() * 10, line])

func _lbl() -> String:
	var l := "C%d" % _label_counter
	_label_counter += 1
	return l

func _scan_globals(ast: Dictionary) -> void:
	for decl in ast["declarations"]:
		if decl["type"] == "VarDecl" and decl.get("is_global", false):
			var sz: int = decl.get("array_size", -1)
			if sz > 0:
				_var_map[decl["name"]] = {"off": _global_offset, "sz": sz}
				_global_offset += sz
			else:
				_var_map[decl["name"]] = {"off": _global_offset, "sz": 2}
				_global_offset += 2

func _scan_strings(node) -> void:
	if node is Dictionary:
		if node["type"] == "StringLit" and not _string_labels.has(node["value"]):
			_string_labels[node["value"]] = "CS%d" % _str_label_counter
			_str_label_counter += 1
		for key in node:
			if key != "type":
				_scan_strings(node[key])
	elif node is Array:
		for item in node:
			_scan_strings(item)

func _gen_func(decl: Dictionary) -> void:
	_func_name = decl["name"]
	_local_offsets.clear()
	_local_sp = 0
	for stmt in decl["body"]["statements"]:
		_scan_locals(stmt)
	_emit("")
	_emit("%s:" % _func_name)
	_emit("PHA")
	_emit("TXA")
	_emit("PHA")
	_emit("LDA #%d" % ((_local_sp + 2) & 0xFF))
	_emit("CLC")
	_emit("ADC %d" % ZP_FP)
	_emit("STA %d" % ZP_FP)
	_emit("LDA #0")
	_emit("ADC %d" % ZP_FP_HI)
	_emit("STA %d" % ZP_FP_HI)
	for stmt in decl["body"]["statements"]:
		_gen_stmt(stmt)
	_emit("%s_END:" % _func_name)
	_emit("LDY #0")
	_emit("LDA (%d),Y" % ZP_FP)
	_emit("TAX")
	_emit("DEY")
	_emit("LDA (%d),Y" % ZP_FP)
	_emit("STA %d" % ZP_FP)
	_emit("STX %d" % ZP_FP_HI)
	_emit("PLA")
	_emit("TAX")
	_emit("PLA")
	_emit("RTS")

func _scan_locals(node) -> void:
	if node is Dictionary:
		if node["type"] == "VarDecl" and not node.get("is_global", false):
			var sz: int = node.get("array_size", 1)
			if sz <= 0:
				sz = 2
			_local_offsets[node["name"]] = {"off": -_local_sp - 2, "sz": sz}
			_local_sp += sz
		for key in node:
			if key != "type":
				_scan_locals(node[key])
	elif node is Array:
		for item in node:
			_scan_locals(item)

func _gen_stmt(stmt: Dictionary) -> void:
	match stmt.get("type", ""):
		"Block":
			for s in stmt["statements"]:
				_gen_stmt(s)
		"IfStmt":
			_gen_if(stmt)
		"WhileStmt":
			_gen_while(stmt)
		"ForStmt":
			_gen_for(stmt)
		"ReturnStmt":
			if stmt["expr"] != null:
				_gen_expr(stmt["expr"])
			else:
				_emit("LDA #0")
				_emit("LDX #0")
			_emit("JMP %s_END" % _func_name)
		"BreakStmt":
			if _break_target != "":
				_emit("JMP %s" % _break_target)
		"ExprStmt":
			_gen_expr(stmt["expr"])
			_emit("LDA #0")
			_emit("LDX #0")
		"VarDecl":
			if stmt.get("init") != null and not stmt.get("is_global", false):
				_gen_expr(stmt["init"])
				_store_local(stmt["name"])

func _gen_if(stmt: Dictionary) -> void:
	var el := _lbl()
	var end := _lbl()
	_gen_expr(stmt["cond"])
	_emit("ORA %d" % ZP_TMP_HI)
	_emit("BNE %s" % el)
	_gen_stmt(stmt["then_body"])
	_emit("JMP %s" % end)
	_emit("%s:" % el)
	if stmt["else_body"] != null:
		_gen_stmt(stmt["else_body"])
	_emit("%s:" % end)

func _gen_while(stmt: Dictionary) -> void:
	var loop := _lbl()
	var end := _lbl()
	var prev_break := _break_target
	var prev_cont := _continue_target
	_break_target = end
	_continue_target = loop
	_emit("%s:" % loop)
	_gen_expr(stmt["cond"])
	_emit("ORA %d" % ZP_TMP_HI)
	_emit("BEQ %s" % end)
	_gen_stmt(stmt["body"])
	_emit("JMP %s" % loop)
	_emit("%s:" % end)
	_break_target = prev_break
	_continue_target = prev_cont

func _gen_for(stmt: Dictionary) -> void:
	var loop := _lbl()
	var end := _lbl()
	var step := _lbl()
	var prev_break := _break_target
	var prev_cont := _continue_target
	_break_target = end
	_continue_target = step
	if stmt["init"] != null:
		_gen_expr(stmt["init"])
		_emit("TAX")
		_emit("PLA")
	_emit("%s:" % loop)
	if stmt["cond"] != null:
		_gen_expr(stmt["cond"])
		_emit("ORA %d" % ZP_TMP_HI)
		_emit("BEQ %s" % end)
	_gen_stmt(stmt["body"])
	_emit("%s:" % step)
	if stmt["step"] != null:
		_gen_expr(stmt["step"])
		_emit("TAX")
		_emit("PLA")
	_emit("JMP %s" % loop)
	_emit("%s:" % end)
	_break_target = prev_break
	_continue_target = prev_cont

func _gen_expr(expr: Dictionary) -> void:
	if expr == null:
		_emit("LDA #0")
		_emit("LDX #0")
		return
	match expr["type"]:
		"NumberLit":
			var v: int = expr["value"]
			v = v & 0xFFFF
			_emit("LDA #%d" % (v & 0xFF))
			_emit("LDX #%d" % ((v >> 8) & 0xFF))
		"IdentRef":
			_load_ident(expr["name"])
		"StringLit":
			var lbl: String = _string_labels.get(expr["value"], "CS0")
			_emit("LDA #<%s" % lbl)
			_emit("LDX #>%s" % lbl)
		"AssignExpr":
			_gen_assign(expr)
		"BinaryExpr":
			_gen_binary(expr)
		"UnaryExpr":
			_gen_unary(expr)
		"FuncCall":
			_gen_call(expr)
		"ArrayRef":
			_gen_array_ref(expr)
		"DerefExpr":
			_gen_deref(expr)
		"AddrOfExpr":
			_gen_addr_of(expr)
		_:
			_emit("LDA #0")
			_emit("LDX #0")

func _load_ident(name: String) -> void:
	if _var_map.has(name):
		var info: Dictionary = _var_map[name]
		_emit("LDA GDATA + %d" % info["off"])
		_emit("LDX GDATA + %d" % (info["off"] + 1))
	elif _local_offsets.has(name):
		var info: Dictionary = _local_offsets[name]
		var off: int = info["off"] & 0xFF
		_emit("LDY #%d" % off)
		_emit("LDA (%d),Y" % ZP_FP)
		_emit("STA %d" % ZP_TMP)
		_emit("INY")
		_emit("LDA (%d),Y" % ZP_FP)
		_emit("STA %d" % ZP_TMP_HI)
		_emit("LDA %d" % ZP_TMP)
		_emit("LDX %d" % ZP_TMP_HI)
	else:
		_emit("LDA #0")
		_emit("LDX #0")

func _store_local(name: String) -> void:
	if _local_offsets.has(name):
		var info: Dictionary = _local_offsets[name]
		var off: int = info["off"] & 0xFF
		_emit("STA %d" % ZP_TMP)
		_emit("STX %d" % ZP_TMP_HI)
		_emit("LDY #%d" % off)
		_emit("LDA %d" % ZP_TMP)
		_emit("STA (%d),Y" % ZP_FP)
		_emit("INY")
		_emit("LDA %d" % ZP_TMP_HI)
		_emit("STA (%d),Y" % ZP_FP)
	elif _var_map.has(name):
		var info: Dictionary = _var_map[name]
		_emit("STA GDATA + %d" % info["off"])
		_emit("STX GDATA + %d" % (info["off"] + 1))

func _gen_assign(expr: Dictionary) -> void:
	var target = expr["target"]
	var op: String = expr["op"]
	var val: Dictionary = expr["value"]
	_gen_expr(val)
	_emit("STA %d" % ZP_TMP)
	_emit("STX %d" % ZP_TMP_HI)
	if target["type"] == "IdentRef":
		var name: String = target["name"]
		if op == "=":
			_emit("LDA %d" % ZP_TMP)
			_emit("LDX %d" % ZP_TMP_HI)
		elif op == "+=":
			_load_ident(name)
			_emit("CLC")
			_emit("ADC %d" % ZP_TMP)
			_emit("STA %d" % ZP_TMP)
			_emit("TXA")
			_emit("ADC %d" % ZP_TMP_HI)
			_emit("TAX")
			_emit("LDA %d" % ZP_TMP)
		elif op == "-=":
			_load_ident(name)
			_emit("SEC")
			_emit("SBC %d" % ZP_TMP)
			_emit("STA %d" % ZP_TMP)
			_emit("TXA")
			_emit("SBC %d" % ZP_TMP_HI)
			_emit("TAX")
			_emit("LDA %d" % ZP_TMP)
		_store_local(name)
	_emit("LDA %d" % ZP_TMP)
	_emit("LDX %d" % ZP_TMP_HI)

func _gen_binary(expr: Dictionary) -> void:
	var op: String = expr["op"]
	var left: Dictionary = expr["left"]
	var right: Dictionary = expr["right"]
	_gen_expr(left)
	_emit("STA %d" % ZP_TMP)
	_emit("STX %d" % ZP_TMP_HI)
	_gen_expr(right)
	_emit("STA %d" % ZP_TMP2)
	_emit("STX %d" % ZP_TMP2_HI)
	match op:
		"+":
			_emit("CLC")
			_emit("ADC %d" % ZP_TMP)
			_emit("STA %d" % ZP_TMP)
			_emit("TXA")
			_emit("ADC %d" % ZP_TMP_HI)
			_emit("TAX")
			_emit("LDA %d" % ZP_TMP)
		"-":
			_emit("STA %d" % ZP_TMP2)
			_emit("TXA")
			_emit("STA %d" % ZP_TMP2_HI)
			_emit("SEC")
			_emit("LDA %d" % ZP_TMP)
			_emit("SBC %d" % ZP_TMP2)
			_emit("STA %d" % ZP_TMP)
			_emit("LDA %d" % ZP_TMP_HI)
			_emit("SBC %d" % ZP_TMP2_HI)
			_emit("TAX")
			_emit("LDA %d" % ZP_TMP)
		"*":
			_emit("STA %d" % ZP_TMP2)
			_emit("STX %d" % ZP_TMP2_HI)
			_emit("LDA %d" % ZP_TMP)
			_emit("LDX %d" % ZP_TMP_HI)
			_gen_mul16()
		"/":
			_emit("STA %d" % ZP_TMP2)
			_emit("STX %d" % ZP_TMP2_HI)
			_emit("LDA %d" % ZP_TMP)
			_emit("LDX %d" % ZP_TMP_HI)
			_gen_div16()
		"%":
			_emit("STA %d" % ZP_TMP2)
			_emit("STX %d" % ZP_TMP2_HI)
			_emit("LDA %d" % ZP_TMP)
			_emit("LDX %d" % ZP_TMP_HI)
			_gen_mod16()
		"&":
			_emit("AND %d" % ZP_TMP)
			_emit("STA %d" % ZP_TMP)
			_emit("TXA")
			_emit("AND %d" % ZP_TMP_HI)
			_emit("TAX")
			_emit("LDA %d" % ZP_TMP)
		"|":
			_emit("ORA %d" % ZP_TMP)
			_emit("STA %d" % ZP_TMP)
			_emit("TXA")
			_emit("ORA %d" % ZP_TMP_HI)
			_emit("TAX")
			_emit("LDA %d" % ZP_TMP)
		"^":
			_emit("EOR %d" % ZP_TMP)
			_emit("STA %d" % ZP_TMP)
			_emit("TXA")
			_emit("EOR %d" % ZP_TMP_HI)
			_emit("TAX")
			_emit("LDA %d" % ZP_TMP)
		"<<":
			_gen_lshift()
		">>":
			_gen_rshift()
		"==":
			_gen_eq()
		"!=":
			_gen_neq()
		"<":
			_gen_lt()
		"<=":
			_gen_lte()
		">":
			_gen_gt()
		">=":
			_gen_gte()
		"&&":
			_gen_and()
		"||":
			_gen_or()
		_:
			_emit("LDA #0")
			_emit("LDX #0")

func _gen_mul16() -> void:
	var l1 := _lbl()
	var l2 := _lbl()
	var l3 := _lbl()
	_emit("STA %d" % ZP_TMP)
	_emit("STX %d" % ZP_TMP_HI)
	_emit("LDA %d" % ZP_TMP2)
	_emit("STA %d" % ZP_TMP2)
	_emit("LDA %d" % ZP_TMP2_HI)
	_emit("STA %d" % ZP_TMP2_HI)
	_emit("LDA #0")
	_emit("STA %d" % ZP_TMP)
	_emit("STA %d" % ZP_TMP_HI)
	_emit("LDX #16")
	_emit("%s:" % l1)
	_emit("LSR %d" % ZP_TMP2_HI)
	_emit("ROR %d" % ZP_TMP2)
	_emit("BCC %s" % l2)
	_emit("CLC")
	_emit("LDA %d" % ZP_TMP)
	_emit("ADC %d" % ZP_TMP)
	_emit("STA %d" % ZP_TMP)
	_emit("LDA %d" % ZP_TMP_HI)
	_emit("ADC %d" % ZP_TMP_HI)
	_emit("STA %d" % ZP_TMP_HI)
	_emit("%s:" % l2)
	_emit("ASL %d" % ZP_TMP)
	_emit("ROL %d" % ZP_TMP_HI)
	_emit("DEX")
	_emit("BNE %s" % l1)
	_emit("%s:" % l3)
	_emit("LDA %d" % ZP_TMP)
	_emit("LDX %d" % ZP_TMP_HI)

func _gen_div16() -> void:
	var l1 := _lbl()
	var l2 := _lbl()
	_emit("STA %d" % ZP_TMP)
	_emit("STX %d" % ZP_TMP_HI)
	_emit("LDA %d" % ZP_TMP2)
	_emit("STA %d" % ZP_TMP2)
	_emit("LDA %d" % ZP_TMP2_HI)
	_emit("STA %d" % ZP_TMP2_HI)
	_emit("LDA #0")
	_emit("STA %d" % ZP_TMP)
	_emit("STA %d" % ZP_TMP_HI)
	_emit("LDX #16")
	_emit("%s:" % l1)
	_emit("ASL %d" % ZP_TMP2)
	_emit("ROL %d" % ZP_TMP2_HI)
	_emit("ROL %d" % ZP_TMP)
	_emit("ROL %d" % ZP_TMP_HI)
	_emit("SEC")
	_emit("LDA %d" % ZP_TMP)
	_emit("SBC %d" % ZP_TMP)
	_emit("BMI %s" % l2)
	_emit("STA %d" % ZP_TMP)
	_emit("INC %d" % ZP_TMP2)
	_emit("%s:" % l2)
	_emit("DEX")
	_emit("BNE %s" % l1)
	_emit("LDA %d" % ZP_TMP2)
	_emit("LDX %d" % ZP_TMP2_HI)

func _gen_mod16() -> void:
	var l1 := _lbl()
	var l2 := _lbl()
	_emit("STA %d" % ZP_TMP)
	_emit("STX %d" % ZP_TMP_HI)
	_emit("LDA %d" % ZP_TMP2)
	_emit("STA %d" % ZP_TMP2)
	_emit("LDA %d" % ZP_TMP2_HI)
	_emit("STA %d" % ZP_TMP2_HI)
	_emit("LDA #0")
	_emit("STA %d" % ZP_TMP)
	_emit("STA %d" % ZP_TMP_HI)
	_emit("LDX #16")
	_emit("%s:" % l1)
	_emit("ASL %d" % ZP_TMP2)
	_emit("ROL %d" % ZP_TMP2_HI)
	_emit("ROL %d" % ZP_TMP)
	_emit("ROL %d" % ZP_TMP_HI)
	_emit("SEC")
	_emit("LDA %d" % ZP_TMP)
	_emit("SBC %d" % ZP_TMP)
	_emit("BMI %s" % l2)
	_emit("STA %d" % ZP_TMP)
	_emit("%s:" % l2)
	_emit("DEX")
	_emit("BNE %s" % l1)
	_emit("LDA %d" % ZP_TMP)
	_emit("LDX %d" % ZP_TMP_HI)

func _gen_lshift() -> void:
	var l1 := _lbl()
	var l2 := _lbl()
	_emit("STA %d" % ZP_TMP)
	_emit("STX %d" % ZP_TMP_HI)
	_emit("LDA %d" % ZP_TMP2)
	_emit("LDX #0")
	_emit("STX %d" % ZP_TMP2_HI)
	_emit("%s:" % l1)
	_emit("LDA %d" % ZP_TMP2)
	_emit("BEQ %s" % l2)
	_emit("ASL %d" % ZP_TMP)
	_emit("ROL %d" % ZP_TMP_HI)
	_emit("DEC %d" % ZP_TMP2)
	_emit("JMP %s" % l1)
	_emit("%s:" % l2)
	_emit("LDA %d" % ZP_TMP)
	_emit("LDX %d" % ZP_TMP_HI)

func _gen_rshift() -> void:
	var l1 := _lbl()
	var l2 := _lbl()
	_emit("STA %d" % ZP_TMP)
	_emit("STX %d" % ZP_TMP_HI)
	_emit("LDA %d" % ZP_TMP2)
	_emit("LDX #0")
	_emit("STX %d" % ZP_TMP2_HI)
	_emit("%s:" % l1)
	_emit("LDA %d" % ZP_TMP2)
	_emit("BEQ %s" % l2)
	_emit("LSR %d" % ZP_TMP_HI)
	_emit("ROR %d" % ZP_TMP)
	_emit("DEC %d" % ZP_TMP2)
	_emit("JMP %s" % l1)
	_emit("%s:" % l2)
	_emit("LDA %d" % ZP_TMP)
	_emit("LDX %d" % ZP_TMP_HI)

func _gen_eq() -> void:
	var l1 := _lbl()
	var l2 := _lbl()
	_emit("CMP %d" % ZP_TMP)
	_emit("BNE %s" % l1)
	_emit("CPX %d" % ZP_TMP_HI)
	_emit("BNE %s" % l1)
	_emit("LDA #1")
	_emit("LDX #0")
	_emit("JMP %s" % l2)
	_emit("%s:" % l1)
	_emit("LDA #0")
	_emit("LDX #0")
	_emit("%s:" % l2)

func _gen_neq() -> void:
	var l1 := _lbl()
	var l2 := _lbl()
	_emit("CMP %d" % ZP_TMP)
	_emit("BNE %s" % l1)
	_emit("CPX %d" % ZP_TMP_HI)
	_emit("BEQ %s" % l2)
	_emit("%s:" % l1)
	_emit("LDA #1")
	_emit("LDX #0")
	_emit("JMP %s" % l2)
	_emit("%s:" % l2)
	_emit("LDA #0")
	_emit("LDX #0")

func _gen_lt() -> void:
	var l1 := _lbl()
	_emit("SEC")
	_emit("LDA %d" % ZP_TMP)
	_emit("SBC %d" % ZP_TMP2)
	_emit("STA %d" % ZP_TMP)
	_emit("LDA %d" % ZP_TMP_HI)
	_emit("SBC %d" % ZP_TMP2_HI)
	_emit("BMI %s" % l1)
	_emit("BPL %s" % _lbl())
	_emit("%s:" % l1)
	_emit("LDA #1")
	_emit("LDX #0")
	_emit("LDA #0")
	_emit("LDX #0")

func _gen_lte() -> void:
	var l1 := _lbl()
	_emit("SEC")
	_emit("LDA %d" % ZP_TMP)
	_emit("SBC %d" % ZP_TMP2)
	_emit("STA %d" % ZP_TMP)
	_emit("LDA %d" % ZP_TMP_HI)
	_emit("SBC %d" % ZP_TMP2_HI)
	_emit("BPL %s" % l1)
	_emit("BMI %s" % _lbl())
	_emit("%s:" % l1)
	_emit("LDA #0")
	_emit("LDX #0")
	_emit("LDA #1")
	_emit("LDX #0")

func _gen_gt() -> void:
	var l1 := _lbl()
	_emit("SEC")
	_emit("LDA %d" % ZP_TMP2)
	_emit("SBC %d" % ZP_TMP)
	_emit("STA %d" % ZP_TMP)
	_emit("LDA %d" % ZP_TMP2_HI)
	_emit("SBC %d" % ZP_TMP_HI)
	_emit("BMI %s" % l1)
	_emit("BPL %s" % _lbl())
	_emit("%s:" % l1)
	_emit("LDA #1")
	_emit("LDX #0")
	_emit("LDA #0")
	_emit("LDX #0")

func _gen_gte() -> void:
	var l1 := _lbl()
	_emit("SEC")
	_emit("LDA %d" % ZP_TMP2)
	_emit("SBC %d" % ZP_TMP)
	_emit("STA %d" % ZP_TMP)
	_emit("LDA %d" % ZP_TMP2_HI)
	_emit("SBC %d" % ZP_TMP_HI)
	_emit("BPL %s" % l1)
	_emit("BMI %s" % _lbl())
	_emit("%s:" % l1)
	_emit("LDA #0")
	_emit("LDX #0")
	_emit("LDA #1")
	_emit("LDX #0")
	_emit("JMP %s" % _lbl())
	_emit("%s:" % l1)
	_emit("LDA #1")
	_emit("LDX #0")

func _gen_and() -> void:
	var l1 := _lbl()
	var l2 := _lbl()
	_emit("CMP #0")
	_emit("BNE %s" % l1)
	_emit("CPX #0")
	_emit("BNE %s" % l1)
	_emit("LDA #0")
	_emit("LDX #0")
	_emit("JMP %s" % l2)
	_emit("%s:" % l1)
	_emit("LDA %d" % ZP_TMP2)
	_emit("CMP #0")
	_emit("BNE %s" % l1)
	_emit("CPX %d" % ZP_TMP2_HI)
	_emit("BNE %s" % l1)
	_emit("LDA #0")
	_emit("LDX #0")
	_emit("JMP %s" % l2)
	_emit("%s:" % l1)
	_emit("LDA #1")
	_emit("LDX #0")
	_emit("%s:" % l2)

func _gen_or() -> void:
	var l1 := _lbl()
	var l2 := _lbl()
	_emit("CMP #0")
	_emit("BNE %s" % l1)
	_emit("CPX #0")
	_emit("BNE %s" % l1)
	_emit("LDA %d" % ZP_TMP2)
	_emit("CMP #0")
	_emit("BNE %s" % l1)
	_emit("LDX %d" % ZP_TMP2_HI)
	_emit("CPX #0")
	_emit("BNE %s" % l1)
	_emit("LDA #0")
	_emit("LDX #0")
	_emit("JMP %s" % l2)
	_emit("%s:" % l1)
	_emit("LDA #1")
	_emit("LDX #0")
	_emit("%s:" % l2)

func _gen_unary(expr: Dictionary) -> void:
	match expr["op"]:
		"!":
			_gen_expr(expr["operand"])
			_emit("CMP #0")
			_emit("BNE %s" % _lbl())
			_emit("CPX #0")
			_emit("BNE %s" % _lbl())
			_emit("LDA #1")
			_emit("LDX #0")
			_emit("JMP %s" % _lbl())
			_emit("LDA #0")
			_emit("LDX #0")
		"~":
			_gen_expr(expr["operand"])
			_emit("EOR #$FF")
			_emit("STA %d" % ZP_TMP)
			_emit("TXA")
			_emit("EOR #$FF")
			_emit("TAX")
			_emit("LDA %d" % ZP_TMP)
		"neg":
			_gen_expr(expr["operand"])
			_emit("EOR #$FF")
			_emit("CLC")
			_emit("ADC #1")
			_emit("STA %d" % ZP_TMP)
			_emit("TXA")
			_emit("EOR #$FF")
			_emit("ADC #0")
			_emit("TAX")
			_emit("LDA %d" % ZP_TMP)

func _gen_call(expr: Dictionary) -> void:
	var func_ref: Dictionary = expr["func"]
	var args: Array = expr["args"]
	var name: String = ""
	if func_ref["type"] == "IdentRef":
		name = func_ref["name"]
	match name:
		"putc":
			_gen_expr(args[0])
			_emit("STA $C002")
			_emit("LDA #$0D")
			_emit("STA $C003")
			_emit("LDA #0")
			_emit("LDX #0")
		"getc":
			var l1 := _lbl()
			_emit("%s:" % l1)
			_emit("LDA $C001")
			_emit("BEQ %s" % l1)
			_emit("LDX #0")
		"peek":
			_gen_expr(args[0])
			_emit("STA $F8")
			_emit("STX $F9")
			_emit("LDY #0")
			_emit("LDA ($F8),Y")
			_emit("LDX #0")
		"poke":
			_gen_expr(args[0])
			_emit("STA $F8")
			_emit("STX $F9")
			_gen_expr(args[1])
			_emit("LDY #0")
			_emit("STA ($F8),Y")
			_emit("LDA #0")
			_emit("LDX #0")
		_:
			for i in range(args.size() - 1, -1, -1):
				_gen_expr(args[i])
				_emit("TAX")
				_emit("PHA")
				_emit("PLA")
			_emit("JSR %s" % name)
			_emit("TAX")
			_emit("PLA")

func _gen_array_ref(ref: Dictionary) -> void:
	_gen_expr(ref["index"])
	_emit("ASL A")
	_emit("TAY")
	var arr_name: String = ""
	if ref["array"]["type"] == "IdentRef":
		arr_name = ref["array"]["name"]
	if _var_map.has(arr_name):
		var info: Dictionary = _var_map[arr_name]
		_emit("LDA #<(GDATA + %d)" % info["off"])
		_emit("CLC")
		_emit("ADC %d" % ZP_TMP)
		_emit("STA %d" % ZP_TMP)
		_emit("LDA #>(GDATA + %d)" % info["off"])
		_emit("ADC %d" % ZP_TMP_HI)
		_emit("STA %d" % ZP_TMP_HI)
	_emit("LDY #0")
	_emit("LDA (%d),Y" % ZP_TMP)
	_emit("STA %d" % ZP_TMP)
	_emit("INY")
	_emit("LDA (%d),Y" % ZP_TMP)
	_emit("STA %d" % ZP_TMP_HI)
	_emit("LDA %d" % ZP_TMP)
	_emit("LDX %d" % ZP_TMP_HI)

func _gen_deref(expr: Dictionary) -> void:
	_gen_expr(expr)
	_emit("STA %d" % ZP_TMP)
	_emit("STX %d" % ZP_TMP_HI)
	_emit("LDY #0")
	_emit("LDA (%d),Y" % ZP_TMP)
	_emit("STA %d" % ZP_TMP)
	_emit("LDY #1")
	_emit("LDA (%d),Y" % ZP_TMP_HI)
	_emit("STA %d" % ZP_TMP_HI)
	_emit("LDA %d" % ZP_TMP)
	_emit("LDX %d" % ZP_TMP_HI)

func _gen_addr_of(expr: Dictionary) -> void:
	if expr["type"] == "IdentRef":
		if _var_map.has(expr["name"]):
			var info: Dictionary = _var_map[expr["name"]]
			_emit("LDA #<(GDATA + %d)" % info["off"])
			_emit("LDX #>(GDATA + %d)" % info["off"])
		elif _local_offsets.has(expr["name"]):
			var info: Dictionary = _local_offsets[expr["name"]]
			var off: int = info["off"] & 0xFF
			_emit("LDY #%d" % off)
			_emit("LDA (%d),Y" % ZP_FP)
			_emit("STA %d" % ZP_TMP)
			_emit("INY")
			_emit("LDA (%d),Y" % ZP_FP)
			_emit("STA %d" % ZP_TMP_HI)
			_emit("LDA %d" % ZP_TMP)
			_emit("LDX %d" % ZP_TMP_HI)
	else:
		_emit("LDA #0")
		_emit("LDX #0")

func _emit_data() -> void:
	_emit("")
	_emit("GDATA:")
	if _global_offset > 0:
		var bytes := PackedByteArray()
		bytes.resize(_global_offset)
		var bl := ".BYTE "
		for i in range(_global_offset):
			if i > 0:
				bl += ","
			bl += "$00"
		_emit(bl)
	_emit("DATA_END:")
	for s in _string_labels:
		var lbl: String = _string_labels[s]
		_emit("%s:" % lbl)
		var chars: PackedByteArray = s.to_utf8_buffer()
		var line := ".BYTE "
		for i in range(chars.size()):
			if i > 0:
				line += ","
			line += "$%02X" % chars[i]
		line += ",$00"
		_emit(line)

class_name BasicInterpreter
extends RefCounted

var _memory: MemoryBus
var _variables: Dictionary = {}
var _arrays: Dictionary = {}
var _program: Array = []
var _for_stack: Array = []
var _gosub_stack: Array = []
var _data_values: Array = []
var _data_pointer: int = 0
var _running: bool = false
var _current_line: int = 0
var _jumped: bool = false
var _awaiting_input: bool = false
var _input_vars: Array = []
var _output_callback: Callable
var _input_callback: Callable

var _demos_with_param: Array = ["primenums", "pi"]

enum TT {
	NUMBER, STRING, IDENT, OP, LPAREN, RPAREN,
	COMMA, SEMI, KW, EOL, NEQ, LTE, GTE, COLON
}

var _keywords: Dictionary = {}

func _init(sram: MemoryBus, output_cb: Callable, input_cb: Callable) -> void:
	_memory = sram
	_output_callback = output_cb
	_input_callback = input_cb
	_setup_keywords()

func _setup_keywords() -> void:
	_keywords = {
		"PRINT": true, "INPUT": true, "GOTO": true, "GOSUB": true,
		"RETURN": true, "FOR": true, "TO": true, "STEP": true,
		"NEXT": true, "IF": true, "THEN": true, "ELSE": true,
		"LET": true, "REM": true, "END": true, "DIM": true,
		"READ": true, "DATA": true, "RESTORE": true,
		"ON": true, "AND": true, "OR": true, "NOT": true,
		"INT": true, "RND": true, "ABS": true, "SQR": true,
		"SIN": true, "COS": true, "TAN": true, "ATN": true,
		"LOG": true, "EXP": true, "SGN": true, "LEN": true,
		"CHR$": true, "ASC": true, "LEFT$": true, "RIGHT$": true,
		"MID$": true, "STR$": true, "VAL": true, "TAB": true,
		"PEEK": true, "POKE": true, "SYS": true, "WAIT": true,
		"CLR": true, "NEW": true, "LIST": true, "RUN": true,
		"CONT": true, "LOAD": true, "SAVE": true, "MEM": true,
		"DEF": true, "FN": true, "STOP": true, "BREAK": true,
	}

func load_program(text: String) -> void:
	_program.clear()
	_variables.clear()
	_arrays.clear()
	_for_stack.clear()
	_gosub_stack.clear()
	_data_values.clear()
	_data_pointer = 0
	for line in text.split("\n"):
		line = line.strip_edges()
		if line == "":
			continue
		var parsed = _parse_line(line)
		if parsed != null:
			_program.append(parsed)
	_program.sort_custom(func(a, b): return a[0] < b[0])
	_collect_data()

func _parse_line(line: String) -> Variant:
	var pos = 0
	while pos < line.length() and line[pos] == ' ':
		pos += 1
	var num_str = ""
	while pos < line.length() and line[pos].is_valid_int():
		num_str += line[pos]
		pos += 1
	if num_str == "":
		return null
	var line_num = int(num_str)
	while pos < line.length() and line[pos] == ' ':
		pos += 1
	var stmt = line.substr(pos)
	return [line_num, stmt]

func run() -> void:
	_running = true
	_current_line = 0
	_data_pointer = 0
	while _running and _current_line < _program.size():
		_execute_line(_program[_current_line])
		if not _running:
			break

func continue_run() -> void:
	_running = true
	while _running and _current_line < _program.size():
		_execute_line(_program[_current_line])

func _execute_line(line_data: Array) -> void:
	var _line_num: int = line_data[0]
	var stmt: String = line_data[1]
	_jumped = false
	_execute_statement(stmt)
	if _running and not _jumped:
		_current_line += 1

func _execute_statement(stmt: String) -> void:
	stmt = stmt.strip_edges()
	if stmt == "":
		return
	var parts = _split_on_colon(stmt)
	for i in range(parts.size()):
		_execute_single(parts[i])
		if not _running or _jumped:
			break

func _split_on_colon(stmt: String) -> Array:
	var parts: Array = []
	var current = ""
	var in_quote = false
	var qchar = ""
	for i in range(stmt.length()):
		var ch = stmt[i]
		if in_quote:
			current += ch
			if ch == qchar:
				in_quote = false
			continue
		if ch == '"' or ch == "'":
			in_quote = true
			qchar = ch
			current += ch
		elif ch == ':':
			parts.append(current)
			current = ""
		else:
			current += ch
	parts.append(current)
	return parts

func _execute_single(stmt: String) -> void:
	stmt = stmt.strip_edges()
	if stmt == "":
		return
	var toks = _tokenize(stmt)
	if toks.size() == 0:
		return
	var t = toks[0]
	if t[0] == TT.KW:
		match t[1]:
			"PRINT": _exec_print(toks)
			"INPUT": _exec_input(toks)
			"GOTO": _exec_goto(toks)
			"GOSUB": _exec_gosub(toks)
			"RETURN": _exec_return()
			"FOR": _exec_for(toks)
			"NEXT": _exec_next(toks)
			"IF": _exec_if(toks)
			"LET": _exec_let(toks)
			"REM": return
			"END", "STOP", "BREAK": _running = false
			"DIM": _exec_dim(toks)
			"READ": _exec_read(toks)
			"DATA": return
			"RESTORE": _data_pointer = 0
			"ON": _exec_on(toks)
			"POKE": _exec_poke(toks)
			"SYS": _exec_sys(toks)
			"CLR": _variables.clear(); _arrays.clear()
			"NEW": _program.clear(); _variables.clear(); _arrays.clear(); _running = false
			"LIST": _exec_list()
			"RUN": _current_line = 0; _data_pointer = 0
	elif t[0] == TT.IDENT:
		var pos = 0
		var name = t[1].to_upper()
		pos += 1
		if pos < toks.size() and toks[pos][0] == TT.LPAREN:
			_exec_let_array(toks, name, pos)
		elif pos < toks.size() and toks[pos][0] == TT.OP and toks[pos][1] == "=":
			pos += 1
			var val = _eval(toks, pos)
			_variables[name] = val

func _tokenize(text: String) -> Array:
	var tokens: Array = []
	var pos = 0
	while pos < text.length():
		while pos < text.length() and text[pos] == ' ':
			pos += 1
		if pos >= text.length():
			break
		var ch = text[pos]
		if ch == '"' or ch == "'":
			var q = ch
			pos += 1
			var s = ""
			while pos < text.length() and text[pos] != q:
				s += text[pos]
				pos += 1
			if pos < text.length():
				pos += 1
			tokens.append([TT.STRING, s])
		elif ch.is_valid_int() or (ch == '.' and pos + 1 < text.length() and text[pos + 1].is_valid_int()):
			var num = ""
			var has_dot = false
			while pos < text.length() and (text[pos].is_valid_int() or (text[pos] == '.' and not has_dot)):
				if text[pos] == '.':
					has_dot = true
				num += text[pos]
				pos += 1
			tokens.append([TT.NUMBER, float(num) if has_dot else int(num)])
		elif ch == '<':
			pos += 1
			if pos < text.length() and text[pos] == '=':
				tokens.append([TT.LTE, "<="])
				pos += 1
			elif pos < text.length() and text[pos] == '>':
				tokens.append([TT.NEQ, "<>"])
				pos += 1
			else:
				tokens.append([TT.OP, "<"])
		elif ch == '>':
			pos += 1
			if pos < text.length() and text[pos] == '=':
				tokens.append([TT.GTE, ">="])
				pos += 1
			else:
				tokens.append([TT.OP, ">"])
		elif ch == '=':
			tokens.append([TT.OP, "="])
			pos += 1
		elif ch in "+-*/^":
			tokens.append([TT.OP, ch])
			pos += 1
		elif ch == '(':
			tokens.append([TT.LPAREN, "("])
			pos += 1
		elif ch == ')':
			tokens.append([TT.RPAREN, ")"])
			pos += 1
		elif ch == ',':
			tokens.append([TT.COMMA, ","])
			pos += 1
		elif ch == ';':
			tokens.append([TT.SEMI, ";"])
			pos += 1
		elif ch == ':':
			tokens.append([TT.COLON, ":"])
			pos += 1
		elif ch.is_valid_identifier() or ch == '$' or ch == '_':
			var ident = ""
			while pos < text.length() and (text[pos].is_valid_identifier() or text[pos] == '$' or text[pos] == '%'):
				ident += text[pos]
				pos += 1
			if _keywords.has(ident.to_upper()):
				tokens.append([TT.KW, ident.to_upper()])
			else:
				tokens.append([TT.IDENT, ident])
		else:
			pos += 1
	tokens.append([TT.EOL, ""])
	return tokens

# ---- Position-tracking variable for _eval ----
var _ep: int = 0

func _eval(toks: Array, start_pos: int) -> Variant:
	_ep = start_pos
	return _eval_or(toks)

func _eval_or(toks: Array) -> Variant:
	var val = _eval_and(toks)
	while _ep < toks.size() and toks[_ep][0] == TT.KW and toks[_ep][1] == "OR":
		_ep += 1
		var right = _eval_and(toks)
		val = 1 if (val or right) else 0
	return val

func _eval_and(toks: Array) -> Variant:
	var val = _eval_not(toks)
	while _ep < toks.size() and toks[_ep][0] == TT.KW and toks[_ep][1] == "AND":
		_ep += 1
		var right = _eval_not(toks)
		val = 1 if (val and right) else 0
	return val

func _eval_not(toks: Array) -> Variant:
	if _ep < toks.size() and toks[_ep][0] == TT.KW and toks[_ep][1] == "NOT":
		_ep += 1
		var val = _eval_cmp(toks)
		return 0 if val else 1
	return _eval_cmp(toks)

func _eval_cmp(toks: Array) -> Variant:
	var val = _eval_add(toks)
	while _ep < toks.size():
		var op: String = ""
		if toks[_ep][0] == TT.OP and toks[_ep][1] in ["<", ">", "="]:
			op = toks[_ep][1]
		elif toks[_ep][0] == TT.LTE:
			op = "<="
		elif toks[_ep][0] == TT.GTE:
			op = ">="
		elif toks[_ep][0] == TT.NEQ:
			op = "<>"
		else:
			break
		_ep += 1
		var right = _eval_add(toks)
		match op:
			"<": val = 1 if val < right else 0
			">": val = 1 if val > right else 0
			"=": val = 1 if val == right else 0
			"<=": val = 1 if val <= right else 0
			">=": val = 1 if val >= right else 0
			"<>": val = 1 if val != right else 0
	return val

func _eval_add(toks: Array) -> Variant:
	var val = _eval_mul(toks)
	while _ep < toks.size() and toks[_ep][0] == TT.OP and toks[_ep][1] in ["+", "-"]:
		var op = toks[_ep][1]
		_ep += 1
		var right = _eval_mul(toks)
		if op == "+":
			if val is String and right is String:
				val = val + right
			elif val is String:
				val = val + str(right)
			elif right is String:
				val = str(val) + right
			else:
				val = float(val) + float(right)
				if val == int(val) and abs(val) < 2147483647:
					val = int(val)
		else:
			val = float(val) - float(right)
			if val == int(val) and abs(val) < 2147483647:
				val = int(val)
	return val

func _eval_mul(toks: Array) -> Variant:
	var val = _eval_power(toks)
	while _ep < toks.size() and toks[_ep][0] == TT.OP and toks[_ep][1] in ["*", "/"]:
		var op = toks[_ep][1]
		_ep += 1
		var right = _eval_power(toks)
		if op == "*":
			val = float(val) * float(right)
		else:
			val = float(val) / float(right) if float(right) != 0 else 0.0
		if val == int(val) and abs(val) < 2147483647:
			val = int(val)
	return val

func _eval_power(toks: Array) -> Variant:
	var val = _eval_unary(toks)
	if _ep < toks.size() and toks[_ep][0] == TT.OP and toks[_ep][1] == "^":
		_ep += 1
		var right = _eval_power(toks)
		val = pow(float(val), float(right))
		if val == int(val) and abs(val) < 2147483647:
			val = int(val)
	return val

func _eval_unary(toks: Array) -> Variant:
	if _ep < toks.size() and toks[_ep][0] == TT.OP and toks[_ep][1] == "-":
		_ep += 1
		var val = float(_eval_atom(toks))
		return -val
	if _ep < toks.size() and toks[_ep][0] == TT.OP and toks[_ep][1] == "+":
		_ep += 1
		return _eval_atom(toks)
	return _eval_atom(toks)

func _eval_atom(toks: Array) -> Variant:
	if _ep >= toks.size():
		return 0
	var tok = toks[_ep]
	match tok[0]:
		TT.NUMBER:
			_ep += 1
			return tok[1]
		TT.STRING:
			_ep += 1
			return tok[1]
		TT.IDENT:
			var name = tok[1].to_upper()
			_ep += 1
			if _ep < toks.size() and toks[_ep][0] == TT.LPAREN:
				_ep += 1
				var idx = int(_eval_or(toks))
				if _ep < toks.size() and toks[_ep][0] == TT.RPAREN:
					_ep += 1
				if _arrays.has(name) and _arrays[name].has(idx):
					return _arrays[name][idx]
				return 0
			if _variables.has(name):
				return _variables[name]
			return 0
		TT.KW:
			var fn_name = tok[1].to_upper()
			match fn_name:
				"INT":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return int(floor(float(v)))
				"RND":
					_ep += 1; _ep += 1
					var _v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return randf()
				"ABS":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return abs(v)
				"SQR":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return sqrt(float(v))
				"SIN":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return sin(float(v))
				"COS":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return cos(float(v))
				"TAN":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return tan(float(v))
				"ATN":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return atan(float(v))
				"LOG":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return log(float(v))
				"EXP":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return exp(float(v))
				"SGN":
					_ep += 1; _ep += 1
					var v = float(_eval_or(toks))
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return 1.0 if v > 0 else (-1.0 if v < 0 else 0.0)
				"LEN":
					_ep += 1; _ep += 1
					var v = str(_eval_or(toks))
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return v.length()
				"CHR$":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return char(int(v))
				"ASC":
					_ep += 1; _ep += 1
					var v = str(_eval_or(toks))
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return v.unicode_at(0) if v.length() > 0 else 0
				"LEFT$":
					_ep += 1; _ep += 1
					var s = str(_eval_or(toks))
					_ep += 1
					var n = int(_eval_or(toks))
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return s.substr(0, n)
				"RIGHT$":
					_ep += 1; _ep += 1
					var s = str(_eval_or(toks))
					_ep += 1
					var n = int(_eval_or(toks))
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return s.substr(max(0, s.length() - n))
				"MID$":
					_ep += 1; _ep += 1
					var s = str(_eval_or(toks))
					_ep += 1
					var start = int(_eval_or(toks))
					var length = -1
					if _ep < toks.size() and toks[_ep][0] == TT.COMMA:
						_ep += 1
						length = int(_eval_or(toks))
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					var st = start - 1
					if length >= 0:
						return s.substr(st, length)
					return s.substr(st)
				"STR$":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return str(v)
				"VAL":
					_ep += 1; _ep += 1
					var v = str(_eval_or(toks))
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return float(v) if v.is_valid_float() else 0.0
				"PEEK":
					_ep += 1; _ep += 1
					var v = _eval_or(toks)
					if _ep < toks.size() and toks[_ep][0] == TT.RPAREN: _ep += 1
					return _memory.peek(int(v))
				_:
					_ep += 1
					return 0
		TT.LPAREN:
			_ep += 1
			var val = _eval_or(toks)
			if _ep < toks.size() and toks[_ep][0] == TT.RPAREN:
				_ep += 1
			return val
		_:
			_ep += 1
			return 0

# ---- Statement executors ----

func _exec_print(toks: Array) -> void:
	var output = ""
	var pos = 1
	var newline = true
	while pos < toks.size() and toks[pos][0] != TT.EOL:
		if toks[pos][0] == TT.SEMI:
			newline = false
			pos += 1
			continue
		if toks[pos][0] == TT.COMMA:
			output += "\t"
			newline = true
			pos += 1
			continue
		if toks[pos][0] == TT.KW and toks[pos][1] == "TAB":
			pos += 1
			if pos < toks.size() and toks[pos][0] == TT.LPAREN:
				pos += 1
				var tab_val = _eval(toks, pos)
				pos = _ep
				if pos < toks.size() and toks[pos][0] == TT.RPAREN:
					pos += 1
				var spaces = int(tab_val) - output.length()
				if spaces > 0:
					output += " ".repeat(spaces)
			newline = false
			continue
		var val = _eval(toks, pos)
		pos = _ep
		if val is float:
			if val == int(val):
				output += " " + str(int(val)) + " "
			else:
				output += " " + str(val) + " "
		elif val is int:
			output += " " + str(val) + " "
		else:
			output += str(val)
		newline = true
	if newline:
		output += "\n"
	_output_callback.call(output)

func _exec_input(toks: Array) -> Variant:
	var pos = 1
	var prompt = "? "
	if pos < toks.size() and toks[pos][0] == TT.STRING:
		prompt = toks[pos][1]
		pos += 1
		if pos < toks.size() and toks[pos][0] == TT.SEMI:
			pos += 1
		elif pos < toks.size() and toks[pos][0] == TT.COMMA:
			pos += 1
	var vars: Array = []
	while pos < toks.size() and toks[pos][0] != TT.EOL:
		if toks[pos][0] == TT.IDENT:
			vars.append(toks[pos][1])
		pos += 1
	if _running:
		_awaiting_input = true
		_input_vars = vars
		_output_callback.call(prompt)
		return null
	var values = _input_callback.call(prompt)
	if values == null:
		for vname in vars:
			_variables[vname.to_upper()] = 0
	else:
		for i in range(min(vars.size(), values.size())):
			var vname = str(vars[i]).to_upper()
			var val = values[i]
			if val.is_valid_int():
				_variables[vname] = int(val)
			elif val.is_valid_float():
				_variables[vname] = float(val)
			else:
				_variables[vname] = val
	return null

func provide_input(values: Array) -> void:
	for i in range(min(_input_vars.size(), values.size())):
		var vname = str(_input_vars[i]).to_upper()
		var val = values[i]
		if val.is_valid_int():
			_variables[vname] = int(val)
		elif val.is_valid_float():
			_variables[vname] = float(val)
		else:
			_variables[vname] = val
	for vname in _input_vars:
		if not _variables.has(vname.to_upper()):
			_variables[vname.to_upper()] = 0
	_awaiting_input = false

func _exec_goto(toks: Array) -> void:
	var target = _eval(toks, 1)
	var idx = _find_line(int(target))
	if idx >= 0:
		_current_line = idx
		_jumped = true
		_running = true
	else:
		_output_callback.call("ERROR: LINE NOT FOUND\n")
		_running = false

func _exec_gosub(toks: Array) -> void:
	var target = _eval(toks, 1)
	var idx = _find_line(int(target))
	if idx >= 0:
		_gosub_stack.append(_current_line + 1)
		_current_line = idx
		_jumped = true
	else:
		_output_callback.call("ERROR: LINE NOT FOUND\n")
		_running = false

func _exec_return() -> void:
	if _gosub_stack.size() > 0:
		_current_line = _gosub_stack.pop_back()
		_jumped = true
	else:
		_output_callback.call("ERROR: RETURN WITHOUT GOSUB\n")
		_running = false

func _exec_for(toks: Array) -> void:
	var pos = 1
	var var_name = toks[pos][1].to_upper()
	pos += 1
	pos += 1  # skip =
	var start_val = _eval(toks, pos)
	pos = _ep
	pos += 1  # skip TO
	var end_val = _eval(toks, pos)
	pos = _ep
	var step_val = 1
	if pos < toks.size() and toks[pos][0] == TT.KW and toks[pos][1] == "STEP":
		pos += 1
		step_val = _eval(toks, pos)
		pos = _ep
	_variables[var_name] = start_val
	_for_stack.append({"var": var_name, "end": end_val, "step": step_val, "line": _current_line})

func _exec_next(toks: Array) -> void:
	var var_name = ""
	if toks.size() > 1 and toks[1][0] == TT.IDENT:
		var_name = toks[1][1].to_upper()
	if _for_stack.size() == 0:
		_output_callback.call("ERROR: NEXT WITHOUT FOR\n")
		_running = false
		return
	var target_idx: int
	if var_name == "":
		target_idx = _for_stack.size() - 1
	else:
		target_idx = -1
		for i in range(_for_stack.size() - 1, -1, -1):
			if _for_stack[i]["var"] == var_name:
				target_idx = i
				break
		if target_idx < 0:
			_output_callback.call("ERROR: NEXT WITHOUT FOR\n")
			_running = false
			return
		while _for_stack.size() > target_idx + 1:
			_for_stack.pop_back()
	var for_info = _for_stack[target_idx]
	var cur = float(_variables[for_info["var"]])
	var step = float(for_info["step"])
	cur += step
	_variables[for_info["var"]] = cur
	var done = step > 0 and cur > float(for_info["end"]) or step < 0 and cur < float(for_info["end"])
	if done:
		_for_stack.pop_back()
	else:
		_current_line = for_info["line"]
		_jumped = true

func _exec_if(toks: Array) -> void:
	var pos = 1
	var cond = _eval(toks, pos)
	pos = _ep
	if pos < toks.size() and toks[pos][0] == TT.KW and toks[pos][1] == "THEN":
		pos += 1
	if not cond:
		return
	if pos < toks.size() and toks[pos][0] == TT.NUMBER:
		var target = int(toks[pos][1])
		var idx = _find_line(target)
		if idx >= 0:
			_current_line = idx
			_jumped = true
		else:
			_output_callback.call("ERROR: LINE NOT FOUND\n")
			_running = false
	elif pos < toks.size():
		var stmt = _reconstruct(toks, pos)
		_execute_statement(stmt)

func _exec_let(toks: Array) -> void:
	var pos = 1 if toks[0][1] == "LET" else 0
	var name = toks[pos][1].to_upper()
	pos += 1
	if pos < toks.size() and toks[pos][0] == TT.LPAREN:
		pos += 1
		var idx = int(_eval(toks, pos))
		pos = _ep
		if pos < toks.size() and toks[pos][0] == TT.RPAREN:
			pos += 1
		pos += 1  # skip =
		var val = _eval(toks, pos)
		if not _arrays.has(name):
			_arrays[name] = {}
		_arrays[name][idx] = val
		return
	pos += 1  # skip =
	var val = _eval(toks, pos)
	_variables[name] = val

func _exec_let_array(toks: Array, name: String, start_pos: int) -> void:
	var pos = start_pos + 1  # skip (
	var idx = int(_eval(toks, pos))
	pos = _ep
	if pos < toks.size() and toks[pos][0] == TT.RPAREN:
		pos += 1
	pos += 1  # skip =
	var val = _eval(toks, pos)
	if not _arrays.has(name):
		_arrays[name] = {}
	_arrays[name][idx] = val

func _exec_dim(toks: Array) -> void:
	var pos = 1
	while pos < toks.size() and toks[pos][0] != TT.EOL:
		if toks[pos][0] == TT.IDENT:
			var name = toks[pos][1].to_upper()
			pos += 1
			if pos < toks.size() and toks[pos][0] == TT.LPAREN:
				pos += 1
				var size = int(_eval(toks, pos))
				pos = _ep
				if not _arrays.has(name):
					_arrays[name] = {}
				if pos < toks.size() and toks[pos][0] == TT.RPAREN:
					pos += 1
		pos += 1

func _exec_read(toks: Array) -> void:
	var pos = 1
	while pos < toks.size() and toks[pos][0] != TT.EOL:
		if toks[pos][0] == TT.IDENT:
			var name = toks[pos][1].to_upper()
			pos += 1
			if _data_pointer < _data_values.size():
				_variables[name] = _data_values[_data_pointer]
				_data_pointer += 1
			else:
				_output_callback.call("ERROR: OUT OF DATA\n")
				_running = false
				return
		if pos < toks.size() and toks[pos][0] == TT.COMMA:
			pos += 1

func _exec_on(toks: Array) -> void:
	var pos = 1
	var val = int(_eval(toks, pos))
	pos = _ep
	if pos < toks.size() and toks[pos][0] == TT.KW and toks[pos][1] == "GOTO":
		pos += 1
		var targets: Array = []
		while pos < toks.size() and toks[pos][0] != TT.EOL:
			if toks[pos][0] == TT.NUMBER:
				targets.append(int(toks[pos][1]))
			pos += 1
		if val >= 1 and val <= targets.size():
			var idx = _find_line(targets[val - 1])
			if idx >= 0:
				_current_line = idx
				_running = true
	elif pos < toks.size() and toks[pos][0] == TT.KW and toks[pos][1] == "GOSUB":
		pos += 1
		var targets: Array = []
		while pos < toks.size() and toks[pos][0] != TT.EOL:
			if toks[pos][0] == TT.NUMBER:
				targets.append(int(toks[pos][1]))
			pos += 1
		if val >= 1 and val <= targets.size():
			var idx = _find_line(targets[val - 1])
			if idx >= 0:
				_gosub_stack.append(_current_line + 1)
				_current_line = idx
				_running = true

func _exec_poke(toks: Array) -> void:
	var pos = 1
	var addr = int(_eval(toks, pos))
	pos = _ep
	pos += 1  # skip comma
	var val = int(_eval(toks, pos))
	_memory.poke(addr, val)

func _exec_sys(toks: Array) -> void:
	var addr = int(_eval(toks, 1))
	var cpu = CPU6502.new(_memory)
	cpu.PC = addr
	cpu.run(10000)

func _exec_list() -> void:
	var output = ""
	for entry in _program:
		output += str(entry[0]) + " " + str(entry[1]) + "\n"
	_output_callback.call(output)

func _find_line(line_num: int) -> int:
	for i in range(_program.size()):
		if _program[i][0] == line_num:
			return i
		if _program[i][0] > line_num:
			return -1
	return -1

func _collect_data() -> void:
	_data_values.clear()
	_data_pointer = 0
	for entry in _program:
		var stmt = str(entry[1]).strip_edges()
		if stmt.to_upper().begins_with("DATA "):
			var data_str = stmt.substr(5)
			for item in data_str.split(","):
				item = item.strip_edges()
				if item.begins_with('"') and item.ends_with('"'):
					_data_values.append(item.substr(1, item.length() - 2))
				elif item.is_valid_int():
					_data_values.append(int(item))
				elif item.is_valid_float():
					_data_values.append(float(item))
				else:
					_data_values.append(item)

func _reconstruct(toks: Array, start: int) -> String:
	var result = ""
	for i in range(start, toks.size()):
		if toks[i][0] == TT.EOL:
			break
		var val = str(toks[i][1])
		if result.length() > 0 and toks[i][0] != TT.LPAREN and toks[i][0] != TT.RPAREN and val != "," and val != ";":
			if result.length() > 0 and result[-1] != " " and result[-1] != "(":
				result += " "
		result += val
	return result

func set_variable(name: String, value: Variant) -> void:
	_variables[name.to_upper()] = value

func get_variable(name: String) -> Variant:
	return _variables.get(name.to_upper(), 0)

func execute_line(stmt: String) -> void:
	_execute_statement(stmt)

func serialize() -> Dictionary:
	var prog_lines = []
	for entry in _program:
		prog_lines.append([entry[0], entry[1]])
	return {
		"program": prog_lines,
		"variables": _variables,
		"arrays": _arrays,
		"data_values": _data_values,
		"data_pointer": _data_pointer,
	}

func deserialize(data: Dictionary) -> void:
	_program.clear()
	for entry in data.get("program", []):
		_program.append([int(entry[0]), str(entry[1])])
	_variables = data.get("variables", {})
	_arrays = data.get("arrays", {})
	_data_values = data.get("data_values", [])
	_data_pointer = int(data.get("data_pointer", 0))
	_for_stack.clear()
	_gosub_stack.clear()
	_running = false

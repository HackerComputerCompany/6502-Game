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
var _output_callback: Callable
var _input_callback: Callable
var _sleeping: bool = false
var _sleep_frames: int = 0

enum TokenType {
	NUMBER, STRING, IDENTIFIER, OPERATOR, LPAREN, RPAREN,
	COMMA, SEMICOLON, KEYWORD, EOF_LITERAL, NOT_EQUAL,
	LTE, GTE, EOL
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
		"DEF": true, "FN": true, "STOP": true,
	}

func load_program(text: String) -> void:
	_program.clear()
	_variables.clear()
	_arrays.clear()
	_for_stack.clear()
	_gosub_stack.clear()
	_data_values.clear()
	_data_pointer = 0
	var lines = text.split("\n")
	for line in lines:
		line = line.strip_edges()
		if line.length() == 0:
			continue
		var parsed = _parse_line(line)
		if parsed != null:
			_program.append(parsed)
	_program.sort_custom(func(a, b): return a[0] < b[0])
	_collect_data()

func _parse_line(line: String) -> Variant:
	if line == "":
		return null
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
		if _sleeping:
			break

func continue_run() -> void:
	_running = true
	_sleeping = false
	while _running and _current_line < _program.size():
		_execute_line(_program[_current_line])
		if _sleeping:
			break

func _execute_line(line_data: Array) -> void:
	var line_num: int = line_data[0]
	var _stmt: String = line_data[1]
	_execute_statement(_stmt)
	if _running and not _sleeping:
		_current_line += 1

func _execute_statement(stmt: String) -> void:
	stmt = stmt.strip_edges()
	if stmt == "":
		return
	var tokens = _tokenize(stmt)
	if tokens.size() == 0:
		return
	var first = tokens[0]
	match first[0]:
		TokenType.KEYWORD:
			var kw = first[1].to_upper()
			match kw:
				"PRINT": _exec_print(tokens, 1)
				"INPUT": _exec_input(tokens, 1)
				"GOTO": _exec_goto(tokens)
				"GOSUB": _exec_gosub(tokens)
				"RETURN": _exec_return()
				"FOR": _exec_for(tokens)
				"NEXT": _exec_next(tokens)
				"IF": _exec_if(tokens)
				"LET": _exec_let(tokens, 2)
				"REM": return
				"END", "STOP": _running = false
				"DIM": _exec_dim(tokens)
				"READ": _exec_read(tokens)
				"DATA": return
				"RESTORE": _data_pointer = 0; _current_line += 1; return
				"ON": _exec_on(tokens)
				"POKE": _exec_poke(tokens)
				"PEEK": pass
				"SYS": _exec_sys(tokens)
				"CLR": _variables.clear(); _arrays.clear()
				"NEW": _program.clear(); _variables.clear(); _arrays.clear(); _running = false
				"LIST": _exec_list()
				"RUN": _current_line = 0; _data_pointer = 0
				"DEF": return
				_: pass
		TokenType.IDENTIFIER:
			if tokens.size() >= 2 and tokens[1][0] == TokenType.OPERATOR and tokens[1][1] == "=":
				_exec_let(tokens, 0)
			elif tokens.size() >= 2 and tokens[1][0] == TokenType.LPAREN:
				_exec_let(tokens, 0)

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
			var quote = ch
			pos += 1
			var s = ""
			while pos < text.length() and text[pos] != quote:
				s += text[pos]
				pos += 1
			if pos < text.length():
				pos += 1
			tokens.append([TokenType.STRING, s])
		elif ch.is_valid_int() or (ch == '.' and pos + 1 < text.length() and text[pos + 1].is_valid_int()):
			var num = ""
			var has_dot = false
			while pos < text.length() and (text[pos].is_valid_int() or (text[pos] == '.' and not has_dot)):
				if text[pos] == '.':
					has_dot = true
				num += text[pos]
				pos += 1
			tokens.append([TokenType.NUMBER, float(num) if has_dot else int(num)])
		elif ch == '<':
			pos += 1
			if pos < text.length() and text[pos] == '=':
				tokens.append([TokenType.LTE, "<="])
				pos += 1
			elif pos < text.length() and text[pos] == '>':
				tokens.append([TokenType.NOT_EQUAL, "<>"])
				pos += 1
			else:
				tokens.append([TokenType.OPERATOR, "<"])
		elif ch == '>':
			pos += 1
			if pos < text.length() and text[pos] == '=':
				tokens.append([TokenType.GTE, ">="])
				pos += 1
			else:
				tokens.append([TokenType.OPERATOR, ">"])
		elif ch == '=':
			tokens.append([TokenType.OPERATOR, "="])
			pos += 1
		elif ch == '+':
			tokens.append([TokenType.OPERATOR, "+"])
			pos += 1
		elif ch == '-':
			tokens.append([TokenType.OPERATOR, "-"])
			pos += 1
		elif ch == '*':
			tokens.append([TokenType.OPERATOR, "*"])
			pos += 1
		elif ch == '/':
			tokens.append([TokenType.OPERATOR, "/"])
			pos += 1
		elif ch == '^':
			tokens.append([TokenType.OPERATOR, "^"])
			pos += 1
		elif ch == '(':
			tokens.append([TokenType.LPAREN, "("])
			pos += 1
		elif ch == ')':
			tokens.append([TokenType.RPAREN, ")"])
			pos += 1
		elif ch == ',':
			tokens.append([TokenType.COMMA, ","])
			pos += 1
		elif ch == ';':
			tokens.append([TokenType.SEMICOLON, ";"])
			pos += 1
		elif ch == '$' or ch.is_valid_int() or ch == '_':
			var ident = ""
			while pos < text.length() and (text[pos].is_valid_identifier() or text[pos] == '$' or text[pos] == '%'):
				ident += text[pos]
				pos += 1
			if _keywords.has(ident.to_upper()):
				tokens.append([TokenType.KEYWORD, ident.to_upper()])
			else:
				tokens.append([TokenType.IDENTIFIER, ident])
		elif ch.is_valid_identifier() or ch == '_':
			var ident = ""
			while pos < text.length() and (text[pos].is_valid_identifier() or text[pos] == '$' or text[pos] == '%'):
				ident += text[pos]
				pos += 1
			if _keywords.has(ident.to_upper()):
				tokens.append([TokenType.KEYWORD, ident.to_upper()])
			else:
				tokens.append([TokenType.IDENTIFIER, ident])
		else:
			pos += 1
	tokens.append([TokenType.EOL, ""])
	return tokens

func _exec_print(tokens: Array, start: int) -> void:
	var output = ""
	var pos = start
	var newline = true
	while pos < tokens.size() and tokens[pos][0] != TokenType.EOL:
		if tokens[pos][0] == TokenType.SEMICOLON:
			newline = false
			pos += 1
			continue
		if tokens[pos][0] == TokenType.COMMA:
			output += "\t"
			newline = true
			pos += 1
			continue
		if tokens[pos][0] == TokenType.KEYWORD and tokens[pos][1] == "TAB":
			pos += 1
			if pos < tokens.size() and tokens[pos][0] == TokenType.LPAREN:
				pos += 1
				var tab_val = _eval_expression(tokens, pos)
				pos = _skip_to(tokens, pos, [TokenType.RPAREN])
				if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
					pos += 1
				var spaces = int(tab_val) - output.length()
				if spaces > 0:
					output += " ".repeat(spaces)
			newline = false
			continue
		var val = _eval_expression(tokens, pos)
		pos = _next_print_item(tokens, pos)
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

func _next_print_item(tokens: Array, pos: int) -> int:
	var _depth = 0
	while pos < tokens.size() and tokens[pos][0] != TokenType.EOL:
		if tokens[pos][0] == TokenType.SEMICOLON or tokens[pos][0] == TokenType.COMMA:
			return pos
		if tokens[pos][0] == TokenType.RPAREN:
			if _depth == 0:
				return pos
			_depth -= 1
		if tokens[pos][0] == TokenType.LPAREN:
			_depth += 1
		pos += 1
	return pos

func _exec_input(tokens: Array, start: int) -> Variant:
	var pos = start
	var prompt = "? "
	if tokens[pos][0] == TokenType.STRING:
		prompt = tokens[pos][1]
		pos += 1
		if pos < tokens.size() and tokens[pos][0] == TokenType.SEMICOLON:
			pos += 1
		elif pos < tokens.size() and tokens[pos][0] == TokenType.COMMA:
			pos += 1
	var vars: Array = []
	while pos < tokens.size() and tokens[pos][0] != TokenType.EOL:
		if tokens[pos][0] == TokenType.IDENTIFIER:
			vars.append(tokens[pos][1])
		pos += 1
		if pos < tokens.size() and tokens[pos][0] == TokenType.COMMA:
			pos += 1
	var values = _input_callback.call(prompt)
	if values == null:
		return null
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

func _exec_goto(tokens: Array) -> void:
	var pos = 1
	var target = _eval_expression(tokens, pos)
	var idx = _find_line(int(target))
	if idx >= 0:
		_current_line = idx
		_running = true
	else:
		_output_callback.call("ERROR: LINE NOT FOUND\n")
		_running = false

func _exec_gosub(tokens: Array) -> void:
	var pos = 1
	var target = _eval_expression(tokens, pos)
	var idx = _find_line(int(target))
	if idx >= 0:
		_gosub_stack.append(_current_line + 1)
		_current_line = idx
	else:
		_output_callback.call("ERROR: LINE NOT FOUND\n")
		_running = false

func _exec_return() -> void:
	if _gosub_stack.size() > 0:
		_current_line = _gosub_stack.pop_back()
	else:
		_output_callback.call("ERROR: RETURN WITHOUT GOSUB\n")
		_running = false

func _exec_for(tokens: Array) -> void:
	var pos = 1
	var var_name = tokens[pos][1].to_upper()
	pos += 1
	pos += 1
	var start_val = _eval_expression(tokens, pos)
	pos = _skip_to(tokens, pos, [TokenType.KEYWORD])
	pos += 1
	var end_val = _eval_expression(tokens, pos)
	var step_val = 1.0
	pos = _skip_to(tokens, pos, [TokenType.KEYWORD, TokenType.EOL])
	if pos < tokens.size() and tokens[pos][0] == TokenType.KEYWORD and tokens[pos][1] == "STEP":
		pos += 1
		step_val = _eval_expression(tokens, pos)
	_variables[var_name] = start_val
	_for_stack.append({
		"var": var_name,
		"end": end_val,
		"step": step_val,
		"line": _current_line
	})

func _exec_next(tokens: Array) -> void:
	var var_name = ""
	if tokens.size() > 1 and tokens[1][0] == TokenType.IDENTIFIER:
		var_name = tokens[1][1].to_upper()
	if _for_stack.size() == 0:
		_output_callback.call("ERROR: NEXT WITHOUT FOR\n")
		_running = false
		return
	var for_info = _for_stack[-1]
	if var_name != "" and var_name != for_info["var"]:
		_output_callback.call("ERROR: NEXT WITHOUT FOR\n")
		_running = false
		return
	_variables[for_info["var"]] = float(_variables[for_info["var"]]) + float(for_info["step"])
	var done = false
	if float(for_info["step"]) > 0:
		done = float(_variables[for_info["var"]]) > float(for_info["end"])
	else:
		done = float(_variables[for_info["var"]]) < float(for_info["end"])
	if done:
		_for_stack.pop_back()
	else:
		_current_line = for_info["line"]

func _exec_if(tokens: Array) -> void:
	var pos = 1
	var cond = _eval_expression(tokens, pos)
	pos = _skip_to(tokens, pos, [TokenType.KEYWORD])
	if pos < tokens.size() and tokens[pos][0] == TokenType.KEYWORD and tokens[pos][1] == "THEN":
		pos += 1
	if not cond:
		_skip_then_clause(tokens, pos)
		return
	if pos < tokens.size() and tokens[pos][0] == TokenType.NUMBER:
		var target = int(tokens[pos][1])
		var idx = _find_line(target)
		if idx >= 0:
			_current_line = idx
			_running = true
		else:
			_output_callback.call("ERROR: LINE NOT FOUND\n")
			_running = false
	elif pos < tokens.size():
		var stmt = _reconstruct(tokens, pos)
		_execute_statement(stmt)

func _skip_then_clause(tokens: Array, pos: int) -> void:
	pass

func _exec_let(tokens: Array, start: int) -> void:
	var pos = start
	var var_name = tokens[pos][1].to_upper()
	pos += 1
	if pos < tokens.size() and tokens[pos][0] == TokenType.LPAREN:
		pos += 1
		var idx = int(_eval_expression(tokens, pos))
		pos = _skip_to(tokens, pos, [TokenType.RPAREN])
		pos += 1
		pos += 1
		var val = _eval_expression(tokens, pos)
		if not _arrays.has(var_name):
			_arrays[var_name] = {}
		_arrays[var_name][idx] = val
		return
	pos += 1
	var val = _eval_expression(tokens, pos)
	_variables[var_name] = val

func _exec_dim(tokens: Array) -> void:
	var pos = 1
	while pos < tokens.size() and tokens[pos][0] != TokenType.EOL:
		if tokens[pos][0] == TokenType.IDENTIFIER:
			var name = tokens[pos][1].to_upper()
			pos += 1
			if pos < tokens.size() and tokens[pos][0] == TokenType.LPAREN:
				pos += 1
				var size = int(_eval_expression(tokens, pos))
				if not _arrays.has(name):
					_arrays[name] = {}
				pos = _skip_to(tokens, pos, [TokenType.RPAREN])
				pos += 1
		pos += 1

func _exec_read(tokens: Array) -> void:
	var pos = 1
	while pos < tokens.size() and tokens[pos][0] != TokenType.EOL:
		if tokens[pos][0] == TokenType.IDENTIFIER:
			var name = tokens[pos][1].to_upper()
			pos += 1
			if _data_pointer < _data_values.size():
				_variables[name] = _data_values[_data_pointer]
				_data_pointer += 1
			else:
				_output_callback.call("ERROR: OUT OF DATA\n")
				_running = false
				return
		if pos < tokens.size() and tokens[pos][0] == TokenType.COMMA:
			pos += 1

func _exec_on(tokens: Array) -> void:
	var pos = 1
	var val = int(_eval_expression(tokens, pos))
	pos = _skip_to(tokens, pos, [TokenType.KEYWORD])
	if pos < tokens.size() and tokens[pos][1] == "GOTO":
		pos += 1
		var targets: Array = []
		while pos < tokens.size() and tokens[pos][0] != TokenType.EOL:
			if tokens[pos][0] == TokenType.NUMBER:
				targets.append(int(tokens[pos][1]))
			pos += 1
		if val >= 1 and val <= targets.size():
			var idx = _find_line(targets[val - 1])
			if idx >= 0:
				_current_line = idx
				_running = true
	elif pos < tokens.size() and tokens[pos][1] == "GOSUB":
		pos += 1
		var targets: Array = []
		while pos < tokens.size() and tokens[pos][0] != TokenType.EOL:
			if tokens[pos][0] == TokenType.NUMBER:
				targets.append(int(tokens[pos][1]))
			pos += 1
		if val >= 1 and val <= targets.size():
			var idx = _find_line(targets[val - 1])
			if idx >= 0:
				_gosub_stack.append(_current_line + 1)
				_current_line = idx
				_running = true

func _exec_poke(tokens: Array) -> void:
	var pos = 1
	var addr = int(_eval_expression(tokens, pos))
	pos += 1
	pos += 1
	var val = int(_eval_expression(tokens, pos))
	_memory.poke(addr, val)

func _exec_sys(tokens: Array) -> void:
	var pos = 1
	var addr = int(_eval_expression(tokens, pos))
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
			var items = data_str.split(",")
			for item in items:
				item = item.strip_edges()
				if item.begins_with('"') and item.ends_with('"'):
					_data_values.append(item.substr(1, item.length() - 2))
				elif item.is_valid_int():
					_data_values.append(int(item))
				elif item.is_valid_float():
					_data_values.append(float(item))
				else:
					_data_values.append(item)

func _eval_expression(tokens: Array, pos: int) -> Variant:
	var result = _eval_or(tokens, pos)
	return result[0]

func _eval_or(tokens: Array, pos: int) -> Array:
	var res = _eval_and(tokens, pos)
	var val = res[0]
	pos = res[1]
	while pos < tokens.size() and tokens[pos][0] == TokenType.KEYWORD and tokens[pos][1] == "OR":
		pos += 1
		res = _eval_and(tokens, pos)
		val = 1.0 if (val or res[0]) else 0.0
		pos = res[1]
	return [val, pos]

func _eval_and(tokens: Array, pos: int) -> Array:
	var res = _eval_not(tokens, pos)
	var val = res[0]
	pos = res[1]
	while pos < tokens.size() and tokens[pos][0] == TokenType.KEYWORD and tokens[pos][1] == "AND":
		pos += 1
		res = _eval_not(tokens, pos)
		val = 1.0 if (val and res[0]) else 0.0
		pos = res[1]
	return [val, pos]

func _eval_not(tokens: Array, pos: int) -> Array:
	if pos < tokens.size() and tokens[pos][0] == TokenType.KEYWORD and tokens[pos][1] == "NOT":
		pos += 1
		var res = _eval_comparison(tokens, pos)
		return [0.0 if res[0] else 1.0, res[1]]
	return _eval_comparison(tokens, pos)

func _eval_comparison(tokens: Array, pos: int) -> Array:
	var res = _eval_add(tokens, pos)
	var val = res[0]
	pos = res[1]
	while pos < tokens.size() and (tokens[pos][0] == TokenType.OPERATOR and tokens[pos][1] in ["<", ">", "=", "<=", ">=", "<>"] or tokens[pos][0] in [TokenType.LTE, TokenType.GTE, TokenType.NOT_EQUAL]):
		var op = tokens[pos][1]
		if tokens[pos][0] == TokenType.LTE:
			op = "<="
		elif tokens[pos][0] == TokenType.GTE:
			op = ">="
		elif tokens[pos][0] == TokenType.NOT_EQUAL:
			op = "<>"
		pos += 1
		res = _eval_add(tokens, pos)
		var right = res[0]
		pos = res[1]
		match op:
			"<": val = 1.0 if val < right else 0.0
			">": val = 1.0 if val > right else 0.0
			"=": val = 1.0 if val == right else 0.0
			"<=": val = 1.0 if val <= right else 0.0
			">=": val = 1.0 if val >= right else 0.0
			"<>": val = 1.0 if val != right else 0.0
	return [val, pos]

func _eval_add(tokens: Array, pos: int) -> Array:
	var res = _eval_mult(tokens, pos)
	var val = res[0]
	pos = res[1]
	while pos < tokens.size() and tokens[pos][0] == TokenType.OPERATOR and tokens[pos][1] in ["+", "-"]:
		var op = tokens[pos][1]
		pos += 1
		res = _eval_mult(tokens, pos)
		if op == "+":
			val = float(val) + float(res[0])
		else:
			val = float(val) - float(res[0])
		pos = res[1]
	return [val, pos]

func _eval_mult(tokens: Array, pos: int) -> Array:
	var res = _eval_power(tokens, pos)
	var val = res[0]
	pos = res[1]
	while pos < tokens.size() and tokens[pos][0] == TokenType.OPERATOR and tokens[pos][1] in ["*", "/"]:
		var op = tokens[pos][1]
		pos += 1
		res = _eval_power(tokens, pos)
		if op == "*":
			val = float(val) * float(res[0])
		else:
			if float(res[0]) != 0:
				val = float(val) / float(res[0])
			else:
				val = 0.0
		pos = res[1]
	return [val, pos]

func _eval_power(tokens: Array, pos: int) -> Array:
	var res = _eval_unary(tokens, pos)
	var val = res[0]
	pos = res[1]
	if pos < tokens.size() and tokens[pos][0] == TokenType.OPERATOR and tokens[pos][1] == "^":
		pos += 1
		res = _eval_power(tokens, pos)
		val = pow(float(val), float(res[0]))
		pos = res[1]
	return [val, pos]

func _eval_unary(tokens: Array, pos: int) -> Array:
	if pos < tokens.size() and tokens[pos][0] == TokenType.OPERATOR and tokens[pos][1] == "-":
		pos += 1
		var res = _eval_atom(tokens, pos)
		return [-float(res[0]), res[1]]
	return _eval_atom(tokens, pos)

func _eval_atom(tokens: Array, pos: int) -> Array:
	if pos >= tokens.size():
		return [0, pos]
	var tok = tokens[pos]
	match tok[0]:
		TokenType.NUMBER:
			return [tok[1], pos + 1]
		TokenType.STRING:
			return [tok[1], pos + 1]
		TokenType.IDENTIFIER:
			var name = tok[1].to_upper()
			pos += 1
			if pos < tokens.size() and tokens[pos][0] == TokenType.LPAREN:
				pos += 1
				var idx = _eval_expression(tokens, pos)
				pos = idx[1] if idx is Array else pos
				if idx is Array:
					idx = idx[0]
					pos = idx[1] if idx is Array else pos
				if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
					pos += 1
				if _arrays.has(name) and _arrays[name].has(int(idx)):
					return [_arrays[name][int(idx)], pos]
				return [0, pos]
			else:
				if _variables.has(name):
					return [_variables[name], pos]
				return [0, pos]
		TokenType.KEYWORD:
			var fn_name = tok[1].to_upper()
			match fn_name:
				"INT":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [floor(float(res[0])), pos]
				"RND":
					pos += 1
					pos += 1
					pos += 1
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [randf(), pos]
				"ABS":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [abs(float(res[0])), pos]
				"SQR":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [sqrt(float(res[0])), pos]
				"SIN":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [sin(float(res[0])), pos]
				"COS":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [cos(float(res[0])), pos]
				"TAN":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [tan(float(res[0])), pos]
				"ATN":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [atan(float(res[0])), pos]
				"LOG":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [log(float(res[0])), pos]
				"EXP":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [exp(float(res[0])), pos]
				"SGN":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					var v = float(res[0])
					return [1.0 if v > 0 else (-1.0 if v < 0 else 0.0), pos]
				"LEN":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [str(res[0]).length(), pos]
				"CHR$":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [char(int(res[0])), pos]
				"ASC":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					var s = str(res[0])
					return [s.ord_at(0) if s.length() > 0 else 0, pos]
				"LEFT$":
					pos += 1
					pos += 1
					var s_res = _eval_expression(tokens, pos)
					pos = s_res[1]
					pos += 1
					var n_res = _eval_expression(tokens, pos)
					pos = n_res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					var s = str(s_res[0])
					return [s.substr(0, int(n_res[0])), pos]
				"RIGHT$":
					pos += 1
					pos += 1
					var s_res = _eval_expression(tokens, pos)
					pos = s_res[1]
					pos += 1
					var n_res = _eval_expression(tokens, pos)
					pos = n_res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					var s = str(s_res[0])
					var n = int(n_res[0])
					return [s.substr(max(0, s.length() - n)), pos]
				"MID$":
					pos += 1
					pos += 1
					var s_res = _eval_expression(tokens, pos)
					pos = s_res[1]
					pos += 1
					var start_res = _eval_expression(tokens, pos)
					pos = start_res[1]
					var length = -1
					if pos < tokens.size() and tokens[pos][0] == TokenType.COMMA:
						pos += 1
						var l_res = _eval_expression(tokens, pos)
						length = int(l_res[0])
						pos = l_res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					var s = str(s_res[0])
					var st = int(start_res[0]) - 1
					if length >= 0:
						return [s.substr(st, length), pos]
					return [s.substr(st), pos]
				"STR$":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [str(res[0]), pos]
				"VAL":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					var s = str(res[0])
					return [float(s) if s.is_valid_float() else 0.0, pos]
				"PEEK":
					pos += 1
					pos += 1
					var res = _eval_expression(tokens, pos)
					pos = res[1]
					if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
						pos += 1
					return [_memory.peek(int(res[0])), pos]
				_:
					return [0, pos + 1]
		TokenType.LPAREN:
			pos += 1
			var res = _eval_expression(tokens, pos)
			pos = res[1]
			if pos < tokens.size() and tokens[pos][0] == TokenType.RPAREN:
				pos += 1
			return [res[0], pos]
		TokenType.OPERATOR:
			if tok[1] == "+":
				pos += 1
				var res = _eval_atom(tokens, pos)
				return [res[0], res[1]]
			elif tok[1] == "-":
				pos += 1
				var res = _eval_atom(tokens, pos)
				return [-float(res[0]), res[1]]
	return [0, pos + 1]

func _skip_to(tokens: Array, pos: int, targets: Array) -> int:
	var depth = 0
	while pos < tokens.size() and tokens[pos][0] != TokenType.EOL:
		for t in targets:
			if tokens[pos][0] == t and depth == 0:
				return pos
		if tokens[pos][0] == TokenType.LPAREN:
			depth += 1
		elif tokens[pos][0] == TokenType.RPAREN:
			depth -= 1
		pos += 1
	return pos

func _reconstruct(tokens: Array, start: int) -> String:
	var result = ""
	for i in range(start, tokens.size()):
		if tokens[i][0] == TokenType.EOL:
			break
		if result.length() > 0 and tokens[i][0] != TokenType.OPERATOR and tokens[i][0] != TokenType.LPAREN and tokens[i][0] != TokenType.RPAREN:
			if result.length() > 0 and result[-1] != " ":
				result += " "
		result += str(tokens[i][1])
	return result

func set_variable(name: String, value: Variant) -> void:
	_variables[name.to_upper()] = value

func get_variable(name: String) -> Variant:
	return _variables.get(name.to_upper(), 0)

func execute_line(stmt: String) -> void:
	_execute_statement(stmt)
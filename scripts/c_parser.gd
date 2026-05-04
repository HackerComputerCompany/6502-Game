## Recursive-descent parser for Small-C -> AST.
class_name CParser
extends RefCounted

var errors: Array[String] = []

var _tokens: Array
var _pos: int
var _defines: Dictionary = {}

func parse(tokens: Array) -> Dictionary:
	_tokens = tokens
	_pos = 0
	_defines.clear()
	errors.clear()
	var program: Dictionary = {"type": "Program", "declarations": []}
	_preprocess_defines()
	while not _at_end():
		var decl: Dictionary = _parse_declaration()
		if not decl.is_empty():
			program["declarations"].append(decl)
	return program

func _preprocess_defines() -> void:
	var i := 0
	while i < _tokens.size():
		var tok = _tokens[i]
		if tok.type == CLexer.TokenType.DEFINE_KW:
			var name_tok = _tokens[i + 1]
			var val_tok = _tokens[i + 3]
			_defines[name_tok.value] = val_tok.value
			i += 4
		else:
			i += 1

func _cur() -> Dictionary:
	if _pos < _tokens.size():
		var t = _tokens[_pos]
		return {"type": t.type, "value": t.value, "line": t.line}
	return {"type": CLexer.TokenType.END, "value": "", "line": 0}

func _peek_ahead(offset: int = 1) -> Dictionary:
	var idx := _pos + offset
	if idx < _tokens.size():
		var t = _tokens[idx]
		return {"type": t.type, "value": t.value, "line": t.line}
	return {"type": CLexer.TokenType.END, "value": "", "line": 0}

func _advance() -> Dictionary:
	var cur := _cur()
	_pos += 1
	return cur

func _expect(tt: int) -> Dictionary:
	var cur := _cur()
	if cur["type"] != tt:
		_error("Expected token type %d, got '%s' (type %d) at line %d" % [tt, cur["value"], cur["type"], cur["line"]])
		return cur
	return _advance()

func _at_end() -> bool:
	return _cur()["type"] == CLexer.TokenType.END

func _error(msg: String) -> void:
	errors.append(msg)

func _empty_dict() -> Dictionary:
	return {}

func _parse_declaration() -> Dictionary:
	var cur := _cur()
	if cur["type"] == CLexer.TokenType.INT_KW or cur["type"] == CLexer.TokenType.CHAR_KW:
		return _parse_func_or_var_decl()
	elif cur["type"] == CLexer.TokenType.IDENT:
		var next: Dictionary = _peek_ahead()
		if next["value"] == "(":
			var fname: String = cur["value"]
			_advance()
			return _parse_func_def("int", fname)
		_advance()
		return _empty_dict()
	_advance()
	return _empty_dict()

func _parse_func_or_var_decl() -> Dictionary:
	var type_tok := _advance()
	var type_name := "int" if type_tok["type"] == CLexer.TokenType.INT_KW else "char"
	var name_tok := _cur()
	if name_tok["type"] != CLexer.TokenType.IDENT:
		_error("Expected identifier, got '%s'" % name_tok["value"])
		_advance()
		return _empty_dict()
	_advance()
	var next := _cur()
	if next["value"] == "(":
		return _parse_func_def(type_name, name_tok["value"])
	elif next["value"] == "[":
		return _parse_global_array(type_name, name_tok["value"])
	elif next["value"] == "=":
		_advance()
		var init: Dictionary = _parse_expression()
		_expect(CLexer.TokenType.SEMICOLON)
		return {"type": "VarDecl", "name": name_tok["value"], "var_type": type_name, "init": init, "is_global": true, "array_size": -1}
	else:
		_expect(CLexer.TokenType.SEMICOLON)
		return {"type": "VarDecl", "name": name_tok["value"], "var_type": type_name, "init": null, "is_global": true, "array_size": -1}

func _parse_func_def(type_name: String, name: String) -> Dictionary:
	_expect(CLexer.TokenType.LPAREN)
	var params: Array = []
	if _cur()["value"] != ")":
		params = _parse_param_list()
	_expect(CLexer.TokenType.RPAREN)
	var body: Dictionary = _parse_block()
	return {"type": "FuncDef", "name": name, "return_type": type_name, "params": params, "body": body}

func _parse_param_list() -> Array:
	var params: Array = []
	var cur := _cur()
	if cur["type"] == CLexer.TokenType.INT_KW or cur["type"] == CLexer.TokenType.CHAR_KW:
		var ptype := _advance()
		var ptype_name := "int" if ptype["type"] == CLexer.TokenType.INT_KW else "char"
		var is_array := false
		var pname := _cur()
		_advance()
		if _cur()["value"] == "[":
			is_array = true
			_advance()
			_expect(CLexer.TokenType.RBRACKET)
		params.append({"name": pname["value"], "var_type": ptype_name, "is_array": is_array})
	while _cur()["value"] == ",":
		_advance()
		cur = _cur()
		if cur["type"] == CLexer.TokenType.INT_KW or cur["type"] == CLexer.TokenType.CHAR_KW:
			var ptype := _advance()
			var ptype_name := "int" if ptype["type"] == CLexer.TokenType.INT_KW else "char"
			var is_array := false
			var pname := _cur()
			_advance()
			if _cur()["value"] == "[":
				is_array = true
				_advance()
				_expect(CLexer.TokenType.RBRACKET)
			params.append({"name": pname["value"], "var_type": ptype_name, "is_array": is_array})
	return params

func _parse_global_array(type_name: String, name: String) -> Dictionary:
	_advance()
	var size_tok := _cur()
	var size: int = -1
	if size_tok["type"] == CLexer.TokenType.NUMBER:
		size = _parse_int(size_tok["value"])
		_advance()
	_expect(CLexer.TokenType.RBRACKET)
	var init = null
	if _cur()["value"] == "=":
		_advance()
		init = _parse_array_init()
	_expect(CLexer.TokenType.SEMICOLON)
	return {"type": "VarDecl", "name": name, "var_type": type_name, "init": init, "is_global": true, "array_size": size}

func _parse_array_init() -> Array:
	_expect(CLexer.TokenType.LBRACE)
	var vals: Array = []
	if _cur()["value"] != "}":
		vals.append(_parse_expression())
		while _cur()["value"] == ",":
			_advance()
			vals.append(_parse_expression())
	_expect(CLexer.TokenType.RBRACE)
	return vals

func _parse_block() -> Dictionary:
	_expect(CLexer.TokenType.LBRACE)
	var stmts: Array = []
	while _cur()["value"] != "}":
		var stmt: Dictionary = _parse_statement()
		if not stmt.is_empty():
			stmts.append(stmt)
	_expect(CLexer.TokenType.RBRACE)
	return {"type": "Block", "statements": stmts}

func _parse_statement() -> Dictionary:
	var cur := _cur()
	if cur["value"] == "{":
		return _parse_block()
	elif cur["value"] == "if":
		return _parse_if()
	elif cur["value"] == "while":
		return _parse_while()
	elif cur["value"] == "for":
		return _parse_for()
	elif cur["value"] == "return":
		return _parse_return()
	elif cur["value"] == "break":
		_advance()
		_expect(CLexer.TokenType.SEMICOLON)
		return {"type": "BreakStmt"}
	elif cur["type"] == CLexer.TokenType.GOTO_KW:
		_advance()
		var target := _cur()["value"]
		_advance()
		_expect(CLexer.TokenType.SEMICOLON)
		return {"type": "GotoStmt", "target": target}
	elif cur["value"] == ";":
		_advance()
		return {"type": "EmptyStmt"}
	elif cur["type"] == CLexer.TokenType.INT_KW or cur["type"] == CLexer.TokenType.CHAR_KW:
		return _parse_local_decl()
	elif _peek_ahead()["value"] == ":":
		var label := cur["value"]
		_advance()
		_advance()
		return {"type": "LabelStmt", "label": label}
	else:
		return _parse_expr_stmt()

func _parse_local_decl() -> Dictionary:
	var type_tok := _advance()
	var type_name := "int" if type_tok["type"] == CLexer.TokenType.INT_KW else "char"
	return _parse_single_var_decl(type_name)

func _parse_single_var_decl(type_name: String) -> Dictionary:
	var name_tok := _cur()
	if name_tok["type"] != CLexer.TokenType.IDENT:
		_error("Expected identifier, got '%s'" % name_tok["value"])
		_advance()
		return {"type": "EmptyStmt"}
	_advance()
	var arr_size: int = -1
	if _cur()["value"] == "[":
		_advance()
		var sz_tok := _cur()
		if sz_tok["type"] == CLexer.TokenType.NUMBER:
			arr_size = _parse_int(sz_tok["value"])
			_advance()
		_expect(CLexer.TokenType.RBRACKET)
	var init = null
	if _cur()["value"] == "=":
		_advance()
		init = _parse_expression()
	_expect(CLexer.TokenType.SEMICOLON)
	return {"type": "VarDecl", "name": name_tok["value"], "var_type": type_name, "init": init, "is_global": false, "array_size": arr_size}

func _parse_if() -> Dictionary:
	_advance()
	_expect(CLexer.TokenType.LPAREN)
	var cond: Dictionary = _parse_expression()
	_expect(CLexer.TokenType.RPAREN)
	var then_body: Dictionary = _parse_statement()
	var else_body = null
	if _cur()["value"] == "else":
		_advance()
		else_body = _parse_statement()
	return {"type": "IfStmt", "cond": cond, "then_body": then_body, "else_body": else_body}

func _parse_while() -> Dictionary:
	_advance()
	_expect(CLexer.TokenType.LPAREN)
	var cond: Dictionary = _parse_expression()
	_expect(CLexer.TokenType.RPAREN)
	var body: Dictionary = _parse_statement()
	return {"type": "WhileStmt", "cond": cond, "body": body}

func _parse_for() -> Dictionary:
	_advance()
	_expect(CLexer.TokenType.LPAREN)
	var init = null
	if _cur()["value"] != ";":
		init = _parse_expression()
	_expect(CLexer.TokenType.SEMICOLON)
	var cond = null
	if _cur()["value"] != ";":
		cond = _parse_expression()
	_expect(CLexer.TokenType.SEMICOLON)
	var step = null
	if _cur()["value"] != ")":
		step = _parse_expression()
	_expect(CLexer.TokenType.RPAREN)
	var body: Dictionary = _parse_statement()
	return {"type": "ForStmt", "init": init, "cond": cond, "step": step, "body": body}

func _parse_return() -> Dictionary:
	_advance()
	var expr = null
	if _cur()["value"] != ";":
		expr = _parse_expression()
	_expect(CLexer.TokenType.SEMICOLON)
	return {"type": "ReturnStmt", "expr": expr}

func _parse_expr_stmt() -> Dictionary:
	var expr: Dictionary = _parse_expression()
	_expect(CLexer.TokenType.SEMICOLON)
	return {"type": "ExprStmt", "expr": expr}

func _parse_expression() -> Dictionary:
	return _parse_assign()

func _parse_assign() -> Dictionary:
	var expr: Dictionary = _parse_or()
	var cur := _cur()
	if cur["value"] == "=" or cur["value"] == "+=" or cur["value"] == "-=":
		var op: String = _advance()["value"]
		var val: Dictionary = _parse_assign()
		return {"type": "AssignExpr", "target": expr, "op": op, "value": val}
	return expr

func _parse_or() -> Dictionary:
	var left: Dictionary = _parse_and()
	while _cur()["value"] == "||":
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_and()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_and() -> Dictionary:
	var left: Dictionary = _parse_bitor()
	while _cur()["value"] == "&&":
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_bitor()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_bitor() -> Dictionary:
	var left: Dictionary = _parse_bitxor()
	while _cur()["value"] == "|":
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_bitxor()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_bitxor() -> Dictionary:
	var left: Dictionary = _parse_bitand()
	while _cur()["value"] == "^":
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_bitand()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_bitand() -> Dictionary:
	var left: Dictionary = _parse_equality()
	while _cur()["value"] == "&" and _peek_ahead()["value"] != "&":
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_equality()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_equality() -> Dictionary:
	var left: Dictionary = _parse_relational()
	while _cur()["value"] == "==" or _cur()["value"] == "!=":
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_relational()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_relational() -> Dictionary:
	var left: Dictionary = _parse_shift()
	while _cur()["value"] in ["<", ">", "<=", ">="]:
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_shift()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_shift() -> Dictionary:
	var left: Dictionary = _parse_additive()
	while _cur()["value"] == "<<" or _cur()["value"] == ">>":
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_additive()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_additive() -> Dictionary:
	var left: Dictionary = _parse_multiplicative()
	while _cur()["value"] == "+" or _cur()["value"] == "-":
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_multiplicative()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_multiplicative() -> Dictionary:
	var left: Dictionary = _parse_unary()
	while _cur()["value"] in ["*", "/", "%"]:
		var op: String = _advance()["value"]
		var right: Dictionary = _parse_unary()
		left = {"type": "BinaryExpr", "left": left, "op": op, "right": right}
	return left

func _parse_unary() -> Dictionary:
	var cur := _cur()
	if cur["value"] == "!":
		_advance()
		var operand: Dictionary = _parse_unary()
		return {"type": "UnaryExpr", "op": "!", "operand": operand}
	elif cur["value"] == "~":
		_advance()
		var operand: Dictionary = _parse_unary()
		return {"type": "UnaryExpr", "op": "~", "operand": operand}
	elif cur["value"] == "-":
		var ahead := _peek_ahead()
		if ahead["type"] == CLexer.TokenType.NUMBER:
			var num_tok := _advance()
			_advance()
			var val: int = -_parse_int(num_tok["value"])
			return {"type": "NumberLit", "value": val}
		var operand: Dictionary = _parse_unary()
		return {"type": "UnaryExpr", "op": "neg", "operand": operand}
	elif cur["value"] == "*":
		_advance()
		var operand: Dictionary = _parse_unary()
		return {"type": "DerefExpr", "expr": operand}
	elif cur["value"] == "&" and _peek_ahead()["value"] != "&":
		_advance()
		var operand: Dictionary = _parse_unary()
		return {"type": "AddrOfExpr", "expr": operand}
	return _parse_postfix()

func _parse_postfix() -> Dictionary:
	var expr: Dictionary = _parse_primary()
	while _cur()["value"] == "[" or _cur()["value"] == "(":
		if _cur()["value"] == "(":
			_advance()
			var args: Array = []
			if _cur()["value"] != ")":
				args.append(_parse_expression())
				while _cur()["value"] == ",":
					_advance()
					args.append(_parse_expression())
			_expect(CLexer.TokenType.RPAREN)
			expr = {"type": "FuncCall", "func": expr, "args": args}
		elif _cur()["value"] == "[":
			_advance()
			var index: Dictionary = _parse_expression()
			_expect(CLexer.TokenType.RBRACKET)
			expr = {"type": "ArrayRef", "array": expr, "index": index}
	return expr

func _parse_primary() -> Dictionary:
	var cur := _cur()
	if cur["type"] == CLexer.TokenType.NUMBER:
		_advance()
		return {"type": "NumberLit", "value": _parse_int(cur["value"])}
	elif cur["type"] == CLexer.TokenType.STRING:
		_advance()
		return {"type": "StringLit", "value": cur["value"]}
	elif cur["type"] == CLexer.TokenType.IDENT:
		_advance()
		return {"type": "IdentRef", "name": cur["value"]}
	elif cur["value"] == "(":
		_advance()
		var expr: Dictionary = _parse_expression()
		_expect(CLexer.TokenType.RPAREN)
		return expr
	else:
		_error("Unexpected '%s' at line %d" % [cur["value"], cur["line"]])
		_advance()
		return {"type": "NumberLit", "value": 0}

func _parse_int(s: String) -> int:
	s = s.strip_edges()
	if s.begins_with("0x") or s.begins_with("0X"):
		var hex_str := s.substr(2)
		var val: int = 0
		for i in range(hex_str.length()):
			var c := hex_str[i].to_lower()
			val = val * 16
			if c.is_valid_int():
				val += int(c)
			else:
				val += c.unicode_at(0) - ord("a") + 10
		return val
	elif s.begins_with("0") and s.length() > 1:
		var oct_str := s
		var val: int = 0
		for i in range(oct_str.length()):
			val = val * 8 + int(oct_str[i])
		return val
	return int(s)

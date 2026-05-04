## C lexer for Small-C compiler.
## Tokenizes C source into a flat token stream.
class_name CLexer
extends RefCounted

enum TokenType {
	INT_KW, CHAR_KW, IF_KW, ELSE_KW, WHILE_KW, FOR_KW, RETURN_KW, BREAK_KW,
	GOTO_KW,
	DEFINE_KW,
	IDENT, NUMBER, STRING,
	LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET,
	SEMICOLON, COMMA,
	ASSIGN, PLUS_ASSIGN, MINUS_ASSIGN,
	PLUS, MINUS, STAR, SLASH, PERCENT,
	EQ, NEQ, LT, GT, LTE, GTE,
	AND, OR, NOT,
	AMPERSAND, PIPE, CARET, TILDE,
	LSHIFT, RSHIFT,
	ANDAND, OROR,
	EXCLAMATION,
	END,
}

class Token:
	var type: int
	var value: String
	var line: int
	func _init(t: int, v: String, l: int) -> void:
		type = t; value = v; line = l

var tokens: Array[Token] = []
var errors: Array[String] = []

static var _keywords: Dictionary = {}
static var _kw_init: bool = false

func _init() -> void:
	if not _kw_init:
		_keywords["int"] = TokenType.INT_KW
		_keywords["char"] = TokenType.CHAR_KW
		_keywords["if"] = TokenType.IF_KW
		_keywords["else"] = TokenType.ELSE_KW
		_keywords["while"] = TokenType.WHILE_KW
		_keywords["for"] = TokenType.FOR_KW
		_keywords["return"] = TokenType.RETURN_KW
		_keywords["break"] = TokenType.BREAK_KW
		_keywords["goto"] = TokenType.GOTO_KW
		_keywords["define"] = TokenType.DEFINE_KW
		_kw_init = true

func tokenize(source: String) -> Array[Token]:
	tokens.clear()
	errors.clear()
	var lines := source.split("\n")
	var i := 0
	while i < lines.size():
		var line := lines[i]
		var line_num := i + 1
		line = _strip_comments(line)
		var pos := 0
		while pos < line.length():
			var ch := line[pos]
			if ch == " " or ch == "\t" or ch == "\r":
				pos += 1
				continue
			if ch == "#":
				var rest := line.substr(pos + 1).strip_edges()
				if rest.begins_with("define"):
					_tokenize_directive(rest, line_num)
				pos = line.length()
				continue
			if ch == '"':
				pos = _read_string(line, pos, line_num)
				continue
			if ch == "'":
				pos = _read_char_literal(line, pos, line_num)
				continue
			if ch.is_valid_int():
				pos = _read_number(line, pos, line_num)
				continue
			if _is_ident_start(ch):
				pos = _read_ident(line, pos, line_num)
				continue
			pos = _read_operator(line, pos, line_num)
		i += 1
	tokens.append(Token.new(TokenType.END, "", lines.size()))
	return tokens

func _strip_comments(line: String) -> String:
	var result := ""
	var in_str := false
	var i := 0
	while i < line.length():
		var ch := line[i]
		if in_str:
			result += ch
			if ch == "\\":
				i += 1
				if i < line.length():
					result += line[i]
			elif ch == '"':
				in_str = false
		else:
			if ch == '"':
				in_str = true
				result += ch
			elif ch == "/" and i + 1 < line.length() and line[i + 1] == "/":
				break
			elif ch == "/" and i + 1 < line.length() and line[i + 1] == "*":
				i += 2
				while i + 1 < line.length() and not (line[i] == "*" and line[i + 1] == "/"):
					i += 1
				i += 1
				continue
			else:
				result += ch
		i += 1
	return result

func _read_string(line: String, pos: int, line_num: int) -> int:
	pos += 1
	var val := ""
	while pos < line.length() and line[pos] != '"':
		if line[pos] == "\\" and pos + 1 < line.length():
			pos += 1
			match line[pos]:
				"n": val += "\n"
				"t": val += "\t"
				"\\": val += "\\"
				'"': val += '"'
				"0": val += char(0)
				_: val += line[pos]
		else:
			val += line[pos]
		pos += 1
	if pos < line.length():
		pos += 1
	tokens.append(Token.new(TokenType.STRING, val, line_num))
	return pos

func _read_char_literal(line: String, pos: int, line_num: int) -> int:
	pos += 1
	var val := 0
	if pos < line.length():
		if line[pos] == "\\" and pos + 1 < line.length():
			pos += 1
			match line[pos]:
				"n": val = 10
				"t": val = 9
				"\\": val = 92
				"'": val = 39
				"0": val = 0
				_: val = line[pos].unicode_at(0)
		else:
			val = line[pos].unicode_at(0)
		pos += 1
	if pos < line.length() and line[pos] == "'":
		pos += 1
	tokens.append(Token.new(TokenType.NUMBER, str(val), line_num))
	return pos

func _read_number(line: String, pos: int, line_num: int) -> int:
	var val := ""
	while pos < line.length() and (line[pos].is_valid_int() or line[pos].to_lower() in ["a", "b", "c", "d", "e", "f"]):
		val += line[pos]
		pos += 1
	tokens.append(Token.new(TokenType.NUMBER, val, line_num))
	return pos

func _read_ident(line: String, pos: int, line_num: int) -> int:
	var name := ""
	while pos < line.length() and _is_ident_char(line[pos]):
		name += line[pos]
		pos += 1
	if _keywords.has(name):
		tokens.append(Token.new(_keywords[name], name, line_num))
	else:
		tokens.append(Token.new(TokenType.IDENT, name, line_num))
	return pos

func _read_operator(line: String, pos: int, line_num: int) -> int:
	var ch := line[pos]
	var two := ""
	if pos + 1 < line.length():
		two = line[pos] + line[pos + 1]
	if two == "==":
		tokens.append(Token.new(TokenType.EQ, "==", line_num))
		return pos + 2
	elif two == "!=":
		tokens.append(Token.new(TokenType.NEQ, "!=", line_num))
		return pos + 2
	elif two == "<=":
		tokens.append(Token.new(TokenType.LTE, "<=", line_num))
		return pos + 2
	elif two == ">=":
		tokens.append(Token.new(TokenType.GTE, ">=", line_num))
		return pos + 2
	elif two == "&&":
		tokens.append(Token.new(TokenType.ANDAND, "&&", line_num))
		return pos + 2
	elif two == "||":
		tokens.append(Token.new(TokenType.OROR, "||", line_num))
		return pos + 2
	elif two == "<<":
		tokens.append(Token.new(TokenType.LSHIFT, "<<", line_num))
		return pos + 2
	elif two == ">>":
		tokens.append(Token.new(TokenType.RSHIFT, ">>", line_num))
		return pos + 2
	elif two == "+=":
		tokens.append(Token.new(TokenType.PLUS_ASSIGN, "+=", line_num))
		return pos + 2
	elif two == "-=":
		tokens.append(Token.new(TokenType.MINUS_ASSIGN, "-=", line_num))
		return pos + 2
	match ch:
		"(": tokens.append(Token.new(TokenType.LPAREN, "(", line_num))
		")": tokens.append(Token.new(TokenType.RPAREN, ")", line_num))
		"{": tokens.append(Token.new(TokenType.LBRACE, "{", line_num))
		"}": tokens.append(Token.new(TokenType.RBRACE, "}", line_num))
		"[": tokens.append(Token.new(TokenType.LBRACKET, "[", line_num))
		"]": tokens.append(Token.new(TokenType.RBRACKET, "]", line_num))
		";": tokens.append(Token.new(TokenType.SEMICOLON, ";", line_num))
		",": tokens.append(Token.new(TokenType.COMMA, ",", line_num))
		"=": tokens.append(Token.new(TokenType.ASSIGN, "=", line_num))
		"+": tokens.append(Token.new(TokenType.PLUS, "+", line_num))
		"-": tokens.append(Token.new(TokenType.MINUS, "-", line_num))
		"*": tokens.append(Token.new(TokenType.STAR, "*", line_num))
		"/": tokens.append(Token.new(TokenType.SLASH, "/", line_num))
		"%": tokens.append(Token.new(TokenType.PERCENT, "%", line_num))
		"<": tokens.append(Token.new(TokenType.LT, "<", line_num))
		">": tokens.append(Token.new(TokenType.GT, ">", line_num))
		"&": tokens.append(Token.new(TokenType.AMPERSAND, "&", line_num))
		"|": tokens.append(Token.new(TokenType.PIPE, "|", line_num))
		"^": tokens.append(Token.new(TokenType.CARET, "^", line_num))
		"~": tokens.append(Token.new(TokenType.TILDE, "~", line_num))
		"!": tokens.append(Token.new(TokenType.EXCLAMATION, "!", line_num))
		_:
			errors.append("Line %d: unexpected character '%s'" % [line_num, ch])
	return pos + 1

func _is_ident_start(ch: String) -> bool:
	var u := ch.unicode_at(0)
	return (u >= 65 and u <= 90) or (u >= 97 and u <= 122) or u == 95

func _is_ident_char(ch: String) -> bool:
	var u := ch.unicode_at(0)
	return _is_ident_start(ch) or (u >= 48 and u <= 57)

func _tokenize_directive(rest: String, line_num: int) -> void:
	rest = rest.substr(6).strip_edges()
	var space := rest.find(" ")
	if space < 0:
		errors.append("Line %d: #define requires name and value" % line_num)
		return
	var name := rest.substr(0, space).strip_edges()
	var val := rest.substr(space + 1).strip_edges()
	tokens.append(Token.new(TokenType.DEFINE_KW, name, line_num))
	tokens.append(Token.new(TokenType.IDENT, name, line_num))
	tokens.append(Token.new(TokenType.ASSIGN, "=", line_num))
	if val.is_valid_int():
		tokens.append(Token.new(TokenType.NUMBER, val, line_num))
	elif val.begins_with('"') and val.ends_with('"'):
		tokens.append(Token.new(TokenType.STRING, val.substr(1, val.length() - 2), line_num))
	else:
		tokens.append(Token.new(TokenType.IDENT, val, line_num))

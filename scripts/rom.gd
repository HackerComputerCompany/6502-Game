class_name ROM
extends RefCounted

var _memory: MemoryBus

func _init(mem: MemoryBus) -> void:
	_memory = mem
	_load_rom()

func _load_rom() -> void:
	_write_warmboot()
	_write_char_out()
	_write_string_out()
	_write_counter()
	_write_add_two()
	_write_fibonacci()
	_write_scroll()
	_write_hex_out()

func _write_warmboot() -> void:
	var code = [
		0xA2, 0x00,
		0x8E, 0x00, 0xC0,
		0xA9, 0x0C,
		0x8D, 0x03, 0xC0,
		0xA9, 0x0D,
		0x8D, 0x03, 0xC0,
		0xA0, 0x00,
		0xB1, 0x10,
		0xF0, 0x06,
		0x8D, 0x02, 0xC0,
		0xC8,
		0xD0, 0xF5,
		0x4C, 0x00, 0x08,
	]
	_store_at(0xF000, code)

func _write_char_out() -> void:
	var code = [
		0x8D, 0x02, 0xC0,
		0x60,
	]
	_store_at(0xF020, code)

func _write_string_out() -> void:
	var code = [
		0xA0, 0x00,
		0xB1, 0x1C,
		0xF0, 0x05,
		0x8D, 0x02, 0xC0,
		0xC8,
		0xD0, 0xF7,
		0x60,
	]
	_store_at(0xF030, code)

func _write_counter() -> void:
	var code = [
		0xA2, 0x30,
		0x8E, 0x00, 0x20,
		0xAD, 0x00, 0x20,
		0x8D, 0x02, 0xC0,
		0xA9, 0x0D,
		0x8D, 0x03, 0xC0,
		0xEE, 0x00, 0x20,
		0xA2, 0x10,
		0xCA,
		0xD0, 0xFD,
		0xAE, 0x00, 0x20,
		0xE0, 0x3A,
		0xD0, 0xE6,
		0x60,
	]
	_store_at(0xF040, code)

func _write_add_two() -> void:
	var code = [
		0x18,
		0x69, 0x02,
		0x8D, 0x00, 0x20,
		0xAD, 0x00, 0x20,
		0x09, 0x30,
		0x8D, 0x02, 0xC0,
		0xA9, 0x0D,
		0x8D, 0x03, 0xC0,
		0x60,
	]
	_store_at(0xF060, code)

func _write_fibonacci() -> void:
	var code = [
		0xA9, 0x00,
		0x8D, 0x00, 0x20,
		0xA9, 0x01,
		0x8D, 0x01, 0x20,
		0xA2, 0x08,
		0xAD, 0x00, 0x20,
		0x8D, 0x02, 0xC0,
		0xA9, 0x20,
		0x8D, 0x02, 0xC0,
		0x18,
		0xAD, 0x00, 0x20,
		0x6D, 0x01, 0x20,
		0x8D, 0x02, 0x20,
		0xAD, 0x01, 0x20,
		0x8D, 0x00, 0x20,
		0xAD, 0x02, 0x20,
		0x8D, 0x01, 0x20,
		0xCA,
		0xD0, 0xDD,
		0x60,
	]
	_store_at(0xF080, code)

func _write_scroll() -> void:
	var code = [
		0xA9, 0x2A,
		0x8D, 0x02, 0xC0,
		0xA9, 0x0D,
		0x8D, 0x03, 0xC0,
		0xA2, 0xFF,
		0xCA,
		0xD0, 0xFD,
		0xA9, 0x2F,
		0x8D, 0x02, 0xC0,
		0xA9, 0x0D,
		0x8D, 0x03, 0xC0,
		0xA2, 0xFF,
		0xCA,
		0xD0, 0xFD,
		0x4C, 0x00, 0xF0,
	]
	_store_at(0xF0C0, code)

func _write_hex_out() -> void:
	var code = [
		0x48,
		0x4A,
		0x4A,
		0x4A,
		0x4A,
		0x20, 0xE0, 0xF1,
		0x68,
		0x29, 0x0F,
		0x18,
		0x69, 0x30,
		0xC9, 0x3A,
		0x90, 0x02,
		0x69, 0x06,
		0x8D, 0x02, 0xC0,
		0x60,
		0x18,
		0x69, 0x30,
		0xC9, 0x3A,
		0x90, 0x02,
		0x69, 0x06,
		0x8D, 0x02, 0xC0,
		0x60,
	]
	_store_at(0xF100, code)

func _store_at(addr: int, code: Array) -> void:
	for i in range(code.size()):
		_memory.poke(addr + i, code[i])

func get_warmboot_addr() -> int:
	return 0xF000

func get_char_out_addr() -> int:
	return 0xF020

func get_string_out_addr() -> int:
	return 0xF030

func get_counter_addr() -> int:
	return 0xF040

func get_add_two_addr() -> int:
	return 0xF060

func get_fibonacci_addr() -> int:
	return 0xF080

func get_scroll_addr() -> int:
	return 0xF0C0

func get_hex_out_addr() -> int:
	return 0xF100

func load_demo_program(name: String) -> String:
	var demos: Dictionary = {
		"hello": '10 PRINT "HELLO, WORLD!"\n20 END',
		"counter": '10 FOR I = 1 TO 10\n20 PRINT I\n30 NEXT I\n40 END',
		"fibonacci": '10 A = 0\n20 B = 1\n30 FOR I = 1 TO 15\n40 PRINT A\n50 C = A + B\n60 A = B\n70 B = C\n80 NEXT I\n90 END',
		"guess": '10 N = INT(RND(1) * 100) + 1\n20 G = 0\n30 G = G + 1\n40 INPUT "GUESS? "; G\n50 IF G < N THEN PRINT "TOO LOW" : GOTO 30\n60 IF G > N THEN PRINT "TOO HIGH" : GOTO 30\n70 PRINT "YOU GOT IT IN"; G; "GUESSES!"\n80 END',
		"times": '10 FOR I = 1 TO 9\n20 FOR J = 1 TO 9\n30 IF I * J < 10 THEN PRINT " ";\n40 PRINT I * J; " ";\n50 NEXT J\n60 PRINT ""\n70 NEXT I\n80 END',
		"mandelbrot": '10 FOR Y = -10 TO 10\n20 FOR X = -30 TO 30\n30 R = X / 15\n40 I = Y / 10\n50 ZR = 0 : ZI = 0\n60 FOR K = 0 TO 15\n70 TR = ZR * ZR - ZI * ZI + R\n80 ZI = 2 * ZR * ZI + I\n90 ZR = TR\n100 IF ZR * ZR + ZI * ZI > 4 THEN GOTO 130\n110 NEXT K\n120 PRINT " ";\n125 GOTO 140\n130 IF K < 5 THEN PRINT "#";\n132 IF K >= 5 AND K < 10 THEN PRINT "*";\n134 IF K >= 10 THEN PRINT ".";\n140 NEXT X\n150 PRINT ""\n160 NEXT Y\n170 END',
		"sys_counter": '10 REM 6502 COUNTER AT $F040\n20 SYS 61488\n30 END',
		"sys_fib": '10 REM 6502 FIBONACCI AT $F080\n20 SYS 61568\n30 END',
		"sys_add2": '10 REM 6502 ADD 2 AT $F060\n20 POKE 8192, 5\n30 SYS 61536\n40 PRINT "RESULT: "; PEEK(8192)\n50 END',
		"sys_6502": '10 REM MANUAL 6502 CODE\n20 POKE 768, 169\n30 POKE 769, 65\n40 POKE 770, 141\n50 POKE 771, 0\n60 POKE 772, 4\n70 POKE 773, 96\n80 SYS 768\n90 PRINT PEEK(1024)\n100 END',
	}
	if demos.has(name):
		return demos[name]
	return demos["hello"]

func get_demo_list() -> Array:
	return [
		{"name": "hello", "desc": "Hello World"},
		{"name": "counter", "desc": "Count 1-10"},
		{"name": "fibonacci", "desc": "Fibonacci Sequence"},
		{"name": "guess", "desc": "Number Guessing Game"},
		{"name": "times", "desc": "Multiplication Table"},
		{"name": "mandelbrot", "desc": "ASCII Mandelbrot Set"},
		{"name": "sys_counter", "desc": "6502 Counter ($F040)"},
		{"name": "sys_fib", "desc": "6502 Fibonacci ($F080)"},
		{"name": "sys_add2", "desc": "6502 Add 2 ($F060)"},
		{"name": "sys_6502", "desc": "Manual 6502 Code Demo"},
	]
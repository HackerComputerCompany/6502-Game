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
		"primenums": '5 REM PRIMENUMS - FINDS N PRIMES\n10 IF N < 1 THEN N = 10\n20 PRINT "FIRST "; N; " PRIME NUMBERS:"\n30 C = 0\n40 P = 2\n50 IF C >= N THEN GOTO 150\n60 ISPRIME = 1\n70 I = 2\n80 IF I * I > P THEN GOTO 120\n90 IF P - INT(P / I) * I = 0 THEN ISPRIME = 0 : GOTO 120\n100 I = I + 1\n110 GOTO 80\n120 IF ISPRIME = 1 THEN PRINT P; " "; : C = C + 1\n130 P = P + 1\n140 GOTO 50\n150 PRINT ""\n160 END',
		"pi": '5 REM PI - CALCULATE PI USING N TERMS\n10 IF N < 1 THEN N = 100\n20 PRINT "CALCULATING PI USING"; N; "TERMS"\n30 PRINT "OF THE GREGORY-LEIBNIZ SERIES"\n40 PI = 0\n50 FOR I = 0 TO N - 1\n60 IF I - INT(I / 2) * 2 = 0 THEN PI = PI + 4 / (2 * I + 1)\n70 IF I - INT(I / 2) * 2 <> 0 THEN PI = PI - 4 / (2 * I + 1)\n80 NEXT I\n90 PRINT "PI = "; PI\n100 PRINT "ACTUAL: 3.14159265"\n110 END',
		"sys_counter": '10 REM 6502 COUNTER AT $F040\n20 SYS 61488\n30 END',
		"sys_fib": '10 REM 6502 FIBONACCI AT $F080\n20 SYS 61568\n30 END',
		"sys_add2": '10 REM 6502 ADD 2 AT $F060\n20 POKE 8192, 5\n30 SYS 61536\n40 PRINT "RESULT: "; PEEK(8192)\n50 END',
		"sys_6502": '10 REM MANUAL 6502 CODE\n20 POKE 768, 169\n30 POKE 769, 65\n40 POKE 770, 141\n50 POKE 771, 0\n60 POKE 772, 4\n70 POKE 773, 96\n80 SYS 768\n90 PRINT PEEK(1024)\n100 END',
		"gpu_text": '10 REM GPU TEXT DEMO (PR F12 TO VIEW)\n20 PRINT "GPU TEXT DEMO - PRESS F12"\n30 T$="HELLO FROM BASIC6502!"\n40 FOR I=1 TO LEN(T$)\n50 POKE 57753+I,ASC(MID$(T$,I,1))\n60 POKE 58777+I,10:NEXT\n70 T$="GPU TEXT MODE DEMONSTRATION"\n80 FOR I=1 TO LEN(T$)\n90 POKE 57832+I,ASC(MID$(T$,I,1))\n100 POKE 58856+I,5:NEXT\n110 T$="40 X 25 CHARACTER GRID"\n120 FOR I=1 TO LEN(T$)\n130 POKE 57912+I,ASC(MID$(T$,I,1))\n140 POKE 58936+I,3:NEXT\n150 T$="16 COLORS PER CHARACTER"\n160 FOR I=1 TO LEN(T$)\n170 POKE 57991+I,ASC(MID$(T$,I,1))\n180 POKE 59015+I,14:NEXT\n190 T$="PRESS F12 TO TOGGLE DISPLAY"\n200 FOR I=1 TO LEN(T$)\n210 POKE 58232+I,ASC(MID$(T$,I,1))\n220 POKE 59256+I,8:NEXT\n230 END',
		## GPU PIXEL demo — REG_PIX_COLOR no longer auto-plots; POKE 61439,1 issues CMD_PLOT.
		"gpu_pixels": '10 REM GPU PIXEL DEMO (F12 TO VIEW)\n20 PRINT "GPU PIXEL DEMO - PRESS F12"\n30 POKE 61424,1:REM BITMAP MODE\n40 FOR I=0 TO 4\n50 YY=10+I*25\n60 FOR X=0 TO 159\n70 POKE 61429,X:POKE 61431,YY:POKE 61433,I+1:POKE 61439,1\n80 NEXT X:NEXT I\n90 FOR I=0 TO 119\n100 POKE 61429,I:POKE 61431,I:POKE 61433,14:POKE 61439,1:NEXT\n110 FOR X=20 TO 139\n120 POKE 61429,X:POKE 61431,20:POKE 61433,9:POKE 61439,1\n130 POKE 61429,X:POKE 61431,100:POKE 61433,9:POKE 61439,1:NEXT\n140 FOR Y=20 TO 100\n150 POKE 61429,20:POKE 61431,Y:POKE 61433,9:POKE 61439,1\n160 POKE 61429,139:POKE 61431,Y:POKE 61433,9:POKE 61439,1:NEXT\n170 PRINT "DONE"\n180 END',
		"gpu_sine": '10 REM GPU SINE WAVE (F12 TO VIEW)\n20 PRINT "GPU SINE WAVE - PRESS F12"\n30 POKE 61424,1:REM BITMAP MODE\n40 FOR X=0 TO 159\n50 Y=60+50*SIN(X/25)\n60 POKE 61429,X:POKE 61431,Y:POKE 61433,14:POKE 61439,1:NEXT\n70 PRINT "DONE"\n80 END',
		## GPU DRAW demo — demonstrates HLINE, RECT, RECT_OUT, CIRCLE_FILL, and LINE commands.
		"gpu_draw": '10 REM GPU DRAW SHAPES (F12 TO VIEW)\n20 GRAPHICS\n30 POKE 61424,1:REM BITMAP MODE\n40 REM COLOR BARS USING HLINE\n50 FOR I=0 TO 7\n60 POKE 61433,I:POKE 61431,4+I*8:POKE 61429,0:POKE 61435,159:POKE 61439,5:NEXT I\n70 REM FILLED RECTANGLE\n80 POKE 61429,15:POKE 61431,70:POKE 61433,10:POKE 61435,70:POKE 61437,100:POKE 61439,3\n90 REM RECT OUTLINE\n100 POKE 61433,15:POKE 61439,4\n110 REM FILLED CIRCLE\n120 POKE 61429,120:POKE 61431,85:POKE 61433,13:POKE 61435,22:POKE 61439,8\n130 REM DIAGONAL LINES\n140 POKE 61429,0:POKE 61431,70:POKE 61433,14:POKE 61435,70:POKE 61437,119:POKE 61439,2\n150 POKE 61429,70:POKE 61431,119:POKE 61433,7:POKE 61435,145:POKE 61437,100:POKE 61439,2\n160 PRINT "DONE"\n170 END',
		## GPU OVERLAY demo — text + bitmap layers simultaneously (mode=3).
		"gpu_overlay": '10 REM GPU OVERLAY (F12 TO VIEW)\n20 GRAPHICS\n30 POKE 61424,3:REM TEXT+BITMAP OVERLAY\n40 REM DRAW A BITMAP BACKGROUND\n50 POKE 61433,1:POKE 61431,0:POKE 61429,0:POKE 61435,159:POKE 61439,5\n60 POKE 61433,2:POKE 61431,119:POKE 61439,5\n70 FOR I=0 TO 7\n80 POKE 61429,20+I*15:POKE 61431,60:POKE 61433,I+8:POKE 61435,20+I*15+12:POKE 61437,100:POKE 61439,3:NEXT I\n90 REM TEXT OVERLAYS ON TOP\n100 POKE 57344+0,ASC("O"):POKE 57344+1,ASC("V"):POKE 57344+2,ASC("E"):POKE 57344+3,ASC("R"):POKE 57344+4,ASC("L"):POKE 57344+5,ASC("A"):POKE 57344+6,ASC("Y")\n110 FOR I=0 TO 6:POKE 58368+I,15:NEXT I\n120 POKE 57419,ASC("T"):POKE 57420,ASC("E"):POKE 57421,ASC("X"):POKE 57422,ASC("T"):POKE 57423,ASC("+")
130 POKE 57424,ASC("B"):POKE 57425,ASC("M"):POKE 57426,ASC("P"):POKE 57427,ASC(":"):POKE 57428,ASC(")")\n140 FOR I=0 TO 9:POKE 58443+I,3:NEXT I\n150 PRINT "DONE"\n160 END',
		## GPU BLIT demo — copies a region of the framebuffer.
		"gpu_blit": '10 REM GPU BLIT DEMO (F12 TO VIEW)\n20 GRAPHICS\n30 POKE 61424,1:REM BITMAP MODE\n40 REM DRAW A YELLOW SQUARE AT (10,10)\n50 POKE 61429,10:POKE 61431,10:POKE 61433,14:POKE 61435,30:POKE 61437,30:POKE 61439,3\n60 REM BLIT IT TO THREE NEW POSITIONS\n70 REM BLIT: SOURCE=(10,10), W=20, H=20, DEST=(50,10)\n80 POKE 61429,10:POKE 61431,10:POKE 61435,20:POKE 61437,20\n90 POKE 61427,50:POKE 61439,10\n100 REM BLIT: SOURCE=(10,10), W=20, H=20, DEST=(50,50)\n110 POKE 61427,50:POKE 61428,50:POKE 61439,10\n120 REM BLIT: SOURCE=(10,10), W=20, H=20, DEST=(100,10)\n130 POKE 61427,100:POKE 61428,10:POKE 61439,10\n140 REM BLIT: SOURCE=(10,10), W=20, H=20, DEST=(100,50)\n150 POKE 61427,100:POKE 61428,50:POKE 61439,10\n160 PRINT "BLIT DONE"\n170 END',
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
		{"name": "primenums", "desc": "Prime Numbers (DEMO PRIMENUMS N)"},
		{"name": "pi", "desc": "Calculate Pi (DEMO PI N)"},
		{"name": "sys_counter", "desc": "6502 Counter ($F040)"},
		{"name": "sys_fib", "desc": "6502 Fibonacci ($F080)"},
		{"name": "sys_add2", "desc": "6502 Add 2 ($F060)"},
		{"name": "sys_6502", "desc": "Manual 6502 Code Demo"},
		{"name": "gpu_text", "desc": "GPU Text Mode Demo"},
		{"name": "gpu_pixels", "desc": "GPU Pixel Patterns"},
		{"name": "gpu_sine", "desc": "GPU Sine Wave"},
		{"name": "gpu_draw", "desc": "GPU Draw Shapes Demo"},
		{"name": "gpu_overlay", "desc": "GPU Text+Bitmap Overlay"},
		{"name": "gpu_blit", "desc": "GPU Blit Copy Rect Demo"},
	]

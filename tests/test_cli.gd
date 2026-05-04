extends SceneTree

var _output: String = ""
var _basic: BasicInterpreter
var _computer: Computer
var _tests_passed: int = 0
var _tests_failed: int = 0
var _current_test: String = ""

func _init() -> void:
	var _bw := 58
	var _pad := _bw - 2
	print("╔" + "═".repeat(_bw) + "╗")
	print("║ " + "BASIC6502 CLI Test Environment".rpad(_pad) + " ║")
	print("║ " + "godot --path . --headless -s tests/test_cli.gd".rpad(_pad) + " ║")
	print("║ " + "Optional: same cmd + res:// or user:// path (.bas …)".rpad(_pad) + " ║")
	print("╚" + "═".repeat(_bw) + "╝")
	print("")

	_spawn_default_computer()

	var args = OS.get_cmdline_args()
	var file_arg = ""
	for arg in args:
		if arg.begins_with("res://") or arg.begins_with("user://") or arg.begins_with("/"):
			if arg.ends_with(".bas") or arg.ends_with(".txt") or arg.ends_with(".bin"):
				file_arg = arg
				break
	if file_arg != "":
		_run_file(file_arg)
	else:
		run_tests()

	print("\n========== RESULTS ==========")
	print("  PASSED: %d" % _tests_passed)
	print("  FAILED: %d" % _tests_failed)
	print("  TOTAL:  %d" % (_tests_passed + _tests_failed))
	print("=============================\n")
	_dispose_current_computer()
	quit()

func _on_output(text: String) -> void:
	_output += text

func _on_program_finished() -> void:
	pass


func _dispose_current_computer() -> void:
	if _computer == null:
		return
	for sig_name in [&"output", &"output_richtext", &"ready_for_input", &"program_finished", &"full_reboot_requested"]:
		for conn in _computer.get_signal_connection_list(sig_name):
			var cb: Callable = conn["callable"]
			if cb.is_valid():
				_computer.disconnect(sig_name, cb)
	_computer.disconnect_memory_signal_links()
	_computer = null


func _spawn_default_computer() -> void:
	_dispose_current_computer()
	_computer = Computer.new()
	_computer.output.connect(_on_output)
	_computer.program_finished.connect(_on_program_finished)
	_basic = _computer.basic


func _run_file(filepath: String) -> void:
	if not FileAccess.file_exists(filepath):
		print("ERROR: File not found: %s" % filepath)
		return
	print("Running: %s\n" % filepath)
	var file = FileAccess.open(filepath, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		_computer.run_basic(content)
		if _output != "":
			print(_output.strip_edges())

func _assert(condition: bool, message: String) -> void:
	if condition:
		_tests_passed += 1
	else:
		_tests_failed += 1
		print("  FAIL [%s]: %s" % [_current_test, message])

func _begin_test(name: String) -> void:
	_current_test = name
	_output = ""
	print("Running: %s" % name)

func _run_basic(program: String) -> String:
	_output = ""
	_dispose_current_computer()
	_computer = Computer.new()
	_computer.output.connect(_on_output)
	_basic = _computer.basic
	_basic.load_program(program)
	_basic.run()
	return _output

func run_tests() -> void:
	test_for_loop()
	test_nested_loops()
	test_for_step()
	test_for_reverse()
	test_bsave_bload()
	test_write_readfile()
	test_basic_arithmetic()
	test_basic_if_then()
	test_basic_gosub()
	test_basic_arrays()

func test_for_loop() -> void:
	_begin_test("FOR/NEXT Basic")
	var out = _run_basic("10 FOR I = 1 TO 5\n20 PRINT I\n30 NEXT I\n40 END")
	print("  Output: [%s]" % out.strip_edges().replace("\n", "|"))
	_assert("1" in out, "Starts at 1")
	_assert("5" in out, "Ends at 5")
	var count = 0
	for line in out.split("\n"):
		if line.strip_edges().is_valid_int():
			count += 1
	_assert(count == 5, "Exactly 5 iterations, got %d" % count)

func test_nested_loops() -> void:
	_begin_test("Nested FOR/NEXT")
	var out = _run_basic("10 FOR I = 1 TO 3\n20 FOR J = 1 TO 3\n30 PRINT I; J\n40 NEXT J\n50 NEXT I\n60 END")
	_assert("1" in out and "3" in out, "Nested loop runs")
	var lines = out.split("\n")
	var count = 0
	for line in lines:
		if line.strip_edges() != "":
			count += 1
	_assert(count == 9, "3x3 = 9 lines, got %d" % count)

func test_for_step() -> void:
	_begin_test("FOR STEP")
	var out = _run_basic("10 FOR I = 0 TO 10 STEP 2\n20 PRINT I\n30 NEXT I\n40 END")
	_assert("0" in out, "Starts at 0")
	_assert("10" in out, "Reaches 10")
	_assert("2" in out, "Prints 2")
	var count = 0
	for line in out.split("\n"):
		var val = line.strip_edges()
		if val.is_valid_int() and int(val) % 2 == 0:
			count += 1
	_assert(count == 6, "6 even values 0-10, got %d" % count)

func test_for_reverse() -> void:
	_begin_test("FOR Reverse Step")
	var out = _run_basic("10 FOR I = 5 TO 1 STEP -1\n20 PRINT I\n30 NEXT I\n40 END")
	_assert("5" in out, "Starts at 5")
	_assert("1" in out, "Reaches 1")

func test_bsave_bload() -> void:
	_begin_test("BSAVE/BLOAD Binary")
	_output = ""
	_dispose_current_computer()
	_computer = Computer.new()
	_computer.output.connect(_on_output)
	_basic = _computer.basic
	var mem = _basic._memory
	mem.poke(0x1000, 0xDE)
	mem.poke(0x1001, 0xAD)
	mem.poke(0x1002, 0xBE)
	mem.poke(0x1003, 0xEF)
	_basic.load_program('10 BSAVE "test.bin", 4096, 4\n20 END')
	_basic.run()
	_assert("SAVED 4 BYTES" in _output, "BSAVE saves 4 bytes")
	if FileAccess.file_exists("user://test.bin"):
		var file = FileAccess.open("user://test.bin", FileAccess.READ)
		_assert(file != null, "Binary file exists")
		if file:
			var lo = file.get_8()
			var hi = file.get_8()
			var saved_addr = lo | (hi << 8)
			_assert(saved_addr == 0x1000, "Header has load addr 0x1000")
			_assert(file.get_8() == 0xDE, "Byte 0 = 0xDE")
			_assert(file.get_8() == 0xAD, "Byte 1 = 0xAD")
			_assert(file.get_8() == 0xBE, "Byte 2 = 0xBE")
			_assert(file.get_8() == 0xEF, "Byte 3 = 0xEF")
			file.close()
			_run_basic('10 BLOAD "test.bin", $2000\n20 PRINT PEEK($2000)\n30 PRINT PEEK($2003)\n40 END')
			_assert("222" in _output, "BLOAD byte 0 = 0xDE (222)")
			_assert("239" in _output, "BLOAD byte 3 = 0xEF (239)")
	else:
		print("  [SKIP] Cannot verify BLOAD")

func test_write_readfile() -> void:
	_begin_test("WRITE/READFILE Text")
	_run_basic('10 WRITE "test.txt", "HELLO FROM BASIC"\n20 END')
	_assert("WRITTEN" in _output, "WRITE creates text file")
	if FileAccess.file_exists("user://test.txt"):
		var file = FileAccess.open("user://test.txt", FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			_assert(content == "HELLO FROM BASIC", "Content correct: %s" % content)
		_run_basic('10 READFILE "test.txt", MSG$\n20 PRINT MSG$\n30 END')
		_assert("HELLO FROM BASIC" in _output, "READFILE loads into variable")
	else:
		print("  [SKIP] Cannot verify READFILE")

func test_basic_arithmetic() -> void:
	_begin_test("BASIC Arithmetic")
	var out = _run_basic("10 PRINT 2 + 3 * 4\n20 PRINT (2 + 3) * 4\n30 END")
	_assert("14" in out, "Operator precedence: 2+3*4=14")

func test_basic_if_then() -> void:
	_begin_test("BASIC IF/THEN")
	var out = _run_basic('10 IF 5 > 3 THEN PRINT "YES"\n20 IF 1 < 2 THEN PRINT "TRUE"\n30 END')
	_assert("YES" in out, "IF true condition")
	_assert("TRUE" in out, "IF with comparison")

func test_basic_gosub() -> void:
	_begin_test("BASIC GOSUB/RETURN")
	var out = _run_basic("10 GOSUB 100\n20 PRINT \"BACK\"\n30 END\n100 PRINT \"SUB\"\n110 RETURN")
	_assert("SUB" in out, "GOSUB calls subroutine")
	_assert("BACK" in out, "RETURN goes back")

func test_basic_arrays() -> void:
	_begin_test("BASIC Arrays")
	var out = _run_basic("10 DIM A(5)\n20 FOR I = 0 TO 5\n30 A(I) = I * 10\n40 NEXT I\n50 PRINT A(3)\n60 END")
	_assert("30" in out, "Array A(3)=30")

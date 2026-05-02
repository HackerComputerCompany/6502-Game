extends SceneTree

var _tests_passed: int = 0
var _tests_failed: int = 0
var _current_test: String = ""

func _init() -> void:
	print("\n========== BASIC6502 REGRESSION TEST SUITE ==========\n")
	test_memory_bus()
	test_memory_io()
	test_memory_reset_vectors()
	test_cpu_load_store()
	test_cpu_arithmetic()
	test_cpu_logical()
	test_cpu_shifts()
	test_cpu_comparisons()
	test_cpu_branches()
	test_cpu_stack()
	test_cpu_jumps()
	test_cpu_flags()
	test_cpu_edge_cases()
	test_cpu_multi_instruction()
	test_cpu_overflow()
	test_cpu_nop_brk()
	test_cpu_addressing_modes()
	test_cpu_transfers()
	test_cpu_indirect_jmp()
	test_cpu_page_boundary_bug()
	test_cpu_bit()
	test_cpu_inx_iny_dex_dey()
	test_basic_print()
	test_basic_variables()
	test_basic_arithmetic()
	test_basic_conditions()
	test_basic_loops()
	test_basic_gosub()
	test_basic_functions()
	test_basic_strings()
	test_basic_arrays()
	test_basic_read_data()
	test_basic_poke_peek()
	test_basic_nested_for()
	test_basic_comparison_operators()
	test_basic_boolean_logic()
	test_basic_trig_functions()
	test_basic_computed_gosub()
	test_computer_integration()
	print("\n========== TEST RESULTS ==========")
	print("  PASSED: %d" % _tests_passed)
	print("  FAILED: %d" % _tests_failed)
	print("  TOTAL:  %d" % (_tests_passed + _tests_failed))
	print("===================================\n")
	quit()

func _assert(condition: bool, message: String) -> void:
	if condition:
		_tests_passed += 1
	else:
		_tests_failed += 1
		print("  FAIL [%s]: %s" % [_current_test, message])

func _begin_test(name: String) -> void:
	_current_test = name
	print("Running: %s" % name)

func test_memory_bus() -> void:
	_begin_test("MemoryBus")
	var mem = MemoryBus.new()
	mem.poke(0x0000, 0x42)
	_assert(mem.peek(0x0000) == 0x42, "peek/poke basic")
	mem.poke_word(0x0100, 0x1234)
	_assert(mem.peek_word(0x0100) == 0x1234, "peek_word/poke_word")
	_assert(mem.peek(0x0100) == 0x34, "poke_word low byte")
	_assert(mem.peek(0x0101) == 0x12, "poke_word high byte")
	mem.poke(0xFFFF, 0xAB)
	_assert(mem.peek(0xFFFF) == 0xAB, "highest address")
	mem.poke(0x10000, 0xFF)
	_assert(mem.peek(0x0000) == 0xFF, "overflow wraps to 16-bit")
	mem.reset()
	_assert(mem.peek(0x0000) == 0x00, "reset clears memory")
	var data = PackedByteArray([0x01, 0x02, 0x03, 0x04])
	mem.load_bytes(data, 0x0200)
	_assert(mem.peek(0x0200) == 0x01, "load_bytes byte 0")
	_assert(mem.peek(0x0203) == 0x04, "load_bytes byte 3")

func test_memory_io() -> void:
	_begin_test("MemoryBus I/O")
	var mem = MemoryBus.new()
	var output_chars: String = ""
	var on_char = func(ch: String): output_chars += ch
	mem.char_output.connect(on_char)
	mem.poke(0xC002, 0x41)
	_assert(output_chars == "A", "screen output char A")
	mem.poke(0xC002, 0x0D)
	mem.poke(0xC002, 0x42)
	_assert(output_chars == "AB", "screen output char B after newline control")
	mem.push_input("Hi")
	_assert(mem.peek(0xC001) == 1, "keyboard status has data")
	var ch = mem.peek(0xC000)
	_assert(ch == ord("H"), "keyboard read H")
	ch = mem.peek(0xC000)
	_assert(ch == ord("i"), "keyboard read i")
	mem.clear_input()
	_assert(mem.peek(0xC001) == 0, "keyboard status empty after read all")

func test_cpu_load_store() -> void:
	_begin_test("CPU Load/Store")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	mem.poke_word(0xFFFC, 0x00)
	mem.poke_word(0xFFFE, 0x00)
	mem.poke(0x0800, 0xA9)
	mem.poke(0x0801, 0x42)
	cpu.step()
	_assert(cpu.A == 0x42, "LDA immediate")
	_assert(cpu.get_flag(CPU6502.Flag.Z) == false, "LDA immediate Z flag")
	_assert(cpu.get_flag(CPU6502.Flag.N) == false, "LDA immediate N flag")
	cpu.PC = 0x0810
	mem.poke(0x0810, 0xA2)
	mem.poke(0x0811, 0xFF)
	cpu.step()
	_assert(cpu.X == 0xFF, "LDX immediate")
	_assert(cpu.get_flag(CPU6502.Flag.N) == true, "LDX immediate N flag")
	cpu.PC = 0x0820
	mem.poke(0x0820, 0xA0)
	mem.poke(0x0821, 0x00)
	cpu.step()
	_assert(cpu.Y == 0x00, "LDY immediate")
	_assert(cpu.get_flag(CPU6502.Flag.Z) == true, "LDY immediate Z flag")
	cpu.PC = 0x0830
	mem.poke(0x0830, 0x85)
	mem.poke(0x0831, 0x10)
	cpu.step()
	_assert(mem.peek(0x0010) == 0x42, "STA zero page")
	cpu.PC = 0x0840
	mem.poke(0x0840, 0xA5)
	mem.poke(0x0841, 0x10)
	cpu.step()
	_assert(cpu.A == 0x42, "LDA zero page from STA result")

func test_cpu_arithmetic() -> void:
	_begin_test("CPU Arithmetic")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x10
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0800, 0x69)
	mem.poke(0x0801, 0x20)
	cpu.step()
	_assert(cpu.A == 0x30, "ADC immediate 0x10 + 0x20")
	cpu.PC = 0x0810
	cpu.A = 0xFF
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0810, 0x69)
	mem.poke(0x0811, 0x01)
	cpu.step()
	_assert(cpu.A == 0x00, "ADC immediate 0xFF + 0x01 overflow")
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "ADC carry set on overflow")
	cpu.PC = 0x0820
	cpu.A = 0x50
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0820, 0xE9)
	mem.poke(0x0821, 0x10)
	cpu.step()
	_assert(cpu.A == 0x40, "SBC immediate 0x50 - 0x10")
	cpu.PC = 0x0830
	cpu.A = 0x05
	cpu.set_flag(CPU6502.Flag.C, true)
	mem.poke(0x0830, 0x69)
	mem.poke(0x0831, 0x03)
	cpu.step()
	_assert(cpu.A == 0x09, "ADC with carry 0x05 + 0x03 + 1")

func test_cpu_logical() -> void:
	_begin_test("CPU Logical")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0xFF
	mem.poke(0x0800, 0x29)
	mem.poke(0x0801, 0x0F)
	cpu.step()
	_assert(cpu.A == 0x0F, "AND immediate")
	cpu.PC = 0x0810
	cpu.A = 0xF0
	mem.poke(0x0810, 0x09)
	mem.poke(0x0811, 0x0F)
	cpu.step()
	_assert(cpu.A == 0xFF, "ORA immediate")
	cpu.PC = 0x0820
	cpu.A = 0xFF
	mem.poke(0x0820, 0x49)
	mem.poke(0x0821, 0xFF)
	cpu.step()
	_assert(cpu.A == 0x00, "EOR immediate")
	_assert(cpu.get_flag(CPU6502.Flag.Z) == true, "EOR result zero flag")

func test_cpu_shifts() -> void:
	_begin_test("CPU Shift/Rotate")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x81
	mem.poke(0x0800, 0x0A)
	cpu.step()
	_assert(cpu.A == 0x02, "ASL accumulator")
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "ASL carry")
	cpu.PC = 0x0810
	cpu.A = 0x01
	mem.poke(0x0810, 0x4A)
	cpu.step()
	_assert(cpu.A == 0x00, "LSR accumulator")
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "LSR carry")
	cpu.PC = 0x0820
	cpu.A = 0x01
	cpu.set_flag(CPU6502.Flag.C, true)
	mem.poke(0x0820, 0x2A)
	cpu.step()
	_assert(cpu.A == 0x81, "ROL accumulator with carry in")
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "ROL carry out")
	cpu.PC = 0x0830
	cpu.A = 0x80
	cpu.set_flag(CPU6502.Flag.C, true)
	mem.poke(0x0830, 0x6A)
	cpu.step()
	_assert(cpu.A == 0xC0, "ROR accumulator")
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "ROR carry")
	mem.poke(0x0050, 0x10)
	cpu.PC = 0x0840
	mem.poke(0x0840, 0xE6)
	mem.poke(0x0841, 0x50)
	cpu.step()
	_assert(mem.peek(0x0050) == 0x11, "INC zero page")
	cpu.PC = 0x0850
	mem.poke(0x0850, 0xC6)
	mem.poke(0x0851, 0x50)
	cpu.step()
	_assert(mem.peek(0x0050) == 0x10, "DEC zero page")

func test_cpu_comparisons() -> void:
	_begin_test("CPU Comparisons")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x50
	mem.poke(0x0800, 0xC9)
	mem.poke(0x0801, 0x50)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.Z) == true, "CMP equal Z")
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "CMP equal C")
	_assert(cpu.get_flag(CPU6502.Flag.N) == false, "CMP equal N")
	cpu.PC = 0x0810
	cpu.A = 0x50
	mem.poke(0x0810, 0xC9)
	mem.poke(0x0811, 0x20)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.Z) == false, "CMP greater Z")
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "CMP greater C")
	cpu.PC = 0x0820
	cpu.A = 0x10
	mem.poke(0x0820, 0xC9)
	mem.poke(0x0821, 0x20)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.C) == false, "CMP less C")
	_assert(cpu.get_flag(CPU6502.Flag.N) == true, "CMP less N")

func test_cpu_branches() -> void:
	_begin_test("CPU Branches")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.set_flag(CPU6502.Flag.Z, true)
	mem.poke(0x0800, 0xF0)
	mem.poke(0x0801, 0x10)
	cpu.step()
	_assert(cpu.PC == 0x0812, "BEQ branch taken")
	cpu.PC = 0x0800
	cpu.set_flag(CPU6502.Flag.Z, false)
	mem.poke(0x0800, 0xF0)
	mem.poke(0x0801, 0x10)
	cpu.step()
	_assert(cpu.PC == 0x0802, "BEQ branch not taken")
	cpu.PC = 0x0800
	cpu.set_flag(CPU6502.Flag.C, true)
	mem.poke(0x0800, 0xB0)
	mem.poke(0x0801, 0x05)
	cpu.step()
	_assert(cpu.PC == 0x0807, "BCS branch taken")
	cpu.PC = 0x0810
	cpu.set_flag(CPU6502.Flag.N, true)
	mem.poke(0x0810, 0x30)
	mem.poke(0x0811, 0x7E)
	cpu.step()
	_assert(cpu.PC == 0x0790, "BMI branch backward (negative offset)")

func test_cpu_stack() -> void:
	_begin_test("CPU Stack")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x42
	mem.poke(0x0800, 0x48)
	cpu.step()
	_assert(mem.peek(0x01FF) == 0x42, "PHA push to stack")
	_assert(cpu.SP == 0xFC, "PHA SP decremented")
	cpu.PC = 0x0810
	mem.poke(0x0810, 0x68)
	cpu.A = 0x00
	cpu.step()
	_assert(cpu.A == 0x42, "PLA pull from stack")
	_assert(cpu.SP == 0xFD, "PLA SP incremented")

func test_cpu_jumps() -> void:
	_begin_test("CPU Jumps/Subroutines")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	mem.poke(0x0800, 0x4C)
	mem.poke_word(0x0801, 0x1234)
	cpu.step()
	_assert(cpu.PC == 0x1234, "JMP absolute")
	cpu.PC = 0x0900
	cpu.SP = 0xFD
	mem.poke(0x0900, 0x20)
	mem.poke_word(0x0901, 0x1000)
	cpu.step()
	_assert(cpu.PC == 0x1000, "JSR sets PC")
	_assert(mem.peek_word(0x01FE) == 0x0902, "JSR pushes return address")
	cpu.PC = 0x1000
	mem.poke(0x1000, 0x60)
	cpu.step()
	_assert(cpu.PC == 0x0903, "RTS returns to correct address")

func test_cpu_flags() -> void:
	_begin_test("CPU Flag Instructions")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.set_flag(CPU6502.Flag.C, true)
	mem.poke(0x0800, 0x18)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.C) == false, "CLC clears carry")
	cpu.PC = 0x0810
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0810, 0x38)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "SEC sets carry")
	cpu.PC = 0x0820
	cpu.set_flag(CPU6502.Flag.I, true)
	mem.poke(0x0820, 0x58)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.I) == false, "CLI clears interrupt")
	cpu.PC = 0x0830
	cpu.set_flag(CPU6502.Flag.V, true)
	mem.poke(0x0830, 0xB8)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.V) == false, "CLV clears overflow")

func test_cpu_edge_cases() -> void:
	_begin_test("CPU Edge Cases")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.X = 0x05
	mem.poke(0x08, 0x42)
	cpu.PC = 0x0800
	mem.poke(0x0800, 0xB5)
	mem.poke(0x0801, 0x03)
	cpu.A = 0x00
	cpu.step()
	_assert(cpu.A == 0x42, "LDA zero page X indexed")
	cpu.PC = 0x0810
	cpu.Y = 0x03
	mem.poke(0x09, 0x80)
	mem.poke(0x08, 0x00)
	mem.poke(0x1000, 0x99)
	mem.poke_word(0x0008, 0x1000 - 3)
	cpu.A = 0x77
	mem.poke(0x0810, 0x99)
	mem.poke_word(0x0811, 0x1000)
	cpu.Y = 0x03
	cpu.step()
	_assert(mem.peek(0x1003) == 0x77, "STA absolute Y indexed")
	cpu.PC = 0x0820
	cpu.A = 0x50
	cpu.X = 0x50
	mem.poke(0x0820, 0xE8)
	cpu.step()
	_assert(cpu.X == 0x51, "INX")
	cpu.PC = 0x0830
	mem.poke(0x0830, 0xE8)
	cpu.step()
	_assert(cpu.X == 0x52, "INX again")
	cpu.PC = 0x0840
	mem.poke(0x0840, 0xCA)
	cpu.step()
	_assert(cpu.X == 0x51, "DEX")

func test_basic_print() -> void:
	_begin_test("BASIC PRINT")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 PRINT \"HELLO WORLD\"\n20 PRINT 42\n30 PRINT 1+2\n40 END")
	basic.run()
	_assert("HELLO WORLD" in output, "PRINT string literal")
	_assert("42" in output, "PRINT number")
	_assert("3" in output, "PRINT expression")

func test_basic_variables() -> void:
	_begin_test("BASIC Variables")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 LET A = 42\n20 LET B = A + 8\n30 PRINT B\n40 END")
	basic.run()
	_assert("50" in output, "LET and variable arithmetic")
	basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 A = 100\n20 A = A - 1\n30 PRINT A\n40 END")
	basic.run()
	_assert("99" in output, "Variable reassignment")

func test_basic_arithmetic() -> void:
	_begin_test("BASIC Arithmetic")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 PRINT 2 + 3 * 4\n20 PRINT (2 + 3) * 4\n30 PRINT 10 / 2\n40 PRINT 2 ^ 8\n50 END")
	basic.run()
	_assert("14" in output, "Operator precedence: 2+3*4=14")
	_assert("20" in output, "Parenthesized: (2+3)*4=20")
	_assert("5" in output, "Division: 10/2=5")
	_assert("256" in output, "Power: 2^8=256")

func test_basic_conditions() -> void:
	_begin_test("BASIC IF/THEN")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 IF 5 > 3 THEN PRINT \"YES\"\n20 IF 2 = 2 THEN PRINT \"EQUAL\"\n30 IF 1 < 0 THEN PRINT \"NO\"\n40 END")
	basic.run()
	_assert("YES" in output, "IF true condition")
	_assert("EQUAL" in output, "IF equal condition")
	_assert(not ("NO" in output), "IF false condition not executed")

func test_basic_loops() -> void:
	_begin_test("BASIC FOR/NEXT")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 FOR I = 1 TO 5\n20 PRINT I\n30 NEXT I\n40 END")
	basic.run()
	_assert("1" in output and "5" in output, "FOR loop 1 to 5")
	basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 FOR I = 10 TO 1 STEP -1\n20 PRINT I\n30 NEXT I\n40 END")
	basic.run()
	_assert("10" in output, "FOR loop with negative step")

func test_basic_gosub() -> void:
	_begin_test("BASIC GOSUB/RETURN")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 GOSUB 100\n20 PRINT \"BACK\"\n30 END\n100 PRINT \"SUB\"\n110 RETURN")
	basic.run()
	_assert("SUB" in output, "GOSUB calls subroutine")
	_assert("BACK" in output, "RETURN goes back")

func test_basic_functions() -> void:
	_begin_test("BASIC Built-in Functions")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 PRINT INT(3.7)\n20 PRINT ABS(-5)\n30 PRINT SQR(16)\n40 PRINT SGN(-10)\n50 END")
	basic.run()
	_assert("3" in output, "INT(3.7)=3")
	_assert("5" in output, "ABS(-5)=5")
	_assert("4" in output, "SQR(16)=4")

func test_basic_strings() -> void:
	_begin_test("BASIC String Functions")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program('10 A$ = "HELLO"\n20 PRINT LEFT$(A$, 3)\n30 PRINT RIGHT$(A$, 3)\n40 PRINT MID$(A$, 2, 3)\n50 PRINT LEN(A$)\n60 END')
	basic.run()
	_assert("HEL" in output, "LEFT$()")
	_assert("LLO" in output, "RIGHT$()")
	_assert("ELL" in output, "MID$()")
	_assert("5" in output, "LEN()")

func test_basic_arrays() -> void:
	_begin_test("BASIC Arrays")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 DIM A(5)\n20 FOR I = 0 TO 5\n30 A(I) = I * 10\n40 NEXT I\n50 PRINT A(3)\n60 END")
	basic.run()
	_assert("30" in output, "Array subscript A(3)=30")

func test_basic_read_data() -> void:
	_begin_test("BASIC READ/DATA")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 READ A, B, C\n20 PRINT A; B; C\n30 DATA 10, 20, 30\n40 END")
	basic.run()
	_assert("10" in output, "READ first value")
	_assert("20" in output, "READ second value")
	_assert("30" in output, "READ third value")

func test_basic_poke_peek() -> void:
	_begin_test("BASIC POKE/PEEK")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 POKE 1000, 42\n20 PRINT PEEK(1000)\n30 END")
	basic.run()
	_assert("42" in output, "POKE then PEEK roundtrip")

func test_cpu_multi_instruction() -> void:
	_begin_test("CPU Multi-Instruction Program")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	mem.poke(0x0800, 0xA9)
	mem.poke(0x0801, 0x05)
	mem.poke(0x0802, 0xA2)
	mem.poke(0x0803, 0x03)
	mem.poke(0x0804, 0x8A)
	mem.poke(0x0805, 0xA2)
	mem.poke(0x0806, 0x0A)
	mem.poke(0x0807, 0x18)
	mem.poke(0x0808, 0x6D)
	mem.poke(0x0809, 0x00)
	mem.poke(0x080A, 0x20)
	mem.poke(0x2000, 0x0A)
	cpu.PC = 0x0800
	cpu.run(20)
	_assert(cpu.A == 0x0F, "A=5, X=3, TXA, LDX #10, CLC, ADC $2000 => A=0x0F")
	_assert(cpu.X == 0x0A, "X should be 10")

func test_cpu_overflow() -> void:
	_begin_test("CPU Overflow Detection")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x7F
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0800, 0x69)
	mem.poke(0x0801, 0x01)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.V) == true, "ADC overflow: 0x7F + 0x01")
	cpu.PC = 0x0810
	cpu.A = 0x80
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0810, 0xE9)
	mem.poke(0x0811, 0x01)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.V) == true, "SBC overflow: 0x80 - 0x01")

func test_cpu_nop_brk() -> void:
	_begin_test("CPU NOP/BRK")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	mem.poke(0x0800, 0xEA)
	var start_pc = cpu.PC
	cpu.step()
	_assert(cpu.PC == start_pc + 1, "NOP increments PC by 1")
	cpu.PC = 0x0810
	cpu.SP = 0xFD
	mem.poke(0x0810, 0x00)
	mem.poke_word(0xFFFE, 0x9000)
	cpu.step()
	_assert(cpu.PC == 0x9000, "BRK jumps to IRQ vector")
	_assert(cpu.get_flag(CPU6502.Flag.I) == true, "BRK sets interrupt flag")

func test_computer_integration() -> void:
	_begin_test("Computer Integration")
	var output_acculated: String = ""
	var comp_output = func(text: String): output_acculated += text
	var computer = Computer.new()
	computer.output.connect(comp_output)
	computer.run_basic("10 PRINT \"HELLO FROM BASIC6502\"\n20 FOR I = 1 TO 3\n30 PRINT I * I\n40 NEXT I\n50 END")
	_assert("HELLO FROM BASIC6502" in output_acculated, "Computer prints greeting")
	_assert("1" in output_acculated, "Computer prints 1*1")
	_assert("4" in output_acculated, "Computer prints 2*2")
	_assert("9" in output_acculated, "Computer prints 3*3")
	var output2: String = ""
	var comp_output2 = func(text: String): output2 += text
	var computer2 = Computer.new()
	computer2.output.connect(comp_output2)
	computer2.run_basic("10 A = 100\n20 B = 200\n30 IF A < B THEN PRINT \"A IS LESS\"\n40 IF A > B THEN PRINT \"B IS LESS\"\n50 END")
	_assert("A IS LESS" in output2, "Computer conditional A<B")
	_assert(not ("B IS LESS" in output2), "Computer conditional not A>B")

func test_cpu_addressing_modes() -> void:
	_begin_test("CPU Addressing Modes")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	mem.poke(0x0050, 0xAA)
	cpu.PC = 0x0800
	cpu.A = 0x00
	mem.poke(0x0800, 0xA5)
	mem.poke(0x0801, 0x50)
	cpu.step()
	_assert(cpu.A == 0xAA, "LDA zero page")
	cpu.PC = 0x0810
	cpu.A = 0x00
	cpu.X = 0x02
	mem.poke(0x0052, 0xBB)
	mem.poke(0x0810, 0xB5)
	mem.poke(0x0811, 0x50)
	cpu.step()
	_assert(cpu.A == 0xBB, "LDA zero page X")
	cpu.PC = 0x0820
	cpu.A = 0xCC
	mem.poke(0x0820, 0x8D)
	mem.poke_word(0x0821, 0x3000)
	cpu.step()
	_assert(mem.peek(0x3000) == 0xCC, "STA absolute")
	cpu.PC = 0x0830
	cpu.A = 0x00
	cpu.Y = 0x03
	mem.poke(0x3003, 0xDD)
	mem.poke(0x0830, 0xB9)
	mem.poke_word(0x0831, 0x3000)
	cpu.step()
	_assert(cpu.A == 0xDD, "LDA absolute Y")
	cpu.PC = 0x0840
	cpu.A = 0x00
	cpu.X = 0x04
	cpu.Y = 0x02
	mem.poke(0x0060, 0x00)
	mem.poke(0x0061, 0x30)
	mem.poke(0x3006, 0xEE)
	mem.poke(0x0840, 0xA1)
	mem.poke(0x0841, 0x5C)
	cpu.step()
	_assert(cpu.A == 0xEE, "LDA indirect X")
	cpu.PC = 0x0850
	cpu.A = 0xFF
	cpu.Y = 0x02
	mem.poke(0x0064, 0x00)
	mem.poke(0x0065, 0x30)
	mem.poke(0x0850, 0x91)
	mem.poke(0x0851, 0x64)
	cpu.step()
	_assert(mem.peek(0x3002) == 0xFF, "STA indirect Y")

func test_cpu_transfers() -> void:
	_begin_test("CPU Transfer Instructions")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x42
	mem.poke(0x0800, 0xAA)
	cpu.step()
	_assert(cpu.X == 0x42, "TAX transfers A to X")
	cpu.PC = 0x0810
	mem.poke(0x0810, 0x8A)
	cpu.A = 0x00
	cpu.step()
	_assert(cpu.A == 0x42, "TXA transfers X to A")
	cpu.PC = 0x0820
	cpu.A = 0x55
	mem.poke(0x0820, 0xA8)
	cpu.step()
	_assert(cpu.Y == 0x55, "TAY transfers A to Y")
	cpu.PC = 0x0830
	mem.poke(0x0830, 0x98)
	cpu.A = 0x00
	cpu.step()
	_assert(cpu.A == 0x55, "TYA transfers Y to A")

func test_cpu_indirect_jmp() -> void:
	_begin_test("CPU Indirect JMP")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	mem.poke(0x0800, 0x6C)
	mem.poke(0x0801, 0x00)
	mem.poke(0x0802, 0x30)
	mem.poke_word(0x3000, 0xABCD)
	cpu.step()
	_assert(cpu.PC == 0xABCD, "JMP indirect")

func test_cpu_page_boundary_bug() -> void:
	_begin_test("CPU 6502 Page Boundary Bug (Indirect)")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	mem.poke(0x0800, 0x6C)
	mem.poke(0x0801, 0xFF)
	mem.poke(0x0802, 0x01)
	mem.poke(0x01FF, 0x34)
	mem.poke(0x0100, 0x12)
	mem.poke(0x0200, 0x78)
	cpu.step()
	_assert(cpu.PC == 0x1234, "JMP indirect page boundary bug: wraps low byte")

func test_cpu_bit() -> void:
	_begin_test("CPU BIT Instruction")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x0F
	mem.poke(0x0050, 0xF0)
	mem.poke(0x0800, 0x24)
	mem.poke(0x0801, 0x50)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.Z) == true, "BIT zero result")
	_assert(cpu.get_flag(CPU6502.Flag.N) == true, "BIT negative from memory bit 7")
	_assert(cpu.get_flag(CPU6502.Flag.V) == true, "BIT overflow from memory bit 6")

func test_basic_nested_for() -> void:
	_begin_test("BASIC Nested FOR Loops")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 FOR I = 1 TO 3\n20 FOR J = 1 TO 2\n30 PRINT I * 10 + J\n40 NEXT J\n50 NEXT I\n60 END")
	basic.run()
	_assert("11" in output, "Nested FOR I=1,J=1")
	_assert("12" in output, "Nested FOR I=1,J=2")
	_assert("21" in output, "Nested FOR I=2,J=1")
	_assert("32" in output, "Nested FOR I=3,J=2")

func test_basic_comparison_operators() -> void:
	_begin_test("BASIC Comparison Operators")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 IF 5 <= 5 THEN PRINT \"LTE YES\"\n20 IF 5 >= 5 THEN PRINT \"GTE YES\"\n30 IF 5 <> 3 THEN PRINT \"NEQ YES\"\n40 IF 5 <> 5 THEN PRINT \"NEQ NO\"\n50 END")
	basic.run()
	_assert("LTE YES" in output, "<= operator")
	_assert("GTE YES" in output, ">= operator")
	_assert("NEQ YES" in output, "<> operator true")
	_assert(not ("NEQ NO" in output), "<> operator false")

func test_basic_boolean_logic() -> void:
	_begin_test("BASIC Boolean Logic")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 IF 1 AND 1 THEN PRINT \"AND YES\"\n20 IF 1 AND 0 THEN PRINT \"AND NO\"\n30 IF 0 OR 1 THEN PRINT \"OR YES\"\n40 IF NOT 0 THEN PRINT \"NOT YES\"\n50 END")
	basic.run()
	_assert("AND YES" in output, "AND operator")
	_assert(not ("AND NO" in output), "AND operator false")
	_assert("OR YES" in output, "OR operator")
	_assert("NOT YES" in output, "NOT operator")

func test_basic_trig_functions() -> void:
	_begin_test("BASIC Trig Functions")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 PRINT INT(SIN(0) * 100)\n20 PRINT INT(COS(0) * 100)\n30 END")
	basic.run()
	_assert("0" in output, "SIN(0) ≈ 0")
	_assert("100" in output, "COS(0) ≈ 1")

func test_memory_reset_vectors() -> void:
	_begin_test("Memory Reset Vectors")
	var mem = MemoryBus.new()
	_assert(mem.peek(0xFFFC) == 0x00, "Reset vector low byte default")
	_assert(mem.peek(0xFFFD) == 0x08, "Reset vector high byte default")
	_assert(mem.peek(0xFFFE) == 0x00, "IRQ vector low byte default")
	_assert(mem.peek(0xFFFF) == 0x08, "IRQ vector high byte default")

func test_basic_computed_gosub() -> void:
	_begin_test("BASIC ON GOSUB")
	var output: String = ""
	var on_output = func(text: String): output += text
	var mem = MemoryBus.new()
	var basic = BasicInterpreter.new(mem, on_output, func(_p): return [""])
	basic.load_program("10 ON 2 GOTO 100, 200, 300\n20 PRINT \"SKIP\"\n30 END\n100 PRINT \"ONE\"\n110 GOTO 30\n200 PRINT \"TWO\"\n210 GOTO 30")
	basic.run()
	_assert("TWO" in output, "ON GOTO branching")

func test_cpu_inx_iny_dex_dey() -> void:
	_begin_test("CPU INX/INY/DEX/DEY")
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.Y = 0x0F
	mem.poke(0x0800, 0xC8)
	cpu.step()
	_assert(cpu.Y == 0x10, "INY increment")
	cpu.PC = 0x0810
	cpu.Y = 0xFF
	mem.poke(0x0810, 0xC8)
	cpu.step()
	_assert(cpu.Y == 0x00, "INY overflow")
	_assert(cpu.get_flag(CPU6502.Flag.Z) == true, "INY overflow zero flag")
	cpu.PC = 0x0820
	cpu.Y = 0x00
	mem.poke(0x0820, 0x88)
	cpu.step()
	_assert(cpu.Y == 0xFF, "DEY underflow")
	_assert(cpu.get_flag(CPU6502.Flag.N) == true, "DEY underflow negative flag")
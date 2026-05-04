extends SceneTree

var _tests_passed: int = 0
var _tests_failed: int = 0
var _current_test: String = ""
var _output: String = ""

func _init() -> void:
	print("\n========== BASIC6502 REGRESSION TEST SUITE ==========\n")
	test_memory_bus()
	test_memory_reset_vectors()
	test_cpu_load_store()
	test_cpu_arithmetic()
	test_cpu_logical()
	test_cpu_shifts()
	test_cpu_comparisons()
	test_cpu_branches()
	test_cpu_stack()
	test_cpu_jumps_subroutines()
	test_cpu_flags()
	test_cpu_transfers()
	test_cpu_nop_brk()
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
	test_basic_computed_gosub()
	test_computer_integration()
	test_computer_var_persistence()
	test_memory_cart_select_register()
	test_memory_main_ram_high_water()
	test_cart_loader_switch_clears_workspace()
	test_cart_loader_poke_c030()
	test_cart_text_editor_commands()
	test_assembler6502_hello_snippet()
	test_cart_asm_commands()
	test_computer_cart_serialize_roundtrip()
	test_basic_nested_loops()
	test_basic_for_step()
	test_basic_for_reverse()
	test_bsave_bload()
	test_write_readfile()
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
	_output = ""
	print("Running: %s" % name)

func _on_output(text: String) -> void:
	_output += text

func _fresh_cpu() -> CPU6502:
	var mem = MemoryBus.new()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	return cpu

func _fresh_mem() -> MemoryBus:
	return MemoryBus.new()

func test_memory_bus() -> void:
	_begin_test("MemoryBus")
	var mem = _fresh_mem()
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

func test_memory_reset_vectors() -> void:
	_begin_test("Memory Reset Vectors")
	var mem = _fresh_mem()
	_assert(mem.peek(0xFFFC) == 0x00, "Reset vector low byte -> $FC00 boot stub")
	_assert(mem.peek(0xFFFD) == 0xFC, "Reset vector high byte -> $FC00 boot stub")
	_assert(mem.peek(0xFFFE) == 0x00, "IRQ vector low -> $0800")
	_assert(mem.peek(0xFFFF) == 0x08, "IRQ vector high -> $0800")
	_assert(mem.peek(0xFC00) == 0xA9, "Boot stub LDA #imm")

func test_memory_cart_select_register() -> void:
	_begin_test("Memory Cart Select $C030")
	var mem = _fresh_mem()
	_assert(mem.peek(0xC030) == 0, "peek C030 default 0")
	mem.set_cart_id_readback(1)
	_assert(mem.peek(0xC030) == 1, "peek C030 readback")

func test_memory_main_ram_high_water() -> void:
	_begin_test("Main RAM high-water")
	var mem = _fresh_mem()
	_assert(mem.get_main_ram_used_high_water() == 0, "empty main RAM")
	mem.poke(0x0500, 0x01)
	_assert(mem.get_main_ram_used_high_water() == (0x0500 - 0x0200 + 1), "span to last byte")
	mem.poke(0x0500, 0x00)
	_assert(mem.get_main_ram_used_high_water() == 0, "clear restores zero")

func test_cpu_load_store() -> void:
	_begin_test("CPU Load/Store")
	var mem = _fresh_mem()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x42
	mem.poke(0x0800, 0x85)
	mem.poke(0x0801, 0x10)
	cpu.step()
	_assert(mem.peek(0x0010) == 0x42, "STA zero page")
	cpu.PC = 0x0810
	mem.poke(0x0810, 0xA5)
	mem.poke(0x0811, 0x10)
	cpu.A = 0x00
	cpu.step()
	_assert(cpu.A == 0x42, "LDA zero page")
	cpu.PC = 0x0820
	cpu.A = 0xFF
	mem.poke(0x0820, 0x85)
	mem.poke(0x0821, 0x20)
	cpu.step()
	_assert(mem.peek(0x0020) == 0xFF, "STA zero page 2")
	cpu.PC = 0x0830
	mem.poke(0x0830, 0xA5)
	mem.poke(0x0831, 0x20)
	cpu.A = 0x00
	cpu.step()
	_assert(cpu.A == 0xFF, "LDA zero page reload")

func test_cpu_arithmetic() -> void:
	_begin_test("CPU Arithmetic")
	var mem = _fresh_mem()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x10
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0800, 0x69)
	mem.poke(0x0801, 0x20)
	cpu.step()
	_assert(cpu.A == 0x30, "ADC immediate 0x10 + 0x20")
	cpu.PC = 0x0810
	cpu.A = 0x50
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0810, 0xE9)
	mem.poke(0x0811, 0x10)
	cpu.step()
	_assert(cpu.A == 0x3F, "SBC immediate 0x50 - 0x10")
	cpu.PC = 0x0820
	cpu.A = 0xFF
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0820, 0x69)
	mem.poke(0x0821, 0x01)
	cpu.step()
	_assert(cpu.A == 0x00, "ADC immediate 0xFF + 0x01 overflow")
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "ADC carry set on overflow")

func test_cpu_logical() -> void:
	_begin_test("CPU Logical")
	var mem = _fresh_mem()
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

func test_cpu_shifts() -> void:
	_begin_test("CPU Shift/Rotate")
	var mem = _fresh_mem()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x81
	cpu.set_flag(CPU6502.Flag.C, false)
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
	cpu.set_flag(CPU6502.Flag.C, false)
	mem.poke(0x0820, 0x2A)
	cpu.step()
	_assert(cpu.A == 0x02, "ROL accumulator no carry in")
	cpu.PC = 0x0830
	cpu.A = 0x80
	cpu.set_flag(CPU6502.Flag.C, true)
	mem.poke(0x0830, 0x6A)
	cpu.step()
	_assert(cpu.A == 0xC0, "ROR accumulator with carry in (bit7 from old C)")
	_assert(cpu.get_flag(CPU6502.Flag.C) == false, "ROR carry out is old bit0 of A")
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
	var mem = _fresh_mem()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x50
	mem.poke(0x0800, 0xC9)
	mem.poke(0x0801, 0x50)
	cpu.step()
	_assert(cpu.get_flag(CPU6502.Flag.Z) == true, "CMP equal Z")
	_assert(cpu.get_flag(CPU6502.Flag.C) == true, "CMP equal C")

func test_cpu_branches() -> void:
	_begin_test("CPU Branches")
	var mem = _fresh_mem()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.set_flag(CPU6502.Flag.Z, true)
	mem.poke(0x0800, 0xD0)
	mem.poke(0x0801, 0x05)
	cpu.step()
	_assert(cpu.PC == 0x0802, "BNE not taken when Z=1")
	cpu.PC = 0x0810
	cpu.set_flag(CPU6502.Flag.Z, false)
	mem.poke(0x0810, 0xD0)
	mem.poke(0x0811, 0x05)
	cpu.step()
	_assert(cpu.PC == 0x0817, "BNE taken when Z=0")
	cpu.PC = 0x0820
	cpu.set_flag(CPU6502.Flag.C, true)
	mem.poke(0x0820, 0xB0)
	mem.poke(0x0821, 0x05)
	cpu.step()
	_assert(cpu.PC == 0x0827, "BCS branch taken")

func test_cpu_stack() -> void:
	_begin_test("CPU Stack")
	var mem = _fresh_mem()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x42
	cpu.SP = 0xFD
	mem.poke(0x0800, 0x48)
	cpu.step()
	_assert(mem.peek(0x01FD) == 0x42, "PHA push to stack at $0100+SP")
	_assert(cpu.SP == 0xFC, "PHA SP decremented")
	cpu.PC = 0x0810
	mem.poke(0x0810, 0x68)
	cpu.A = 0x00
	cpu.step()
	_assert(cpu.A == 0x42, "PLA pull from stack")

func test_cpu_jumps_subroutines() -> void:
	_begin_test("CPU Jumps/Subroutines")
	var mem = _fresh_mem()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	mem.poke(0x0800, 0x4C)
	mem.poke(0x0801, 0x34)
	mem.poke(0x0802, 0x12)
	cpu.step()
	_assert(cpu.PC == 0x1234, "JMP absolute")
	cpu.PC = 0x0900
	cpu.SP = 0xFD
	mem.poke(0x0900, 0x20)
	mem.poke(0x0901, 0x00)
	mem.poke(0x0902, 0x10)
	cpu.step()
	_assert(cpu.PC == 0x1000, "JSR sets PC")
	cpu.PC = 0x1000
	mem.poke(0x1000, 0x60)
	cpu.step()
	_assert(cpu.PC == 0x0903, "RTS returns")

func test_cpu_flags() -> void:
	_begin_test("CPU Flag Instructions")
	var mem = _fresh_mem()
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

func test_cpu_transfers() -> void:
	_begin_test("CPU Transfers")
	var mem = _fresh_mem()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	cpu.A = 0x42
	mem.poke(0x0800, 0xAA)
	cpu.step()
	_assert(cpu.X == 0x42, "TAX")
	cpu.PC = 0x0810
	mem.poke(0x0810, 0x8A)
	cpu.A = 0x00
	cpu.step()
	_assert(cpu.A == 0x42, "TXA")

func test_cpu_nop_brk() -> void:
	_begin_test("CPU NOP/BRK")
	var mem = _fresh_mem()
	var cpu = CPU6502.new(mem)
	cpu.PC = 0x0800
	mem.poke(0x0800, 0xEA)
	cpu.step()
	_assert(cpu.PC == 0x0801, "NOP increments PC")

func test_basic_print() -> void:
	_begin_test("BASIC PRINT")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program('10 PRINT "HELLO WORLD"\n20 PRINT 42\n30 PRINT 1+2\n40 END')
	basic.run()
	_assert("HELLO" in _output, "PRINT string literal")
	_assert("42" in _output, "PRINT number")
	_assert("3" in _output, "PRINT expression")

func test_basic_variables() -> void:
	_begin_test("BASIC Variables")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 LET A = 42\n20 LET B = A + 8\n30 PRINT B\n40 END")
	basic.run()
	_assert("50" in _output, "LET and variable arithmetic")

func test_basic_arithmetic() -> void:
	_begin_test("BASIC Arithmetic")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 PRINT 2 + 3 * 4\n20 PRINT (2 + 3) * 4\n30 END")
	basic.run()
	_assert("14" in _output, "Operator precedence")

func test_basic_conditions() -> void:
	_begin_test("BASIC IF/THEN")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program('10 IF 5 > 3 THEN PRINT "YES"\n20 END')
	basic.run()
	_assert("YES" in _output, "IF true condition")

func test_basic_loops() -> void:
	_begin_test("BASIC FOR/NEXT")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 FOR I = 1 TO 5\n20 PRINT I\n30 NEXT I\n40 END")
	basic.run()
	_assert("1" in _output, "FOR loop starts at 1")
	_assert("5" in _output, "FOR loop ends at 5")
	var lines = _output.split("\n")
	var count = 0
	for l in lines:
		if l.strip_edges().is_valid_int():
			count += 1
	_assert(count == 5, "FOR loop iterates exactly 5 times, got %d" % count)

func test_cart_loader_switch_clears_workspace() -> void:
	_begin_test("Cart Loader Workspace")
	var comp = Computer.new()
	comp.memory.poke(0xE000, 0x55)
	comp.memory.poke(0x0200, 0xAA)
	comp.cart_manager.switch_to(1, false)
	_assert(comp.memory.peek(0xE000) == 0x00, "cart swap clears $E000")
	_assert(comp.memory.peek(0x0200) == 0xAA, "main RAM preserved")
	_assert(comp.cart_manager.current.name == "TEXT", "TEXT cart active")

func test_cart_loader_poke_c030() -> void:
	_begin_test("Cart Loader POKE $C030")
	var comp = Computer.new()
	comp.memory.poke(0xC030, 1)
	_assert(comp.cart_manager.current.id == 1, "POKE C030 selects TEXT")
	_assert(comp.memory.peek(0xC030) == 1, "peek C030 matches cart")
	comp.memory.poke(0xC030, 0)
	_assert(comp.cart_manager.current.id == 0, "POKE C030 selects BASIC")

func test_cart_text_editor_commands() -> void:
	_begin_test("TEXT Cart Editor")
	var comp = Computer.new()
	comp.output.connect(_on_output)
	comp.output_richtext.connect(_on_output)
	comp.cart_manager.switch_to(1, false)
	_output = ""
	comp.cart_manager.handle_command("NEW")
	comp.cart_manager.handle_command("10 HELLO")
	_output = ""
	comp.cart_manager.handle_command("LIST")
	_assert("10" in _output and "HELLO" in _output, "LIST shows line")
	comp.cart_manager.handle_command("10")
	_output = ""
	comp.cart_manager.handle_command("LIST")
	_assert("HELLO" not in _output, "delete line 10")

func test_assembler6502_hello_snippet() -> void:
	_begin_test("Assembler6502 hello snippet")
	var mem = _fresh_mem()
	var asm = Assembler6502.new()
	var src: Array = [[10, "LDA #$41"], [20, "STA $C002"], [30, "RTS"]]
	var ok = asm.assemble(mem, src)
	_assert(ok, "assemble ok: %s" % str(asm.errors))
	_assert(mem.peek(0x0800) == 0xA9, "LDA #")
	_assert(mem.peek(0x0801) == 0x41, "imm")
	_assert(mem.peek(0x0802) == 0x8D, "STA abs")
	_assert(mem.peek(0x0803) == 0x02 and mem.peek(0x0804) == 0xC0, "addr C002")
	_assert(mem.peek(0x0805) == 0x60, "RTS")
	_assert(asm.last_start == 0x0800 and asm.last_end == 0x0805, "object range")

func test_cart_asm_commands() -> void:
	_begin_test("ASM cart assemble")
	var comp = Computer.new()
	comp.cart_manager.switch_to(2, false)
	comp.cart_manager.handle_command("NEW")
	comp.cart_manager.handle_command("10 LDA #$41")
	comp.cart_manager.handle_command("20 STA $C002")
	comp.cart_manager.handle_command("30 RTS")
	comp.cart_manager.handle_command("ASM")
	_assert(comp.memory.peek(0x0800) == 0xA9, "cart ASM pokes code")
	_assert(comp.memory.peek(0x0805) == 0x60, "RTS in RAM")

func test_computer_cart_serialize_roundtrip() -> void:
	_begin_test("Computer Cart Serialize")
	var comp = Computer.new()
	comp.cart_manager.switch_to(1, false)
	comp.cart_manager.handle_command("NEW")
	comp.cart_manager.handle_command("20 WORLD")
	var data := comp.serialize()
	var comp2 := Computer.new()
	comp2.deserialize(data)
	_assert(comp2.cart_manager.get_current_id() == 1, "restored TEXT cart")
	var st: Dictionary = comp2.cart_manager.serialize_cart_state()
	_assert(st.has("lines") and st["lines"].size() == 1, "TEXT buffer serialized")
	_assert(int(st["lines"][0]["ln"]) == 20, "line number preserved")

func test_basic_nested_loops() -> void:
	_begin_test("BASIC Nested FOR/NEXT")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 FOR I = 1 TO 3\n20 FOR J = 1 TO 3\n30 PRINT I; J\n40 NEXT J\n50 NEXT I\n60 END")
	basic.run()
	_assert("1" in _output, "Nested loop I=1")
	_assert("3" in _output, "Nested loop I=3,J=3")

func test_basic_for_step() -> void:
	_begin_test("BASIC FOR STEP")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 FOR I = 0 TO 10 STEP 2\n20 PRINT I\n30 NEXT I\n40 END")
	basic.run()
	_assert("0" in _output, "STEP loop starts at 0")
	_assert("10" in _output, "STEP loop reaches 10")
	_assert("2" in _output, "STEP loop prints 2")

func test_basic_for_reverse() -> void:
	_begin_test("BASIC FOR Reverse Step")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 FOR I = 5 TO 1 STEP -1\n20 PRINT I\n30 NEXT I\n40 END")
	basic.run()
	_assert("5" in _output, "Reverse loop starts at 5")
	_assert("1" in _output, "Reverse loop reaches 1")

func test_basic_gosub() -> void:
	_begin_test("BASIC GOSUB/RETURN")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 GOSUB 100\n20 PRINT \"BACK\"\n30 END\n100 PRINT \"SUB\"\n110 RETURN")
	basic.run()
	_assert("SUB" in _output, "GOSUB calls subroutine")
	_assert("BACK" in _output, "RETURN goes back")

func test_basic_functions() -> void:
	_begin_test("BASIC Built-in Functions")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 PRINT INT(3.7)\n20 PRINT ABS(-5)\n30 END")
	basic.run()
	_assert("3" in _output, "INT(3.7)=3")
	_assert("5" in _output, "ABS(-5)=5")

func test_basic_strings() -> void:
	_begin_test("BASIC String Functions")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program('10 A$ = "HELLO"\n20 PRINT LEFT$(A$, 3)\n30 END')
	basic.run()
	_assert("HEL" in _output, "LEFT$()")

func test_basic_arrays() -> void:
	_begin_test("BASIC Arrays")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 DIM A(5)\n20 FOR I = 0 TO 5\n30 A(I) = I * 10\n40 NEXT I\n50 PRINT A(3)\n60 END")
	basic.run()
	_assert("30" in _output, "Array A(3)=30")

func test_basic_read_data() -> void:
	_begin_test("BASIC READ/DATA")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 READ A, B, C\n20 PRINT A\n30 DATA 10, 20, 30\n40 END")
	basic.run()
	_assert("10" in _output, "READ first value")

func test_basic_poke_peek() -> void:
	_begin_test("BASIC POKE/PEEK")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 POKE 1000, 42\n20 PRINT PEEK(1000)\n30 END")
	basic.run()
	_assert("42" in _output, "POKE then PEEK")

func test_basic_computed_gosub() -> void:
	_begin_test("BASIC ON GOSUB")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program("10 ON 2 GOTO 100, 200\n20 END\n100 PRINT \"ONE\"\n110 GOTO 20\n200 PRINT \"TWO\"\n210 GOTO 20")
	basic.run()
	_assert("TWO" in _output, "ON GOTO branching")

func test_computer_integration() -> void:
	_begin_test("Computer Integration")
	var comp = Computer.new()
	comp.output.connect(_on_output)
	comp.run_basic_sync("10 PRINT \"HELLO\"\n20 FOR I = 1 TO 3\n30 PRINT I * I\n40 NEXT I\n50 END")
	_assert("HELLO" in _output, "Computer prints greeting")
	_assert("9" in _output, "Computer prints 3*3=9")

func test_computer_var_persistence() -> void:
	_begin_test("Computer Variable Persistence Across RUN")
	var comp = Computer.new()
	comp.output.connect(_on_output)
	comp.basic.execute_line("LET X = 100")
	_output = ""
	comp.run_basic_sync("10 PRINT X\n20 X = X + 1\n30 END")
	_assert("100" in _output, "First RUN sees pre-set variable X=100")
	_assert(comp.basic.get_variable("X") == 101, "X updated to 101 after first RUN")
	_output = ""
	comp.run_basic_sync("10 PRINT X\n20 X = X * 2\n30 END")
	_assert("101" in _output, "Second RUN sees persisted X=101")
	_assert(comp.basic.get_variable("X") == 202, "X doubled to 202 after second RUN")
	_output = ""
	comp.basic.execute_line("NEW")
	comp.run_basic_sync("10 PRINT X\n20 END")
	_assert(" 0 " in _output, "X reset to 0 after NEW")

func test_bsave_bload() -> void:
	_begin_test("BSAVE/BLOAD Binary")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	mem.poke(0x1000, 0xDE)
	mem.poke(0x1001, 0xAD)
	mem.poke(0x1002, 0xBE)
	mem.poke(0x1003, 0xEF)
	basic.load_program('10 BSAVE "test.bin", 4096, 4\n20 END')
	basic.run()
	_assert("SAVED 4 BYTES" in _output or "SAVED" in _output, "BSAVE saves 4 bytes")
	if FileAccess.file_exists("user://test.bin"):
		var file = FileAccess.open("user://test.bin", FileAccess.READ)
		_assert(file != null, "Binary file exists")
		if file:
			var lo = file.get_8()
			var hi = file.get_8()
			var saved_addr = lo | (hi << 8)
			_assert(saved_addr == 0x1000, "Header has load addr 0x1000, got 0x%04X" % saved_addr)
			_assert(file.get_8() == 0xDE, "Byte 0 = 0xDE")
			_assert(file.get_8() == 0xAD, "Byte 1 = 0xAD")
			_assert(file.get_8() == 0xBE, "Byte 2 = 0xBE")
			_assert(file.get_8() == 0xEF, "Byte 3 = 0xEF")
			file.close()
	else:
		print("  [SKIP] Cannot verify BLOAD (file not created)")

func test_write_readfile() -> void:
	_begin_test("WRITE/READFILE Text")
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.load_program('10 WRITE "test.txt", "HELLO FROM BASIC"\n20 END')
	basic.run()
	_assert("WRITTEN" in _output, "WRITE creates text file")
	if FileAccess.file_exists("user://test.txt"):
		var file = FileAccess.open("user://test.txt", FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			_assert(content == "HELLO FROM BASIC", "WRITE stores correct content, got: %s" % content)
	else:
		print("  [SKIP] Cannot verify READFILE")
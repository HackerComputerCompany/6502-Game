extends SceneTree

const _SoftFloatScript := preload("res://scripts/native_basic_softfloat.gd")
const _MemoryBus6502 := preload("res://scripts/memory_bus_6502.gd")
var _reg_sf: RefCounted

var _tests_passed: int = 0
var _tests_failed: int = 0
var _current_test: String = ""
var _output: String = ""

func _init() -> void:
	_reg_sf = _SoftFloatScript.new()
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
	test_text_cart_list_range_and_print()
	test_text_cart_save_load_roundtrip_disk()
	test_text_cart_catalog_and_scratch_missing()
	test_reboot_deep_clears_cart_buffers()
	test_assembler6502_hello_snippet()
	test_assembler_hello_demo_run_single_A()
	test_assembler_stars_demo_run_ten_asterisks()
	test_cart_asm_commands()
	test_cart_asm_demos_assemble()
	test_c_cart_compile_hello()
	test_c_cart_compile_and_run()
	test_c_cart_demo_compiles()
	test_c_cart_build_alias_compiles()
	test_c_cart_del_line_removes_from_buffer()
	test_c_cart_demo_list_and_unknown_demo()
	test_c_cart_save_load_roundtrip_compile()
	test_hc65_round_trip()
	test_assembler_meta_directives()
	test_cart_asm_saveobj_all_demos()
	test_basic_loadobj_native_call()
	test_computer_cart_serialize_roundtrip()
	test_native_softfloat_primitives()
	test_native_basic_runtime_arithmetic()
	test_basic_runtime_mode_serialize()
	test_cart_native_registered()
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
	return _MemoryBus6502.new()


func _dispose_computer(comp: Computer) -> void:
	if comp == null:
		return
	for sig_name in [&"output", &"output_richtext", &"ready_for_input", &"program_finished", &"full_reboot_requested"]:
		for conn in comp.get_signal_connection_list(sig_name):
			var cb: Callable = conn["callable"]
			if cb.is_valid():
				comp.disconnect(sig_name, cb)
	comp.disconnect_memory_signal_links()


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
	_dispose_computer(comp)

func test_cart_loader_poke_c030() -> void:
	_begin_test("Cart Loader POKE $C030")
	var comp = Computer.new()
	comp.memory.poke(0xC030, 1)
	_assert(comp.cart_manager.current.id == 1, "POKE C030 selects TEXT")
	_assert(comp.memory.peek(0xC030) == 1, "peek C030 matches cart")
	comp.memory.poke(0xC030, 0)
	_assert(comp.cart_manager.current.id == 0, "POKE C030 selects BASIC")
	_dispose_computer(comp)

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
	_dispose_computer(comp)


func test_text_cart_list_range_and_print() -> void:
	_begin_test("TEXT Cart LIST range and PRINT")
	var comp = Computer.new()
	comp.output_richtext.connect(_on_output)
	comp.cart_manager.switch_to(1, false)
	comp.cart_manager.handle_command("NEW")
	comp.cart_manager.handle_command("10 ALPHA")
	comp.cart_manager.handle_command("20 BRAVO")
	comp.cart_manager.handle_command("30 CHARLIE")
	_output = ""
	comp.cart_manager.handle_command("LIST 20 30")
	_assert("BRAVO" in _output and "CHARLIE" in _output, "range lists middle lines")
	_assert("ALPHA" not in _output, "range excludes low line")
	_output = ""
	comp.cart_manager.handle_command("PRINT")
	_assert("ALPHA" in _output and "BRAVO" in _output and "CHARLIE" in _output, "PRINT dumps all bodies")
	_dispose_computer(comp)


func test_text_cart_save_load_roundtrip_disk() -> void:
	_begin_test("TEXT Cart SAVE/LOAD round-trip")
	var path := "user://regtest_text_editor_roundtrip.txt"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var comp = Computer.new()
	comp.output_richtext.connect(_on_output)
	comp.cart_manager.switch_to(1, false)
	comp.cart_manager.handle_command("NEW")
	comp.cart_manager.handle_command("10 FIRST LINE")
	comp.cart_manager.handle_command("20 SECOND LINE")
	_output = ""
	comp.cart_manager.handle_command("SAVE regtest_text_editor_roundtrip")
	_assert("Saved" in _output, "SAVE reports success")
	comp.cart_manager.handle_command("NEW")
	_output = ""
	comp.cart_manager.handle_command("LIST")
	_assert("empty" in _output.to_lower(), "buffer cleared after NEW")
	_output = ""
	comp.cart_manager.handle_command("LOAD regtest_text_editor_roundtrip")
	_assert("Loaded" in _output, "LOAD reports success")
	_output = ""
	comp.cart_manager.handle_command("LIST")
	_assert("FIRST" in _output and "SECOND" in _output, "lines restored from disk")
	_dispose_computer(comp)


func test_text_cart_catalog_and_scratch_missing() -> void:
	_begin_test("TEXT Cart CATALOG and SCRATCH missing file")
	var comp = Computer.new()
	comp.output_richtext.connect(_on_output)
	comp.cart_manager.switch_to(1, false)
	_output = ""
	comp.cart_manager.handle_command("CATALOG")
	_assert(".TXT" in _output or "txt" in _output.to_lower(), "catalog lists txt section")
	_output = ""
	comp.cart_manager.handle_command("SCRATCH regtest_text_absolutely_missing_xyz")
	_assert("not found" in _output.to_lower() or "File not found" in _output, "scratch missing file")
	_dispose_computer(comp)


func test_reboot_deep_clears_cart_buffers() -> void:
	_begin_test("REBOOT deep clears ASM buffer")
	var comp = Computer.new()
	comp.output_richtext.connect(_on_output)
	comp.cart_manager.switch_to(2, false)
	comp.cart_manager.handle_command("10 LDA #$00")
	comp.cart_manager.handle_command("REBOOT")
	_assert(comp.cart_manager.current.id == 0, "REBOOT returns to BASIC cart")
	comp.cart_manager.switch_to(2, false)
	_output = ""
	comp.cart_manager.handle_command("LIST")
	_assert("empty source" in _output.to_lower(), "ASM listing empty after REBOOT")
	_dispose_computer(comp)

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


func test_assembler_hello_demo_run_single_A() -> void:
	_begin_test("hello-style object run prints one A then halts")
	var mem = _MemoryBus6502.new()
	var asm = Assembler6502.new()
	var src: Array = [
		[10, "LDA #$41"],
		[20, "STA $C002"],
		[30, "LDA #$0D"],
		[40, "STA $C003"],
		[50, "RTS"],
	]
	_assert(asm.assemble(mem, src), str(asm.errors))
	var cpu = CPU6502.new(mem)
	mem.prepare_cpu_stack_for_user_rts(cpu)
	cpu.PC = asm.last_start & 0xFFFF
	var captured: Array = [""]
	var capture_cb_a := func(t: String): if t != "[CLR]": captured[0] = t
	mem.output_ready.connect(capture_cb_a)
	cpu.run(10000)
	mem.output_ready.disconnect(capture_cb_a)
	var s: String = str(captured[0])
	var ac := 0
	for i in range(s.length()):
		if s.unicode_at(i) == 0x41:
			ac += 1
	_assert(ac == 1, "expected one 'A', got %d in %s" % [ac, s])
	_assert(cpu.halted, "CPU should halt on $FF after RTS")


func test_assembler_stars_demo_run_ten_asterisks() -> void:
	_begin_test("stars demo RUN prints exactly ten asterisks")
	var mem = _fresh_mem()
	var asm = Assembler6502.new()
	var lines: Array = [
		[10, "LDX #$0A"],
		[20, "LOOP: LDA #$2A"],
		[30, "STA $C002"],
		[40, "DEX"],
		[50, "BNE LOOP"],
		[60, "LDA #$0D"],
		[70, "STA $C003"],
		[80, "RTS"],
	]
	_assert(asm.assemble(mem, lines), str(asm.errors))
	var cpu = CPU6502.new(mem)
	mem.prepare_cpu_stack_for_user_rts(cpu)
	cpu.PC = asm.last_start & 0xFFFF
	var captured: Array = [""]
	var capture_cb := func(t: String): if t != "[CLR]": captured[0] = t
	mem.output_ready.connect(capture_cb)
	cpu.run(10000)
	mem.output_ready.disconnect(capture_cb)
	var s: String = str(captured[0])
	var star_count := 0
	for i in range(s.length()):
		if s.unicode_at(i) == 0x2A:
			star_count += 1
	_assert(star_count == 10, "expected 10 '*', got %d in %s" % [star_count, s])
	_assert(cpu.halted, "CPU should halt on $FF after RTS (PC was $%04X)" % cpu.PC)


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
	_dispose_computer(comp)

func test_c_cart_compile_hello() -> void:
	_begin_test("C cart compile hello")
	var comp = Computer.new()
	comp.output_richtext.connect(_on_output)
	_output = ""
	comp.cart_manager.switch_to(3, false)
	comp.cart_manager.handle_command("NEW")
	comp.cart_manager.handle_command("10 main() {")
	comp.cart_manager.handle_command("20 putc(65); putc(13);")
	comp.cart_manager.handle_command("30 }")
	_output = ""
	comp.cart_manager.handle_command("COMPILE")
	_assert("Compiled" in _output, "compile success: %s" % _output)
	_dispose_computer(comp)

func test_c_cart_compile_and_run() -> void:
	_begin_test("C cart compile and run")
	var comp = Computer.new()
	comp.output.connect(_on_output)
	comp.output_richtext.connect(_on_output)
	_output = ""
	comp.cart_manager.switch_to(3, false)
	comp.cart_manager.handle_command("NEW")
	comp.cart_manager.handle_command("10 main() {")
	comp.cart_manager.handle_command("20 putc(65); putc(66); putc(67); putc(13);")
	comp.cart_manager.handle_command("30 }")
	_output = ""
	comp.cart_manager.handle_command("COMPILE")
	_assert("Compiled" in _output, "compiled: %s" % _output)
	_output = ""
	comp.cart_manager.handle_command("RUN")
	_assert("ABC" in _output, "output contains ABC: %s" % _output)
	_dispose_computer(comp)

func test_c_cart_demo_compiles() -> void:
	_begin_test("C cart DEMO sources compile")
	var demo_names: Array = ["hello", "count", "fib", "sum", "max", "stars"]
	for demo_name in demo_names:
		var comp = Computer.new()
		comp.output_richtext.connect(_on_output)
		_output = ""
		comp.cart_manager.switch_to(3, false)
		comp.cart_manager.handle_command("DEMO " + str(demo_name))
		comp.cart_manager.handle_command("COMPILE")
		_assert("failed" not in _output.to_lower(), "demo %s compiles (%s)" % [demo_name, _output])
		_dispose_computer(comp)


func test_c_cart_build_alias_compiles() -> void:
	_begin_test("C cart BUILD alias compiles")
	var comp = Computer.new()
	comp.output_richtext.connect(_on_output)
	comp.cart_manager.switch_to(3, false)
	_output = ""
	comp.cart_manager.handle_command("BUILD")
	_assert("No source" in _output, "BUILD with empty buffer errors")
	comp.cart_manager.handle_command("10 main() {")
	comp.cart_manager.handle_command("20 putc(88); putc(13);")
	comp.cart_manager.handle_command("30 }")
	_output = ""
	comp.cart_manager.handle_command("BUILD")
	_assert("Compiled" in _output, "BUILD compiles like COMPILE: %s" % _output)
	_dispose_computer(comp)


func test_c_cart_del_line_removes_from_buffer() -> void:
	_begin_test("C cart DEL removes line")
	var comp = Computer.new()
	comp.output_richtext.connect(_on_output)
	comp.cart_manager.switch_to(3, false)
	comp.cart_manager.handle_command("NEW")
	comp.cart_manager.handle_command("10 main() {")
	comp.cart_manager.handle_command("20 putc(65);")
	comp.cart_manager.handle_command("30 putc(13);")
	comp.cart_manager.handle_command("40 }")
	comp.cart_manager.handle_command("DEL 30")
	_output = ""
	comp.cart_manager.handle_command("LIST")
	_assert("10" in _output and "20" in _output and "40" in _output, "LIST still shows 10/20/40")
	_assert(not _output.contains("30  putc"), "deleted line 30 absent from LIST")
	_dispose_computer(comp)


func test_c_cart_demo_list_and_unknown_demo() -> void:
	_begin_test("C cart DEMO list and unknown demo")
	var comp = Computer.new()
	comp.output_richtext.connect(_on_output)
	comp.cart_manager.switch_to(3, false)
	_output = ""
	comp.cart_manager.handle_command("DEMOS")
	_assert("hello" in _output.to_lower() or "built-in" in _output.to_lower(), "demo list mentions demos")
	_output = ""
	comp.cart_manager.handle_command("DEMO definitely_not_a_builtin_demo_name_qxz")
	_assert("Unknown" in _output or "unknown" in _output.to_lower(), "unknown demo rejected")
	_dispose_computer(comp)


func test_c_cart_save_load_roundtrip_compile() -> void:
	_begin_test("C cart SAVE/LOAD round-trip and COMPILE")
	var path := "user://regtest_c_cart_roundtrip.c"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var comp = Computer.new()
	comp.output_richtext.connect(_on_output)
	comp.cart_manager.switch_to(3, false)
	comp.cart_manager.handle_command("NEW")
	comp.cart_manager.handle_command("10 main() {")
	comp.cart_manager.handle_command("20 putc(90); putc(13);")
	comp.cart_manager.handle_command("30 }")
	_output = ""
	comp.cart_manager.handle_command("SAVE regtest_c_cart_roundtrip")
	_assert("Saved" in _output, "SAVE .c success")
	comp.cart_manager.handle_command("NEW")
	_output = ""
	comp.cart_manager.handle_command("LIST")
	_assert("empty" in _output.to_lower(), "cleared")
	_output = ""
	comp.cart_manager.handle_command("LOAD regtest_c_cart_roundtrip")
	_assert("Loaded" in _output, "LOAD .c success")
	_output = ""
	comp.cart_manager.handle_command("COMPILE")
	_assert("Compiled" in _output, "compile after load: %s" % _output)
	_dispose_computer(comp)


func test_cart_asm_demos_assemble() -> void:
	_begin_test("ASM cart DEMO sources assemble")
	var demo_names: Array = ["hello", "stars", "digits", "branch", "equ_star", "org_hi", "data_end"]
	for demo_name in demo_names:
		var comp = Computer.new()
		comp.output_richtext.connect(_on_output)
		_output = ""
		comp.cart_manager.switch_to(2, false)
		comp.cart_manager.handle_command("DEMO " + str(demo_name))
		comp.cart_manager.handle_command("ASM")
		_assert("Assembly failed" not in _output, "demo %s assembles (%s)" % [demo_name, _output])
		if demo_name == "hello":
			_assert(comp.memory.peek(0x0800) == 0xA9, "hello at $0800")
		if demo_name == "org_hi":
			_assert(comp.memory.peek(0x0900) == 0xA9, "org_hi code at $0900")
		_dispose_computer(comp)


func test_hc65_round_trip() -> void:
	_begin_test("HC65 encode/decode")
	var code := PackedByteArray([0xA9, 0x01, 0x60])
	var ex: Array = ["10 TST"]
	var blob := HC65Object.encode(0x700, 0x700, code, "TST", "TST", "test obj", ex)
	var dec: Dictionary = HC65Object.decode(blob)
	_assert(bool(dec.get("ok", false)), str(dec.get("errors", [])))
	_assert(int(dec["load_addr"]) == 0x700, "load")
	_assert(int(dec["entry_addr"]) == 0x700, "entry")
	_assert((dec["code"] as PackedByteArray).size() == 3, "code len")
	_assert(str(dec["export_name"]) == "TST", "export")
	_assert(str(dec["help_syntax"]) == "TST", "syntax")
	_assert(str(dec["help_desc"]) == "test obj", "desc")
	var hx: Array = dec["help_examples"]
	_assert(hx.size() == 1 and str(hx[0]) == "10 TST", "example")


func test_assembler_meta_directives() -> void:
	_begin_test("Assembler .EXPORT .ENTRY .HELP")
	var mem = _fresh_mem()
	var asm = Assembler6502.new()
	var src: Array = [
		[5, ".EXPORT TST"],
		[6, ".HELP_SYNTAX \"TST\""],
		[7, ".HELP_DESC \"demo\""],
		[8, ".HELP_EXAMPLE \"10 TST\""],
		[10, "START: LDA #$77"],
		[20, "STA $C002"],
		[30, "RTS"],
		[40, ".ENTRY START"],
	]
	var ok = asm.assemble(mem, src)
	_assert(ok, str(asm.errors))
	_assert(asm.meta_export == "TST", "export")
	_assert(asm.object_entry == 0x0800, "entry at START")
	_assert(asm.meta_help_syntax == "TST", "help syn")
	_assert(asm.meta_help_examples.size() == 1, "one example")


func test_cart_asm_saveobj_all_demos() -> void:
	_begin_test("ASM SAVEOBJ HC65 for all demos")
	var demo_names: Array = ["hello", "stars", "digits", "branch", "equ_star", "org_hi", "data_end"]
	for demo_name in demo_names:
		var comp = Computer.new()
		comp.output_richtext.connect(_on_output)
		_output = ""
		comp.cart_manager.switch_to(2, false)
		comp.cart_manager.handle_command("DEMO " + str(demo_name))
		comp.cart_manager.handle_command("ASM")
		_assert("Assembly failed" not in _output, "assemble demo %s" % demo_name)
		var base := "regtest_hc65_%s" % demo_name
		comp.cart_manager.handle_command("SAVEOBJ " + base)
		_assert("Write failed" not in _output, "SAVEOBJ wrote %s" % base)
		var path := "user://%s.obj" % base
		var f := FileAccess.open(path, FileAccess.READ)
		_assert(f != null, "open %s" % path)
		var raw := f.get_buffer(f.get_length())
		f.close()
		var dec: Dictionary = HC65Object.decode(raw)
		_assert(bool(dec.get("ok", false)), "decode %s: %s" % [demo_name, str(dec.get("errors", []))])
		var code: PackedByteArray = dec["code"]
		_assert(code.size() > 0, "nonempty code %s" % demo_name)
		if demo_name == "org_hi":
			_assert(int(dec["load_addr"]) == 0x0900, "org_hi load addr")
		_dispose_computer(comp)


func test_basic_loadobj_native_call() -> void:
	_begin_test("BASIC LOADOBJ + native call")
	var code := PackedByteArray([0xA9, 0x5A, 0x8D, 0x02, 0xC0, 0xA9, 0x0D, 0x8D, 0x03, 0xC0, 0x60])
	var blob := HC65Object.encode(0x600, 0x600, code, "ZZZ", "ZZZ", "writes Z", [])
	var path := "user://regtest_loadobj_zzz.obj"
	var wf := FileAccess.open(path, FileAccess.WRITE)
	_assert(wf != null, "write test obj")
	wf.store_buffer(blob)
	wf.close()
	var mem = _fresh_mem()
	var basic = BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.execute_line('LOADOBJ "regtest_loadobj_zzz.obj", ZZZ')
	basic.execute_line("ZZZ")
	_assert("Z" in _output or _output.contains("Z"), "native ran: %s" % _output)
	var h := basic.format_native_help("ZZZ")
	_assert("ZZZ" in h and "LOADOBJ" in h, "native help")


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
	_dispose_computer(comp)
	_dispose_computer(comp2)


func test_native_softfloat_primitives() -> void:
	_begin_test("Native IEEE soft-float primitives")
	var one: int = _reg_sf.float_bits(1.0)
	var two: int = _reg_sf.float_bits(2.0)
	var thr: int = _reg_sf.add_bits(one, two)
	_assert(thr == _reg_sf.float_bits(3.0), "add 1+2")
	var neg: int = _reg_sf.sub_bits(thr, two)
	_assert(neg == one, "sub 3-2")
	var ten: int = _reg_sf.mul_bits(_reg_sf.float_bits(2.5), _reg_sf.float_bits(4.0))
	_assert(ten == _reg_sf.float_bits(10.0), "mul 2.5*4")
	var dv: int = _reg_sf.div_bits(_reg_sf.float_bits(10.0), _reg_sf.float_bits(4.0))
	_assert(abs(_reg_sf.bits_float(dv) - 2.5) < 1e-5, "div 10/4")


func test_native_basic_runtime_arithmetic() -> void:
	_begin_test("BASIC NATIVE runtime arithmetic")
	var mem := _fresh_mem()
	var basic := BasicInterpreter.new(mem, _on_output, func(_p): return [""])
	basic.basic_runtime_mode = BasicInterpreter.BasicRuntimeMode.NATIVE
	_output = ""
	basic.execute_line("PRINT 2.5*4")
	_assert(_output.strip_edges() == "10", "PRINT 2.5*4 native")
	_output = ""
	basic.execute_line("PRINT 10/4")
	var q := float(_output.strip_edges())
	_assert(abs(q - 2.5) < 1e-4, "PRINT 10/4 native")
	_output = ""
	basic.execute_line("PRINT 1/0")
	_assert(_output.strip_edges() == "0", "native div0 -> 0")
	_output = ""
	basic.basic_runtime_mode = BasicInterpreter.BasicRuntimeMode.HYBRID
	basic.execute_line("PRINT 1/0")
	_assert(_output.strip_edges() == "0", "hybrid div0 -> 0")


func test_basic_runtime_mode_serialize() -> void:
	_begin_test("Basic runtime mode serialize")
	var comp := Computer.new()
	comp.basic.basic_runtime_mode = BasicInterpreter.BasicRuntimeMode.NATIVE
	var data := comp.serialize()
	var comp2 := Computer.new()
	comp2.deserialize(data)
	_assert(comp2.basic.basic_runtime_mode == BasicInterpreter.BasicRuntimeMode.NATIVE, "mode restored")
	_dispose_computer(comp)
	_dispose_computer(comp2)


func test_cart_native_registered() -> void:
	_begin_test("Cart NATIVE registered")
	var comp := Computer.new()
	_assert(comp.cart_manager.switch_to("NATIVE", true), "switch to NATIVE cart")
	_assert(comp.cart_manager.current.name == "NATIVE", "current cart")
	_assert(comp.cart_manager.switch_to(0, true), "back to BASIC")
	_dispose_computer(comp)


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
	_dispose_computer(comp)

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
	_dispose_computer(comp)

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
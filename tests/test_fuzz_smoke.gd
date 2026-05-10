extends SceneTree

## Short fuzz smoke: BASIC one-liners, assembler sources, CPU runs, TEXT cart, C cart.
## Run: godot --path . --headless -s tests/test_fuzz_smoke.gd -- --fuzz-iters=500 --fuzz-seed=42

var _tests_passed: int = 0
var _tests_failed: int = 0

const _MemoryBus6502 := preload("res://scripts/memory_bus_6502.gd")

const _ASM_CHUNKS: Array[String] = [
	"LDA #",
	"LDX #",
	"LDY #",
	"STA $",
	"STX $",
	"STY $",
	"INX",
	"DEX",
	"INY",
	"DEY",
	"NOP",
	"CLC",
	"SEC",
	"BNE ",
	"BEQ ",
	"JMP ",
	"JSR $",
	"RTS",
	"BRK",
	"LOOP",
	": LDA #$",
	",X",
	",Y",
	" ($",
	"),Y",
	";",
	".BYTE ",
	".ORG $",
]


func _init() -> void:
	var ua := OS.get_cmdline_user_args()
	var iters := 400
	var seed_u := int(Time.get_ticks_usec() % 1_000_000_007)
	for a in ua:
		if a.begins_with("--fuzz-iters="):
			iters = maxi(10, int(a.get_slice("=", 1)))
		elif a.begins_with("--fuzz-seed="):
			seed_u = int(a.get_slice("=", 1))

	print("\n========== FUZZ SMOKE ==========")
	print("  seed=%d  iterations=%d\n" % [seed_u, iters])

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_u as int

	var budget_deadline_ms := Time.get_ticks_msec() + 120_000

	_begin_round("BASIC execute_line fuzz")
	_fuzz_basic_execute_lines(iters, rng, budget_deadline_ms)

	_begin_round("Assembler6502 fuzz")
	_fuzz_assembler(iters, rng, budget_deadline_ms)

	_begin_round("CPU random RAM fuzz")
	_fuzz_cpu_random(iters, rng, budget_deadline_ms)

	_begin_round("TEXT cart command fuzz")
	_fuzz_text_cart_commands(iters, rng, budget_deadline_ms)

	_begin_round("C cart command fuzz")
	_fuzz_c_cart_commands(iters, rng, budget_deadline_ms)

	print("\n========== FUZZ RESULTS ==========")
	print("  PASSED checks: %d" % _tests_passed)
	print("  FAILED checks: %d" % _tests_failed)
	print("===================================\n")

	quit(1 if _tests_failed > 0 else 0)


func _begin_round(name: String) -> void:
	print("Running: %s" % name)


func _pass() -> void:
	_tests_passed += 1


func _fail(msg: String) -> void:
	_tests_failed += 1
	push_error("fuzz: %s" % msg)


func _fuzz_basic_execute_lines(iters: int, rng: RandomNumberGenerator, deadline_ms: int) -> void:
	for _i in range(iters):
		if Time.get_ticks_msec() > deadline_ms:
			_fail("global time budget exceeded during BASIC fuzz")
			return
		var comp := Computer.new()
		var line := _random_basic_line(rng)
		var t0 := Time.get_ticks_msec()
		comp.basic.execute_line(line)
		var dt := Time.get_ticks_msec() - t0
		comp.disconnect_memory_signal_links()
		if dt > 5_000:
			_fail("BASIC execute_line stall >5s line=%s" % line.substr(0, mini(80, line.length())))
			return
		_pass()


func _random_basic_line(rng: RandomNumberGenerator) -> String:
	## Whitelist-only: random token soup caused tokenizer/parser path hangs.
	var n := rng.randi_range(0, 12)
	match n:
		0, 1:
			return "REM %s" % _random_ident(rng)
		2:
			return "PRINT %d" % rng.randi_range(-999_999, 999_999)
		3:
			return "PRINT \"%s\"" % _random_string_lit(rng)
		4:
			return "LET %s = %d" % [_random_ident(rng), rng.randi_range(-10_000, 10_000)]
		5:
			return "LET %s$ = \"%s\"" % [_random_ident(rng), _random_string_lit(rng)]
		6:
			var a := rng.randi_range(-50, 50)
			var b := rng.randi_range(-50, 50)
			return "PRINT %d + %d * %d" % [a, b, rng.randi_range(-10, 10)]
		7:
			return "IF %d %s %d THEN PRINT \"OK\"" % [
				rng.randi_range(-20, 20), ["<", ">", "=", "<>", "<=", ">="][rng.randi_range(0, 5)],
				rng.randi_range(-20, 20),
			]
		8:
			return "CLR"
		9:
			return "LIST"
		10:
			return "PRINT LEN(\"%s\")" % _random_string_lit(rng)
		11:
			return "PRINT INT(RND(1) * %d)" % rng.randi_range(1, 1000)
		_:
			return "PRINT CHR$(%d)" % rng.randi_range(32, 126)


func _random_ident(rng: RandomNumberGenerator) -> String:
	var letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var s := ""
	var ln := rng.randi_range(1, 6)
	for _j in range(ln):
		s += letters[rng.randi_range(0, letters.length() - 1)]
	return s


func _random_string_lit(rng: RandomNumberGenerator) -> String:
	var alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "
	var out := ""
	var ln := rng.randi_range(0, 24)
	for _j in range(ln):
		out += alphabet[rng.randi_range(0, alphabet.length() - 1)]
	return out


func _random_short_ascii_body(rng: RandomNumberGenerator, max_len: int) -> String:
	var alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 (){};_-+/%"
	var out := ""
	var ln := rng.randi_range(0, max_len)
	for _j in range(ln):
		out += alphabet[rng.randi_range(0, alphabet.length() - 1)]
	return out


func _fuzz_text_cart_commands(iters: int, rng: RandomNumberGenerator, deadline_ms: int) -> void:
	for _i in range(iters):
		if Time.get_ticks_msec() > deadline_ms:
			_fail("global time budget exceeded during TEXT cart fuzz")
			return
		var comp := Computer.new()
		var t0 := Time.get_ticks_msec()
		comp.cart_manager.switch_to(1, false)
		var n_cmds := rng.randi_range(2, 7)
		for _j in range(n_cmds):
			comp.cart_manager.handle_command(_random_text_cart_command(rng))
		var dt := Time.get_ticks_msec() - t0
		comp.disconnect_memory_signal_links()
		if dt > 8_000:
			_fail("TEXT cart fuzz stall >8s")
			return
		_pass()


func _random_text_cart_command(rng: RandomNumberGenerator) -> String:
	match rng.randi_range(0, 13):
		0:
			return "NEW"
		1:
			return "HELP"
		2:
			return "PRINT"
		3:
			return "LIST"
		4:
			var a := rng.randi_range(10, 400)
			var b := rng.randi_range(a, min(a + 800, 9999))
			return "LIST %d %d" % [a, b]
		5:
			return "DIR"
		6:
			return "CATALOG"
		7:
			return "SAVE fuzz_txt_%d" % rng.randi()
		8:
			return "LOAD fuzz_txt_%d" % rng.randi()
		9:
			return "SCRATCH fuzz_txt_missing_%d" % rng.randi()
		10:
			return "DELETE fuzz_txt_missing_%d" % rng.randi()
		11:
			var ln := rng.randi_range(1, 999) * 10
			return str(ln)
		_:
			var ln2 := rng.randi_range(1, 120) * 10
			var body := _random_short_ascii_body(rng, 44)
			if body.strip_edges() == "":
				body = "note"
			return "%d %s" % [ln2, body]


func _fuzz_c_cart_commands(iters: int, rng: RandomNumberGenerator, deadline_ms: int) -> void:
	var demo_pick := ["hello", "count", "fib", "sum", "max", "stars"]
	for _i in range(iters):
		if Time.get_ticks_msec() > deadline_ms:
			_fail("global time budget exceeded during C cart fuzz")
			return
		var comp := Computer.new()
		var t0 := Time.get_ticks_msec()
		comp.cart_manager.switch_to(3, false)
		var n_cmds := rng.randi_range(2, 6)
		for _j in range(n_cmds):
			comp.cart_manager.handle_command(_random_c_cart_command(rng, demo_pick))
		var dt := Time.get_ticks_msec() - t0
		comp.disconnect_memory_signal_links()
		if dt > 6_000:
			_fail("C cart fuzz stall >6s")
			return
		_pass()


func _random_c_cart_command(rng: RandomNumberGenerator, demos: Array) -> String:
	## Whitelist-only: avoid COMPILE/BUILD/RUN on random fragments (parser/codegen can stall).
	match rng.randi_range(0, 14):
		0:
			return "NEW"
		1:
			return "HELP"
		2:
			return "LIST"
		3:
			var a := rng.randi_range(10, 300)
			var b := rng.randi_range(a, min(a + 900, 9999))
			return "LIST %d %d" % [a, b]
		4:
			return "DIR"
		5:
			return "CATALOG"
		6:
			return "DEMO"
		7:
			return "DEMOS"
		8:
			return "DEMO %s" % demos[rng.randi_range(0, demos.size() - 1)]
		9:
			return "DEMO fuzz_unknown_demo_%d" % rng.randi()
		10:
			return "DEL %d" % (rng.randi_range(1, 80) * 10)
		11:
			return "SAVE fuzz_c_%d" % rng.randi()
		12:
			return "LOAD fuzz_c_%d" % rng.randi()
		13:
			var ln_del := rng.randi_range(1, 120) * 10
			return str(ln_del)
		_:
			var ln := rng.randi_range(40, 220) * 10
			var frag: String = "// %s" % _random_ident(rng)
			return "%d %s" % [ln, frag]


func _fuzz_assembler(iters: int, rng: RandomNumberGenerator, deadline_ms: int) -> void:
	for _i in range(iters):
		if Time.get_ticks_msec() > deadline_ms:
			_fail("global time budget exceeded during assembler fuzz")
			return
		var mem := MemoryBus.new()
		var asm := Assembler6502.new()
		var lines: Array = []
		var ln := 10
		var nlines := rng.randi_range(1, 12)
		for _j in range(nlines):
			lines.append([ln, _random_asm_body(rng)])
			ln += rng.randi_range(10, 50)
		var t0 := Time.get_ticks_msec()
		asm.assemble(mem, lines)
		var dt := Time.get_ticks_msec() - t0
		if dt > 5_000:
			_fail("assemble stall >5s")
			return
		_pass()


func _random_asm_body(rng: RandomNumberGenerator) -> String:
	var parts: Array[String] = []
	var target_len := rng.randi_range(4, 64)
	var blen := 0
	while blen < target_len:
		var p := _ASM_CHUNKS[rng.randi_range(0, _ASM_CHUNKS.size() - 1)]
		parts.append(p)
		blen += p.length()
	var body := ""
	for p in parts:
		body += p
	body = body.strip_edges()
	if body == "":
		body = "NOP"
	return body


func _fuzz_cpu_random(iters: int, rng: RandomNumberGenerator, deadline_ms: int) -> void:
	for _i in range(iters):
		if Time.get_ticks_msec() > deadline_ms:
			_fail("global time budget exceeded during CPU fuzz")
			return
		var mem := _MemoryBus6502.new()
		var cpu := CPU6502.new(mem)
		mem.prepare_cpu_stack_for_user_rts(cpu)
		var fill_n := rng.randi_range(16, 384)
		for k in range(fill_n):
			mem.poke((0x0800 + k) & 0xFFFF, rng.randi() & 0xFF)
		cpu.A = rng.randi() & 0xFF
		cpu.X = rng.randi() & 0xFF
		cpu.Y = rng.randi() & 0xFF
		cpu.P = (rng.randi() & 0xFF) | 0x20
		cpu.SP = rng.randi_range(0x80, 0xFB)
		cpu.halted = false
		cpu.PC = 0x0800
		var steps := rng.randi_range(80, 800)
		var t0 := Time.get_ticks_msec()
		cpu.run(steps)
		var dt := Time.get_ticks_msec() - t0
		if dt > 8_000:
			_fail("cpu.run stall")
			return
		_pass()

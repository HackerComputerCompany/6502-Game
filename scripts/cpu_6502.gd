class_name CPU6502
extends "res://scripts/cpu.gd"

enum Flag {
	C = 0,
	Z = 1,
	I = 2,
	D = 3,
	B = 4,
	V = 6,
	N = 7,
}

var A: int = 0
var X: int = 0
var Y: int = 0
var SP: int = 0xFD
var P: int = 0x24

var cycles: int = 0

var _opcode_table: Dictionary = {}

func _init(mem: MemoryBus) -> void:
	super(mem)
	cpu_type = "6502"
	PC = 0x0800
	_build_opcode_table()

func reset() -> void:
	A = 0
	X = 0
	Y = 0
	SP = 0xFD
	P = 0x24
	halted = false
	cycles = 0
	PC = memory.peek_word(0xFFFC)

func get_flag(flag: int) -> bool:
	return (P >> flag) & 1 == 1

func set_flag(flag: int, val: bool) -> void:
	if val:
		P |= (1 << flag)
	else:
		P &= ~(1 << flag)

func set_nz(val: int) -> void:
	set_flag(Flag.Z, (val & 0xFF) == 0)
	set_flag(Flag.N, (val & 0x80) != 0)

func _read_byte(addr: int) -> int:
	return memory.peek(addr)

func _read_word(addr: int) -> int:
	return memory.peek(addr) | (memory.peek(addr + 1) << 8)

func _write_byte(addr: int, val: int) -> void:
	memory.poke(addr, val)

func _push(val: int) -> void:
	memory.poke(0x0100 | SP, val & 0xFF)
	SP = (SP - 1) & 0xFF

func _pull() -> int:
	SP = (SP + 1) & 0xFF
	return memory.peek(0x0100 | SP)

func _push_word(val: int) -> void:
	_push((val >> 8) & 0xFF)
	_push(val & 0xFF)

func _pull_word() -> int:
	var lo = _pull()
	var hi = _pull()
	return (hi << 8) | lo

func _get_addr(mode: String) -> int:
	## PC points at opcode; operands always follow at PC+1 (and PC+2 for 16-bit).
	match mode:
		"ZPG":
			return _read_byte(PC + 1)
		"ZPX":
			return (_read_byte(PC + 1) + X) & 0xFF
		"ZPY":
			return (_read_byte(PC + 1) + Y) & 0xFF
		"ABS":
			return _read_word(PC + 1)
		"ABX":
			return (_read_word(PC + 1) + X) & 0xFFFF
		"ABY":
			return (_read_word(PC + 1) + Y) & 0xFFFF
		"IND":
			var ptr = _read_word(PC + 1)
			if (ptr & 0xFF) == 0xFF:
				return (memory.peek(ptr & 0xFF00) << 8) | memory.peek(ptr)
			return _read_word(ptr)
		"IZX":
			var zp = (_read_byte(PC + 1) + X) & 0xFF
			return memory.peek(zp) | (memory.peek((zp + 1) & 0xFF) << 8)
		"IZY":
			var zp = _read_byte(PC + 1)
			return (memory.peek(zp) | (memory.peek((zp + 1) & 0xFF) << 8)) + Y
		"REL":
			var offset = _read_byte(PC + 1)
			if offset >= 0x80:
				offset -= 0x100
			return (PC + 2 + offset) & 0xFFFF
		"IMP", "ACC":
			return 0
	return 0

func _addr_bytes(mode: String) -> int:
	match mode:
		"IMP", "ACC": return 0
		"IMM": return 1
		"ZPG", "ZPX", "ZPY", "IZX", "IZY", "REL": return 1
		"ABS", "ABX", "ABY", "IND": return 2
	return 0

func step() -> void:
	if halted:
		return
	var opcode = _read_byte(PC)
	var entry = _opcode_table.get(opcode, null)
	if entry == null:
		halted = true
		cpu_halted.emit()
		return
	var instr: String = entry[0]
	var mode: String = entry[1]
	var addr = _get_addr(mode)
	var next_pc = PC + 1 + _addr_bytes(mode)
	var val: int
	var result: int
	match instr:
		"LDA":
			if mode == "IMM":
				A = _read_byte(PC + 1)
			else:
				A = _read_byte(addr)
			set_nz(A)
		"LDX":
			if mode == "IMM":
				X = _read_byte(PC + 1)
			else:
				X = _read_byte(addr)
			set_nz(X)
		"LDY":
			if mode == "IMM":
				Y = _read_byte(PC + 1)
			else:
				Y = _read_byte(addr)
			set_nz(Y)
		"STA":
			_write_byte(addr, A)
		"STX":
			_write_byte(addr, X)
		"STY":
			_write_byte(addr, Y)
		"ADC":
			val = _read_byte(PC + 1) if mode == "IMM" else _read_byte(addr)
			result = A + val + (1 if get_flag(Flag.C) else 0)
			set_flag(Flag.C, result > 0xFF)
			set_flag(Flag.V, ((A ^ result) & (val ^ result) & 0x80) != 0)
			A = result & 0xFF
			set_nz(A)
		"SBC":
			val = _read_byte(PC + 1) if mode == "IMM" else _read_byte(addr)
			result = A - val - (0 if get_flag(Flag.C) else 1)
			set_flag(Flag.C, result >= 0)
			set_flag(Flag.V, ((A ^ val) & (A ^ result) & 0x80) != 0)
			A = result & 0xFF
			set_nz(A)
		"AND":
			val = _read_byte(PC + 1) if mode == "IMM" else _read_byte(addr)
			A = A & val
			set_nz(A)
		"ORA":
			val = _read_byte(PC + 1) if mode == "IMM" else _read_byte(addr)
			A = A | val
			set_nz(A)
		"EOR":
			val = _read_byte(PC + 1) if mode == "IMM" else _read_byte(addr)
			A = A ^ val
			set_nz(A)
		"ASL":
			if mode == "ACC":
				set_flag(Flag.C, (A & 0x80) != 0)
				A = (A << 1) & 0xFF
				set_nz(A)
				next_pc = PC + 1
			else:
				val = _read_byte(addr)
				set_flag(Flag.C, (val & 0x80) != 0)
				val = (val << 1) & 0xFF
				_write_byte(addr, val)
				set_nz(val)
		"LSR":
			if mode == "ACC":
				set_flag(Flag.C, (A & 1) != 0)
				A = (A >> 1) & 0xFF
				set_nz(A)
				next_pc = PC + 1
			else:
				val = _read_byte(addr)
				set_flag(Flag.C, (val & 1) != 0)
				val = (val >> 1) & 0xFF
				_write_byte(addr, val)
				set_nz(val)
		"ROL":
			var old_c = get_flag(Flag.C)
			if mode == "ACC":
				set_flag(Flag.C, (A & 0x80) != 0)
				A = ((A << 1) | (1 if old_c else 0)) & 0xFF
				set_nz(A)
				next_pc = PC + 1
			else:
				val = _read_byte(addr)
				set_flag(Flag.C, (val & 0x80) != 0)
				val = ((val << 1) | (1 if old_c else 0)) & 0xFF
				_write_byte(addr, val)
				set_nz(val)
		"ROR":
			var old_c = get_flag(Flag.C)
			if mode == "ACC":
				set_flag(Flag.C, (A & 1) != 0)
				A = ((A >> 1) | (0x80 if old_c else 0)) & 0xFF
				set_nz(A)
				next_pc = PC + 1
			else:
				val = _read_byte(addr)
				set_flag(Flag.C, (val & 1) != 0)
				val = ((val >> 1) | (0x80 if old_c else 0)) & 0xFF
				_write_byte(addr, val)
				set_nz(val)
		"INC":
			val = (_read_byte(addr) + 1) & 0xFF
			_write_byte(addr, val)
			set_nz(val)
		"DEC":
			val = (_read_byte(addr) - 1) & 0xFF
			_write_byte(addr, val)
			set_nz(val)
		"INX":
			X = (X + 1) & 0xFF
			set_nz(X)
		"INY":
			Y = (Y + 1) & 0xFF
			set_nz(Y)
		"DEX":
			X = (X - 1) & 0xFF
			set_nz(X)
		"DEY":
			Y = (Y - 1) & 0xFF
			set_nz(Y)
		"CMP":
			val = _read_byte(PC + 1) if mode == "IMM" else _read_byte(addr)
			result = A - val
			set_flag(Flag.C, A >= val)
			set_nz(result & 0xFF)
		"CPX":
			val = _read_byte(PC + 1) if mode == "IMM" else _read_byte(addr)
			result = X - val
			set_flag(Flag.C, X >= val)
			set_nz(result & 0xFF)
		"CPY":
			val = _read_byte(PC + 1) if mode == "IMM" else _read_byte(addr)
			result = Y - val
			set_flag(Flag.C, Y >= val)
			set_nz(result & 0xFF)
		"BCC":
			if not get_flag(Flag.C):
				next_pc = addr
		"BCS":
			if get_flag(Flag.C):
				next_pc = addr
		"BEQ":
			if get_flag(Flag.Z):
				next_pc = addr
		"BNE":
			if not get_flag(Flag.Z):
				next_pc = addr
		"BMI":
			if get_flag(Flag.N):
				next_pc = addr
		"BPL":
			if not get_flag(Flag.N):
				next_pc = addr
		"BVS":
			if get_flag(Flag.V):
				next_pc = addr
		"BVC":
			if not get_flag(Flag.V):
				next_pc = addr
		"JMP":
			next_pc = addr
		"JSR":
			_push_word(PC + 2)
			next_pc = addr
		"RTS":
			next_pc = _pull_word() + 1
		"RTI":
			P = (_pull() & 0xEF) | 0x20
			next_pc = _pull_word()
		"BIT":
			val = _read_byte(addr)
			set_flag(Flag.Z, (A & val) == 0)
			set_flag(Flag.N, (val & 0x80) != 0)
			set_flag(Flag.V, (val & 0x40) != 0)
		"NOP":
			pass
		"BRK":
			## NMOS BRK pushes PC+2 (opcode + phantom operand byte); IR vectors same as IRQ ($FFFE).
			var pcbrk := (PC + 2) & 0xFFFF
			_push_word(pcbrk)
			_push(P | 0x10)
			set_flag(Flag.I, true)
			next_pc = _read_word(0xFFFE)
		"PHA":
			_push(A)
		"PHP":
			_push(P | 0x30)
		"PLA":
			A = _pull()
			set_nz(A)
		"PLP":
			P = (_pull() & 0xEF) | 0x20
		"TAX":
			X = A
			set_nz(X)
		"TXA":
			A = X
			set_nz(A)
		"TAY":
			Y = A
			set_nz(Y)
		"TYA":
			A = Y
			set_nz(A)
		"TXS":
			SP = X
		"TSX":
			X = SP
			set_nz(X)
		"CLC":
			set_flag(Flag.C, false)
		"SEC":
			set_flag(Flag.C, true)
		"CLD":
			set_flag(Flag.D, false)
		"SED":
			set_flag(Flag.D, true)
		"CLI":
			set_flag(Flag.I, false)
		"SEI":
			set_flag(Flag.I, true)
		"CLV":
			set_flag(Flag.V, false)
		_:
			halted = true
			cpu_halted.emit()
			return
	PC = next_pc & 0xFFFF
	cycles += 1

func run(cycle_limit: int = 100000) -> void:
	var count = 0
	while not halted and count < cycle_limit:
		step()
		count += 1

func get_state() -> Dictionary:
	return {
		"A": A, "X": X, "Y": Y, "SP": SP, "PC": PC, "P": P,
		"C": get_flag(Flag.C), "Z": get_flag(Flag.Z),
		"I": get_flag(Flag.I), "D": get_flag(Flag.D),
		"V": get_flag(Flag.V), "N": get_flag(Flag.N),
	}

func serialize() -> Dictionary:
	return {
		"A": A, "X": X, "Y": Y, "SP": SP, "PC": PC,
		"P": P, "halted": halted, "cycles": cycles,
	}

func deserialize(data: Dictionary) -> void:
	A = int(data.get("A", 0))
	X = int(data.get("X", 0))
	Y = int(data.get("Y", 0))
	SP = int(data.get("SP", 0xFD))
	PC = int(data.get("PC", 0x0800))
	P = int(data.get("P", 0x24))
	halted = data.get("halted", false)
	cycles = int(data.get("cycles", 0))

func _build_opcode_table() -> void:
	var opcodes = {
		0x69: ["ADC", "IMM"], 0x65: ["ADC", "ZPG"], 0x75: ["ADC", "ZPX"],
		0x6D: ["ADC", "ABS"], 0x7D: ["ADC", "ABX"], 0x79: ["ADC", "ABY"],
		0x61: ["ADC", "IZX"], 0x71: ["ADC", "IZY"],
		0xE9: ["SBC", "IMM"], 0xE5: ["SBC", "ZPG"], 0xF5: ["SBC", "ZPX"],
		0xED: ["SBC", "ABS"], 0xFD: ["SBC", "ABX"], 0xF9: ["SBC", "ABY"],
		0xE1: ["SBC", "IZX"], 0xF1: ["SBC", "IZY"],
		0x29: ["AND", "IMM"], 0x25: ["AND", "ZPG"], 0x35: ["AND", "ZPX"],
		0x2D: ["AND", "ABS"], 0x3D: ["AND", "ABX"], 0x39: ["AND", "ABY"],
		0x21: ["AND", "IZX"], 0x31: ["AND", "IZY"],
		0x09: ["ORA", "IMM"], 0x05: ["ORA", "ZPG"], 0x15: ["ORA", "ZPX"],
		0x0D: ["ORA", "ABS"], 0x1D: ["ORA", "ABX"], 0x19: ["ORA", "ABY"],
		0x01: ["ORA", "IZX"], 0x11: ["ORA", "IZY"],
		0x49: ["EOR", "IMM"], 0x45: ["EOR", "ZPG"], 0x55: ["EOR", "ZPX"],
		0x4D: ["EOR", "ABS"], 0x5D: ["EOR", "ABX"], 0x59: ["EOR", "ABY"],
		0x41: ["EOR", "IZX"], 0x51: ["EOR", "IZY"],
		0x0A: ["ASL", "ACC"], 0x06: ["ASL", "ZPG"], 0x16: ["ASL", "ZPX"],
		0x0E: ["ASL", "ABS"], 0x1E: ["ASL", "ABX"],
		0x4A: ["LSR", "ACC"], 0x46: ["LSR", "ZPG"], 0x56: ["LSR", "ZPX"],
		0x4E: ["LSR", "ABS"], 0x5E: ["LSR", "ABX"],
		0x2A: ["ROL", "ACC"], 0x26: ["ROL", "ZPG"], 0x36: ["ROL", "ZPX"],
		0x2E: ["ROL", "ABS"], 0x3E: ["ROL", "ABX"],
		0x6A: ["ROR", "ACC"], 0x66: ["ROR", "ZPG"], 0x76: ["ROR", "ZPX"],
		0x6E: ["ROR", "ABS"], 0x7E: ["ROR", "ABX"],
		0xE6: ["INC", "ZPG"], 0xF6: ["INC", "ZPX"],
		0xEE: ["INC", "ABS"], 0xFE: ["INC", "ABX"],
		0xC6: ["DEC", "ZPG"], 0xD6: ["DEC", "ZPX"],
		0xCE: ["DEC", "ABS"], 0xDE: ["DEC", "ABX"],
		0xA9: ["LDA", "IMM"], 0xA5: ["LDA", "ZPG"], 0xB5: ["LDA", "ZPX"],
		0xAD: ["LDA", "ABS"], 0xBD: ["LDA", "ABX"], 0xB9: ["LDA", "ABY"],
		0xA1: ["LDA", "IZX"], 0xB1: ["LDA", "IZY"],
		0xA2: ["LDX", "IMM"], 0xA6: ["LDX", "ZPG"], 0xB6: ["LDX", "ZPY"],
		0xAE: ["LDX", "ABS"], 0xBE: ["LDX", "ABY"],
		0xA0: ["LDY", "IMM"], 0xA4: ["LDY", "ZPG"], 0xB4: ["LDY", "ZPX"],
		0xAC: ["LDY", "ABS"], 0xBC: ["LDY", "ABX"],
		0x85: ["STA", "ZPG"], 0x95: ["STA", "ZPX"],
		0x8D: ["STA", "ABS"], 0x9D: ["STA", "ABX"], 0x99: ["STA", "ABY"],
		0x81: ["STA", "IZX"], 0x91: ["STA", "IZY"],
		0x86: ["STX", "ZPG"], 0x96: ["STX", "ZPY"], 0x8E: ["STX", "ABS"],
		0x84: ["STY", "ZPG"], 0x94: ["STY", "ZPX"], 0x8C: ["STY", "ABS"],
		0xC9: ["CMP", "IMM"], 0xC5: ["CMP", "ZPG"], 0xD5: ["CMP", "ZPX"],
		0xCD: ["CMP", "ABS"], 0xDD: ["CMP", "ABX"], 0xD9: ["CMP", "ABY"],
		0xC1: ["CMP", "IZX"], 0xD1: ["CMP", "IZY"],
		0xE0: ["CPX", "IMM"], 0xE4: ["CPX", "ZPG"], 0xEC: ["CPX", "ABS"],
		0xC0: ["CPY", "IMM"], 0xC4: ["CPY", "ZPG"], 0xCC: ["CPY", "ABS"],
		0x90: ["BCC", "REL"], 0xB0: ["BCS", "REL"],
		0xF0: ["BEQ", "REL"], 0xD0: ["BNE", "REL"],
		0x30: ["BMI", "REL"], 0x10: ["BPL", "REL"],
		0x70: ["BVS", "REL"], 0x50: ["BVC", "REL"],
		0x4C: ["JMP", "ABS"], 0x6C: ["JMP", "IND"],
		0x20: ["JSR", "ABS"],
		0x60: ["RTS", "IMP"],
		0x40: ["RTI", "IMP"],
		0x24: ["BIT", "ZPG"], 0x2C: ["BIT", "ABS"],
		0xEA: ["NOP", "IMP"],
		0x00: ["BRK", "IMP"],
		0x48: ["PHA", "IMP"], 0x08: ["PHP", "IMP"],
		0x68: ["PLA", "IMP"], 0x28: ["PLP", "IMP"],
		0xAA: ["TAX", "IMP"], 0x8A: ["TXA", "IMP"],
		0xA8: ["TAY", "IMP"], 0x98: ["TYA", "IMP"],
		0x9A: ["TXS", "IMP"], 0xBA: ["TSX", "IMP"],
		0x18: ["CLC", "IMP"], 0x38: ["SEC", "IMP"],
		0xD8: ["CLD", "IMP"], 0xF8: ["SED", "IMP"],
		0x58: ["CLI", "IMP"], 0x78: ["SEI", "IMP"],
		0xB8: ["CLV", "IMP"],
		0xE8: ["INX", "IMP"], 0xC8: ["INY", "IMP"],
		0xCA: ["DEX", "IMP"], 0x88: ["DEY", "IMP"],
	}
	for opcode in opcodes:
		_opcode_table[opcode] = opcodes[opcode]

func disassemble(addr: int, count: int = 1) -> Array:
	var results = []
	for _i in range(count):
		if addr > 0xFFFF:
			break
		var opcode = memory.peek(addr)
		var entry = _opcode_table.get(opcode, null)
		var line_str: String
		var line_addr = addr
		if entry == null:
			line_str = "???"
			addr += 1
		else:
			var instr = entry[0]
			var mode = entry[1]
			var nbytes = 1 + _addr_bytes(mode)
			var operand_str = _format_operand(addr, mode)
			line_str = instr + " " + operand_str
			addr += nbytes
		results.append({"addr": line_addr, "disasm": line_str})
	return results

func _format_operand(addr: int, mode: String) -> String:
	match mode:
		"IMP":
			return ""
		"ACC":
			return "A"
		"IMM":
			return "#$" + _hex(memory.peek(addr + 1), 2)
		"ZPG":
			return "$" + _hex(memory.peek(addr + 1), 2)
		"ZPX":
			return "$" + _hex(memory.peek(addr + 1), 2) + ",X"
		"ZPY":
			return "$" + _hex(memory.peek(addr + 1), 2) + ",Y"
		"ABS":
			return "$" + _hex(memory.peek_word(addr + 1), 4)
		"ABX":
			return "$" + _hex(memory.peek_word(addr + 1), 4) + ",X"
		"ABY":
			return "$" + _hex(memory.peek_word(addr + 1), 4) + ",Y"
		"IND":
			return "($" + _hex(memory.peek_word(addr + 1), 4) + ")"
		"IZX":
			return "($" + _hex(memory.peek(addr + 1), 2) + ",X)"
		"IZY":
			return "($" + _hex(memory.peek(addr + 1), 2) + "),Y"
		"REL":
			var offset = memory.peek(addr + 1)
			if offset >= 128:
				offset = offset - 256
			var target = (addr + 2 + offset) & 0xFFFF
			return "$" + _hex(target, 4)
		_:
			return ""

func _hex(val: int, digits: int) -> String:
	var s = ("%0" + str(digits) + "X") % val
	return s

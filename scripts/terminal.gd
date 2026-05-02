extends Control

@onready var screen: RichTextLabel = $VBoxContainer/Screen
@onready var input_line: LineEdit = $VBoxContainer/InputLine
@onready var status_bar: Label = $VBoxContainer/StatusBar
@onready var title_bar: Label = $VBoxContainer/TopBar/TitleBar
@onready var baud_label: Label = $VBoxContainer/TopBar/BaudLabel
@onready var font_label: Label = $VBoxContainer/TopBar/FontLabel

var computer: Computer
var sound: SoundManager
var command_history: Array = []
var history_pos: int = -1

var _base_font_size: int = 18

var _available_fonts: Array = [
	{"name": "Press Start 2P", "path": "res://fonts/pressstart2p.ttf", "type": "terminal"},
	{"name": "VT323", "path": "res://fonts/vt323.ttf", "type": "terminal"},
	{"name": "Share Tech Mono", "path": "res://fonts/sharetechmono.ttf", "type": "terminal"},
	{"name": "IBM Plex Mono", "path": "res://fonts/ibmplexmono.ttf", "type": "mono"},
]
var _current_font_idx: int = 0

var _baud_rates: Array = [300, 1200, 2400, 9600, 14400]
var _current_baud_idx: int = 2

var _output_queue: String = ""
var _output_timer: float = 0.0
var _is_streaming: bool = false

var _instant_output: bool = false
var debug: DebugManager
var _debug_visible: bool = false

var _fonts_loaded: bool = false

func _ready() -> void:
	computer = Computer.new()
	computer.output.connect(_on_output)
	sound = SoundManager.new()
	add_child(sound)
	debug = DebugManager.new()
	add_child(debug)
	input_line.text_submitted.connect(_on_input_line_text_submitted)
	input_line.grab_focus()
	_print_banner()
	_update_status()
	_update_baud_label()
	_update_font_label()
	call_deferred("_apply_font_deferred")

func _apply_font_deferred() -> void:
	if _fonts_loaded:
		return
	_apply_font()
	_fonts_loaded = true

func _process(delta: float) -> void:
	if debug.is_recording():
		var fc = debug.get_frame_count()
		if fc % 30 == 0:
			_update_status()
	if _is_streaming and _output_queue.length() > 0:
		var chars_per_second = float(_baud_rates[_current_baud_idx]) / 10.0
		var chars_this_frame = max(1, int(chars_per_second * delta))
		var num_chars = mini(chars_this_frame, _output_queue.length())
		var text_to_show = _output_queue.substr(0, num_chars)
		_output_queue = _output_queue.substr(num_chars)
		_stream_char_by_char(text_to_show)
		if _output_queue.length() == 0:
			_is_streaming = false
	else:
		_is_streaming = false

func _stream_char_by_char(text: String) -> void:
	for ch in text:
		match ch:
			"\n":
				sound.play_line_feed()
			"\a":
				sound.play_bell()
				continue
			_:
				sound.play_key()
		var escaped = ch
		escaped = escaped.replace("&", "&amp;")
		escaped = escaped.replace("[", "&lsqb;")
		escaped = escaped.replace("]", "&rsqb;")
		screen.append_text("[color=lime]" + escaped + "[/color]")
	screen.scroll_to_line(screen.get_line_count() - 1)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		input_line.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			if history_pos > 0:
				history_pos -= 1
				input_line.text = command_history[history_pos]
				input_line.caret_column = input_line.text.length()
		elif event.keycode == KEY_DOWN:
			if history_pos < command_history.size() - 1:
				history_pos += 1
				input_line.text = command_history[history_pos]
			else:
				history_pos = command_history.size()
				input_line.text = ""
			input_line.caret_column = input_line.text.length()
		elif event.keycode == KEY_F1:
			_show_help()
		elif event.keycode == KEY_F5:
			_run_program()
			input_line.grab_focus()
		elif event.keycode == KEY_F10:
			computer.reset()
			screen.clear()
			_print_banner()
			_update_status()
			input_line.grab_focus()
		elif event.keycode == KEY_F7:
			_current_baud_idx = (_current_baud_idx + 1) % _baud_rates.size()
			_update_baud_label()
		elif event.keycode == KEY_F8:
			_current_font_idx = (_current_font_idx + 1) % _available_fonts.size()
			_apply_font()
			_update_font_label()
		elif event.keycode == KEY_F9:
			var path = debug.take_screenshot()
			_instant_output = true
			screen.append_text("\n[color=cyan]Screenshot: " + path + "[/color]\n")
			_instant_output = false
		elif event.keycode == KEY_F6:
			debug.toggle_recording()
			_instant_output = true
			if debug.is_recording():
				screen.append_text("\n[color=yellow] Recording ON (F6 to stop) [/color]\n")
			else:
				screen.append_text("\n[color=yellow] Recording OFF - frames saved [/color]\n")
			_instant_output = false

func _print_banner() -> void:
	_instant_output = true
	screen.append_text("[color=green][b]BASIC6502[/b] - 6502-Powered BASIC Environment[/color]\n")
	screen.append_text("[color=green]Version 1.4 | 64KB RAM | 6502 CPU @ 1MHz | ROM Active[/color]\n")
	screen.append_text("[color=green]F1=Help F5=Run F6=Rec F9=SS F7=Baud F8=Font F10=Reset[/color]\n")
	screen.append_text("[color=green]Type DEMO to list built-in programs, DEMO name to load one.\n\n[/color]")
	screen.append_text("[color=lime]READY.\n[/color]")
	_instant_output = false

func _on_output(text: String) -> void:
	if text == "[CLR]":
		screen.clear()
		return
	if _instant_output:
		var escaped = text
		escaped = escaped.replace("&", "&amp;")
		escaped = escaped.replace("[", "&lsqb;")
		escaped = escaped.replace("]", "&rsqb;")
		screen.append_text("[color=lime]" + escaped + "[/color]")
		screen.scroll_to_line(screen.get_line_count() - 1)
		return
	_output_queue += text
	_is_streaming = true

func _update_status() -> void:
	var state = computer.cpu.get_state()
	var rec = " [REC]" if debug.is_recording() else ""
	status_bar.text = "A:%02X X:%02X Y:%02X SP:%02X PC:%04X %s%s-%s%s%s%s%s%s | MEM:64K%s | F7=Baud F8=Font" % [
		state.A, state.X, state.Y, state.SP, state.PC,
		"C" if state.C else ".", "Z" if state.Z else ".",
		"I" if state.I else ".", "D" if state.D else ".",
		".", "V" if state.V else ".", "N" if state.N else ".", ".",
		rec
	]

func _update_baud_label() -> void:
	var rate = _baud_rates[_current_baud_idx]
	if rate >= 14400:
		baud_label.text = "%d BAUD" % rate
	else:
		baud_label.text = "%d BAUD" % rate
	sound.play_bell()

func _update_font_label() -> void:
	font_label.text = "FONT: " + _available_fonts[_current_font_idx]["name"]

func _apply_font() -> void:
	var font_info = _available_fonts[_current_font_idx]
	var path = font_info["path"]
	var dynamic_font = FontFile.new()
	var err = dynamic_font.load_dynamic_font(path)
	if err != OK:
		if not _fonts_loaded:
			get_tree().create_timer(0.2).timeout.connect(_apply_font_deferred)
		return
	_fonts_loaded = true
	var font_size = _base_font_size
	if font_info["name"] == "Press Start 2P":
		font_size = max(_base_font_size - 4, 10)
	screen.add_theme_font_override("normal_font", dynamic_font)
	screen.add_theme_font_size_override("normal_font_size", font_size)
	input_line.add_theme_font_size_override("font_size", font_size)
	sound.play_key()

func _on_input_line_text_submitted(text: String) -> void:
	if text.strip_edges() == "":
		return
	sound.play_carriage()
	command_history.append(text)
	history_pos = command_history.size()
	input_line.clear()
	_handle_command(text.strip_edges())
	_instant_output = true
	screen.append_text("[color=lime]\nREADY.\n[/color]")
	_instant_output = false
	input_line.grab_focus()

func _handle_command(text: String) -> void:
	var upper = text.to_upper()
	if upper == "HELP":
		_show_help()
	elif upper == "CLEAR" or upper == "CLS":
		screen.clear()
	elif upper == "RESET":
		computer.reset()
		screen.clear()
		_print_banner()
		_update_status()
	elif upper == "NEW":
		computer.reset()
		_update_status()
	elif upper == "LIST":
		_list_program()
	elif upper.begins_with("RUN"):
		_run_program()
	elif upper.begins_with("SAVE "):
		_save_program(text.substr(5).strip_edges())
	elif upper.begins_with("LOAD "):
		_load_program(text.substr(5).strip_edges())
	elif upper == "DIR" or upper == "CATALOG":
		_show_catalog()
	elif upper == "DEMO" or upper == "DEMOS":
		_show_demos()
	elif upper.begins_with("DEMO ") or upper.begins_with("DEMOS "):
		var demo_name = text.substr(5).strip_edges().to_lower()
		_load_demo(demo_name)
	elif upper == "CPU":
		_show_cpu_state()
	elif upper.begins_with("PEEK("):
		_peek_command(text)
	elif upper.begins_with("SYS"):
		_sys_command(text)
	elif text[0].is_valid_int():
		_add_program_line(text)
		sound.play_key()
	else:
		computer.execute_basic_line(text)
	_update_status()

func _show_help() -> void:
	_instant_output = true
	var help_text = "\n[color=cyan][b]BASIC6502 Commands:[/b][/color]\n"
	help_text += "[color=yellow]  RUN       [/color]- Run the current program\n"
	help_text += "[color=yellow]  LIST      [/color]- List the current program\n"
	help_text += "[color=yellow]  NEW       [/color]- Clear the program and variables\n"
	help_text += "[color=yellow]  CLEAR     [/color]- Clear the screen\n"
	help_text += "[color=yellow]  RESET     [/color]- Full system reset\n"
	help_text += "[color=yellow]  CPU       [/color]- Show CPU registers\n"
	help_text += "[color=yellow]  SAVE name [/color]- Save program to disk\n"
	help_text += "[color=yellow]  LOAD name [/color]- Load program from disk\n"
	help_text += "[color=yellow]  DIR       [/color]- List saved programs\n"
	help_text += "[color=yellow]  DEMO      [/color]- List built-in demo programs\n"
	help_text += "[color=yellow]  DEMO name [/color]- Load a demo program\n"
	help_text += "[color=yellow]  SYS addr  [/color]- Execute machine code at address\n"
	help_text += "[color=yellow]  PEEK(addr)[/color]- Read memory location\n"
	help_text += "\n[color=cyan][b]Keyboard Shortcuts:[/b][/color]\n"
	help_text += "[color=yellow]  F7  [/color]- Cycle baud rate (300/1200/2400/9600/14400)\n"
	help_text += "[color=yellow]  F8  [/color]- Cycle font (VT323/Press Start 2P/Share Tech/IBM Plex)\n"
	help_text += "[color=yellow]  F9  [/color]- Take screenshot (saved to user://debug/screenshots/)\n"
	help_text += "[color=yellow]  F6  [/color]- Start/stop video recording\n"
	help_text += "[color=yellow]  F1  [/color]- Show this help\n"
	help_text += "[color=yellow]  F5  [/color]- Run program\n"
	help_text += "[color=yellow]  F10 [/color]- Reset system\n"
	help_text += "\n[color=cyan][b]BASIC Statements:[/b][/color]\n"
	help_text += "[color=yellow]  PRINT, INPUT, GOTO, GOSUB, RETURN[/color]\n"
	help_text += "[color=yellow]  FOR..TO..STEP..NEXT, IF..THEN[/color]\n"
	help_text += "[color=yellow]  LET, DIM, READ, DATA, RESTORE[/color]\n"
	help_text += "[color=yellow]  POKE, ON..GOTO/GOSUB, END[/color]\n"
	help_text += "\n[color=cyan][b]BASIC Functions:[/b][/color]\n"
	help_text += "[color=yellow]  INT(), RND(), ABS(), SQR(), SIN(), COS()[/color]\n"
	help_text += "[color=yellow]  TAN(), ATN(), LOG(), EXP(), SGN()[/color]\n"
	help_text += "[color=yellow]  LEN(), CHR$(), ASC(), LEFT$(), RIGHT$()[/color]\n"
	help_text += "[color=yellow]  MID$(), STR$(), VAL(), PEEK(), TAB()[/color]\n\n"
	screen.append_text(help_text)
	_instant_output = false

func _list_program() -> void:
	var prog = computer.basic._program
	if prog.size() == 0:
		screen.append_text("[color=yellow]No program in memory.\n[/color]")
		return
	_instant_output = true
	var text = "\n"
	for entry in prog:
		text += "[color=white]%5d %s\n[/color]" % [entry[0], entry[1]]
	text += "\n"
	screen.append_text(text)
	_instant_output = false

func _run_program() -> void:
	screen.append_text("\n")
	var prog_lines: Array = []
	for entry in computer.basic._program:
		prog_lines.append(str(entry[0]) + " " + str(entry[1]))
	var program = "\n".join(prog_lines)
	computer.run_basic(program)

func _add_program_line(text: String) -> void:
	pass

func _save_program(filename: String) -> void:
	if filename == "":
		sound.play_error()
		screen.append_text("[color=red]ERROR: MISSING FILENAME\n[/color]")
		return
	var save_data: Dictionary = {}
	var prog_lines: Array = []
	for entry in computer.basic._program:
		prog_lines.append({"line": entry[0], "code": entry[1]})
	save_data["program"] = prog_lines
	var json_str = JSON.stringify(save_data, "\t")
	var file = FileAccess.open("user://" + filename + ".bas", FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		screen.append_text("[color=lime]SAVED: " + filename + "\n[/color]")
	else:
		sound.play_error()
		screen.append_text("[color=red]ERROR: CANNOT SAVE FILE\n[/color]")

func _load_program(filename: String) -> void:
	if filename == "":
		sound.play_error()
		screen.append_text("[color=red]ERROR: MISSING FILENAME\n[/color]")
		return
	var file = FileAccess.open("user://" + filename + ".bas", FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		var result = json.parse(json_str)
		if result == OK:
			var data = json.data
			var prog_text = ""
			for entry in data["program"]:
				prog_text += str(entry["line"]) + " " + str(entry["code"]) + "\n"
			computer.run_basic(prog_text)
			screen.append_text("[color=lime]LOADED: " + filename + "\n[/color]")
		else:
			sound.play_error()
			screen.append_text("[color=red]ERROR: INVALID FILE FORMAT\n[/color]")
	else:
		sound.play_error()
		screen.append_text("[color=red]ERROR: FILE NOT FOUND\n[/color]")

func _show_catalog() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		_instant_output = true
		screen.append_text("\n[color=cyan][b]SAVED PROGRAMS:[/b][/color]\n")
		var count = 0
		while file_name != "":
			if file_name.ends_with(".bas"):
				screen.append_text("[color=yellow]  " + file_name.replace(".bas", "") + "\n[/color]")
				count += 1
			file_name = dir.get_next()
		if count == 0:
			screen.append_text("[color=yellow]  (none)\n[/color]")
		screen.append_text("\n")
		dir.list_dir_end()
		_instant_output = false

func _show_cpu_state() -> void:
	_instant_output = true
	var state = computer.cpu.get_state()
	var text = "\n[color=cyan][b]6502 CPU STATE:[/b][/color]\n"
	text += "[color=white]  A:  $%02X (%d)\n[/color]" % [state.A, state.A]
	text += "[color=white]  X:  $%02X (%d)\n[/color]" % [state.X, state.X]
	text += "[color=white]  Y:  $%02X (%d)\n[/color]" % [state.Y, state.Y]
	text += "[color=white]  SP: $%02X\n[/color]" % state.SP
	text += "[color=white]  PC: $%04X\n[/color]" % state.PC
	text += "[color=white]  Flags: %s%s-%s%s%s%s%s%s\n[/color]" % [
		"C" if state.C else ".", "Z" if state.Z else ".",
		"I" if state.I else ".", "D" if state.D else ".",
		".", "V" if state.V else ".", "N" if state.N else ".", "."
	]
	text += "\n"
	screen.append_text(text)
	_instant_output = false

func _show_demos() -> void:
	_instant_output = true
	var text = "\n[color=cyan][b]BUILT-IN DEMO PROGRAMS:[/b][/color]\n"
	text += "[color=yellow]  Type DEMO name to load, then RUN[/color]\n\n"
	var demos = computer.rom.get_demo_list()
	for d in demos:
		text += "[color=white]  %-14s[/color] %s\n" % [d["name"], d["desc"]]
	text += "\n[color=cyan][b]ROM ROUTINES (use with SYS):[/b][/color]\n"
	text += "[color=white]  $F000[/color]  Warm boot (prints message)\n"
	text += "[color=white]  $F040[/color]  Counter (prints 0-9)\n"
	text += "[color=white]  $F060[/color]  Add 2 to accumulator\n"
	text += "[color=white]  $F080[/color]  Fibonacci (8 terms)\n"
	text += "[color=white]  $F0C0[/color]  Scroll animation (infinite loop)\n"
	text += "[color=white]  $F100[/color]  Hex output (A register)\n"
	text += "[color=white]  $F020[/color]  Print char (A register -> screen)\n"
	text += "[color=white]  $F030[/url]  Print string ($1C/$1D = ptr, Y=index)\n\n"
	screen.append_text(text)
	_instant_output = false

func _load_demo(name: String) -> void:
	var program = computer.load_demo(name)
	if program != "":
		_instant_output = true
		screen.append_text("[color=lime]Loading demo: " + name + "\n[/color]")
		_instant_output = false
		computer.run_basic("")
		computer.basic.load_program(program)
		_list_program()
		screen.append_text("[color=lime]Type RUN to execute.\n[/color]")
		sound.play_bell()
	else:
		screen.append_text("[color=red]ERROR: DEMO NOT FOUND. Type DEMO to list available demos.\n[/color]")

func _peek_command(text: String) -> void:
	computer.execute_basic_line(text)

func _sys_command(text: String) -> void:
	computer.execute_basic_line(text)
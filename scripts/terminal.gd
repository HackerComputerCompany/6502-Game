extends Control

@onready var screen: RichTextLabel = $VBoxContainer/Screen
@onready var input_line: LineEdit = $VBoxContainer/InputLine
@onready var status_bar: Label = $VBoxContainer/StatusBar
@onready var title_bar: Label = $VBoxContainer/TitleBar

var computer: Computer
var command_history: Array = []
var history_pos: int = -1
var program_mode: bool = false
var program_buffer: String = ""
var _base_font_size: int = 18

func _ready() -> void:
	computer = Computer.new()
	computer.output.connect(_on_output)
	input_line.text_submitted.connect(_on_input_line_text_submitted)
	input_line.grab_focus()
	_print_banner()
	_update_status()
	_scale_fonts()

func _on_resized() -> void:
	_scale_fonts()

func _scale_fonts() -> void:
	var root_size = get_viewport().get_visible_rect().size
	var scale_factor = min(root_size.x / 1280.0, root_size.y / 960.0)
	scale_factor = clamp(scale_factor, 0.5, 3.0)
	var font_size = int(_base_font_size * scale_factor)
	font_size = max(font_size, 10)
	screen.add_theme_font_size_override("normal_font_size", font_size)
	screen.add_theme_font_size_override("mono_font_size", font_size)
	input_line.add_theme_font_size_override("font_size", font_size)
	title_bar.add_theme_font_size_override("font_size", max(font_size - 2, 10))
	status_bar.add_theme_font_size_override("font_size", max(font_size - 4, 10))

func _print_banner() -> void:
	screen.append_text("[color=green][b]BASIC6502[/b] - 6502-Powered BASIC Environment[/color]\n")
	screen.append_text("[color=green]Version 1.0 | 64KB RAM | 6502 CPU @ 1MHz[/color]\n")
	screen.append_text("[color=green]Type HELP for commands, or start coding!\n\n[/color]")
	screen.append_text("[color=lime]READY.[/color]\n")

func _on_output(text: String) -> void:
	if text == "[CLR]":
		screen.clear()
		return
	text = text.replace("&", "&amp;")
	text = text.replace("[", "&lsqb;")
	text = text.replace("]", "&rsqb;")
	screen.append_text("[color=lime]" + text + "[/color]")
	await get_tree().process_frame
	screen.scroll_to_line(screen.get_line_count() - 1)

func _update_status() -> void:
	var state = computer.cpu.get_state()
	status_bar.text = "A:%02X X:%02X Y:%02X SP:%02X PC:%04X P:%c%c%c%c%c%c%c%c | MEM:64K" % [
		state.A, state.X, state.Y, state.SP, state.PC,
		"-" if not state.C else "C",
		"-" if not state.Z else "Z",
		"-" if not state.I else "I",
		"-" if not state.D else "D",
		"-", 
		"-" if not state.V else "V",
		"-" if not state.N else "N",
		"-", "-"
	]

func _on_input_line_text_submitted(text: String) -> void:
	if text.strip_edges() == "":
		return
	command_history.append(text)
	history_pos = command_history.size()
	input_line.clear()
	_handle_command(text.strip_edges())

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
		screen.append_text("[color=lime]\nREADY.\n[/color]")
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
	elif upper == "CPU":
		_show_cpu_state()
	elif upper.begins_with("PEEK("):
		_peek_command(text)
	elif upper.begins_with("SYS"):
		_sys_command(text)
	elif text[0].is_valid_int():
		_add_program_line(text)
	else:
		computer.execute_basic_line(text)
	_update_status()

func _show_help() -> void:
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
	help_text += "[color=yellow]  SYS addr  [/color]- Execute machine code at address\n"
	help_text += "[color=yellow]  PEEK(addr)[/color]- Read memory location\n"
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

func _list_program() -> void:
	var prog = computer.basic._program
	if prog.size() == 0:
		screen.append_text("[color=yellow]No program in memory.\n[/color]")
		return
	var text = "\n"
	for entry in prog:
		text += "[color=white]%5d %s\n[/color]" % [entry[0], entry[1]]
	text += "\n"
	screen.append_text(text)

func _run_program() -> void:
	screen.append_text("\n")
	computer.run_basic("")
	var prog_lines: Array = []
	for entry in computer.basic._program:
		prog_lines.append(str(entry[0]) + " " + str(entry[1]))
	var program = "\n".join(prog_lines)
	computer.run_basic(program)
	screen.append_text("[color=lime]\nREADY.\n[/color]")

func _add_program_line(text: String) -> void:
	screen.append_text("[color=lime]\n[/color]")

func _save_program(filename: String) -> void:
	if filename == "":
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
		screen.append_text("[color=red]ERROR: CANNOT SAVE FILE\n[/color]")

func _load_program(filename: String) -> void:
	if filename == "":
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
			screen.append_text("[color=red]ERROR: INVALID FILE FORMAT\n[/color]")
	else:
		screen.append_text("[color=red]ERROR: FILE NOT FOUND\n[/color]")

func _show_catalog() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
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

func _show_cpu_state() -> void:
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

func _peek_command(text: String) -> void:
	computer.execute_basic_line(text)

func _sys_command(text: String) -> void:
	computer.execute_basic_line(text)

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
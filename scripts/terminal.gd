extends Control

@onready var screen: RichTextLabel = $VBoxContainer/Screen
@onready var input_line: LineEdit = $VBoxContainer/InputLine
@onready var status_bar: Label = $VBoxContainer/StatusBar
@onready var title_bar: Label = $VBoxContainer/TopBar/TitleBar
@onready var baud_label: Label = $VBoxContainer/TopBar/BaudLabel
@onready var font_label: Label = $VBoxContainer/TopBar/FontLabel
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var curvature_slider: HSlider = $SettingsPanel/VBoxContainer/CurvatureSlider
@onready var curvature_label: Label = $SettingsPanel/VBoxContainer/CurvatureLabel
@onready var scanline_slider: HSlider = $SettingsPanel/VBoxContainer/ScanlineSlider
@onready var scanline_label: Label = $SettingsPanel/VBoxContainer/ScanlineLabel
@onready var vignette_slider: HSlider = $SettingsPanel/VBoxContainer/VignetteSlider
@onready var vignette_label: Label = $SettingsPanel/VBoxContainer/VignetteLabel
@onready var glow_slider: HSlider = $SettingsPanel/VBoxContainer/GlowSlider
@onready var glow_label: Label = $SettingsPanel/VBoxContainer/GlowLabel
@onready var flicker_slider: HSlider = $SettingsPanel/VBoxContainer/FlickerSlider
@onready var flicker_label: Label = $SettingsPanel/VBoxContainer/FlickerLabel
@onready var reset_btn: Button = $SettingsPanel/VBoxContainer/ResetBtn
@onready var save_btn: Button = $SettingsPanel/VBoxContainer/SaveBtn
@onready var load_btn: Button = $SettingsPanel/VBoxContainer/LoadBtn
@onready var crt_overlay: ColorRect = $CRTOverlay

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

var _clock_speeds: Array = [0.5, 1.0, 10.0]
var _clock_labels: Array = ["0.5 MHz", "1 MHz", "10 MHz"]
var _current_clock_idx: int = 1

var _cycles_per_line: int = 1000

var _output_queue: String = ""
var _output_timer: float = 0.0
var _is_streaming: bool = false

var _instant_output: bool = false
var debug: DebugManager
var _debug_visible: bool = false

var _fonts_loaded: bool = false

const SAVE_PATH = "user://savestate.json"

const WARMUP_DURATION: float = 120.0
const BOOT_DURATION: float = 5.0

var _warmup_elapsed: float = 0.0
var _boot_elapsed: float = 0.0
var _boot_phase: int = 0
var _boot_done: bool = false
var _warmup_done: bool = false
var _input_buffer: String = ""

const COLD_CURVATURE: float = 0.10
const COLD_SCANLINE: float = 0.15
const COLD_VIGNETTE: float = 1.0
const COLD_GLOW: float = 0.6
const COLD_FLICKER: float = 0.05

func _ready() -> void:
	computer = Computer.new()
	computer.output.connect(_on_output)
	computer.program_finished.connect(_on_program_finished)
	sound = SoundManager.new()
	add_child(sound)
	debug = DebugManager.new()
	add_child(debug)
	input_line.text_submitted.connect(_on_input_line_text_submitted)
	curvature_slider.value_changed.connect(_on_curvature_changed)
	scanline_slider.value_changed.connect(_on_scanline_changed)
	vignette_slider.value_changed.connect(_on_vignette_changed)
	glow_slider.value_changed.connect(_on_glow_changed)
	flicker_slider.value_changed.connect(_on_flicker_changed)
	reset_btn.pressed.connect(_on_reset_settings)
	save_btn.pressed.connect(_on_save_state)
	load_btn.pressed.connect(_on_load_state)
	input_line.grab_focus()
	_update_status()
	_update_baud_label()
	_update_font_label()
	call_deferred("_apply_font_deferred")
	call_deferred("_load_state_silent")
	call_deferred("_start_cold_boot")

func _start_cold_boot() -> void:
	if _warmup_done:
		_on_curvature_changed(curvature_slider.value)
		_on_scanline_changed(scanline_slider.value)
		_on_vignette_changed(vignette_slider.value)
		_on_glow_changed(glow_slider.value)
		_on_flicker_changed(flicker_slider.value)
		return
	crt_overlay.material.set_shader_parameter("crt_curvature", COLD_CURVATURE)
	crt_overlay.material.set_shader_parameter("scanline_intensity", COLD_SCANLINE)
	crt_overlay.material.set_shader_parameter("vignette_intensity", COLD_VIGNETTE)
	crt_overlay.material.set_shader_parameter("glow_intensity", COLD_GLOW)
	crt_overlay.material.set_shader_parameter("flicker_intensity", COLD_FLICKER)

func _apply_font_deferred() -> void:
	if _fonts_loaded:
		return
	_apply_font()
	_fonts_loaded = true

func _process(delta: float) -> void:
	if not _warmup_done:
		_process_warmup(delta)
	if not _boot_done:
		_process_boot(delta)
	if computer._program_running and not computer._awaiting_input:
		var mhz = _clock_speeds[_current_clock_idx]
		var lines_per_frame = max(1, int((mhz * 1e6) / _cycles_per_line / 60.0))
		computer.step_basic(lines_per_frame)
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
	if not input_line.has_focus() and _boot_done:
		input_line.grab_focus()

func _process_warmup(delta: float) -> void:
	_warmup_elapsed += delta
	var t = clampf(_warmup_elapsed / WARMUP_DURATION, 0.0, 1.0)
	var ease_t = 1.0 - pow(1.0 - t, 3.0)
	var curv = lerpf(COLD_CURVATURE, curvature_slider.value, ease_t)
	var scan = lerpf(COLD_SCANLINE, scanline_slider.value, ease_t)
	var vig = lerpf(COLD_VIGNETTE, vignette_slider.value, ease_t)
	var glow = lerpf(COLD_GLOW, glow_slider.value, ease_t)
	var flick = lerpf(COLD_FLICKER, flicker_slider.value, ease_t)
	crt_overlay.material.set_shader_parameter("crt_curvature", curv)
	crt_overlay.material.set_shader_parameter("scanline_intensity", scan)
	crt_overlay.material.set_shader_parameter("vignette_intensity", vig)
	crt_overlay.material.set_shader_parameter("glow_intensity", glow)
	crt_overlay.material.set_shader_parameter("flicker_intensity", flick)
	if _warmup_elapsed >= WARMUP_DURATION:
		_warmup_done = true
		_on_curvature_changed(curvature_slider.value)
		_on_scanline_changed(scanline_slider.value)
		_on_vignette_changed(vignette_slider.value)
		_on_glow_changed(glow_slider.value)
		_on_flicker_changed(flicker_slider.value)

func _process_boot(delta: float) -> void:
	_boot_elapsed += delta
	var phases = [
		{"time": 0.0, "msg": null},
		{"time": 0.5, "msg": "[color=green][b]BASIC6502 BIOS v1.4[/b][/color]\n"},
		{"time": 1.2, "msg": "[color=green]Testing RAM... 65536 bytes OK[/color]\n"},
		{"time": 2.0, "msg": "[color=green]6502 CPU @ 1MHz... OK[/color]\n"},
		{"time": 2.6, "msg": "[color=green]ROM at $F000... OK[/color]\n"},
		{"time": 3.2, "msg": "[color=green]I/O ports $C000-$C030... OK[/color]\n"},
		{"time": 4.0, "msg": null},
		{"time": 5.0, "msg": null},
	]
	if _boot_phase < phases.size() and _boot_elapsed >= phases[_boot_phase].time:
		var msg = phases[_boot_phase].msg
		_boot_phase += 1
		if msg != null:
			_instant_output = true
			screen.append_text(msg)
			_instant_output = false
			sound.play_key()
	if _boot_elapsed >= BOOT_DURATION:
		_boot_done = true
		_print_banner()
		_flush_input_buffer()
		input_line.grab_focus()

func _flush_input_buffer() -> void:
	if _input_buffer == "":
		return
	var lines = _input_buffer.split("\n")
	_input_buffer = ""
	for line in lines:
		line = line.strip_edges()
		if line == "":
			continue
		command_history.append(line)
		_handle_command(line)
		_instant_output = true
		screen.append_text("[color=lime]\nREADY.\n[/color]")
		_instant_output = false
	history_pos = command_history.size()

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
		elif event.keycode == KEY_F3:
			_debug_visible = not _debug_visible
			settings_panel.visible = _debug_visible
		elif event.keycode == KEY_F4:
			_current_clock_idx = (_current_clock_idx + 1) % _clock_speeds.size()
			_update_clock_label()
		elif event.keycode == KEY_F5:
			_run_program()
			input_line.grab_focus()
		elif event.keycode == KEY_F6:
			debug.toggle_recording()
			_instant_output = true
			if debug.is_recording():
				screen.append_text("\n[color=yellow] Recording ON (F6 to stop) [/color]\n")
			else:
				screen.append_text("\n[color=yellow] Recording OFF - frames saved [/color]\n")
			_instant_output = false
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
		elif event.keycode == KEY_F10:
			computer.reset()
			screen.clear()
			_print_banner()
			_update_status()
			input_line.grab_focus()

func _print_banner() -> void:
	_instant_output = true
	screen.append_text("[color=green][b]BASIC6502[/b] - 6502-Powered BASIC Environment[/color]\n")
	screen.append_text("[color=green]Version 1.4 | 64KB RAM | 6502 CPU @ 1MHz | ROM Active[/color]\n")
	screen.append_text("[color=green]F1=Help F3=CRT F4=Clock F5=Run F6=Rec F7=Baud F8=Font F9=SS F10=Reset[/color]\n")
	screen.append_text("[color=green]Type DEMO to list built-in programs, DEMO name to load one.\n[/color]")
	screen.append_text("[color=lime]READY.\n[/color]")
	_instant_output = false

func _on_output(text: String) -> void:
	if text == "[CLR]":
		screen.clear()
		return
	_output_queue += text
	_is_streaming = true

func _on_program_finished() -> void:
	_instant_output = true
	screen.append_text("\n[color=lime]READY.\n[/color]")
	_instant_output = false

func _update_status() -> void:
	var state = computer.cpu.get_state()
	var rec: String = " [REC]" if debug.is_recording() else ""
	var run: String = " [RUN]" if computer._program_running else ""
	var clk: String = _clock_labels[_current_clock_idx]
	status_bar.text = "A:%02X X:%02X Y:%02X SP:%02X PC:%04X %s%s-%s%s%s%s%s%s | %s%s%s | F4=Clock F7=Baud" % [
		state.A, state.X, state.Y, state.SP, state.PC,
		"C" if state.C else ".", "Z" if state.Z else ".",
		"I" if state.I else ".", "D" if state.D else ".",
		".", "V" if state.V else ".", "N" if state.N else ".", ".",
		clk, rec, run
	]

func _update_clock_label() -> void:
	_instant_output = true
	screen.append_text("\n[color=cyan]CPU Clock: " + _clock_labels[_current_clock_idx] + "[/color]\n")
	_instant_output = false
	sound.play_bell()

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
		input_line.clear()
		input_line.grab_focus()
		return
	sound.play_carriage()
	input_line.clear()
	input_line.grab_focus()
	if not _boot_done:
		_input_buffer += text.strip_edges() + "\n"
		return
	if computer._awaiting_input:
		computer.submit_input(text.strip_edges())
		return
	command_history.append(text.strip_edges())
	history_pos = command_history.size()
	_handle_command(text.strip_edges())
	_instant_output = true
	screen.append_text("[color=lime]\nREADY.\n[/color]")
	_instant_output = false

func _handle_command(text: String) -> void:
	var upper = text.to_upper()
	if upper == "HELP":
		_show_help()
	elif upper.begins_with("HELP "):
		_show_help_topic(text.substr(5).strip_edges().to_upper())
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
	help_text += "\n[color=cyan][b]Keyboard Shortcuts:[/b][/color]\n"
	help_text += "[color=yellow]  F3  [/color]- Toggle CRT settings panel\n"
	help_text += "[color=yellow]  F4  [/color]- Cycle CPU clock (0.5/1/10 MHz)\n"
	help_text += "[color=yellow]  F7  [/color]- Cycle baud rate (300/1200/2400/9600/14400)\n"
	help_text += "[color=yellow]  F8  [/color]- Cycle font\n"
	help_text += "[color=yellow]  F9  [/color]- Take screenshot\n"
	help_text += "[color=yellow]  F6  [/color]- Start/stop video recording\n"
	help_text += "[color=yellow]  F1  [/color]- Show this help\n"
	help_text += "[color=yellow]  F5  [/color]- Run program\n"
	help_text += "[color=yellow]  F10 [/color]- Reset system\n"
	help_text += "\n[color=cyan][b]Save/Load (in CRT Settings panel - F3):[/b][/color]\n"
	help_text += "[color=yellow]  Save State[/color] - Save CRT settings, program, variables & memory\n"
	help_text += "[color=yellow]  Load State[/color] - Restore a previously saved state\n"
	help_text += "[color=yellow]  Reset to Defaults[/color] - Reset CRT sliders to defaults\n"
	help_text += "\n[color=cyan][b]BASIC Statements:[/b][/color]\n"
	help_text += "[color=yellow]  PRINT, INPUT, GOTO, GOSUB, RETURN[/color]\n"
	help_text += "[color=yellow]  FOR..TO..STEP..NEXT, IF..THEN[/color]\n"
	help_text += "[color=yellow]  LET, DIM, READ, DATA, RESTORE[/color]\n"
	help_text += "[color=yellow]  POKE, ON..GOTO/GOSUB, END[/color]\n"
	help_text += "\n[color=cyan][b]BASIC Functions:[/b][/color]\n"
	help_text += "[color=yellow]  INT(), RND(), ABS(), SQR(), SIN(), COS()[/color]\n"
	help_text += "[color=yellow]  TAN(), ATN(), LOG(), EXP(), SGN()[/color]\n"
	help_text += "[color=yellow]  LEN(), CHR$(), ASC(), LEFT$(), RIGHT$()[/color]\n"
	help_text += "[color=yellow]  MID$(), STR$(), VAL(), PEEK(), TAB()[/color]\n"
	help_text += "\n[color=lime]Type HELP <topic> for details. Examples: HELP PRINT, HELP FOR, HELP POKE[/color]\n"
	screen.append_text(help_text)
	_instant_output = false

var _help_topics: Dictionary = {}

func _init_help_topics() -> void:
	if _help_topics.size() > 0:
		return
	_help_topics = {
		"PRINT": {
			"syntax": "PRINT expr [;|, expr ...]",
			"desc": "Output text, numbers, or expressions to the screen. Semicolons join output without spaces; commas add tab stops. A trailing semicolon suppresses the newline.",
			"examples": [
				'PRINT "HELLO WORLD"',
				'PRINT 42 + 8',
				'PRINT "SCORE: "; SCORE',
				'10 PRINT "VALUE: "; X; " UNITS"',
			]
		},
		"INPUT": {
			"syntax": 'INPUT [prompt$]; var$',
			"desc": "Display a prompt and wait for the user to type a value. Assigns the entered value to a variable.",
			"examples": [
				'INPUT "YOUR NAME? "; N$',
				'10 INPUT "GUESS A NUMBER: "; G',
				'INPUT A',
			]
		},
		"GOTO": {
			"syntax": "GOTO linenum",
			"desc": "Jump unconditionally to the specified line number. Often used for simple loops. Use with caution — infinite loops can occur.",
			"examples": [
				'GOTO 100',
				'10 PRINT "HELLO": GOTO 10',
			]
		},
		"GOSUB": {
			"syntax": "GOSUB linenum",
			"desc": "Call a subroutine at the given line number. Execution returns to the next line after RETURN. GOSUB/RETURN forms a call stack up to ~100 levels deep.",
			"examples": [
				'10 GOSUB 500',
				'20 PRINT "BACK": END',
				'500 PRINT "IN SUB": RETURN',
			]
		},
		"RETURN": {
			"syntax": "RETURN",
			"desc": "Return from a subroutine called by GOSUB. Execution continues after the GOSUB statement.",
			"examples": [
				'500 PRINT "IN SUB": RETURN',
			]
		},
		"FOR": {
			"syntax": "FOR var = start TO end [STEP incr]",
			"desc": "Begin a counted loop. The variable counts from start to end. Optional STEP sets the increment (default 1). The loop body ends with NEXT var.",
			"examples": [
				'10 FOR I = 1 TO 10',
				'20 PRINT I',
				'30 NEXT I',
				'FOR X = 0 TO 100 STEP 5',
			]
		},
		"NEXT": {
			"syntax": "NEXT var",
			"desc": "End a FOR loop. Increments the loop variable and jumps back to the FOR line if the end value has not been reached.",
			"examples": [
				'10 FOR I = 1 TO 5',
				'20 PRINT I',
				'30 NEXT I',
			]
		},
		"IF": {
			"syntax": "IF condition THEN statement [ELSE statement]",
			"desc": "Conditional execution. If the condition is true, the THEN clause runs. Optional ELSE runs when the condition is false. Use GOTO or any statement after THEN.",
			"examples": [
				'IF X > 10 THEN PRINT "BIG"',
				'IF A = B THEN PRINT "SAME" ELSE PRINT "DIFFERENT"',
				'10 IF G < N THEN PRINT "TOO LOW"',
			]
		},
		"THEN": {
			"syntax": "IF condition THEN statement",
			"desc": "Used after IF to specify what to do when the condition is true. See HELP IF for details.",
			"examples": [
				'IF X > 0 THEN PRINT "POSITIVE"',
			]
		},
		"ELSE": {
			"syntax": "IF condition THEN stmt1 ELSE stmt2",
			"desc": "Optional part of IF — provides an alternative when the condition is false. See HELP IF for details.",
			"examples": [
				'IF A > B THEN PRINT "A" ELSE PRINT "B"',
			]
		},
		"LET": {
			"syntax": "LET var = expr",
			"desc": "Assign a value to a variable. LET is optional — you can assign with just var = expr.",
			"examples": [
				'LET X = 42',
				'X = 42',
				'LET NAME$ = "BASIC"',
			]
		},
		"DIM": {
			"syntax": "DIM var(size) [, var(size) ...]",
			"desc": "Declare an array with the given size. Arrays are 0-indexed. If not DIMmed, arrays auto-size on first use.",
			"examples": [
				'DIM A(10)',
				'DIM A(10), B$(20)',
				'10 DIM SCORES(100)',
			]
		},
		"READ": {
			"syntax": "READ var [, var ...]",
			"desc": "Read values from DATA statements into variables. Use RESTORE to reset the data pointer.",
			"examples": [
				'10 READ A, B, C',
				'20 DATA 10, 20, 30',
			]
		},
		"DATA": {
			"syntax": "DATA value [, value ...]",
			"desc": "Define data values to be read by READ statements. Values are read sequentially. Use RESTORE to start over.",
			"examples": [
				'10 DATA 10, 20, 30',
				'10 DATA "HELLO", "WORLD"',
			]
		},
		"RESTORE": {
			"syntax": "RESTORE",
			"desc": "Reset the DATA pointer so the next READ starts from the first DATA statement again.",
			"examples": [
				'30 RESTORE',
			]
		},
		"POKE": {
			"syntax": "POKE address, value",
			"desc": "Write a byte (0-255) to a memory address. Used for direct hardware access, screen control, and machine language programming. Common addresses: $C002 (screen char), $C003 (screen ctrl: 12=clear, 13=newline).",
			"examples": [
				'POKE 49152, 65',
				'10 POKE $C002, 65',
				'POKE 49155, 12',
			]
		},
		"PEEK": {
			"syntax": "PEEK(addr)",
			"desc": "Read a byte from a memory address. Returns a value 0-255. Useful for reading hardware ports and examining memory. Address $C000 is keyboard data, $C001 is keyboard status.",
			"examples": [
				'PRINT PEEK(49152)',
				'A = PEEK($C000)',
				'10 PRINT PEEK(2048)',
			]
		},
		"ON": {
			"syntax": "ON expr GOTO line1, line2, ... | ON expr GOSUB line1, line2, ...",
			"desc": "Computed branch — jumps to the Nth line number in the list based on the expression value (1-based). Equivalent to a switch/case.",
			"examples": [
				'10 ON X GOTO 100, 200, 300',
				'10 ON CHOICE GOSUB 500, 600, 700',
			]
		},
		"END": {
			"syntax": "END",
			"desc": "Stop program execution immediately. Same as STOP.",
			"examples": [
				'99 END',
				'10 PRINT "DONE": END',
			]
		},
		"STOP": {
			"syntax": "STOP",
			"desc": "Stop program execution. Same as END.",
			"examples": [
				'50 STOP',
			]
		},
		"REM": {
			"syntax": "REM comment text",
			"desc": "Add a comment to your program. Everything after REM on that line is ignored. Comments help document your code.",
			"examples": [
				'10 REM THIS IS A COMMENT',
				'100 REM --- MAIN LOOP ---',
			]
		},
		"CLR": {
			"syntax": "CLR",
			"desc": "Clear all variables and arrays from memory, but keep the program text intact. Different from NEW which also clears the program.",
			"examples": [
				'CLR',
			]
		},
		"NEW": {
			"syntax": "NEW",
			"desc": "Clear the current program and all variables from memory. Starts fresh.",
			"examples": [
				'NEW',
			]
		},
		"LIST": {
			"syntax": "LIST",
			"desc": "Display all lines of the current program in memory.",
			"examples": [
				'LIST',
			]
		},
		"RUN": {
			"syntax": "RUN",
			"desc": "Execute the current program from the first line number.",
			"examples": [
				'RUN',
			]
		},
		"CLEAR": {
			"syntax": "CLEAR  or  CLS",
			"desc": "Clear the terminal screen. Does not affect the program or variables.",
			"examples": [
				'CLEAR',
				'CLS',
			]
		},
		"RESET": {
			"syntax": "RESET",
			"desc": "Full system reset — clears all memory, reloads ROM, resets CPU registers, and reinitializes the BASIC interpreter.",
			"examples": [
				'RESET',
			]
		},
		"CPU": {
			"syntax": "CPU",
			"desc": "Display the current state of the 6502 CPU registers: A (accumulator), X, Y (index), SP (stack pointer), PC (program counter), and status flags.",
			"examples": [
				'CPU',
			]
		},
		"SYS": {
			"syntax": "SYS address",
			"desc": "Execute 6502 machine code at the given memory address. The CPU jumps to that address and runs until it encounters an RTS (return from subroutine). Used with POKE to run custom assembly.",
			"examples": [
				'SYS $F000',
				'10 POKE 768,169: POKE 769,65: SYS 768',
			]
		},
		"SAVE": {
			"syntax": "SAVE filename",
			"desc": "Save the current BASIC program to disk (stored in user:// directory as filename.bas).",
			"examples": [
				'SAVE MYPROG',
				'SAVE TEST1',
			]
		},
		"LOAD": {
			"syntax": "LOAD filename",
			"desc": "Load a previously saved BASIC program from disk (from user:// directory).",
			"examples": [
				'LOAD MYPROG',
				'LOAD TEST1',
			]
		},
		"DIR": {
			"syntax": "DIR  or  CATALOG",
			"desc": "List all saved BASIC program files on disk.",
			"examples": [
				'DIR',
				'CATALOG',
			]
		},
		"DEMO": {
			"syntax": "DEMO  or  DEMO name",
			"desc": "With no argument, lists available demo programs. With a name, loads that demo into memory. Type RUN afterwards to execute it.",
			"examples": [
				'DEMO',
				'DEMO HELLO',
				'DEMO MANDELBROT',
			]
		},
		"INT": {
			"syntax": "INT(x)",
			"desc": "Return the integer part of x (truncate toward zero).",
			"examples": [
				'PRINT INT(3.7)   -> 3',
				'PRINT INT(-2.3)  -> -2',
				'10 N = INT(RND(1) * 100)',
			]
		},
		"RND": {
			"syntax": "RND(x)",
			"desc": "Return a random number between 0 and 1. The argument is ignored — each call returns a new random value.",
			"examples": [
				'PRINT RND(1)',
				'10 N = INT(RND(1) * 100) + 1',
			]
		},
		"ABS": {
			"syntax": "ABS(x)",
			"desc": "Return the absolute value of x.",
			"examples": [
				'PRINT ABS(-5)  -> 5',
				'PRINT ABS(3)   -> 3',
			]
		},
		"SQR": {
			"syntax": "SQR(x)",
			"desc": "Return the square root of x.",
			"examples": [
				'PRINT SQR(16)  -> 4',
				'PRINT SQR(2)   -> 1.414...',
			]
		},
		"SIN": {
			"syntax": "SIN(x)",
			"desc": "Return the sine of x (x in radians).",
			"examples": [
				'PRINT SIN(3.14159)',
			]
		},
		"COS": {
			"syntax": "COS(x)",
			"desc": "Return the cosine of x (x in radians).",
			"examples": [
				'PRINT COS(0)  -> 1',
			]
		},
		"TAN": {
			"syntax": "TAN(x)",
			"desc": "Return the tangent of x (x in radians).",
			"examples": [
				'PRINT TAN(0.7854)',
			]
		},
		"ATN": {
			"syntax": "ATN(x)",
			"desc": "Return the arctangent of x (result in radians).",
			"examples": [
				'PRINT ATN(1)  -> 0.785...',
			]
		},
		"LOG": {
			"syntax": "LOG(x)",
			"desc": "Return the natural logarithm of x (base e).",
			"examples": [
				'PRINT LOG(2.71828)  -> ~1',
			]
		},
		"EXP": {
			"syntax": "EXP(x)",
			"desc": "Return e raised to the power of x.",
			"examples": [
				'PRINT EXP(1)  -> 2.718...',
			]
		},
		"SGN": {
			"syntax": "SGN(x)",
			"desc": "Return -1 if x is negative, 0 if zero, 1 if positive.",
			"examples": [
				'PRINT SGN(-10)  -> -1',
				'PRINT SGN(0)    -> 0',
				'PRINT SGN(42)   -> 1',
			]
		},
		"LEN": {
			"syntax": "LEN(s$)",
			"desc": "Return the number of characters in string s$.",
			"examples": [
				'PRINT LEN("HELLO")  -> 5',
				'10 L = LEN(N$)',
			]
		},
		"CHR$": {
			"syntax": "CHR$(n)",
			"desc": "Return the character with ASCII code n (0-255).",
			"examples": [
				'PRINT CHR$(65)  -> A',
				'10 PRINT CHR$(7)  : REM bell',
			]
		},
		"ASC": {
			"syntax": "ASC(s$)",
			"desc": "Return the ASCII code of the first character of string s$.",
			"examples": [
				'PRINT ASC("A")  -> 65',
				'10 CODE = ASC(K$)',
			]
		},
		"LEFT$": {
			"syntax": "LEFT$(s$, n)",
			"desc": "Return the first n characters of string s$.",
			"examples": [
				'PRINT LEFT$("HELLO", 3)  -> HEL',
			]
		},
		"RIGHT$": {
			"syntax": 'RIGHT$(s$, n)',
			"desc": "Return the last n characters of string s$.",
			"examples": [
				'PRINT RIGHT$("HELLO", 3)  -> LLO',
			]
		},
		"MID$": {
			"syntax": "MID$(s$, start, length)",
			"desc": "Return a substring of s$ starting at position start (1-based) with the given length.",
			"examples": [
				'PRINT MID$("HELLO", 2, 3)  -> ELL',
			]
		},
		"STR$": {
			"syntax": "STR$(n)",
			"desc": "Convert a number to a string representation.",
			"examples": [
				'PRINT STR$(42)  -> "42"',
				'A$ = STR$(X)',
			]
		},
		"VAL": {
			"syntax": "VAL(s$)",
			"desc": "Convert a string to a number. Returns 0 if the string is not a valid number.",
			"examples": [
				'PRINT VAL("42")  -> 42',
				'10 N = VAL(A$)',
			]
		},
		"TAB": {
			"syntax": "TAB(n)",
			"desc": "In a PRINT statement, move the cursor to column n (1-based). Used for formatting output.",
			"examples": [
				'10 PRINT TAB(10); "X"',
				'PRINT TAB(5); NAME$; TAB(20); SCORE',
			]
		},
	}

func _show_help_topic(topic: String) -> void:
	_init_help_topics()
	_instant_output = true
	if _help_topics.has(topic):
		var info = _help_topics[topic]
		var t = "\n[color=cyan][b]" + topic + "[/b][/color]\n\n"
		t += "[color=white]Syntax:  [/color][color=lime]" + info["syntax"] + "[/color]\n\n"
		t += "[color=white]" + info["desc"] + "[/color]\n\n"
		t += "[color=cyan]Examples:[/color]\n"
		for ex in info["examples"]:
			t += "[color=lime]  " + ex + "[/color]\n"
		t += "\n"
		screen.append_text(t)
	else:
		screen.append_text("\n[color=red]No help for: " + topic + "[/color]\n")
		screen.append_text("[color=yellow]Type HELP for a list of commands, or try: HELP PRINT, HELP FOR, HELP POKE[/color]\n\n")
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

func _on_curvature_changed(value: float) -> void:
	curvature_label.text = "Curvature: %.4f" % value
	if _warmup_done:
		crt_overlay.material.set_shader_parameter("crt_curvature", value)

func _on_scanline_changed(value: float) -> void:
	scanline_label.text = "Scanlines: %.3f" % value
	if _warmup_done:
		crt_overlay.material.set_shader_parameter("scanline_intensity", value)

func _on_vignette_changed(value: float) -> void:
	vignette_label.text = "Vignette: %.2f" % value
	if _warmup_done:
		crt_overlay.material.set_shader_parameter("vignette_intensity", value)

func _on_glow_changed(value: float) -> void:
	glow_label.text = "Glow: %.2f" % value
	if _warmup_done:
		crt_overlay.material.set_shader_parameter("glow_intensity", value)

func _on_flicker_changed(value: float) -> void:
	flicker_label.text = "Flicker: %.3f" % value
	if _warmup_done:
		crt_overlay.material.set_shader_parameter("flicker_intensity", value)

func _on_reset_settings() -> void:
	curvature_slider.value = 0.01
	scanline_slider.value = 0.04
	vignette_slider.value = 0.18
	glow_slider.value = 0.18
	flicker_slider.value = 0.005

func _on_save_state() -> void:
	var data = {
		"version": 1,
		"crt": {
			"curvature": curvature_slider.value,
			"scanline_intensity": scanline_slider.value,
			"vignette_intensity": vignette_slider.value,
			"glow_intensity": glow_slider.value,
			"flicker_intensity": flicker_slider.value,
		},
		"font_idx": _current_font_idx,
		"baud_idx": _current_baud_idx,
		"clock_idx": _current_clock_idx,
		"command_history": command_history,
		"computer": computer.serialize(),
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		_instant_output = true
		screen.append_text("\n[color=cyan]State saved.[/color]\n")
		_instant_output = false
		sound.play_bell()
	else:
		_instant_output = true
		screen.append_text("\n[color=red]ERROR: Could not save state.[/color]\n")
		_instant_output = false

func _on_load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_instant_output = true
		screen.append_text("\n[color=yellow]No saved state found.[/color]\n")
		_instant_output = false
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		_instant_output = true
		screen.append_text("\n[color=red]ERROR: Could not read save file.[/color]\n")
		_instant_output = false
		return
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		_instant_output = true
		screen.append_text("\n[color=red]ERROR: Corrupt save file.[/color]\n")
		_instant_output = false
		return
	var data = json.data
	_apply_saved_state(data)
	_instant_output = true
	screen.append_text("\n[color=cyan]State loaded.[/color]\n")
	_instant_output = false
	sound.play_bell()

func _load_state_silent() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		return
	_apply_saved_state(json.data)
	_boot_done = true
	_warmup_done = true
	screen.clear()
	_print_banner()
	_instant_output = true
	screen.append_text("[color=cyan]Previous state restored. Press F3 to adjust CRT settings.[/color]\n\n")
	_instant_output = false
	input_line.grab_focus()

func _apply_saved_state(data: Dictionary) -> void:
	if data.has("crt"):
		var crt = data["crt"]
		if crt.has("curvature"):
			curvature_slider.value = float(crt["curvature"])
			_on_curvature_changed(curvature_slider.value)
		if crt.has("scanline_intensity"):
			scanline_slider.value = float(crt["scanline_intensity"])
			_on_scanline_changed(scanline_slider.value)
		if crt.has("vignette_intensity"):
			vignette_slider.value = float(crt["vignette_intensity"])
			_on_vignette_changed(vignette_slider.value)
		if crt.has("glow_intensity"):
			glow_slider.value = float(crt["glow_intensity"])
			_on_glow_changed(glow_slider.value)
		if crt.has("flicker_intensity"):
			flicker_slider.value = float(crt["flicker_intensity"])
			_on_flicker_changed(flicker_slider.value)
	if data.has("font_idx"):
		_current_font_idx = int(data["font_idx"])
		_apply_font()
		_update_font_label()
	if data.has("baud_idx"):
		_current_baud_idx = int(data["baud_idx"])
		_update_baud_label()
	if data.has("clock_idx"):
		_current_clock_idx = int(data["clock_idx"])
	if data.has("command_history"):
		command_history = data["command_history"]
		history_pos = command_history.size()
	if data.has("computer"):
		computer.deserialize(data["computer"])
extends Control

@onready var screen: RichTextLabel = $VBoxContainer/Screen
var _cmd_line: String = ""
var _cmd_cursor: int = 0
var _cursor_visible: bool = true
var _cursor_timer: float = 0.0
var _cmd_display: RichTextLabel
var input_line: LineEdit
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

var _demos_with_param: Array = ["primenums", "pi"]
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

var _monitor_mode: bool = false
var _monitor_addr: int = 0x0000

const SAVE_PATH = "user://savestate.json"

const WARMUP_DURATION: float = 120.0
const BOOT_DURATION: float = 5.0
const BOOT_FADE_DURATION: float = 4.0

var _warmup_elapsed: float = 0.0
var _boot_elapsed: float = 0.0
var _boot_phase: int = 0
var _boot_done: bool = false
var _warmup_done: bool = false
var _input_buffer: String = ""
var _mouse_hide_timer: float = 0.0

const COLD_CURVATURE: float = 0.10
const COLD_SCANLINE: float = 0.15
const COLD_VIGNETTE: float = 1.0
const COLD_GLOW: float = 0.6
const COLD_FLICKER: float = 0.05

func _ready() -> void:
	Input.mouse_mode = Input.MouseMode.MOUSE_MODE_HIDDEN
	computer = Computer.new()
	computer.output.connect(_on_output)
	computer.output_richtext.connect(_on_output_richtext)
	computer.program_finished.connect(_on_program_finished)
	computer.cart_manager.cart_changed.connect(_on_cart_changed)
	sound = SoundManager.new()
	add_child(sound)
	debug = DebugManager.new()
	add_child(debug)
	input_line = $VBoxContainer/InputLine
	input_line.visible = false
	input_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cmd_display = RichTextLabel.new()
	_cmd_display.name = "CommandLine"
	_cmd_display.bbcode_enabled = true
	_cmd_display.fit_content = true
	_cmd_display.scroll_active = false
	_cmd_display.custom_minimum_size = Vector2(0, 36)
	_cmd_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var _cmd_style = StyleBoxFlat.new()
	_cmd_style.bg_color = Color(0.02, 0.02, 0.06)
	_cmd_style.content_margin_top = 6
	_cmd_style.content_margin_left = 5
	_cmd_style.content_margin_bottom = 4
	_cmd_style.border_width_left = 3
	_cmd_style.border_width_bottom = 3
	_cmd_style.border_width_right = 3
	_cmd_style.border_color = Color(0.3, 0.35, 0.3, 1)
	_cmd_style.corner_radius_bottom_left = 4
	_cmd_style.corner_radius_bottom_right = 4
	_cmd_display.add_theme_stylebox_override("normal", _cmd_style)
	_cmd_display.add_theme_color_override("default_color", Color(0.2, 1, 0.2))
	var _vbox = screen.get_parent()
	var _screen_idx = screen.get_index()
	_vbox.add_child(_cmd_display)
	_vbox.move_child(_cmd_display, _screen_idx + 1)
	_update_cmd_display()
	curvature_slider.value_changed.connect(_on_curvature_changed)
	scanline_slider.value_changed.connect(_on_scanline_changed)
	vignette_slider.value_changed.connect(_on_vignette_changed)
	glow_slider.value_changed.connect(_on_glow_changed)
	flicker_slider.value_changed.connect(_on_flicker_changed)
	reset_btn.pressed.connect(_on_reset_settings)
	save_btn.pressed.connect(_on_save_state)
	load_btn.pressed.connect(_on_load_state)
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
		crt_overlay.material.set_shader_parameter("brightness", 1.0)
		crt_overlay.material.set_shader_parameter("static_intensity", 0.0)
		return
	crt_overlay.material.set_shader_parameter("crt_curvature", COLD_CURVATURE)
	crt_overlay.material.set_shader_parameter("scanline_intensity", COLD_SCANLINE)
	crt_overlay.material.set_shader_parameter("vignette_intensity", COLD_VIGNETTE)
	crt_overlay.material.set_shader_parameter("glow_intensity", COLD_GLOW)
	crt_overlay.material.set_shader_parameter("flicker_intensity", COLD_FLICKER)
	crt_overlay.material.set_shader_parameter("brightness", 0.0)
	crt_overlay.material.set_shader_parameter("static_intensity", 1.0)
	sound.play_crackle()

func _apply_font_deferred() -> void:
	if _fonts_loaded:
		return
	_apply_font()
	_fonts_loaded = true

func _process(delta: float) -> void:
	_mouse_hide_timer -= delta
	if _mouse_hide_timer <= 0 and Input.mouse_mode != Input.MouseMode.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MouseMode.MOUSE_MODE_HIDDEN
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
	_cursor_timer += delta
	if _cursor_timer >= 0.5:
		_cursor_timer -= 0.5
		_cursor_visible = not _cursor_visible
		_update_cmd_display()

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
		crt_overlay.material.set_shader_parameter("brightness", 1.0)
		crt_overlay.material.set_shader_parameter("static_intensity", 0.0)

func _process_boot(delta: float) -> void:
	_boot_elapsed += delta
	var fade_t = clampf(_boot_elapsed / BOOT_FADE_DURATION, 0.0, 1.0)
	var brightness = fade_t * fade_t
	var static_amt = max(0.0, 1.0 - fade_t * 3.0)
	crt_overlay.material.set_shader_parameter("brightness", brightness)
	crt_overlay.material.set_shader_parameter("static_intensity", static_amt)
	var phases = [
		{"time": 0.0, "msg": null},
		{"time": 0.5, "msg": "[color=green][b]Hacker Computer Company[/b][/color]\n"},
		{"time": 1.0, "msg": "[color=green][b]BASIC6502 BIOS v1.4[/b][/color]\n"},
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
		_update_cmd_display()
		_update_status()

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
		_emit_prompt()
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
		var escaped = _escape_bbcode(ch)
		screen.append_text("[color=lime]" + escaped + "[/color]")
	screen.scroll_to_line(screen.get_line_count() - 1)

func _escape_bbcode(text: String) -> String:
	text = text.replace("&", "&amp;")
	text = text.replace("[", "&lsqb;")
	text = text.replace("]", "&rsqb;")
	return text

func _update_cmd_display() -> void:
	if not _cmd_display:
		return
	var before = _cmd_line.substr(0, _cmd_cursor)
	var after = _cmd_line.substr(_cmd_cursor)
	var cursor_char = "[color=white]█[/color]" if _cursor_visible else " "
	var escaped_before = _escape_bbcode(before)
	var escaped_after = _escape_bbcode(after)
	_cmd_display.clear()
	_cmd_display.append_text("[color=lime]" + escaped_before + "[/color]" + cursor_char + "[color=lime]" + escaped_after + "[/color]")

func _submit_command() -> void:
	if not _boot_done:
		if _cmd_line.strip_edges() != "":
			_input_buffer += _cmd_line.strip_edges() + "\n"
		_cmd_line = ""
		_cmd_cursor = 0
		_update_cmd_display()
		return
	sound.play_carriage()
	var text = _cmd_line.strip_edges()
	_cmd_line = ""
	_cmd_cursor = 0
	_cursor_visible = true
	_cursor_timer = 0.0
	_update_cmd_display()
	if text == "":
		if not computer._program_running:
			_emit_prompt()
		return
	_instant_output = true
	screen.append_text("[color=lime]" + _escape_bbcode(text) + "[/color]\n")
	_instant_output = false
	if computer._awaiting_input:
		computer.submit_input(text)
		return
	command_history.append(text)
	history_pos = command_history.size()
	_handle_command(text)
	if not computer._program_running:
		_emit_prompt()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE
		_mouse_hide_timer = 3.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE
		_mouse_hide_timer = 3.0
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE
		_mouse_hide_timer = 3.0
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _monitor_mode:
				_exit_monitor()
				return
			if computer._program_running:
				_break_running_program()
				return
		if event.keycode == KEY_C and event.ctrl_pressed:
			if computer._program_running:
				_break_running_program()
				return
		var handled = false
		match event.keycode:
			KEY_F1:
				_show_help()
				handled = true
			KEY_F3:
				_debug_visible = not _debug_visible
				settings_panel.visible = _debug_visible
				handled = true
			KEY_F4:
				_current_clock_idx = (_current_clock_idx + 1) % _clock_speeds.size()
				_update_clock_label()
				handled = true
			KEY_F5:
				_run_program()
				handled = true
			KEY_F6:
				debug.toggle_recording()
				_instant_output = true
				if debug.is_recording():
					screen.append_text("\n[color=yellow] Recording ON (F6 to stop) [/color]\n")
				else:
					screen.append_text("\n[color=yellow] Recording OFF - frames saved [/color]\n")
				_instant_output = false
				handled = true
			KEY_F7:
				_current_baud_idx = (_current_baud_idx + 1) % _baud_rates.size()
				_update_baud_label()
				handled = true
			KEY_F8:
				_current_font_idx = (_current_font_idx + 1) % _available_fonts.size()
				_apply_font()
				_update_font_label()
				handled = true
			KEY_F9:
				var path = debug.take_screenshot()
				_instant_output = true
				screen.append_text("\n[color=green]Screenshot: " + path + "[/color]\n")
				_instant_output = false
				handled = true
			KEY_F10:
				computer.reset()
				_cmd_line = ""
				_cmd_cursor = 0
				screen.clear()
				_print_banner()
				_update_status()
				_update_cmd_display()
				handled = true
		if handled:
			return
		var unicode_val = event.unicode
		if unicode_val > 0 and not event.ctrl_pressed and not event.meta_pressed:
			if not _boot_done:
				return
			_cmd_line = _cmd_line.insert(_cmd_cursor, char(unicode_val))
			_cmd_cursor += 1
			_cursor_visible = true
			_cursor_timer = 0.0
			sound.play_key()
			_update_cmd_display()
			return
		match event.keycode:
			KEY_BACKSPACE:
				if _cmd_cursor > 0:
					_cmd_line = _cmd_line.substr(0, _cmd_cursor - 1) + _cmd_line.substr(_cmd_cursor)
					_cmd_cursor -= 1
					_cursor_visible = true
					_cursor_timer = 0.0
					sound.play_key()
					_update_cmd_display()
			KEY_DELETE:
				if _cmd_cursor < _cmd_line.length():
					_cmd_line = _cmd_line.substr(0, _cmd_cursor) + _cmd_line.substr(_cmd_cursor + 1)
					_cursor_visible = true
					_cursor_timer = 0.0
					sound.play_key()
					_update_cmd_display()
			KEY_LEFT:
				if _cmd_cursor > 0:
					_cmd_cursor -= 1
					_cursor_visible = true
					_cursor_timer = 0.0
					_update_cmd_display()
			KEY_RIGHT:
				if _cmd_cursor < _cmd_line.length():
					_cmd_cursor += 1
					_cursor_visible = true
					_cursor_timer = 0.0
					_update_cmd_display()
			KEY_HOME:
				_cmd_cursor = 0
				_cursor_visible = true
				_cursor_timer = 0.0
				_update_cmd_display()
			KEY_END:
				_cmd_cursor = _cmd_line.length()
				_cursor_visible = true
				_cursor_timer = 0.0
				_update_cmd_display()
			KEY_ENTER, KEY_KP_ENTER:
				_submit_command()
			KEY_UP:
				if _boot_done and history_pos > 0:
					history_pos -= 1
					_cmd_line = command_history[history_pos]
					_cmd_cursor = _cmd_line.length()
					_cursor_visible = true
					_cursor_timer = 0.0
					_update_cmd_display()
			KEY_DOWN:
				if _boot_done and command_history.size() > 0:
					if history_pos < command_history.size() - 1:
						history_pos += 1
						_cmd_line = command_history[history_pos]
					else:
						history_pos = command_history.size()
						_cmd_line = ""
					_cmd_cursor = _cmd_line.length()
					_cursor_visible = true
					_cursor_timer = 0.0
					_update_cmd_display()

func _print_banner() -> void:
	_instant_output = true
	screen.append_text("[color=green][b]Hacker Computer Company[/b][/color]\n")
	screen.append_text("[color=green][b]BASIC6502[/b] - 6502-Powered BASIC Environment[/color]\n")
	screen.append_text("[color=green]Version 1.4 | 64KB RAM | 6502 CPU @ 1MHz | ROM Active[/color]\n")
	screen.append_text("[color=green]F1=Help F3=Settings F4=Clock F5=Run F6=Rec F7=Baud F8=Font F9=SS F10=Reset[/color]\n")
	if computer.cart_manager.get_current_id() == 2:
		screen.append_text("[color=green]ASM cart: type DEMO for sample sources, HELP for all commands; then ASM and RUN.\n[/color]")
	else:
		screen.append_text("[color=green]Type DEMO to list built-in programs, DEMO name to load one.\n[/color]")
		screen.append_text("[color=green]Some demos take a number: DEMO PRIMENUMS 100 or DEMO PI 1000\n[/color]")
	screen.append_text("[color=lime]" + computer.cart_manager.get_prompt() + "\n[/color]")
	_instant_output = false

func _on_output(text: String) -> void:
	if text == "[CLR]":
		screen.clear()
		return
	_output_queue += text
	_is_streaming = true

func _on_output_richtext(text: String) -> void:
	if text == "[CLR]":
		screen.clear()
		return
	if "\a" in text:
		sound.play_bell()
	for ch in text:
		if ch == "\n":
			sound.play_line_feed()
	screen.append_text(text)
	screen.scroll_to_line(screen.get_line_count() - 1)

func _on_program_finished() -> void:
	_update_status()
	_emit_prompt()

func _emit_prompt() -> void:
	var p: String = computer.cart_manager.get_prompt()
	computer.output.emit("\n" + p + "\n")

func _on_cart_changed(_cart_name: String) -> void:
	var b := computer.cart_manager.get_banner_text()
	if b != "":
		_instant_output = true
		screen.append_text(b)
		_instant_output = false
	_update_status()
	sound.play_bell()

func _update_title_bar() -> void:
	var cart_nm := computer.cart_manager.current.name if computer.cart_manager.current != null else "?"
	var used: int = computer.memory.get_main_ram_used_high_water()
	var ram_part := _format_title_ram_usage(used)
	title_bar.text = "  BASIC6502  |  6502 CPU  |  Cart: %s  |  %s" % [cart_nm, ram_part]

func _format_title_ram_usage(used: int) -> String:
	const TOTAL_K := 64
	if used < 1024:
		return "%d bytes / %dK RAM" % [used, TOTAL_K]
	return "%dK / %dK RAM" % [int(float(used) / 1024.0), TOTAL_K]

func _update_status() -> void:
	_update_title_bar()
	var state = computer.cpu.get_state()
	var rec: String = " [REC]" if debug.is_recording() else ""
	var run: String = " [RUN]" if computer._program_running else ""
	var clk: String = _clock_labels[_current_clock_idx]
	var cart_tag := "[%s] " % computer.cart_manager.current.name if computer.cart_manager.current != null else ""
	status_bar.text = "%sA:%02X X:%02X Y:%02X SP:%02X PC:%04X %s%s-%s%s%s%s%s%s | %s%s%s | F4=Clock F7=Baud" % [
		cart_tag,
		state.A, state.X, state.Y, state.SP, state.PC,
		"C" if state.C else ".", "Z" if state.Z else ".",
		"I" if state.I else ".", "D" if state.D else ".",
		".", "V" if state.V else ".", "N" if state.N else ".", ".",
		clk, rec, run
	]

func _update_clock_label() -> void:
	_instant_output = true
	screen.append_text("\n[color=green]CPU Clock: " + _clock_labels[_current_clock_idx] + "[/color]\n")
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
	if _cmd_display:
		_cmd_display.add_theme_font_override("normal_font", dynamic_font)
		_cmd_display.add_theme_font_size_override("normal_font_size", font_size)
	sound.play_key()

func _handle_command(text: String) -> void:
	if _monitor_mode:
		_handle_monitor_command(text)
		return
	if computer.cart_manager.handle_command(text):
		_update_status()
		return
	var upper = text.to_upper()
	if upper == "HELP":
		_show_help()
	elif upper.begins_with("HELP "):
		_show_help_topic(text.substr(5).strip_edges().to_upper())
	elif upper == "CLEAR" or upper == "CLS":
		screen.clear()
	elif upper == "RESET":
		computer.reset()
		_cmd_line = ""
		_cmd_cursor = 0
		screen.clear()
		_print_banner()
		_update_status()
	elif upper == "NEW":
		computer.reset()
		_update_status()
	elif upper == "STOP" or upper == "BREAK":
		_cmd_stop()
	elif upper == "HALT":
		_cmd_halt()
	elif upper == "STEP":
		_cmd_step()
	elif upper == "POWEROFF":
		_cmd_poweroff()
	elif upper == "MONITOR" or upper == "MON":
		_enter_monitor()
	elif upper == "LIST":
		_list_program()
	elif upper.begins_with("LIST "):
		_list_program(text.substr(5).strip_edges())
	elif upper == "RUN":
		_run_program()
	elif upper.begins_with("RUN ") or upper == "RUN,":
		_run_program_with_args(text.substr(3).strip_edges())
	elif upper.begins_with("SAVE "):
		_save_program(text.substr(5).strip_edges())
	elif upper.begins_with("LOAD "):
		_load_program(text.substr(5).strip_edges())
	elif upper == "DIR" or upper == "CATALOG":
		_show_catalog()
	elif upper.begins_with("SCRATCH ") or upper.begins_with("DELETE "):
		_scratch_program(text.substr(text.find(" ") + 1).strip_edges())
	elif upper.begins_with("RENAME "):
		_rename_program(text.substr(7).strip_edges())
	elif upper == "DEMO" or upper == "DEMOS":
		_show_demos()
	elif upper.begins_with("DEMO ") or upper.begins_with("DEMOS "):
		var demo_arg = text.substr(5).strip_edges()
		var space_pos = demo_arg.find(" ")
		var demo_name: String
		var demo_param: String = ""
		if space_pos >= 0:
			demo_name = demo_arg.substr(0, space_pos).to_lower()
			demo_param = demo_arg.substr(space_pos + 1).strip_edges()
		else:
			demo_name = demo_arg.to_lower()
		_load_demo(demo_name, demo_param)
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

func _help_keyboard_shortcuts_block() -> String:
	var b := "\n[color=cyan]Keyboard Shortcuts:[/color]\n"
	b += "[color=yellow]  F3  [/color]- Toggle System Settings panel\n"
	b += "[color=yellow]  F4  [/color]- Cycle CPU clock (0.5/1/10 MHz)\n"
	b += "[color=yellow]  F7  [/color]- Cycle baud rate (300/1200/2400/9600/14400)\n"
	b += "[color=yellow]  F8  [/color]- Cycle font\n"
	b += "[color=yellow]  F9  [/color]- Take screenshot\n"
	b += "[color=yellow]  F6  [/color]- Start/stop video recording\n"
	b += "[color=yellow]  F1  [/color]- Show this help\n"
	b += "[color=yellow]  F5  [/color]- Run program (from start)\n"
	b += "[color=yellow]  F10 [/color]- Reset system\n"
	return b


func _show_help() -> void:
	_instant_output = true
	var cur = computer.cart_manager.current
	if cur != null:
		var cart_h := cur.help_text()
		if cart_h != "":
			screen.append_text(cart_h)
			screen.append_text(_help_keyboard_shortcuts_block())
			if computer.cart_manager.get_current_id() == 0:
				screen.append_text("\n[color=lime]Type HELP <topic> for BASIC details. Examples: HELP PRINT, HELP FOR[/color]\n")
			_instant_output = false
			return
	var help_text = "\n[color=cyan]BASIC6502 Commands:[/color]\n"
	help_text += "[color=yellow]  RUN [n]   [/color]- Run program (optionally from line n)\n"
	help_text += "[color=yellow]  LIST [n]  [/color]- List program (or line range)\n"
	help_text += "[color=yellow]  NEW       [/color]- Clear the program and variables\n"
	help_text += "[color=yellow]  CLEAR     [/color]- Clear the screen\n"
	help_text += "[color=yellow]  RESET     [/color]- Full system reset\n"
	help_text += "[color=yellow]  CPU       [/color]- Show CPU registers\n"
	help_text += "[color=yellow]  STOP/BREAK[/color]- Break running program\n"
	help_text += "[color=yellow]  HALT      [/color]- Halt the CPU\n"
	help_text += "[color=yellow]  STEP      [/color]- Single-step one CPU instruction\n"
	help_text += "[color=yellow]  MONITOR   [/color]- Enter system monitor (Apple II style)\n"
	help_text += "[color=yellow]  POWEROFF  [/color]- Shut down\n"
	help_text += "[color=yellow]  SAVE name [/color]- Save program to disk\n"
	help_text += "[color=yellow]  LOAD name [/color]- Load program from disk\n"
	help_text += "[color=yellow]  SCRATCH   [/color]- Delete a saved program (or DELETE)\n"
	help_text += "[color=yellow]  RENAME    [/color]- Rename a saved program\n"
	help_text += "[color=yellow]  DIR       [/color]- List saved programs\n"
	help_text += "[color=yellow]  DEMO      [/color]- List built-in BASIC demo programs\n"
	help_text += "[color=yellow]  DEMO name [/color]- Load a BASIC demo (some accept N); on ASM cart use DEMO for assembler samples\n"
	help_text += "[color=yellow]  CART      [/color]- List ROM carts (BASIC, TEXT, ASM)\n"
	help_text += "[color=yellow]  CART name [/color]- Hot-swap cartridge (clears $E000-$EFFF)\n"
	help_text += "[color=yellow]  BSAVE     [/color]- Save memory range as binary (addr, len)\n"
	help_text += "[color=yellow]  BLOAD     [/color]- Load binary file into memory (addr)\n"
	help_text += "[color=yellow]  LOADOBJ   [/color]- Load HC65 .obj from user://; optional , NAME registers native call\n"
	help_text += "[color=yellow]  WRITE     [/color]- Write text to file (filename, text)\n"
	help_text += "[color=yellow]  READFILE  [/color]- Read file into var or display\n"
	help_text += _help_keyboard_shortcuts_block()
	help_text += "\n[color=cyan]Save/Load (in System Settings panel - F3):[/color]\n"
	help_text += "[color=yellow]  Save State[/color] - Save system settings, program, variables & memory\n"
	help_text += "[color=yellow]  Load State[/color] - Restore a previously saved state\n"
	help_text += "[color=yellow]  Reset to Defaults[/color] - Reset CRT sliders to defaults\n"
	help_text += "\n[color=cyan]BASIC Statements:[/color]\n"
	help_text += "[color=yellow]  PRINT, INPUT, GOTO, GOSUB, RETURN[/color]\n"
	help_text += "[color=yellow]  FOR..TO..STEP..NEXT, IF..THEN[/color]\n"
	help_text += "[color=yellow]  LET, DIM, READ, DATA, RESTORE[/color]\n"
	help_text += "[color=yellow]  POKE, ON..GOTO/GOSUB, END, STOP, BREAK[/color]\n"
	help_text += "\n[color=cyan]BASIC Functions:[/color]\n"
	help_text += "[color=yellow]  INT(), RND(), ABS(), SQR(), SIN(), COS()[/color]\n"
	help_text += "[color=yellow]  TAN(), ATN(), LOG(), EXP(), SGN()[/color]\n"
	help_text += "[color=yellow]  LEN(), CHR$(), ASC(), LEFT$(), RIGHT$()[/color]\n"
	help_text += "[color=yellow]  MID$(), STR$(), VAL(), PEEK(), TAB()[/color]\n"
	help_text += "\n[color=lime]Type HELP <topic> for BASIC details (HELP LOADOBJ). After LOADOBJ, HELP <name> shows embedded help.[/color]\n"
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
				'PRINT "HELLO WORLD"        -> displays HELLO WORLD',
				'10 PRINT "SCORE: "; SCORE   -> with semicolon, no space before value',
				'PRINT 42 + 8                -> displays 50',
				'PRINT A; " "; B             -> multiple expressions separated by ;',
			]
		},
		"INPUT": {
			"syntax": 'INPUT [prompt$]; var[, var ...]',
			"desc": "Display a prompt and wait for the user to type a value. Assigns the entered value to a variable. Multiple variables separated by commas accept multiple inputs.",
			"examples": [
				'10 INPUT "YOUR NAME? "; N$   -> prompts then reads string',
				'20 INPUT "AGE? "; A           -> prompts then reads number',
				'INPUT X                       -> reads a number with ? prompt',
			]
		},
		"GOTO": {
			"syntax": "GOTO linenum",
			"desc": "Jump unconditionally to the specified line number. Often used for simple loops. Can cause infinite loops if not paired with a condition.",
			"examples": [
				'10 PRINT "AGAIN": GOTO 10    -> infinite loop',
				'50 IF X > 10 THEN GOTO 100   -> conditional jump',
				'99 GOTO 10                    -> jump back to start',
			]
		},
		"GOSUB": {
			"syntax": "GOSUB linenum",
			"desc": "Call a subroutine at the given line number. Execution returns to the line after GOSUB when RETURN is hit. Supports nesting up to ~100 levels deep.",
			"examples": [
				'10 GOSUB 500                  -> call subroutine at line 500',
				'20 PRINT "BACK": END           -> continues here after RETURN',
				'500 PRINT "IN SUB": RETURN    -> subroutine definition',
			]
		},
		"RETURN": {
			"syntax": "RETURN",
			"desc": "Return from a subroutine called by GOSUB. Execution continues at the line after the GOSUB. Causes ERROR if no GOSUB is active.",
			"examples": [
				'500 PRINT "HELLO": RETURN     -> simple subroutine',
				'300 RETURN                     -> return to caller',
				'10 GOSUB 100: PRINT "DONE"    -> GOSUB/RETURN pair',
			]
		},
		"FOR": {
			"syntax": "FOR var = start TO end [STEP incr]",
			"desc": "Begin a counted loop. Variable counts from start to end. STEP is optional (default 1). Loop body ends with NEXT var. Nested FOR loops are supported.",
			"examples": [
				'10 FOR I = 1 TO 10            -> count from 1 to 10',
				'20 FOR X = 0 TO 100 STEP 5    -> count by 5',
				'10 FOR I = 10 TO 1 STEP -1    -> count backwards',
			]
		},
		"NEXT": {
			"syntax": "NEXT var",
			"desc": "End a FOR loop. Increments the loop variable by STEP and jumps back to the FOR line if the end value hasn't been reached. Must match a FOR statement. NEXT without a variable matches the innermost FOR.",
			"examples": [
				'30 NEXT I                      -> end of FOR I loop',
				'20 NEXT                         -> end of innermost FOR loop',
				'10 FOR X = 1 TO 5: PRINT X: NEXT X  -> single-line loop',
			]
		},
		"IF": {
			"syntax": "IF condition THEN statement [: ELSE statement]",
			"desc": "Conditional execution. If the condition is true, the THEN clause runs. Optional ELSE runs when false. THEN can be followed by a line number (GOTO) or any statement. Use colon : to separate multiple statements.",
			"examples": [
				'10 IF X > 10 THEN PRINT "BIG"       -> simple condition',
				'20 IF A = B THEN GOTO 100            -> THEN with line number',
				'30 IF N < 0 THEN PRINT "NEG" ELSE PRINT "POS"  -> with ELSE',
			]
		},
		"THEN": {
			"syntax": "IF condition THEN statement",
			"desc": "Used after IF to specify what to do when the condition is true. Can be followed by a line number (implicit GOTO) or any BASIC statement. See HELP IF for full details.",
			"examples": [
				'10 IF X > 0 THEN PRINT "POSITIVE"',
				'20 IF A = 1 THEN 100              -> shorthand for GOTO 100',
				'30 IF DONE THEN END                -> end program if DONE is true',
			]
		},
		"ELSE": {
			"syntax": "IF condition THEN stmt1 ELSE stmt2",
			"desc": "Optional part of IF — provides an alternative when the condition is false. Must appear on the same line as the IF. See HELP IF for full details.",
			"examples": [
				'10 IF A > B THEN PRINT "A" ELSE PRINT "B"',
				'20 IF X THEN PRINT "YES" ELSE PRINT "NO"',
				'30 IF N >= 0 THEN GOTO 100 ELSE GOTO 200',
			]
		},
		"LET": {
			"syntax": "[LET] var = expr",
			"desc": "Assign a value to a variable. LET is optional — you can assign with just var = expr. Supports numbers, strings (var$), and expressions.",
			"examples": [
				'10 LET X = 42                  -> explicit assignment',
				'20 X = X + 1                    -> implicit (no LET needed)',
				'30 NAME$ = "BASIC"              -> string assignment',
			]
		},
		"DIM": {
			"syntax": "DIM var(size) [, var(size) ...]",
			"desc": "Declare an array with the given size. Arrays are 0-indexed. If not DIMmed, arrays auto-size on first use up to 10 elements. Multiple arrays can be declared on one line.",
			"examples": [
				'10 DIM A(10)                    -> array of 11 elements (0-10)',
				'20 DIM A(10), B$(20)            -> two arrays at once',
				'30 DIM SCORES(100)              -> large array for scores',
			]
		},
		"READ": {
			"syntax": "READ var [, var ...]",
			"desc": "Read values from DATA statements into variables. Values are read sequentially from all DATA lines. Use RESTORE to reset the data pointer.",
			"examples": [
				'10 READ A, B, C                 -> read three numbers',
				'20 READ NAME$                    -> read a string',
				'10 FOR I = 1 TO 5: READ N(I): NEXT I  -> fill array from DATA',
			]
		},
		"DATA": {
			"syntax": "DATA value [, value ...]",
			"desc": "Define data values to be read by READ statements. Values are read sequentially across all DATA lines. Strings should be quoted if they contain commas.",
			"examples": [
				'10 DATA 10, 20, 30              -> three numbers',
				'20 DATA "HELLO", "WORLD"        -> two strings',
				'100 DATA 1, 2, 3, 4, 5          -> five numbers',
			]
		},
		"RESTORE": {
			"syntax": "RESTORE",
			"desc": "Reset the DATA pointer so the next READ starts from the first DATA statement again. Useful for re-reading data values.",
			"examples": [
				'30 RESTORE                       -> reset to start of DATA',
				'10 FOR I = 1 TO 2: READ X: NEXT I: RESTORE  -> read then reset',
				'100 RESTORE                      -> allows DATA to be read again',
			]
		},
		"POKE": {
			"syntax": "POKE address, value",
			"desc": "Write a byte (0-255) to a memory address. Used for direct hardware access and machine language programming. Key addresses: $C002 (screen char), $C003 (control: 12=clear, 13=newline).",
			"examples": [
				'10 POKE 49152, 65              -> write A to screen port',
				'20 POKE $C002, 65              -> same using hex address',
				'30 POKE 49155, 12              -> clear screen (12 = form feed)',
			]
		},
		"PEEK": {
			"syntax": "PEEK(addr)",
			"desc": "Read a byte from a memory address. Returns a value 0-255. Key addresses: $C000 (keyboard data), $C001 (keyboard status). Can be used in expressions.",
			"examples": [
				'10 PRINT PEEK(49152)          -> read screen port',
				'20 A = PEEK($C000)             -> read keyboard data',
				'30 IF PEEK($C001) THEN GOTO 10 -> check if key pressed',
			]
		},
		"ON": {
			"syntax": "ON expr GOTO line1, line2, ... | ON expr GOSUB line1, line2, ...",
			"desc": "Computed branch — jumps to the Nth line number in the list based on the expression value (1-based). If expr is 0 or exceeds the list, no jump occurs.",
			"examples": [
				'10 ON X GOTO 100, 200, 300     -> jump to line 100, 200, or 300',
				'20 ON CHOICE GOSUB 500, 600, 700 -> call subroutine 500, 600, or 700',
				'30 ON MENU GOTO 50, 100, 150, 200  -> four-way branch',
			]
		},
		"END": {
			"syntax": "END  |  STOP  |  BREAK",
			"desc": "Stop program execution immediately. END, STOP, and BREAK are interchangeable. Shows 'BREAK AT LINE n' when used in a program.",
			"examples": [
				'99 END                          -> normal program termination',
				'50 IF X < 0 THEN STOP           -> conditional stop for debugging',
				'10 PRINT "TEST": BREAK           -> stop and show line number',
			]
		},
		"STOP": {
			"syntax": "STOP  |  BREAK",
			"desc": "Stop the currently running program. In a program, shows 'BREAK AT LINE n'. At the command line, stops any running program. Also triggered by the F5 key.",
			"examples": [
				'STOP                             -> break running program',
				'BREAK                             -> same as STOP',
				'50 IF ERROR THEN STOP             -> conditional breakpoint',
			]
		},
		"BREAK": {
			"syntax": "BREAK  |  STOP",
			"desc": "Break (stop) the currently running program. Same as STOP. Shows the line number where execution stopped.",
			"examples": [
				'BREAK                            -> break running program',
				'STOP                              -> same as BREAK',
				'50 IF DONE THEN BREAK             -> stop if condition met',
			]
		},
		"REM": {
			"syntax": "REM comment text",
			"desc": "Add a comment (remark) to your program. Everything after REM on that line is ignored. Comments help document your code. Cannot be followed by more statements.",
			"examples": [
				'10 REM THIS IS A COMMENT        -> explanatory note',
				'100 REM --- MAIN LOOP ---       -> section divider',
				'50 REM X INCREASES BY 1 EACH LOOP -> algorithm note',
			]
		},
		"CLR": {
			"syntax": "CLR",
			"desc": "Clear all variables and arrays from memory, but keep the program text intact. Different from NEW which also clears the program. Useful for resetting state without losing your program.",
			"examples": [
				'CLR                              -> clear all variables',
				'10 CLR                            -> clear vars from within program',
				'100 CLR: FOR I = 1 TO 10          -> reset then start fresh loop',
			]
		},
		"NEW": {
			"syntax": "NEW",
			"desc": "Clear the current program and all variables from memory. Starts fresh. This cannot be undone — make sure you SAVE first if needed.",
			"examples": [
				'NEW                               -> clear everything and start over',
				'10 REM Type NEW to begin a fresh program',
				'-> After NEW, LIST shows no program lines',
			]
		},
		"LIST": {
			"syntax": "LIST  |  LIST linenum  |  LIST start end",
			"desc": "Display program lines in memory. With no arguments, lists all lines. With one line number, shows just that line. With two numbers, shows all lines in that range. Typing a line number with no statement deletes that line.",
			"examples": [
				'LIST                              -> show all program lines',
				'LIST 30                            -> show only line 30',
				'LIST 10 100                        -> show lines 10 through 100',
			]
		},
		"RUN": {
			"syntax": "RUN  |  RUN linenum  |  RUN var=val, ...  |  RUN linenum, var=val, ...",
			"desc": "Execute the current program. With a line number, start at that line. With variable assignments, set variables before running. Assignments can include numbers, strings, and expressions.",
			"examples": [
				'RUN                               -> start from first line',
				'RUN 100                            -> start at line 100',
				'RUN N=10                           -> set N=10 then run from start',
				'RUN 100, N=10, S$="HELLO"         -> start at line 100, set N and S$',
			]
		},
		"CLEAR": {
			"syntax": "CLEAR  |  CLS",
			"desc": "Clear the terminal screen. Does not affect the program or variables. Use NEW to clear the program, CLR to clear variables only.",
			"examples": [
				'CLEAR                             -> clear the screen',
				'CLS                               -> same as CLEAR',
				'10 CLEAR                          -> clear screen from within program',
			]
		},
		"RESET": {
			"syntax": "RESET",
			"desc": "Full system reset — clears all memory, reloads ROM, resets CPU registers, and reinitializes the BASIC interpreter. The screen is cleared and the boot banner is shown.",
			"examples": [
				'RESET                             -> full system restart',
				'-> Use when the system is in a bad state',
				'-> All program and variable data is lost',
			]
		},
		"CPU": {
			"syntax": "CPU",
			"desc": "Display the current state of the 6502 CPU registers: A (accumulator), X and Y (index), SP (stack pointer), PC (program counter), and status flags (NVDIZC).",
			"examples": [
				'CPU                               -> show all CPU registers',
				'-> Useful after STEP or HALT for debugging',
				'10 SYS 61488: CPU                  -> run 6502 code then show regs',
			]
		},
		"SYS": {
			"syntax": "SYS address",
			"desc": "Execute 6502 machine code at the given memory address. The CPU jumps to that address and runs until RTS (return from subroutine). Use POKE to load code before calling SYS. Address can be decimal or hex with $ prefix.",
			"examples": [
				'10 SYS 61488                       -> call ROM routine at $F000',
				'20 POKE 768,169: POKE 769,65: SYS 768  -> load and run machine code',
				'SYS $F040                           -> call counter routine in hex',
			]
		},
		"SAVE": {
			"syntax": "SAVE filename",
			"desc": "Save the current BASIC program to disk (stored in user:// directory as filename.bas). The file contains program text only, not variable values.",
			"examples": [
				'SAVE MYPROG                       -> save as MYPROG.bas',
				'SAVE TEST1                         -> save as TEST1.bas',
				'SAVE "COOL GAME"                   -> save with spaces',
			]
		},
		"LOAD": {
			"syntax": "LOAD filename",
			"desc": "Load a previously saved BASIC program from disk (from user:// directory). Replaces the current program and clears all variables.",
			"examples": [
				'LOAD MYPROG                       -> load MYPROG.bas',
				'LOAD TEST1                         -> load TEST1.bas',
				'-> Type RUN after LOAD to execute',
			]
		},
		"DIR": {
			"syntax": "DIR  |  CATALOG",
			"desc": "List all saved BASIC program files on disk. Shows filename and size. Use LOAD filename to load a program, then RUN to execute it.",
			"examples": [
				'DIR                               -> list all saved programs',
				'CATALOG                            -> same as DIR',
				'-> After DIR, use LOAD <name> to retrieve a program',
			]
		},
		"SCRATCH": {
			"syntax": "SCRATCH filename  |  DELETE filename",
			"desc": "Delete a saved program file from disk. The file is permanently removed. Use DIR first to see what files exist.",
			"examples": [
				'SCRATCH MYPROG                  -> delete MYPROG.bas',
				'DELETE TEST1                      -> same as SCRATCH',
				'-> Use DIR to list files before deleting',
			]
		},
		"DELETE": {
			"syntax": "DELETE filename  |  SCRATCH filename",
			"desc": "Delete a saved program file from disk. Same as SCRATCH. The file is permanently removed.",
			"examples": [
				'DELETE MYPROG                    -> delete MYPROG.bas',
				'SCRATCH OLDGAME                  -> same as DELETE',
				'-> Be sure you want to delete before using this command',
			]
		},
		"RENAME": {
			"syntax": "RENAME oldname newname",
			"desc": "Rename a saved program file on disk. The old name must exist and the new name must not already exist.",
			"examples": [
				'RENAME MYPROG COOLPROG          -> rename file',
				'RENAME TEST1 BACKUP              -> rename TEST1 to BACKUP',
				'-> Use DIR to verify the new name appears',
			]
		},
		"DEMO": {
			"syntax": "DEMO  |  DEMO name  |  DEMO name N",
			"desc": "With no argument, lists available demo programs. With a name, loads that demo into memory (does not auto-run). Some demos accept a number N as a parameter (e.g. PRIMENUMS and PI). Type RUN afterwards to execute.",
			"examples": [
				'DEMO                               -> list all demos',
				'DEMO MANDELBROT                    -> load Mandelbrot demo',
				'DEMO PRIMENUMS 100                -> find first 100 primes',
				'DEMO PI 1000                      -> calculate pi with 1000 terms',
			]
		},
		"HALT": {
			"syntax": "HALT",
			"desc": "Halt the 6502 CPU immediately. The CPU will not execute further until you type STEP, enter the MONITOR, or RESET. Useful for debugging machine code programs.",
			"examples": [
				'HALT                               -> freeze the CPU',
				'10 SYS $F000: HALT                  -> run code then freeze',
				'-> Use STEP or MONITOR to continue after HALT',
			]
		},
		"STEP": {
			"syntax": "STEP",
			"desc": "Execute a single 6502 CPU instruction at the current program counter, then display the instruction and registers. Useful for debugging machine code. Only works when CPU is halted.",
			"examples": [
				'STEP                               -> execute one CPU instruction',
				'-> Use after HALT or in MONITOR mode',
				'-> Shows the instruction that was just executed',
			]
		},
		"MONITOR": {
			"syntax": "MONITOR  |  MON",
			"desc": "Enter the system monitor mode (Apple II style). Inspect memory, disassemble code, step through instructions, and modify memory. Type H inside the monitor for a full command list.",
			"examples": [
				'MONITOR                            -> enter monitor mode',
				'MON                                -> same shortcut',
				'-> Type H inside monitor for help, ESC to exit',
			]
		},
		"POWEROFF": {
			"syntax": "POWEROFF",
			"desc": "Shut down the BASIC6502 application. Same as closing the window. All unsaved program data is lost.",
			"examples": [
				'POWEROFF                           -> quit the application',
				'-> Make sure you SAVE before POWEROFF',
				'-> Equivalent to clicking the window close button',
			]
		},
		"INT": {
			"syntax": "INT(x)",
			"desc": "Return the integer part of x, truncated toward zero. The fractional part is discarded.",
			"examples": [
				'PRINT INT(3.7)     -> 3           -> positive truncation',
				'PRINT INT(-2.3)    -> -2          -> negative truncation',
				'10 N = INT(RND(1) * 100) + 1     -> random integer 1-100',
			]
		},
		"RND": {
			"syntax": "RND(x)",
			"desc": "Return a random number between 0 and 1. The argument is ignored — each call returns a new random value. Use INT and multiplication to get integers in a range.",
			"examples": [
				'PRINT RND(1)       -> 0.xxxxxxxx  -> random float 0-1',
				'10 N = INT(RND(1) * 100) + 1     -> random integer 1-100',
				'10 D = INT(RND(1) * 6) + 1       -> dice roll 1-6',
			]
		},
		"ABS": {
			"syntax": "ABS(x)",
			"desc": "Return the absolute value of x — the distance from zero, always positive.",
			"examples": [
				'PRINT ABS(-5)      -> 5           -> negative becomes positive',
				'PRINT ABS(3)        -> 3           -> positive stays positive',
				'10 D = ABS(X2 - X1)               -> calculate distance',
			]
		},
		"SQR": {
			"syntax": "SQR(x)",
			"desc": "Return the square root of x. x must be non-negative.",
			"examples": [
				'PRINT SQR(16)      -> 4          -> 4 squared is 16',
				'PRINT SQR(2)        -> 1.4142...  -> irrational result',
				'10 H = SQR(A*A + B*B)            -> hypotenuse (Pythagoras)',
			]
		},
		"SIN": {
			"syntax": "SIN(x)",
			"desc": "Return the sine of x, where x is in radians. To convert degrees to radians, multiply by PI/180.",
			"examples": [
				'PRINT SIN(3.14159)  -> ~0 (sin of pi)',
				'10 S = SIN(ANGLE * 3.14159 / 180) -> sin of degrees',
				'PRINT SIN(0)        -> 0          -> sin of zero',
			]
		},
		"COS": {
			"syntax": "COS(x)",
			"desc": "Return the cosine of x, where x is in radians. Commonly used with SIN for rotation and wave calculations.",
			"examples": [
				'PRINT COS(0)        -> 1          -> cosine of zero',
				'10 X = COS(ANGLE * 3.14159 / 180) -> cos of degrees',
				'PRINT COS(3.14159)  -> ~-1         -> cos of pi',
			]
		},
		"TAN": {
			"syntax": "TAN(x)",
			"desc": "Return the tangent of x (sin/cos), where x is in radians. Undefined at odd multiples of PI/2.",
			"examples": [
				'PRINT TAN(0)         -> 0          -> tangent of zero',
				'PRINT TAN(0.7854)   -> ~1         -> tangent of pi/4',
				'10 T = TAN(ANGLE * 3.14159 / 180)  -> tan of degrees',
			]
		},
		"ATN": {
			"syntax": "ATN(x)",
			"desc": "Return the arctangent of x (result in radians). Can compute PI as 4*ATN(1). Result range is -PI/2 to PI/2.",
			"examples": [
				'PRINT ATN(1)         -> 0.7854...  -> arctan(1) = pi/4',
				'10 PI = 4 * ATN(1)   -> calculate pi accurately',
				'10 A = ATN(Y / X)    -> angle from rise/run',
			]
		},
		"LOG": {
			"syntax": "LOG(x)",
			"desc": "Return the natural logarithm of x (base e). x must be positive. For log base 10, use LOG(x)/LOG(10).",
			"examples": [
				'PRINT LOG(2.71828)  -> ~1         -> log of e',
				'10 L10 = LOG(X) / LOG(10)        -> log base 10',
				'PRINT LOG(1)          -> 0          -> log of 1 is always 0',
			]
		},
		"EXP": {
			"syntax": "EXP(x)",
			"desc": "Return e (2.71828...) raised to the power of x. Inverse of LOG.",
			"examples": [
				'PRINT EXP(1)         -> 2.718...   -> e to the 1st power',
				'PRINT EXP(0)          -> 1          -> e to the 0th power',
				'10 Y = EXP(X)                     -> exponential function',
			]
		},
		"SGN": {
			"syntax": "SGN(x)",
			"desc": "Return the sign of x: -1 if negative, 0 if zero, 1 if positive.",
			"examples": [
				'PRINT SGN(-10)      -> -1         -> negative number',
				'PRINT SGN(0)          -> 0          -> zero',
				'PRINT SGN(42)        -> 1          -> positive number',
			]
		},
		"LEN": {
			"syntax": "LEN(s$)",
			"desc": "Return the number of characters in string s$. Useful for loops and string validation.",
			"examples": [
				'PRINT LEN("HELLO")  -> 5          -> five characters',
				'10 L = LEN(N$)                     -> store length in variable',
				'10 IF LEN(A$) > 10 THEN PRINT "LONG STRING"',
			]
		},
		"CHR$": {
			"syntax": "CHR$(n)",
			"desc": "Return the character with ASCII code n (0-255). Inverse of ASC(). Common codes: 7=bell, 10=linefeed, 13=carriage return.",
			"examples": [
				'PRINT CHR$(65)       -> A          -> ASCII 65 is A',
				'10 PRINT CHR$(7)     -> bell sound (alert)',
				'10 PRINT CHR$(13); CHR$(10)       -> newline',
			]
		},
		"ASC": {
			"syntax": "ASC(s$)",
			"desc": "Return the ASCII code of the first character of string s$. Inverse of CHR$(). Values range 0-255.",
			"examples": [
				'PRINT ASC("A")      -> 65         -> A is ASCII 65',
				'10 CODE = ASC(K$)                  -> get key code',
				'10 IF ASC(A$) >= 65 THEN PRINT "LETTER"',
			]
		},
		"LEFT$": {
			"syntax": "LEFT$(s$, n)",
			"desc": "Return the first n characters of string s$. If n exceeds the string length, the entire string is returned.",
			"examples": [
				'PRINT LEFT$("HELLO", 3)  -> HEL  -> first 3 chars',
				'10 A$ = LEFT$(NAME$, 1)            -> first character only',
				'10 PRINT LEFT$(TXT$, 10)            -> first 10 chars',
			]
		},
		"RIGHT$": {
			"syntax": 'RIGHT$(s$, n)',
			"desc": "Return the last n characters of string s$. If n exceeds string length, the entire string is returned.",
			"examples": [
				'PRINT RIGHT$("HELLO", 3)  -> LLO  -> last 3 chars',
				'10 EXT$ = RIGHT$(FNAME$, 3)       -> get file extension',
				'10 PRINT RIGHT$(TXT$, 10)          -> last 10 chars',
			]
		},
		"MID$": {
			"syntax": "MID$(s$, start, length)",
			"desc": "Return a substring of s$ starting at position start (1-based) with the given length. If length is omitted, returns from start to end of string.",
			"examples": [
				'PRINT MID$("HELLO", 2, 3)  -> ELL  -> chars 2-4',
				'10 PRINT MID$(A$, 5)              -> from char 5 to end',
				'10 PART$ = MID$(TEXT$, P, 1)       -> single character at P',
			]
		},
		"STR$": {
			"syntax": "STR$(n)",
			"desc": "Convert a number to a string. Positive numbers include a leading space. Inverse of VAL().",
			"examples": [
				'PRINT STR$(42)       -> " 42"      -> number to string',
				'10 A$ = STR$(X)                    -> store number as string',
				'10 PRINT "VALUE: " + STR$(SCORE)    -> concatenate with text',
			]
		},
		"VAL": {
			"syntax": "VAL(s$)",
			"desc": "Convert a string to a number. Returns 0 if the string is not a valid number. Inverse of STR$().",
			"examples": [
				'PRINT VAL("42")       -> 42        -> string to number',
				'10 N = VAL(A$)                     -> convert input to number',
				'PRINT VAL("HELLO")   -> 0          -> invalid string',
			]
		},
		"TAB": {
			"syntax": "TAB(n)",
			"desc": "In a PRINT statement, move the cursor to column n (1-based). Used for formatting tabular output. Only meaningful inside PRINT.",
			"examples": [
				'10 PRINT TAB(10); "X"             -> print X at column 10',
				'10 PRINT TAB(5); NAME$; TAB(20); SCORE  -> two-column display',
				'10 FOR I = 1 TO N: PRINT TAB(I); "*": NEXT I -> diagonal',
			]
		},
		"LOADOBJ": {
			"syntax": "LOADOBJ \"filename\" [, NAME]",
			"desc": "Loads an HC65 object file from user://filename (see ASM cart SAVEOBJ). Writes bytes to the file's load address, then registers NAME as a native statement (v1: no arguments). If you omit , NAME, the file must include a .EXPORT name from the assembler.",
			"examples": [
				'LOADOBJ "mylib.obj", PRIMEGEN   -> register PRIMEGEN then type PRIMEGEN to run',
				'LOADOBJ "mylib.obj"            -> uses .EXPORT inside the .obj file',
				'HELP PRIMEGEN                  -> shows .HELP_SYNTAX / .HELP_DESC / examples if present',
			]
		},
		"COLON": {
			"syntax": "statement : statement",
			"desc": "Colon separates multiple statements on one program line. Each statement is executed in order. If a GOTO or STOP is encountered, remaining statements are skipped.",
			"examples": [
				'10 X = 1 : PRINT X               -> two statements on one line',
				'20 IF A > B THEN PRINT "A" : GOTO 100  -> colon in IF',
				'30 A = 10 : B = 20 : PRINT A + B   -> three statements',
			]
		},
	}

func _show_help_topic(topic: String) -> void:
	_init_help_topics()
	_instant_output = true
	var nh := computer.basic.format_native_help(topic)
	if nh != "":
		screen.append_text(nh)
		_instant_output = false
		return
	if _help_topics.has(topic):
		var info = _help_topics[topic]
		var t = "\n[color=cyan]" + topic + "[/color]\n\n"
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

func _list_program(range_str: String = "") -> void:
	var prog = computer.basic._program
	if prog.size() == 0:
		screen.append_text("[color=yellow]No program in memory.\n[/color]")
		return
	var start_line: int = -1
	var end_line: int = 999999999
	if range_str != "":
		var parts = range_str.split(" ")
		if parts.size() == 1:
			start_line = int(parts[0])
			end_line = start_line
		elif parts.size() >= 2:
			start_line = int(parts[0])
			end_line = int(parts[1])
	_instant_output = true
	var text = "\n"
	for entry in prog:
		if entry[0] >= start_line and entry[0] <= end_line:
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

func _run_program_with_args(args_str: String) -> void:
	if computer.basic._program.size() == 0:
		sound.play_error()
		screen.append_text("[color=red]ERROR: NO PROGRAM IN MEMORY\n[/color]")
		return
	screen.append_text("\n")
	var start_line: int = -1
	var rest: String = args_str
	if rest.length() > 0 and rest[0].is_valid_int():
		var num_end = 0
		while num_end < rest.length() and (rest[num_end].is_valid_int() or rest[num_end] == '.'):
			num_end += 1
		var num_str = rest.substr(0, num_end)
		start_line = int(num_str)
		rest = rest.substr(num_end).strip_edges()
		if rest.begins_with(","):
			rest = rest.substr(1).strip_edges()
	var assignments = rest.split(",", false)
	for assignment in assignments:
		assignment = assignment.strip_edges()
		if assignment == "":
			continue
		var eq_pos = assignment.find("=")
		if eq_pos < 0:
			sound.play_error()
			screen.append_text("[color=red]ERROR: INVALID PARAMETER: %s\n[/color]" % assignment)
			return
		var var_name = assignment.substr(0, eq_pos).strip_edges().to_upper()
		var var_value_str = assignment.substr(eq_pos + 1).strip_edges()
		computer.basic.execute_line("LET " + var_name + " = " + var_value_str)
	var prog_lines: Array = []
	for entry in computer.basic._program:
		prog_lines.append(str(entry[0]) + " " + str(entry[1]))
	var program = "\n".join(prog_lines)
	computer.run_basic(program, start_line)

func _add_program_line(text: String) -> void:
	var parsed = computer.basic._parse_line(text.strip_edges())
	if parsed == null:
		sound.play_error()
		screen.append_text("[color=red]ERROR: INVALID LINE NUMBER\n[/color]")
		return
	var line_num = parsed[0]
	var stmt = parsed[1]
	if stmt.strip_edges() == "":
		var idx = -1
		for i in range(computer.basic._program.size()):
			if computer.basic._program[i][0] == line_num:
				idx = i
				break
		if idx >= 0:
			computer.basic._program.remove_at(idx)
			screen.append_text("[color=yellow]DELETED LINE %d\n[/color]" % line_num)
		else:
			screen.append_text("[color=yellow]NO LINE %d TO DELETE\n[/color]" % line_num)
		return
	var replaced = false
	for i in range(computer.basic._program.size()):
		if computer.basic._program[i][0] == line_num:
			computer.basic._program[i] = parsed
			replaced = true
			break
	if not replaced:
		computer.basic._program.append(parsed)
		computer.basic._program.sort_custom(func(a, b): return a[0] < b[0])
	computer.basic._collect_data()
	_instant_output = true
	if replaced:
		screen.append_text("[color=cyan]UPDATED LINE %d\n[/color]" % line_num)
	else:
		screen.append_text("[color=lime]INSERTED LINE %d\n[/color]" % line_num)
	screen.append_text("[color=white]%5d %s\n[/color]" % [line_num, stmt])
	_instant_output = false

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
		screen.append_text("\n[color=cyan]SAVED PROGRAMS:[/color]\n")
		var count = 0
		var total_bytes = 0
		while file_name != "":
			if file_name.ends_with(".bas"):
				var f = FileAccess.open("user://" + file_name, FileAccess.READ)
				var size = f.get_length() if f else 0
				if f:
					f.close()
				total_bytes += size
				var name = file_name.replace(".bas", "")
				var size_str = _format_size(size)
				screen.append_text("[color=yellow]  %-16s %s\n[/color]" % [name, size_str])
				count += 1
			file_name = dir.get_next()
		if count == 0:
			screen.append_text("[color=yellow]  (none)\n[/color]")
		screen.append_text("[color=white]  %d file(s), %s used\n[/color]" % [count, _format_size(total_bytes)])
		screen.append_text("\n")
		dir.list_dir_end()
		_instant_output = false

func _format_size(bytes: int) -> String:
	if bytes < 1024:
		return str(bytes) + " B"
	elif bytes < 1048576:
		return str(bytes / 1024.0) + " KB"
	else:
		return str(bytes / 1048576.0) + " MB"

func _scratch_program(filename: String) -> void:
	if filename == "":
		sound.play_error()
		screen.append_text("[color=red]ERROR: MISSING FILENAME\n[/color]")
		return
	var path = "user://" + filename + ".bas"
	if FileAccess.file_exists(path):
		var dir = DirAccess.open("user://")
		if dir and dir.remove(filename + ".bas") == OK:
			screen.append_text("[color=lime]DELETED: " + filename + "\n[/color]")
		else:
			sound.play_error()
			screen.append_text("[color=red]ERROR: CANNOT DELETE FILE\n[/color]")
	else:
		sound.play_error()
		screen.append_text("[color=red]ERROR: FILE NOT FOUND\n[/color]")

func _rename_program(args: String) -> void:
	var parts = args.split(" ")
	if parts.size() < 2:
		sound.play_error()
		screen.append_text("[color=red]ERROR: RENAME OLD NEW\n[/color]")
		return
	var old_name = parts[0].strip_edges()
	var new_name = parts[1].strip_edges()
	if old_name == "" or new_name == "":
		sound.play_error()
		screen.append_text("[color=red]ERROR: RENAME OLD NEW\n[/color]")
		return
	var old_path = "user://" + old_name + ".bas"
	var new_path = "user://" + new_name + ".bas"
	if not FileAccess.file_exists(old_path):
		sound.play_error()
		screen.append_text("[color=red]ERROR: FILE NOT FOUND: " + old_name + "\n[/color]")
		return
	if FileAccess.file_exists(new_path):
		sound.play_error()
		screen.append_text("[color=red]ERROR: FILE ALREADY EXISTS: " + new_name + "\n[/color]")
		return
	var dir = DirAccess.open("user://")
	if dir and dir.rename(old_name + ".bas", new_name + ".bas") == OK:
		screen.append_text("[color=lime]RENAMED: " + old_name + " -> " + new_name + "\n[/color]")
	else:
		sound.play_error()
		screen.append_text("[color=red]ERROR: CANNOT RENAME FILE\n[/color]")

func _show_cpu_state() -> void:
	_instant_output = true
	var state = computer.cpu.get_state()
	var text = "\n[color=cyan]6502 CPU STATE:[/color]\n"
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
	var text = "\n[color=cyan]BUILT-IN DEMO PROGRAMS:[/color]\n"
	text += "[color=yellow]  Type DEMO name to load, then RUN[/color]\n\n"
	var demos = computer.rom.get_demo_list()
	for d in demos:
		text += "[color=white]  %-14s[/color] %s\n" % [d["name"], d["desc"]]
	text += "\n[color=cyan]ROM ROUTINES (use with SYS):[/color]\n"
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

func _load_demo(name: String, param: String = "") -> void:
	var program = computer.load_demo(name)
	if program != "":
		computer.basic.load_program(program)
		computer.basic._running = false
		computer._program_running = false
		if param != "" and _demos_with_param.has(name):
			computer.basic._variables["N"] = float(param)
		_instant_output = true
		screen.append_text("[color=lime]Loaded demo: " + name + "\n[/color]")
		_list_program()
		screen.append_text("[color=lime]Type RUN to execute.\n[/color]")
		_instant_output = false
		sound.play_bell()
	else:
		_instant_output = true
		screen.append_text("[color=red]ERROR: DEMO NOT FOUND. Type DEMO to list available demos.\n[/color]")
		_instant_output = false

func _peek_command(text: String) -> void:
	computer.execute_basic_line(text)

func _sys_command(text: String) -> void:
	computer.execute_basic_line(text)

func _break_running_program() -> void:
	computer.break_program()
	_instant_output = true
	screen.append_text("\n[color=yellow]BREAK at line " + str(computer.basic._current_line) + "[/color]\n")
	_instant_output = false
	sound.play_bell()

func _cmd_stop() -> void:
	_break_running_program()

func _cmd_halt() -> void:
	computer.cpu.halted = true
	computer._program_running = false
	computer.basic._running = false
	_instant_output = true
	screen.append_text("[color=red]CPU HALTED. Type MONITOR to inspect, or RESET to restart.[/color]\n")
	_instant_output = false
	sound.play_bell()

func _cmd_step() -> void:
	if computer.cpu.halted:
		computer.cpu.halted = false
	var old_pc = computer.cpu.PC
	computer.cpu.step()
	var disasm = computer.cpu.disassemble(old_pc, 1)
	var line_text = "$" + ("%04X" % old_pc) + ": " + disasm[0]["disasm"] + "\n"
	_instant_output = true
	screen.append_text("[color=green]" + line_text + "[/color]")
	_show_cpu_reg()
	_instant_output = false

func _cmd_poweroff() -> void:
	_instant_output = true
	screen.append_text("\n[color=yellow]POWER OFF...[/color]\n")
	_instant_output = false
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func _enter_monitor() -> void:
	_monitor_mode = true
	_monitor_addr = computer.cpu.PC
	_instant_output = true
	screen.append_text("\n[color=cyan]*** SYSTEM MONITOR ***[/color]\n")
	screen.append_text("[color=green]Type H for monitor commands. ESC or Q to exit.[/color]\n")
	screen.append_text("[color=green]*[/color] ")
	_instant_output = false
	sound.play_bell()

func _exit_monitor() -> void:
	_monitor_mode = false
	_instant_output = true
	screen.append_text("\n[color=green]Exit monitor.[/color]\n")
	_instant_output = false

func _handle_monitor_command(text: String) -> void:
	var upper = text.to_upper().strip_edges()
	if upper == "H" or upper == "HELP":
		_show_monitor_help()
	elif upper == "Q" or upper == "QUIT" or upper == "EXIT":
		_exit_monitor()
	elif upper == "R" or upper == "REGS" or upper == "REGISTERS":
		_show_cpu_reg()
	elif upper == "S" or upper == "STEP":
		computer.cpu.halted = false
		var old_pc = computer.cpu.PC
		computer.cpu.step()
		var disasm = computer.cpu.disassemble(old_pc, 1)
		_instant_output = true
		screen.append_text("[color=white]$%04X: %s[/color]\n" % [old_pc, disasm[0]["disasm"]])
		_show_cpu_reg()
		_instant_output = false
	elif upper == "G" or upper == "GO":
		computer.cpu.halted = false
		_instant_output = true
		screen.append_text("[color=green]Running from $%04X...[/color]\n" % computer.cpu.PC)
		screen.append_text("[color=green]Type STOP to break.[/color]\n")
		_instant_output = false
		computer._program_running = false
		computer.basic._running = false
		var sys_addr = computer.cpu.PC
		computer.cpu.PC = sys_addr
		computer.cpu.halted = false
		computer.cpu.step()
	elif upper.begins_with("G ") or upper.begins_with("GO "):
		var addr_str = upper.substr(upper.find(" ") + 1).strip_edges()
		var addr = _parse_hex_addr(addr_str)
		if addr >= 0:
			computer.cpu.PC = addr
			computer.cpu.halted = false
			_instant_output = true
			screen.append_text("[color=green]Running from $%04X...[/color]\n" % addr)
			_instant_output = false
			computer.cpu.step()
		else:
			_instant_output = true
			screen.append_text("[color=red]Invalid address.[/color]\n")
			_instant_output = false
	elif upper == "D" or upper.begins_with("D ") or upper.begins_with("DIS ") or upper.begins_with("DISASM"):
		var count = 16
		var addr = _monitor_addr
		if upper.length() > 2 and upper.begins_with("D "):
			var arg = upper.substr(2).strip_edges()
			addr = _parse_hex_addr(arg)
			if addr < 0:
				addr = _monitor_addr
		elif upper.begins_with("DIS ") or upper.begins_with("DISASM"):
			var space_pos = upper.find(" ")
			if space_pos >= 0:
				addr = _parse_hex_addr(upper.substr(space_pos + 1).strip_edges())
				if addr < 0:
					addr = _monitor_addr
		_show_disassembly(addr, count)
		_monitor_addr = addr + count * 3
	elif upper == "M" or upper.begins_with("M ") or upper.begins_with("MEM "):
		var count = 64
		var addr = _monitor_addr
		if upper.length() > 2:
			var arg = upper.substr(upper.find(" ") + 1).strip_edges()
			addr = _parse_hex_addr(arg)
			if addr < 0:
				addr = _monitor_addr
		_show_memory_dump(addr, count)
		_monitor_addr = addr + count
	elif upper.begins_with(":") or upper.begins_with("W "):
		_monitor_write(upper)
	elif upper == "RESET":
		computer.reset()
		_monitor_addr = computer.cpu.PC
		_instant_output = true
		screen.append_text("[color=yellow]System reset.[/color]\n")
		_instant_output = false
	else:
		var addr = _parse_hex_addr(upper)
		if addr >= 0:
			_monitor_addr = addr
			_show_memory_dump(addr, 8)
		else:
			_instant_output = true
			screen.append_text("[color=red]Unknown monitor command. Type H for help.[/color]\n")
			_instant_output = false
	_instant_output = true
	screen.append_text("[color=green]*[/color] ")
	_instant_output = false

func _parse_hex_addr(s: String) -> int:
	s = s.strip_edges()
	if s.begins_with("$"):
		s = s.substr(1)
	if s.begins_with("0X"):
		s = s.substr(2)
	if s.is_valid_int():
		return int(s)
	if s.is_valid_html_color():
		return int("0x" + s)
	return -1

func _show_monitor_help() -> void:
	_instant_output = true
	var h = "\n[color=cyan]SYSTEM MONITOR COMMANDS[/color]\n"
	h += "[color=yellow]  <addr>[/color]      - Examine memory at hex addr\n"
	h += "[color=yellow]  D [addr][/color]     - Disassemble 16 instructions\n"
	h += "[color=yellow]  M [addr][/color]     - Memory dump (64 bytes)\n"
	h += "[color=yellow]  :addr:hh hh...[/color] - Write bytes to memory\n"
	h += "[color=yellow]  R[/color]           - Show CPU registers\n"
	h += "[color=yellow]  S[/color]           - Single-step one CPU instruction\n"
	h += "[color=yellow]  G [addr][/color]    - Go (run from addr or current PC)\n"
	h += "[color=yellow]  RESET[/color]      - Reset CPU and memory\n"
	h += "[color=yellow]  Q / ESC[/color]    - Exit monitor\n"
	screen.append_text(h)
	_instant_output = false

func _show_cpu_reg() -> void:
	var s = computer.cpu.get_state()
	var line = "[color=white]A:%02X X:%02X Y:%02X SP:%02X PC:%04X %s%s%s%s%s%s%s[/color]\n" % [
		s.A, s.X, s.Y, s.SP, s.PC,
		"C" if s.C else ".", "Z" if s.Z else ".",
		"I" if s.I else ".", "D" if s.D else ".",
		"B.", "V" if s.V else ".", "N" if s.N else "."
	]
	_instant_output = true
	screen.append_text(line)
	_instant_output = false

func _show_disassembly(addr: int, count: int) -> void:
	_instant_output = true
	var disasm = computer.cpu.disassemble(addr, count)
	for entry in disasm:
		var a: int = entry["addr"]
		var num_bytes = 0
		screen.append_text("[color=white]$%04X: %s[/color]\n" % [a, entry["disasm"]])
	_instant_output = false

func _show_memory_dump(addr: int, count: int) -> void:
	_instant_output = true
	var offset = 0
	while offset < count:
		var row_addr = (addr + offset) & 0xFFFF
		var hex_str = "[color=white]$%04X: " % row_addr
		var ascii_str = ""
		for i in range(16):
			if offset + i >= count:
				hex_str += "   "
				ascii_str += " "
			else:
				var b = computer.memory.peek(row_addr + i)
				hex_str += "%02X " % b
				if b >= 32 and b < 127:
					ascii_str += char(b)
				else:
					ascii_str += "."
		hex_str += " " + ascii_str + "\n"
		screen.append_text(hex_str)
		offset += 16
	_instant_output = false

func _monitor_write(upper: String) -> void:
	var cmd = upper
	if cmd.begins_with("W "):
		cmd = cmd.substr(2)
	elif cmd.begins_with(":"):
		cmd = cmd.substr(1)
	var parts = cmd.split(":")
	if parts.size() < 2:
		_instant_output = true
		screen.append_text("[color=red]Format: addr:hh hh hh[/color]\n")
		_instant_output = false
		return
	var addr = _parse_hex_addr(parts[0].strip_edges())
	if addr < 0:
		_instant_output = true
		screen.append_text("[color=red]Invalid address.[/color]\n")
		_instant_output = false
		return
	var byte_strs = parts[1].strip_edges().split(" ")
	for bs in byte_strs:
		if bs.strip_edges() == "":
			continue
		var val = _parse_hex_addr(bs.strip_edges())
		if val >= 0 and val <= 255:
			computer.memory.poke(addr, val)
			addr += 1
		else:
			_instant_output = true
			screen.append_text("[color=red]Invalid byte: %s[/color]\n" % bs)
			_instant_output = false
			return
	_instant_output = true
	screen.append_text("[color=green]Wrote %d bytes.[/color]\n" % byte_strs.size())
	_instant_output = false

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
		screen.append_text("\n[color=green]State saved.[/color]\n")
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
	var raw_bytes = file.get_buffer(file.get_length())
	file.close()
	var json_text = raw_bytes.get_string_from_utf8()
	if json_text == "":
		_instant_output = true
		screen.append_text("\n[color=red]ERROR: Corrupt save file (invalid encoding). Deleted.[/color]\n")
		_instant_output = false
		DirAccess.remove_absolute(SAVE_PATH)
		return
	var json = JSON.new()
	if json.parse(json_text) != OK:
		_instant_output = true
		screen.append_text("\n[color=red]ERROR: Corrupt save file. Deleted.[/color]\n")
		_instant_output = false
		DirAccess.remove_absolute(SAVE_PATH)
		return
	var data = json.data
	_apply_saved_state(data)
	_instant_output = true
	screen.append_text("\n[color=green]State loaded.[/color]\n")
	_instant_output = false
	sound.play_bell()

func _load_state_silent() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var raw_bytes = file.get_buffer(file.get_length())
	file.close()
	var json_text = raw_bytes.get_string_from_utf8()
	if json_text == "":
		DirAccess.remove_absolute(SAVE_PATH)
		return
	var json = JSON.new()
	if json.parse(json_text) != OK:
		DirAccess.remove_absolute(SAVE_PATH)
		return
	_apply_saved_state(json.data)
	_boot_done = true
	_warmup_done = true
	crt_overlay.material.set_shader_parameter("brightness", 1.0)
	crt_overlay.material.set_shader_parameter("static_intensity", 0.0)
	_cmd_line = ""
	_cmd_cursor = 0
	screen.clear()
	_print_banner()
	_instant_output = true
	screen.append_text("[color=green]Previous state restored. Press F3 to adjust settings.[/color]\n\n")
	_instant_output = false
	_update_cmd_display()

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
		_update_status()

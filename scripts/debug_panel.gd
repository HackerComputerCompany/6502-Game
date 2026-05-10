extends PanelContainer

var computer: Computer = null
var _info_cache: Array = []
var _reg_value_labels: Dictionary = {}
var _flag_labels: Dictionary = {}
var _desc_labels: Dictionary = {}

var _title_label: Label
var _cpu_info_label: Label
var _reg_container: VBoxContainer
var _flag_container: VBoxContainer
var _disasm_label: RichTextLabel
var _help_label: RichTextLabel
var _step_btn: Button
var _cont_btn: Button
var _reset_btn: Button

func setup(comp: Computer) -> void:
	computer = comp
	_build_ui()

func _build_ui() -> void:
	add_theme_stylebox_override("panel", _make_panel_bg())
	custom_minimum_size = Vector2(320, 0)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	add_child(vbox)

	_title_label = Label.new()
	_title_label.text = "  Debug Panel (F2)"
	_title_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	_title_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_title_label)

	_cpu_info_label = Label.new()
	_cpu_info_label.add_theme_font_size_override("font_size", 10)
	_cpu_info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(_cpu_info_label)

	vbox.add_child(_sep())

	var rh = Label.new()
	rh.text = "  Registers"
	rh.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	rh.add_theme_font_size_override("font_size", 11)
	vbox.add_child(rh)

	_reg_container = VBoxContainer.new()
	_reg_container.add_theme_constant_override("separation", 1)
	vbox.add_child(_reg_container)

	vbox.add_child(_sep())

	var fh = Label.new()
	fh.text = "  Status Flags"
	fh.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	fh.add_theme_font_size_override("font_size", 11)
	vbox.add_child(fh)

	_flag_container = VBoxContainer.new()
	_flag_container.add_theme_constant_override("separation", 1)
	vbox.add_child(_flag_container)

	vbox.add_child(_sep())

	var ch = Label.new()
	ch.text = "  Controls"
	ch.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	ch.add_theme_font_size_override("font_size", 11)
	vbox.add_child(ch)

	var ctrl_box = HBoxContainer.new()
	ctrl_box.add_theme_constant_override("separation", 5)
	vbox.add_child(ctrl_box)

	_step_btn = Button.new()
	_step_btn.text = "Step"
	_step_btn.pressed.connect(_on_step)
	ctrl_box.add_child(_step_btn)

	_cont_btn = Button.new()
	_cont_btn.text = "Continue"
	_cont_btn.pressed.connect(_on_continue)
	ctrl_box.add_child(_cont_btn)

	_reset_btn = Button.new()
	_reset_btn.text = "Reset CPU"
	_reset_btn.pressed.connect(_on_reset_cpu)
	ctrl_box.add_child(_reset_btn)

	vbox.add_child(_sep())

	var dh = Label.new()
	dh.text = "  Disassembly"
	dh.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	dh.add_theme_font_size_override("font_size", 11)
	vbox.add_child(dh)

	_disasm_label = RichTextLabel.new()
	_disasm_label.bbcode_enabled = true
	_disasm_label.fit_content = false
	_disasm_label.custom_minimum_size = Vector2(0, 100)
	_disasm_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_disasm_label.add_theme_font_size_override("normal_font_size", 11)
	_disasm_label.add_theme_color_override("default_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(_disasm_label)

	vbox.add_child(_sep())

	var hh = Label.new()
	hh.text = "  Register Help"
	hh.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	hh.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hh)

	_help_label = RichTextLabel.new()
	_help_label.bbcode_enabled = true
	_help_label.fit_content = true
	_help_label.custom_minimum_size = Vector2(0, 50)
	_help_label.add_theme_font_size_override("normal_font_size", 10)
	_help_label.add_theme_color_override("default_color", Color(0.65, 0.65, 0.65))
	vbox.add_child(_help_label)

	_populate_info()
	refresh()

func _make_panel_bg() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.06, 0.15, 0.97)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.2, 0.3, 0.2, 1)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_right = 6
	s.corner_radius_bottom_left = 6
	return s

func _sep() -> HSeparator:
	var s = HSeparator.new()
	s.add_theme_color_override("default_color", Color(0.2, 0.25, 0.2, 0.5))
	return s

func _populate_info() -> void:
	if not computer or not computer.cpu:
		return
	if not computer.cpu.has_method("get_register_info"):
		return
	_info_cache = computer.cpu.get_register_info()
	for info in _info_cache:
		var key: String = info.get("key", "")
		var group: String = info.get("group", "")
		if group == "register":
			_add_reg_row(key, info.get("name", key), info.get("desc", ""))
		elif group == "flag":
			_add_flag_row(key, info.get("name", key), info.get("desc", ""))

func _add_reg_row(key: String, name: String, desc: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)

	var nl = Label.new()
	nl.text = "  " + name + ":"
	nl.add_theme_font_size_override("font_size", 11)
	nl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	nl.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(nl)

	var vl = Label.new()
	vl.text = "$00"
	vl.add_theme_font_size_override("font_size", 11)
	vl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	vl.custom_minimum_size = Vector2(75, 0)
	_reg_value_labels[key] = vl
	hbox.add_child(vl)

	var dl = Label.new()
	dl.text = desc
	dl.add_theme_font_size_override("font_size", 9)
	dl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desc_labels[key] = dl
	hbox.add_child(dl)

	_reg_container.add_child(hbox)

func _add_flag_row(key: String, name: String, desc: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)

	var nl = Label.new()
	nl.text = "  " + name + ":"
	nl.add_theme_font_size_override("font_size", 10)
	nl.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	nl.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(nl)

	var vl = Label.new()
	vl.text = "0"
	vl.add_theme_font_size_override("font_size", 11)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vl.custom_minimum_size = Vector2(18, 0)
	_flag_labels[key] = vl
	hbox.add_child(vl)

	var dl = Label.new()
	dl.text = desc
	dl.add_theme_font_size_override("font_size", 9)
	dl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desc_labels[key] = dl
	hbox.add_child(dl)

	_flag_container.add_child(hbox)

func refresh() -> void:
	if not computer or not computer.cpu:
		return
	var state = computer.cpu.get_state()
	var cpu_type = computer.cpu.cpu_type if computer.cpu.cpu_type != "" else "?"
	var halted = "Yes" if computer.cpu.halted else "No"
	var run = "Yes" if computer._program_running else "No"
	_cpu_info_label.text = "CPU: %s | Halted: %s | Run: %s" % [cpu_type, halted, run]

	for info in _info_cache:
		var key = info.get("key", "")
		var group = info.get("group", "")
		if group == "register" and key in state and key in _reg_value_labels:
			var val = state[key]
			if key == "PC":
				_reg_value_labels[key].text = "$%04X" % val
			elif key == "P":
				_reg_value_labels[key].text = "$%02X" % val
			elif key == "SP":
				_reg_value_labels[key].text = "$%02X (%d)" % [val, val]
			else:
				_reg_value_labels[key].text = "$%02X (%d)" % [val, val]
		elif group == "flag" and key in state and key in _flag_labels:
			var val = state[key]
			_flag_labels[key].text = "1" if val else "0"
			if val:
				_flag_labels[key].add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
			else:
				_flag_labels[key].add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))

	_update_disasm()

	_help_label.clear()
	_help_label.append_text("[color=#888888]Registers show hex and decimal values.\nFlags: green=set, red=clear.\nUse Step to execute one instruction.[/color]")

func _update_disasm() -> void:
	if not computer or not computer.cpu:
		return
	var pc = computer.cpu.PC if "PC" in computer.cpu else 0
	var lines = computer.cpu.disassemble(pc, 8)
	_disasm_label.clear()
	for entry in lines:
		var addr = entry.get("addr", 0)
		var instr = entry.get("disasm", "???")
		var bytes_str = ""
		if computer.memory:
			var b0 = computer.memory.peek(addr)
			var b1 = computer.memory.peek(addr + 1)
			var b2 = computer.memory.peek(addr + 2)
			bytes_str = "%02X %02X %02X" % [b0, b1, b2]
		_disasm_label.append_text("[color=#888888]$%04X  %s[/color]  [color=#cccccc]%s[/color]\n" % [addr, bytes_str, instr])

func _on_step() -> void:
	if not computer or not computer.cpu:
		return
	if computer.cpu.halted:
		computer.cpu.halted = false
	computer.cpu.step()
	_show_step_result()
	refresh()

func _show_step_result() -> void:
	var pc = computer.cpu.PC
	var lines = computer.cpu.disassemble(pc, 1)
	var instr = lines[0]["disasm"] if lines.size() > 0 else "???"
	var state = computer.cpu.get_state()
	var msg = "\n[color=cyan]** STEP **[/color] "
	msg += "[color=white]PC=$%04X  %s  A=$%02X X=$%02X Y=$%02X[/color]\n" % [pc, instr, state.A, state.X, state.Y]
	computer.output_richtext.emit(msg)

func _on_continue() -> void:
	if not computer or not computer.cpu:
		return
	if computer.cpu.halted:
		computer.cpu.halted = false
		computer.output_richtext.emit("\n[color=green]CPU resumed.[/color]\n")
		if not computer._program_running and computer.basic and computer.basic._program.size() > 0:
			computer.run_basic("", -1)
	else:
		if not computer._program_running and computer.basic and computer.basic._program.size() > 0:
			computer.run_basic("", -1)
	refresh()

func _on_reset_cpu() -> void:
	if not computer or not computer.cpu:
		return
	computer.cpu.reset()
	computer.output_richtext.emit("\n[color=yellow]CPU reset.[/color]\n")
	refresh()

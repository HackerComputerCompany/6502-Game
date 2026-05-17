extends CanvasLayer

var _queue: Array = []
var _busy: bool = false
var _char_timer: float = 0.0
var _char_index: int = 0
var _current_text: String = ""
var _displayed_text: String = ""
var _on_finished: Callable = Callable()

var _panel: Panel
var _speaker_label: Label
var _text_label: RichTextLabel
var _portrait: TextureRect

func _ready() -> void:
	_panel = Panel.new()
	_panel.size = Vector2(300, 70)
	_panel.position = Vector2(10, 105)
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.size = Vector2(290, 65)
	vbox.position = Vector2(5, 5)
	_panel.add_child(vbox)

	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(24, 24)
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP
	_portrait.hide()
	hbox.add_child(_portrait)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	_speaker_label.add_theme_font_size_override("font_size", 12)
	_speaker_label.text = ""
	text_vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.add_theme_color_override("default_color", Color(0.15, 0.15, 0.15))
	_text_label.add_theme_font_size_override("normal_font_size", 11)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.bbcode_enabled = true
	text_vbox.add_child(_text_label)

	hide()

func _make_panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.95, 0.92, 0.85)
	s.border_width_left = 3
	s.border_width_top = 3
	s.border_width_right = 3
	s.border_width_bottom = 3
	s.border_color = Color(0.3, 0.25, 0.2)
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_right = 4
	s.corner_radius_bottom_left = 4
	return s

func show_text(speaker: String, text: String, portrait: Texture2D = null) -> void:
	_queue.append({"speaker": speaker, "text": text, "portrait": portrait})
	if not _busy:
		_show_next()

func show_sequence(entries: Array[Dictionary], on_finished: Callable = Callable()) -> void:
	_queue = entries.duplicate()
	_on_finished = on_finished
	if not _busy:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		hide()
		if _on_finished.is_valid():
			_on_finished.call()
		return
	_busy = true
	var entry = _queue.pop_front()
	_speaker_label.text = entry.get("speaker", "")
	if entry.get("portrait"):
		_portrait.texture = entry["portrait"]
		_portrait.show()
	else:
		_portrait.hide()
	_current_text = entry.get("text", "")
	_char_index = 0
	_displayed_text = ""
	_text_label.text = ""
	show()
	_char_timer = 0.0

func _process(delta: float) -> void:
	if not _busy or not visible:
		return
	if _char_index < len(_current_text):
		_char_timer += delta * 60.0
		while _char_index < len(_current_text) and _char_timer >= 1.0:
			_char_timer -= 1.0
			_displayed_text += _current_text[_char_index]
			_char_index += 1
		_text_label.text = _displayed_text

func _input(event: InputEvent) -> void:
	if not _busy or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_ENTER:
				if _char_index < len(_current_text):
					_displayed_text = _current_text
					_text_label.text = _displayed_text
					_char_index = len(_current_text)
				else:
					_show_next()

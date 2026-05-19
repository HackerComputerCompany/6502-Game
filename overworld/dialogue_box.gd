extends CanvasLayer

var _queue: Array = []
var _busy: bool = false
var _char_timer: float = 0.0
var _char_index: int = 0
var _current_text: String = ""
var _displayed_text: String = ""
var _on_finished: Callable = Callable()
var _open_cooldown: float = 0.0

var _panel: Panel
var _speaker_label: Label
var _text_label: RichTextLabel
var _portrait: TextureRect

var _beep_player: AudioStreamPlayer
var _advance_player: AudioStreamPlayer
var _open_player: AudioStreamPlayer
var _beep_pitch: float = 1.0
var _beep_counter: int = 0

func _ready() -> void:
	_beep_player = AudioStreamPlayer.new()
	_beep_player.volume_db = -8.0
	add_child(_beep_player)

	_advance_player = AudioStreamPlayer.new()
	_advance_player.volume_db = -6.0
	add_child(_advance_player)

	_open_player = AudioStreamPlayer.new()
	_open_player.volume_db = -4.0
	add_child(_open_player)

	_panel = Panel.new()
	_panel.size = Vector2(600, 80)
	_panel.position = Vector2(20, 380)
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.01
	vbox.anchor_top = 0.05
	vbox.anchor_right = 0.99
	vbox.anchor_bottom = 0.95
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
	_speaker_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_speaker_label.add_theme_font_size_override("font_size", 14)
	_speaker_label.text = ""
	text_vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.add_theme_color_override("default_color", Color(1, 1, 1))
	_text_label.add_theme_font_size_override("normal_font_size", 13)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	text_vbox.add_child(_text_label)

	hide()

func _make_beep_stream(pitch: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.04
	var samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / float(sample_rate)
		var val: float = sin(2.0 * PI * 800.0 * pitch * t) * 0.3
		var envelope: float = max(0.0, 1.0 - t / duration)
		var sample: int = int(val * envelope * 32767.0)
		sample = clampi(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _make_advance_stream() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.08
	var samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / float(sample_rate)
		var val: float = sin(2.0 * PI * 1200.0 * t) * 0.25 + sin(2.0 * PI * 600.0 * t) * 0.15
		var envelope: float = max(0.0, 1.0 - (t / duration) * 2.0)
		var sample: int = int(val * envelope * 32767.0)
		sample = clampi(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _make_open_stream() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.1
	var samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / float(sample_rate)
		var freq: float = 400.0 + 600.0 * (t / duration)
		var val: float = sin(2.0 * PI * freq * t) * 0.2
		var envelope: float = max(0.0, 1.0 - t / duration)
		var sample: int = int(val * envelope * 32767.0)
		sample = clampi(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _make_panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0)
	s.border_width_left = 3
	s.border_width_top = 3
	s.border_width_right = 3
	s.border_width_bottom = 3
	s.border_color = Color(0.8, 0.8, 0.8)
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_right = 4
	s.corner_radius_bottom_left = 4
	return s

func show_text(speaker: String, text: String, portrait: Texture2D = null) -> void:
	_queue.append({"speaker": speaker, "text": text, "portrait": portrait})
	if not _busy:
		_show_next()

func show_sequence(entries: Array, on_finished: Callable = Callable()) -> void:
	_queue = entries.duplicate()
	_on_finished = on_finished
	if not _busy:
		_show_next()

func advance() -> void:
	if not _busy or not visible:
		return
	if _open_cooldown > 0.0:
		return
	if _char_index < len(_current_text):
		_displayed_text = _current_text
		_text_label.text = _displayed_text
		_char_index = len(_current_text)
	else:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		hide()
		_busy = false
		var callback := _on_finished
		_on_finished = Callable()
		if callback.is_valid():
			callback.call()
		return
	_busy = true
	var entry = _queue.pop_front()
	_speaker_label.text = str(entry.get("speaker", ""))
	if entry.get("portrait"):
		_portrait.texture = entry["portrait"]
		_portrait.show()
	else:
		_portrait.hide()
	_current_text = str(entry.get("text", ""))
	_char_index = 0
	_displayed_text = ""
	_text_label.text = ""
	show()
	_char_timer = 0.0
	_open_cooldown = 0.15
	_beep_counter = 0
	_open_player.stream = _make_open_stream()
	_open_player.play()

func _process(delta: float) -> void:
	if _open_cooldown > 0.0:
		_open_cooldown -= delta
	if not _busy or not visible:
		return
	if _char_index < len(_current_text):
		_char_timer += delta * 30.0
		while _char_index < len(_current_text) and _char_timer >= 1.0:
			_char_timer -= 1.0
			_displayed_text += _current_text[_char_index]
			_char_index += 1
			_beep_counter += 1
			if _beep_counter % 2 == 0:
				_beep_pitch = 1.0 + (_char_index % 3) * 0.15
				_beep_player.stream = _make_beep_stream(_beep_pitch)
				_beep_player.play()
		_text_label.text = _displayed_text
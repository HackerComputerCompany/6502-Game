class_name SoundManager
extends Node

var _key_player: AudioStreamPlayer
var _bell_player: AudioStreamPlayer
var _line_feed_player: AudioStreamPlayer
var _carriage_player: AudioStreamPlayer
var _error_player: AudioStreamPlayer

var _key_stream: AudioStreamWAV
var _bell_stream: AudioStreamWAV
var _line_feed_stream: AudioStreamWAV
var _carriage_stream: AudioStreamWAV
var _error_stream: AudioStreamWAV

var _crackle_player: AudioStreamPlayer
var _crackle_stream: AudioStreamWAV

var sound_enabled: bool = true
var volume_db: float = -6.0

func _ready() -> void:
	_key_stream = _generate_click(400, 0.025, 0.03)
	_bell_stream = _generate_bell()
	_line_feed_stream = _generate_click(300, 0.06, 0.08)
	_carriage_stream = _generate_carriage()
	_error_stream = _generate_click(200, 0.08, 0.15)
	
	_key_player = AudioStreamPlayer.new()
	_key_player.stream = _key_stream
	_key_player.volume_db = volume_db
	add_child(_key_player)
	
	_bell_player = AudioStreamPlayer.new()
	_bell_player.stream = _bell_stream
	_bell_player.volume_db = volume_db
	add_child(_bell_player)
	
	_line_feed_player = AudioStreamPlayer.new()
	_line_feed_player.stream = _line_feed_stream
	_line_feed_player.volume_db = volume_db
	add_child(_line_feed_player)
	
	_carriage_player = AudioStreamPlayer.new()
	_carriage_player.stream = _carriage_stream
	_carriage_player.volume_db = volume_db
	add_child(_carriage_player)
	
	_error_player = AudioStreamPlayer.new()
	_error_player.stream = _error_stream
	_error_player.volume_db = volume_db + 3.0
	add_child(_error_player)
	
	_crackle_stream = _generate_crackle()
	_crackle_player = AudioStreamPlayer.new()
	_crackle_player.stream = _crackle_stream
	_crackle_player.volume_db = volume_db
	add_child(_crackle_player)

func play_key() -> void:
	if not sound_enabled:
		return
	if not _key_player.playing:
		_key_player.play()
	else:
		_key_player.stop()
		_key_player.play()

func play_bell() -> void:
	if not sound_enabled:
		return
	if not _bell_player.playing:
		_bell_player.play()
	else:
		_bell_player.stop()
		_bell_player.play()

func play_line_feed() -> void:
	if not sound_enabled:
		return
	if not _line_feed_player.playing:
		_line_feed_player.play()
	else:
		_line_feed_player.stop()
		_line_feed_player.play()

func play_carriage() -> void:
	if not sound_enabled:
		return
	if not _carriage_player.playing:
		_carriage_player.play()

func play_error() -> void:
	if not sound_enabled:
		return
	if not _error_player.playing:
		_error_player.play()

func play_crackle() -> void:
	if not sound_enabled:
		return
	_crackle_player.stop()
	_crackle_player.play()

func _generate_click(freq: float, duration: float, decay: float) -> AudioStreamWAV:
	var sample_rate = 44100
	var samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t / decay)
		var noise = randf_range(-1.0, 1.0) * 0.3
		var tone = sin(2.0 * PI * freq * t) * 0.5
		var sample = clampf((tone + noise) * envelope, -1.0, 1.0)
		var val = int(sample * 32767.0)
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _generate_bell() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.3
	var samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t / 0.12)
		var bell = sin(2.0 * PI * 800.0 * t) * 0.6
		bell += sin(2.0 * PI * 1600.0 * t) * 0.15
		bell += sin(2.0 * PI * 2400.0 * t) * 0.05
		var sample = clampf(bell * envelope, -1.0, 1.0)
		var val = int(sample * 32767.0)
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _generate_crackle() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 1.5
	var samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t / 0.3)
		var crackle = 0.0
		if randf() < 0.04:
			crackle = randf_range(-1.0, 1.0) * 0.8
		var hiss = randf_range(-1.0, 1.0) * 0.15
		var pop = sin(2.0 * PI * 150.0 * t) * 0.2 * exp(-fmod(t * 20.0, 1.0) / 0.1)
		var sample = clampf((crackle + hiss + pop) * envelope, -1.0, 1.0)
		var val = int(sample * 32767.0)
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _generate_carriage() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.15
	var samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t / 0.05)
		var noise = randf_range(-1.0, 1.0) * 0.6
		var tick = sin(2.0 * PI * 120.0 * t) * 0.3
		var sample = clampf((noise + tick) * envelope, -1.0, 1.0)
		var val = int(sample * 32767.0)
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
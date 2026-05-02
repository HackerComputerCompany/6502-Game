class_name DebugManager
extends Node

var _screenshot_dir: String = "user://debug/screenshots"
var _video_dir: String = "user://debug/video"
var _is_recording: bool = false
var _frames: Array = []
var _frame_interval: float = 1.0 / 30.0
var _frame_timer: float = 0.0
var _video_width: int = 960
var _video_height: int = 720

signal debug_log(message: String)

func _ready() -> void:
	_ensure_dirs()

func _ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(_screenshot_dir)
	DirAccess.make_dir_recursive_absolute(_video_dir)

func _process(delta: float) -> void:
	if _is_recording:
		_frame_timer += delta
		if _frame_timer >= _frame_interval:
			_frame_timer -= _frame_interval
			_capture_frame()

func _capture_frame() -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		_frames.append(img)

func take_screenshot() -> String:
	var img = get_viewport().get_texture().get_image()
	if img == null:
		debug_log.emit("SCREENSHOT: Failed to capture")
		return ""
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var filename = _screenshot_dir + "/screenshot_%s.png" % timestamp
	var err = img.save_png(filename)
	if err == OK:
		debug_log.emit("SCREENSHOT: Saved " + filename)
		return filename
	debug_log.emit("SCREENSHOT: Error saving screenshot")
	return ""

func start_recording() -> void:
	if _is_recording:
		return
	_is_recording = true
	_frames.clear()
	_frame_timer = 0.0
	debug_log.emit("VIDEO: Recording started")

func stop_recording() -> String:
	if not _is_recording:
		debug_log.emit("VIDEO: Not recording")
		return ""
	_is_recording = false
	if _frames.size() == 0:
		debug_log.emit("VIDEO: No frames captured")
		return ""
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var dir = _video_dir + "/frames_%s" % timestamp
	DirAccess.make_dir_recursive_absolute(dir)
	for i in range(_frames.size()):
		var filename = dir + "/frame_%05d.png" % i
		_frames[i].save_png(filename)
	debug_log.emit("VIDEO: Saved %d frames to %s" % [_frames.size(), dir])
	debug_log.emit("VIDEO: Convert with: ffmpeg -framerate 30 -i %s/frame_%%05d.png -c:v libx264 -pix_fmt yuv420p output.mp4" % dir)
	_frames.clear()
	return dir

func toggle_recording() -> void:
	if _is_recording:
		stop_recording()
	else:
		start_recording()

func is_recording() -> bool:
	return _is_recording

func get_frame_count() -> int:
	return _frames.size()

func execute_command(cmd: String) -> String:
	var parts = cmd.strip_edges().split(" ")
	var action = parts[0].to_lower()
	match action:
		"screenshot", "ss":
			return take_screenshot()
		"record", "rec":
			start_recording()
			return "Recording started"
		"stop":
			return stop_recording()
		"toggle":
			toggle_recording()
			return "Recording: " + str(_is_recording)
		"status":
			return "Recording: %s | Frames: %d | FPS: 30" % [str(_is_recording), _frames.size()]
		"help":
			return _help_text()
		_:
			return "Unknown debug command: %s. Type 'help' for commands." % action

func _help_text() -> String:
	return """Debug Commands:
  screenshot / ss    - Take a screenshot (saved to user://debug/screenshots/)
  record / rec       - Start video recording
  stop               - Stop recording and save frames
  toggle             - Toggle recording on/off
  status             - Show recording status
  help               - Show this help

Video Export:
  After stop, convert frames to MP4:
  ffmpeg -framerate 30 -i <frame_dir>/frame_%05d.png -c:v libx264 -pix_fmt yuv420p output.mp4"""
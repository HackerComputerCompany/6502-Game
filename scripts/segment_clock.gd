extends Control

var display_time: String = "12:00"
var _display_mode: int = 0

const MODE_GREEN := 0
const MODE_RED := 1
const MODE_OFF := 2

const _SEGMENT_PATTERNS: Array[int] = [
	0b0111111, 0b0000110, 0b1011011, 0b1001111, 0b1100110,
	0b1101101, 0b1111101, 0b0000111, 0b1111111, 0b1101111,
]

const SEGMENT_THICK: float = 2.0
const DIGIT_W: float = 10.0
const DIGIT_H: float = 22.0
const GAP: float = 2.0
const COLON_W: float = 6.0
const COLON_DOT_R: float = 1.5

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_display_mode = (_display_mode + 1) % 3
		queue_redraw()
		accept_event()

func set_time(t: String) -> void:
	display_time = t
	queue_redraw()

func set_display_mode(m: int) -> void:
	_display_mode = m
	queue_redraw()

func get_display_mode() -> int:
	return _display_mode

func _char_x(idx: int) -> float:
	var x: float = 0.0
	for i in range(idx):
		if i == 2:
			x += COLON_W
		else:
			x += DIGIT_W + GAP
	return x

func _draw() -> void:
	var on_color: Color
	if _display_mode == MODE_GREEN:
		on_color = Color(0.0, 0.8, 0.0, 1.0)
	elif _display_mode == MODE_RED:
		on_color = Color(0.8, 0.0, 0.0, 1.0)
	else:
		on_color = Color(0.0, 0.0, 0.0, 0.0)
	var dim := Color(0.0, 0.3, 0.0, 0.3)
	var ox := 2.0
	var oy := (size.y - DIGIT_H) / 2.0
	var ch_idx := 0
	for i in range(display_time.length()):
		var ch := display_time[i]
		if ch == ':':
			var cx := ox + _char_x(ch_idx) + COLON_W / 2.0
			var cy := oy + DIGIT_H / 2.0 - COLON_DOT_R
			if _display_mode != MODE_OFF:
				draw_circle(Vector2(cx, cy), COLON_DOT_R, on_color)
				draw_circle(Vector2(cx, cy + 8.0), COLON_DOT_R, on_color)
			else:
				draw_circle(Vector2(cx, cy), COLON_DOT_R, dim)
				draw_circle(Vector2(cx, cy + 8.0), COLON_DOT_R, dim)
			continue
		if ch < '0' or ch > '9':
			continue
		var digit := int(ch)
		var pat := _SEGMENT_PATTERNS[digit]
		var dx := ox + _char_x(ch_idx)
		_draw_digit(dx, oy, pat, on_color, dim)
		ch_idx += 1
	custom_minimum_size.x = ox + _char_x(4) + DIGIT_W

func _draw_digit(x: float, y: float, pattern: int, col: Color, dim: Color) -> void:
	var hh := DIGIT_H / 2.0
	if pattern & (1 << 0):
		draw_rect(Rect2(x, y, DIGIT_W, SEGMENT_THICK), col)
	else:
		draw_rect(Rect2(x, y, DIGIT_W, SEGMENT_THICK), dim)
	if pattern & (1 << 1):
		draw_rect(Rect2(x + DIGIT_W - SEGMENT_THICK, y + SEGMENT_THICK, SEGMENT_THICK, hh - SEGMENT_THICK), col)
	else:
		draw_rect(Rect2(x + DIGIT_W - SEGMENT_THICK, y + SEGMENT_THICK, SEGMENT_THICK, hh - SEGMENT_THICK), dim)
	if pattern & (1 << 2):
		draw_rect(Rect2(x + DIGIT_W - SEGMENT_THICK, y + hh, SEGMENT_THICK, hh - SEGMENT_THICK), col)
	else:
		draw_rect(Rect2(x + DIGIT_W - SEGMENT_THICK, y + hh, SEGMENT_THICK, hh - SEGMENT_THICK), dim)
	if pattern & (1 << 3):
		draw_rect(Rect2(x, y + DIGIT_H - SEGMENT_THICK, DIGIT_W, SEGMENT_THICK), col)
	else:
		draw_rect(Rect2(x, y + DIGIT_H - SEGMENT_THICK, DIGIT_W, SEGMENT_THICK), dim)
	if pattern & (1 << 4):
		draw_rect(Rect2(x, y + hh, SEGMENT_THICK, hh - SEGMENT_THICK), col)
	else:
		draw_rect(Rect2(x, y + hh, SEGMENT_THICK, hh - SEGMENT_THICK), dim)
	if pattern & (1 << 5):
		draw_rect(Rect2(x, y + SEGMENT_THICK, SEGMENT_THICK, hh - SEGMENT_THICK), col)
	else:
		draw_rect(Rect2(x, y + SEGMENT_THICK, SEGMENT_THICK, hh - SEGMENT_THICK), dim)
	if pattern & (1 << 6):
		draw_rect(Rect2(x, y + hh - SEGMENT_THICK / 2.0, DIGIT_W, SEGMENT_THICK), col)
	else:
		draw_rect(Rect2(x, y + hh - SEGMENT_THICK / 2.0, DIGIT_W, SEGMENT_THICK), dim)

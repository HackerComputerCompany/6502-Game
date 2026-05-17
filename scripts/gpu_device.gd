## Memory-mapped GPU device ($E000-$EFFF) for the Teaching Lab.
##
## Provides two display modes:
##   TEXT (default)  — 40x25 character grid, 5x7 pixel font, 16 colors per cell.
##   BITMAP — 160x120 pixel framebuffer, 16-color indexed palette.
##
## Drawing API (bitmap mode):
##   Set draw_x/y via $EFF5-8, color via $EFF9, optional aux_x/y via $EFFB-E,
##   then write a command byte to $EFFF to execute: PLOT, LINE, RECT, CIRCLE, etc.
##
## The UI terminal polls gpu._dirty and calls render_to_image() to update a
## TextureRect display panel (toggled via F12 or GRAPHICS command).
extends "res://scripts/gpu_base.gd"

## Base address of GPU address range.
const GPU_BASE := 0xE000
## End address (inclusive).
const GPU_END := 0xEFFF

const TEXT_COLS := 40
const TEXT_ROWS := 25
const TEXT_CELLS := TEXT_COLS * TEXT_ROWS

## Control registers (memory-mapped, 8-bit each).
const REG_MODE := 0xEFF0
const REG_FG := 0xEFF1
const REG_BG := 0xEFF2
const REG_CURSOR_X := 0xEFF3
const REG_CURSOR_Y := 0xEFF4
const REG_PIX_X_L := 0xEFF5
const REG_PIX_X_H := 0xEFF6
const REG_PIX_Y_L := 0xEFF7
const REG_PIX_Y_H := 0xEFF8
const REG_PIX_COLOR := 0xEFF9
const REG_PIX_READ := 0xEFFA
## Auxiliary registers for command parameter 2 (X2, right-edge, or radius).
const REG_AUX_X_L := 0xEFFB
const REG_AUX_X_H := 0xEFFC
const REG_AUX_Y_L := 0xEFFD
const REG_AUX_Y_H := 0xEFFE
## Command register — writing a command byte executes a draw operation.
const REG_COMMAND := 0xEFFF

## Draw command values written to REG_COMMAND.
const CMD_NOP := 0
const CMD_PLOT := 1
const CMD_LINE := 2
const CMD_RECT := 3
const CMD_RECT_OUT := 4
const CMD_HLINE := 5
const CMD_VLINE := 6
const CMD_CIRCLE := 7
const CMD_CIRCLE_FILL := 8
const CMD_CLS := 9
## Copy a rectangular region within the bitmap framebuffer.
## Source: (draw_x, draw_y), size (aux_x, aux_y).
## Destination: (cursor_x, cursor_y). Clips to framebuffer bounds.
const CMD_BLIT := 10

const MODE_TEXT := 0
const MODE_BITMAP := 1
## Both text and bitmap layers simultaneously (overlay). Text renders with
## transparent background so the bitmap layer shows through.
const MODE_TEXT_BITMAP := 3

const FB_WIDTH := 160
const FB_HEIGHT := 120

const PALETTE: Array = [
	Color(0.00, 0.00, 0.00),
	Color(0.00, 0.00, 0.67),
	Color(0.00, 0.67, 0.00),
	Color(0.00, 0.67, 0.67),
	Color(0.67, 0.00, 0.00),
	Color(0.67, 0.00, 0.67),
	Color(0.67, 0.33, 0.00),
	Color(0.67, 0.67, 0.67),
	Color(0.33, 0.33, 0.33),
	Color(0.33, 0.33, 1.00),
	Color(0.33, 1.00, 0.33),
	Color(0.33, 1.00, 1.00),
	Color(1.00, 0.33, 0.33),
	Color(1.00, 0.33, 1.00),
	Color(1.00, 1.00, 0.33),
	Color(1.00, 1.00, 1.00),
]

var mode: int = MODE_TEXT
var fg_color: int = 15
var bg_color: int = 0
var cursor_x: int = 0
var cursor_y: int = 0
var draw_x: int = 0
var draw_y: int = 0
var draw_color: int = 15
var aux_x: int = 0
var aux_y: int = 0

var _text_buf: PackedByteArray
var _attr_buf: PackedByteArray
var _bitmap_fb: PackedByteArray
func _init() -> void:
	name = "GPU"
	_text_buf.resize(TEXT_CELLS)
	_text_buf.fill(ord(" "))
	_attr_buf.resize(TEXT_CELLS)
	_attr_buf.fill(0)
	_bitmap_fb.resize(FB_WIDTH * FB_HEIGHT)
	_bitmap_fb.fill(0)

func handles_address(addr: int) -> bool:
	return addr >= GPU_BASE and addr <= GPU_END

func peek(addr: int) -> int:
	addr = addr & 0xFFFF
	if addr < REG_MODE:
		if addr < GPU_BASE + TEXT_CELLS:
			return _text_buf[addr - GPU_BASE] & 0xFF
		if addr < GPU_BASE + TEXT_CELLS * 2:
			return _attr_buf[addr - GPU_BASE - TEXT_CELLS] & 0xFF
		return 0
	match addr:
		REG_MODE: return mode & 0xFF
		REG_FG: return fg_color & 0xFF
		REG_BG: return bg_color & 0xFF
		REG_CURSOR_X: return cursor_x & 0xFF
		REG_CURSOR_Y: return cursor_y & 0xFF
		REG_PIX_X_L: return draw_x & 0xFF
		REG_PIX_X_H: return (draw_x >> 8) & 0xFF
		REG_PIX_Y_L: return draw_y & 0xFF
		REG_PIX_Y_H: return (draw_y >> 8) & 0xFF
		REG_PIX_COLOR: return draw_color & 0xFF
		REG_PIX_READ:
			var idx := draw_y * FB_WIDTH + draw_x
			if draw_x >= 0 and draw_x < FB_WIDTH and draw_y >= 0 and draw_y < FB_HEIGHT:
				return _bitmap_fb[idx] & 0xFF
			return 0
		REG_AUX_X_L: return aux_x & 0xFF
		REG_AUX_X_H: return (aux_x >> 8) & 0xFF
		REG_AUX_Y_L: return aux_y & 0xFF
		REG_AUX_Y_H: return (aux_y >> 8) & 0xFF
		REG_COMMAND: return 0
	return 0

func poke(addr: int, val: int) -> void:
	addr = addr & 0xFFFF
	val = val & 0xFF
	if addr < REG_MODE:
		if addr < GPU_BASE + TEXT_CELLS:
			_text_buf[addr - GPU_BASE] = val
		elif addr < GPU_BASE + TEXT_CELLS * 2:
			_attr_buf[addr - GPU_BASE - TEXT_CELLS] = val
		_dirty = true
		framebuffer_updated.emit()
		return
	match addr:
		REG_MODE:
			mode = val
			_dirty = true
			framebuffer_updated.emit()
		REG_FG: fg_color = val & 0x0F
		REG_BG: bg_color = val & 0x0F
		REG_CURSOR_X: cursor_x = val & 0xFF
		REG_CURSOR_Y: cursor_y = val & 0xFF
		REG_PIX_X_L: draw_x = (draw_x & 0xFF00) | val
		REG_PIX_X_H: draw_x = (draw_x & 0x00FF) | (val << 8)
		REG_PIX_Y_L: draw_y = (draw_y & 0xFF00) | val
		REG_PIX_Y_H: draw_y = (draw_y & 0x00FF) | (val << 8)
		REG_PIX_COLOR:
			draw_color = val & 0x0F
		REG_AUX_X_L: aux_x = (aux_x & 0xFF00) | val
		REG_AUX_X_H: aux_x = (aux_x & 0x00FF) | (val << 8)
		REG_AUX_Y_L: aux_y = (aux_y & 0xFF00) | val
		REG_AUX_Y_H: aux_y = (aux_y & 0x00FF) | (val << 8)
		REG_COMMAND: _execute_command(val)

func _plot_pixel(x: int, y: int, color: int) -> void:
	if x >= 0 and x < FB_WIDTH and y >= 0 and y < FB_HEIGHT:
		_bitmap_fb[y * FB_WIDTH + x] = color & 0x0F
		_dirty = true
		framebuffer_updated.emit()

## Dispatch a draw command using current register values.
func _execute_command(cmd: int) -> void:
	match cmd:
		CMD_PLOT:
			_plot_pixel(draw_x, draw_y, draw_color)
		CMD_LINE:
			_draw_line(draw_x, draw_y, aux_x, aux_y, draw_color)
		CMD_RECT:
			_fill_rect(draw_x, draw_y, aux_x, aux_y, draw_color)
		CMD_RECT_OUT:
			_draw_rect_outline(draw_x, draw_y, aux_x, aux_y, draw_color)
		CMD_HLINE:
			_draw_hline(draw_x, aux_x, draw_y, draw_color)
		CMD_VLINE:
			_draw_vline(draw_x, draw_y, aux_y, draw_color)
		## Radius is aux_x, clamped to safe range.
		CMD_CIRCLE:
			_draw_circle(draw_x, draw_y, clampi(aux_x, 1, 120), draw_color)
		CMD_CIRCLE_FILL:
			_fill_circle(draw_x, draw_y, clampi(aux_x, 1, 120), draw_color)
		CMD_CLS:
			_clear_bitmap()
		CMD_BLIT:
			_blit_rect(draw_x, draw_y, aux_x, aux_y, cursor_x, cursor_y)

## Bresenham line algorithm from (x0,y0) to (x1,y1).
func _draw_line(x0: int, y0: int, x1: int, y1: int, color: int) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		_plot_pixel(x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

## Fill a rectangle from (x0,y0) to (x1,y1) inclusive. Clips to framebuffer bounds.
func _fill_rect(x0: int, y0: int, x1: int, y1: int, color: int) -> void:
	var minx := clampi(mini(x0, x1), 0, FB_WIDTH - 1)
	var maxx := clampi(maxi(x0, x1), 0, FB_WIDTH - 1)
	var miny := clampi(mini(y0, y1), 0, FB_HEIGHT - 1)
	var maxy := clampi(maxi(y0, y1), 0, FB_HEIGHT - 1)
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			_bitmap_fb[y * FB_WIDTH + x] = color & 0x0F
	_dirty = true
	framebuffer_updated.emit()

## Draw the outline of a rectangle using four HLINE/VLINE calls.
func _draw_rect_outline(x0: int, y0: int, x1: int, y1: int, color: int) -> void:
	_draw_hline(x0, x1, y0, color)
	_draw_hline(x0, x1, y1, color)
	_draw_vline(x0, y0, y1, color)
	_draw_vline(x1, y0, y1, color)

## Fast horizontal line from x0 to x1 at row y. Writes directly to framebuffer.
func _draw_hline(x0: int, x1: int, y: int, color: int) -> void:
	if y < 0 or y >= FB_HEIGHT:
		return
	var minx := clampi(mini(x0, x1), 0, FB_WIDTH - 1)
	var maxx := clampi(maxi(x0, x1), 0, FB_WIDTH - 1)
	var row := y * FB_WIDTH
	var c := color & 0x0F
	for x in range(minx, maxx + 1):
		_bitmap_fb[row + x] = c
	_dirty = true
	framebuffer_updated.emit()

## Fast vertical line from y0 to y1 at column x. Writes directly to framebuffer.
func _draw_vline(x: int, y0: int, y1: int, color: int) -> void:
	if x < 0 or x >= FB_WIDTH:
		return
	var miny := clampi(mini(y0, y1), 0, FB_HEIGHT - 1)
	var maxy := clampi(maxi(y0, y1), 0, FB_HEIGHT - 1)
	var c := color & 0x0F
	for y in range(miny, maxy + 1):
		_bitmap_fb[y * FB_WIDTH + x] = c
	_dirty = true
	framebuffer_updated.emit()

## Bresenham circle outline at center (cx,cy) with radius r. Plots 8 symmetric points.
func _draw_circle(cx: int, cy: int, r: int, color: int) -> void:
	var x := 0
	var y := r
	var d := 3 - 2 * r
	while x <= y:
		_plot_pixel(cx + x, cy + y, color)
		_plot_pixel(cx - x, cy + y, color)
		_plot_pixel(cx + x, cy - y, color)
		_plot_pixel(cx - x, cy - y, color)
		_plot_pixel(cx + y, cy + x, color)
		_plot_pixel(cx - y, cy + x, color)
		_plot_pixel(cx + y, cy - x, color)
		_plot_pixel(cx - y, cy - x, color)
		if d < 0:
			d += 4 * x + 6
		else:
			d += 4 * (x - y) + 10
			y -= 1
		x += 1

## Filled circle by scanning each row and drawing horizontal spans.
func _fill_circle(cx: int, cy: int, r: int, color: int) -> void:
	for dy in range(-r, r + 1):
		var dx := int(sqrt(r * r - dy * dy))
		_draw_hline(cx - dx, cx + dx, cy + dy, color)

func _blit_rect(src_x: int, src_y: int, w: int, h: int, dst_x: int, dst_y: int) -> void:
	if w <= 0 or h <= 0:
		return
	var sw := mini(w, FB_WIDTH - src_x)
	var sh := mini(h, FB_HEIGHT - src_y)
	if sw <= 0 or sh <= 0:
		return
	var dw := mini(sw, FB_WIDTH - dst_x)
	var dh := mini(sh, FB_HEIGHT - dst_y)
	if dw <= 0 or dh <= 0:
		return
	if dst_y <= src_y:
		for row in range(dh):
			var sy := src_y + row
			var dy := dst_y + row
			for col in range(dw):
				_bitmap_fb[dy * FB_WIDTH + dst_x + col] = _bitmap_fb[sy * FB_WIDTH + src_x + col]
	else:
		for row in range(dh - 1, -1, -1):
			var sy := src_y + row
			var dy := dst_y + row
			for col in range(dw):
				_bitmap_fb[dy * FB_WIDTH + dst_x + col] = _bitmap_fb[sy * FB_WIDTH + src_x + col]
	_dirty = true
	framebuffer_updated.emit()

func _clear_bitmap() -> void:
	_bitmap_fb.fill(bg_color & 0x0F)
	_dirty = true
	framebuffer_updated.emit()

func _text_layer_enabled() -> bool:
	return mode == MODE_TEXT or mode == MODE_TEXT_BITMAP

func _bitmap_layer_enabled() -> bool:
	return mode == MODE_BITMAP or mode == MODE_TEXT_BITMAP

func render_to_image() -> Image:
	var img := Image.create(FB_WIDTH, FB_HEIGHT, false, Image.FORMAT_RGBA8)
	var text_on := _text_layer_enabled()
	var bmp_on := _bitmap_layer_enabled()
	if bmp_on:
		for y in range(FB_HEIGHT):
			for x in range(FB_WIDTH):
				var c := _bitmap_fb[y * FB_WIDTH + x] & 0x0F
				img.set_pixel(x, y, PALETTE[c])
	if text_on:
		for row in range(TEXT_ROWS):
			for col in range(TEXT_COLS):
				var idx := row * TEXT_COLS + col
				var ch := _text_buf[idx]
				var attr := _attr_buf[idx]
				var fg := attr & 0x0F
				var bg := (attr >> 4) & 0x0F
				_draw_char(img, col * 4, row * 5, ch, fg, bg, bmp_on)
	_dirty = false
	return img

func _draw_char(img: Image, ox: int, oy: int, ch: int, fg: int, bg: int, transparent_bg: bool = false) -> void:
	var fgc = PALETTE[fg & 0x0F]
	var bgc = PALETTE[bg & 0x0F]
	for row in range(5):
		for col in range(4):
			var px := ox + col
			var py := oy + row
			if px >= 0 and px < FB_WIDTH and py >= 0 and py < FB_HEIGHT:
				var on := _font_pixel(ch, col, row)
				if on:
					img.set_pixel(px, py, fgc)
				elif not transparent_bg:
					img.set_pixel(px, py, bgc)

func _font_pixel(ch: int, col: int, row: int) -> bool:
	var idx := clampi(ch - 32, 0, 94)
	var bits := _FONT_DATA[idx * 7 + row]
	return (bits >> (6 - col)) & 1 == 1

func serialize() -> Dictionary:
	return {
		"mode": mode,
		"fg_color": fg_color,
		"bg_color": bg_color,
		"cursor_x": cursor_x,
		"cursor_y": cursor_y,
		"draw_x": draw_x,
		"draw_y": draw_y,
		"draw_color": draw_color,
		"aux_x": aux_x,
		"aux_y": aux_y,
		"text_buf": _text_buf.hex_encode(),
		"attr_buf": _attr_buf.hex_encode(),
		"bitmap_fb": _bitmap_fb.hex_encode(),
	}

func deserialize(data: Dictionary) -> void:
	mode = data.get("mode", MODE_TEXT)
	fg_color = data.get("fg_color", 15)
	bg_color = data.get("bg_color", 0)
	cursor_x = data.get("cursor_x", 0)
	cursor_y = data.get("cursor_y", 0)
	draw_x = data.get("draw_x", 0)
	draw_y = data.get("draw_y", 0)
	draw_color = data.get("draw_color", 15)
	aux_x = data.get("aux_x", 0)
	aux_y = data.get("aux_y", 0)
	if data.has("text_buf"):
		var dec: PackedByteArray = (data["text_buf"] as String).hex_decode()
		for i in range(mini(dec.size(), _text_buf.size())):
			_text_buf[i] = dec[i]
	if data.has("attr_buf"):
		var dec: PackedByteArray = (data["attr_buf"] as String).hex_decode()
		for i in range(mini(dec.size(), _attr_buf.size())):
			_attr_buf[i] = dec[i]
	if data.has("bitmap_fb"):
		var dec: PackedByteArray = (data["bitmap_fb"] as String).hex_decode()
		for i in range(mini(dec.size(), _bitmap_fb.size())):
			_bitmap_fb[i] = dec[i]
	_dirty = true
	framebuffer_updated.emit()

func reset() -> void:
	_text_buf.fill(ord(" "))
	_attr_buf.fill(0)
	_bitmap_fb.fill(0)
	mode = MODE_TEXT
	fg_color = 15
	bg_color = 0
	cursor_x = 0
	cursor_y = 0
	draw_x = 0
	draw_y = 0
	draw_color = 15
	aux_x = 0
	aux_y = 0
	_dirty = true
	framebuffer_updated.emit()

const _FONT_DATA: PackedByteArray = [
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	0x20,0x20,0x20,0x20,0x00,0x20,0x00,
	0x50,0x50,0x50,0x00,0x00,0x00,0x00,
	0x50,0xF8,0x50,0xF8,0x50,0x00,0x00,
	0x20,0x78,0xA0,0x70,0x28,0xF0,0x20,
	0xC0,0xC8,0x10,0x20,0x40,0x98,0x18,
	0x40,0xA0,0x40,0xA8,0x90,0x68,0x00,
	0x10,0x20,0x40,0x00,0x00,0x00,0x00,
	0x10,0x20,0x40,0x40,0x40,0x20,0x10,
	0x40,0x20,0x10,0x10,0x10,0x20,0x40,
	0x00,0x20,0xA8,0x70,0xA8,0x20,0x00,
	0x00,0x20,0x20,0xF8,0x20,0x20,0x00,
	0x00,0x00,0x00,0x00,0x20,0x20,0x40,
	0x00,0x00,0x00,0xF8,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x20,0x00,
	0x00,0x08,0x10,0x20,0x40,0x80,0x00,
	0x70,0x88,0x98,0xA8,0xC8,0x88,0x70,
	0x20,0x60,0xA0,0x20,0x20,0x20,0xF8,
	0x70,0x88,0x08,0x10,0x60,0x80,0xF8,
	0x70,0x88,0x08,0x30,0x08,0x88,0x70,
	0x10,0x30,0x50,0x90,0xF8,0x10,0x10,
	0xF8,0x80,0xE0,0x10,0x08,0x88,0x70,
	0x30,0x40,0x80,0xF0,0x88,0x88,0x70,
	0xF8,0x08,0x10,0x20,0x40,0x40,0x40,
	0x70,0x88,0x88,0x70,0x88,0x88,0x70,
	0x70,0x88,0x88,0x78,0x08,0x10,0x60,
	0x00,0x00,0x20,0x00,0x20,0x00,0x00,
	0x00,0x00,0x20,0x00,0x20,0x20,0x40,
	0x08,0x10,0x20,0x40,0x20,0x10,0x08,
	0x00,0x00,0xF8,0x00,0xF8,0x00,0x00,
	0x40,0x20,0x10,0x08,0x10,0x20,0x40,
	0x70,0x88,0x08,0x10,0x20,0x00,0x20,
	0x70,0x88,0xB8,0xA8,0xB0,0x80,0x78,
	0x20,0x50,0x88,0x88,0xF8,0x88,0x88,
	0xF0,0x88,0x88,0xF0,0x88,0x88,0xF0,
	0x70,0x88,0x80,0x80,0x80,0x88,0x70,
	0xF0,0x88,0x88,0x88,0x88,0x88,0xF0,
	0xF8,0x80,0x80,0xF0,0x80,0x80,0xF8,
	0xF8,0x80,0x80,0xF0,0x80,0x80,0x80,
	0x70,0x88,0x80,0xB8,0x88,0x88,0x70,
	0x88,0x88,0x88,0xF8,0x88,0x88,0x88,
	0xF8,0x20,0x20,0x20,0x20,0x20,0xF8,
	0x08,0x08,0x08,0x08,0x08,0x88,0x70,
	0x88,0x90,0xA0,0xC0,0xA0,0x90,0x88,
	0x80,0x80,0x80,0x80,0x80,0x80,0xF8,
	0x88,0xD8,0xA8,0xA8,0x88,0x88,0x88,
	0x88,0x88,0xC8,0xA8,0x98,0x88,0x88,
	0x70,0x88,0x88,0x88,0x88,0x88,0x70,
	0xF0,0x88,0x88,0xF0,0x80,0x80,0x80,
	0x70,0x88,0x88,0x88,0xA8,0x90,0x68,
	0xF0,0x88,0x88,0xF0,0xA0,0x90,0x88,
	0x70,0x88,0x80,0x70,0x08,0x88,0x70,
	0xF8,0x20,0x20,0x20,0x20,0x20,0x20,
	0x88,0x88,0x88,0x88,0x88,0x88,0x70,
	0x88,0x88,0x88,0x88,0x50,0x50,0x20,
	0x88,0x88,0x88,0xA8,0xA8,0xD8,0x88,
	0x88,0x88,0x50,0x20,0x50,0x88,0x88,
	0x88,0x88,0x50,0x20,0x20,0x20,0x20,
	0xF8,0x08,0x10,0x20,0x40,0x80,0xF8,
	0x70,0x40,0x40,0x40,0x40,0x40,0x70,
	0x00,0x80,0x40,0x20,0x10,0x08,0x00,
	0x70,0x10,0x10,0x10,0x10,0x10,0x70,
	0x20,0x50,0x88,0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x00,0xF8,
	0x40,0x20,0x10,0x00,0x00,0x00,0x00,
	0x00,0x00,0x70,0x08,0x78,0x88,0x78,
	0x80,0x80,0xF0,0x88,0x88,0x88,0xF0,
	0x00,0x00,0x70,0x88,0x80,0x88,0x70,
	0x08,0x08,0x78,0x88,0x88,0x88,0x78,
	0x00,0x00,0x70,0x88,0xF8,0x80,0x70,
	0x18,0x20,0x20,0xF8,0x20,0x20,0x20,
	0x00,0x00,0x78,0x88,0x78,0x08,0x70,
	0x80,0x80,0xF0,0x88,0x88,0x88,0x88,
	0x20,0x00,0x60,0x20,0x20,0x20,0x70,
	0x10,0x00,0x30,0x10,0x10,0x10,0x90,
	0x80,0x80,0x88,0x90,0xE0,0x90,0x88,
	0x60,0x20,0x20,0x20,0x20,0x20,0x70,
	0x00,0x00,0xD0,0xA8,0xA8,0x88,0x88,
	0x00,0x00,0xF0,0x88,0x88,0x88,0x88,
	0x00,0x00,0x70,0x88,0x88,0x88,0x70,
	0x00,0x00,0xF0,0x88,0xF0,0x80,0x80,
	0x00,0x00,0x78,0x88,0x78,0x08,0x08,
	0x00,0x00,0xB0,0xC0,0x80,0x80,0x80,
	0x00,0x00,0x70,0x80,0x70,0x08,0xF0,
	0x40,0x40,0xE0,0x40,0x40,0x48,0x30,
	0x00,0x00,0x88,0x88,0x88,0x98,0x68,
	0x00,0x00,0x88,0x88,0x88,0x50,0x20,
	0x00,0x00,0x88,0x88,0xA8,0xA8,0x50,
	0x00,0x00,0x88,0x50,0x20,0x50,0x88,
	0x00,0x00,0x88,0x88,0x78,0x08,0x70,
	0x00,0x00,0xF8,0x10,0x20,0x40,0xF8,
	0x18,0x20,0x20,0x40,0x20,0x20,0x18,
	0x20,0x20,0x20,0x20,0x20,0x20,0x20,
	0xC0,0x20,0x20,0x10,0x20,0x20,0xC0,
	0x40,0xA8,0x10,0x00,0x00,0x00,0x00,
]

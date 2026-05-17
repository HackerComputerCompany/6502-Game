## Abstract base class for pluggable GPU devices.
##
## Defines the interface that all GPU implementations must provide.
## Extends io_device.gd with graphics-specific capabilities:
##   - Framebuffer rendering via render_to_image()
##   - Dirty-tracking for efficient UI polling
##   - framebuffer_updated signal for event-driven updates
##
## To create a new GPU type:
##   extends "res://scripts/gpu_base.gd"
##   func render_to_image() -> Image: ...
extends "res://scripts/io_device.gd"

## Set to true when framebuffer content changes. The UI polls this
## in _process() and calls render_to_image() when needed.
var _dirty: bool = true

## Emitted whenever the framebuffer content changes (from poke or draw commands).
signal framebuffer_updated()

## Render the current GPU state (text mode or bitmap framebuffer) to an Image.
## Called by the UI when _dirty is true. Returns RGBA8 Image at the
## GPU's native resolution.
func render_to_image() -> Image:
	return Image.create(160, 120, false, Image.FORMAT_RGBA8)

func serialize() -> Dictionary:
	return {}

func deserialize(data: Dictionary) -> void:
	_dirty = true
	framebuffer_updated.emit()

func reset() -> void:
	super()
	_dirty = true
	framebuffer_updated.emit()

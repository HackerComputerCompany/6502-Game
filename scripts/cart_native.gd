extends ROMCart

func _init() -> void:
	id = 4
	name = "NATIVE"
	description = "BASIC runtime switch: HYBRID vs IEEE754 soft-float NATIVE"
	prompt = "RUNTIME>"

func install() -> void:
	pass

func uninstall() -> void:
	pass

func handle_command(text: String) -> bool:
	var stripped := text.strip_edges()
	if stripped == "":
		return false
	var cmd := stripped.to_upper().split(" ", false)[0]
	match cmd:
		"HYBRID":
			computer.basic.set_runtime_mode_hybrid()
			computer.emit_richtext("[color=lime]BASIC arithmetic: HYBRID[/color]\n")
			return true
		"NATIVE":
			computer.basic.set_runtime_mode_native()
			computer.emit_richtext("[color=lime]BASIC arithmetic: NATIVE (IEEE soft-float)[/color]\n")
			return true
		"STATUS":
			var native_on: bool = computer.basic.is_runtime_mode_native()
			var tag := "NATIVE (IEEE soft-float)" if native_on else "HYBRID (GDScript float)"
			computer.emit_richtext("[color=cyan]BASIC runtime: %s[/color]\n" % tag)
			return true
		"HELP":
			computer.emit_richtext(help_text())
			return true
	return false

func help_text() -> String:
	var h := "\n[color=cyan]NATIVE runtime cart[/color]\n"
	h += "  [yellow]HYBRID[/yellow]   Fast path: GDScript float for + − × ÷\n"
	h += "  [yellow]NATIVE[/yellow]   Portable path: IEEE754 soft-float (+ − × ÷, unary −)\n"
	h += "  [yellow]STATUS[/yellow]   Show active mode\n"
	h += "  [yellow]HELP[/yellow]     This text\n"
	h += "[color=gray]^ exponent ( ), transcendental builtins still use GDScript.[/color]\n"
	h += "[color=gray]Return: [white]CART BASIC[/color][/color]\n"
	return h

func banner_text() -> String:
	return "[color=cyan]*** RUNTIME cart — HYBRID / NATIVE IEEE soft-float ***[/color]\n"

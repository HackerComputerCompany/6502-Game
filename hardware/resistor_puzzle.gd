extends "res://hardware/puzzle_base.gd"

var _bands: Array = []
var _correct_value: String = ""
var _unit: String = ""

var _band_colors := {
	"black": 0, "brown": 1, "red": 2, "orange": 3, "yellow": 4,
	"green": 5, "blue": 6, "violet": 7, "gray": 8, "white": 9,
}

var _color_names := ["black", "brown", "red", "orange", "yellow", "green", "blue", "violet", "gray", "white"]

func _init() -> void:
	puzzle_id = "resistor_basics_1"
	puzzle_name = "Resistor Color Codes"
	description = "Identify resistor values by their color bands."
	_generate()

func _generate() -> void:
	var d1 := randi() % 10
	var d2 := randi() % 10
	var mult := randi() % 6
	var val := (d1 * 10 + d2) * int(pow(10, mult))
	_correct_value = _format_value(val)
	var tolerance := "gold"
	_bands = [_color_names[d1], _color_names[d2], _color_names[mult], "gold"]
	_unit = _get_unit(val)

func _format_value(val: int) -> String:
	if val >= 1_000_000:
		return "%dM" % (val / 1_000_000)
	elif val >= 1_000:
		return "%dK" % (val / 1_000)
	return str(val)

func _get_unit(val: int) -> String:
	if val >= 1_000_000:
		return "M\u03A9"
	elif val >= 1_000:
		return "K\u03A9"
	return "\u03A9"

func get_question() -> String:
	var band_str := ""
	for i in 3:
		if i > 0:
			band_str += ", "
		band_str += _bands[i].capitalize()
	band_str += " (" + _bands[3].capitalize() + " tolerance)"
	return "A resistor has bands: %s.\nWhat is its value?" % band_str

func get_hint() -> String:
	return "The first two bands are digits, the third is the multiplier. Black=0, Brown=1, Red=2, Orange=3, Yellow=4, Green=5, Blue=6, Violet=7, Gray=8, White=9.\nExample: Red-Red-Orange = 22 × 1000 = 22K\u03A9"

func check_solution(input: String) -> bool:
	var cleaned := input.strip_edges().to_upper().replace(" ", "")
	var expected := _correct_value.to_upper().replace(" ", "")
	var with_unit := expected + "O"
	var expected_full := expected + _unit.to_upper().replace("\u03A9", "O")
	return cleaned == expected or cleaned == with_unit or cleaned == expected_full

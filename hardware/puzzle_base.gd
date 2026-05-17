extends RefCounted

var puzzle_id: String = ""
var puzzle_name: String = ""
var description: String = ""
var solved: bool = false

func check_solution(_input: String) -> bool:
	return false

func get_question() -> String:
	return ""

func get_hint() -> String:
	return ""

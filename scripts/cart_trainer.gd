extends ROMCart

var _curriculum: Dictionary = {}
var _completed: Array = []
var _scores: Dictionary = {}
var _current_module_idx: int = 0
var _current_lesson_idx: int = 0
var _quiz_active: bool = false
var _quiz_index: int = 0
var _quiz_answers: Array = []

const CURRICULUM_PATH: String = "res://trainer/curriculum.json"

func _init() -> void:
	id = 5
	name = "TRAINER"
	description = "Interactive BASIC6502 & ASM lessons with quizzes"
	prompt = "LEARN>"
	manifest = {"cpus": ["6502"]}

func install() -> void:
	_load_curriculum()

func reboot_clear_state() -> void:
	_completed.clear()
	_scores.clear()
	_current_module_idx = 0
	_current_lesson_idx = 0
	_quiz_active = false
	_quiz_index = 0
	_quiz_answers.clear()

func serialize() -> Dictionary:
	return {
		"completed": _completed.duplicate(),
		"scores": _scores.duplicate(true),
		"module_idx": _current_module_idx,
		"lesson_idx": _current_lesson_idx,
	}

func deserialize(data: Dictionary) -> void:
	_completed = data.get("completed", []).duplicate()
	_scores = data.get("scores", {}).duplicate(true)
	_current_module_idx = data.get("module_idx", 0)
	_current_lesson_idx = data.get("lesson_idx", 0)

func _load_curriculum() -> void:
	var file = FileAccess.open(CURRICULUM_PATH, FileAccess.READ)
	if file == null:
		_emit("[color=red]Failed to load curriculum.[/color]\n")
		_curriculum = {"modules": []}
		return
	var json_str = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		_emit("[color=red]Curriculum parse error: %s[/color]\n" % json.get_error_message())
		_curriculum = {"modules": []}
		return
	_curriculum = json.data

func _emit(s: String) -> void:
	if computer:
		computer.emit_richtext(s)

func _get_modules() -> Array:
	return _curriculum.get("modules", [])

func _get_current_module() -> Dictionary:
	var mods = _get_modules()
	if mods.size() == 0:
		return {}
	if _current_module_idx >= 0 and _current_module_idx < mods.size():
		return mods[_current_module_idx]
	return {}

func _get_current_lesson() -> Dictionary:
	var mod = _get_current_module()
	var lessons = mod.get("lessons", [])
	if _current_lesson_idx >= 0 and _current_lesson_idx < lessons.size():
		return lessons[_current_lesson_idx]
	return {}

func _get_lesson_by_id(lesson_id: int) -> Dictionary:
	for mod in _get_modules():
		for lesson in mod.get("lessons", []):
			if lesson.get("id") == lesson_id:
				return lesson
	return {}

func _is_completed(lesson_id: int) -> bool:
	return lesson_id in _completed

func _pct_completed() -> int:
	var total := 0
	var done := 0
	for mod in _get_modules():
		for lesson in mod.get("lessons", []):
			total += 1
			if _is_completed(lesson.get("id", 0)):
				done += 1
	if total == 0:
		return 100
	return int(float(done) / float(total) * 100.0)

func help_text() -> String:
	return """[color=cyan]TRAINER — Interactive Learning Cart[/color]

Learn BASIC6502 and assembly language with
step-by-step lessons and quizzes.

[color=lime]Commands:[/color]
  [color=white]MENU[/color]          — Show module/lesson list
  [color=white]OPEN <n>[/color]      — Open lesson by number
  [color=white]NEXT[/color]          — Next lesson in current module
  [color=white]BACK[/color]          — Previous lesson (for review)
  [color=white]QUIZ[/color]          — Start quiz for current lesson
  [color=white]ANSWER <text>[/color] — Submit answer (or A/B/C/D)
  [color=white]PROGRESS[/color]      — Show completion %
  [color=white]HELP[/color]          — This screen
  [color=white]CART BASIC[/color]   — Switch to BASIC cart to practice

[color=yellow]Tip:[/color] Use OPEN 1 to start your first lesson!
"""

func handle_command(text: String) -> bool:
	var t := text.strip_edges()
	if t == "":
		return false
	if _quiz_active:
		return _handle_quiz_input(t)
	var upper := t.to_upper()
	if upper == "HELP":
		_emit(help_text())
		return true
	if upper == "MENU" or upper == "TOPICS":
		_show_menu()
		return true
	if upper.begins_with("OPEN ") or upper.begins_with("LESSON "):
		var arg = t.substr(t.find(" ") + 1).strip_edges()
		_cmd_open(arg)
		return true
	if upper == "NEXT":
		_cmd_next()
		return true
	if upper == "BACK":
		_cmd_back()
		return true
	if upper == "QUIZ":
		_cmd_quiz()
		return true
	if upper == "PROGRESS" or upper == "STATUS":
		_show_progress()
		return true
	return false

func _show_menu() -> void:
	_emit("[CLR]")
	var buf := "\n[color=cyan]TRAINER — Lesson Menu[/color]\n\n"
	for mi in range(_get_modules().size()):
		var mod = _get_modules()[mi]
		buf += "[color=yellow]%s:[/color] %s\n" % [mod.get("id", "?").to_upper(), mod.get("description", "")]
		buf += "\n"
		for li in range(mod.get("lessons", []).size()):
			var lesson = mod.get("lessons")[li]
			var lid = lesson.get("id", 0)
			var mark = "[color=lime]✓[/color] " if _is_completed(lid) else "  "
			var cur = " [color=cyan]<--[/color]" if mi == _current_module_idx and li == _current_lesson_idx else ""
			buf += "%s  [color=white]%d.[/color] %s%s\n" % [mark, lid, lesson.get("title", "?"), cur]
		buf += "\n"
	buf += "[color=lime]OPEN <number> to start a lesson. QUIZ to test yourself.[/color]\n"
	_emit(buf)

func _cmd_open(arg: String) -> void:
	if arg.is_valid_int():
		var lid = int(arg)
		var lesson = _get_lesson_by_id(lid)
		if lesson.is_empty():
			_emit("[color=red]No lesson with id %d. Type MENU to see available lessons.[/color]\n" % lid)
			return
		for mi in range(_get_modules().size()):
			for li in range(_get_modules()[mi].get("lessons", []).size()):
				if _get_modules()[mi].get("lessons")[li].get("id") == lid:
					_current_module_idx = mi
					_current_lesson_idx = li
					_show_current_lesson()
					return
	_emit("[color=red]Usage: OPEN <lesson number>. Type MENU to list lessons.[/color]\n")

func _cmd_next() -> void:
	var mod = _get_current_module()
	var lessons = mod.get("lessons", [])
	if lessons.size() == 0:
		_emit("[color=yellow]No more lessons in this module.[/color]\n")
		return
	if _current_lesson_idx + 1 < lessons.size():
		_current_lesson_idx += 1
		_show_current_lesson()
	else:
		_emit("[color=yellow]You're at the last lesson in this module. Type MENU to see more.[/color]\n")

func _cmd_back() -> void:
	if _current_lesson_idx > 0:
		_current_lesson_idx -= 1
		_show_current_lesson()
	else:
		_emit("[color=yellow]You're at the first lesson. Type MENU to see all lessons.[/color]\n")

func _show_current_lesson() -> void:
	_emit("[CLR]")
	var lesson = _get_current_lesson()
	if lesson.is_empty():
		_emit("[color=red]No lesson selected. Type MENU to browse lessons.[/color]\n")
		return
	var buf := "\n"
	buf += "[color=cyan]=== Lesson %d: %s ===[/color]\n\n" % [lesson.get("id", 0), lesson.get("title", "")]
	buf += lesson.get("body", "")
	buf += "\n\n[color=lime]Type QUIZ to test your knowledge. NEXT for the next lesson.[/color]\n"
	_emit(buf)

func _cmd_quiz() -> void:
	var lesson = _get_current_lesson()
	var lid = str(int(lesson.get("id", 0)))
	var quizzes = _curriculum.get("quizzes", {}).get(lid, [])
	if quizzes.size() == 0:
		_emit("[color=yellow]No quiz for this lesson yet.[/color]\n")
		return
	_quiz_active = true
	_quiz_index = 0
	_quiz_answers = quizzes
	_show_question()

func _show_question() -> void:
	if _quiz_index >= _quiz_answers.size():
		_quiz_active = false
		var lesson = _get_current_lesson()
		var lid = int(lesson.get("id", 0))
		if not _is_completed(lid):
			_completed.append(lid)
		_emit("\n[color=lime]Quiz complete! Lesson marked as done. (%d%% overall)[/color]\n\n" % _pct_completed())
		return
	_emit("[CLR]")
	var q = _quiz_answers[_quiz_index]
	var qtype = q.get("type", "MC")
	var buf := "\n[color=cyan]Question %d of %d:[/color]\n" % [_quiz_index + 1, _quiz_answers.size()]
	buf += q.get("question", "") + "\n\n"
	if qtype == "FILL":
		## Fill-in-the-blank: show no multiple-choice options, expect free-text.
		buf += "[color=lime]Type ANSWER <your answer> (or CANCEL to quit):[/color]\n"
	else:
		## Multiple-choice: show A/B/C/D options.
		var opts = q.get("options", [])
		for oi in range(opts.size()):
			var letter = char(ord("A") + oi)
			buf += "  [color=white]%s.[/color] %s\n" % [letter, opts[oi]]
		buf += "\n[color=lime]Type ANSWER <letter> or just the letter (A/B/C/D):[/color]\n"
	_emit(buf)

func _handle_quiz_input(text: String) -> bool:
	var upper = text.strip_edges().to_upper()
	if upper == "QUIT" or upper == "EXIT" or upper == "CANCEL":
		_quiz_active = false
		_emit("\n[color=yellow]Quiz cancelled.[/color]\n")
		return true
	## Fetch current question data (set by _cmd_quiz/_show_question).
	var q = _quiz_answers[_quiz_index]
	var qtype = q.get("type", "MC")
	if qtype == "FILL":
		## Delegate free-text answer handling; don't try letter parsing.
		return _handle_fill_answer(text, q)
	var choice: int = -1
	if upper in ["A", "B", "C", "D"]:
		choice = ord(upper) - ord("A")
	elif upper.begins_with("ANSWER "):
		var letter = upper.substr(7).strip_edges()
		if letter in ["A", "B", "C", "D"]:
			choice = ord(letter) - ord("A")
	elif upper.is_valid_int():
		choice = int(upper) - 1
	if choice < 0:
		_emit("[color=yellow]Please type A, B, C, D (or CANCEL to quit).[/color]\n")
		return true
	var correct = q.get("correct", 0)
	if choice == correct:
		_emit("\n[color=lime]✓ Correct![/color]\n\n")
		_quiz_index += 1
		_show_question()
	else:
		var hint = q.get("hint", "Try again.")
		_emit("\n[color=red]✗ Not quite.[/color] %s\n\n" % hint)
	return true

## Check a free-text answer against expected value (case-insensitive) and alternatives.
func _handle_fill_answer(text: String, q: Dictionary) -> bool:
	var raw = text.strip_edges()
	if raw.begins_with("ANSWER "):
		raw = raw.substr(7).strip_edges()
	if raw == "":
		_emit("[color=yellow]Type your answer, or CANCEL to quit.[/color]\n")
		return true
	var expected = q.get("answer", "").strip_edges().to_upper()
	var alts = q.get("alternatives", [])
	var ok = raw.to_upper() == expected
	if not ok:
		for alt in alts:
			if raw.to_upper() == alt.to_upper().strip_edges():
				ok = true
				break
	if ok:
		_emit("\n[color=lime]✓ Correct![/color]\n\n")
		_quiz_index += 1
		_show_question()
	else:
		var hint = q.get("hint", "Try again.")
		_emit("\n[color=red]✗ Not quite.[/color] %s\n\n" % hint)
	return true

func _show_progress() -> void:
	_emit("[CLR]")
	var pct = _pct_completed()
	var buf := "\n[color=cyan]TRAINER — Progress[/color]\n"
	var total := 0
	var done := 0
	for mod in _get_modules():
		var lessons = mod.get("lessons", [])
		var mod_done = 0
		for lesson in lessons:
			total += 1
			if _is_completed(lesson.get("id", 0)):
				done += 1
				mod_done += 1
		var mod_pct = 0 if lessons.size() == 0 else int(float(mod_done) / float(lessons.size()) * 100.0)
		buf += "  [color=yellow]%s:[/color] %d/%d (%d%%)\n" % [mod.get("title", "?"), mod_done, lessons.size(), mod_pct]
	buf += "\n[color=lime]Overall: %d%% complete[/color]\n" % pct
	buf += "[color=white]Lessons completed: %d/%d[/color]\n" % [done, total]
	_emit(buf)

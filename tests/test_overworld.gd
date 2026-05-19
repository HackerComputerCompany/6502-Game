extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _current: String = ""

func _init() -> void:
	print("\n========== OVERWORLD TEST SUITE ==========\n")
	test_town_map()
	test_procgen_assets()
	test_player_state()
	test_resistor_puzzle()
	test_npc_dialogue_filtering()
	print("\n========== TEST RESULTS ==========")
	print("  PASSED: %d" % _passed)
	print("  FAILED: %d" % _failed)
	print("  TOTAL:  %d" % (_passed + _failed))
	print("===================================\n")
	quit(0 if _failed == 0 else 1)

func _begin(name: String) -> void:
	_current = name
	print("Running: %s" % name)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		print("  FAIL [%s]: %s" % [_current, msg])

# --- town_map.gd ---

func test_town_map() -> void:
	_begin("TownMap basic layout")
	var map = preload("res://overworld/town_map.gd").new()
	_assert(map.MAP_W == 48, "MAP_W is 48")
	_assert(map.MAP_H == 30, "MAP_H is 30")

	_begin("TownMap default tile type")
	_assert(map.get_ground(1, 1) == 0, "unset tile is GRASS (0)")

	_begin("TownMap building collision")
	_assert(map.is_passable(18, 5) == false, "building wall tile is impassable")

	_begin("TownMap door passability")
	_assert(map.is_passable(18, 6) == true, "door tile is passable")

	_begin("TownMap water impassable")
	_assert(map.is_passable(8, 1) == false, "WATER tile is impassable")

	_begin("TownMap tree collision")
	_assert(map.is_passable(1, 1) == false, "tree tile is impassable")

	_begin("TownMap path passable")
	_assert(map.is_passable(8, 3) == true, "path tile is passable")

	_begin("TownMap out of bounds")
	_assert(map.is_passable(-1, 0) == false, "negative x is out of bounds")
	_assert(map.is_passable(0, -1) == false, "negative y is out of bounds")
	_assert(map.is_passable(48, 0) == false, "x >= MAP_W is out of bounds")
	_assert(map.is_passable(0, 30) == false, "y >= MAP_H is out of bounds")

	_begin("TownMap ground getter")
	_assert(map.get_ground(18, 6) == 3, "door ground is wall (WALL_BEIGE=3) underneath")
	_assert(map.get_ground(-1, 0) == 0, "out of bounds get_ground returns GRASS")

	_begin("TownMap decoration getter")
	_assert(map.get_decoration(-1, 0) == 12, "out of bounds get_decoration returns BLANK (12)")
	_assert(map.get_decoration(0, 0) != 12, "edge tree decorations exist")

	_begin("TownMap building positions")
	var buildings = [
		Vector2i(2, 4), Vector2i(2, 11), Vector2i(2, 18),
		Vector2i(10, 4), Vector2i(10, 18),
		Vector2i(18, 4), Vector2i(18, 18),
		Vector2i(26, 4), Vector2i(26, 11), Vector2i(26, 18),
		Vector2i(34, 4), Vector2i(34, 11), Vector2i(34, 18),
	]
	for b in buildings:
		_assert(map.is_passable(b.x, b.y) == false, "building at (%d,%d) is impassable" % [b.x, b.y])

	_begin("TownMap door positions exist")
	var door_positions = [Vector2i(18, 6), Vector2i(34, 6), Vector2i(26, 13), Vector2i(10, 20)]
	for d in door_positions:
		_assert(map.get_decoration(d.x, d.y) == 7, "door at (%d,%d) is DOOR (7) on decor layer" % [d.x, d.y])
		_assert(map.get_ground(d.x, d.y) != 7, "door at (%d,%d) ground is wall not DOOR" % [d.x, d.y])

	_begin("TownMap tile enum values")
	_assert(map.Tile.GRASS == 0, "Tile.GRASS == 0")
	_assert(map.Tile.DOOR == 7, "Tile.DOOR == 7")
	_assert(map.Tile.BLANK == 12, "Tile.BLANK == 12")
	_assert(map.Tile.WATER == 8, "Tile.WATER == 8")
	_assert(map.Tile.TREE == 10, "Tile.TREE == 10")

# --- procgen_assets.gd ---

func test_procgen_assets() -> void:
	var P = preload("res://overworld/procgen_assets.gd")

	_begin("ProcGen tile textures non-null")
	_assert(P.tile_grass() != null, "tile_grass() returns non-null")
	_assert(P.tile_path() != null, "tile_path() returns non-null")
	_assert(P.tile_door() != null, "tile_door() returns non-null")
	_assert(P.tile_water() != null, "tile_water() returns non-null")
	_assert(P.tile_fence() != null, "tile_fence() returns non-null")
	_assert(P.tile_tree() != null, "tile_tree() returns non-null")
	_assert(P.tile_sign() != null, "tile_sign() returns non-null")

	_begin("ProcGen building wall textures")
	_assert(P.tile_building_wall() != null, "tile_building_wall() with default color")
	_assert(P.tile_building_wall(Color(0.5, 0.3, 0.2)) != null, "tile_building_wall() with custom color")

	_begin("ProcGen roof textures")
	_assert(P.tile_roof() != null, "tile_roof() with default color")
	_assert(P.tile_roof(Color(0.6, 0.2, 0.1)) != null, "tile_roof() with custom color")

	_begin("ProcGen character textures non-null")
	_assert(P.player_texture() != null, "player_texture() returns non-null")

	_begin("ProcGen NPC textures non-null")
	for i in range(5):
		_assert(P.npc_texture(i) != null, "npc_texture(%d) returns non-null" % i)
	_assert(P.npc_texture(99) != null, "npc_texture(99) wraps and returns non-null")

	_begin("ProcGen texture dimensions")
	var grass = P.tile_grass()
	_assert(grass.get_image().get_size() == Vector2i(16, 16), "tile texture is 16x16")
	var player = P.player_texture()
	_assert(player.get_image().get_size() == Vector2i(16, 32), "player texture is 16x32 (Stardew-scale)")

# --- player_state.gd ---

func test_player_state() -> void:
	var S = preload("res://scripts/player_state.gd")

	_begin("PlayerState initial state")
	var ps = S.new()
	_assert(ps.player_money == 5, "initial money is 5")
	_assert(ps.current_chapter == 1, "initial chapter is 1")
	_assert(ps.current_year == 1985, "initial year is 1985")
	_assert(ps.terminal_unlocked == true, "terminal starts unlocked")
	_assert(ps.inventory.size() == 0, "inventory starts empty")

	_begin("PlayerState has_item")
	_assert(ps.has_item("nonexistent") == false, "missing item returns false")
	ps.add_item("Floppy Disk")
	_assert(ps.has_item("Floppy Disk") == true, "existing item returns true")

	_begin("PlayerState add_item no duplicates")
	var before = ps.inventory.size()
	ps.add_item("Floppy Disk")
	_assert(ps.inventory.size() == before, "add_item does not duplicate")

	_begin("PlayerState add_item with description")
	ps.add_item("Manual", "A technical manual")
	var item = ps.inventory[ps.inventory.size() - 1]
	_assert(item.name == "Manual", "item name matches")
	_assert(item.description == "A technical manual", "item description matches")

	_begin("PlayerState remove_item")
	ps.add_item("Temporary")
	_assert(ps.has_item("Temporary") == true, "item exists before removal")
	ps.remove_item("Temporary")
	_assert(ps.has_item("Temporary") == false, "item gone after removal")
	_assert(ps.has_item("Floppy Disk") == true, "other items unaffected")

	_begin("PlayerState remove_item nonexistent")
	ps.remove_item("DoesNotExist")
	_assert(true, "removing nonexistent item does not error")

	_begin("PlayerState quest flags")
	_assert(ps.get_quest_flag("met_mike") == false, "unset flag defaults to false")
	ps.set_quest_flag("met_mike")
	_assert(ps.get_quest_flag("met_mike") == true, "set flag returns true")
	_assert(ps.get_quest_flag("nonexistent") == false, "unset flag still false")

	_begin("PlayerState quest flag custom value")
	ps.set_quest_flag("score", 42)
	_assert(ps.get_quest_flag("score") == 42, "flag stores custom value")

	_begin("PlayerState advance_time")
	ps.game_time_hour = 8.0
	ps.advance_time(2.0)
	_assert(ps.game_time_hour == 10.0, "advance_time adds hours")
	ps.game_time_hour = 23.0
	ps.advance_time(2.0)
	_assert(ps.game_time_hour == 1.0, "advance_time wraps past midnight")

	_begin("PlayerState get_time_string")
	ps.game_time_hour = 9.0
	ps.game_time_minute = 0.0
	_assert(ps.get_time_string() == "9:00 AM", "9:00 formats as 9:00 AM")
	ps.game_time_hour = 13.5
	_assert(ps.get_time_string() == "1:00 PM", "13:00 formats as 1:00 PM")
	ps.game_time_hour = 0.0
	ps.game_time_minute = 0.0
	_assert(ps.get_time_string() == "12:00 AM", "0:00 formats as 12:00 AM")

	_begin("PlayerState skills default to 0")
	_assert(ps.skills.basic_programming == 0.0, "basic_programming starts at 0")
	_assert(ps.skills.electronics == 0.0, "electronics starts at 0")

# --- resistor_puzzle.gd ---

func test_resistor_puzzle() -> void:
	_begin("ResistorPuzzle creation")
	var puzzle = preload("res://hardware/resistor_puzzle.gd").new()
	_assert(puzzle.puzzle_id == "resistor_basics_1", "puzzle_id set")
	_assert(puzzle.puzzle_name == "Resistor Color Codes", "puzzle_name set")
	_assert(puzzle.solved == false, "starts unsolved")

	_begin("ResistorPuzzle get_question returns string")
	var q = puzzle.get_question()
	_assert(q.length() > 0, "question is non-empty")
	_assert(q.contains("bands") or q.contains("value"), "question mentions bands or value")

	_begin("ResistorPuzzle get_hint returns string")
	var h = puzzle.get_hint()
	_assert(h.length() > 0, "hint is non-empty")
	_assert(h.contains("Black") or h.contains("Brown"), "hint contains color names")

	_begin("ResistorPuzzle check_solution basic")
	_assert(puzzle.check_solution("foo bar") == false, "nonsense answer is wrong")

	_begin("ResistorPuzzle check_solution with unit variations")
	var p2 = preload("res://hardware/resistor_puzzle.gd").new()
	var ans = p2._correct_value
	_assert(p2.check_solution(ans) == true, "exact correct answer passes")
	if ans.ends_with("K") or ans.ends_with("M"):
		var with_o = ans + "O"
		_assert(p2.check_solution(with_o) == true, "answer with O suffix passes")

	_begin("ResistorPuzzle multi-value correct answer")
	var p3 = preload("res://hardware/resistor_puzzle.gd").new()
	var val = p3._correct_value
	_assert(p3.check_solution(val.to_upper()) == true, "case-insensitive passes")
	_assert(p3.check_solution(" " + val + " ") == true, "whitespace-trimmed passes")

# --- npc.gd dialogue filtering ---

func test_npc_dialogue_filtering() -> void:
	_begin("NPC setup and basic dialogue")
	var npc = preload("res://overworld/npc.gd").new()
	npc.setup("TestNPC", [
		{"speaker": "TestNPC", "text": "Hello"},
		{"speaker": "TestNPC", "text": "World"},
	])
	var dia = npc.get_dialogue()
	_assert(dia.size() == 2, "unfiltered dialogue returns all entries")
	_assert(dia[0].text == "Hello", "first dialogue entry correct")

	_begin("NPC require_flag filtering")
	npc.setup("FilteredNPC", [
		{"speaker": "F", "text": "Flag required", "require_flag": "test_flag"},
		{"speaker": "F", "text": "Always shown"},
	])
	dia = npc.get_dialogue()
	_assert(dia.size() == 1, "filtered dialogue hides flag-gated entry")
	_assert(dia[0].text == "Always shown", "only unfiltered entry remains")

	_begin("NPC require_flag with flag set")
	npc.get_player_state().set_quest_flag("test_flag")
	dia = npc.get_dialogue()
	_assert(dia.size() == 2, "all entries visible when flag is set")

	_begin("NPC require_no_flag filtering")
	npc.setup("NoFlagNPC", [
		{"speaker": "N", "text": "First meeting", "require_no_flag": "already_met"},
		{"speaker": "N", "text": "Welcome back"},
	])
	dia = npc.get_dialogue()
	_assert(dia.size() == 2, "both entries visible before no-flag set")

	npc.get_player_state().set_quest_flag("already_met")
	dia = npc.get_dialogue()
	_assert(dia.size() == 1, "hide require_no_flag entry when flag is set")
	_assert(dia[0].text == "Welcome back", "only non-excluded entry remains")

	_begin("NPC requires both flag conditions")
	npc.setup("MultiNPC", [
		{"speaker": "M", "text": "Only if A and not B", "require_flag": "flag_a", "require_no_flag": "flag_b"},
		{"speaker": "M", "text": "Default"},
	])
	npc.get_player_state().set_quest_flag("flag_a")
	dia = npc.get_dialogue()
	_assert(dia.size() == 2, "flag_a met + flag_b absent shows all")

	npc.get_player_state().set_quest_flag("flag_b")
	dia = npc.get_dialogue()
	_assert(dia.size() == 1, "flag_a + flag_b hides combined condition")
	_assert(dia[0].text == "Default", "only default entry remains")

	_begin("NPC quest flag set on dialogue end")
	npc.setup("QuestNPC", [{"speaker": "Q", "text": "Take quest"}], 0, "", "quest_started")
	_assert(npc.get_player_state().get_quest_flag("quest_started") == false, "flag not set before dialogue")
	npc._on_dialogue_done()
	_assert(npc.get_player_state().get_quest_flag("quest_started") == true, "flag set after dialogue ends")

	_begin("NPC item reward on dialogue end")
	npc.setup("ItemNPC", [{"speaker": "I", "text": "Here"}], 0, "", "", "Key Item")
	_assert(npc.get_player_state().has_item("Key Item") == false, "item not given before dialogue")
	npc._on_dialogue_done()
	_assert(npc.get_player_state().has_item("Key Item") == true, "item given after dialogue ends")

	_begin("NPC empty dialogue returns empty")
	npc.setup("Silent", [])
	var empty = npc.get_dialogue()
	_assert(empty.size() == 0, "empty dialogue returns empty array")

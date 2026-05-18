extends Node2D

signal terminal_requested()

const TILE_SIZE := 32
const TILE_TYPES := 14
const FURNITURE_SCALE := 2.0

const INTERACTIVE_FURNITURE := ["desk", "bed", "garbage_can"]

var _map_data
var _map_script_path: String = ""
var _npc_list: Array = []
var _active_npc: Node = null
var _furniture_nodes: Array = []
var _label_nodes: Array = []
var _interact_highlights: Array = []
var _flash_time: float = 0.0
var _night_overlay: ColorRect
var _daylight: float = 1.0
var _transition_cooldown: float = 0.0
var _ps = null
var _npc_areas: Array = []

func _get_ps():
	if _ps == null:
		if Engine.has_singleton("PlayerState"):
			_ps = Engine.get_singleton("PlayerState")
		else:
			_ps = preload("res://scripts/player_state.gd").new()
	return _ps

@onready var _ground_map: TileMapLayer = $GroundTileMap
@onready var _deco_map: TileMapLayer = $DecorationTileMap
@onready var _player: CharacterBody2D = $Player
@onready var _camera: Camera2D = $Camera2D
@onready var _dialogue: CanvasLayer = $DialogueBox
@onready var _npc_container: Node2D = $NPCContainer
@onready var _furniture_container: Node2D = $FurnitureContainer
@onready var _hud: CanvasLayer = $HUD

func _ready() -> void:
	_night_overlay = ColorRect.new()
	_night_overlay.color = Color(0, 0, 0.15, 0.0)
	_night_overlay.size = Vector2(10000, 10000)
	_night_overlay.position = Vector2(-5000, -5000)
	_night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_night_overlay.z_index = 50
	add_child(_night_overlay)
	_load_map("res://overworld/house_map.gd")

func load_map(path: String, entry_point: String = "") -> void:
	_load_map(path, entry_point)

func _load_map(path: String, entry_point: String = "") -> void:
	_map_script_path = path
	_clear_furniture()
	_map_data = load(path).new()
	_build_tilemaps()
	_place_furniture()
	_place_labels()
	_place_npcs()
	_setup_camera()
	var ep_dict = _map_data.get("ENTRY_POINTS")
	if entry_point != "" and ep_dict != null and ep_dict.has(entry_point):
		var ep = ep_dict[entry_point]
		_player.position = Vector2(ep.x * TILE_SIZE + TILE_SIZE / 2, ep.y * TILE_SIZE + TILE_SIZE / 2)
	_update_map_pos()
	_transition_cooldown = 0.3

var _atlas_built := false

func _build_tilemaps() -> void:
	_ground_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_deco_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ground_map.clear()
	_deco_map.clear()

	if not _atlas_built:
		var Tile = preload("res://overworld/town_map.gd").Tile
		var tile_colors := {
			Tile.GRASS: Color(0.25, 0.45, 0.15),
			Tile.PATH: Color(0.30, 0.18, 0.08),
			Tile.WALL_BROWN: Color(1.0, 1.0, 1.0),
			Tile.WALL_BEIGE: Color(1.0, 1.0, 1.0),
			Tile.WALL_GRAY: Color(0.85, 0.85, 0.85),
			Tile.ROOF_RED: Color(0.55, 0.12, 0.10),
			Tile.ROOF_GRAY: Color(0.40, 0.40, 0.45),
			Tile.DOOR: Color(0.75, 0.65, 0.25),
			Tile.WATER: Color(0.15, 0.30, 0.65),
			Tile.FENCE: Color(0.45, 0.30, 0.15),
			Tile.TREE: Color(0.18, 0.50, 0.18),
			Tile.SIGN: Color(0.55, 0.40, 0.20),
			Tile.BLANK: Color(0, 0, 0, 0),
			Tile.SIDEWALK: Color(0.50, 0.38, 0.22),
		}
		var s := TILE_SIZE
		var atlas_img := Image.create(TILE_TYPES * s, s, false, Image.FORMAT_RGBA8)
		atlas_img.fill(Color(0, 0, 0, 0))
		for i in range(TILE_TYPES):
			var color = tile_colors.get(i, Color.MAGENTA)
			for py in range(s):
				for px in range(s):
					atlas_img.set_pixel(i * s + px, py, color)
		var atlas_tex := ImageTexture.create_from_image(atlas_img)
		var ts := TileSet.new()
		ts.tile_size = Vector2i(s, s)
		var source := TileSetAtlasSource.new()
		source.texture = atlas_tex
		source.texture_region_size = Vector2i(s, s)
		for i in TILE_TYPES:
			source.create_tile(Vector2i(i, 0))
		ts.add_source(source, 0)
		_ground_map.tile_set = ts
		_deco_map.tile_set = ts
		_atlas_built = true

	for y in range(_map_data.MAP_H):
		for x in range(_map_data.MAP_W):
			var g = _map_data.get_ground(x, y)
			var d = _map_data.get_decoration(x, y)
			if g != preload("res://overworld/town_map.gd").Tile.BLANK:
				_ground_map.set_cell(Vector2i(x, y), 0, Vector2i(g, 0))
			if d != preload("res://overworld/town_map.gd").Tile.BLANK:
				_deco_map.set_cell(Vector2i(x, y), 0, Vector2i(d, 0))

func _clear_furniture() -> void:
	for node in _furniture_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_furniture_nodes.clear()
	for node in _label_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_label_nodes.clear()
	for node in _interact_highlights:
		if is_instance_valid(node):
			node.queue_free()
	_interact_highlights.clear()
	for node in _npc_list:
		if is_instance_valid(node):
			node.queue_free()
	_npc_list.clear()
	for node in _npc_areas:
		if is_instance_valid(node):
			node.queue_free()
	_npc_areas.clear()
	_active_npc = null

const FURNITURE_COLORS := {
	"desk": Color(0.45, 0.28, 0.12),
	"chair": Color(0.35, 0.2, 0.1),
	"bed": Color(0.0, 0.281, 0.716, 1.0),
	"table": Color(0.5, 0.35, 0.18),
	"stove": Color(0.3, 0.3, 0.35),
	"fridge": Color(0.85, 0.85, 0.9),
	"toilet": Color(0.95, 0.95, 0.95),
	"bathtub": Color(0.9, 0.9, 0.95),
	"shelf": Color(0.55, 0.38, 0.2),
	"workbench": Color(0.5, 0.45, 0.35),
	"tv": Color(0.15, 0.15, 0.15),
	"couch": Color(0.4, 0.55, 0.35),
	"garbage_can": Color(0.35, 0.35, 0.35),
}

func _place_furniture() -> void:
	if not _map_data.has_method("get_furniture"):
		return
	for f in _map_data.get_furniture():
		var name: String = f[0]
		var tx: int = f[1]
		var ty: int = f[2]
		var z: int = f[3] if f.size() > 3 else 0
		var blocks: bool = f[4] if f.size() > 4 else false
		var fw: int = f[5] if f.size() > 5 else 1
		var fh: int = f[6] if f.size() > 6 else 1

		var tex_path := name + ".png"
		var has_texture := ResourceLoader.exists(tex_path)
		var sprite: Sprite2D = null

		if has_texture:
			var tex = load(tex_path) as Texture2D
			if tex:
				sprite = Sprite2D.new()
				sprite.texture = tex
				sprite.centered = false
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.scale = Vector2(FURNITURE_SCALE, FURNITURE_SCALE)
				sprite.position = Vector2(tx * TILE_SIZE, ty * TILE_SIZE)
				sprite.z_index = z
				_furniture_container.add_child(sprite)
				_furniture_nodes.append(sprite)
				if blocks:
					var real_w = ceil(tex.get_width() * FURNITURE_SCALE / float(TILE_SIZE))
					var real_h = ceil(tex.get_height() * FURNITURE_SCALE / float(TILE_SIZE))
					for dy in range(real_h):
						for dx in range(real_w):
							_collide_tile(tx + dx, ty + dy)
		else:
			var color = FURNITURE_COLORS.get(name, Color.MAGENTA)
			var img := Image.create(fw * TILE_SIZE, fh * TILE_SIZE, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var desk_color = color
			for py in range(fh * TILE_SIZE):
				for px in range(fw * TILE_SIZE):
					var on_edge = px < 2 or px >= fw * TILE_SIZE - 2 or py < 2 or py >= fh * TILE_SIZE - 2
					if on_edge:
						img.set_pixel(px, py, Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 1.0))
					else:
						img.set_pixel(px, py, desk_color)
			var tex := ImageTexture.create_from_image(img)
			sprite = Sprite2D.new()
			sprite.texture = tex
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.position = Vector2(tx * TILE_SIZE, ty * TILE_SIZE)
			sprite.z_index = ty
			_furniture_container.add_child(sprite)
			_furniture_nodes.append(sprite)
			if blocks:
				for dy in range(fh):
					for dx in range(fw):
						_collide_tile(tx + dx, ty + dy)

		if name in INTERACTIVE_FURNITURE:
			var highlight := ColorRect.new()
			highlight.size = Vector2(fw * TILE_SIZE, fh * TILE_SIZE)
			highlight.position = Vector2(tx * TILE_SIZE, ty * TILE_SIZE)
			highlight.color = Color(1, 1, 0.3, 0)
			highlight.z_index = ty + 1
			_furniture_container.add_child(highlight)
			_interact_highlights.append({"node": highlight, "name": name})

func _place_labels() -> void:
	if not _map_data.has_method("get_labels"):
		return
	for label_data in _map_data.get_labels():
		var text: String = label_data[0]
		var lx: int = label_data[1]
		var ly: int = label_data[2]
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(1, 1, 0.4))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 3)
		label.position = Vector2(lx * TILE_SIZE, ly * TILE_SIZE)
		label.z_index = 100
		_furniture_container.add_child(label)
		_label_nodes.append(label)

func _collide_tile(tx: int, ty: int) -> void:
	if tx < 0 or tx >= _map_data.MAP_W or ty < 0 or ty >= _map_data.MAP_H:
		return
	var Tile = preload("res://overworld/town_map.gd").Tile
	if _map_data.get_decoration(tx, ty) == Tile.DOOR:
		return
	if _map_data.collision.size() > ty and _map_data.collision[ty].size() > tx:
		_map_data.collision[ty][tx] = 1

func _place_npcs() -> void:
	var definitions := _get_npc_definitions()
	for def in definitions:
		var npc = preload("res://overworld/npc.gd").new()
		npc.name = "NPC_%s" % def.get("name", "unknown")
		npc.setup(
			def.get("name", ""),
			def.get("dialogue", []),
			def.get("appearance", 0),
			def.get("quest_req", ""),
			def.get("quest_set", ""),
			def.get("item", "")
		)
		npc.facing_left = def.get("facing_left", false)
		var pos = def.get("position", Vector2.ZERO)
		npc.position = Vector2(pos.x * TILE_SIZE + TILE_SIZE / 2, pos.y * TILE_SIZE + TILE_SIZE / 2)
		_npc_container.add_child(npc)
		_npc_list.append(npc)
		var area := Area2D.new()
		var shape := CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		shape.shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		area.add_child(shape)
		area.position = npc.position
		add_child(area)
		area.set_meta("npc_ref", npc)
		_npc_areas.append(area)

func _get_npc_definitions() -> Array:
	if _map_script_path.find("house_map") != -1:
		return [
			{
				"name": "Dad",
				"appearance": 5,
				"position": Vector2(24, 15),
				"facing_left": false,
				"dialogue": [
					{"speaker": "Dad", "text": "Hey kiddo. Your mom says you've been spending a lot of time on that computer."},
					{"speaker": "Dad", "text": "Not that I'm complaining — it's good to learn this stuff. Good for job skills, right?"},
					{"speaker": "Dad", "text": "Just make sure you're taking out the garbage like you promised.", "require_no_flag": "chores_done"},
					{"speaker": "Dad", "text": "Nice job with the chores today. I'll put in a good word for your allowance.", "require_flag": "chores_done"},
				],
			},
			{
				"name": "Mom",
				"appearance": 6,
				"position": Vector2(38, 15),
				"facing_left": true,
				"dialogue": [
					{"speaker": "Mom", "text": "Honey, is your room clean? I don't want to have to ask again."},
					{"speaker": "Mom", "text": "Your sister needs the phone line tonight — she's calling her friend about the dance."},
					{"speaker": "Mom", "text": "Oh, I almost forgot — I picked up some components at the store. They're on the kitchen counter if you need them.", "require_flag": "met_mike"},
				],
			},
			{
				"name": "Jessica",
				"appearance": 7,
				"position": Vector2(24, 5),
				"facing_left": true,
				"dialogue": [
					{"speaker": "Jessica", "text": "Ugh, are you playing on that thing again?"},
					{"speaker": "Jessica", "text": "Whatever. Just stay off the phone line after 7 — I'm calling Amanda."},
					{"speaker": "Jessica", "text": "...Fine. I heard some weird beeping on the phone yesterday. Sounded like a computer. Your dorky friends?", "require_flag": "met_mike"},
				],
			},
		]
	if _map_script_path.find("library") != -1:
		return [
			{
				"name": "Librarian",
				"appearance": 1,
				"position": Vector2(6, 5),
				"facing_left": false,
				"quest_req": "met_mike",
				"dialogue": [
					{"speaker": "Librarian", "text": "Shhh... oh, it's you. Someone left this manual on the table yesterday. It's from the Water Reclamation Department."},
					{"speaker": "Librarian", "text": "It has a bunch of phone numbers in the back. Looks like SCADA system access numbers. You seem like the type who'd find that interesting."},
					{"speaker": "Librarian", "text": "Just don't cause any floods, alright?", "require_flag": "read_manual"},
					{"speaker": "Librarian", "text": "The manual's right there if you want to look at it.", "require_no_flag": "read_manual"},
				],
				"item": "Water Reclamation Manual",
				"quest_set": "got_manual",
			},
		]
	if _map_script_path.find("chipmart") != -1:
		return [
			{
				"name": "Clerk",
				"appearance": 2,
				"position": Vector2(6, 4),
				"facing_left": false,
				"dialogue": [
					{"speaker": "Clerk", "text": "Welcome to ChipMart! Let me know if you need any components."},
					{"speaker": "Clerk", "text": "If you're studying electronics, you should learn your resistor color codes. Black, Brown, Red, Orange, Yellow, Green, Blue, Violet, Gray, White."},
					{"speaker": "Clerk", "text": "BB ROY of Great Britain has a Very Good Wife — that's how I learned 'em!", "require_flag": "got_manual"},
				],
			},
		]
	if _map_script_path.find("diner") != -1:
		return [
			{
				"name": "Cook",
				"appearance": 3,
				"position": Vector2(7, 4),
				"facing_left": true,
				"dialogue": [
					{"speaker": "Cook", "text": "Hungry? Burger and fries is $2.50. Best deal in town."},
					{"speaker": "Cook", "text": "I've been seeing a lot of weird interference on the radio lately. Someone's broadcasting on frequencies they shouldn't be.", "require_flag": "met_mike"},
				],
			},
		]
	if _map_script_path.find("school") != -1:
		return [
			{
				"name": "Teacher",
				"appearance": 1,
				"position": Vector2(7, 2),
				"facing_left": false,
				"dialogue": [
					{"speaker": "Teacher", "text": "School's out for the summer, but the computer lab is still open if you need it."},
					{"speaker": "Teacher", "text": "A few of the computers have modems. Just don't go calling any long-distance numbers!", "require_flag": "met_mike"},
				],
			},
		]
	if _map_script_path.find("police_dept") != -1:
		return [
			{
				"name": "Officer",
				"appearance": 4,
				"position": Vector2(4, 4),
				"facing_left": false,
				"dialogue": [
					{"speaker": "Officer", "text": "Nothing to report today. Quiet town, mostly."},
					{"speaker": "Officer", "text": "We've had some complaints about strange phone calls. If you hear anything unusual, let us know.", "require_flag": "met_mike"},
				],
			},
		]
	if _map_script_path.find("phone_co") != -1:
		return [
			{
				"name": "Technician",
				"appearance": 2,
				"position": Vector2(6, 3),
				"facing_left": true,
				"dialogue": [
					{"speaker": "Technician", "text": "This is a restricted area. What are you doing in here?"},
					{"speaker": "Technician", "text": "...Fine, look around if you want. Just don't touch anything. The switching equipment is sensitive.", "require_flag": "got_manual"},
				],
			},
		]
	if _map_script_path.find("water_recl") != -1:
		return [
			{
				"name": "Engineer",
				"appearance": 4,
				"position": Vector2(7, 5),
				"facing_left": false,
				"dialogue": [
					{"speaker": "Engineer", "text": "The water reclamation facility handles all the town's water treatment."},
					{"speaker": "Engineer", "text": "Our SCADA system controls the valves remotely. Very efficient... and very vulnerable, if you know what I mean.", "require_flag": "got_manual"},
				],
			},
		]
	if _map_script_path.find("lazer_arcade") != -1:
		return [
			{
				"name": "Kid",
				"appearance": 3,
				"position": Vector2(6, 5),
				"facing_left": false,
				"dialogue": [
					{"speaker": "Kid", "text": "This place is awesome! They have Galaga AND Centipede!"},
					{"speaker": "Kid", "text": "I heard if you put in the code on the machine in the back, something weird happens. Probably just a rumor though.", "require_flag": "met_mike"},
				],
			},
		]
	if _map_script_path.find("rich_kid_house") != -1:
		return [
			{
				"name": "Rich Kid",
				"appearance": 0,
				"position": Vector2(3, 4),
				"facing_left": true,
				"dialogue": [
					{"speaker": "Rich Kid", "text": "Oh, it's you. My dad bought me a new stereo system. Bet you don't have one of THESE."},
					{"speaker": "Rich Kid", "text": "What? You have a computer? Pfft. I have a Nintendo AND a Sega. Top that.", "require_flag": "met_mike"},
				],
			},
		]
	return [
		{
			"name": "Mike",
			"appearance": 0,
			"position": Vector2(19, 39),
			"dialogue": [
				{"speaker": "Mike", "text": "Hey! You made it. Check out my new computer — it's a Vector 64! My parents got it for my birthday."},
				{"speaker": "Mike", "text": "I've been messing around with BASIC all week. There's this weird BBS number I found... 555-0199. I can't get it to connect though."},
				{"speaker": "Mike", "text": "Go ahead, try it out. Just walk up to the desk and press SPACE."},
			],
			"quest_set": "met_mike",
		},
		{
			"name": "Girl",
			"appearance": 3,
			"position": Vector2(77, 10),
			"dialogue": [
				{"speaker": "Girl", "text": "Don't you have anything better to do than talk to me?"},
				{"speaker": "Girl", "text": "...But since you're here, I heard someone's been war dialing the phone company exchange. Weird busy signal pattern on 555-01xx.", "require_flag": "met_mike"},
			],
		},
		{
			"name": "Old Man",
			"appearance": 4,
			"position": Vector2(30, 32),
			"dialogue": [
				{"speaker": "Old Man", "text": "Back in my day, computers took up entire rooms. Now kids have 'em on their desks."},
				{"speaker": "Old Man", "text": "Progress, I suppose. Still doesn't beat a good soldering iron and a handful of components."},
			],
		},
	]

func _setup_camera() -> void:
	_camera.position = _player.position
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = _map_data.MAP_W * TILE_SIZE
	_camera.limit_bottom = _map_data.MAP_H * TILE_SIZE

func get_map_data():
	return _map_data

func _process(delta: float) -> void:
	if _dialogue.visible:
		_player.can_move = false
	else:
		_player.can_move = true
	_get_ps().tick_game_time(delta)
	_daylight = _get_ps().get_daylight_factor()
	var night_alpha: float = (1.0 - _daylight) * 0.55
	_night_overlay.color = Color(0, 0, 0.15, night_alpha)

func _physics_process(delta: float) -> void:
	if _dialogue.visible:
		return
	_camera.position = _player.position
	if _transition_cooldown > 0:
		_transition_cooldown -= delta
	else:
		_check_exit()
	_update_interact_flash(delta)
	_update_npc_bubbles()

func _unhandled_input(event: InputEvent) -> void:
	pass

func forward_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if _dialogue.visible:
			if event.pressed and not event.echo:
				if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
					_dialogue.advance()
			return
		_player.forward_input(event)
		if event.pressed and not event.echo:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_try_interact()

func _try_interact() -> void:
	var px: int = int(_player.position.x / TILE_SIZE)
	var py: int = int(_player.position.y / TILE_SIZE)
	var map = _map_data

	var exits_dict = map.get("EXITS")
	if exits_dict != null:
		for exit_tile in exits_dict:
			if abs(px - exit_tile.x) <= 1 and abs(py - exit_tile.y) <= 1:
				var exit_data = exits_dict[exit_tile]
				var target_map = exit_data.get("map", "")
				var entry = exit_data.get("entry", "")
				if target_map != "":
					_load_map(target_map, entry)
					return

	var ep_dict = map.get("ENTRY_POINTS")
	if ep_dict != null and ep_dict.has("desk"):
		var desk_val = ep_dict["desk"]
		var computer_spots: Array = []
		if desk_val is Array:
			for pos in desk_val:
				computer_spots.append(Vector2i(pos))
		else:
			computer_spots = [Vector2i(desk_val)]
		for spot in computer_spots:
			if abs(px - spot.x) <= 1 and abs(py - spot.y) <= 1:
				_open_terminal()
				return
	if ep_dict != null and ep_dict.has("bed"):
		var bed_val = ep_dict["bed"]
		var bed_spots: Array = []
		if bed_val is Array:
			for pos in bed_val:
				bed_spots.append(Vector2i(pos))
		else:
			bed_spots = [Vector2i(bed_val)]
		for spot in bed_spots:
			if abs(px - spot.x) <= 1 and abs(py - spot.y) <= 1:
				_use_bed()
				return

	if ep_dict != null and ep_dict.has("garbage_can"):
		var gc_val = ep_dict["garbage_can"]
		var gc_spots: Array = []
		if gc_val is Array:
			for pos in gc_val:
				gc_spots.append(Vector2i(pos))
		else:
			gc_spots = [Vector2i(gc_val)]
		for spot in gc_spots:
			if abs(px - spot.x) <= 1 and abs(py - spot.y) <= 1:
				_take_out_garbage()
				return

	var best_npc = null
	var best_dist: float = 999.0
	for npc in _npc_list:
		if npc.get_dialogue().size() == 0:
			continue
		var nx: float = npc.position.x / TILE_SIZE
		var ny: float = npc.position.y / TILE_SIZE
		var dist: float = sqrt((px - nx) * (px - nx) + (py - ny) * (py - ny))
		if dist < best_dist:
			best_dist = dist
			best_npc = npc
	if best_npc != null and best_dist <= 2.0:
		_active_npc = best_npc
		best_npc.on_interacted(_dialogue)
		return

	var Tile = preload("res://overworld/town_map.gd").Tile
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var cx: int = px + dx
			var cy: int = py + dy
			if cx >= 0 and cx < map.MAP_W and cy >= 0 and cy < map.MAP_H:
				if map.get_decoration(cx, cy) == Tile.DOOR:
					_dialogue.show_text("", "You push the door open...")
					return

func _update_map_pos() -> void:
	if _player and _map_data:
		var tx := int(_player.position.x / TILE_SIZE)
		var ty := int(_player.position.y / TILE_SIZE)
		_get_ps().overworld_position = Vector2(tx, ty)
		_get_ps().current_map = _map_script_path

func _check_exit() -> void:
	if _dialogue.visible or not _map_data:
		return
	var px := int(_player.position.x / TILE_SIZE)
	var py := int(_player.position.y / TILE_SIZE)
	var tile := Vector2i(px, py)
	var exits_dict = _map_data.get("EXITS")
	if exits_dict != null and tile in exits_dict:
		var exit_data = exits_dict[tile]
		var target_map = exit_data.get("map", "")
		var entry = exit_data.get("entry", "")
		if target_map != "":
			_load_map(target_map, entry)

func _open_terminal() -> void:
	if not _get_ps().terminal_unlocked:
		_dialogue.show_text("", "The computer doesn't seem to be working right now.")
		return
	terminal_requested.emit()

func _use_bed() -> void:
	_get_ps().game_time_hour = 7.0
	_get_ps().game_time_minute = 0.0
	_get_ps()._advance_day()
	_dialogue.show_text("", "You crawl into bed and sleep through the night.")
	_transition_cooldown = 0.5

func _take_out_garbage() -> void:
	_get_ps().set_quest_flag("garbage_taken_out", true)
	_update_chores()
	_dialogue.show_text("", "You take out the garbage. Good job!")

func _update_chores() -> void:
	if _get_ps().get_quest_flag("garbage_taken_out") and _get_ps().get_quest_flag("room_clean"):
		_get_ps().set_quest_flag("chores_done", true)
	else:
		_get_ps().set_quest_flag("chores_done", false)

func _update_interact_flash(delta: float) -> void:
	if _interact_highlights.is_empty():
		return
	var ep_dict = _map_data.get("ENTRY_POINTS") if _map_data else null
	if ep_dict == null:
		return
	var front_tile = _player.interact_front_tile()
	var near_item := ""
	for item_name in INTERACTIVE_FURNITURE:
		if not ep_dict.has(item_name):
			continue
		var tiles = ep_dict[item_name]
		var tile_list: Array = []
		if tiles is Array:
			for pos in tiles:
				tile_list.append(Vector2i(pos))
		else:
			tile_list = [Vector2i(tiles)]
		if front_tile in tile_list:
			near_item = item_name
			break
	if near_item != "":
		_flash_time += delta * 4.0
		var alpha := 0.3 + 0.25 * sin(_flash_time * PI)
		for h in _interact_highlights:
			var show: bool = h["name"] == near_item
			h["node"].color = Color(1, 1, 0.3, alpha if show else 0.0)
	else:
		_flash_time = 0.0
		for h in _interact_highlights:
			h["node"].color = Color(1, 1, 0.3, 0)

func _update_npc_bubbles() -> void:
	var px := int(_player.position.x / TILE_SIZE)
	var py := int(_player.position.y / TILE_SIZE)
	for npc in _npc_list:
		var nx := int(npc.position.x / TILE_SIZE)
		var ny := int(npc.position.y / TILE_SIZE)
		var dist: int = abs(px - nx) + abs(py - ny)
		var has_dialogue: bool = npc.get_dialogue().size() > 0
		npc.show_bubble(dist <= 2 and has_dialogue)

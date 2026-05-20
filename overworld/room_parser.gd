class_name RoomParser

## RoomParser — ASCII room template parser
##
## Defines rooms visually with a character grid instead of manual tile/loop code.
## Each room file provides a MAP string, a LEGEND dictionary, and optional overlay
## layers (LAYER2 + LAYER2_LEGEND, LAYER3 + LAYER3_LEGEND, ...).
##
## ─── MAP ───
## A multiline string where each character maps to a tile or furniture origin.
## Spaces are ignored. Line width determines MAP_W; line count determines MAP_H.
## The grid must be rectangular (shorter lines are padded with PATH tiles).
##
## ─── LEGEND ───
## Maps single characters to tile/furniture definitions:
##
##   '#' : {'ground': Tile.WALL_BROWN, 'collision': true}
##   '.' : {'ground': Tile.PATH}
##   'D' : {'ground': Tile.PATH, 'decoration': Tile.DOOR}
##   'w' : {'ground': Tile.WALL_GRAY, 'collision': true}     # window
##   'S' : {'furniture': 'shelf', 'fw': 6, 'fh': 1, 'z': 4, 'blocks': true}
##   't' : {'furniture': 'table', 'fw': 2, 'fh': 1, 'z': 2, 'blocks': true}
##
## Keys per legend entry:
##   'ground'      — Tile enum value for the ground layer (default: PATH)
##   'decoration'  — Tile enum value for the decoration layer
##   'collision'   — true sets this tile as impassable (default: false)
##   'furniture'   — furniture type name (string); marks this tile as a furniture origin
##   'fw'          — furniture width in tiles (default: 1)
##   'fh'          — furniture height in tiles (default: 1)
##   'z'           — z-index for rendering order (default: 0)
##   'blocks'      — whether overworld.gd should set collision on fw×fh area (default: true)
##
## Doors are automatically walkable (collision=0, ground=PATH) regardless of legend order.
##
## ─── FURNITURE ───
## Furniture uses origin-only placement: one character marks the top-left corner,
## and 'fw'×'fh' defines how many tiles it occupies. Tiles under a furniture item
## that are not its origin should be marked '.' in the MAP — the parser fills
## collision for the full fw×fh rectangle from the origin.
##
## Multi-size variants of the same furniture type need different characters:
##   'S' : {'furniture': 'shelf', 'fw': 6, 'fh': 1}   # horizontal shelf
##   'V' : {'furniture': 'shelf', 'fw': 1, 'fh': 4}   # vertical shelf
##
## The furniture list returned by get_furniture() uses this format:
##   [name, x, y, z, blocks, fw, fh]
##
## ─── LAYERS ───
## Overlay layers let you place spawns, effects, or additional tiles on top of the
## base map without cluttering it. Each overlay pair is:
##   const LAYER2 := "..."          # same-size grid, '.' = skip, any other char = overlay
##   const LAYER2_LEGEND := { ... } # legend specific to layer2 characters
##
## Overlays are processed in order after the base MAP. They can override ground,
## collision, decoration, or add furniture. Common uses:
##   'N' : {'spawn': 'npc_librarian'}       # NPC spawn point
##   'L' : {'ground': Tile.PATH, 'collision': true, 'decoration': Tile.SIGN}  # late addition
##
## The parser checks for LAYER2/LAYER2_LEGEND, then LAYER3/LAYER3_LEGEND, etc.
## It stops at the first missing pair.
##
## ─── EXAMPLE ROOM ───
##   const MAP := """
##   ########
##   #1.....#
##   #V..t.w#
##   #V..... #
##   #V..t..#
##   #V...k.#
##   ####D###
##   """
##   const LEGEND := {
##       '#': {'ground': Tile.WALL_BROWN, 'collision': true},
##       '.': {'ground': Tile.PATH},
##       'w': {'ground': Tile.WALL_BROWN, 'collision': true},
##       'D': {'ground': Tile.PATH, 'decoration': Tile.DOOR},
##       'S': {'furniture': 'shelf', 'fw': 6, 'fh': 1, 'z': 4},
##       'V': {'furniture': 'shelf', 'fw': 1, 'fh': 4, 'z': 4},
##       't': {'furniture': 'table', 'fw': 2, 'fh': 1, 'z': 2},
##       'k': {'furniture': 'desk',  'fw': 2, 'fh': 1, 'z': 3},
##   }
##   const ENTRY_POINTS := {"front_door": Vector2(4, 7)}
##   const EXITS        := {Vector2i(4, 7): {"map": "res://overworld/town_map.gd", "entry": "library_door"}}
##   const LABELS        := [["Library", 2, 0]]

const Tile = preload("res://overworld/overworld_constants.gd").Tile


static func build(target: Node) -> void:
	var map: String = target.MAP
	var legend: Dictionary = target.LEGEND

	var lines := map.strip_edges().split("\n")
	var h := lines.size()
	var w := 0
	for line in lines:
		w = maxi(w, line.length())

	target.MAP_W = w
	target.MAP_H = h

	_init_arrays(target, w, h)

	var furniture_list: Array = []

	# Pass 1: base map
	_parse_grid(target, lines, legend, w, h, furniture_list)

	# Pass 2+: overlay layers
	var layer_idx := 2
	while true:
		var map_prop: String = "LAYER" + str(layer_idx)
		var legend_prop: String = "LAYER" + str(layer_idx) + "_LEGEND"
		var overlay_map = target.get(map_prop)
		var overlay_legend = target.get(legend_prop)
		if overlay_map == null or overlay_legend == null:
			break
		if not overlay_map is String or not overlay_legend is Dictionary:
			break

		var overlay_lines := (overlay_map as String).strip_edges().split("\n")
		_parse_grid(target, overlay_lines, overlay_legend as Dictionary, w, h, furniture_list)

		layer_idx += 1

	target._furniture_list = furniture_list


static func _init_arrays(target: Node, w: int, h: int) -> void:
	target.collision = []
	target.ground = []
	target.decorations = []
	for y in range(h):
		target.collision.append([])
		target.ground.append([])
		target.decorations.append([])
		for x in range(w):
			target.collision[y].append(0)
			target.ground[y].append(Tile.PATH)
			target.decorations[y].append(Tile.BLANK)


static func _parse_grid(target: Node, lines: Array, legend: Dictionary, w: int, h: int, furniture_list: Array) -> void:
	for y in range(min(lines.size(), h)):
		var line: String = lines[y]
		for x in range(min(line.length(), w)):
			var ch: String = line[x]
			if ch == ' ':
				continue
			if not legend.has(ch):
				continue
			var entry: Dictionary = legend[ch]

			# Ground tile
			if entry.has('ground'):
				target.ground[y][x] = int(entry['ground'])

			# Collision
			if entry.get('collision', false):
				target.collision[y][x] = 1

			# Decoration
			if entry.has('decoration'):
				target.decorations[y][x] = int(entry['decoration'])

			# Doors are always walkable
			if entry.has('decoration') and int(entry['decoration']) == Tile.DOOR:
				target.collision[y][x] = 0
				target.ground[y][x] = Tile.PATH

			# Furniture (origin-only; collision set for full fw×fh)
			if entry.has('furniture'):
				var fw: int = int(entry.get('fw', 1))
				var fh: int = int(entry.get('fh', 1))
				var z: int = int(entry.get('z', 0))
				var blocks: bool = entry.get('blocks', true)
				furniture_list.append([entry['furniture'], x, y, z, blocks, fw, fh])
				for dy in range(fh):
					for dx in range(fw):
						var px: int = x + dx
						var py: int = y + dy
						if px >= 0 and px < w and py >= 0 and py < h:
							target.collision[py][px] = 1

			# Spawn point (for NPC placement, triggers, etc.)
			if entry.has('spawn'):
				if not 'spawns' in target:
					target.spawns = []
				target.spawns.append({'name': entry['spawn'], 'pos': Vector2i(x, y)})
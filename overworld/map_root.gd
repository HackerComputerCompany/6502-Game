extends Node2D
class_name MapRoot

## Root node for editor-authored overworld maps (house.tscn, library.tscn, etc.)
##
## Scene layout:
##   GroundTileMap / DecorationTileMap — TileMapLayer children using shared_tileset.tres
##   EntryPoints — EntryPointMarker children (entry_id → spawn tile)
##   Exits — ExitMarker children (tile_x/y, target_map, entry_id)
##   Furniture — FurnitureMarker and/or Sprite2D props
##   Labels — room name Label nodes
##   CollisionCache — legacy collision grid from furniture/appliances (optional)

@onready var ground_tilemap: TileMapLayer = $GroundTileMap
@onready var decoration_tilemap: TileMapLayer = $DecorationTileMap
@onready var entry_points: Node2D = $EntryPoints
@onready var exits: Node2D = $Exits
@onready var furniture: Node2D = $Furniture
@onready var labels: Node2D = $Labels

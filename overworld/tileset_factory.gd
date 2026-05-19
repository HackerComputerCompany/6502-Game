class_name TilesetFactory
extends RefCounted

## 16×16 tile atlas from procgen_assets (native Stardew-scale art).

const _OW = preload("res://overworld/overworld_constants.gd")
const TILE_SIZE := _OW.TILE_SIZE
const SOURCE_ID := 0

static func build_shared_tileset() -> TileSet:
	var P := preload("res://overworld/procgen_assets.gd")
	var Tile := preload("res://overworld/town_map.gd").Tile

	var textures: Array = []
	textures.resize(14)
	textures[Tile.GRASS] = P.tile_grass()
	textures[Tile.PATH] = P.tile_path()
	textures[Tile.WALL_BROWN] = P.tile_building_wall(Color(0.5, 0.3, 0.2))
	textures[Tile.WALL_BEIGE] = P.tile_building_wall(Color(0.85, 0.8, 0.7))
	textures[Tile.WALL_GRAY] = P.tile_building_wall(Color(0.55, 0.55, 0.58))
	textures[Tile.ROOF_RED] = P.tile_roof(Color(0.6, 0.2, 0.1))
	textures[Tile.ROOF_GRAY] = P.tile_roof(Color(0.45, 0.45, 0.5))
	textures[Tile.DOOR] = P.tile_door()
	textures[Tile.WATER] = P.tile_water()
	textures[Tile.FENCE] = P.tile_fence()
	textures[Tile.TREE] = P.tile_tree()
	textures[Tile.SIGN] = P.tile_sign()
	textures[Tile.BLANK] = _blank_texture()
	textures[Tile.SIDEWALK] = P.tile_path()

	var atlas_w := 14 * TILE_SIZE
	var atlas_img := Image.create(atlas_w, TILE_SIZE, false, Image.FORMAT_RGBA8)
	atlas_img.fill(Color(0, 0, 0, 0))
	for i in range(14):
		var tile_img: Image = textures[i].get_image()
		for px in range(TILE_SIZE):
			for py in range(TILE_SIZE):
				atlas_img.set_pixel(i * TILE_SIZE + px, py, tile_img.get_pixel(px, py))

	var atlas_tex := ImageTexture.create_from_image(atlas_img)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = atlas_tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in range(14):
		source.create_tile(Vector2i(i, 0))
	ts.add_source(source, SOURCE_ID)
	return ts

static func _blank_texture() -> ImageTexture:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

static func save_shared_tileset(path: String = "res://overworld/art/tilesets/shared_tileset.tres") -> void:
	var ts := build_shared_tileset()
	var err := ResourceSaver.save(ts, path)
	if err != OK:
		push_error("Failed to save tileset: %s" % path)
	else:
		print("Saved tileset: ", path)

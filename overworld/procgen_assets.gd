static func make_tile_texture(color: Color, detail_color: Color = Color(), detail_pixels: Array = []) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(color)
	for p in detail_pixels:
		img.set_pixel(p[0], p[1], detail_color)
	return ImageTexture.create_from_image(img)

static func tile_grass() -> ImageTexture:
	return make_tile_texture(Color(0.22, 0.55, 0.18), Color(0.18, 0.45, 0.14), [
		[3, 5], [4, 5], [8, 3], [9, 3], [12, 7], [13, 7],
		[5, 11], [6, 11], [10, 13], [11, 13],
	])

static func tile_path() -> ImageTexture:
	return make_tile_texture(Color(0.55, 0.50, 0.42), Color(0.45, 0.40, 0.35), [
		[1, 1], [2, 1], [14, 14], [13, 14],
	])

static func tile_building_wall(color: Color = Color(0.5, 0.3, 0.2)) -> ImageTexture:
	return make_tile_texture(color, Color(color.r * 0.7, color.g * 0.7, color.b * 0.7), [
		[0, 0], [1, 0], [0, 1], [1, 1],
		[14, 14], [15, 14], [14, 15], [15, 15],
	])

static func tile_roof(color: Color = Color(0.6, 0.2, 0.1)) -> ImageTexture:
	return make_tile_texture(color, Color(color.r * 1.2, color.g * 1.2, color.b * 1.2), [
		[0, 7], [15, 7],
	])

static func tile_door() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.25, 0.1))
	for y in range(0, 16):
		img.set_pixel(0, y, Color(0.3, 0.18, 0.05))
		img.set_pixel(15, y, Color(0.3, 0.18, 0.05))
	img.set_pixel(8, 8, Color(0.9, 0.7, 0.2))
	return ImageTexture.create_from_image(img)

static func tile_water() -> ImageTexture:
	return make_tile_texture(Color(0.15, 0.35, 0.6), Color(0.25, 0.45, 0.7), [
		[2, 3], [3, 3], [7, 7], [8, 7], [12, 11], [13, 11],
	])

static func tile_fence() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(0, 16):
		img.set_pixel(x, 4, Color(0.5, 0.35, 0.2))
		img.set_pixel(x, 8, Color(0.5, 0.35, 0.2))
		img.set_pixel(x, 12, Color(0.5, 0.35, 0.2))
	img.set_pixel(0, 0, Color(0.5, 0.35, 0.2))
	img.set_pixel(0, 15, Color(0.5, 0.35, 0.2))
	img.set_pixel(15, 0, Color(0.5, 0.35, 0.2))
	img.set_pixel(15, 15, Color(0.5, 0.35, 0.2))
	return ImageTexture.create_from_image(img)

static func tile_tree() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(4, 12):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.15, 0.5, 0.1))
	for x in range(6, 10):
		for y in range(0, 4):
			img.set_pixel(x, y, Color(0.1, 0.4, 0.08))
	img.set_pixel(7, 10, Color(0.4, 0.25, 0.1))
	img.set_pixel(7, 11, Color(0.4, 0.25, 0.1))
	img.set_pixel(7, 12, Color(0.4, 0.25, 0.1))
	img.set_pixel(7, 13, Color(0.4, 0.25, 0.1))
	img.set_pixel(7, 14, Color(0.4, 0.25, 0.1))
	img.set_pixel(7, 15, Color(0.4, 0.25, 0.1))
	return ImageTexture.create_from_image(img)

static func tile_sign() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(7, 0, Color(0.5, 0.35, 0.2))
	img.set_pixel(7, 1, Color(0.5, 0.35, 0.2))
	img.set_pixel(7, 2, Color(0.5, 0.35, 0.2))
	for x in range(3, 13):
		for y in range(3, 8):
			img.set_pixel(x, y, Color(0.6, 0.5, 0.3))
	img.set_pixel(3, 3, Color(0.5, 0.4, 0.2))
	img.set_pixel(12, 3, Color(0.5, 0.4, 0.2))
	img.set_pixel(3, 7, Color(0.5, 0.4, 0.2))
	img.set_pixel(12, 7, Color(0.5, 0.4, 0.2))
	img.set_pixel(5, 5, Color(0.2, 0.2, 0.2))
	img.set_pixel(6, 5, Color(0.2, 0.2, 0.2))
	img.set_pixel(7, 5, Color(0.2, 0.2, 0.2))
	img.set_pixel(8, 5, Color(0.2, 0.2, 0.2))
	img.set_pixel(9, 5, Color(0.2, 0.2, 0.2))
	return ImageTexture.create_from_image(img)

static func make_character_texture(body_color: Color, head_color: Color, hat_color: Color = Color()) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if hat_color.a > 0:
		for x in range(4, 12):
			for y in range(0, 4):
				img.set_pixel(x, y, hat_color)
	for x in range(4, 12):
		for y in range(4, 10):
			img.set_pixel(x, y, head_color)
	for x in range(5, 11):
		for y in range(10, 18):
			img.set_pixel(x, y, body_color)
	for x in range(5, 8):
		for y in range(18, 24):
			img.set_pixel(x, y, Color(0.2, 0.15, 0.1))
	for x in range(8, 11):
		for y in range(18, 24):
			img.set_pixel(x, y, Color(0.2, 0.15, 0.1))
	img.set_pixel(6, 6, Color(1, 1, 1))
	img.set_pixel(9, 6, Color(1, 1, 1))
	img.set_pixel(6, 7, Color(0.1, 0.1, 0.1))
	img.set_pixel(9, 7, Color(0.1, 0.1, 0.1))
	img.set_pixel(7, 8, Color(0.8, 0.5, 0.3))
	img.set_pixel(8, 8, Color(0.8, 0.5, 0.3))
	img.set_pixel(7, 9, Color(0.8, 0.5, 0.3))
	img.set_pixel(8, 9, Color(0.8, 0.5, 0.3))
	return ImageTexture.create_from_image(img)

static func player_texture() -> ImageTexture:
	return make_character_texture(Color(0.2, 0.4, 0.8), Color(0.9, 0.7, 0.5), Color(0.6, 0.1, 0.1))

static func npc_texture(variant: int = 0) -> ImageTexture:
	var colors := [
		[Color(0.8, 0.3, 0.3), Color(0.9, 0.7, 0.5), Color()],
		[Color(0.3, 0.6, 0.3), Color(0.8, 0.6, 0.4), Color(0.4, 0.3, 0.2)],
		[Color(0.5, 0.3, 0.7), Color(0.9, 0.8, 0.6), Color()],
		[Color(0.2, 0.5, 0.6), Color(0.8, 0.6, 0.4), Color(0.3, 0.2, 0.5)],
		[Color(0.7, 0.5, 0.2), Color(0.8, 0.6, 0.4), Color(0.5, 0.3, 0.1)],
	]
	var c = colors[variant % colors.size()]
	return make_character_texture(c[0], c[1], c[2])

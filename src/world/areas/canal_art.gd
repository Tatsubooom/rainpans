class_name CanalArt
## Area 3: an underground canal. Rain only falls through a collapsed hole in
## the vault, in a shaft of grey light; everywhere else it is drips from the
## cracked ceiling. Big, long reverb.

const W := 320
const H := 180

const LAMP := Vector2i(38, 104)
const FLOOR_TOP := 134
const HOLE_X0 := 122
const HOLE_X1 := 206
const VAULT_Y := 66


static func build() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3303
	var drips := []
	for x in [146, 92, 238, 60, 276, 184, 110, 300, 20]:
		drips.append(Vector2(x, VAULT_Y + 2 + (x * 7) % 9))
	return {
		"name": "地下水路",
		"layers": {"sky": _back(rng), "mid": _mid(rng), "floor": _floor(rng), "front": _front(rng)},
		"floor": Rect2(6, 140, 308, 26),
		"shelters": [Rect2(0, 0, HOLE_X0, VAULT_Y + 4), Rect2(HOLE_X1, 0, W - HOLE_X1, VAULT_Y + 4)],
		"rain_rect": Rect2(HOLE_X0 + 4, 8, HOLE_X1 - HOLE_X0 - 8, 0),
		"far_rain_rect": Rect2(HOLE_X0 + 6, 10, HOLE_X1 - HOLE_X0 - 12, 120),
		"drips": drips,
		"drip_depth": 152.0,
		"lamp": Vector2(LAMP),
		"lamp_color": Pal.LAMP2,
		"puddles": [Rect2(140, 150, 46, 8), Rect2(60, 158, 26, 4), Rect2(232, 146, 30, 4)],
		"smoke": [Vector2(282, 98)],
		"smoke_steam": true,
		"floor_y": FLOOR_TOP,
		"blinks": [[Vector2(231, 79), Color("3aa060"), 5.0, 0.92]],
		"trickles": [[Vector2(HOLE_X0 + 6, VAULT_Y - 6), 150.0], [Vector2(HOLE_X1 - 8, VAULT_Y - 6), 148.0]],
		"ambient": Color(0.98, 0.86, 0.8),
		"bed": "water",
		"reverb_room": 0.97,
		"shaft": Rect2(HOLE_X0, 0, HOLE_X1 - HOLE_X0, 160),
		"water_y": 167,
	}


static func _brick(c: PixCanvas, x0: int, y0: int, w: int, h: int, base: Color, mortar: Color, hi: Color, rng: RandomNumberGenerator) -> void:
	c.rect(x0, y0, w, h, base)
	for y in range(y0, y0 + h):
		var row := (y - y0) / 4
		if (y - y0) % 4 == 3:
			c.hline(x0, x0 + w - 1, y, mortar)
			continue
		var off := 4 if row % 2 == 0 else 0
		for x in range(x0, x0 + w):
			if (x - x0 + off) % 8 == 7:
				c.px(x, y, mortar)
			elif (y - y0) % 4 == 0 and rng.randf() < 0.25:
				c.px(x, y, hi)


static func _back(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H, Pal.INK)
	# Sky seen through the hole in the vault.
	c.vgrad(HOLE_X0 - 14, 0, HOLE_X1 - HOLE_X0 + 28, VAULT_Y + 4, [Pal.NIGHT2, Pal.NIGHT3, Pal.FOG0, Pal.FOG1])
	# A broken building leaning over the hole, high above.
	c.poly(PackedVector2Array([Vector2(HOLE_X0 + 40, 0), Vector2(HOLE_X1 + 4, 0), Vector2(HOLE_X1 + 4, 22), Vector2(HOLE_X0 + 56, 14)]), Pal.NIGHT1)
	for k in 5:
		c.hline(HOLE_X0 + 58 + k * 3, HOLE_X1, 4 + k * 3, Pal.NIGHT0)
	# Far tunnel wall in brick.
	_brick(c, 0, VAULT_Y - 6, W, FLOOR_TOP - VAULT_Y + 6, Pal.RUST0, Pal.INK, Pal.RUST1, rng)
	# A further arch, black, leading on into the dark.
	var ax := 228
	var aw := 64
	for y in range(84, FLOOR_TOP):
		for x in range(ax, ax + aw):
			var dx := (x - ax - aw / 2.0) / (aw / 2.0)
			var top := 84 + (1.0 - sqrt(maxf(0.0, 1.0 - dx * dx))) * 22.0
			if y >= top:
				c.px(x, y, Pal.INK)
			elif y >= top - 2:
				c.px(x, y, Pal.RUST1)
	# One faint far light deep in the tunnel.
	c.px(258, 114, Pal.LAMP3)
	c.px(258, 115, Pal.LAMP4)
	# Water stains and moss low on the wall.
	for x in W:
		var hgt := 4 + int(absf(sin(x * 0.11)) * 6.0)
		for y in range(FLOOR_TOP - hgt, FLOOR_TOP):
			if c.get_px(x, y) != Pal.INK:
				c.dpx(x, y, Pal.MOSS0, 0.7)
		if rng.randf() < 0.1:
			c.vline(x, VAULT_Y, VAULT_Y + rng.randi_range(6, 30), Pal.RUST1)
	return c.img


static func _mid(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Pipes running along the wall, one leaking steam.
	for py in [92, 98]:
		c.hline(0, W, py, Pal.CON1)
		c.hline(0, W, py + 1, Pal.CON3 if py == 92 else Pal.CON2)
		c.hline(0, W, py + 2, Pal.INK)
		for x in range(6, W, 38):
			c.rect(x, py - 1, 2, 5, Pal.RUST2)
	c.rect(278, 96, 6, 4, Pal.RUST3)
	c.px(282, 97, Pal.INK)
	# Ladder up to a sealed hatch.
	for y in range(70, FLOOR_TOP):
		c.px(176, y, Pal.RUST2)
		c.px(183, y, Pal.RUST2)
		if y % 5 == 0:
			c.hline(177, 182, y, Pal.RUST1)
	# Hanging roots through the hole's edge.
	for i in 18:
		var rx := HOLE_X0 + rng.randi_range(-4, HOLE_X1 - HOLE_X0 + 4)
		var rl := rng.randi_range(4, 22)
		for k in rl:
			var col := Pal.MOSS2 if k < rl - 3 else Pal.MOSS3
			c.px(rx + int(sin(k * 0.5 + i) * 1.2), VAULT_Y - 2 + k, col)
	return c.img


static func _floor(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Walkway with a stone kerb, then the canal channel in front.
	c.vgrad(0, FLOOR_TOP, W, 34, [Pal.CON0, Pal.CON1, Pal.CON2])
	for x in range(0, W, 16):
		c.vline(x + (4 if (x / 16) % 2 == 0 else 0), FLOOR_TOP, FLOOR_TOP + 33, Pal.CON0)
	for y in [FLOOR_TOP + 11, FLOOR_TOP + 22]:
		c.hline(0, W, y, Pal.CON0)
	var n := FastNoiseLite.new()
	n.seed = 31
	n.frequency = 0.2
	for y in range(FLOOR_TOP, FLOOR_TOP + 33):
		for x in W:
			var v := n.get_noise_2d(x, y * 1.5)
			if v > 0.35:
				c.dpx(x, y, Pal.CON3, (v - 0.35) * 1.8)
	# Kerb.
	c.rect(0, 165, W, 3, Pal.CON3)
	c.hline(0, W, 165, Pal.CON4)
	c.hline(0, W, 167, Pal.INK)
	# Canal water (animated highlights are drawn by the stage).
	c.rect(0, 168, W, H - 168, Pal.NIGHT1)
	for y in range(168, H):
		c.drect(0, y, W, 1, Pal.NIGHT2, (y - 168) / 16.0)
	# Puddles.
	for p in [Rect2(140, 150, 46, 8), Rect2(60, 158, 26, 4), Rect2(232, 146, 30, 4)]:
		var cx := int(p.position.x + p.size.x / 2)
		var cy := int(p.position.y + p.size.y / 2)
		c.ellipse(cx, cy, p.size.x / 2 + 1, p.size.y / 2 + 1, Pal.CON0)
		c.ellipse(cx, cy, p.size.x / 2, p.size.y / 2, Pal.NIGHT1)
	# A crate, a sleeping bag, a stove: someone stayed here once.
	c.rect(8, 124, 18, 12, Pal.RUST1)
	c.hline(8, 25, 124, Pal.RUST2)
	c.rect(30, 130, 22, 5, Pal.MOSS1)
	c.hline(30, 51, 130, Pal.MOSS2)
	c.ellipse(34, 132, 4, 2, Pal.MOSS2)
	c.rect(56, 128, 6, 6, Pal.CON3)
	c.rect(57, 126, 4, 2, Pal.CON4)
	return c.img


static func _front(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# The vault: a heavy brick arch across the top with a ragged hole.
	_brick(c, 0, 0, W, VAULT_Y, Pal.CON1, Pal.INK, Pal.CON2, rng)
	for x in W:
		var t := (x - W / 2.0) / (W / 2.0)
		var bottom := int(VAULT_Y - 10 + t * t * 12.0)
		c.erase_rect(x, bottom + 2, 1, VAULT_Y - bottom)
		c.px(x, bottom, Pal.CON3)
		c.px(x, bottom + 1, Pal.INK)
	# The collapse: an irregular oval torn through the vault, seen from below,
	# with a broken lip catching the light from above.
	var hc := Vector2((HOLE_X0 + HOLE_X1) / 2.0, VAULT_Y * 0.42)
	var hr := Vector2((HOLE_X1 - HOLE_X0) / 2.0, VAULT_Y * 0.5)
	var rough := FastNoiseLite.new()
	rough.seed = 77
	rough.frequency = 0.25
	for y in range(0, VAULT_Y + 2):
		for x in range(HOLE_X0 - 12, HOLE_X1 + 12):
			var d := Vector2((x - hc.x) / hr.x, (y - hc.y) / hr.y).length()
			d += rough.get_noise_2d(x, y) * 0.12
			if d < 1.0:
				c.erase_rect(x, y, 1, 1)
			elif d < 1.08:
				c.px(x, y, Pal.CON3 if y > hc.y else Pal.CON0)
			elif d < 1.16 and y > hc.y:
				c.px(x, y, Pal.CON2)
	# Rubble hanging on rebar at the lip.
	for k in 6:
		var rx := int(hc.x + rng.randi_range(-int(hr.x) + 6, int(hr.x) - 6))
		var ry := int(hc.y + hr.y * 0.9)
		c.line(rx, ry - 2, rx + rng.randi_range(-3, 3), ry + rng.randi_range(2, 6), Pal.RUST2)
	# Side pillars framing the scene.
	for px in [0, W - 10]:
		_brick(c, px, VAULT_Y - 4, 10, FLOOR_TOP + 34 - VAULT_Y + 4, Pal.CON1, Pal.INK, Pal.CON2, rng)
		c.vline(px + (9 if px == 0 else 0), VAULT_Y - 4, FLOOR_TOP + 30, Pal.CON3 if px == 0 else Pal.INK)
	# Lantern hung on a bracket from the left pillar.
	c.hline(10, LAMP.x, LAMP.y - 9, Pal.RUST2)
	c.line(10, LAMP.y - 3, 18, LAMP.y - 9, Pal.RUST1)
	c.vline(LAMP.x, LAMP.y - 9, LAMP.y - 5, Pal.INK)
	var lantern := PixCanvas.grid([
		"..ooo..",
		".o444o.",
		"ooooooo",
		"o1abba1",
		"o1bccb1",
		"o1bccb1",
		"o1abba1",
		"ooooooo",
		".o444o.",
	], {
		"o": Pal.INK, "1": Pal.RUST1, "4": Pal.RUST3,
		"a": Pal.LAMP3, "b": Pal.LAMP1, "c": Pal.LAMP0,
	})
	c.stamp(lantern, LAMP.x - 3, LAMP.y - 5)
	return c.img

class_name RailArt
## Area 2: a broken elevated railway. A platform canopy shelters the left,
## an abandoned railcar with lit windows rests on the right, and the drowned
## city lies below, mirrored in flood water.

const W := 320
const H := 180

const LAMP := Vector2i(62, 104)
const FLOOR_TOP := 133
const CANOPY_Y := 84
const CANOPY_X1 := 118


static func build() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7071
	return {
		"name": "途切れた高架",
		"layers": {"sky": _sky(rng), "mid": _mid(rng), "floor": _floor(rng), "front": _front(rng)},
		"floor": Rect2(6, 140, 308, 36),
		"shelters": [Rect2(0, 0, CANOPY_X1, CANOPY_Y + 6)],
		"drips": [Vector2(108, 92), Vector2(84, 92), Vector2(30, 92), Vector2(97, 92), Vector2(58, 92), Vector2(16, 92), Vector2(113, 92)],
		"drip_depth": 154.0,
		"lamp": Vector2(LAMP),
		"lamp_color": Pal.LAMP2,
		"puddles": [Rect2(150, 158, 40, 6), Rect2(226, 168, 50, 7), Rect2(30, 166, 34, 5), Rect2(262, 147, 24, 4)],
		"smoke": [Vector2(286, 92), Vector2(40, 98)],
		"floor_y": FLOOR_TOP,
		"ambient": Color(0.9, 0.96, 1.0),
		"reverb_room": 0.86,
		"windows": [Vector2(222, 112), Vector2(250, 112), Vector2(278, 112)],
	}


static func _sky(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H, Pal.NIGHT0)
	c.vgrad(0, 0, W, 104, [Pal.INK, Pal.NIGHT0, Pal.NIGHT1, Pal.NIGHT2, Pal.NIGHT3, Pal.FOG0])
	var n := FastNoiseLite.new()
	n.seed = 23
	n.frequency = 0.014
	n.fractal_octaves = 3
	for y in 90:
		for x in W:
			var v := (n.get_noise_2d(x * 0.8, y * 2.6) * 0.5 + 0.5) * (1.0 - y / 120.0)
			if v > 0.4:
				c.dpx(x, y, Pal.NIGHT2, (v - 0.4) * 5.0)
			if v > 0.56:
				c.dpx(x, y, Pal.NIGHT3, (v - 0.56) * 4.0)
	# Drowned city: rooftops and towers stand out of a flat flood.
	var water_y := 112
	var x := -4
	while x < W:
		var bw := rng.randi_range(6, 20)
		var top := rng.randi_range(70, 104)
		if rng.randf() < 0.12:
			top = rng.randi_range(40, 64)
		for i in bw:
			var bite := int(absf(sin((x + i) * 0.9)) * 3.0) if rng.randf() < 0.4 else 0
			c.vline(x + i, top + bite, water_y, Pal.NIGHT3)
			c.px(x + i, top + bite, Pal.FOG0)
		var wy := top + 3
		while wy < water_y - 2:
			for wx in range(x + 2, x + bw - 1, 3):
				if rng.randf() < 0.5:
					c.px(wx, wy, Pal.NIGHT1)
			wy += 4
		x += bw + rng.randi_range(0, 5)
	for y in range(80, water_y):
		c.drect(0, y, W, 1, Pal.FOG0, (y - 80) / 50.0)
	# Flood water: dark, with broken reflections of the skyline.
	c.rect(0, water_y, W, H - water_y, Pal.NIGHT1)
	for y in range(water_y, H):
		var depth := y - water_y
		for xx in W:
			var src := c.get_px(xx, water_y - 1 - depth * 2)
			if src == Pal.NIGHT3 or src == Pal.FOG0:
				if (xx + int(sin(y * 1.7) * 2.0)) % 3 != 0:
					c.px(xx, y, Pal.NIGHT2)
		if depth % 3 == 0:
			for xx in range(rng.randi_range(0, 9), W, rng.randi_range(9, 23)):
				c.hline(xx, xx + rng.randi_range(2, 6), y, Pal.FOG0)
	return c.img


static func _mid(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# The viaduct continues to the left as pillars; the deck has fallen.
	for px in [8, 52, 96]:
		c.rect(px, 98, 9, 40, Pal.CON1)
		c.vline(px, 98, 137, Pal.CON2)
		c.vline(px + 8, 98, 137, Pal.CON0)
		c.rect(px - 3, 96, 15, 3, Pal.CON2)
		c.hline(px - 3, px + 11, 96, Pal.CON3)
		for k in 3:
			c.line(px + 2 + k * 3, 96, px + 1 + k * 3 + rng.randi_range(-2, 2), 91 + rng.randi_range(-2, 1), Pal.RUST1)
	# A bent catenary mast and wires hanging loose.
	c.vline(150, 40, 134, Pal.CON1)
	c.vline(151, 40, 134, Pal.CON0)
	c.line(151, 44, 176, 48, Pal.CON1)
	for x in range(0, 320):
		var y := int(52 + 0.0009 * pow(x - 160, 2) * 1.0)
		if x < 150 or x > 151:
			c.px(x, y, Pal.INK)
	for x in range(176, 236):
		var y := int(48 + (x - 176) * 0.9 + sin((x - 176) * 0.08) * 6.0)
		c.px(x, y, Pal.INK)

	# The railcar on the right, windows glowing from a lamp left inside.
	var cx := 206
	var cy := 94
	var cw := 116
	var ch := 40
	c.rect(cx, cy, cw, ch, Pal.MOSS1)
	c.hline(cx, cx + cw, cy, Pal.MOSS3)
	c.hline(cx, cx + cw, cy + 1, Pal.MOSS2)
	c.rect(cx, cy - 4, cw, 4, Pal.CON2)
	c.hline(cx + 2, cx + cw, cy - 5, Pal.CON3)
	c.hline(cx, cx + cw, cy + 26, Pal.MOSS0)
	c.hline(cx, cx + cw, cy + 27, Pal.RUST2)
	c.rect(cx, cy + 34, cw, 6, Pal.INK)
	for wx in [cx + 8, cx + 36, cx + 64, cx + 92]:
		c.rect(wx, cy + 8, 18, 14, Pal.INK)
		c.rect(wx + 1, cy + 9, 16, 12, Pal.LAMP3)
		c.rect(wx + 2, cy + 10, 14, 6, Pal.LAMP2)
		c.hline(wx + 3, wx + 13, cy + 10, Pal.LAMP1)
		# Seat backs silhouetted against the light.
		c.rect(wx + 2, cy + 16, 5, 5, Pal.RUST1)
		c.rect(wx + 10, cy + 16, 5, 5, Pal.RUST1)
		c.vline(wx + 9, cy + 9, cy + 20, Pal.INK)
	# One broken pane with rain streaks on the others.
	c.line(cx + 64, cy + 9, cx + 72, cy + 20, Pal.INK)
	for i in 30:
		var sx := cx + 9 + rng.randi_range(0, 100)
		var sy := cy + 9 + rng.randi_range(0, 8)
		if c.get_px(sx, sy) == Pal.LAMP2 or c.get_px(sx, sy) == Pal.LAMP3:
			c.vline(sx, sy, sy + rng.randi_range(1, 3), Pal.LAMP3)
	# Rust and moss running down the body.
	for x in range(cx, cx + cw):
		if rng.randf() < 0.18:
			c.vline(x, cy + 22, cy + 22 + rng.randi_range(2, 10), Pal.RUST1)
		if rng.randf() < 0.12:
			c.vline(x, cy + 2, cy + 2 + rng.randi_range(1, 5), Pal.MOSS2)
	# Lit window light spilling on the car's lower body.
	for y in range(cy + 22, cy + 26):
		for x in range(cx + 4, cx + cw - 4):
			c.dpx(x, y, Pal.LAMP4, 0.35 - (y - cy - 22) * 0.08)
	# Faded number.
	c.rect(cx + 108, cy + 10, 6, 8, Pal.MOSS2)
	c.px(cx + 110, cy + 12, Pal.BONE)
	c.px(cx + 110, cy + 15, Pal.BONE)
	return c.img


static func _floor(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Deck slab and a low parapet along the back.
	c.rect(0, 126, W, FLOOR_TOP - 126, Pal.CON2)
	c.hline(0, W, 126, Pal.CON4)
	c.hline(0, W, FLOOR_TOP - 1, Pal.CON0)
	for x in range(0, W, 17):
		c.vline(x, 127, FLOOR_TOP - 2, Pal.CON1)
	c.vgrad(0, FLOOR_TOP, W, H - FLOOR_TOP, [Pal.CON0, Pal.CON1, Pal.CON1, Pal.CON2])
	# Ballast texture.
	var n := FastNoiseLite.new()
	n.seed = 9
	n.frequency = 0.3
	for y in range(FLOOR_TOP, H):
		for x in W:
			var v := n.get_noise_2d(x, y * 1.6)
			if v > 0.3:
				c.dpx(x, y, Pal.CON3, (v - 0.3) * 1.6)
			elif v < -0.5:
				c.px(x, y, Pal.CON0)
	# Sleepers and two rails converging toward a vanishing point far left.
	var vp := Vector2(-260, 120)
	for i in 26:
		var sx := 4 + i * 13
		c.line(sx, 146, sx - 6, 170, Pal.RUST0)
		c.line(sx + 1, 146, sx - 5, 170, Pal.RUST1)
	for ry in [148, 168]:
		for x in W:
			var y: int = ry + int((x - W) * (ry - vp.y) / (W - vp.x) * 0.0)
			c.px(x, y, Pal.CON4)
			c.px(x, y + 1, Pal.CON1)
			if (x * 13) % 7 == 0:
				c.px(x, y, Pal.RUST3)
	# Weeds breaking through the ballast.
	for i in 16:
		var wx := rng.randi_range(0, W)
		var wy := rng.randi_range(FLOOR_TOP + 2, H - 2)
		for k in rng.randi_range(2, 6):
			c.px(wx + (k % 2), wy - k, Pal.MOSS2 if k < 3 else Pal.MOSS3)
	# Puddles.
	for p in [Rect2(150, 158, 40, 6), Rect2(226, 168, 50, 7), Rect2(30, 166, 34, 5), Rect2(262, 147, 24, 4)]:
		var cx := int(p.position.x + p.size.x / 2)
		var cy := int(p.position.y + p.size.y / 2)
		c.ellipse(cx, cy, p.size.x / 2 + 1, p.size.y / 2 + 1, Pal.CON0)
		c.ellipse(cx, cy, p.size.x / 2, p.size.y / 2, Pal.NIGHT1)
		for yy in range(int(p.position.y), int(p.end.y)):
			for xx in range(int(p.position.x), int(p.end.x)):
				if c.get_px(xx, yy) == Pal.NIGHT1:
					var t: float = (yy - p.position.y) / p.size.y
					c.dpx(xx, yy, Pal.NIGHT2, 1.0 - t)
	# Window light falling on the deck in front of the railcar.
	for wx in [214, 242, 270, 298]:
		for y in range(FLOOR_TOP + 1, FLOOR_TOP + 9):
			var spread := (y - FLOOR_TOP) / 2
			for x in range(wx - 2 - spread, wx + 18 + spread):
				c.dpx(x, y, Pal.RUST1, 0.5 - (y - FLOOR_TOP) * 0.05)
	# Platform edge under the canopy.
	c.rect(0, FLOOR_TOP, CANOPY_X1 - 4, 4, Pal.CON3)
	c.hline(0, CANOPY_X1 - 5, FLOOR_TOP, Pal.CON4)
	for x in range(0, CANOPY_X1 - 4, 4):
		c.px(x, FLOOR_TOP + 1, Pal.LAMP4 if x % 8 == 0 else Pal.CON2)
	# A bench and a dead vending machine on the platform.
	c.rect(10, 104, 16, 30, Pal.NIGHT3)
	c.rect(12, 107, 12, 12, Pal.NIGHT1)
	c.hline(12, 23, 107, Pal.FOG0)
	for k in 3:
		c.rect(13 + k * 4, 109, 2, 3, [Pal.RUST3, Pal.MOSS3, Pal.FOG2][k])
	c.rect(12, 123, 12, 3, Pal.INK)
	c.vline(10, 104, 133, Pal.FOG0)
	c.rect(36, 120, 30, 2, Pal.RUST2)
	c.hline(36, 65, 120, Pal.RUST3)
	c.rect(38, 122, 2, 8, Pal.CON1)
	c.rect(62, 122, 2, 8, Pal.CON1)
	c.rect(36, 112, 30, 2, Pal.RUST1)
	return c.img


static func _front(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Platform canopy: a concrete slab broken off on its right end.
	var y0 := CANOPY_Y
	c.rect(0, y0 - 6, CANOPY_X1, 8, Pal.CON2)
	c.hline(0, CANOPY_X1 - 6, y0 - 6, Pal.CON4)
	c.hline(0, CANOPY_X1, y0 + 2, Pal.CON0)
	c.rect(0, y0 + 3, CANOPY_X1 - 2, 2, Pal.INK)
	for x in range(CANOPY_X1 - 8, CANOPY_X1 + 1):
		var bite := (x - (CANOPY_X1 - 8)) / 2
		c.erase_rect(x, y0 - 6, 1, bite)
	# Exposed rebar at the break.
	for k in 4:
		c.line(CANOPY_X1 - 1, y0 - 4 + k * 2, CANOPY_X1 + 3 + k, y0 - 6 + k * 3, Pal.RUST2)
	# Columns.
	for colx in [24, 92]:
		c.rect(colx, y0 + 3, 4, FLOOR_TOP - y0 + 4, Pal.CON2)
		c.vline(colx, y0 + 3, FLOOR_TOP + 6, Pal.CON3)
		c.vline(colx + 3, y0 + 3, FLOOR_TOP + 6, Pal.CON0)
	# Station sign hanging under the slab.
	c.rect(30, y0 + 6, 26, 7, Pal.BONE)
	c.rect(31, y0 + 7, 24, 5, Pal.CON5)
	for k in 5:
		c.rect(33 + k * 4, y0 + 8, 2, 3, Pal.CON1)
	c.vline(32, y0 + 3, y0 + 5, Pal.INK)
	c.vline(53, y0 + 3, y0 + 5, Pal.INK)
	# The lantern somebody hung from the sign.
	c.vline(LAMP.x, y0 + 3, LAMP.y - 5, Pal.INK)
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
	# Foreground: the deck edge ends in a jagged break at the bottom right.
	var edge := PackedVector2Array([
		Vector2(292, 180), Vector2(298, 174), Vector2(304, 176), Vector2(310, 170),
		Vector2(316, 172), Vector2(320, 168), Vector2(320, 180),
	])
	c.poly(edge, Pal.INK)
	return c.img

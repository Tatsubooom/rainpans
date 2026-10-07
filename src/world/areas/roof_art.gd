class_name RoofArt
## Area 1: a ruined rooftop in the rain. Paints the layered backdrop and
## returns the gameplay geometry (floor, overhang, drips, lamp...).

const W := 320
const H := 180

const LAMP := Vector2i(222, 108)
const FLOOR_TOP := 131
const ROOF_Y := 90 # underside of the corrugated overhang
const ROOF_X0 := 194


static func build() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261006
	var sky := _sky(rng)
	var mid := _mid(rng)
	var floor_img := _floor(rng)
	var front := _front(rng)
	return {
		"name": "崩れた屋上",
		"layers": {"sky": sky, "mid": mid, "floor": floor_img, "front": front},
		# Drums sit with their base inside this band.
		"floor": Rect2(6, 138, 308, 38),
		# Rain stops on these (x0, x1, y). Anything below is sheltered.
		"shelters": [Rect2(ROOF_X0, 0, W - ROOF_X0, ROOF_Y + 6)],
		# Drip points along the overhang lip; more open with the 雨樋 upgrade.
		"drips": [Vector2(203, 96), Vector2(231, 96), Vector2(214, 96), Vector2(247, 96), Vector2(197, 96), Vector2(262, 96), Vector2(224, 96)],
		"lamp": Vector2(LAMP),
		"lamp_color": Pal.LAMP2,
		"puddles": [Rect2(36, 155, 48, 9), Rect2(112, 166, 56, 8), Rect2(98, 143, 30, 5), Rect2(150, 150, 22, 4), Rect2(204, 150, 36, 6)],
		"smoke": [Vector2(146, 70)],
		"floor_y": FLOOR_TOP,
		"blinks": [[Vector2(159, 37), Color("d0482e"), 2.6, 0.22], [Vector2(54, 7), Color("d0482e"), 3.4, 0.18]],
		"trickles": [[Vector2(ROOF_X0 + 1, ROOF_Y + 5), 146.0]],
		"weeds": [[Vector2(14, 177), 5], [Vector2(302, 173), 4], [Vector2(137, 133), 6], [Vector2(62, 132), 4], [Vector2(190, 134), 3]],
		"perches": [Vector2(125, 67), Vector2(300, 58), Vector2(40, 110), Vector2(118, 110), Vector2(212, 110)],
		"ambient": Color(0.92, 0.95, 1.0),
		"reverb_room": 0.78,
	}


# ----------------------------------------------------------------- far layer

static func _sky(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H, Pal.NIGHT0)
	c.vgrad(0, 0, W, 112, [Pal.INK, Pal.NIGHT0, Pal.NIGHT1, Pal.NIGHT2, Pal.NIGHT3, Pal.FOG0])
	c.rect(0, 112, W, H - 112, Pal.FOG0)

	# Low clouds: two octaves of noise, dithered in two tones.
	var n := FastNoiseLite.new()
	n.seed = 11
	n.frequency = 0.018
	n.fractal_octaves = 3
	for y in 82:
		for x in W:
			var v := n.get_noise_2d(x, y * 2.2) * 0.5 + 0.5
			var shade := v * (1.0 - y / 110.0)
			if shade > 0.42:
				c.dpx(x, y, Pal.NIGHT2, (shade - 0.42) * 6.0)
			if shade > 0.55:
				c.dpx(x, y, Pal.NIGHT3, (shade - 0.55) * 5.0)

	# Farthest skyline, half lost in rain haze.
	_skyline(c, rng, 66, 98, 6, 18, Pal.NIGHT3, Pal.FOG0, 0.0)
	for y in range(86, 124):
		c.drect(0, y, W, 1, Pal.FOG0, (y - 86) / 60.0)
	# A collapsed tower: the landmark on the horizon.
	_tower(c, 150, 38, Pal.NIGHT3, Pal.FOG0)
	# Nearer skyline with dead windows.
	_skyline(c, rng, 82, 108, 10, 26, Pal.NIGHT2, Pal.NIGHT3, 1.0)
	for y in range(100, 124):
		c.drect(0, y, W, 1, Pal.FOG0, (y - 100) / 40.0)
	return c.img


static func _skyline(c: PixCanvas, rng: RandomNumberGenerator, top_min: int, top_max: int,
		wmin: int, wmax: int, body: Color, edge: Color, windows: float) -> void:
	var x := -rng.randi_range(0, 8)
	while x < W:
		var bw := rng.randi_range(wmin, wmax)
		var top := rng.randi_range(top_min, top_max)
		var broken := rng.randf() < 0.45
		var phase := rng.randf() * 10.0
		var depth := rng.randi_range(2, 6)
		for i in bw:
			var bite := int(absf(sin((x + i) * 0.7 + phase)) * depth) if broken else 0
			c.vline(x + i, top + bite, 130, body)
			c.px(x + i, top + bite, edge)
		if not broken and rng.randf() < 0.3:
			c.vline(x + bw / 2, top - rng.randi_range(4, 10), top, body)
		if windows > 0.0:
			var wy := top + 3
			while wy < 120:
				for wx in range(x + 2, x + bw - 2, 3):
					if rng.randf() < 0.55:
						c.px(wx, wy, Pal.NIGHT1)
				wy += 4
		x += bw + rng.randi_range(-2, 3)


static func _tower(c: PixCanvas, x: int, top: int, body: Color, edge: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(x, 130), Vector2(x, top + 14), Vector2(x + 3, top + 6), Vector2(x + 7, top + 9),
		Vector2(x + 9, top), Vector2(x + 13, top + 11), Vector2(x + 18, top + 18),
		Vector2(x + 18, 130),
	])
	c.poly(pts, body)
	c.line(x + 9, top, x + 13, top + 11, edge)
	c.line(x + 3, top + 6, x + 7, top + 9, edge)
	# Exposed floor slabs and girders.
	for y in range(top + 20, 128, 5):
		c.hline(x + 1, x + 16, y, Pal.NIGHT2)
	c.line(x + 9, top, x + 4, top - 6, Pal.NIGHT2)
	c.line(x + 13, top + 4, x + 22, top - 3, Pal.NIGHT2)


# ----------------------------------------------------------------- mid layer

static func _mid(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Ruined block on the left, broken open toward the rooftop.
	var outline := PackedVector2Array([
		Vector2(0, 8), Vector2(52, 8), Vector2(56, 14), Vector2(60, 12), Vector2(66, 30),
		Vector2(72, 34), Vector2(78, 58), Vector2(86, 62), Vector2(92, 92), Vector2(98, 98),
		Vector2(100, 122), Vector2(0, 122),
	])
	c.poly(outline, Pal.CON1)
	# Floor slabs with dark rooms between.
	for fy in range(18, 120, 13):
		var right := 0
		for x in range(0, 101):
			if c.get_px(x, fy).a > 0.0:
				right = x
		c.rect(0, fy, right + 1, 2, Pal.CON3)
		c.hline(0, right, fy + 2, Pal.CON0)
		# Windows / missing walls.
		var wx := 4
		while wx < right - 6:
			var ww := rng.randi_range(5, 9)
			c.rect(wx, fy + 4, ww, 7, Pal.INK)
			# A hint of interior: a fallen beam, a shelf.
			if rng.randf() < 0.35:
				c.line(wx, fy + 10, wx + ww - 1, fy + 5 + rng.randi_range(0, 4), Pal.CON1)
			wx += ww + rng.randi_range(3, 6)
	# Rebar fingers sticking out of the broken edge.
	for i in 14:
		var yy := rng.randi_range(12, 118)
		var edge := 0
		for x in range(0, 101):
			if c.get_px(x, yy).a > 0.0:
				edge = x
		var rl := rng.randi_range(3, 9)
		c.line(edge, yy, edge + rl, yy - rng.randi_range(-3, 4), Pal.RUST2)
		c.px(edge + rl, yy, Pal.RUST3)
	# Moss and vines spilling down the face.
	for i in 22:
		var vx := rng.randi_range(0, 80)
		var vy := rng.randi_range(10, 100)
		var vl := rng.randi_range(4, 18)
		for k in vl:
			var col := Pal.MOSS2 if k < vl / 2 else Pal.MOSS1
			if c.get_px(vx, vy + k).a > 0.0:
				c.px(vx + (1 if (k / 3) % 2 == 0 else 0), vy + k, col)
	# Rain-wet sheen down the corner nearest the lamp light.
	for y in range(10, 122):
		for x in range(0, 101):
			if c.get_px(x, y).a > 0.0 and c.get_px(x + 1, y).a == 0.0:
				c.px(x, y, Pal.CON3)
				c.dpx(x - 1, y, Pal.CON2, 0.5)

	# Water tank on stilts, behind the parapet.
	var tx := 108
	var ty := 66
	for lx in [tx + 3, tx + 30]:
		c.rect(lx, ty + 24, 2, 34, Pal.RUST1)
		c.px(lx, ty + 24, Pal.RUST2)
	c.line(tx + 4, ty + 30, tx + 30, ty + 52, Pal.RUST1)
	c.line(tx + 30, ty + 30, tx + 4, ty + 52, Pal.RUST1)
	c.rect(tx, ty + 4, 35, 22, Pal.RUST1)
	c.ellipse(tx + 17, ty + 4, 17.5, 4.0, Pal.RUST2)
	c.ellipse(tx + 17, ty + 4, 15.0, 2.5, Pal.RUST1)
	for x in range(tx, tx + 35):
		var shade := float(x - tx) / 35.0
		for y in range(ty + 6, ty + 26):
			if shade < 0.25:
				c.dpx(x, y, Pal.RUST2, 0.6)
			elif shade > 0.8:
				c.dpx(x, y, Pal.RUST0, 0.7)
		# Rust streaks.
		if rng.randf() < 0.25:
			c.vline(x, ty + 8, ty + 8 + rng.randi_range(4, 16), Pal.RUST3 if shade < 0.5 else Pal.RUST2)
	c.hline(tx, tx + 34, ty + 14, Pal.RUST0)
	c.hline(tx, tx + 34, ty + 25, Pal.INK)
	return c.img


# --------------------------------------------------------------- floor layer

static func _floor(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Parapet wall at the back edge of the roof.
	var py := 118
	c.rect(0, py, W, FLOOR_TOP - py, Pal.CON2)
	c.hline(0, W, py, Pal.CON4)
	c.hline(0, W, py + 1, Pal.CON3)
	c.hline(0, W, FLOOR_TOP - 1, Pal.CON0)
	for x in range(0, W, 23):
		c.vline(x, py + 2, FLOOR_TOP - 2, Pal.CON1)
	# A collapsed gap in the parapet with a bent railing.
	for x in range(158, 188):
		var top := py + 7 - int(abs(sin(x * 0.9)) * 3.0)
		c.erase_rect(x, py, 1, top - py)
		c.px(x, top, Pal.CON3)
	c.line(160, py - 6, 172, py - 2, Pal.RUST2)
	c.line(172, py - 2, 186, py - 9, Pal.RUST2)
	for x in [160, 168, 178, 186]:
		c.vline(x, py - 8, py, Pal.RUST1)
	# Railing on the rest of the parapet.
	c.hline(0, 157, py - 8, Pal.RUST1)
	c.hline(189, W, py - 8, Pal.RUST1)
	for x in range(2, W, 9):
		if x < 157 or x > 189:
			c.vline(x, py - 8, py - 1, Pal.RUST1)
			c.px(x, py - 8, Pal.RUST2)

	# The roof slab itself: darker toward the back.
	c.vgrad(0, FLOOR_TOP, W, H - FLOOR_TOP, [Pal.CON0, Pal.CON1, Pal.CON2, Pal.CON2])
	var n := FastNoiseLite.new()
	n.seed = 5
	n.frequency = 0.09
	for y in range(FLOOR_TOP, H):
		for x in W:
			var v := n.get_noise_2d(x, y * 2.0)
			if v > 0.35:
				c.dpx(x, y, Pal.CON3, (v - 0.35) * 2.0)
			elif v < -0.45:
				c.dpx(x, y, Pal.CON1, 0.6)
	# Expansion joints (perspective lines).
	for i in 7:
		var x0 := 20 + i * 48
		c.line(x0, FLOOR_TOP, int(160 + (x0 - 160) * 1.6), H, Pal.CON1)
	c.hline(0, W, 148, Pal.CON1)
	c.hline(0, W, 165, Pal.CON1)
	# Cracks with moss.
	for i in 9:
		var x := rng.randi_range(0, W)
		var y := rng.randi_range(FLOOR_TOP + 2, H)
		for k in rng.randi_range(6, 20):
			c.px(x, y, Pal.CON0)
			if rng.randf() < 0.3:
				c.px(x, y - 1, Pal.MOSS1)
			x += rng.randi_range(-1, 1) + (1 if rng.randf() < 0.6 else 0)
			y += rng.randi_range(-1, 1)

	# Stairwell hut on the right.
	var hx := 246
	c.rect(hx, 58, W - hx, FLOOR_TOP - 58 + 2, Pal.CON2)
	c.hline(hx, W, 58, Pal.CON4)
	for y in range(60, FLOOR_TOP + 2):
		c.dpx(hx, y, Pal.CON3, 0.9)
		# Water stains running down from the roof line.
		for x in range(hx + 1, W):
			if (x * 7) % 13 == 0 and y < 60 + (x * 31) % 40:
				c.dpx(x, y, Pal.CON1, 0.6)
	# Doorway: dark inside, a faint warm spill near the floor.
	var dx := 266
	c.rect(dx, 96, 22, FLOOR_TOP - 96 + 1, Pal.INK)
	c.rect(dx - 2, 94, 26, 2, Pal.CON3)
	c.vline(dx - 1, 96, FLOOR_TOP, Pal.CON1)
	c.hline(dx + 2, dx + 19, FLOOR_TOP, Pal.RUST0)
	c.hline(dx + 6, dx + 15, FLOOR_TOP - 1, Pal.RUST0)
	# A small sign, letters long gone.
	c.rect(292, 72, 18, 9, Pal.RUST2)
	c.rect(293, 73, 16, 7, Pal.RUST1)
	c.hline(295, 306, 76, Pal.RUST3)
	# Pipes and a cable up the wall.
	c.vline(250, 60, FLOOR_TOP, Pal.CON4)
	c.vline(251, 60, FLOOR_TOP, Pal.CON1)
	for y in range(64, FLOOR_TOP, 9):
		c.px(250, y, Pal.CON5)

	# Sheltered strip under the overhang is drier: fewer bright specks.
	for y in range(FLOOR_TOP, H):
		for x in range(ROOF_X0 + 4, W):
			c.dpx(x, y, Pal.CON1, 0.35)

	# Puddles: sky reflected, a dark lip.
	for p in [Rect2(36, 155, 48, 9), Rect2(112, 166, 56, 8), Rect2(98, 143, 30, 5), Rect2(150, 150, 22, 4), Rect2(204, 150, 36, 6)]:
		var cx := int(p.position.x + p.size.x / 2)
		var cy := int(p.position.y + p.size.y / 2)
		c.ellipse(cx, cy, p.size.x / 2 + 1, p.size.y / 2 + 1, Pal.CON0)
		c.ellipse(cx, cy, p.size.x / 2, p.size.y / 2, Pal.NIGHT1)
		for yy in range(int(p.position.y), int(p.end.y)):
			for xx in range(int(p.position.x), int(p.end.x)):
				if c.get_px(xx, yy) == Pal.NIGHT1:
					var t: float = (yy - p.position.y) / p.size.y
					c.dpx(xx, yy, Pal.NIGHT2, 1.0 - t)
					# Reflected parapet line and railing.
					if yy == int(p.position.y) + 1:
						c.dpx(xx, yy, Pal.CON2, 0.7)
	# Props: boxes, a folding chair, a bucket of nothing.
	_box(c, 222, 120, 16, 12, Pal.RUST2, Pal.RUST3)
	_box(c, 228, 112, 11, 9, Pal.RUST1, Pal.RUST2)
	_chair(c, 18, 124)
	_bicycle(c, 36, 130)
	# An umbrella blown inside out, lying against the parapet.
	var umb := PixCanvas.grid([
		"......o......",
		"..oo.o.o.oo..",
		".o2o3o3o3o2o.",
		"o23433433432o",
		".ooooooooooo.",
		"......o......",
		"......o......",
		".....o.......",
	], {"o": Pal.INK, "2": Pal.NIGHT3, "3": Pal.FOG0, "4": Pal.FOG1})
	c.stamp(umb, 140, 124)
	# Weed in a cracked planter.
	c.rect(84, 124, 14, 8, Pal.CON3)
	c.hline(84, 97, 124, Pal.CON4)
	c.rect(85, 125, 12, 2, Pal.RUST0)
	for i in 9:
		var sx := 86 + i
		var sh := 3 + int(abs(sin(i * 1.7)) * 8)
		for k in sh:
			c.px(sx + (1 if k > sh / 2 and i % 2 == 0 else 0), 124 - k, Pal.MOSS2 if k < sh - 2 else Pal.MOSS3)
	return c.img


static func _box(c: PixCanvas, x: int, y: int, bw: int, bh: int, body: Color, lit: Color) -> void:
	c.rect(x, y, bw, bh, body)
	c.hline(x, x + bw - 1, y, lit)
	c.vline(x, y, y + bh - 1, lit)
	c.hline(x, x + bw - 1, y + bh - 1, Pal.INK)
	c.vline(x + bw - 1, y, y + bh - 1, Pal.RUST0)
	c.hline(x + 2, x + bw - 3, y + bh / 2, Pal.RUST0)


static func _bicycle(c: PixCanvas, x: int, y: int) -> void:
	# A rusted bicycle leaning on the parapet: two wheels, frame, bars.
	var col := Pal.RUST1
	for cx in [x, x + 16]:
		for a in 24:
			var t := TAU * a / 24.0
			c.px(cx + int(roundf(cos(t) * 5.0)), y - 5 + int(roundf(sin(t) * 5.0)), Pal.INK)
		c.px(cx, y - 5, col)
	c.line(x, y - 5, x + 7, y - 5, col)
	c.line(x + 7, y - 5, x + 12, y - 11, col)
	c.line(x + 3, y - 11, x + 12, y - 11, col)
	c.line(x + 3, y - 11, x, y - 5, col)
	c.line(x + 7, y - 5, x + 4, y - 12, col)
	c.line(x + 12, y - 11, x + 16, y - 5, col)
	c.hline(x + 2, x + 5, y - 13, Pal.INK)
	c.line(x + 12, y - 11, x + 13, y - 14, col)
	c.hline(x + 11, x + 15, y - 14, Pal.RUST2)


static func _chair(c: PixCanvas, x: int, y: int) -> void:
	var col := Pal.FOG0
	c.line(x, y + 12, x + 8, y, col)
	c.line(x + 8, y + 12, x + 2, y + 4, col)
	c.hline(x + 1, x + 9, y + 6, Pal.FOG1)
	c.hline(x + 1, x + 9, y + 7, Pal.NIGHT3)
	c.vline(x + 8, y - 8, y + 6, col)
	c.vline(x + 10, y - 8, y + 6, col)
	c.hline(x + 8, x + 10, y - 8, Pal.FOG1)


# --------------------------------------------------------------- front layer

static func _front(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Corrugated tin overhang, seen slightly from below.
	var y0 := ROOF_Y
	for x in range(ROOF_X0, W):
		var ridge := (x - ROOF_X0) % 4
		var top := y0 - 3 + (1 if ridge == 0 else 0)
		var col: Color = [Pal.RUST3, Pal.RUST2, Pal.RUST1, Pal.RUST2][ridge]
		c.vline(x, top, y0 + 3, col)
		c.px(x, y0 + 4, Pal.RUST0)
		c.px(x, top, Pal.RUST4 if ridge == 0 else col)
		# Rust holes.
		if rng.randf() < 0.05:
			c.px(x, y0 + rng.randi_range(-1, 2), Pal.INK)
	# Underside in shadow.
	c.rect(ROOF_X0 + 2, y0 + 5, W - ROOF_X0 - 2, 2, Pal.RUST0)
	c.drect(ROOF_X0 + 2, y0 + 7, W - ROOF_X0 - 2, 2, Pal.INK, 0.5)
	# Post holding it up.
	c.vline(ROOF_X0 + 6, y0 + 5, FLOOR_TOP + 22, Pal.CON3)
	c.vline(ROOF_X0 + 7, y0 + 5, FLOOR_TOP + 22, Pal.CON1)
	c.px(ROOF_X0 + 6, FLOOR_TOP + 23, Pal.CON0)
	c.px(ROOF_X0 + 7, FLOOR_TOP + 23, Pal.CON0)
	# Lantern on a wire.
	c.vline(LAMP.x, y0 + 5, LAMP.y - 5, Pal.INK)
	var lx := LAMP.x - 3
	var ly := LAMP.y - 5
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
	c.stamp(lantern, lx, ly)

	# Sagging cable across the top, a few hanging drops caught on it.
	for x in W:
		var t := x / float(W)
		var y := int(6 + 18 * 4.0 * t * (1.0 - t))
		c.px(x, y, Pal.INK)
	# Foreground rubble in the corners frames the scene.
	var rubble := PackedVector2Array([
		Vector2(0, 172), Vector2(10, 168), Vector2(18, 171), Vector2(26, 176), Vector2(30, 180), Vector2(0, 180),
	])
	c.poly(rubble, Pal.INK)
	c.line(4, 170, 12, 168, Pal.CON1)
	return c.img

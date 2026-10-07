class_name RoofArt
## Area 1: a ruined rooftop in the rain, painted at full resolution
## (640x360). Returns the layered backdrop and the gameplay geometry.

const W := 640
const H := 360

const LAMP := Vector2i(444, 214)
const FLOOR_TOP := 262
const PARAPET_Y := 236
const ROOF_Y := 180 # underside of the corrugated overhang
const ROOF_X0 := 388
const HUT_X := 492

const PUDDLES := [Rect2(64, 308, 104, 18), Rect2(222, 330, 118, 16), Rect2(190, 286, 62, 10), Rect2(300, 298, 46, 8)]


static func build() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261007
	return {
		"name": "崩れた屋上",
		"res": 2,
		"layers": {"sky": _sky(rng), "mid": _mid(rng), "floor": _floor(rng), "front": _front(rng)},
		# Drums sit with their base inside this band.
		"floor": Rect2(12, 276, 616, 76),
		# Rain stops on these. Anything below is sheltered.
		"shelters": [Rect2(ROOF_X0, 0, W - ROOF_X0, ROOF_Y + 12)],
		# Drip points along the overhang lip; more open with the 雨樋 upgrade.
		"drips": [Vector2(406, 194), Vector2(462, 194), Vector2(428, 194), Vector2(494, 194), Vector2(394, 194), Vector2(524, 194), Vector2(448, 194)],
		"drip_depth": 304.0,
		"lamp": Vector2(LAMP),
		"lamp_color": Pal.LAMP2,
		"puddles": PUDDLES,
		"smoke": [Vector2(332, 150)],
		"floor_y": FLOOR_TOP,
		"blinks": [[Vector2(318, 73), Color("d0482e"), 2.6, 0.22], [Vector2(112, 9), Color("d0482e"), 3.4, 0.18]],
		"trickles": [[Vector2(ROOF_X0 + 2, ROOF_Y + 10), 292.0]],
		"weeds": [[Vector2(28, 354), 10], [Vector2(604, 346), 8], [Vector2(274, 266), 12], [Vector2(124, 264), 8], [Vector2(380, 268), 6], [Vector2(560, 270), 9]],
		"perches": [Vector2(253, 121), Vector2(600, 115), Vector2(80, 221), Vector2(236, 221), Vector2(424, 221)],
		"ambient": Color(0.6, 0.66, 0.84),
		"reverb_room": 0.78,
	}


# ------------------------------------------------------------------ far layer

static func _sky(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H, Pal.NIGHT0)
	c.vgrad(0, 0, W, 230, [Pal.INK, Pal.NIGHT0, Pal.NIGHT1, Pal.NIGHT2, Pal.NIGHT3, Pal.FOG0])
	c.rect(0, 230, W, H - 230, Pal.FOG0)

	# Cloud ceiling: soft rolls with lit undersides and darker crowns.
	var n := FastNoiseLite.new()
	n.seed = 11
	n.frequency = 0.008
	n.fractal_octaves = 4
	for y in 170:
		var fade := 1.0 - y / 220.0
		for x in W:
			var v := (n.get_noise_2d(x, y * 2.4) * 0.5 + 0.5) * fade
			var below := (n.get_noise_2d(x, (y + 3) * 2.4) * 0.5 + 0.5) * fade
			if v > 0.44:
				c.dpx(x, y, Pal.NIGHT2, (v - 0.44) * 7.0)
			if v > 0.56:
				c.dpx(x, y, Pal.NIGHT3, (v - 0.56) * 6.0)
			# A lighter rim where a cloud ends above clear-ish sky.
			if v > 0.5 and below < 0.47:
				c.px(x, y, Pal.FOG0)
	# Distant rain curtains: slanted faint streak bands.
	for band in 4:
		var bx := rng.randi_range(0, W)
		for k in 260:
			var sx := bx + rng.randi_range(-40, 40)
			var sy := rng.randi_range(60, 230)
			if rng.randf() < 0.6:
				c.line(sx, sy, sx - 2, sy + 6, Pal.NIGHT3)

	# Farthest skyline, mostly haze.
	_skyline(c, rng, 150, 196, 10, 32, Pal.NIGHT3, Pal.FOG0, false)
	for y in range(180, 250):
		c.drect(0, y, W, 1, Pal.FOG0, (y - 180) / 110.0)
	_tower(c, 300, 74)
	# Nearer skyline with window grids, water tanks, antennas.
	_skyline(c, rng, 168, 214, 18, 54, Pal.NIGHT2, Pal.NIGHT3, true)
	for y in range(204, 250):
		c.drect(0, y, W, 1, Pal.FOG0, (y - 204) / 70.0)
	return c.img


static func _skyline(c: PixCanvas, rng: RandomNumberGenerator, top_min: int, top_max: int,
		wmin: int, wmax: int, body: Color, edge: Color, detail: bool) -> void:
	var x := -rng.randi_range(0, 16)
	while x < W:
		var bw := rng.randi_range(wmin, wmax)
		var top := rng.randi_range(top_min, top_max)
		var broken := rng.randf() < 0.4
		var phase := rng.randf() * 10.0
		var depth := rng.randi_range(4, 12)
		for i in bw:
			var bite := int(absf(sin((x + i) * 0.35 + phase)) * depth) if broken else 0
			c.vline(x + i, top + bite, 260, body)
			c.px(x + i, top + bite, edge)
		if detail:
			# Window grid: 2x2 dark panes with the odd faint one.
			var wy := top + 6
			while wy < 248:
				var wx := x + 3
				while wx < x + bw - 3:
					var r := rng.randf()
					if r < 0.55:
						c.rect(wx, wy, 2, 2, Pal.NIGHT1)
					elif r < 0.57:
						c.rect(wx, wy, 2, 2, Pal.FOG0)
					wx += 4
				wy += 6
			# Rooftop clutter on intact buildings.
			if not broken:
				if rng.randf() < 0.35:
					var tx := x + rng.randi_range(2, maxi(3, bw - 12))
					c.rect(tx, top - 8, 9, 6, body)
					c.hline(tx, tx + 8, top - 8, edge)
					c.vline(tx + 1, top - 2, top, body)
					c.vline(tx + 7, top - 2, top, body)
				if rng.randf() < 0.4:
					var ax := x + rng.randi_range(2, maxi(3, bw - 3))
					var ah := rng.randi_range(8, 22)
					c.vline(ax, top - ah, top, body)
					c.hline(ax - 2, ax + 2, top - ah + 3, body)
		x += bw + rng.randi_range(-3, 6)


static func _tower(c: PixCanvas, x: int, top: int) -> void:
	# A collapsed high-rise: the landmark on the horizon.
	var body := Pal.NIGHT3
	var pts := PackedVector2Array([
		Vector2(x, 260), Vector2(x, top + 28), Vector2(x + 6, top + 12), Vector2(x + 14, top + 18),
		Vector2(x + 18, top), Vector2(x + 26, top + 22), Vector2(x + 36, top + 36), Vector2(x + 36, 260),
	])
	c.poly(pts, body)
	c.line(x + 18, top, x + 26, top + 22, Pal.FOG0)
	c.line(x + 6, top + 12, x + 14, top + 18, Pal.FOG0)
	c.line(x + 26, top + 22, x + 36, top + 36, Pal.FOG0)
	# Exposed floors with window bays.
	for y in range(top + 40, 256, 8):
		c.hline(x + 1, x + 34, y, Pal.NIGHT2)
		for wx in range(x + 3, x + 33, 5):
			c.rect(wx, y + 2, 3, 4, Pal.NIGHT1)
	# Bent girders against the sky.
	c.line(x + 18, top, x + 8, top - 12, Pal.NIGHT2)
	c.line(x + 26, top + 8, x + 44, top - 6, Pal.NIGHT2)
	c.line(x + 44, top - 6, x + 46, top + 2, Pal.NIGHT2)
	c.vline(x + 18, top - 4, top, Pal.NIGHT2)


# ------------------------------------------------------------------ mid layer

static func _mid(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	_ruin(c, rng)
	_water_tank(c, rng, 216, 116)
	return c.img


static func _ruin(c: PixCanvas, rng: RandomNumberGenerator) -> void:
	# A block of flats broken open toward the rooftop.
	var outline := PackedVector2Array([
		Vector2(0, 16), Vector2(104, 16), Vector2(112, 28), Vector2(120, 24), Vector2(132, 60),
		Vector2(144, 68), Vector2(156, 116), Vector2(172, 124), Vector2(184, 184), Vector2(196, 196),
		Vector2(200, 244), Vector2(0, 244),
	])
	c.poly(outline, Pal.CON1)
	# Facade texture: stained concrete.
	for y in range(16, 244):
		for x in range(0, 201):
			if c.get_px(x, y) == Pal.CON1:
				var v := sin(x * 0.9 + y * 0.13) * 0.5 + sin(x * 0.17) * 0.5
				if v > 0.75:
					c.dpx(x, y, Pal.CON2, 0.5)
	# Rain stains running down from every slab edge.
	for i in 60:
		var sx := rng.randi_range(0, 196)
		var sy := rng.randi_range(18, 230)
		var ln := rng.randi_range(6, 30)
		for k in ln:
			if c.get_px(sx, sy + k) == Pal.CON1 or c.get_px(sx, sy + k) == Pal.CON2:
				c.dpx(sx, sy + k, Pal.CON0, 0.8 - float(k) / ln * 0.6)
	# Floors: slab, its lit lip, and window bays with frames and interiors.
	for fy in range(28, 240, 26):
		var right := 0
		for x in range(0, 201):
			if c.get_px(x, fy).a > 0.0:
				right = x
		c.rect(0, fy, right + 1, 4, Pal.CON3)
		c.hline(0, right, fy, Pal.CON4)
		c.hline(0, right, fy + 4, Pal.INK)
		var wx := 6
		while wx < right - 14:
			var ww := rng.randi_range(12, 18)
			var wh := 16
			c.rect(wx, fy + 7, ww, wh, Pal.INK)
			var kind := rng.randf()
			if kind < 0.45:
				# Window frame with a mullion and some panes left.
				c.hline(wx, wx + ww - 1, fy + 7, Pal.CON2)
				c.vline(wx + ww / 2, fy + 7, fy + 7 + wh - 1, Pal.CON2)
				if rng.randf() < 0.5:
					c.rect(wx + 1, fy + 8, ww / 2 - 1, wh / 2, Pal.NIGHT1)
					c.px(wx + 2, fy + 9, Pal.NIGHT3)
			elif kind < 0.7:
				# A room seen through: a fallen beam and a dark doorway.
				c.line(wx, fy + 7 + wh - 2, wx + ww - 1, fy + 10, Pal.CON1)
				c.rect(wx + ww - 6, fy + 12, 4, wh - 5, Pal.NIGHT0)
			else:
				# Curtain remnant hanging in the gap.
				c.rect(wx + 1, fy + 8, 4, wh - 6, Pal.CLOTH0)
				c.vline(wx + 2, fy + 8, fy + 8 + wh - 8, Pal.CLOTH1)
			# Sill.
			c.hline(wx - 1, wx + ww, fy + 7 + wh, Pal.CON3)
			wx += ww + rng.randi_range(6, 12)
		# Balcony rails on some floors.
		if rng.randf() < 0.5:
			var bx := rng.randi_range(4, maxi(5, right - 50))
			c.hline(bx, bx + 40, fy - 8, Pal.RUST1)
			for k in range(bx, bx + 41, 4):
				c.vline(k, fy - 8, fy - 1, Pal.RUST1)
	# Air conditioner boxes clinging to the facade.
	for i in 5:
		var ax := rng.randi_range(6, 150)
		var ay := rng.randi_range(40, 220)
		if c.get_px(ax, ay).a == 0.0 or c.get_px(ax + 14, ay).a == 0.0:
			continue
		c.rect(ax, ay, 14, 9, Pal.CON3)
		c.hline(ax, ax + 13, ay, Pal.CON5)
		c.circle(ax + 9, ay + 4, 3.0, Pal.CON1)
		c.px(ax + 9, ay + 4, Pal.CON4)
		for k in 3:
			c.hline(ax + 1, ax + 4, ay + 2 + k * 2, Pal.CON2)
	# Rebar fingers sticking out of the broken edge.
	for i in 30:
		var yy := rng.randi_range(24, 236)
		var edge := 0
		for x in range(0, 201):
			if c.get_px(x, yy).a > 0.0:
				edge = x
		var rl := rng.randi_range(6, 18)
		var ey := yy - rng.randi_range(-6, 8)
		c.line(edge, yy, edge + rl, ey, Pal.RUST2)
		c.px(edge + rl, ey, Pal.RUST3)
	# Vines with leaves spilling down the face.
	for i in 26:
		var vx := rng.randi_range(0, 160)
		var vy := rng.randi_range(20, 200)
		var vl := rng.randi_range(10, 46)
		for k in vl:
			var px := vx + int(sin(k * 0.3 + i) * 2.0)
			if c.get_px(px, vy + k).a == 0.0:
				break
			c.px(px, vy + k, Pal.MOSS1)
			if k % 4 == 0:
				var side := 1 if (k / 4) % 2 == 0 else -1
				c.px(px + side, vy + k, Pal.MOSS2)
				c.px(px + side * 2, vy + k + 1, Pal.MOSS3 if k < vl / 2 else Pal.MOSS2)
	# Rain-wet sheen down the broken corner nearest the lamp light.
	for y in range(18, 244):
		for x in range(0, 201):
			if c.get_px(x, y).a > 0.0 and c.get_px(x + 1, y).a == 0.0:
				c.px(x, y, Pal.CON4)
				c.dpx(x - 1, y, Pal.CON3, 0.6)
				c.dpx(x - 2, y, Pal.CON2, 0.4)
	# Roof edge silhouette details: a tilted antenna and a cut cable.
	c.line(60, 16, 54, 0, Pal.CON1)
	c.line(54, 4, 64, 2, Pal.CON1)
	c.vline(112, 6, 16, Pal.CON1)
	c.hline(108, 116, 10, Pal.CON1)


static func _water_tank(c: PixCanvas, rng: RandomNumberGenerator, tx: int, ty: int) -> void:
	# Wooden water tank on a steel stand, behind the parapet.
	var tw := 74
	var body_top := ty + 14
	var body_h := 46
	# Legs and bracing first (behind the tank).
	for lx in [tx + 6, tx + 34, tx + 62]:
		c.rect(lx, body_top + body_h, 4, 236 - body_top - body_h, Pal.RUST1)
		c.vline(lx, body_top + body_h, 235, Pal.RUST2)
		for ry in range(body_top + body_h + 6, 236, 12):
			c.px(lx + 1, ry, Pal.RUST3)
	for b in 3:
		var y0 := body_top + body_h + 4 + b * 20
		c.line(tx + 8, y0, tx + 36, y0 + 18, Pal.RUST1)
		c.line(tx + 36, y0, tx + 64, y0 + 18, Pal.RUST1)
		c.line(tx + 64, y0, tx + 36, y0 + 18, Pal.RUST0)
		c.line(tx + 36, y0, tx + 8, y0 + 18, Pal.RUST0)
	c.hline(tx + 4, tx + tw - 4, body_top + body_h + 2, Pal.RUST2)
	# Staves: vertical planks shaded as a cylinder.
	for x in range(tw):
		var u := float(x) / (tw - 1)
		var shade := 0.5 - 0.5 * cos(u * PI) # 0 left .. 1 right
		var col := Pal.WOOD3 if shade < 0.2 else (Pal.WOOD2 if shade < 0.55 else (Pal.WOOD1 if shade < 0.85 else Pal.WOOD0))
		c.vline(tx + x, body_top, body_top + body_h, col)
		if x % 6 == 0:
			c.vline(tx + x, body_top, body_top + body_h, Pal.WOOD0)
		# Grain and rot.
		if rng.randf() < 0.3:
			var gy := body_top + rng.randi_range(2, body_h - 4)
			c.vline(tx + x, gy, gy + rng.randi_range(2, 8), Pal.WOOD1 if shade < 0.5 else Pal.WOOD0)
	# Steel hoops with rivets.
	for hy in [body_top + 8, body_top + 24, body_top + 40]:
		c.hline(tx, tx + tw - 1, hy, Pal.CON3)
		c.hline(tx, tx + tw - 1, hy + 1, Pal.RUST1)
		for x in range(tx + 3, tx + tw - 2, 9):
			c.px(x, hy, Pal.CON5)
	# Conical roof with a hatch and a finial.
	var roof := PackedVector2Array([
		Vector2(tx - 3, body_top + 1), Vector2(tx + tw / 2, ty - 2), Vector2(tx + tw + 3, body_top + 1),
	])
	c.poly(roof, Pal.WOOD1)
	for k in range(0, tw + 6, 5):
		c.line(tx - 3 + k, body_top, tx + tw / 2, ty - 1, Pal.WOOD0)
	c.line(tx - 3, body_top + 1, tx + tw / 2, ty - 2, Pal.WOOD2)
	c.hline(tx - 3, tx + tw + 3, body_top + 1, Pal.WOOD0)
	c.vline(tx + tw / 2, ty - 8, ty - 2, Pal.CON3)
	c.px(tx + tw / 2, ty - 9, Pal.CON5)
	c.rect(tx + 20, body_top - 8, 8, 5, Pal.WOOD2)
	c.hline(tx + 20, tx + 27, body_top - 8, Pal.WOOD3)
	# Moss on the roof and leaks streaking the staves.
	for i in 40:
		var mx := tx + rng.randi_range(0, tw)
		var my := body_top - rng.randi_range(0, 6)
		if c.get_px(mx, my) != Color(0, 0, 0, 0):
			c.px(mx, my, Pal.MOSS2 if rng.randf() < 0.5 else Pal.MOSS1)
	for i in 8:
		var lx := tx + rng.randi_range(4, tw - 4)
		c.vline(lx, body_top + rng.randi_range(10, 30), body_top + body_h, Pal.MOSS0)
	# Ladder up the side.
	c.vline(tx + tw + 4, body_top - 2, 236, Pal.RUST1)
	c.vline(tx + tw + 9, body_top - 2, 236, Pal.RUST1)
	for ry in range(body_top, 236, 6):
		c.hline(tx + tw + 4, tx + tw + 9, ry, Pal.RUST2)


# ---------------------------------------------------------------- floor layer

static func _floor(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	_parapet(c, rng)
	_slab(c, rng)
	_hut(c, rng)
	_puddles(c, rng)
	_props(c, rng)
	return c.img


static func _parapet(c: PixCanvas, rng: RandomNumberGenerator) -> void:
	var py := PARAPET_Y
	# Concrete blocks with chipped edges and stains.
	c.rect(0, py, W, FLOOR_TOP - py, Pal.CON2)
	c.noise_rect(0, py + 3, W, FLOOR_TOP - py - 4, [Pal.CON1, Pal.CON2, Pal.CON2, Pal.CON3], 41, 0.12, 2.0)
	c.hline(0, W, py, Pal.CON5)
	c.hline(0, W, py + 1, Pal.CON4)
	c.hline(0, W, py + 2, Pal.CON3)
	c.hline(0, W, FLOOR_TOP - 1, Pal.CON0)
	for x in range(0, W, 46):
		c.vline(x, py + 3, FLOOR_TOP - 2, Pal.CON0)
		c.vline(x + 1, py + 3, FLOOR_TOP - 2, Pal.CON3)
	for i in 40:
		var sx := rng.randi_range(0, W)
		c.vline(sx, py + 3, py + 3 + rng.randi_range(3, 18), Pal.CON1)
	# Chips knocked out of the cap.
	for i in 18:
		var cx := rng.randi_range(0, W)
		var cw := rng.randi_range(2, 6)
		c.rect(cx, py, cw, 2, Pal.CON1)
		c.hline(cx, cx + cw - 1, py + 2, Pal.CON0)
	# A collapsed gap with a bent railing.
	for x in range(316, 376):
		var top := py + 14 - int(absf(sin(x * 0.45)) * 6.0)
		c.erase_rect(x, py, 1, top - py)
		c.px(x, top, Pal.CON4)
		c.px(x, top + 1, Pal.CON3)
	c.line(320, py - 12, 344, py - 4, Pal.RUST2)
	c.line(344, py - 4, 372, py - 18, Pal.RUST2)
	c.line(320, py - 11, 344, py - 3, Pal.RUST1)
	for x in [320, 336, 356, 372]:
		c.vline(x, py - 16, py, Pal.RUST1)
	# Railing: top rail, mid rail and posts with bolts and rust drips.
	for seg in [[0, 314], [378, W]]:
		var x0: int = seg[0]
		var x1: int = seg[1]
		c.hline(x0, x1, py - 16, Pal.RUST2)
		c.hline(x0, x1, py - 15, Pal.RUST1)
		c.hline(x0, x1, py - 8, Pal.RUST1)
		for x in range(x0 + 4, x1, 18):
			c.vline(x, py - 16, py - 1, Pal.RUST1)
			c.vline(x + 1, py - 16, py - 1, Pal.RUST0)
			c.px(x, py - 16, Pal.RUST3)
			c.px(x, py - 3, Pal.CON5)
			if rng.randf() < 0.5:
				c.vline(x, py + 3, py + 3 + rng.randi_range(4, 12), Pal.RUST1)


static func _slab(c: PixCanvas, rng: RandomNumberGenerator) -> void:
	# The roof slab: darker toward the back, rain-dark everywhere.
	c.vgrad(0, FLOOR_TOP, W, H - FLOOR_TOP, [Pal.CON0, Pal.CON1, Pal.CON1, Pal.CON2, Pal.CON2])
	var n := FastNoiseLite.new()
	n.seed = 5
	n.frequency = 0.045
	n.fractal_octaves = 3
	for y in range(FLOOR_TOP, H):
		for x in W:
			var v := n.get_noise_2d(x, y * 2.2)
			if v > 0.3:
				c.dpx(x, y, Pal.CON3, (v - 0.3) * 1.6)
			elif v < -0.35:
				c.dpx(x, y, Pal.WET, 0.7)
	# Tiles in perspective: joints converge toward a point above the horizon.
	var vp := Vector2(320, 120)
	for i in range(-12, 13):
		var x_far := 320 + i * 40
		var t := (float(H) - vp.y) / (FLOOR_TOP - vp.y)
		var x_near := int(vp.x + (x_far - vp.x) * t)
		c.line(x_far, FLOOR_TOP, x_near, H, Pal.CON0)
	var rows := [270, 282, 298, 318, 344]
	for ry in rows:
		c.hline(0, W, ry, Pal.CON0)
		c.hline(0, W, ry + 1, Pal.CON3 if ry > 290 else Pal.CON1)
	# Cracks: branching random walks with moss in the widest ones.
	for i in 16:
		var x := rng.randi_range(0, W)
		var y := rng.randi_range(FLOOR_TOP + 4, H)
		var dir := 1 if rng.randf() < 0.5 else -1
		for k in rng.randi_range(14, 50):
			c.px(x, y, Pal.CON0)
			if rng.randf() < 0.25:
				c.px(x, y - 1, Pal.MOSS1)
			if rng.randf() < 0.08:
				var bx := x
				var by := y
				for j in 6:
					bx += dir
					by += rng.randi_range(-1, 1)
					c.px(bx, by, Pal.CON0)
			x += dir if rng.randf() < 0.7 else 0
			y += rng.randi_range(-1, 1)
	# Grit and pebbles, a few leaves.
	for i in 220:
		var gx := rng.randi_range(0, W)
		var gy := rng.randi_range(FLOOR_TOP + 2, H)
		c.px(gx, gy, Pal.CON4 if rng.randf() < 0.6 else Pal.CON0)
	for i in 18:
		var lx := rng.randi_range(0, W)
		var ly := rng.randi_range(FLOOR_TOP + 4, H)
		c.px(lx, ly, Pal.RUST2)
		c.px(lx + 1, ly, Pal.RUST3)
		c.px(lx + 1, ly + 1, Pal.RUST1)
	# Floor drain.
	c.rect(150, 292, 14, 8, Pal.CON0)
	for k in 4:
		c.vline(152 + k * 3, 293, 298, Pal.CON3)
	# The sheltered strip under the overhang is drier.
	for y in range(FLOOR_TOP, H):
		for x in range(ROOF_X0 + 8, W):
			if c.get_px(x, y) == Pal.WET:
				c.px(x, y, Pal.CON1)


static func _hut(c: PixCanvas, rng: RandomNumberGenerator) -> void:
	# Stairwell hut: panelled concrete with a steel door left ajar.
	var hx := HUT_X
	var top := 116
	c.rect(hx, top, W - hx, FLOOR_TOP - top + 4, Pal.CON2)
	c.noise_rect(hx, top + 4, W - hx, FLOOR_TOP - top, [Pal.CON1, Pal.CON2, Pal.CON2, Pal.CON3], 77, 0.05, 1.5)
	c.hline(hx, W, top, Pal.CON5)
	c.hline(hx, W, top + 1, Pal.CON4)
	c.rect(hx, top + 2, W - hx, 3, Pal.CON1)
	c.vline(hx, top, FLOOR_TOP + 3, Pal.CON4)
	c.vline(hx + 1, top, FLOOR_TOP + 3, Pal.CON3)
	# Panel joints and long water stains from the roof line.
	for x in range(hx + 30, W, 36):
		c.vline(x, top + 5, FLOOR_TOP + 3, Pal.CON1)
	for i in 30:
		var sx := rng.randi_range(hx + 2, W)
		var ln := rng.randi_range(10, 80)
		for k in ln:
			c.dpx(sx, top + 5 + k, Pal.CON1, 0.9 - float(k) / ln)
	# Door frame and the door, opened a crack onto darkness.
	var dx := 532
	var dt := 188
	c.rect(dx - 4, dt - 4, 52, FLOOR_TOP - dt + 6, Pal.CON3)
	c.hline(dx - 4, dx + 47, dt - 4, Pal.CON5)
	c.rect(dx, dt, 44, FLOOR_TOP - dt + 2, Pal.INK)
	c.rect(dx, dt, 34, FLOOR_TOP - dt + 2, Pal.RUST1)
	c.vline(dx + 33, dt, FLOOR_TOP + 1, Pal.RUST0)
	c.vline(dx, dt, FLOOR_TOP + 1, Pal.RUST2)
	for py in [dt + 10, dt + 40]:
		c.rect(dx + 4, py, 26, 20, Pal.RUST2)
		c.hline(dx + 4, dx + 29, py, Pal.RUST3)
		c.hline(dx + 4, dx + 29, py + 19, Pal.RUST0)
	c.rect(dx + 28, dt + 34, 3, 6, Pal.CON5)
	for i in 30:
		c.px(dx + rng.randi_range(1, 32), dt + rng.randi_range(1, 70), Pal.RUST3 if rng.randf() < 0.5 else Pal.RUST0)
	# A sliver of warm light from inside, at the threshold.
	c.vline(dx + 35, dt + 30, FLOOR_TOP, Pal.LAMP4)
	c.hline(dx + 34, dx + 43, FLOOR_TOP + 1, Pal.LAMP4)
	# Sign with peeling letters.
	c.rect(580, 140, 40, 20, Pal.RUST2)
	c.rect(582, 142, 36, 16, Pal.RUST1)
	c.hline(580, 619, 140, Pal.RUST3)
	for k in 5:
		c.rect(586 + k * 6, 146, 4, 8, Pal.RUST3 if k != 2 else Pal.RUST2)
	c.px(590, 150, Pal.RUST1)
	# Electric meter box with a dangling cable, conduit up the wall.
	c.rect(508, 150, 16, 22, Pal.CON3)
	c.hline(508, 523, 150, Pal.CON5)
	c.rect(511, 154, 10, 7, Pal.NIGHT1)
	c.circle(516, 157, 2.0, Pal.FOG0)
	c.px(516, 157, Pal.RUST3)
	for y in range(118, 150):
		c.px(512, y, Pal.CON4)
		c.px(513, y, Pal.CON1)
	for y in range(172, 214):
		c.px(516 + int(sin(y * 0.15) * 2.0), y, Pal.INK)
	# Outdoor AC unit on brackets.
	c.rect(584, 214, 40, 28, Pal.CON4)
	c.hline(584, 623, 214, Pal.CON6)
	c.vline(623, 214, 241, Pal.CON2)
	c.circle(598, 227, 10.0, Pal.CON2)
	c.ring(598, 227, 10.0, 10.0, Pal.CON1)
	for a in 4:
		var t := a * PI / 2.0 + 0.4
		c.line(598, 227, 598 + int(cos(t) * 8.0), 227 + int(sin(t) * 8.0), Pal.CON3)
	for k in 6:
		c.hline(612, 620, 218 + k * 4, Pal.CON2)
	c.rect(586, 242, 4, 20, Pal.RUST1)
	c.rect(618, 242, 4, 20, Pal.RUST1)
	# Pipes up the wall, with clamps.
	c.vline(498, 120, FLOOR_TOP, Pal.CON5)
	c.vline(499, 120, FLOOR_TOP, Pal.CON3)
	c.vline(500, 120, FLOOR_TOP, Pal.CON1)
	for y in range(126, FLOOR_TOP, 18):
		c.rect(497, y, 5, 2, Pal.RUST2)


static func _puddles(c: PixCanvas, rng: RandomNumberGenerator) -> void:
	for p in PUDDLES:
		var r: Rect2 = p
		var cx := int(r.position.x + r.size.x / 2)
		var cy := int(r.position.y + r.size.y / 2)
		# Ragged outline: two overlapping ellipses.
		c.ellipse(cx, cy, r.size.x / 2 + 2, r.size.y / 2 + 1, Pal.CON0)
		c.ellipse(cx - int(r.size.x * 0.15), cy + 1, r.size.x * 0.35, r.size.y * 0.45, Pal.CON0)
		c.ellipse(cx, cy, r.size.x / 2, r.size.y / 2, Pal.NIGHT1)
		c.ellipse(cx - int(r.size.x * 0.15), cy + 1, r.size.x * 0.33, r.size.y * 0.4, Pal.NIGHT1)
		# Sky reflected: lighter toward the far edge, plus the railing line.
		for yy in range(int(r.position.y) - 1, int(r.end.y) + 2):
			for xx in range(int(r.position.x) - 2, int(r.end.x) + 2):
				if c.get_px(xx, yy) != Pal.NIGHT1:
					continue
				var t := clampf((yy - r.position.y) / r.size.y, 0.0, 1.0)
				c.dpx(xx, yy, Pal.NIGHT2, 1.0 - t)
				c.dpx(xx, yy, Pal.NIGHT3, 0.45 - t)
				if yy == int(r.position.y) + 2 and xx % 18 != 0:
					c.px(xx, yy, Pal.RUST0)
				if yy == int(r.position.y) + 3 and xx % 18 == 4:
					c.px(xx, yy + 1, Pal.RUST0)


static func _props(c: PixCanvas, rng: RandomNumberGenerator) -> void:
	# Cardboard boxes under the overhang, taped and sagging from the damp.
	_box(c, 446, 240, 32, 24, Pal.RUST2, Pal.RUST3)
	_box(c, 456, 222, 22, 18, Pal.RUST1, Pal.RUST2)
	_box(c, 478, 248, 14, 16, Pal.WOOD2, Pal.WOOD3)
	_chair(c, 34, 248)
	_bicycle(c, 72, 260)
	_umbrella(c, 280, 248)
	_planter(c, 168, 248)
	_tyres(c, 600, 262)
	# A clothesline strung from the railing to the hut, a towel left on it.
	for x in range(186, HUT_X):
		var t := float(x - 186) / (HUT_X - 186)
		var y := int(202 + 22 * 4.0 * t * (1.0 - t))
		c.px(x, y, Pal.CON3)
	_cloth(c, 262, 220, 16, 22, Pal.CLOTH1, Pal.CLOTH2, Pal.CLOTH0)
	_cloth(c, 300, 222, 12, 14, Pal.FOG1, Pal.FOG2, Pal.FOG0)
	for x in [262, 277, 300, 311]:
		c.rect(x, 218 + (2 if x > 290 else 0), 2, 3, Pal.WOOD3)


static func _box(c: PixCanvas, x: int, y: int, bw: int, bh: int, body: Color, lit: Color) -> void:
	c.rect(x, y, bw, bh, body)
	c.hline(x, x + bw - 1, y, lit)
	c.hline(x, x + bw - 1, y + 1, lit)
	c.vline(x, y, y + bh - 1, lit)
	c.hline(x, x + bw - 1, y + bh - 1, Pal.INK)
	c.vline(x + bw - 1, y, y + bh - 1, Pal.RUST0)
	# Tape across the flaps and a sagging dent.
	c.rect(x + bw / 2 - 2, y, 4, bh - 1, Pal.BONE.darkened(0.45))
	c.hline(x + 2, x + bw - 3, y + bh / 2, Pal.RUST0)
	c.line(x + 3, y + bh - 3, x + bw / 3, y + bh / 2 + 2, Pal.RUST0)


static func _chair(c: PixCanvas, x: int, y: int) -> void:
	# A folding chair, metal tube frame and a slatted seat.
	var col := Pal.FOG0
	c.line(x, y + 24, x + 16, y, col)
	c.line(x + 1, y + 24, x + 17, y, Pal.NIGHT3)
	c.line(x + 16, y + 24, x + 4, y + 8, col)
	c.rect(x + 2, y + 12, 18, 2, Pal.FOG1)
	c.hline(x + 2, x + 19, y + 14, Pal.NIGHT3)
	for k in 4:
		c.px(x + 4 + k * 4, y + 12, Pal.FOG2)
	c.vline(x + 16, y - 16, y + 12, col)
	c.vline(x + 20, y - 16, y + 12, col)
	c.rect(x + 16, y - 16, 5, 8, Pal.FOG1)
	c.hline(x + 16, x + 20, y - 16, Pal.FOG2)


static func _bicycle(c: PixCanvas, x: int, y: int) -> void:
	# A rusted bicycle leaning on the parapet: spoked wheels, frame, bars.
	for cx in [x, x + 32]:
		c.ring(cx, y - 10, 10.0, 10.0, Pal.INK)
		c.ring(cx, y - 10, 9.0, 9.0, Pal.CON1)
		for a in 8:
			var t := a * PI / 4.0
			c.line(cx, y - 10, cx + int(cos(t) * 8.0), y - 10 + int(sin(t) * 8.0), Pal.CON2)
		c.px(cx, y - 10, Pal.CON4)
	var col := Pal.RUST2
	c.line(x, y - 10, x + 14, y - 10, col)
	c.line(x + 14, y - 10, x + 24, y - 22, col)
	c.line(x + 6, y - 22, x + 24, y - 22, col)
	c.line(x + 6, y - 22, x, y - 10, col)
	c.line(x + 14, y - 10, x + 8, y - 24, col)
	c.line(x + 24, y - 22, x + 32, y - 10, col)
	c.line(x + 1, y - 10, x + 15, y - 9, Pal.RUST1)
	c.rect(x + 4, y - 27, 8, 2, Pal.INK)
	c.line(x + 24, y - 22, x + 26, y - 28, col)
	c.hline(x + 22, x + 30, y - 28, Pal.RUST3)
	c.circle(x + 14, y - 10, 2.0, Pal.CON3)


static func _umbrella(c: PixCanvas, x: int, y: int) -> void:
	# An umbrella blown inside out, lying against the parapet.
	var g := PixCanvas.grid([
		"............o............",
		"....oo......o......oo....",
		"...o22o....o3o....o22o...",
		"..o2333o..o343o..o3332o..",
		".o233443oo34443oo344332o.",
		"o23344443344444334444332o",
		".ooooooooooooooooooooooo.",
		"............o............",
		"............o............",
		"............o............",
		"...........o.............",
		"..........o..............",
		"..........oo.............",
	], {"o": Pal.INK, "2": Pal.NIGHT3, "3": Pal.FOG0, "4": Pal.FOG1})
	c.stamp(g, x, y)


static func _planter(c: PixCanvas, x: int, y: int) -> void:
	# A cracked concrete planter with a weed gone wild.
	c.rect(x, y, 30, 16, Pal.CON3)
	c.hline(x, x + 29, y, Pal.CON5)
	c.hline(x, x + 29, y + 1, Pal.CON4)
	c.vline(x + 29, y, y + 15, Pal.CON1)
	c.rect(x + 2, y + 2, 26, 4, Pal.WOOD0)
	c.line(x + 18, y + 2, x + 22, y + 15, Pal.CON1)
	for i in 14:
		var sx := x + 4 + i * 2 - (i % 3)
		var sh := 6 + int(absf(sin(i * 1.7)) * 16.0)
		for k in sh:
			var lean := int(float(k) / sh * (2.0 if i % 2 == 0 else -2.0))
			c.px(sx + lean, y + 2 - k, Pal.MOSS2 if k < sh - 4 else Pal.MOSS3)
		if i % 3 == 0:
			c.px(sx - 1, y - sh / 2, Pal.MOSS3)


static func _tyres(c: PixCanvas, x: int, y: int) -> void:
	# A stack of old tyres in the corner.
	for k in 3:
		var ty := y - 8 - k * 9
		c.ellipse(x, ty, 18.0, 6.0, Pal.INK)
		c.ellipse(x, ty, 16.0, 5.0, Pal.CON1)
		c.ellipse(x, ty - 1, 8.0, 2.5, Pal.INK)
		c.hline(x - 14, x + 14, ty + 3, Pal.CON0)
		c.px(x - 10, ty - 3, Pal.CON3)
	# Rainwater sitting in the top one.
	c.ellipse(x, y - 27, 7.0, 2.0, Pal.NIGHT2)
	c.hline(x - 3, x + 1, y - 28, Pal.RAIN)


static func _cloth(c: PixCanvas, x: int, y: int, cw: int, ch: int, a: Color, b: Color, d: Color) -> void:
	# A sodden cloth hanging from the line, folds as vertical bands.
	for yy in ch:
		var sag := int(sin(float(yy) / ch * PI) * 1.5)
		for xx in cw:
			var band := (xx + sag) % 5
			var col := a if band < 3 else (b if band == 3 else d)
			if yy > ch - 3 and (xx * 7 + yy) % 3 == 0:
				continue
			c.px(x + xx, y + yy, col)
	c.vline(x + cw / 2, y + ch, y + ch + 2, Pal.RAIN)


# ---------------------------------------------------------------- front layer

static func _front(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Corrugated tin overhang, seen slightly from below: regular ridges,
	# lit on their upper faces, with a few broad rust blooms.
	var y0 := ROOF_Y
	var cols := [Pal.RUST3, Pal.RUST4, Pal.RUST3, Pal.RUST2, Pal.RUST2, Pal.RUST1, Pal.RUST1, Pal.RUST2]
	for x in range(ROOF_X0, W):
		var ridge := (x - ROOF_X0) % 8
		var col: Color = cols[ridge]
		c.vline(x, y0 - 7, y0 + 4, col)
		c.px(x, y0 - 8, Pal.RUST4 if ridge == 1 else Pal.RUST2)
		# The wavy lip seen end-on.
		var lip := 1 if ridge < 4 else 0
		c.vline(x, y0 + 5, y0 + 6 + lip, Pal.RUST0)
		c.px(x, y0 + 7 + lip, Pal.INK)
	for i in 6:
		var bx := rng.randi_range(ROOF_X0 + 10, W - 30)
		var bw := rng.randi_range(14, 34)
		for x in range(bx, bx + bw):
			for y in range(y0 - 6, y0 + 4):
				var d := absf(x - bx - bw / 2.0) / (bw / 2.0)
				c.dpx(x, y, Pal.RUST1, 0.7 - d * 0.7)
	for i in 3:
		var hx := rng.randi_range(ROOF_X0 + 20, W - 10)
		c.rect(hx, y0 - 3, 2, 2, Pal.NIGHT1)
	# Underside in shadow, with the purlins that carry it.
	c.rect(ROOF_X0 + 4, y0 + 8, W - ROOF_X0 - 4, 3, Pal.RUST0)
	c.drect(ROOF_X0 + 4, y0 + 11, W - ROOF_X0 - 4, 4, Pal.INK, 0.5)
	for x in range(ROOF_X0 + 40, W, 64):
		c.rect(x, y0 + 8, 3, 6, Pal.WOOD1)
	# Post with a bracket, standing on a concrete footing.
	var px := ROOF_X0 + 12
	c.rect(px, y0 + 8, 4, FLOOR_TOP + 44 - y0 - 8, Pal.CON3)
	c.vline(px, y0 + 8, FLOOR_TOP + 44, Pal.CON5)
	c.vline(px + 3, y0 + 8, FLOOR_TOP + 44, Pal.CON1)
	c.line(px + 4, y0 + 20, px + 18, y0 + 9, Pal.CON3)
	c.line(px + 4, y0 + 21, px + 18, y0 + 10, Pal.CON1)
	c.rect(px - 3, FLOOR_TOP + 42, 10, 4, Pal.CON4)
	c.hline(px - 3, px + 6, FLOOR_TOP + 42, Pal.CON5)
	# Lantern on a hook and wire.
	c.vline(LAMP.x, y0 + 8, LAMP.y - 12, Pal.INK)
	c.rect(LAMP.x - 1, y0 + 8, 3, 2, Pal.CON3)
	var lantern := PixCanvas.grid([
		"....ooooo....",
		"...o4444ro...",
		"..ooooooooo..",
		".o411111114o.",
		"oo1abbbbba1oo",
		"o1abbcccbba1o",
		"o1abccccbba1o",
		"o1abccxccba1o",
		"o1abccccbba1o",
		"o1abbcccbba1o",
		"oo1abbbbba1oo",
		".o411111114o.",
		"..ooooooooo..",
		"...o44444o...",
		"....ooooo....",
	], {
		"o": Pal.INK, "1": Pal.RUST1, "4": Pal.RUST3, "r": Pal.RUST4,
		"a": Pal.LAMP3, "b": Pal.LAMP1, "c": Pal.LAMP0, "x": Color("ffffff"),
	})
	c.stamp(lantern, LAMP.x - 6, LAMP.y - 11)
	# Sagging power cable across the top, with drops caught on it.
	for x in W:
		var t := x / float(W)
		var y := int(10 + 34 * 4.0 * t * (1.0 - t))
		c.px(x, y, Pal.INK)
		c.px(x, y + 1, Pal.INK if x % 3 else Pal.NIGHT1)
		if x % 37 == 5:
			c.px(x, y + 2, Pal.RAIN)
	# Foreground rubble framing the bottom-left corner.
	var rubble := PackedVector2Array([
		Vector2(0, 340), Vector2(14, 334), Vector2(26, 336), Vector2(38, 342), Vector2(50, 350),
		Vector2(58, 360), Vector2(0, 360),
	])
	c.poly(rubble, Pal.INK)
	c.line(4, 337, 24, 334, Pal.CON1)
	c.line(26, 337, 40, 343, Pal.CON1)
	c.rect(30, 346, 6, 4, Pal.CON0)
	# Rebar sticking out of the rubble.
	c.line(18, 336, 30, 318, Pal.RUST1)
	c.line(19, 336, 31, 318, Pal.RUST0)
	return c.img

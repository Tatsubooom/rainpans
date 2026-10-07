class_name GlassArt
## Area 3: a broken glasshouse. An iron-ribbed glass vault overhead; rain
## streams down the panes and only falls inside through the broken ones.
## Plants have taken the place over.

const W := 320
const H := 180

const LAMP := Vector2i(258, 100)
const FLOOR_TOP := 132
const EAVE_Y := 78 # where the glass meets the side walls
const RIDGE_Y := 14 # top of the vault
## Broken panes: x ranges of the roof where rain gets in.
const BROKEN := [[52, 76], [148, 166], [214, 236]]


static func _roof_y(x: float) -> float:
	# Pointed-arch profile: steep near the walls, flatter toward the ridge.
	var t := absf(x - W / 2.0) / (W / 2.0)
	return RIDGE_Y + (EAVE_Y - RIDGE_Y) * pow(t, 1.6)


static func _profile() -> PackedFloat32Array:
	var p := PackedFloat32Array()
	p.resize(W)
	for x in W:
		p[x] = _roof_y(x)
	return p


static func build() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var shelters := []
	# Whole roof shelters except the broken panes: split into strips.
	var edges := [0]
	for b in BROKEN:
		edges.append(b[0])
		edges.append(b[1])
	edges.append(W)
	for i in range(0, edges.size(), 2):
		var x0: int = edges[i]
		var x1: int = edges[i + 1]
		shelters.append(Rect2(x0, 0, x1 - x0, _roof_y((x0 + x1) / 2.0) + 2))
	var rects := []
	for b in BROKEN:
		rects.append(Rect2(b[0] + 2, _roof_y((b[0] + b[1]) / 2.0), b[1] - b[0] - 4, 0))
	var drips := []
	for x in [100, 30, 190, 284, 128, 252, 86, 300, 176]:
		drips.append(Vector2(x, _roof_y(x) + 3))
	# Run-off pours in only at the edge of one broken pane.
	var trickles := [[Vector2(BROKEN[1][1] - 1, _roof_y(BROKEN[1][1]) + 2), float(FLOOR_TOP + 6)]]
	return {
		"name": "割れた温室",
		"layers": {"sky": _sky(rng), "mid": _mid(rng), "floor": _floor(rng), "front": _front(rng)},
		"floor": Rect2(6, 139, 308, 34),
		"shelters": shelters,
		"rain_rects": rects,
		"drips": drips,
		"drip_depth": 150.0,
		"lamp": Vector2(LAMP),
		"lamp_color": Pal.LAMP2,
		"puddles": [Rect2(56, 154, 30, 5), Rect2(150, 162, 26, 5), Rect2(214, 148, 24, 4)],
		"smoke": [],
		"floor_y": FLOOR_TOP,
		"wander": [100.0, 30.0, 290.0],
		"trickles": trickles,
		"weeds": [[Vector2(20, 176), 6], [Vector2(110, 137), 5], [Vector2(244, 136), 6], [Vector2(306, 170), 5], [Vector2(170, 136), 4]],
		"perches": [Vector2(160, 15), Vector2(96, 31)],
		"roof_profile": _profile(),
		"broken": BROKEN,
		"bed": "glass",
		"fireflies": 18,
		"firefly_rect": Rect2(20, 90, 280, 42),
		"ambient": Color(0.84, 0.98, 0.9),
		"reverb_room": 0.84,
	}


# ------------------------------------------------------------------ outside

static func _sky(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H, Pal.NIGHT0)
	c.vgrad(0, 0, W, 110, [Pal.NIGHT0, Pal.NIGHT1, Pal.NIGHT2, Pal.NIGHT3, Pal.FOG0])
	# Trees outside, crowding the glass: layered round crowns.
	for layer in 2:
		var col := Pal.NIGHT2 if layer == 0 else Pal.MOSS0
		var base := 70 + layer * 18
		var x := -10
		while x < W + 10:
			var r := rng.randi_range(10, 22) - layer * 3
			c.circle(x, base - r / 2, r, col)
			c.rect(x - 2, base, 4, 60, col)
			x += rng.randi_range(14, 26)
		c.rect(0, base + 4, W, H - base, col)
	# A thin band of haze low behind the trees.
	for y in range(92, 112):
		c.drect(0, y, W, 1, Pal.NIGHT3, (y - 92) / 60.0)
	return c.img


# ----------------------------------------------------------------- interior

static func _mid(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Low brick walls under the glass.
	for side in [0, 1]:
		var x0 := 0 if side == 0 else W - 14
		c.rect(x0, EAVE_Y, 14, FLOOR_TOP - EAVE_Y + 2, Pal.RUST0)
		for y in range(EAVE_Y, FLOOR_TOP, 4):
			c.hline(x0, x0 + 13, y, Pal.INK)
			for x in range(x0 + (2 if (y / 4) % 2 == 0 else 6), x0 + 14, 8):
				c.px(x, y + 1, Pal.INK)
				c.px(x, y + 2, Pal.INK)
		c.hline(x0, x0 + 13, EAVE_Y, Pal.RUST2)
	# A dry fountain basin in the middle with a cracked stone bird on top.
	var fx := 160
	c.ellipse(fx, 128, 30, 6, Pal.CON2)
	c.ellipse(fx, 127, 27, 4, Pal.CON1)
	c.rect(fx - 30, 128, 61, 6, Pal.CON2)
	c.hline(fx - 30, fx + 30, 128, Pal.CON4)
	c.hline(fx - 30, fx + 30, 133, Pal.CON0)
	c.rect(fx - 3, 108, 6, 20, Pal.CON3)
	c.vline(fx - 3, 108, 127, Pal.CON4)
	c.ellipse(fx, 108, 9, 2, Pal.CON3)
	c.hline(fx - 9, fx + 9, 107, Pal.CON4)
	var bird := PixCanvas.grid([
		"..oo.....",
		".o43o....",
		"o4433oooo",
		".o33333o.",
		"..o333o..",
		"...ooo...",
	], {"o": Pal.CON1, "3": Pal.CON3, "4": Pal.CON4})
	c.stamp(bird, fx - 4, 100)
	# Overgrown beds: big leaves and ferns on both sides.
	for i in 26:
		var lx := rng.randi_range(0, W)
		if absf(lx - fx) < 40:
			continue
		var ly := rng.randi_range(92, 128)
		_leaf(c, lx, ly, rng.randi_range(4, 9), rng)
	# Hanging vines from the ironwork.
	for i in 16:
		var vx := rng.randi_range(10, W - 10)
		var top := int(_roof_y(vx)) + 2
		var ln := rng.randi_range(8, 40)
		for k in ln:
			var col := Pal.MOSS2 if k % 5 else Pal.MOSS3
			c.px(vx + int(sin(k * 0.4 + i) * 1.5), top + k, col)
			if k % 6 == 3:
				c.px(vx + 1 + int(sin(k * 0.4 + i) * 1.5), top + k, Pal.MOSS3)
	return c.img


static func _leaf(c: PixCanvas, x: int, y: int, size: int, rng: RandomNumberGenerator, stem := true) -> void:
	# A drooping leaf: a filled teardrop with a lit upper edge and a midrib.
	var dir := 1 if rng.randf() < 0.5 else -1
	for k in size * 2:
		var t := float(k) / (size * 2)
		var half := int(sin(t * PI) * size * 0.45)
		var cx := x + dir * k
		var cy := y + int(t * t * size * 0.9)
		for o in range(-half, half + 1):
			c.px(cx, cy + o, Pal.MOSS1 if o > 0 else Pal.MOSS2)
		c.px(cx, cy - half, Pal.MOSS3)
		c.px(cx, cy, Pal.MOSS0)
	# Stem down to the soil.
	if stem:
		c.vline(x, y, 130, Pal.MOSS0)


static func _floor(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Tiled path, checkered terracotta and stone, many tiles lifted or gone.
	c.rect(0, FLOOR_TOP, W, H - FLOOR_TOP, Pal.CON1)
	for ty in range(FLOOR_TOP, H, 6):
		var row := (ty - FLOOR_TOP) / 6
		for tx in range(-6 + (row % 2) * 4, W, 8):
			var col := Pal.RUST0 if ((tx / 8) + row) % 2 == 0 else Pal.CON1
			if rng.randf() < 0.08:
				col = Pal.MOSS0
			c.rect(tx, ty, 7, 5, col)
			c.hline(tx, tx + 6, ty, Pal.RUST1 if col == Pal.RUST0 else Pal.CON2)
	for y in range(FLOOR_TOP, FLOOR_TOP + 6):
		c.drect(0, y, W, 1, Pal.INK, 0.6 - (y - FLOOR_TOP) * 0.1)
	# Soil beds along the walls.
	c.rect(0, FLOOR_TOP - 2, 26, 8, Pal.RUST0)
	c.rect(W - 26, FLOOR_TOP - 2, 26, 8, Pal.RUST0)
	# Puddles.
	for p in [Rect2(56, 154, 30, 5), Rect2(150, 162, 26, 5), Rect2(214, 148, 24, 4)]:
		var cx := int(p.position.x + p.size.x / 2)
		var cy := int(p.position.y + p.size.y / 2)
		c.ellipse(cx, cy, p.size.x / 2 + 1, p.size.y / 2 + 1, Pal.CON0)
		c.ellipse(cx, cy, p.size.x / 2, p.size.y / 2, Pal.NIGHT1)
	# Broken glass glinting on the tiles under the broken panes.
	for b in BROKEN:
		for i in 8:
			c.px(rng.randi_range(b[0], b[1]), rng.randi_range(FLOOR_TOP + 4, H - 4), Pal.RAIN_HI if i % 3 == 0 else Pal.FOG2)
	# A bench and a watering can someone left.
	c.rect(276, 124, 30, 2, Pal.RUST2)
	c.hline(276, 305, 124, Pal.RUST3)
	c.rect(278, 126, 2, 7, Pal.CON1)
	c.rect(302, 126, 2, 7, Pal.CON1)
	return c.img


static func _front(rng: RandomNumberGenerator) -> Image:
	var c := PixCanvas.new(W, H)
	# Glass: faint blue panes between iron ribs, broken panes left open.
	for x in W:
		var ry := int(_roof_y(x))
		var broken := false
		for b in BROKEN:
			if x >= b[0] and x < b[1]:
				broken = true
		if not broken:
			# The pane itself is a thin translucent band along the vault line,
			# plus a faint fill so the glass reads against the dark sky.
			for y in range(0, ry):
				c.dpx(x, y, Color(Pal.FOG1, 0.3), 0.25)
			c.px(x, ry, Color(Pal.RAIN, 0.8))
			c.px(x, ry + 1, Color(Pal.FOG1, 0.5))
		else:
			# Jagged shards hanging from the frame.
			var shard := int(absf(sin(x * 1.7)) * 5.0)
			for y in range(ry - 2, ry + shard):
				c.px(x, y, Color(Pal.RAIN_HI, 0.55) if y == ry + shard - 1 else Color(Pal.FOG1, 0.4))
	# Iron ribs: radial-ish bars following the arch, plus purlins.
	for rx in range(0, W + 1, 20):
		var top := int(_roof_y(rx))
		c.vline(rx, 0, top + 1, Pal.INK)
		c.vline(rx + 1, 0, top, Pal.CON1)
	for x in W:
		var ry := int(_roof_y(x))
		c.px(x, ry, Pal.INK)
		c.px(x, ry - 1, Pal.CON2)
		for k in [10, 22]:
			if ry - k > 0:
				c.px(x, ry - k, Pal.INK)
	# Side posts down to the walls.
	for px in [12, W - 14]:
		c.rect(px, int(_roof_y(px)), 2, FLOOR_TOP - int(_roof_y(px)), Pal.INK)
		c.vline(px, int(_roof_y(px)), FLOOR_TOP, Pal.CON2)
	# Lantern on a hook from the rib.
	c.line(LAMP.x, int(_roof_y(LAMP.x)), LAMP.x, LAMP.y - 5, Pal.INK)
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
	# Foreground leaves framing the bottom corners.
	for i in 5:
		_leaf(c, rng.randi_range(0, 30), rng.randi_range(150, 168), rng.randi_range(6, 10), rng, false)
		_leaf(c, rng.randi_range(290, 320), rng.randi_range(150, 168), rng.randi_range(6, 10), rng, false)
	return c.img

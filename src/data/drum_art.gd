class_name DrumArt
## Full-resolution drum sprites, painted with a few shape routines (shaded
## cylinders, domes, plates) plus hand-placed details. Each returns an Image
## whose bottom-centre is the drum's footprint. Mouths (`lid`) are declared
## in DrumDefs in these sprite pixels.


static func paint(id: String) -> Image:
	var d := DrumDefs.get_def(id)
	var r: Array = d.ramp
	var ramp := [Color(r[0]), Color(r[1]), Color(r[2]), Color(r[3]), Color(r[4])]
	var acc: Array = d.accent
	var a0 := Color(acc[0])
	var a1 := Color(acc[1])
	match id:
		"can": return _can(ramp, a0, a1)
		"bucket": return _bucket(ramp, a0, a1)
		"helmet": return _helmet(ramp, a0, a1)
		"pot": return _pot(ramp, a0, a1)
		"bottle": return _bottle(ramp, a0, a1)
		"drum": return _drum(ramp, a0, a1)
		"tin": return _tin(ramp, a0, a1)
		"kettle": return _kettle(ramp, a0, a1)
		"pipes": return _pipes(ramp, a0, a1)
		"plate": return _plate(ramp, a0, a1)
		"tarp": return _tarp(ramp, a0, a1)
	return Image.create(8, 8, false, Image.FORMAT_RGBA8)


## Colour on a cylinder at horizontal position u (0 left .. 1 right): lit
## from the upper left, a bright specular band, falling into shadow.
static func _cyl(ramp: Array, u: float, x: int, y: int) -> Color:
	var v := 0.0
	if u < 0.08:
		v = 2.6
	elif u < 0.2:
		v = 3.6
	elif u < 0.3:
		v = 4.0 # specular band
	elif u < 0.55:
		v = 3.0 - (u - 0.3) * 2.0
	else:
		v = 2.4 - (u - 0.55) * 4.4
	return ramp[_band(clampf(v, 0.0, 4.0), x, y)]


## Rounds a 0..4 shade to a ramp index: flat bands, with ordered dithering
## only in a narrow strip at each band edge (keeps surfaces clean).
static func _band(v: float, x: int, y: int) -> int:
	var i := int(v)
	var f := v - i
	if i >= 4:
		return 4
	if f > 0.7:
		return i + 1
	if f > 0.45 and (f - 0.45) * 4.0 > PixCanvas.bayer(x, y):
		return i + 1
	return i


## A shaded cylinder seen slightly from above. Returns the y of the top
## ellipse centre. `open` draws the mouth with dark water inside.
static func _cylinder(c: PixCanvas, x: int, y: int, w: int, h: int, ramp: Array, open := true, taper := 0) -> int:
	var ry := maxi(2, int(w * 0.16))
	var cy := y + ry
	for yy in range(cy, y + h - ry):
		var t := float(yy - cy) / maxf(1.0, h - 2 * ry)
		var inset := int(round(taper * t))
		for xx in range(inset, w - inset):
			var u := float(xx - inset) / maxf(1.0, w - 2 * inset - 1)
			c.px(x + xx, yy, _cyl(ramp, u, x + xx, yy))
		c.px(x + inset, yy, Pal.INK)
		c.px(x + w - 1 - inset, yy, Pal.INK)
	# Bottom curve.
	var by := y + h - ry - 1
	var binset := taper
	var brx := (w - 2 * binset) / 2.0
	for xx in range(binset, w - binset):
		var dx := (xx - binset + 0.5 - brx) / brx
		var dy := int(round(sqrt(maxf(0.0, 1.0 - dx * dx)) * ry))
		var u := float(xx - binset) / maxf(1.0, w - 2 * binset - 1)
		for k in dy:
			c.px(x + xx, by + k, _cyl(ramp, u, x + xx, by + k))
		c.px(x + xx, by + dy, Pal.INK)
	# Top ellipse: rim and either a lid or the open mouth.
	var rx := w / 2.0
	for xx in w:
		var dx := (xx + 0.5 - rx) / rx
		var dy := sqrt(maxf(0.0, 1.0 - dx * dx)) * ry
		var top := int(round(cy - dy))
		var bot := int(round(cy + dy))
		for yy in range(top, bot + 1):
			var inner := absf(dx) < 0.86 and yy > top + 1 and yy < bot - 1
			var col: Color
			if not inner:
				col = ramp[4] if (dx < 0.0 and yy <= cy) else (ramp[3] if yy <= cy else ramp[2])
			elif open:
				# Water inside: dark, with a sky glint on the far side.
				col = Pal.NIGHT1 if yy > cy - 1 else Pal.NIGHT2
				if yy == top + 2 and absf(dx + 0.2) < 0.25:
					col = Pal.FOG1
			else:
				col = ramp[3] if dx < 0.1 else ramp[2]
			c.px(x + xx, yy, col)
		c.px(x + xx, top - 1, Pal.INK)
	c.px(x, cy, Pal.INK)
	c.px(x + w - 1, cy, Pal.INK)
	return cy


static func _speckle(c: PixCanvas, x: int, y: int, w: int, h: int, col: Color, n: int, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in n:
		var px := x + rng.randi_range(0, w - 1)
		var py := y + rng.randi_range(0, h - 1)
		var cur := c.get_px(px, py)
		if cur.a > 0.0 and cur != Pal.INK:
			c.px(px, py, col)


# ---------------------------------------------------------------- the drums

static func _can(ramp: Array, a0: Color, a1: Color) -> Image:
	var c := PixCanvas.new(16, 24)
	_cylinder(c, 0, 0, 16, 24, ramp)
	# Paper label band with a faded mark, torn at one corner.
	for y in range(8, 17):
		for x in range(1, 15):
			var u := (x - 1) / 13.0
			var lit := u < 0.5
			c.px(x, y, a1 if lit else a0)
		c.px(1, y, Pal.INK)
		c.px(14, y, Pal.INK)
	c.hline(1, 14, 8, a1.lightened(0.2))
	c.rect(5, 11, 5, 3, Pal.BONE.darkened(0.2))
	c.hline(6, 8, 12, a0)
	c.rect(11, 15, 3, 2, ramp[2])
	# Ribs pressed into the tin above and below the label.
	for y in [6, 19]:
		for x in range(2, 14):
			c.px(x, y, ramp[1] if x > 8 else ramp[3])
	_speckle(c, 1, 17, 14, 5, Pal.RUST2, 6, 1)
	return c.img


static func _bucket(ramp: Array, a0: Color, a1: Color) -> Image:
	var c := PixCanvas.new(26, 30)
	# Wire handle arcing over the top.
	for x in range(2, 24):
		var t := (x - 2) / 21.0
		var y := int(9 - sin(t * PI) * 8.0)
		c.px(x, y, Pal.CON5 if t < 0.5 else Pal.CON3)
	_cylinder(c, 0, 6, 26, 24, ramp, true, 3)
	# Rolled rim and the handle lugs.
	c.px(1, 10, a1)
	c.px(24, 10, a0)
	c.rect(0, 10, 2, 3, Pal.CON4)
	c.rect(24, 10, 2, 3, Pal.CON2)
	# Embossed bands and a dent.
	for y in [16, 24]:
		for x in range(4, 22):
			c.px(x, y, ramp[1] if x > 14 else ramp[3])
	c.line(16, 19, 19, 22, ramp[1])
	_speckle(c, 3, 14, 20, 14, ramp[1], 6, 2)
	return c.img


static func _helmet(ramp: Array, a0: Color, a1: Color) -> Image:
	var c := PixCanvas.new(34, 18)
	# Dome: half ellipse shaded from the upper left.
	var cx := 17.0
	var cy := 13.0
	for y in range(1, 14):
		for x in range(3, 31):
			var dx := (x + 0.5 - cx) / 14.0
			var dy := (y + 0.5 - cy) / 12.0
			var d := dx * dx + dy * dy
			if d > 1.0:
				continue
			# Light comes from (-0.5, -0.8).
			var nz := sqrt(maxf(0.0, 1.0 - d))
			var lum := clampf(0.55 + (-dx * 0.45 - dy * 0.6) * 0.8 + nz * 0.2, 0.0, 1.0)
			c.px(x, y, ramp[_band(lum * 4.0, x, y)])
			if d > 0.88:
				c.px(x, y, Pal.INK)
	# Ridge down the middle and a glint.
	for y in range(2, 13):
		c.px(17, y, ramp[4] if y < 7 else ramp[3])
	c.rect(10, 4, 2, 1, Pal.BONE)
	c.px(9, 5, Pal.BONE)
	# Brim: wider, flat, with its shadowed underside.
	c.hline(0, 33, 13, Pal.INK)
	c.hline(1, 32, 14, ramp[3])
	c.hline(1, 32, 15, ramp[1])
	c.hline(0, 33, 16, Pal.INK)
	c.px(0, 14, Pal.INK)
	c.px(33, 14, Pal.INK)
	c.px(0, 15, Pal.INK)
	c.px(33, 15, Pal.INK)
	# Headband stripe and scratches.
	c.hline(4, 29, 12, a0)
	c.line(21, 6, 25, 9, ramp[1])
	c.line(8, 9, 11, 10, ramp[2])
	return c.img


static func _pot(ramp: Array, a0: Color, a1: Color) -> Image:
	var c := PixCanvas.new(38, 18)
	_cylinder(c, 0, 0, 26, 18, ramp)
	# Long handle with a hanging loop and a wooden grip.
	c.hline(25, 37, 7, Pal.INK)
	c.hline(25, 31, 8, ramp[2])
	c.hline(25, 31, 9, ramp[1])
	c.rect(31, 7, 6, 3, a1)
	c.hline(31, 36, 7, a1.lightened(0.2))
	c.hline(31, 36, 10, Pal.INK)
	c.px(37, 8, Pal.INK)
	c.px(37, 9, Pal.INK)
	c.ring(35, 8, 1.0, 1.0, Pal.INK)
	# Scorch marks around the base.
	_speckle(c, 1, 13, 24, 4, a0, 14, 3)
	return c.img


static func _bottle(ramp: Array, a0: Color, a1: Color) -> Image:
	var c := PixCanvas.new(12, 28)
	# Neck.
	c.rect(4, 0, 4, 8, ramp[2])
	c.vline(4, 0, 7, ramp[4])
	c.vline(7, 0, 7, ramp[1])
	c.hline(4, 7, 0, Pal.INK)
	c.hline(3, 8, 1, Pal.INK)
	c.rect(4, 1, 4, 1, ramp[3])
	c.vline(3, 1, 7, Pal.INK)
	c.vline(8, 1, 7, Pal.INK)
	# Shoulders and body (glass: a bright edge highlight, see-through middle).
	for y in range(8, 27):
		var half := 5 if y > 11 else 2 + (y - 8)
		for x in range(6 - half, 6 + half):
			var u := float(x - (6 - half)) / maxf(1.0, half * 2 - 1)
			var col: Color = ramp[2]
			if u < 0.2:
				col = ramp[4]
			elif u < 0.35:
				col = ramp[3]
			elif u > 0.8:
				col = ramp[1]
			c.px(x, y, col)
		c.px(6 - half - 1, y, Pal.INK)
		c.px(6 + half, y, Pal.INK)
	c.hline(1, 10, 27, Pal.INK)
	# Paper label, and rainwater inside the lower body.
	c.rect(2, 16, 8, 5, Pal.BONE.darkened(0.15))
	c.hline(2, 9, 16, Pal.BONE)
	c.hline(3, 7, 18, a0)
	for y in range(22, 27):
		for x in range(2, 10):
			if c.get_px(x, y) != Pal.INK:
				c.px(x, y, ramp[1] if x > 4 else ramp[3])
	c.vline(3, 9, 14, a1)
	return c.img


static func _drum(ramp: Array, a0: Color, a1: Color) -> Image:
	var c := PixCanvas.new(32, 40)
	_cylinder(c, 0, 0, 32, 40, ramp)
	# Rolling hoops: a raised rib catching light then its shadow.
	for y in [13, 25]:
		for x in range(1, 31):
			var u := (x - 1) / 29.0
			c.px(x, y, ramp[4] if u < 0.35 else ramp[2])
			c.px(x, y + 1, Pal.INK if u > 0.7 else ramp[0])
	# Bung caps on the lid.
	c.rect(7, 4, 3, 2, ramp[1])
	c.rect(22, 3, 2, 2, ramp[1])
	# Rust blooms and a stencilled band.
	_speckle(c, 1, 6, 30, 30, a0, 34, 4)
	_speckle(c, 1, 6, 30, 30, ramp[4], 8, 5)
	for x in range(6, 26):
		if x % 3 != 0:
			c.px(x, 19, a1)
	c.px(9, 20, a1)
	c.px(18, 20, a1)
	return c.img


static func _tin(ramp: Array, a0: Color, a1: Color) -> Image:
	# A corrugated sheet lying on the floor, seen from above and in front.
	var c := PixCanvas.new(46, 14)
	var pat := [4, 4, 3, 2, 1, 1, 2, 3]
	for y in range(1, 10):
		for x in range(1, 45):
			var v: int = pat[x % 8] - (1 if y > 6 else 0)
			c.px(x, y, ramp[clampi(v, 0, 4)])
	c.hline(0, 45, 0, Pal.INK)
	c.hline(0, 45, 13, Pal.INK)
	c.vline(0, 0, 12, Pal.INK)
	c.vline(45, 0, 12, Pal.INK)
	# The wavy front edge.
	for x in range(1, 45):
		var dip := 1 if pat[x % 8] <= 2 else 0
		c.vline(x, 10, 11 + dip, ramp[1])
		c.px(x, 12 + dip, Pal.INK)
		if dip == 0:
			c.px(x, 12, ramp[0])
	# Rust holes and patches, a bent corner.
	_speckle(c, 1, 1, 44, 9, a0, 22, 6)
	_speckle(c, 1, 1, 44, 9, a1, 10, 7)
	c.rect(38, 2, 3, 2, Pal.NIGHT1)
	c.line(1, 1, 5, 3, ramp[4])
	return c.img


static func _kettle(ramp: Array, a0: Color, a1: Color) -> Image:
	var c := PixCanvas.new(36, 26)
	# Arched handle.
	for x in range(6, 26):
		var t := (x - 6) / 19.0
		var y := int(9 - sin(t * PI) * 8.0)
		c.px(x, y, Pal.INK)
		c.px(x, y + 1, a0)
	c.vline(6, 8, 11, Pal.INK)
	c.vline(25, 8, 11, Pal.INK)
	# Body: a squat dome with a flat base.
	var cx := 15.5
	for y in range(8, 25):
		for x in range(1, 31):
			var dx := (x + 0.5 - cx) / 14.5
			var dy := (y + 0.5 - 22.0) / 14.0
			if y > 22:
				dy = 0.0
			var d := dx * dx + dy * dy
			if d > 1.0:
				continue
			var lum := clampf(0.55 - dx * 0.45 - dy * 0.35, 0.0, 1.0)
			c.px(x, y, Pal.INK if d > 0.9 else ramp[_band(lum * 4.0, x, y)])
	c.hline(2, 29, 25, Pal.INK)
	c.hline(3, 28, 24, ramp[1])
	# Lid and knob.
	c.ellipse(15, 10, 7.0, 2.0, ramp[3])
	c.hline(9, 21, 9, ramp[4])
	c.rect(14, 6, 3, 3, a0)
	c.px(14, 6, a1)
	# Spout reaching out right.
	c.line(28, 18, 34, 11, Pal.INK)
	c.line(28, 19, 34, 12, ramp[2])
	c.line(29, 20, 35, 13, ramp[1])
	c.px(35, 11, Pal.INK)
	# Glints.
	c.rect(6, 13, 2, 2, a1)
	c.px(5, 15, a1)
	return c.img


static func _pipes(ramp: Array, a0: Color, a1: Color) -> Image:
	# Pipe chimes hung from a crossbar on an A-frame.
	var c := PixCanvas.new(28, 36)
	c.hline(0, 27, 0, a1)
	c.hline(0, 27, 1, a1.darkened(0.3))
	c.line(1, 1, 0, 35, a0)
	c.line(2, 1, 4, 35, a0)
	c.line(26, 1, 27, 35, a0)
	c.line(25, 1, 23, 35, a0)
	var lens := [26, 22, 18, 14]
	for i in 4:
		var x := 6 + i * 5
		c.vline(x + 1, 2, 5, Pal.INK)
		var ln: int = lens[i]
		for y in range(6, 6 + ln):
			c.px(x, y, ramp[4] if y < 8 else ramp[3])
			c.px(x + 1, y, ramp[2])
			c.px(x + 2, y, ramp[1])
		c.hline(x, x + 2, 6, Pal.INK)
		c.hline(x, x + 2, 6 + ln, Pal.INK)
		c.px(x + 1, 6 + ln - 1, ramp[0])
	# The striker hanging in the middle.
	c.vline(14, 2, 20, Pal.INK)
	c.rect(12, 20, 5, 2, a1)
	return c.img


static func _plate(ramp: Array, a0: Color, a1: Color) -> Image:
	# A curved armour plate lying slightly tilted, rivets along the edge.
	var c := PixCanvas.new(42, 20)
	for y in range(1, 19):
		var inset := 0 if y > 3 and y < 16 else (2 if y == 2 or y == 17 else 4)
		for x in range(inset, 42 - inset):
			var u := float(x) / 41.0
			var v := 3.6 - u * 2.6 - (y - 2) * 0.06
			c.px(x, y, ramp[_band(clampf(v, 0.0, 4.0), x, y)])
		c.px(inset, y, Pal.INK)
		c.px(41 - inset, y, Pal.INK)
	c.hline(4, 37, 0, Pal.INK)
	c.hline(4, 37, 19, Pal.INK)
	c.hline(4, 37, 1, ramp[4])
	c.hline(4, 37, 18, ramp[0])
	for x in range(5, 38, 6):
		c.px(x, 4, a1)
		c.px(x, 15, a1)
		c.px(x + 1, 5, Pal.INK)
		c.px(x + 1, 16, Pal.INK)
	# Shell scar and rust run-off.
	c.ellipse(26, 9, 3.0, 2.0, ramp[0])
	c.px(25, 8, Pal.INK)
	_speckle(c, 2, 3, 38, 14, a0, 18, 8)
	return c.img


static func _tarp(ramp: Array, a0: Color, a1: Color) -> Image:
	# A tarp tied between two posts, sagging under a pool of rainwater.
	var w := 54
	var c := PixCanvas.new(w, 22)
	for px in [1, w - 4]:
		c.rect(px, 0, 3, 22, a1)
		c.vline(px, 0, 21, a1.lightened(0.15))
		c.vline(px + 2, 0, 21, a0)
		c.hline(px, px + 2, 0, a1.lightened(0.3))
	for x in range(4, w - 4):
		var t := (x - 4) / float(w - 9)
		var edge := 4 + int(round(9.0 * sin(PI * t)))
		c.px(x, edge - 1, Pal.INK)
		for k in 4:
			c.px(x, edge + k, ramp[clampi(4 - k - (1 if t > 0.5 else 0), 0, 4)])
		c.px(x, edge + 4, Pal.INK)
		# Folds where it is tied.
		if t < 0.1 or t > 0.9:
			c.px(x, edge + 1, ramp[1])
	# Tie ropes.
	c.line(4, 4, 7, 6, Pal.BONE.darkened(0.4))
	c.line(w - 5, 4, w - 8, 6, Pal.BONE.darkened(0.4))
	# The pool: dark water with the sky in it.
	for x in range(14, w - 14):
		var t := (x - 4) / float(w - 9)
		var edge := 4 + int(round(9.0 * sin(PI * t)))
		var depth := int((sin(PI * t) - 0.55) * 8.0)
		for k in range(maxi(depth, 1)):
			c.px(x, edge - 1 - k, Pal.NIGHT1 if k > 0 else Pal.NIGHT2)
		if x % 5 == 0:
			c.px(x, edge - 1, Pal.FOG1)
	return c.img

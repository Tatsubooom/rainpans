class_name EnvFx
## Generated textures for light and mist, plus smoke particles.


## A radial light with hard, dithered bands so it reads as pixel light.
static func light_texture(radius: int, bands := 5) -> ImageTexture:
	var size := radius * 2
	var c := PixCanvas.new(size, size)
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - radius, y + 0.5 - radius).length() / radius
			if d >= 1.0:
				continue
			var v := pow(1.0 - d, 1.6)
			# Quantise to bands, dithering across each band edge.
			var q := v * bands
			var lo := floorf(q)
			var f := q - lo
			var level := lo + (1.0 if f > PixCanvas.bayer(x, y) else 0.0)
			var a := clampf(level / bands, 0.0, 1.0)
			c.img.set_pixel(x, y, Color(a, a, a, 1.0))
	return c.texture()


## Additive halo: concentric dithered rings of one colour fading outward.
static func halo_texture(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2
	var c := PixCanvas.new(size, size)
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - radius, y + 0.5 - radius).length() / radius
			if d >= 1.0:
				continue
			var v := pow(1.0 - d, 2.2)
			var q := floorf(v * 4.0 + PixCanvas.bayer(x, y) * 0.999) / 4.0
			if q > 0.0:
				c.img.set_pixel(x, y, Color(color.r * q * 0.55, color.g * q * 0.55, color.b * q * 0.55, 1.0))
	return c.texture()


## Additive horizon glow for dusk and dawn: warm at the bottom, dithered
## up into nothing.
static func horizon_texture(w: int, h: int) -> ImageTexture:
	var c := PixCanvas.new(w, h, Color(0, 0, 0, 1))
	var ramp := [Color("000000"), Color("1a0c14"), Color("3a1820"), Color("5a2a22"), Color("7a4228")]
	var n := ramp.size() - 1
	for y in h:
		var t := pow(float(y) / (h - 1), 1.6) * n
		var i := mini(int(t), n - 1)
		var f := t - i
		for x in w:
			# Break the glow up a little where clouds would sit.
			var wob := sin(x * 0.05) * 0.25 + sin(x * 0.013 + 1.0) * 0.35
			var c0: Color = ramp[i + 1] if f + wob * 0.2 > PixCanvas.bayer(x, y) else ramp[i]
			c.img.set_pixel(x, y, c0)
	return c.texture()


## A slanted beam of cold light: dithered columns, brightest at the top.
static func shaft_texture(w: int, h: int) -> ImageTexture:
	var c := PixCanvas.new(w, h, Color(0, 0, 0, 1))
	for y in h:
		var fall := 1.0 - float(y) / h
		var spread := float(y) * 0.18
		for x in w:
			var u := (x - spread * 0.5) / maxf(1.0, w - spread)
			if u < 0.0 or u > 1.0:
				continue
			var edge := minf(u, 1.0 - u) * 4.0
			var streak := 0.75 + 0.25 * sin(x * 0.7 + y * 0.02)
			var v := clampf(edge, 0.0, 1.0) * fall * streak * 0.5
			var q := floorf(v * 3.0 + PixCanvas.bayer(x, y) * 0.999) / 3.0
			if q > 0.0:
				c.img.set_pixel(x, y, Color(0.16 * q, 0.2 * q, 0.26 * q, 1.0))
	return c.texture()


## A pool of lamplight on the floor: a flattened ellipse in hard dithered
## bands (additive), so the ground under a lamp reads clearly lit.
static func pool_texture(rx: int, ry: int, color: Color) -> ImageTexture:
	var c := PixCanvas.new(rx * 2, ry * 2, Color(0, 0, 0, 1))
	for y in ry * 2:
		for x in rx * 2:
			var d := Vector2((x + 0.5 - rx) / rx, (y + 0.5 - ry) / ry).length()
			if d >= 1.0:
				continue
			var v := pow(1.0 - d, 1.3)
			var q := floorf(v * 5.0 + PixCanvas.bayer(x, y) * 0.999) / 5.0
			if q > 0.0:
				c.img.set_pixel(x, y, Color(color.r * q * 0.42, color.g * q * 0.42, color.b * q * 0.42, 1.0))
	return c.texture()


## A soft band of fog: a few flat translucent tones with dithered edges, so
## it reads as layered haze rather than noise.
static func mist_texture(w: int, h: int, seed: int, color: Color, density: float) -> ImageTexture:
	var c := PixCanvas.new(w, h)
	var n := FastNoiseLite.new()
	n.seed = seed
	n.frequency = 0.012
	n.fractal_octaves = 2
	for y in h:
		var vy := 1.0 - absf((y + 0.5) / h * 2.0 - 1.0)
		for x in w:
			var vx := minf(1.0, minf(x, w - x) / 40.0)
			var v := (n.get_noise_2d(x, y * 3.0) * 0.5 + 0.5) * vy * vx * density
			var a := 0.0
			if v > 0.42:
				a = 0.22
			elif v > 0.3:
				a = 0.14
			elif v > 0.22 and PixCanvas.bayer(x, y) < 0.5:
				a = 0.14
			if a > 0.0:
				c.img.set_pixel(x, y, Color(color, a))
	return c.texture()


## Thunder: a long, low, rolling rumble.
static func thunder_wav() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 5.0)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var lp := 0.0
	var lp2 := 0.0
	var peak := 0.0001
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t := float(i) / rate
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.04
		lp2 += (lp - lp2) * 0.06
		var env := minf(1.0, t * 3.0) * exp(-t * 0.9) * (0.7 + 0.3 * sin(t * 5.3) * sin(t * 1.7))
		buf[i] = lp2 * env
		peak = maxf(peak, absf(buf[i]))
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i] / peak * 0.9, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = bytes
	return wav

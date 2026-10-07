class_name PixCanvas
extends RefCounted
## A tiny software painter over an Image. All art is generated through this at
## load time, so every pixel is placed deliberately (no filtering, no AA).

const BAYER4 := [
	0, 8, 2, 10,
	12, 4, 14, 6,
	3, 11, 1, 9,
	15, 7, 13, 5,
]

var img: Image
var w: int
var h: int


func _init(width: int, height: int, fill := Color(0, 0, 0, 0)) -> void:
	w = width
	h = height
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(fill)


static func bayer(x: int, y: int) -> float:
	return (BAYER4[(y & 3) * 4 + (x & 3)] + 0.5) / 16.0


func texture() -> ImageTexture:
	return ImageTexture.create_from_image(img)


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func px(x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= w or y >= h:
		return
	if c.a >= 1.0:
		img.set_pixel(x, y, c)
	elif c.a > 0.0:
		img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


func get_px(x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= w or y >= h:
		return Color(0, 0, 0, 0)
	return img.get_pixel(x, y)


func erase_rect(x: int, y: int, rw: int, rh: int) -> void:
	for yy in range(maxi(y, 0), mini(y + rh, h)):
		for xx in range(maxi(x, 0), mini(x + rw, w)):
			img.set_pixel(xx, yy, Color(0, 0, 0, 0))


## Writes `c` only where the threshold `t` (0..1) beats the ordered-dither cell.
func dpx(x: int, y: int, c: Color, t: float) -> void:
	if t > bayer(x, y):
		px(x, y, c)


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	for yy in range(maxi(y, 0), mini(y + rh, h)):
		for xx in range(maxi(x, 0), mini(x + rw, w)):
			px(xx, yy, c)


func drect(x: int, y: int, rw: int, rh: int, c: Color, t: float) -> void:
	for yy in range(maxi(y, 0), mini(y + rh, h)):
		for xx in range(maxi(x, 0), mini(x + rw, w)):
			dpx(xx, yy, c, t)


func hline(x0: int, x1: int, y: int, c: Color) -> void:
	for x in range(mini(x0, x1), maxi(x0, x1) + 1):
		px(x, y, c)


func vline(x: int, y0: int, y1: int, c: Color) -> void:
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		px(x, y, c)


func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		px(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


## Ellipse outline (one pixel thick).
func ring(cx: int, cy: int, rx: float, ry: float, c: Color) -> void:
	var steps := int(maxf(rx, ry) * 8.0)
	var last := Vector2i(-99999, -99999)
	for i in steps:
		var t := TAU * i / steps
		var p := Vector2i(roundi(cx + cos(t) * rx), roundi(cy + sin(t) * ry))
		if p != last:
			px(p.x, p.y, c)
			last = p


## A noisy fill: picks from `ramp` by fractal noise, dithered between steps.
func noise_rect(x: int, y: int, rw: int, rh: int, ramp: Array, seed: int, freq := 0.08, sy := 1.0) -> void:
	var n := FastNoiseLite.new()
	n.seed = seed
	n.frequency = freq
	n.fractal_octaves = 3
	var steps := ramp.size() - 1
	for yy in range(rh):
		for xx in range(rw):
			var v := clampf(n.get_noise_2d(xx + x, (yy + y) * sy) * 0.6 + 0.5, 0.0, 0.999) * steps
			var i := int(v)
			var f := v - i
			var col: Color = ramp[mini(i + 1, steps)] if f > bayer(x + xx, y + yy) else ramp[i]
			px(x + xx, y + yy, col)


## Copies `c` over pixels already of colour `match` only (for masked detail).
func recolor(x: int, y: int, rw: int, rh: int, match_col: Color, c: Color, t := 1.0) -> void:
	for yy in range(maxi(y, 0), mini(y + rh, h)):
		for xx in range(maxi(x, 0), mini(x + rw, w)):
			if img.get_pixel(xx, yy) == match_col and t > bayer(xx, yy):
				img.set_pixel(xx, yy, c)


func circle(cx: int, cy: int, r: float, c: Color) -> void:
	var ir := int(ceil(r))
	for y in range(-ir, ir + 1):
		for x in range(-ir, ir + 1):
			if x * x + y * y <= r * r:
				px(cx + x, cy + y, c)


func ellipse(cx: int, cy: int, rx: float, ry: float, c: Color) -> void:
	for y in range(-int(ry) - 1, int(ry) + 2):
		for x in range(-int(rx) - 1, int(rx) + 2):
			var d := (x * x) / (rx * rx) + (y * y) / (ry * ry)
			if d <= 1.0:
				px(cx + x, cy + y, c)


## Fills a convex/concave polygon by scanline (even-odd).
func poly(points: PackedVector2Array, c: Color) -> void:
	var miny := INF
	var maxy := -INF
	for p in points:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	for y in range(int(floor(miny)), int(ceil(maxy)) + 1):
		var fy := y + 0.5
		var xs: Array[float] = []
		for i in points.size():
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			if (a.y <= fy and b.y > fy) or (b.y <= fy and a.y > fy):
				xs.append(a.x + (fy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var i := 0
		while i + 1 < xs.size():
			for x in range(int(round(xs[i])), int(round(xs[i + 1]))):
				px(x, y, c)
			i += 2


## Vertical gradient that steps through `ramp` using ordered dithering between
## neighbouring swatches, so it stays inside the palette.
func vgrad(x: int, y: int, rw: int, rh: int, ramp: Array) -> void:
	var n := ramp.size() - 1
	for yy in range(rh):
		var t := float(yy) / maxf(1.0, rh - 1) * n
		var i := mini(int(t), n - 1) if n > 0 else 0
		var f := t - i
		for xx in range(rw):
			var c: Color = ramp[i + 1] if n > 0 and f > bayer(x + xx, y + yy) else ramp[i]
			px(x + xx, y + yy, c)


## Copies another image onto this one, skipping transparent pixels.
func stamp(src: Image, x: int, y: int, flip := false) -> void:
	for yy in src.get_height():
		for xx in src.get_width():
			var c := src.get_pixel(src.get_width() - 1 - xx if flip else xx, yy)
			if c.a > 0.0:
				px(x + xx, y + yy, c)


## Builds an Image from rows of characters. `key` maps a character to a Color;
## unknown characters (and '.') are transparent.
static func grid(rows: Array, key: Dictionary) -> Image:
	var gh := rows.size()
	var gw := 0
	for r in rows:
		gw = maxi(gw, (r as String).length())
	var out := Image.create(gw, gh, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in gh:
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if key.has(ch):
				out.set_pixel(x, y, key[ch])
	return out

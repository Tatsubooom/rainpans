class_name PixCanvas
extends RefCounted
## A tiny software painter over an Image. All art is generated through this at
## load time, so every pixel is placed deliberately (no filtering, no AA).
##
## Drawing calls take *logical* coordinates on a w x h grid. The image itself
## is `k` times larger: with k = 2 an area composed on the 320x180 grid comes
## out at 640x360. Filled areas cover k x k blocks, but edges are traced at
## full resolution: lines step one fine pixel at a time, curves and polygons
## are rasterised finely, and every dither / gradient uses the fine grid. So
## the design stays the same while the pixels get smaller.

const BAYER4 := [
	0, 8, 2, 10,
	12, 4, 14, 6,
	3, 11, 1, 9,
	15, 7, 13, 5,
]

## Default scale for new canvases (AreaLibrary sets it while building areas).
static var scale_k := 1

var img: Image
var w: int # logical size
var h: int
var k := 1
var _nw: int # native size
var _nh: int


func _init(width: int, height: int, fill := Color(0, 0, 0, 0), scale := -1) -> void:
	k = scale if scale > 0 else scale_k
	w = width
	h = height
	_nw = w * k
	_nh = h * k
	img = Image.create(_nw, _nh, false, Image.FORMAT_RGBA8)
	img.fill(fill)


static func bayer(x: int, y: int) -> float:
	return (BAYER4[(y & 3) * 4 + (x & 3)] + 0.5) / 16.0


func texture() -> ImageTexture:
	return ImageTexture.create_from_image(img)


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


# --------------------------------------------------------- native primitives

func _put(nx: int, ny: int, c: Color) -> void:
	if nx < 0 or ny < 0 or nx >= _nw or ny >= _nh:
		return
	if c.a >= 1.0:
		img.set_pixel(nx, ny, c)
	elif c.a > 0.0:
		img.set_pixel(nx, ny, img.get_pixel(nx, ny).blend(c))


func _fill(nx: int, ny: int, nw: int, nh: int, c: Color) -> void:
	for yy in range(maxi(ny, 0), mini(ny + nh, _nh)):
		for xx in range(maxi(nx, 0), mini(nx + nw, _nw)):
			_put(xx, yy, c)


# ------------------------------------------------------------ logical calls

func px(x: int, y: int, c: Color) -> void:
	if k == 1:
		_put(x, y, c)
	else:
		_fill(x * k, y * k, k, k, c)


func get_px(x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= w or y >= h:
		return Color(0, 0, 0, 0)
	return img.get_pixel(x * k, y * k)


func erase_rect(x: int, y: int, rw: int, rh: int) -> void:
	for yy in range(maxi(y * k, 0), mini((y + rh) * k, _nh)):
		for xx in range(maxi(x * k, 0), mini((x + rw) * k, _nw)):
			img.set_pixel(xx, yy, Color(0, 0, 0, 0))


## Writes `c` only where the threshold `t` (0..1) beats the ordered-dither
## cell, tested per fine pixel so dithers come out finer at k > 1.
func dpx(x: int, y: int, c: Color, t: float) -> void:
	for yy in range(y * k, y * k + k):
		for xx in range(x * k, x * k + k):
			if t > bayer(xx, yy):
				_put(xx, yy, c)


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	_fill(x * k, y * k, rw * k, rh * k, c)


func drect(x: int, y: int, rw: int, rh: int, c: Color, t: float) -> void:
	for yy in range(maxi(y * k, 0), mini((y + rh) * k, _nh)):
		for xx in range(maxi(x * k, 0), mini((x + rw) * k, _nw)):
			if t > bayer(xx, yy):
				_put(xx, yy, c)


func hline(x0: int, x1: int, y: int, c: Color) -> void:
	var a := mini(x0, x1)
	_fill(a * k, y * k, (maxi(x0, x1) - a + 1) * k, k, c)


func vline(x: int, y0: int, y1: int, c: Color) -> void:
	var a := mini(y0, y1)
	_fill(x * k, a * k, k, (maxi(y0, y1) - a + 1) * k, c)


## Bresenham at full resolution between the logical pixel centres, with a
## k-wide brush: same weight as before, finer steps on diagonals.
func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	if k == 1:
		_line_native(x0, y0, x1, y1, c, 1)
		return
	_line_native(x0 * k, y0 * k, x1 * k, y1 * k, c, k)


func _line_native(x0: int, y0: int, x1: int, y1: int, c: Color, brush: int) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		if brush == 1:
			_put(x0, y0, c)
		else:
			_fill(x0, y0, brush, brush, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func circle(cx: int, cy: int, r: float, c: Color) -> void:
	ellipse(cx, cy, r, r, c)


## Filled ellipse, rasterised at full resolution (same footprint as the
## logical shape, smoother edge).
func ellipse(cx: int, cy: int, rx: float, ry: float, c: Color) -> void:
	var ncx := (cx + 0.5) * k
	var ncy := (cy + 0.5) * k
	var nrx := (rx + 0.5) * k
	var nry := (ry + 0.5) * k
	for yy in range(int(floor(ncy - nry)), int(ceil(ncy + nry)) + 1):
		for xx in range(int(floor(ncx - nrx)), int(ceil(ncx + nrx)) + 1):
			var dx := (xx + 0.5 - ncx) / nrx
			var dy := (yy + 0.5 - ncy) / nry
			if dx * dx + dy * dy <= 1.0:
				_put(xx, yy, c)


## Ellipse outline (one fine pixel thick).
func ring(cx: int, cy: int, rx: float, ry: float, c: Color) -> void:
	var ncx := (cx + 0.5) * k - 0.5
	var ncy := (cy + 0.5) * k - 0.5
	var steps := int(maxf(rx, ry) * k * 8.0) + 8
	var last := Vector2i(-99999, -99999)
	for i in steps:
		var t := TAU * i / steps
		var p := Vector2i(roundi(ncx + cos(t) * rx * k), roundi(ncy + sin(t) * ry * k))
		if p != last:
			_put(p.x, p.y, c)
			last = p


## Fills a polygon by scanline (even-odd) at full resolution.
func poly(points: PackedVector2Array, c: Color) -> void:
	var pts := PackedVector2Array()
	for p in points:
		pts.append(p * k)
	var miny := INF
	var maxy := -INF
	for p in pts:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	for y in range(int(floor(miny)), int(ceil(maxy)) + 1):
		var fy := y + 0.5
		var xs: Array[float] = []
		for i in pts.size():
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			if (a.y <= fy and b.y > fy) or (b.y <= fy and a.y > fy):
				xs.append(a.x + (fy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var i := 0
		while i + 1 < xs.size():
			for x in range(int(round(xs[i])), int(round(xs[i + 1]))):
				_put(x, y, c)
			i += 2


## Vertical gradient stepping through `ramp`, dithered between neighbouring
## swatches on the fine grid.
func vgrad(x: int, y: int, rw: int, rh: int, ramp: Array) -> void:
	var n := ramp.size() - 1
	var ny0 := y * k
	var nh := rh * k
	for yy in range(nh):
		var t := float(yy) / maxf(1.0, nh - 1) * n
		var i := mini(int(t), n - 1) if n > 0 else 0
		var f := t - i
		for xx in range(x * k, (x + rw) * k):
			var col: Color = ramp[i + 1] if n > 0 and f > bayer(xx, ny0 + yy) else ramp[i]
			_put(xx, ny0 + yy, col)


## Copies a small sprite (logical pixels) onto this canvas, skipping
## transparent pixels. Each sprite pixel covers a k x k block.
func stamp(src: Image, x: int, y: int, flip := false) -> void:
	for yy in src.get_height():
		for xx in src.get_width():
			var c := src.get_pixel(src.get_width() - 1 - xx if flip else xx, yy)
			if c.a > 0.0:
				px(x + xx, y + yy, c)


## A noisy fill: picks from `ramp` by fractal noise, dithered between steps.
func noise_rect(x: int, y: int, rw: int, rh: int, ramp: Array, seed: int, freq := 0.08, sy := 1.0) -> void:
	var n := FastNoiseLite.new()
	n.seed = seed
	n.frequency = freq / k
	n.fractal_octaves = 3
	var steps := ramp.size() - 1
	for yy in range(y * k, (y + rh) * k):
		for xx in range(x * k, (x + rw) * k):
			var v := clampf(n.get_noise_2d(xx, yy * sy) * 0.6 + 0.5, 0.0, 0.999) * steps
			var i := int(v)
			var f := v - i
			var col: Color = ramp[mini(i + 1, steps)] if f > bayer(xx, yy) else ramp[i]
			_put(xx, yy, col)


## Copies `c` over pixels already of colour `match_col` only.
func recolor(x: int, y: int, rw: int, rh: int, match_col: Color, c: Color, t := 1.0) -> void:
	for yy in range(maxi(y * k, 0), mini((y + rh) * k, _nh)):
		for xx in range(maxi(x * k, 0), mini((x + rw) * k, _nw)):
			if img.get_pixel(xx, yy) == match_col and t > bayer(xx, yy):
				img.set_pixel(xx, yy, c)


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

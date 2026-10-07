class_name Smoke
extends Node2D
## Thin smoke rising from distant fires, leaning with the wind.

var sources: Array = []
var steam := false # pale, faster, thinner (leaking pipes)
var wind := -6.0
var _p: Array = [] # [x, y, age, life, size]
var _acc := 0.0
var _rng := RandomNumberGenerator.new()


func setup(points: Array) -> void:
	sources = points
	_rng.randomize()
	# Pre-warm so the column already exists.
	for i in 200:
		_step(0.05)


func _process(delta: float) -> void:
	_step(delta)
	queue_redraw()


func _step(delta: float) -> void:
	_acc += delta * 9.0
	while _acc >= 1.0:
		_acc -= 1.0
		for s in sources:
			var p: Vector2 = s
			_p.append([p.x + _rng.randf_range(-2.0, 2.0), p.y, 0.0, _rng.randf_range(4.0, 7.0), _rng.randf_range(2.0, 4.0)])
	var i := 0
	while i < _p.size():
		var q: Array = _p[i]
		q[2] += delta
		var t: float = q[2] / q[3]
		q[1] -= delta * (14.0 - t * 6.0)
		q[0] += delta * (wind * 2.0 * t + sin(q[2] * 1.3 + i) * 3.0)
		if q[2] >= q[3]:
			_p.remove_at(i)
		else:
			i += 1


func _draw() -> void:
	for q in _p:
		var t: float = q[2] / q[3]
		var r := int(q[4] + t * 8.0)
		var tone := 0 if t < 0.3 else (1 if t < 0.65 else 2)
		var density := int((1.0 - t) * 4.0)
		var tex := _puff(r, tone, density)
		draw_texture(tex, Vector2(floorf(q[0]) - r, floorf(q[1]) - r))


var _puffs := {}


## A dithered disc, cached by radius / tone / density step.
func _puff(r: int, tone: int, density: int) -> ImageTexture:
	var key := r * 100 + tone * 10 + density
	if _puffs.has(key):
		return _puffs[key]
	var cols := [Pal.FOG1, Pal.FOG0, Pal.NIGHT4]
	if steam:
		cols = [Pal.FOG2, Pal.FOG1, Pal.FOG0]
	var c := PixCanvas.new(r * 2 + 1, r * 2 + 1)
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if x * x + y * y > r * r:
				continue
			# Softer toward the rim, thinner as it ages.
			var edge := 1.0 - float(x * x + y * y) / float(r * r + 1)
			if density / 4.0 * (0.5 + 0.5 * edge) > PixCanvas.bayer(x + r, y + r):
				c.img.set_pixel(x + r, y + r, cols[tone])
	_puffs[key] = c.texture()
	return _puffs[key]

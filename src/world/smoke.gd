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
			_p.append([p.x + _rng.randf_range(-1.0, 1.0), p.y, 0.0, _rng.randf_range(4.0, 7.0), _rng.randf_range(1.0, 2.0)])
	var i := 0
	while i < _p.size():
		var q: Array = _p[i]
		q[2] += delta
		var t: float = q[2] / q[3]
		q[1] -= delta * (7.0 - t * 3.0)
		q[0] += delta * (wind * t + sin(q[2] * 1.3 + i) * 1.5)
		if q[2] >= q[3]:
			_p.remove_at(i)
		else:
			i += 1


func _draw() -> void:
	for q in _p:
		var t: float = q[2] / q[3]
		var r: float = q[4] + t * 4.0
		var col := Pal.FOG1 if t < 0.3 else (Pal.FOG0 if t < 0.65 else Pal.NIGHT4)
		if steam:
			col = Pal.FOG2 if t < 0.3 else (Pal.FOG1 if t < 0.6 else Pal.FOG0)
		var cx := floorf(q[0])
		var cy := floorf(q[1])
		var ir := int(r)
		for y in range(-ir, ir + 1):
			for x in range(-ir, ir + 1):
				if x * x + y * y > r * r:
					continue
				# Thin out with age using an ordered dither.
				if (1.0 - t) * 0.8 > PixCanvas.bayer(int(cx) + x, int(cy) + y):
					draw_rect(Rect2(cx + x, cy + y, 1, 1), col)

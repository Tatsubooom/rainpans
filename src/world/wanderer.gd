class_name Wanderer
extends Node2D
## Someone else out there: now and then a small warm light crosses the far
## city, slowly, stopping now and again. Drawn between the sky and the
## nearer layers so buildings hide it as it passes behind them.
##
## Area key "wander": [y, x_from, x_to] in world pixels.

var y := 0.0
var x0 := 0.0
var x1 := 0.0
var _x := 0.0
var _dir := 1.0
var _active := false
var _wait := 0.0
var _pause := 0.0
var _t := 0.0


func setup(a: Dictionary) -> void:
	var w: Array = a.get("wander", [])
	if w.is_empty():
		set_process(false)
		return
	y = w[0]
	x0 = w[1]
	x1 = w[2]
	_wait = randf_range(60.0, 200.0)


func force() -> void:
	_wait = 0.0


func _process(delta: float) -> void:
	_t += delta
	if not _active:
		_wait -= delta
		if _wait <= 0.0:
			_active = true
			_dir = 1.0 if randf() < 0.5 else -1.0
			_x = x0 if _dir > 0.0 else x1
		return
	if _pause > 0.0:
		_pause -= delta
	else:
		_x += _dir * delta * randf_range(2.5, 4.0)
		if randf() < delta * 0.05:
			_pause = randf_range(3.0, 9.0)
	if (_dir > 0.0 and _x > x1) or (_dir < 0.0 and _x < x0):
		_active = false
		_wait = randf_range(180.0, 480.0)
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	# A lantern carried at walking pace: slight bob and a flickering glow.
	var bob := floorf(sin(_t * 5.0) * 0.6 + 0.5) if _pause <= 0.0 else 0.0
	var p := Vector2(floorf(_x), y + bob)
	var f := 0.75 + 0.25 * sin(_t * 13.0) * sin(_t * 3.1)
	for oy in range(-2, 3):
		for ox in range(-2, 3):
			var d := Vector2(ox, oy).length()
			if d < 0.5 or d > 2.3:
				continue
			draw_rect(Rect2(p + Vector2(ox, oy), Vector2.ONE), Color(Pal.LAMP2, 0.4 * f / d))
	draw_rect(Rect2(p, Vector2.ONE), Pal.LAMP1.lerp(Pal.LAMP0, f - 0.75))

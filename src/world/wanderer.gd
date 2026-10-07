class_name Wanderer
extends Node2D
## Nobody is left, but some machines still run: now and then the lights of
## an old maintenance robot cross the far city at a steady crawl, stopping
## to blink at something before moving on. Drawn between the sky and the
## nearer layers so buildings hide it as it passes behind them.
##
## Area key "wander": [y, x_from, x_to] in world pixels.

const WORK_LIGHT := Color("dfe8e6")
const STATUS := Color("6fe08a")
const STATUS_DIM := Color("2f6a45")

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
		# A machine's pace: slow and perfectly even.
		_x += _dir * delta * 3.0
		if randf() < delta * 0.04:
			_pause = randf_range(4.0, 10.0)
	if (_dir > 0.0 and _x > x1) or (_dir < 0.0 and _x < x0):
		_active = false
		_wait = randf_range(180.0, 480.0)
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var p := Vector2(floorf(_x), y)
	# Pale work light, steady, with a faint cold glow.
	for oy in range(-2, 3):
		for ox in range(-2, 3):
			var d := Vector2(ox, oy).length()
			if d < 0.5 or d > 2.3:
				continue
			draw_rect(Rect2(p + Vector2(ox, oy), Vector2.ONE), Color(WORK_LIGHT, 0.22 / d))
	draw_rect(Rect2(p, Vector2.ONE), WORK_LIGHT)
	# Status lamp just behind it: a regular blink, faster while it works.
	var period := 0.6 if _pause > 0.0 else 1.4
	var on := fmod(_t, period) < period * 0.3
	draw_rect(Rect2(p + Vector2(-2.0 * _dir, -1), Vector2.ONE), STATUS if on else STATUS_DIM)

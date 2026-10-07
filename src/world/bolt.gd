class_name Bolt
extends Node2D
## A close lightning strike: a jagged pixel bolt with a couple of forks,
## drawn behind the nearer layers so it comes down somewhere in the ruins.
## Shows for a moment, dies, re-strikes once, then fades.

const CORE := Color("f4f8ff")
const GLOW := Color("9fb6ff")

var _paths: Array = [] # Array of PackedVector2Array
var _t := 1.0


func strike(x: float, ground_y: float) -> void:
	_paths.clear()
	var main := _jag(Vector2(x + randf_range(-40.0, 40.0), -4.0), Vector2(x, ground_y), 9.0)
	_paths.append(main)
	for i in randi_range(2, 3):
		var from: Vector2 = main[randi_range(2, main.size() / 2)]
		var to := from + Vector2(randf_range(-70.0, 70.0), randf_range(30.0, 70.0))
		_paths.append(_jag(from, to, 6.0))
	_t = 0.0
	visible = true


func active() -> bool:
	return _t < 0.6


func _jag(a: Vector2, b: Vector2, wander: float) -> PackedVector2Array:
	var pts := PackedVector2Array([a])
	var n := int(a.distance_to(b) / 10.0) + 2
	for i in range(1, n):
		var p := a.lerp(b, float(i) / n)
		p.x += randf_range(-wander, wander)
		pts.append(p.floor())
	pts.append(b)
	return pts


func _process(delta: float) -> void:
	if _t >= 0.6:
		visible = false
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	# Lit, dark, lit again, then a dimming afterimage.
	var on := _t < 0.09 or (_t > 0.16 and _t < 0.26)
	var after := _t >= 0.26 and _t < 0.6
	if not on and not after:
		return
	var a := 1.0 if on else 0.5 * (1.0 - (_t - 0.26) / 0.34)
	for j in _paths.size():
		var pts: PackedVector2Array = _paths[j]
		var fork := j > 0
		for i in pts.size() - 1:
			_seg(pts[i], pts[i + 1], fork, a)


## Bresenham with a two-pixel core on the trunk and a dim halo either side.
func _seg(p0: Vector2, p1: Vector2, fork: bool, a: float) -> void:
	var x0 := int(p0.x)
	var y0 := int(p0.y)
	var x1 := int(p1.x)
	var y1 := int(p1.y)
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		if not fork:
			draw_rect(Rect2(x0 - 2, y0, 5, 1), Color(GLOW, 0.22 * a))
			draw_rect(Rect2(x0, y0, 2, 1), Color(CORE, a))
		else:
			draw_rect(Rect2(x0 - 1, y0, 3, 1), Color(GLOW, 0.18 * a))
			draw_rect(Rect2(x0, y0, 1, 1), Color(GLOW.lerp(CORE, 0.5), a))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

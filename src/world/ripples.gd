class_name Ripples
extends Node2D
## Rings spreading over puddles. Drawn between the floor and the drums.

var puddles: Array = []
var lamp := Vector2(-999, -999)
var _rings: Array = [] # [x, y, age, life, big]
var _shimmer := 0.0


func setup(a: Dictionary) -> void:
	puddles = a.puddles
	lamp = a.lamp


func is_puddle(p: Vector2) -> bool:
	for r in puddles:
		var rect: Rect2 = r
		var c := rect.get_center()
		var dx := (p.x - c.x) / (rect.size.x * 0.5)
		var dy := (p.y - c.y) / (rect.size.y * 0.5)
		if dx * dx + dy * dy <= 0.8:
			return true
	return false


func add(p: Vector2, big := false) -> void:
	if _rings.size() > 90:
		return
	_rings.append([floorf(p.x), floorf(p.y), 0.0, 0.9 if big else 0.55, big])


func _process(delta: float) -> void:
	_shimmer += delta
	var i := 0
	while i < _rings.size():
		_rings[i][2] += delta
		if _rings[i][2] >= _rings[i][3]:
			_rings.remove_at(i)
		else:
			i += 1
	queue_redraw()


func _draw() -> void:
	for r in _rings:
		var t: float = r[2] / r[3]
		var rx: float = (2.0 + t * (9.0 if r[4] else 6.0))
		var ry := maxf(1.0, rx * 0.3)
		var col := Pal.RAIN if t < 0.5 else Pal.FOG1
		var near_lamp := Vector2(r[0], r[1]).distance_to(lamp) < 60.0
		if near_lamp and t < 0.6:
			col = Pal.LAMP2
		# Pixel ellipse outline, sparse so it reads as a thin ring.
		var steps := int(rx * 4.0)
		for k in steps:
			var a := TAU * k / steps
			var px := Vector2(roundf(r[0] + cos(a) * rx), roundf(r[1] + sin(a) * ry))
			if is_puddle(px):
				draw_rect(Rect2(px, Vector2.ONE), col)
	# Lamp glints on puddle surfaces, slowly shimmering.
	for pr in puddles:
		var rect: Rect2 = pr
		var c := rect.get_center()
		if c.distance_to(lamp) > 140.0:
			continue
		for k in 3:
			var gx := floorf(c.x + (lamp.x - c.x) * 0.08 + sin(_shimmer * 1.3 + k * 2.1) * rect.size.x * 0.18)
			var gy := floorf(rect.position.y + 1.0 + k * 1.0)
			if is_puddle(Vector2(gx, gy)):
				draw_rect(Rect2(gx, gy, 2 if k == 0 else 1, 1), Pal.LAMP3 if k > 0 else Pal.LAMP2)

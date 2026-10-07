class_name Ripples
extends Node2D
## Rings spreading over puddles. Drawn between the floor and the drums.

var puddles: Array = []
var lamp := Vector2(-999, -999)
var _rings: Array = [] # [x, y, age, life, big]
## Classic pixel splash crowns where drops hit dry floor (4 phases):
## a 2px dash, a 4px ring, two flying dots, gone.
var _crowns: Array = [] # [x, y, age, lit]
const CROWN_LIFE := 0.2
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


func crown(p: Vector2, lit: bool) -> void:
	if _crowns.size() < 120:
		_crowns.append([floorf(p.x), floorf(p.y), 0.0, lit])


func _process(delta: float) -> void:
	_shimmer += delta
	var c := 0
	while c < _crowns.size():
		_crowns[c][2] += delta
		if _crowns[c][2] >= CROWN_LIFE:
			_crowns.remove_at(c)
		else:
			c += 1
	var i := 0
	while i < _rings.size():
		_rings[i][2] += delta
		if _rings[i][2] >= _rings[i][3]:
			_rings.remove_at(i)
		else:
			i += 1
	queue_redraw()


func _draw() -> void:
	for cr in _crowns:
		var phase := int(cr[2] / CROWN_LIFE * 4.0)
		var x: float = cr[0]
		var y: float = cr[1]
		var col := Pal.LAMP2 if cr[3] else Pal.RAIN
		var hi := Pal.LAMP1 if cr[3] else Pal.RAIN_HI
		match phase:
			0:
				draw_rect(Rect2(x - 1, y, 2, 1), hi)
			1:
				draw_rect(Rect2(x - 2, y, 1, 1), col)
				draw_rect(Rect2(x + 1, y, 1, 1), col)
				draw_rect(Rect2(x - 1, y - 1, 2, 1), hi)
			2:
				draw_rect(Rect2(x - 3, y - 2, 1, 1), col)
				draw_rect(Rect2(x + 2, y - 2, 1, 1), col)
	for r in _rings:
		var t: float = r[2] / r[3]
		var rx: float = (4.0 + t * (18.0 if r[4] else 12.0))
		var ry := maxf(1.0, rx * 0.28)
		var col := Pal.RAIN if t < 0.5 else Pal.FOG1
		var near_lamp := Vector2(r[0], r[1]).distance_to(lamp) < 120.0
		if near_lamp and t < 0.6:
			col = Pal.LAMP2
		# Clean pixel ellipse: one point above and below per column; the
		# front (lower) arc is brighter, the back arc fades sooner.
		var irx := int(rx)
		for dx in range(-irx, irx + 1):
			var f := 1.0 - pow(dx / rx, 2.0)
			var dy := roundf(ry * sqrt(maxf(0.0, f)))
			var top := Vector2(r[0] + dx, r[1] - dy)
			var bot := Vector2(r[0] + dx, r[1] + dy)
			if t < 0.7 and is_puddle(top):
				draw_rect(Rect2(top, Vector2.ONE), col)
			if dy > 0.0 and is_puddle(bot):
				draw_rect(Rect2(bot, Vector2.ONE), col)
	# Lamp glints on puddle surfaces, slowly shimmering.
	for pr in puddles:
		var rect: Rect2 = pr
		var c := rect.get_center()
		if c.distance_to(lamp) > 280.0:
			continue
		for k in 3:
			var gx := floorf(c.x + (lamp.x - c.x) * 0.08 + sin(_shimmer * 1.3 + k * 2.1) * rect.size.x * 0.18)
			var gy := floorf(rect.position.y + 2.0 + k * 2.0)
			if is_puddle(Vector2(gx, gy)):
				draw_rect(Rect2(gx, gy, 4 if k == 0 else 2, 1), Pal.LAMP3 if k > 0 else Pal.LAMP2)

class_name EnvAnim
extends Node2D
## Small moving details per area: blinking lights, run-off trickles in heavy
## rain, weeds bending in the wind, a flickering window.
##
## Area keys used:
##   "blinks":   [[Vector2 pos, Color, period_sec, on_fraction], ...]
##   "trickles": [[Vector2 top, bottom_y], ...]   (only in heavier rain)
##   "weeds":    [[Vector2 base, height], ...]
##   "flicker":  [Rect2, ...]  window rects that sometimes stutter

var blinks: Array = []
var trickles: Array = []
var weeds: Array = []
var flicker: Array = []
var roof: PackedFloat32Array = PackedFloat32Array()
var broken: Array = []
var _streaks: Array = [] # [x, speed] water running down the glass
var wind := 0.0
var rain_level := 0.0
var _t := 0.0
var _flick_t := 0.0
var _flick_on := false
var _rng := RandomNumberGenerator.new()


func setup(a: Dictionary) -> void:
	blinks = a.get("blinks", [])
	trickles = a.get("trickles", [])
	weeds = a.get("weeds", [])
	flicker = a.get("flicker", [])
	roof = a.get("roof_profile", PackedFloat32Array())
	broken = a.get("broken", [])
	_rng.randomize()
	_streaks.clear()
	if not roof.is_empty():
		for i in 26:
			_streaks.append([_rng.randf_range(0.0, 640.0), _rng.randf_range(8.0, 24.0)])


func _process(delta: float) -> void:
	_t += delta
	for st in _streaks:
		# Water slides away from the ridge toward the eaves, faster lower down.
		var dir := 1.0 if st[0] >= 320.0 else -1.0
		st[0] += dir * st[1] * delta * (0.6 + absf(st[0] - 320.0) / 240.0)
		if st[0] < 0.0 or st[0] >= 640.0:
			st[0] = 320.0 + _rng.randf_range(-80.0, 80.0)
			st[1] = _rng.randf_range(8.0, 24.0)
	_flick_t -= delta
	if _flick_t <= 0.0:
		# Mostly steady; now and then a short stutter.
		_flick_on = not _flick_on if _rng.randf() < 0.5 else false
		_flick_t = _rng.randf_range(0.05, 0.18) if _flick_on else _rng.randf_range(3.0, 9.0)
	queue_redraw()


func _draw() -> void:
	for b in blinks:
		var period: float = b[2]
		var on: bool = fmod(_t, period) < period * float(b[3])
		var p: Vector2 = b[0]
		if on:
			# A bright core with a soft glow around it (Noita-style bloom).
			for oy in range(-3, 4):
				for ox in range(-3, 4):
					var d := Vector2(ox, oy).length()
					if d < 0.5 or d > 3.2:
						continue
					draw_rect(Rect2(p + Vector2(ox, oy), Vector2.ONE), Color(b[1], 0.42 / (d * d)))
			draw_rect(Rect2(p, Vector2(2, 2)), Color(b[1]).lightened(0.35))
		else:
			draw_rect(Rect2(p, Vector2.ONE), Color(b[1], 0.25))

	if rain_level > 0.45:
		var strength := clampf((rain_level - 0.45) / 0.4, 0.0, 1.0)
		for tr in trickles:
			var top: Vector2 = tr[0]
			var bottom: float = tr[1]
			var y := top.y
			while y < bottom:
				# A broken stream: segments flicker as water bunches up.
				var seg := int(y + _t * 180.0) % 7
				if seg < 4 + int(strength * 3.0):
					var dx := floorf(sin(y * 0.15 + _t * 4.0) * 1.2 + wind * (y - top.y) * 0.3)
					draw_rect(Rect2(top.x + dx, y, 1, 1), Pal.RAIN if seg % 3 else Pal.RAIN_HI)
				y += 1.0
			# Splash where it lands.
			if int(_t * 12.0) % 2 == 0:
				draw_rect(Rect2(top.x - 3, bottom - 1, 7, 1), Pal.RAIN)
				draw_rect(Rect2(top.x + (2 if int(_t * 7.0) % 2 else -3), bottom - 3, 1, 2), Pal.RAIN_HI)

	for w in weeds:
		var base: Vector2 = w[0]
		var h: int = w[1]
		for k in h:
			# Tip bends most; gusts push everything the same way.
			var bend := (float(k) / h) * (wind * -36.0 + sin(_t * 1.7 + base.x) * 1.6)
			var col := Pal.MOSS2 if k < h - 2 else Pal.MOSS3
			draw_rect(Rect2(floorf(base.x + bend), base.y - k, 1, 1), col)

	for st in _streaks:
		var x := int(st[0])
		var on_glass := true
		for b in broken:
			if x >= b[0] and x < b[1]:
				on_glass = false
		if not on_glass or x < 0 or x >= roof.size():
			continue
		var y := floorf(roof[x]) + 1.0
		draw_rect(Rect2(x, y, 1, 1), Pal.RAIN_HI)
		var back := -1 if st[0] >= 320.0 else 1
		if x + back >= 0 and x + back < roof.size():
			draw_rect(Rect2(x + back, floorf(roof[x + back]) + 1.0, 1, 1), Pal.RAIN)

	if _flick_on:
		for r in flicker:
			draw_rect(r, Color(Pal.INK, 0.55))

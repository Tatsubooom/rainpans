class_name Rain
extends Node2D
## Rain, splashes and drips. The near layer is the gameplay layer: every drop
## carries a depth (the floor y it will land on) so it can strike drums that
## stand at that depth, giving the 2.5D rooftop a believable hit test.

signal landed(pos: Vector2, puddle: bool)

const FAR := 0
const NEAR := 1

var layer := NEAR
var area: Dictionary
var drums: Array = [] # Array[Drum], kept by Stage
var ripples: Ripples
var wind := -0.08 # horizontal drift per unit of fall
var rate := 30.0 # drops per second
var drip_rate := 0.0 # drips per second per open drip point
var drip_points := 0
var lamp := Vector2(-999, -999)
var lamp_radius := 46.0
var flash := 0.0 # lightning brightness 0..1

# drop arrays (struct-of-arrays for speed)
var _x := PackedFloat32Array()
var _y := PackedFloat32Array()
var _vy := PackedFloat32Array()
var _depth := PackedFloat32Array()
var _len := PackedFloat32Array()
var _drip := PackedByteArray()

# splash particles
var _sx := PackedFloat32Array()
var _sy := PackedFloat32Array()
var _svx := PackedFloat32Array()
var _svy := PackedFloat32Array()
var _sl := PackedFloat32Array()

var _spawn_acc := 0.0
var _drip_acc := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_process(true)


func setup(a: Dictionary, which: int) -> void:
	area = a
	layer = which
	lamp = a.lamp
	var drips: Array = a.drips
	_drip_acc.resize(drips.size())
	for i in drips.size():
		_drip_acc[i] = _rng.randf()
	# Pre-fill the sky so the first frame is already raining.
	for i in int(rate * 1.2):
		_spawn(_rng.randf_range(0.0, 180.0))


func _spawn(y: float = -8.0) -> void:
	var floor_rect: Rect2 = area.floor
	var x := _rng.randf_range(-20.0, 340.0)
	# Some areas only let rain in through an opening.
	var key := "far_rain_rect" if layer == FAR else "rain_rect"
	if area.has(key):
		var r: Rect2 = area[key]
		x = _rng.randf_range(r.position.x, r.end.x)
		y = maxf(y, r.position.y)
	var depth: float
	var speed: float
	var ln: float
	if layer == FAR:
		depth = _rng.randf_range(110.0, 132.0)
		if area.has("far_rain_rect"):
			depth = (area.far_rain_rect as Rect2).end.y
		speed = _rng.randf_range(150.0, 190.0)
		ln = _rng.randf_range(2.0, 4.0)
	else:
		depth = _rng.randf_range(floor_rect.position.y - 4.0, floor_rect.end.y + 4.0)
		speed = _rng.randf_range(250.0, 320.0) * (0.85 + 0.3 * (depth - 130.0) / 50.0)
		ln = 4.0 + (depth - 130.0) / 14.0
	_x.append(x)
	_y.append(y)
	_vy.append(speed)
	_depth.append(depth)
	_len.append(ln)
	_drip.append(0)


func _spawn_drip(p: Vector2) -> void:
	_x.append(p.x + _rng.randf_range(-0.4, 0.4))
	_y.append(p.y)
	_vy.append(40.0)
	# The lip of the overhang projects onto a fixed band of the floor.
	_depth.append(float(area.get("drip_depth", 152.0)) + _rng.randf_range(-1.5, 1.5))
	_len.append(2.0)
	_drip.append(1)


func _process(delta: float) -> void:
	_spawn_acc += rate * delta
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		_spawn()
	if layer == NEAR and drip_rate > 0.0:
		var pts: Array = area.drips
		for i in mini(drip_points, pts.size()):
			# Each drip point has its own slightly different period.
			_drip_acc[i] += delta * drip_rate * (0.8 + 0.07 * i)
			if _drip_acc[i] >= 1.0:
				_drip_acc[i] = 0.0
				_spawn_drip(pts[i])

	var shelters: Array = area.shelters
	var i := 0
	while i < _x.size():
		var y0 := _y[i]
		var is_drip := _drip[i] == 1
		if is_drip:
			_vy[i] = minf(_vy[i] + 900.0 * delta, 330.0)
		var y1 := y0 + _vy[i] * delta
		var x := _x[i] + (0.0 if is_drip else wind * (y1 - y0))
		_x[i] = x
		_y[i] = y1
		var dead := false
		if layer == NEAR:
			# Sheltered: stops on the roof above.
			if not is_drip:
				for s in shelters:
					var r: Rect2 = s
					if x >= r.position.x and x < r.end.x and y1 >= r.end.y - 4.0 and y0 < r.end.y:
						if _rng.randf() < 0.25:
							_splash(Vector2(x, r.end.y - 6.0), 1, 0.5)
						dead = true
						break
			if not dead:
				for d in drums:
					if d.try_catch(x, y0, y1, _depth[i], 1.0 if is_drip else _vy[i] / 320.0):
						_splash(Vector2(x, d.surface_y()), 2 if not is_drip else 3, 0.8)
						dead = true
						break
			if not dead and y1 >= _depth[i]:
				var p := Vector2(x, _depth[i])
				var in_puddle := ripples != null and ripples.is_puddle(p)
				if in_puddle:
					ripples.add(p, is_drip)
				else:
					_splash(p, 1 if _rng.randf() < 0.6 else 2, 0.6)
				landed.emit(p, in_puddle)
				dead = true
		elif y1 >= _depth[i]:
			dead = true
		if dead or x < -40.0 or x > 360.0:
			_remove(i)
		else:
			i += 1

	var j := 0
	while j < _sx.size():
		_svy[j] += 260.0 * delta
		_sx[j] += _svx[j] * delta
		_sy[j] += _svy[j] * delta
		_sl[j] -= delta
		if _sl[j] <= 0.0:
			_remove_splash(j)
		else:
			j += 1
	queue_redraw()


func _remove(i: int) -> void:
	var last := _x.size() - 1
	_x[i] = _x[last]; _y[i] = _y[last]; _vy[i] = _vy[last]
	_depth[i] = _depth[last]; _len[i] = _len[last]; _drip[i] = _drip[last]
	_x.resize(last); _y.resize(last); _vy.resize(last)
	_depth.resize(last); _len.resize(last); _drip.resize(last)


func _remove_splash(j: int) -> void:
	var last := _sx.size() - 1
	_sx[j] = _sx[last]; _sy[j] = _sy[last]; _svx[j] = _svx[last]
	_svy[j] = _svy[last]; _sl[j] = _sl[last]
	_sx.resize(last); _sy.resize(last); _svx.resize(last)
	_svy.resize(last); _sl.resize(last)


func _splash(p: Vector2, count: int, strength: float) -> void:
	for k in count:
		_sx.append(p.x)
		_sy.append(p.y - 1.0)
		_svx.append(_rng.randf_range(-28.0, 28.0) * strength)
		_svy.append(-_rng.randf_range(30.0, 70.0) * strength)
		_sl.append(_rng.randf_range(0.12, 0.28))


func _lit(p: Vector2) -> float:
	var d := p.distance_to(lamp)
	return clampf(1.0 - d / lamp_radius, 0.0, 1.0)


func _draw() -> void:
	var base := Pal.FOG0 if layer == FAR else Pal.RAIN
	var hi := Pal.FOG1 if layer == FAR else Pal.RAIN_HI
	if flash > 0.0:
		base = base.lerp(Pal.RAIN_HI, flash)
	for i in _x.size():
		var x := floorf(_x[i]) + 0.5
		var y := floorf(_y[i])
		var ln := _len[i]
		var col := base
		if layer == NEAR:
			var l := _lit(Vector2(x, y))
			if l > 0.0:
				# Drops passing the lantern catch its warm light.
				col = Pal.LAMP1 if l > 0.55 else (Pal.LAMP2 if l > 0.25 else base.lerp(Pal.LAMP3, 0.5))
			elif ln > 6.0 and (int(_x[i] * 7.0) % 5) == 0:
				col = hi
		if _drip[i] == 1:
			draw_rect(Rect2(floorf(_x[i]), y, 1, 2), col if col != base else Pal.RAIN_HI)
			continue
		# A slanted 1px streak, drawn pixel-snapped.
		var dx := -wind * ln
		draw_line(Vector2(x + dx, y - ln), Vector2(x, y), col, -1.0)
	for j in _sx.size():
		var p := Vector2(floorf(_sx[j]), floorf(_sy[j]))
		var c := Pal.RAIN_HI if _lit(p) == 0.0 else Pal.LAMP1
		draw_rect(Rect2(p, Vector2.ONE), c)

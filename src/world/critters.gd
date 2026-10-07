class_name Critters
extends Node2D
## Small life: moths circling the lantern, and a crow that sometimes lands on
## the railing to wait out the rain with you.

## Crow frames at full resolution. o ink, 1 blue-black sheen, 2 wet
## highlight, x eye, b beak, f feet.
const CROW_SIT := [
	"....oooo......",
	"...o12ooo.....",
	"..oxo1oooo....",
	".bbooooooo....",
	"...oo11oooo...",
	"...o1122oooo..",
	"...o11222oooo.",
	"....o1111ooooo",
	".....oooooo.oo",
	"......f..f....",
	"......f..f....",
]
const CROW_PECK := [
	"..............",
	"..............",
	"....oooo......",
	"...o12oooooo..",
	"..oxo11222ooo.",
	".bbo111122oooo",
	"bb.oo1111ooooo",
	".....ooooooo.o",
	"......o..o....",
	"......f..f....",
	"......f..f....",
]
const CROW_FLY_A := [
	"1o..........o1",
	".1o........o1.",
	"..1oo....oo1..",
	"...oooooooo...",
	"..oxooooooooo.",
	".bbooo1122ooo.",
	".....ooooo....",
	"..............",
	"..............",
	"..............",
	"..............",
]
const CROW_FLY_B := [
	"..............",
	"..............",
	"..............",
	"....oooooo....",
	"..oxooooooooo.",
	".bbooo1122ooo.",
	"..1oooooooo1..",
	".1oo......oo1.",
	"1o..........o1",
	"..............",
	"..............",
]

var lamp := Vector2(-999, -999)
var perches: Array = []
var _moths: Array = [] # [angle, radius, speed, phase]
## Fireflies (areas with "fireflies": n inside "firefly_rect") and dust motes
## drifting through the lamplight.
var _flies: Array = [] # [pos, vel, phase]
var _fly_rect := Rect2()
var _motes: Array = [] # [offset, vel, phase]
var _crow_state := "away" # away, in, sit, out
var _crow_pos := Vector2.ZERO
var _crow_target := Vector2.ZERO
var _crow_t := 0.0
var _crow_wait := 30.0
var _crow_flip := false
var _peck := 0.0
var _t := 0.0
var _tex := {}


func setup(a: Dictionary) -> void:
	lamp = a.lamp
	perches = a.get("perches", [])
	_moths.clear()
	_flies.clear()
	_motes.clear()
	_fly_rect = a.get("firefly_rect", Rect2())
	for i in int(a.get("fireflies", 0)):
		var p := _fly_rect.position + Vector2(randf() * _fly_rect.size.x, randf() * _fly_rect.size.y)
		_flies.append([p, Vector2(randf_range(-6, 6), randf_range(-4, 4)), randf() * TAU])
	for i in 16:
		_motes.append([Vector2(randf_range(-60, 60), randf_range(-40, 50)), Vector2(randf_range(-3, 3), randf_range(1, 5)), randf() * TAU])
	for i in 3:
		_moths.append([randf() * TAU, randf_range(10.0, 22.0), randf_range(1.5, 3.2), randf() * 10.0])
	var key := {"o": Pal.INK, "x": Pal.FOG2, "b": Pal.CON4, "1": Pal.NIGHT3, "2": Pal.FOG0, "f": Pal.CON3}
	for k in ["sit", "peck", "fa", "fb"]:
		var rows: Array = {"sit": CROW_SIT, "peck": CROW_PECK, "fa": CROW_FLY_A, "fb": CROW_FLY_B}[k]
		_tex[k] = ImageTexture.create_from_image(PixCanvas.grid(rows, key))
	_crow_wait = randf_range(20.0, 60.0)


func _process(delta: float) -> void:
	_t += delta
	for f in _flies:
		# Lazy wandering: steer randomly, stay inside the planted area.
		f[1] += Vector2(randf_range(-20, 20), randf_range(-16, 16)) * delta
		f[1] = (f[1] as Vector2).limit_length(9.0)
		f[0] += f[1] * delta
		if not _fly_rect.has_point(f[0]):
			f[1] = ((_fly_rect.get_center() - f[0]) as Vector2).normalized() * 6.0
	for m in _motes:
		m[0] += m[1] * delta
		if (m[0] as Vector2).y > 56.0 or absf(m[0].x) > 66.0:
			m[0] = Vector2(randf_range(-60, 60), -40.0)
	_crow_step(delta)
	queue_redraw()


func _crow_step(delta: float) -> void:
	if perches.is_empty():
		return
	match _crow_state:
		"away":
			_crow_wait -= delta
			if _crow_wait <= 0.0:
				_crow_target = perches[randi() % perches.size()]
				var from_left := randf() < 0.5
				_crow_pos = Vector2(-20.0 if from_left else 660.0, _crow_target.y - randf_range(80.0, 140.0))
				_crow_flip = not from_left
				_crow_state = "in"
		"in":
			_crow_pos = _crow_pos.move_toward(_crow_target, delta * 110.0)
			if _crow_pos.distance_to(_crow_target) < 0.5:
				_crow_state = "sit"
				_crow_t = randf_range(18.0, 45.0)
		"sit":
			_crow_t -= delta
			_peck = maxf(0.0, _peck - delta)
			if randf() < delta * 0.25:
				_peck = 0.35
			if randf() < delta * 0.08:
				_crow_flip = not _crow_flip
			if _crow_t <= 0.0:
				_crow_state = "out"
				_crow_flip = randf() < 0.5
		"out":
			var dir := Vector2(-1.0 if _crow_flip else 1.0, -0.55)
			_crow_pos += dir * delta * 120.0
			if _crow_pos.x < -40.0 or _crow_pos.x > 680.0 or _crow_pos.y < -40.0:
				_crow_state = "away"
				_crow_wait = randf_range(60.0, 180.0)


func _draw() -> void:
	# Fireflies: slow green-gold blinks with a soft cross of glow.
	for f in _flies:
		var lit := 0.5 + 0.5 * sin(_t * 1.6 + f[2])
		if lit < 0.35:
			continue
		var p := (f[0] as Vector2).floor()
		var col := Color("d8f58a") if lit > 0.75 else Color("8fbf5a")
		draw_rect(Rect2(p, Vector2.ONE), col)
		if lit > 0.7:
			for o in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				draw_rect(Rect2(p + o, Vector2.ONE), Color(col, 0.35))
	# Dust and spray hanging in the lamplight, only visible where it is lit.
	for m in _motes:
		var off: Vector2 = m[0]
		var d := off.length() / 70.0
		if d > 1.0:
			continue
		var tw := 0.5 + 0.5 * sin(_t * 3.0 + m[2])
		if tw < 0.3:
			continue
		var c := Pal.LAMP1 if d < 0.45 else Pal.LAMP3
		draw_rect(Rect2((lamp + off).floor(), Vector2.ONE), Color(c, 0.4 + 0.5 * (1.0 - d) * tw))
	# Moths: erratic little orbits, lit warm on the lamp side.
	for m in _moths:
		var a: float = m[0] + _t * m[2]
		var r: float = m[1] + sin(_t * 2.3 + m[3]) * 3.0
		var p := lamp + Vector2(cos(a) * r, sin(a * 1.3) * r * 0.6 - 2.0)
		p += Vector2(sin(_t * 9.0 + m[3]) * 1.2, cos(_t * 7.0 + m[3]) * 1.0)
		p = p.floor()
		var flap := int(_t * 18.0 + m[3]) % 2 == 0
		draw_rect(Rect2(p, Vector2.ONE), Pal.LAMP0)
		if flap:
			draw_rect(Rect2(p + Vector2(-1, 0), Vector2.ONE), Pal.LAMP2)
			draw_rect(Rect2(p + Vector2(1, 0), Vector2.ONE), Pal.LAMP2)
	if _crow_state == "away" or _tex.is_empty():
		return
	var key := "sit"
	if _crow_state == "in" or _crow_state == "out":
		key = "fa" if int(_t * 8.0) % 2 == 0 else "fb"
	elif _peck > 0.0:
		key = "peck"
	var tex: ImageTexture = _tex[key]
	var pos := (_crow_pos - Vector2(7, 11)).floor()
	if _crow_flip:
		draw_texture_rect(tex, Rect2(pos + Vector2(tex.get_width(), 0), Vector2(-tex.get_width(), tex.get_height())), false)
	else:
		draw_texture_rect(tex, Rect2(pos, tex.get_size()), false)


## Screenshot helper: put the crow on its first perch right away.
func debug_sit() -> void:
	if perches.is_empty():
		return
	_crow_pos = perches[0]
	_crow_state = "sit"
	_crow_t = 999.0

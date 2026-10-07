class_name Critters
extends Node2D
## Small life: moths circling the lantern, and a crow that sometimes lands on
## the railing to wait out the rain with you.

const CROW_SIT := [
	"..oo...",
	".oxoo..",
	"o1oooob",
	"o11ooo.",
	".o1oo..",
	"..o.o..",
]
const CROW_PECK := [
	".......",
	"..oo...",
	".o1ooo.",
	"bxo11oo",
	"..oooo.",
	"..o.o..",
]
const CROW_FLY_A := [
	"1.....1",
	".o...o.",
	"..ooo..",
	"..oxob.",
	".......",
	".......",
]
const CROW_FLY_B := [
	".......",
	"..ooo..",
	"1ooxoob",
	".......",
	".......",
	".......",
]

var lamp := Vector2(-999, -999)
var perches: Array = []
var _moths: Array = [] # [angle, radius, speed, phase]
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
	for i in 3:
		_moths.append([randf() * TAU, randf_range(10.0, 22.0), randf_range(1.5, 3.2), randf() * 10.0])
	var key := {"o": Pal.INK, "x": Pal.FOG2, "b": Pal.CON4, "1": Pal.NIGHT4}
	for k in ["sit", "peck", "fa", "fb"]:
		var rows: Array = {"sit": CROW_SIT, "peck": CROW_PECK, "fa": CROW_FLY_A, "fb": CROW_FLY_B}[k]
		var img := PixCanvas.grid(rows, key)
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		_tex[k] = ImageTexture.create_from_image(img)
	_crow_wait = randf_range(20.0, 60.0)


func _process(delta: float) -> void:
	_t += delta
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
	var pos := (_crow_pos - Vector2(6, 12)).floor()
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

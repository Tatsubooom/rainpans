class_name Visitor
extends Node2D
## One passing visitor. Origin is the middle of its feet on the floor, so the
## y-sorted drum layer orders it against the drums. Walks in from a side,
## stops by a drum (or anywhere), idles in its own way, then walks off.
##
## Frames face right; o ink, 1 body, 2 sheen, 3 dark detail, e eye / lens,
## s status lamp, l leg, b beak, a antler, w pale rump.

const CAT := {
	"walk_a": [
		"................2..2",
		"................1221",
		".o.............o1e1o",
		"o1o............o111o",
		"o1o.oooooooooooo11o.",
		".o1o222222222222oo..",
		"..o11111111111111o..",
		"...o111111111111o...",
		"...o11oo1oooo11o....",
		"...o1o.o1o..o1oo1o..",
		"...oo..oo...oo..oo..",
	],
	"walk_b": [
		"................2..2",
		"................1221",
		"o..............o1e1o",
		"o1o............o111o",
		".o1oooooooooooo11o..",
		"..o1222222222222oo..",
		"..o11111111111111o..",
		"...o111111111111o...",
		"...o11o11ooo11o1o...",
		"....o1oo1o..o1oo1o..",
		"....oo.oo...oo..oo..",
	],
	"sit": [
		"........2...2.",
		"........12.21.",
		"........o111o.",
		"........o1e1o.",
		"........o111o.",
		".......o2111o.",
		"......o22111o.",
		".....o221111o.",
		"....o2211111o.",
		"....o2111111o.",
		"...o22111111o.",
		"...o211o1111o.",
		"o..o111o1o11o.",
		".ooooooooooooo",
	],
	"sit_b": [
		"........2...2.",
		"........12.21.",
		"........o111o.",
		"........o111o.",
		"........o111o.",
		".......o2111o.",
		"......o22111o.",
		".....o221111o.",
		"....o2211111o.",
		"....o2111111o.",
		"o..o22111111o.",
		"o1.o211o1111o.",
		".o1o111o1o11o.",
		"..oooooooooooo",
	],
}

const ROBOT := {
	"walk_a": [
		"......s.........",
		"......o.........",
		"..oooooooooooo..",
		"..o2222222222o..",
		"..o2111111eeoo..",
		"..o2111111eeo...",
		"..o1131111111o..",
		"..o1111111111o..",
		"..oooooooooooo..",
		"....o1o..o1o....",
		".oooooooooooooo.",
		".o3o1o3o1o3o1oo.",
		"..oooooooooooo..",
	],
	"walk_b": [
		"......s.........",
		"......o.........",
		"..oooooooooooo..",
		"..o2222222222o..",
		"..o2111111eeoo..",
		"..o2111111eeo...",
		"..o1131111111o..",
		"..o1111111111o..",
		"..oooooooooooo..",
		"....o1o..o1o....",
		".oooooooooooooo.",
		".oo1o3o1o3o1o3o.",
		"..oooooooooooo..",
	],
	"tap": [
		"......s.............",
		"......o.............",
		"..oooooooooooo......",
		"..o2222222222o......",
		"..o2111111eeoo......",
		"..o2111111eeooooo...",
		"..o113111111o111oo..",
		"..o1111111111ooo1o..",
		"..oooooooooooo..oo..",
		"....o1o..o1o........",
		".oooooooooooooo.....",
		".o3o1o3o1o3o1oo.....",
		"..oooooooooooo......",
	],
}

const HERON := {
	"stand": [
		"......oo........",
		".....o1eobbbb...",
		".....o11o.......",
		"......o1o.......",
		".......o1o......",
		".......o1o......",
		"......o1o.......",
		".....o11o.......",
		"....o2211oo.....",
		"...o222111o.....",
		"..o2222111o.....",
		".o22221111o.....",
		"o2222111111o....",
		".oo1111111o.....",
		"...oo11111o.....",
		".....ooooo......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		".....ll.ll......",
	],
	"dip": [
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"....o2211oo.....",
		"...o222111o1o...",
		"..o2222111oo1o..",
		".o22221111o..o1o.",
		"o2222111111o..oeo",
		".oo1111111o....ob",
		"...oo11111o.....b",
		".....ooooo......b",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		"......l.l.......",
		".....ll.ll......",
	],
	"walk": [
		"......oo........",
		".....o1eobbbb...",
		".....o11o.......",
		"......o1o.......",
		".......o1o......",
		".......o1o......",
		"......o1o.......",
		".....o11o.......",
		"....o2211oo.....",
		"...o222111o.....",
		"..o2222111o.....",
		".o22221111o.....",
		"o2222111111o....",
		".oo1111111o.....",
		"...oo11111o.....",
		".....ooooo......",
		"......l..l......",
		"......l..l......",
		".....l....l.....",
		".....l....l.....",
		".....l....l.....",
		"....l......l....",
		"....l......l....",
		"....l......l....",
		"...ll......ll...",
	],
}

const DEER := {
	"walk_a": [
		"...............a...a..",
		"...............aa.aa..",
		"................aa....",
		"...............oo.o...",
		"..............o11oo...",
		"..............o1e11o..",
		".............o111111o.",
		".............o11ooooo.",
		"............o11o......",
		".oooooooooooo11o......",
		"ow222222222222o.......",
		"ow111111111111o.......",
		".o111111111111o.......",
		"..o1111111111o........",
		"...l..l.....l..l......",
		"...l..l.....l..l......",
		"...l...l...l...l......",
		"..l....l...l....l.....",
		"..l....l...l....l.....",
	],
	"walk_b": [
		"...............a...a..",
		"...............aa.aa..",
		"................aa....",
		"...............oo.o...",
		"..............o11oo...",
		"..............o1e11o..",
		".............o111111o.",
		".............o11ooooo.",
		"............o11o......",
		".oooooooooooo11o......",
		"ow222222222222o.......",
		"ow111111111111o.......",
		".o111111111111o.......",
		"..o1111111111o........",
		"....ll.......ll.......",
		"....ll.......ll.......",
		"...l..l.....l..l......",
		"...l..l.....l..l......",
		"..l...l....l...l......",
	],
	"graze": [
		"......................",
		"......................",
		"......................",
		"......................",
		"......................",
		"......................",
		"......................",
		"......................",
		"......................",
		".oooooooooooooo.......",
		"ow2222222222222o......",
		"ow11111111111111o.....",
		".o111111111111o.o1o...",
		"..o1111111111o...o1o..",
		"...l..l.....l..l..o1oa",
		"...l..l.....l..l..o1eo",
		"...l..l.....l..l...o11o",
		"...l..l.....l..l....ooo",
		"...l..l.....l..l......",
	],
}

const SPEED := {"cat": 28.0, "robot": 12.0, "heron": 16.0, "deer": 22.0}

var kind := "cat"
var stage: Node
var floor_rect := Rect2()
var _frames := {}
var _state := "in" # in, stay, out
var _dir := 1.0
var _target_x := 0.0
var _stay := 0.0
var _t := 0.0
var _act := 0.0 # time left on the current idle action (tap, dip, graze)
var _queue: Array = [] # robot: drums still to check
var _light: PointLight2D
var _anchor := 0.0 # half the width of the base frame


func begin() -> void:
	var src: Dictionary = {"cat": CAT, "robot": ROBOT, "heron": HERON, "deer": DEER}[kind]
	var key := _key()
	for f in src:
		# Drawn on the scenery's 2x grid, smoothed with Scale2x.
		_frames[f] = ImageTexture.create_from_image(PixCanvas.scale2x(PixCanvas.grid(src[f], key)))
	_anchor = floorf((_frames[src.keys()[0]] as ImageTexture).get_width() / 2.0)
	_dir = 1.0 if randf() < 0.5 else -1.0
	var w := float(AreaLibrary.W)
	position = Vector2(-24.0 if _dir > 0.0 else w + 24.0, _pick_y())
	var drums := _drums()
	if kind == "robot":
		# Checks two or three drums, nearest first along its way.
		drums.shuffle()
		_queue = drums.slice(0, mini(3, drums.size()))
		_queue.sort_custom(func(a: Drum, b: Drum): return a.position.x * _dir < b.position.x * _dir)
		_next_robot_target()
		_light = PointLight2D.new()
		_light.texture = EnvFx.light_texture(48, 4)
		_light.color = Color("cfe6e2")
		_light.energy = 0.9
		_light.position = Vector2(18 * _dir, -18)
		add_child(_light)
	elif kind == "cat" and not drums.is_empty():
		var d: Drum = drums[randi() % drums.size()]
		position.y = d.position.y + 1.0
		_target_x = d.position.x - (d.size().x / 2.0 + 18.0) * _dir
	else:
		_target_x = randf_range(w * 0.2, w * 0.8)
	_stay = {"cat": randf_range(25.0, 50.0), "robot": 4.0, "heron": randf_range(30.0, 60.0), "deer": randf_range(20.0, 40.0)}[kind]


## Debug/screenshot: skip the walk in.
func arrive() -> void:
	if _target_x != INF:
		position.x = _target_x
		if kind == "robot" and not _queue.is_empty():
			position.y = (_queue[0] as Drum).position.y + 1.0
	_state = "stay"
	_stay = maxf(_stay, 60.0) if kind != "robot" else 4.0


func _key() -> Dictionary:
	match kind:
		"robot":
			return {"o": Pal.INK, "1": Pal.CON3, "2": Pal.CON4, "3": Pal.RUST2, "e": Color("dfe8e6"), "s": Color("6fe08a")}
		"heron":
			return {"o": Pal.NIGHT1, "1": Pal.FOG1, "2": Pal.FOG2, "e": Pal.LAMP1, "b": Pal.RUST4, "l": Pal.NIGHT1}
		"deer":
			return {"o": Pal.WOOD0, "1": Pal.WOOD2, "2": Pal.WOOD3, "e": Pal.INK, "a": Pal.WOOD3, "l": Pal.WOOD1, "w": Pal.BONE}
	# A grey stray; its eye catches the lamp.
	return {"o": Pal.NIGHT0, "1": Pal.CON4, "2": Pal.CON5, "e": Pal.LAMP1}


func _pick_y() -> float:
	if kind == "heron":
		# Along the water's edge at the front of the walkway.
		return floor_rect.end.y - 4.0
	return randf_range(floor_rect.position.y + 6.0, floor_rect.end.y - 6.0)


func _drums() -> Array:
	var out: Array = []
	for d in stage.rain.drums:
		var dr: Drum = d
		if not dr.ghost:
			out.append(dr)
	return out


func _next_robot_target() -> void:
	while not _queue.is_empty() and not is_instance_valid(_queue[0]):
		_queue.pop_front()
	if _queue.is_empty():
		_target_x = INF
		return
	var d: Drum = _queue[0]
	_target_x = d.position.x - (d.size().x / 2.0 + 22.0) * _dir


func _process(delta: float) -> void:
	_t += delta
	_act = maxf(0.0, _act - delta)
	match _state:
		"in":
			if _target_x == INF:
				_state = "out"
			else:
				var before := position.x
				position.x = move_toward(position.x, _target_x, delta * SPEED[kind])
				if kind == "robot" and not _queue.is_empty():
					# Ease along the floor to the drum's depth as it goes.
					var d: Drum = _queue[0] if is_instance_valid(_queue[0]) else null
					if d:
						position.y = move_toward(position.y, d.position.y + 1.0, delta * 6.0)
				if position.x == _target_x or before == position.x:
					_state = "stay"
		"stay":
			_stay -= delta
			_idle(delta)
			if _stay <= 0.0:
				if kind == "robot" and not _queue.is_empty():
					_queue.pop_front()
					_next_robot_target()
					_stay = 4.0
					_state = "in"
				else:
					_state = "out"
		"out":
			position.x += _dir * delta * SPEED[kind]
			if position.x < -40.0 or position.x > AreaLibrary.W + 40.0:
				queue_free()
	queue_redraw()


func _idle(delta: float) -> void:
	match kind:
		"cat":
			# Once in a while a paw goes out to the drum beside it.
			if _act == 0.0 and randf() < delta * 0.05:
				_act = 0.4
				var d := _near_drum(44.0)
				if d:
					d.strike(0.2, false, true)
		"robot":
			# Two taps per drum, a beat apart, like checking for a crack.
			var d: Drum = _queue[0] if not _queue.is_empty() and is_instance_valid(_queue[0]) else null
			if d and _act == 0.0 and (_stay < 3.2 and _stay > 3.0 or _stay < 1.8 and _stay > 1.6):
				_act = 0.3
				d.strike(0.45, false, true)
		"heron":
			if _act == 0.0 and randf() < delta * 0.12:
				_act = 1.2
				get_tree().create_timer(0.5).timeout.connect(func():
					if is_instance_valid(self) and stage.ripples:
						stage.ripples.add(position + Vector2(30 * _dir, 2), true))
		"deer":
			if _act == 0.0 and randf() < delta * 0.2:
				_act = randf_range(2.0, 5.0)


func _near_drum(reach: float) -> Drum:
	var best: Drum = null
	for d in _drums():
		var dr: Drum = d
		if absf(dr.position.y - position.y) < 14.0 and absf(dr.position.x - position.x) < reach + dr.size().x / 2.0:
			best = dr
	return best


func _frame() -> String:
	var moving := _state != "stay"
	var step := int(_t * (4.0 if kind == "robot" else 6.0)) % 2 == 0
	match kind:
		"cat":
			if moving:
				return "walk_a" if step else "walk_b"
			# Tail flick now and then while sitting.
			return "sit_b" if fmod(_t, 3.1) < 0.4 or _act > 0.0 else "sit"
		"robot":
			if moving:
				return "walk_a" if step else "walk_b"
			return "tap" if _act > 0.0 else "walk_a"
		"heron":
			if moving:
				return "walk" if step else "stand"
			return "dip" if _act > 0.0 else "stand"
		"deer":
			if moving:
				return "walk_a" if step else "walk_b"
			return "graze" if _act > 0.0 else "walk_a"
	return _frames.keys()[0]


func _draw() -> void:
	var tex: ImageTexture = _frames[_frame()]
	var sz := tex.get_size()
	var a := _anchor
	# Soft contact shadow on the wet floor.
	draw_rect(Rect2(-a + 4, -2, a * 2.0 - 8, 3), Color(Pal.NIGHT0, 0.6))
	if _dir < 0.0:
		draw_texture_rect(tex, Rect2(Vector2(a, -sz.y), Vector2(-sz.x, sz.y)), false)
	else:
		draw_texture_rect(tex, Rect2(Vector2(-a, -sz.y), sz), false)
	if kind == "robot":
		# The status lamp blinks faster while it works.
		var period := 0.5 if _state == "stay" else 1.3
		if fmod(_t, period) >= period * 0.35:
			var sx := 12.0 - a if _dir > 0.0 else a - 14.0
			draw_rect(Rect2(sx, -sz.y, 2, 2), Color("2f6a45"))

class_name Drum
extends Node2D
## A placed rain drum. Its origin is the centre of its base on the floor.

signal struck(drum: Drum, amount: float)

const DEPTH_FRONT := 3.0
const DEPTH_BACK := 9.0

var id := ""
var def: Dictionary
var img: Image
var tex: ImageTexture
var degree := 0
var ghost := false # being dragged / previewed
var valid := true # placement preview validity
var hovered := false
var _ring := 0.0
var _wobble := 0.0
var _lit := 0.0
var _hits_recent := 0.0
var _notes: Array = [] # [x, y, age] little glyphs drifting up after a hit
var tune := 0 # player's offset in scale steps (mouse wheel)
var _tune_show := 0.0
var shadow_len := 0.0 # cast away from the lamp along the floor
var shadow_dir := 1.0


func setup(drum_id: String) -> void:
	id = drum_id
	def = DrumDefs.get_def(id)
	img = DrumDefs.make_image(id)
	tex = ImageTexture.create_from_image(img)


## Bakes a warm rim on the edges that face the lamp, stronger when close.
func relight(lamp: Vector2, radius: float, color: Color) -> void:
	var lit := img.duplicate() as Image
	var tl := top_left()
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a == 0.0 or c == Pal.INK:
				continue
			var wp := tl + Vector2(x + 0.5, y + 0.5)
			var to := lamp - wp
			var dist := to.length()
			if dist > radius:
				continue
			var k := 1.0 - dist / radius
			var dir := to / maxf(dist, 0.001)
			var nx := x + int(roundf(dir.x))
			var ny := y + int(roundf(dir.y))
			var open := nx < 0 or ny < 0 or nx >= w or ny >= h
			if not open:
				var n := img.get_pixel(nx, ny)
				open = n.a == 0.0 or n == Pal.INK
			if open:
				# Facing the lamp: banded rim highlight.
				var band := 2 if k > 0.6 else (1 if k > 0.3 else 0)
				var rim: Color = [Pal.LAMP3, Pal.LAMP2, Pal.LAMP1][band]
				lit.set_pixel(x, y, c.lerp(rim, 0.45 + 0.4 * k))
	tex = ImageTexture.create_from_image(lit)
	var d := position.distance_to(lamp)
	shadow_len = floorf(clampf((1.0 - d / (radius * 1.3)) * 14.0, 0.0, 12.0))
	shadow_dir = 1.0 if position.x >= lamp.x else -1.0


func size() -> Vector2i:
	return img.get_size()


func top_left() -> Vector2:
	return Vector2(position.x - floorf(img.get_width() / 2.0), position.y - img.get_height())


## Y of the catching surface (the open top / upper face).
func surface_y() -> float:
	return top_left().y + 2.0


func contains(p: Vector2) -> bool:
	var tl := top_left()
	var local := Vector2i(floori(p.x - tl.x), floori(p.y - tl.y))
	if local.x < 0 or local.y < 0 or local.x >= img.get_width() or local.y >= img.get_height():
		return false
	# Generous: any pixel in the bounding box row band that is opaque nearby.
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var q := local + Vector2i(ox, oy)
			if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
				if img.get_pixelv(q).a > 0.0:
					return true
	return false


## Called by the rain for every drop: does this drop land on us?
func try_catch(x: float, y0: float, y1: float, depth: float, vel: float) -> bool:
	if ghost:
		return false
	if depth < position.y - DEPTH_BACK or depth > position.y + DEPTH_FRONT:
		return false
	var tl := top_left()
	var lid: Array = def.lid
	if x < tl.x + lid[0] or x >= tl.x + lid[1] + 1:
		return false
	var sy := surface_y()
	if y1 < sy or y0 > sy + 3.0:
		return false
	strike(vel)
	return true


## `by_hand`: struck by the player rather than the rain (always shows a
## note glyph, earns a little less so the rain stays the main source).
func strike(vel: float, by_hand := false) -> void:
	var v := vel if by_hand else vel * randf_range(0.6, 1.0)
	var played: bool = Synth.play(id, degree, global_position, v, get_instance_id(), by_hand)
	_ring = 1.0
	_wobble = 1.0
	_hits_recent += 1.0
	var amount: float = Game.earn(def.yield * (0.6 if by_hand else 1.0))
	if played and (by_hand or randf() < 0.3) and _notes.size() < 3:
		_notes.append([randf_range(-3.0, 3.0), -img.get_height() - 3.0, 0.0])
	struck.emit(self, amount)


func _process(delta: float) -> void:
	_ring = maxf(0.0, _ring - delta * 3.0)
	_tune_show = maxf(0.0, _tune_show - delta)
	_wobble = maxf(0.0, _wobble - delta * 8.0)
	_hits_recent = maxf(0.0, _hits_recent - delta * 0.8)
	var i := 0
	while i < _notes.size():
		var n: Array = _notes[i]
		n[2] += delta
		n[1] -= delta * 7.0
		n[0] += sin(n[2] * 3.0) * delta * 3.0
		if n[2] > 1.6:
			_notes.remove_at(i)
		else:
			i += 1
	queue_redraw()


func _draw() -> void:
	var tl := top_left() - position
	var w := img.get_width()
	var h := img.get_height()
	if not ghost:
		# Contact shadow and a wet dark ring on the floor.
		var sw := w + 2
		for x in range(-sw / 2, sw / 2 + 1):
			var edge := absf(x) > sw / 2 - 2
			draw_rect(Rect2(x, 0, 1, 1), Pal.CON0 if not edge else Pal.CON1)
		draw_rect(Rect2(-w / 2 + 1, 1, w - 2, 1), Pal.CON1)
		if shadow_len > 0.0:
			# Long soft shadow thrown by the lantern, thinning with distance.
			for i in int(shadow_len):
				var sx := (w / 2.0 + i) * shadow_dir - (0.0 if shadow_dir > 0 else 1.0)
				if i < shadow_len * 0.6 or (i % 2 == 0):
					draw_rect(Rect2(floorf(sx), 0, 1, 1), Pal.CON0)
				if i < shadow_len * 0.35:
					draw_rect(Rect2(floorf(sx), -1, 1, 1), Pal.CON1)
	var bob := -1.0 if _wobble > 0.6 else 0.0
	var mod := Color(1, 1, 1, 1)
	if ghost:
		mod = Color(1, 1, 1, 0.65) if valid else Color(1, 0.45, 0.4, 0.5)
	draw_texture(tex, tl + Vector2(0, bob), mod)
	if hovered and not ghost:
		# Thin warm outline when hovered.
		for y in h:
			for x in w:
				if img.get_pixel(x, y).a > 0.0:
					continue
				var n := false
				for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = Vector2i(x, y) + o
					if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and img.get_pixelv(q).a > 0.0:
						n = true
				if n:
					draw_rect(Rect2(tl + Vector2(x, y), Vector2.ONE), Pal.LAMP1)
	if _tune_show > 0.0 and not ghost:
		# Tuning pips under the drum: centre mark plus one pip per step.
		var y := 3.0
		draw_rect(Rect2(0, y, 1, 1), Pal.FOG1)
		for k in absi(tune):
			var x := (k + 1) * 2 * signi(tune)
			draw_rect(Rect2(x, y, 1, 1), Pal.LAMP1 if tune > 0 else Pal.RAIN)
	for n in _notes:
		# A three-pixel note: head and stem, fading through the palette.
		var age: float = n[2]
		if age > 1.2 and int(age * 12.0) % 2 == 0:
			continue
		var col := Pal.LAMP1 if age < 0.4 else (Pal.RAIN if age < 0.9 else Pal.FOG1)
		var p := Vector2(floorf(n[0]), floorf(n[1]))
		draw_rect(Rect2(p, Vector2(2, 1)), col)
		draw_rect(Rect2(p + Vector2(1, -3), Vector2(1, 3)), col)
	if _ring > 0.0 and not ghost:
		# A small ring of sound: two pixels flaring out above the lid.
		var lid: Array = def.lid
		var cx: float = tl.x + (lid[0] + lid[1]) / 2.0
		var spread: float = (1.0 - _ring) * ((lid[1] - lid[0]) / 2.0 + 3.0)
		var y := tl.y + 1.0 - (1.0 - _ring) * 3.0
		var col := Pal.RAIN_HI if _ring > 0.5 else Pal.RAIN
		draw_rect(Rect2(floorf(cx - spread), floorf(y), 1, 1), col)
		draw_rect(Rect2(floorf(cx + spread), floorf(y), 1, 1), col)
		if _ring > 0.7:
			draw_rect(Rect2(floorf(cx), floorf(tl.y + 2.0), 1, 1), Pal.BONE)


func show_tuning() -> void:
	_tune_show = 1.5

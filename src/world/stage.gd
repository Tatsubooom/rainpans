class_name Stage
extends Node2D
## The playable scene: layered backdrop, rain, drums, light and weather.
## Also owns drum placement (drag from shelf, move, return to shelf).

signal drum_struck(drum: Drum, amount: float)
signal hover_changed(text: String)

var area_id := "roof"
var area: Dictionary
var rain_far: Rain
var rain: Rain
var ripples: Ripples
var smoke: Smoke
var drums_node: Node2D
var lamp_light: PointLight2D
var glow_light: PointLight2D
var halo: Sprite2D
var modulate_node: CanvasModulate
var sky_sprite: Sprite2D
var horizon: Sprite2D
var mist: Array[Sprite2D] = []
var thunder: AudioStreamPlayer

## set by HUD: rectangles (in viewport px) where dropping returns to shelf
var shelf_rect := Rect2()

var _drag: Drum = null
var _drag_from_shelf := false
var _drag_entry: Dictionary = {}
var _drag_offset := Vector2.ZERO
var _hover: Drum = null
var _t := 0.0
var _flash := 0.0
var _next_flash := 25.0
var _flicker := FastNoiseLite.new()
var _mouse := Vector2(-100, -100) # last pointer position in world px


func build(id: String) -> void:
	for ch in get_children():
		ch.queue_free()
	mist.clear()
	area_id = id
	area = AreaLibrary.build(id)
	var layers: Dictionary = area.layers

	modulate_node = CanvasModulate.new()
	modulate_node.color = area.ambient
	add_child(modulate_node)

	sky_sprite = _layer(layers.sky)
	# Dusk/dawn light low on the horizon (faded in by time of day).
	horizon = Sprite2D.new()
	horizon.texture = EnvFx.horizon_texture(320, 70)
	horizon.centered = false
	horizon.position = Vector2(0, 52)
	horizon.modulate.a = 0.0
	var hmat := CanvasItemMaterial.new()
	hmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	hmat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	horizon.material = hmat
	add_child(horizon)
	smoke = Smoke.new()
	smoke.steam = area.get("smoke_steam", false)
	add_child(smoke)
	smoke.setup(area.smoke)
	rain_far = Rain.new()
	add_child(rain_far)
	rain_far.rate = Game.rain_rate() * 1.2
	rain_far.setup(area, Rain.FAR)
	_mist(EnvFx.mist_texture(260, 26, 1, Pal.FOG1, 1.2), Vector2(-40, 92), 2.0)
	_layer(layers.mid)
	_mist(EnvFx.mist_texture(220, 18, 2, Pal.FOG0, 1.0), Vector2(120, 108), -1.4)
	_layer(layers.floor)

	ripples = Ripples.new()
	add_child(ripples)
	ripples.setup(area)

	drums_node = Node2D.new()
	drums_node.y_sort_enabled = true
	add_child(drums_node)

	rain = Rain.new()
	rain.ripples = ripples
	add_child(rain)
	rain.rate = Game.rain_rate()
	rain.setup(area, Rain.NEAR)

	if area.has("water_y"):
		var water := CanalWater.new()
		water.y0 = area.water_y
		add_child(water)
	_layer(layers.front)
	if area.has("shaft"):
		# A shaft of grey daylight/moonlight through the hole in the vault.
		var shaft := Sprite2D.new()
		var sr: Rect2 = area.shaft
		shaft.texture = EnvFx.shaft_texture(int(sr.size.x), int(sr.size.y))
		shaft.centered = false
		shaft.position = sr.position
		var smat := CanvasItemMaterial.new()
		smat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		smat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		shaft.material = smat
		add_child(shaft)
	_mist(EnvFx.mist_texture(300, 14, 3, Pal.FOG0, 0.7), Vector2(0, 160), 0.8)

	# Lantern: a banded warm light plus a tight bright core.
	lamp_light = PointLight2D.new()
	lamp_light.texture = EnvFx.light_texture(80, 6)
	lamp_light.position = area.lamp
	lamp_light.color = area.lamp_color
	lamp_light.energy = 2.2
	lamp_light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(lamp_light)
	glow_light = PointLight2D.new()
	glow_light.texture = EnvFx.light_texture(16, 3)
	glow_light.position = area.lamp
	glow_light.color = Pal.LAMP1
	glow_light.energy = 0.7
	add_child(glow_light)

	# Visible glow in the wet air around the lantern (additive, dithered bands).
	halo = Sprite2D.new()
	halo.texture = EnvFx.halo_texture(34, Pal.LAMP3)
	halo.position = area.lamp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	halo.material = mat
	add_child(halo)

	# Secondary warm sources (lit windows etc.).
	for wp in area.get("windows", []):
		var wl := PointLight2D.new()
		wl.texture = EnvFx.light_texture(28, 4)
		wl.position = wp
		wl.color = Pal.LAMP3
		wl.energy = 1.1
		add_child(wl)

	thunder = AudioStreamPlayer.new()
	thunder.stream = EnvFx.thunder_wav()
	thunder.bus = "Ambience"
	thunder.volume_db = -10.0
	add_child(thunder)

	_flicker.seed = 4
	_flicker.frequency = 1.3
	for e in Game.placed_in_area():
		_spawn_drum(e)
	apply_upgrades()


func _layer(img: Image) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.centered = false
	add_child(s)
	return s


func _mist(tex: Texture2D, pos: Vector2, speed: float) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	s.set_meta("speed", speed)
	s.set_meta("x0", pos.x)
	add_child(s)
	mist.append(s)


func lamp_energy() -> float:
	return 2.0 + 0.35 * Game.level("lamp")


func apply_upgrades() -> void:
	if rain == null:
		return
	rain.rate = Game.rain_rate()
	rain_far.rate = Game.rain_rate() * 1.2
	rain.drip_points = 1 + Game.level("drip")
	rain.drip_rate = 0.55 + 0.1 * Game.level("drip") + 0.25 * Game.rain_level()
	lamp_light.energy = lamp_energy()
	lamp_light.texture_scale = 1.0 + 0.15 * Game.level("lamp")
	Synth.set_rain_level(Game.rain_level())
	Synth.set_area_bed(area.get("bed", ""))
	Synth.set_reverb_wet(0.28 + 0.06 * Game.level("reverb"), minf(0.98, float(area.get("reverb_room", 0.78)) + 0.03 * Game.level("reverb")))


# ------------------------------------------------------------------- drums

func degree_for(x: float) -> int:
	# Left to right walks up the pentatonic scale.
	return int(round(lerpf(-3.0, 4.0, clampf(x / 320.0, 0.0, 1.0))))


func _spawn_drum(entry: Dictionary) -> Drum:
	var d := Drum.new()
	d.setup(entry.id)
	d.position = Vector2(entry.x, entry.y)
	d.degree = degree_for(entry.x)
	d.set_meta("entry", entry)
	d.struck.connect(func(dr: Drum, amount: float): drum_struck.emit(dr, amount))
	drums_node.add_child(d)
	rain.drums.append(d)
	_relight(d)
	return d


func _relight(d: Drum) -> void:
	d.relight(area.lamp, 90.0 + 12.0 * Game.level("lamp"), area.lamp_color)


func place_drum(id: String, pos: Vector2) -> Drum:
	var entry := {"id": id, "x": pos.x, "y": pos.y}
	Game.placed_in_area().append(entry)
	return _spawn_drum(entry)


func valid_spot(d: Drum, pos: Vector2) -> bool:
	var f: Rect2 = area.floor
	if not f.has_point(pos):
		return false
	var half := d.size().x / 2.0
	if pos.x - half < 0.0 or pos.x + half > 320.0:
		return false
	# No stacking: another drum at nearly the same depth must not overlap.
	for o in rain.drums:
		var other: Drum = o
		if other == d:
			continue
		var oh := other.size().x / 2.0
		if absf(other.position.y - pos.y) < 7.0 and absf(other.position.x - pos.x) < half + oh:
			return false
	return true


func drum_at(p: Vector2) -> Drum:
	var best: Drum = null
	for d in rain.drums:
		var dr: Drum = d
		if dr.contains(p) and (best == null or dr.position.y > best.position.y):
			best = dr
	return best


func begin_shelf_drag(id: String) -> void:
	if _drag != null:
		return
	var d := Drum.new()
	d.setup(id)
	d.ghost = true
	d.position = _mouse.floor()
	drums_node.add_child(d)
	_drag = d
	_drag_from_shelf = true
	_drag_offset = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_mouse = get_canvas_transform().affine_inverse() * event.position
	if _drag == null:
		return
	if event is InputEventMouseMotion:
		_update_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_end_drag()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _drag == null:
		var h := drum_at(_mouse)
		if h != _hover:
			if _hover:
				_hover.hovered = false
			_hover = h
			if _hover:
				_hover.hovered = true
				hover_changed.emit("%s　—　つかんで動かす／右クリックで棚へ" % _hover.def.name)
			else:
				hover_changed.emit("")
	if event is InputEventMouseButton and event.pressed:
		var p := _mouse
		var d := drum_at(p)
		if d == null:
			return
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_remove_drum(d)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_drag = d
			_drag_from_shelf = false
			_drag_offset = d.position - p
			_drag_entry = d.get_meta("entry")
			d.ghost = true
			d.hovered = false
			d.tex = ImageTexture.create_from_image(d.img)
			get_viewport().set_input_as_handled()


func _update_drag_to(d: Drum) -> void:
	d.position = (_mouse + _drag_offset).floor()


func _update_drag() -> void:
	var p := (_mouse + _drag_offset).floor()
	_drag.position = p
	_drag.valid = valid_spot(_drag, p) and not shelf_rect.has_point(_mouse)


func _end_drag() -> void:
	var d := _drag
	_drag = null
	var mouse := _mouse
	_update_drag_to(d)
	var p := d.position
	var over_shelf := shelf_rect.has_point(mouse)
	if _drag_from_shelf:
		d.queue_free()
		if not over_shelf and valid_spot(d, p):
			place_drum(d.id, p)
			Synth.play(d.id, degree_for(p.x), p, 0.5, -1)
		return
	if over_shelf:
		_remove_drum(d)
		return
	if valid_spot(d, p):
		_drag_entry.x = p.x
		_drag_entry.y = p.y
	d.position = Vector2(_drag_entry.x, _drag_entry.y)
	d.degree = degree_for(d.position.x)
	_relight(d)
	d.ghost = false
	d.valid = true


func _remove_drum(d: Drum) -> void:
	var entry: Dictionary = d.get_meta("entry")
	Game.placed_in_area().erase(entry)
	rain.drums.erase(d)
	if _hover == d:
		_hover = null
		hover_changed.emit("")
	d.queue_free()
	Game.changed.emit()


# ----------------------------------------------------------------- weather

## Time of day keys: phase (0..1) -> ambient tint, horizon glow, lamp scale.
const DAY_KEYS := [
	[0.00, Color(1.00, 0.80, 0.84), 0.9, 0.7], # dusk
	[0.18, Color(0.92, 0.95, 1.00), 0.0, 1.0], # night
	[0.45, Color(0.74, 0.80, 0.96), 0.0, 1.1], # deep night
	[0.70, Color(0.90, 0.92, 1.04), 0.25, 0.9], # before dawn
	[0.80, Color(1.08, 1.00, 1.04), 1.0, 0.45], # dawn
	[0.90, Color(1.15, 1.15, 1.18), 0.2, 0.25], # grey morning rain
	[1.00, Color(1.00, 0.80, 0.84), 0.9, 0.7],
]
const DAY_LENGTH := 1440.0 # seconds of play for one full cycle

var _wind := -0.08
var _wind_target := -0.08
var _gust := 0.0
var _next_gust := 40.0
var _wind_x := 0.0
var _day_glow := 0.0
var _day_lamp := 1.0


func day_phase() -> float:
	if Game.debug_phase >= 0.0:
		return Game.debug_phase
	if Game.level("time") <= 0:
		return 0.25
	return fmod(Game.play_time / DAY_LENGTH, 1.0)


func _day_sample(phase: float) -> Array:
	for i in DAY_KEYS.size() - 1:
		var a: Array = DAY_KEYS[i]
		var b: Array = DAY_KEYS[i + 1]
		if phase >= a[0] and phase <= b[0]:
			var t: float = (phase - a[0]) / (b[0] - a[0])
			t = t * t * (3.0 - 2.0 * t)
			return [(a[1] as Color).lerp(b[1], t), lerpf(a[2], b[2], t), lerpf(a[3], b[3], t)]
	return [DAY_KEYS[1][1], 0.0, 1.0]


func _process(delta: float) -> void:
	_t += delta
	var day := _day_sample(day_phase())
	var amb: Color = area.ambient * (day[0] as Color)
	_day_glow = day[1]
	_day_lamp = day[2]
	if horizon:
		# Dusk burns rose; dawn comes in pale gold and grey-blue.
		var ph := day_phase()
		var tint := Color(1.0, 0.85, 0.8) if ph < 0.5 else Color(0.95, 1.1, 1.25)
		horizon.modulate = Color(tint, _day_glow)

	# Lantern flicker: slow breathing plus the odd gutter.
	var f := _flicker.get_noise_1d(_t * 10.0)
	glow_light.energy = (0.65 + f * 0.25) * _day_lamp
	lamp_light.energy = lamp_energy() * (0.93 + f * 0.08) * _day_lamp
	halo.modulate.a = (0.9 + f * 0.1) * clampf(_day_lamp, 0.3, 1.0)

	# Wind: a slow wander, with an occasional gust that leans the rain over
	# and sets the pipe chimes ringing.
	_next_gust -= delta
	if _next_gust <= 0.0:
		_next_gust = randf_range(45.0, 120.0)
		_gust = 1.0
	_gust = maxf(0.0, _gust - delta / 7.0)
	_wind_target = -0.06 + _flicker.get_noise_1d(_t * 0.4 + 50.0) * 0.08 - sin(_gust * PI) * 0.22
	_wind = lerpf(_wind, _wind_target, minf(1.0, delta * 1.5))
	rain.wind = _wind
	rain_far.wind = _wind
	smoke.wind = -6.0 + _wind * 60.0
	_wind_x += delta * (1.0 - _wind * 10.0)
	if _gust > 0.3 and randf() < delta * 3.0 * _gust:
		for d in rain.drums:
			var dr: Drum = d
			if dr.id == "pipes" and not dr.ghost:
				dr.strike(randf_range(0.15, 0.4))
	for m in mist:
		var sp: float = m.get_meta("speed")
		var x0: float = m.get_meta("x0")
		var tw: float = m.texture.get_width()
		m.position.x = floorf(wrapf(x0 + _wind_x * sp, -tw, 320.0 + tw * 0.25))

	# Distant lightning only in heavier rain.
	if Game.rain_level() > 0.55:
		_next_flash -= delta
		if _next_flash <= 0.0:
			_next_flash = randf_range(30.0, 90.0)
			_flash = 1.0
			get_tree().create_timer(randf_range(1.2, 3.0)).timeout.connect(func(): thunder.play())
	var flash_on := false
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 2.5)
		flash_on = _flash > 0.75 or (_flash > 0.35 and _flash < 0.5)
	modulate_node.color = amb.lerp(Color(1.25, 1.3, 1.45), 0.5 if flash_on else 0.0)
	rain.flash = 0.6 if flash_on else 0.0
	rain_far.flash = rain.flash

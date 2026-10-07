class_name Scenarios
## Scripted input runs used by tools/scenario.sh to check interaction
## headlessly. Each prints "SCENARIO OK"/"SCENARIO FAIL ..." and quits.


static func run(main: Node, name: String) -> void:
	match name:
		"drag":
			await _drag(main)
		"rates":
			await _rates(main)
		"progress":
			await _progress(main)
		"travel":
			await _travel(main)
		"sheet":
			_sheet()
		"loop":
			await _loop(main)
		"swap":
			await _swap(main)
		_:
			print("SCENARIO FAIL unknown ", name)
	main.get_tree().quit()


## Scenario coordinates are written on the 320x180 grid (UI layout units);
## events are sent in window pixels (2x).
static func _move(p: Vector2) -> void:
	p *= UiKit.UI_SCALE
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	Input.parse_input_event(e)


static func _button(p: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT) -> void:
	p *= UiKit.UI_SCALE
	var e := InputEventMouseButton.new()
	e.position = p
	e.global_position = p
	e.button_index = button
	e.pressed = pressed
	Input.parse_input_event(e)


static func _frames(main: Node, n: int) -> void:
	for i in n:
		await main.get_tree().process_frame


static func _glide(main: Node, a: Vector2, b: Vector2, steps := 8) -> void:
	for i in steps + 1:
		_move(a.lerp(b, float(i) / steps).floor())
		await _frames(main, 1)


static func _drag(main: Node) -> void:
	Game.reset()
	Game.resonance = 100.0
	var stage: Stage = main.stage
	var hud: Hud = main.hud
	stage.build("roof")
	hud.bind_stage(stage)
	if not hud.shelf.visible:
		hud.toggle_shelf()
	await _frames(main, 3)
	# 1) Drag the free can from slot 0 onto the floor.
	var slot := Vector2(18, 34)
	await _glide(main, Vector2(160, 60), slot)
	_button(slot, true)
	await _frames(main, 2)
	await _glide(main, slot, Vector2(120, 150), 10)
	_button(Vector2(120, 150), false)
	await _frames(main, 2)
	var placed := Game.placed_in_area().size()
	if placed != 1:
		print("SCENARIO FAIL expected 1 placed, got ", placed)
		return
	# 2) Buy a bucket (slot 1) and drop it in the air: must not be placed.
	var slot2 := Vector2(46, 34)
	await _glide(main, Vector2(120, 150), slot2)
	_button(slot2, true)
	await _frames(main, 2)
	if Game.owned.get("bucket", 0) != 1:
		print("SCENARIO FAIL bucket not bought, res=", Game.resonance)
		return
	await _glide(main, slot2, Vector2(60, 80), 6)
	_button(Vector2(60, 80), false)
	await _frames(main, 2)
	if Game.placed_in_area().size() != 1 or Game.free_count("bucket") != 1:
		print("SCENARIO FAIL bucket dropped in the sky was placed")
		return
	# 2b) Click the placed can without moving: it is played by hand.
	var can0: Drum = stage.rain.drums[0]
	var tap := can0.position / 2.0 + Vector2(0, -4)
	await _glide(main, Vector2(60, 80), tap, 4)
	var hits0 := Game.hits_total
	_button(tap, true)
	await _frames(main, 1)
	_button(tap, false)
	await _frames(main, 2)
	if Game.hits_total <= hits0 or absf(Game.placed_in_area()[0].x - 240.0) > 1.0:
		print("SCENARIO FAIL click did not play (or moved) the can")
		return
	# 2c) Keyboard: A plays the leftmost drum; wheel retunes it.
	var hits1 := Game.hits_total
	var k := InputEventKey.new()
	k.keycode = KEY_A
	k.pressed = true
	Input.parse_input_event(k)
	await _frames(main, 2)
	if Game.hits_total <= hits1:
		print("SCENARIO FAIL key A did not play")
		return
	var wheel := InputEventMouseButton.new()
	wheel.position = tap * UiKit.UI_SCALE
	wheel.global_position = tap * UiKit.UI_SCALE
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	Input.parse_input_event(wheel)
	await _frames(main, 2)
	if int(Game.placed_in_area()[0].get("tune", 0)) != 1:
		print("SCENARIO FAIL wheel did not retune: ", Game.placed_in_area()[0])
		return
	# 3) Move the can, then right-click it back to the shelf.
	var can: Drum = stage.rain.drums[0]
	var grab := can.position / 2.0 + Vector2(0, -4)
	await _glide(main, tap, grab)
	_button(grab, true)
	await _frames(main, 1)
	await _glide(main, grab, Vector2(200, 160), 8)
	_button(Vector2(200, 160), false)
	await _frames(main, 2)
	var e: Dictionary = Game.placed_in_area()[0]
	if absf(e.x - 400.0) > 4.0:
		print("SCENARIO FAIL move did not stick: ", e)
		return
	var grab2 := Vector2(e.x, e.y - 8.0) / 2.0
	await _glide(main, Vector2(200, 160), grab2, 2)
	_button(grab2, true, MOUSE_BUTTON_RIGHT)
	await _frames(main, 2)
	if Game.placed_in_area().size() != 0 or Game.free_count("can") != 1:
		print("SCENARIO FAIL right-click did not return the can")
		return
	print("SCENARIO OK drag")


## Measures hits/sec of a single drum per rain level (for balancing).
static func _rates(main: Node) -> void:
	Engine.time_scale = 4.0
	for id in ["can", "bucket", "drum"]:
		var line: String = id + ":"
		for lvl in [0, 10]:
			Game.reset()
			Game.levels["rain"] = lvl
			Game.owned[id] = 1
			Game.placements = {"roof": [{"id": id, "x": 100.0, "y": 150.0}]}
			main.stage.build("roof")
			var t0 := Time.get_ticks_msec()
			var e0 := Game.total_earned
			await main.get_tree().create_timer(12.0).timeout
			var game_secs := (Time.get_ticks_msec() - t0) / 1000.0 * Engine.time_scale
			var hits: float = (Game.total_earned - e0) / (DrumDefs.get_def(id).yield * Game.multiplier())
			line += "  L%d=%.2f/s" % [lvl, hits / game_secs]
		print(line)
	print("SCENARIO OK rates")


## Fast-forwards a fresh game with a simple greedy player that buys, places,
## swaps out weak drums when full and moves on to new places, printing
## milestones. Stops when the ending starts (or the time runs out).
static func _progress(main: Node) -> void:
	Game.reset()
	Game.tutorial = 99
	var stage: Stage = main.stage
	stage.build("roof")
	main.hud.bind_stage(stage)
	Engine.time_scale = float(OS.get_environment("PROGRESS_SPEED")) if OS.get_environment("PROGRESS_SPEED") != "" else 16.0
	var minutes := float(OS.get_environment("PROGRESS_MIN")) if OS.get_environment("PROGRESS_MIN") != "" else 30.0
	var seen := {}
	var start := Time.get_ticks_msec()
	var mark := func(what: String):
		if not seen.has(what):
			seen[what] = true
			print("  %6.1f min  %-8s rate=%s/s" % [Game.play_time / 60.0, what, Game.fmt(Game.rate)])
	while Game.play_time < minutes * 60.0:
		await main.get_tree().create_timer(2.0).timeout
		stage = main.stage
		# Move on when the next place is affordable.
		for a in Game.AREAS:
			if not a in Game.areas_open and Game.resonance >= Game.area_cost(a) and Game.AREAS.find(a) == Game.areas_open.size():
				Game.open_area(a)
				main._travel(a)
				stage = main.stage
				mark.call(a)
		if Game.can_upgrade("wait"):
			Game.buy_upgrade("wait")
			mark.call("ENDING")
			break
		for id in DrumDefs.ORDER:
			while Game.free_count(id) > 0 and _auto_place(stage, id):
				pass
		var bought := true
		var guard := 0
		while bought and guard < 50:
			guard += 1
			bought = false
			var options := []
			for id in ["rain", "reverb", "lamp", "echo", "drip", "time"]:
				if Game.can_upgrade(id):
					options.append(["u", id, Game.upgrade_cost(id)])
			for id in DrumDefs.ORDER:
				if not Game.drum_visible(id) or Game.resonance < Game.drum_cost(id):
					continue
				if Game.area_full():
					# Only worth it if it beats the weakest drum standing here.
					var weakest := _weakest(stage)
					if weakest == null or DrumDefs.get_def(id).yield <= weakest.def.yield:
						continue
				options.append(["d", id, Game.drum_cost(id)])
			options.sort_custom(func(a, b): return a[2] < b[2])
			if options.is_empty():
				break
			var o: Array = options[0]
			if o[0] == "u":
				Game.buy_upgrade(o[1])
				mark.call(o[1])
			else:
				Game.buy_drum(o[1])
				mark.call(o[1])
				if Game.area_full():
					var w := _weakest(stage)
					var pos := w.position
					stage._remove_drum(w)
					await main.get_tree().process_frame
					var probe := _probe(o[1])
					if stage.valid_spot(probe, pos):
						stage.place_drum(o[1], pos)
					else:
						_auto_place(stage, o[1])
					probe.free()
				else:
					_auto_place(stage, o[1])
			bought = true
	print("end: area=", Game.area, " placed=", Game.placed_in_area().size(), " rate=", Game.fmt(Game.rate), "/s res=", Game.fmt(Game.resonance), " levels=", Game.levels)
	Engine.time_scale = 1.0
	await main.get_tree().create_timer(1.0).timeout
	main.get_viewport().get_texture().get_image().save_png("res://shots/progress.png")
	print("SCENARIO OK progress (%.0fs real, %.0f game min)" % [(Time.get_ticks_msec() - start) / 1000.0, Game.play_time / 60.0])


static func _probe(id: String) -> Drum:
	var d := Drum.new()
	d.setup(id)
	return d


static func _weakest(stage: Stage) -> Drum:
	var best: Drum = null
	for d in stage.rain.drums:
		if d.ghost:
			continue
		if best == null or d.def.yield < best.def.yield:
			best = d
	return best


static func _has_room(stage: Stage, id: String) -> bool:
	if Game.area_full():
		return Game.free_count(id) == 0 and false
	var d := Drum.new()
	d.setup(id)
	var f: Rect2 = stage.area.floor
	for y in range(int(f.position.y) + 2, int(f.end.y), 6):
		for x in range(int(f.position.x) + 8, int(f.end.x) - 8, 5):
			if stage.valid_spot(d, Vector2(x, y)):
				d.free()
				return true
	d.free()
	return false


static func _auto_place(stage: Stage, id: String) -> bool:
	if Game.area_full():
		return false
	var d := Drum.new()
	d.setup(id)
	var f: Rect2 = stage.area.floor
	for y in range(int(f.position.y) + 2, int(f.end.y), 6):
		for x in range(int(f.position.x) + 8, int(f.end.x) - 8, 5):
			var p := Vector2(x, y)
			# Avoid the dry strip under shelters unless it is a drip spot.
			var dry := false
			for s in stage.area.shelters:
				if (s as Rect2).has_point(Vector2(x, 10.0)) and absf(y - float(stage.area.get("drip_depth", 152.0))) > 4.0:
					dry = true
			if not dry and stage.valid_spot(d, p):
				d.free()
				stage.place_drum(id, p)
				return true
	d.free()
	return false


## Opens the other areas, arranges something in each, travels back and
## forth (also mid-drag) and checks every arrangement survives.
static func _travel(main: Node) -> void:
	Game.reset()
	Game.resonance = 1e12
	Game.owned = {"can": 2, "bucket": 1}
	main.stage.build("roof")
	main.hud.bind_stage(main.stage)
	main.stage.place_drum("can", Vector2(120, 300))
	for a in ["rail", "glass", "canal"]:
		if not Game.open_area(a):
			print("SCENARIO FAIL could not open ", a)
			return
		main._travel(a)
		await _frames(main, 3)
		if main.stage.area_id != a or not main.stage.rain.drums.is_empty():
			print("SCENARIO FAIL fresh area not empty: ", a)
			return
		main.stage.place_drum("bucket", Vector2(300, 312))
		await _frames(main, 2)
	# Start a drag, then travel away mid-drag.
	main.stage.begin_shelf_drag("can")
	main._travel("roof")
	await _frames(main, 3)
	var ok: bool = Game.placements["roof"].size() == 1 and Game.placements["rail"].size() == 1 and Game.placements["glass"].size() == 1 and Game.placements["canal"].size() == 1
	if not ok:
		print("SCENARIO FAIL placements lost: ", Game.placements)
		return
	if main.stage.rain.drums.size() != 1:
		print("SCENARIO FAIL roof drums not respawned")
		return
	# Let everything run a little in each area to shake out runtime errors.
	for a in ["rail", "glass", "canal", "roof"]:
		main._travel(a)
		await main.get_tree().create_timer(1.0).timeout
	print("SCENARIO OK travel")


## Saves every drum sprite side by side (plain and lamp-lit) for review.
static func _sheet() -> void:
	var cell := Vector2i(30, 26)
	var c := PixCanvas.new(cell.x * DrumDefs.ORDER.size(), cell.y * 2, Pal.CON1)
	for i in DrumDefs.ORDER.size():
		var id: String = DrumDefs.ORDER[i]
		var img := DrumDefs.make_image(id)
		var x := i * cell.x + (cell.x - img.get_width()) / 2
		c.stamp(img, x, cell.y - 2 - img.get_height())
		var d := Drum.new()
		d.setup(id)
		d.position = Vector2(i * cell.x + cell.x / 2.0, cell.y * 2 - 2)
		d.relight(d.position + Vector2(-26, -20), 90.0, Pal.LAMP2)
		c.stamp(d.tex.get_image(), x, cell.y * 2 - 2 - img.get_height())
		d.free()
	c.img.save_png("res://shots/sheet.png")
	print("SCENARIO OK sheet")


static func _key(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	var up := InputEventKey.new()
	up.keycode = k
	up.pressed = false
	Input.parse_input_event(up)


## Record a three-note phrase with the keyboard, stop, and check that the
## loop keeps playing it with no input; then clear it.
static func _loop(main: Node) -> void:
	Game.reset()
	Game.tutorial = 99
	Game.levels["rain"] = 0
	Game.rain_scale = 0.0 # silence the rain so only the loop strikes
	Game.owned = {"can": 1, "bucket": 1}
	main.stage.build("roof")
	main.hud.bind_stage(main.stage)
	main.looper.load_from_save()
	main.stage.place_drum("can", Vector2(120, 300))
	main.stage.place_drum("bucket", Vector2(400, 300))
	main.stage.rain.drip_rate = 0.0
	await _frames(main, 3)
	_key(KEY_R)
	await _frames(main, 2)
	for k in [KEY_A, KEY_S, KEY_A]:
		_key(k)
		await main.get_tree().create_timer(0.3).timeout
	_key(KEY_R)
	await _frames(main, 2)
	var lp: Looper = main.looper
	if lp.recording or lp.notes.size() != 3 or lp.length <= 0.0:
		print("SCENARIO FAIL loop not recorded: notes=", lp.notes.size(), " len=", lp.length)
		return
	var h0 := Game.hits_total
	await main.get_tree().create_timer(lp.length * 2.0 + 0.2).timeout
	var played := Game.hits_total - h0
	if played < 5:
		print("SCENARIO FAIL loop played only ", played, " notes")
		return
	if not Game.loops.has("roof"):
		print("SCENARIO FAIL loop not stored for save")
		return
	_key(KEY_BACKSPACE)
	await _frames(main, 2)
	if lp.length != 0.0 or Game.loops.has("roof"):
		print("SCENARIO FAIL loop not cleared")
		return
	Game.rain_scale = 1.0
	print("SCENARIO OK loop (%d notes replayed)" % played)


## Fill the roof, then drop a new bucket from the shelf onto a can: the can
## goes back to the shelf and the bucket takes its place.
static func _swap(main: Node) -> void:
	Game.reset()
	Game.tutorial = 99
	Game.owned = {"can": Game.capacity(), "bucket": 1}
	var stage: Stage = main.stage
	stage.build("roof")
	main.hud.bind_stage(stage)
	var i := 0
	for y in [142, 152, 162, 172]:
		for x in range(20, 300, 56):
			if i < Game.capacity():
				stage.place_drum("can", Vector2(x, y) * 2)
				i += 1
	if not Game.area_full():
		print("SCENARIO FAIL could not fill the roof: ", Game.placed_in_area().size())
		return
	if not main.hud.shelf.visible:
		main.hud.toggle_shelf()
	await _frames(main, 2)
	var slot := Vector2(46, 34)
	var target := Vector2(76, 152)
	await _glide(main, Vector2(100, 90), slot)
	_button(slot, true)
	await _frames(main, 2)
	await _glide(main, slot, target, 10)
	_button(target, false)
	await _frames(main, 3)
	var cans := Game.placed_count("can")
	var buckets := Game.placed_count("bucket")
	if buckets != 1 or cans != Game.capacity() - 1:
		print("SCENARIO FAIL swap: cans=", cans, " buckets=", buckets)
		return
	print("SCENARIO OK swap")

class_name Scenarios
## Scripted input runs used by tools/scenario.sh to check interaction
## headlessly. Each prints "SCENARIO OK"/"SCENARIO FAIL ..." and quits.


static func run(main: Node, name: String) -> void:
	match name:
		"drag":
			await _drag(main)
		"rates":
			await _rates(main)
		_:
			print("SCENARIO FAIL unknown ", name)
	main.get_tree().quit()


static func _move(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	Input.parse_input_event(e)


static func _button(p: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT) -> void:
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
	# 3) Move the can, then right-click it back to the shelf.
	var can: Drum = stage.rain.drums[0]
	var grab := can.position + Vector2(0, -4)
	await _glide(main, Vector2(60, 80), grab)
	_button(grab, true)
	await _frames(main, 1)
	await _glide(main, grab, Vector2(200, 160), 8)
	_button(Vector2(200, 160), false)
	await _frames(main, 2)
	var e: Dictionary = Game.placed_in_area()[0]
	if absf(e.x - 200.0) > 2.0:
		print("SCENARIO FAIL move did not stick: ", e)
		return
	var grab2 := Vector2(e.x, e.y - 4.0)
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

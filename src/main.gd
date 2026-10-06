extends Node2D
## Entry point. Builds the stage and HUD; also hosts the command-line hooks
## used to capture screenshots and run scripted checks headlessly:
##   -- --shot=path.png [--frames=N] [--demo] [--shelf] [--upgrades]

var stage: Stage
var hud: Hud
var _args := {}
var _frame := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if _args.has("reset"):
		Game.reset()
	if _args.has("demo"):
		_demo_state()
	if _args.has("area"):
		Game.area = _args.area
		if not Game.area in Game.areas_open:
			Game.areas_open.append(Game.area)
	if _args.has("phase"):
		Game.debug_phase = float(_args.phase)

	stage = Stage.new()
	add_child(stage)
	stage.build(Game.area)
	hud = Hud.new()
	add_child(hud)
	hud.bind_stage(stage)
	hud.drag_requested.connect(stage.begin_shelf_drag)
	hud.travel.connect(_travel)
	stage.drum_struck.connect(_on_struck)

	if not (_args.has("shot") or _args.has("scenario")) or _args.has("intro"):
		add_child(Intro.new())
	if _args.has("crow"):
		stage.critters.debug_sit()
	if _args.has("settings"):
		hud.toggle_settings()
	if Game.offline_gain > 0.0:
		hud.toast("留守のあいだに 響き %s" % Game.fmt(Game.offline_gain))
	elif Game.placed_in_area().is_empty():
		hud.toast("棚から空き缶を、雨の当たる場所へ")
	if _args.has("shelf"):
		hud.toggle_shelf()
	if _args.has("upgrades"):
		hud.toggle_upgrades()
	Synth.warm(Game.owned.keys())
	if _args.has("scenario"):
		Scenarios.run(self, _args.scenario)


func _travel(area_id: String) -> void:
	if area_id == Game.area:
		return
	Game.area = area_id
	stage.build(area_id)
	hud.bind_stage(stage)
	Game.save_game()


var hits := 0
var _journal_t := 0.0
var _journal_queue: Array = []


func _on_struck(_d: Drum, _amount: float) -> void:
	hits += 1


func _demo_state() -> void:
	Game.resonance = float(_args.get("res", "1234"))
	Game.total_earned = 50000.0
	Game.owned = {"can": 3, "bucket": 2, "helmet": 1, "pot": 1, "bottle": 1, "drum": 1, "tin": 1, "kettle": 1, "pipes": 1}
	Game.levels["rain"] = int(_args.get("rain", "3"))
	Game.levels["drip"] = 2
	Game.placements = {"rail": [
		{"id": "kettle", "x": 70.0, "y": 154.0},
		{"id": "pipes", "x": 40.0, "y": 150.0},
		{"id": "tin", "x": 168.0, "y": 160.0},
		{"id": "drum", "x": 230.0, "y": 152.0},
		{"id": "bottle", "x": 196.0, "y": 170.0},
		{"id": "helmet", "x": 270.0, "y": 166.0},
		{"id": "pot", "x": 110.0, "y": 172.0},
	], "roof": [
		{"id": "can", "x": 40.0, "y": 150.0},
		{"id": "bucket", "x": 74.0, "y": 141.0},
		{"id": "helmet", "x": 128.0, "y": 158.0},
		{"id": "drum", "x": 172.0, "y": 146.0},
		{"id": "can", "x": 214.0, "y": 152.0},
		{"id": "pot", "x": 252.0, "y": 165.0},
		{"id": "bottle", "x": 98.0, "y": 170.0},
		{"id": "bucket", "x": 290.0, "y": 150.0},
	]}


func _process(delta: float) -> void:
	_frame += 1
	_journal_t += delta
	if _journal_t > 2.0:
		_journal_t = 0.0
		for id in Journal.reached(Game.hits_total):
			if not id in Game.journal and not id in _journal_queue:
				_journal_queue.append(id)
		# One line at a time, spaced out, never on top of another toast.
		if not _journal_queue.is_empty() and hud.info_line.idle():
			var id: String = _journal_queue.pop_front()
			Game.journal.append(id)
			hud.journal_line(Journal.text(id))
	if _args.has("shot") and _frame == int(_args.get("frames", "90")):
		var img := get_viewport().get_texture().get_image()
		img.save_png(_args.shot)
		print("shot saved: ", _args.shot, " res=", Game.resonance, " hits=", hits, " fps=", Engine.get_frames_per_second())
		get_tree().quit()

extends Node2D
## Entry point. Builds the stage and HUD; also hosts the command-line hooks
## used to capture screenshots and run scripted checks headlessly:
##   -- --shot=path.png [--frames=N] [--demo] [--shelf] [--upgrades]

var stage: Stage
var hud: Hud
var looper: Looper
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
	if _args.has("full"):
		# Stress: fill the current area with a mix of every drum type.
		var a: String = _args.get("area", "roof")
		Game.owned = {}
		for id in DrumDefs.ORDER:
			Game.owned[id] = 4
		var arr := []
		var ids: Array = DrumDefs.ORDER
		for i in Game.AREA_CAP[a]:
			arr.append({"id": ids[i % ids.size()], "x": 32.0 + (i % 10) * 60.0, "y": 284.0 + (i / 10) * 18.0})
		Game.placements = {a: arr}
		Game.levels["rain"] = 10
		Game.levels["drip"] = 6
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
	stage.event_note.connect(hud.journal_line)
	looper = Looper.new()
	looper.stage = stage
	add_child(looper)
	stage.hand_strike.connect(looper.on_hand_strike)
	stage.hand_strike.connect(_on_hand_strike)
	hud.top.looper = looper
	Game.unlocked.connect(func(what: String):
		if what == "upgrade:wait":
			start_ending())

	if not (_args.has("shot") or _args.has("scenario")) or _args.has("intro"):
		add_child(Intro.new())
	if _args.has("speed"):
		Engine.time_scale = float(_args.speed)
	if _args.has("ending"):
		start_ending()
	if _args.has("weather"):
		stage.force_weather(_args.weather)
	if _args.has("wanderer"):
		stage.wanderer.force()
	if _args.has("visitor"):
		stage.visitors.spawn(_args.visitor, true)
	if _args.has("strike"):
		stage.strike_lightning()
	if _args.has("crow"):
		stage.critters.debug_sit()
	if _args.has("settings"):
		hud.toggle_settings()
	if _args.has("help"):
		hud.root.add_child(HelpPanel.new())
	if Game.offline_gain > 0.0:
		hud.toast("留守のあいだに 響き %s" % Game.fmt(Game.offline_gain))
	if _args.has("shelf"):
		hud.toggle_shelf()
	if _args.has("upgrades"):
		hud.toggle_upgrades()
	Synth.warm(Game.owned.keys())
	if _args.has("scenario"):
		Scenarios.run(self, _args.scenario)


var _hand_strikes := 0


## After a little playing by hand, mention the looper once.
func _on_hand_strike(_d: Drum, _v: float) -> void:
	_hand_strikes += 1
	if _hand_strikes == 10 and not Game.settings.get("tip_loop", false):
		Game.settings["tip_loop"] = true
		hud.toast("R で、いま弾いたフレーズを録音できる。もう一度 R でループ")


func start_ending() -> void:
	if get_node_or_null("Ending") != null:
		return
	var e := Ending.new()
	e.name = "Ending"
	e.stage = stage
	e.hud = hud
	add_child(e)


func _travel(area_id: String) -> void:
	if area_id == Game.area:
		return
	Game.area = area_id
	stage.build(area_id)
	hud.bind_stage(stage)
	looper.load_from_save()
	if Game.placed_in_area().is_empty():
		hud.toast("%s。棚から雨受けを並べよう（%d 個まで）" % [AreaLibrary.NAMES[area_id], Game.capacity()])
	Game.save_game()


var hits := 0
var _journal_t := 0.0
var _journal_queue: Array = []


func _on_struck(_d: Drum, _amount: float) -> void:
	hits += 1


func _demo_state() -> void:
	Game.tutorial = 99
	Game.resonance = float(_args.get("res", "1234"))
	Game.total_earned = 50000.0
	Game.owned = {"can": 3, "bucket": 2, "helmet": 1, "pot": 1, "bottle": 1, "drum": 1, "tin": 1, "kettle": 1, "pipes": 1}
	Game.levels["rain"] = int(_args.get("rain", "3"))
	Game.levels["drip"] = 2
	Game.placements = {"glass": [
		{"id": "bottle", "x": 128.0, "y": 300.0},
		{"id": "pot", "x": 312.0, "y": 312.0},
		{"id": "kettle", "x": 452.0, "y": 292.0},
		{"id": "helmet", "x": 200.0, "y": 300.0},
		{"id": "drum", "x": 568.0, "y": 320.0},
		{"id": "can", "x": 60.0, "y": 332.0},
	], "rail": [
		{"id": "kettle", "x": 140.0, "y": 308.0},
		{"id": "pipes", "x": 80.0, "y": 300.0},
		{"id": "tin", "x": 336.0, "y": 320.0},
		{"id": "drum", "x": 460.0, "y": 304.0},
		{"id": "bottle", "x": 392.0, "y": 340.0},
		{"id": "helmet", "x": 540.0, "y": 332.0},
		{"id": "pot", "x": 220.0, "y": 344.0},
	], "roof": [
		{"id": "can", "x": 80.0, "y": 300.0},
		{"id": "bucket", "x": 148.0, "y": 282.0},
		{"id": "helmet", "x": 256.0, "y": 316.0},
		{"id": "drum", "x": 344.0, "y": 292.0},
		{"id": "can", "x": 428.0, "y": 304.0},
		{"id": "pot", "x": 504.0, "y": 330.0},
		{"id": "bottle", "x": 196.0, "y": 340.0},
		{"id": "bucket", "x": 580.0, "y": 300.0},
	]}


func _process(delta: float) -> void:
	_frame += 1
	_journal_t += delta
	if _journal_t > 2.0 and get_node_or_null("Ending") == null:
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
		print("shot saved: ", _args.shot, " res=", Game.resonance, " hits=", hits, " fps=", Engine.get_frames_per_second(), " t=", Game.play_time)
		get_tree().quit()

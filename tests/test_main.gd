extends Node
## Headless logic tests: `tools/test.sh`. Exits non-zero on failure.

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: ", what)


func _ready() -> void:
	Game.reset()
	_test_format()
	_test_economy()
	_test_save_roundtrip()
	_test_scale()
	_test_drum_defs()
	_test_catch()
	_test_synth()
	_test_capacity()
	_test_musicality()
	_test_journal()
	_test_disk_save()
	_test_distant()
	print("%d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


func _test_format() -> void:
	check(Game.fmt(0) == "0", "fmt 0")
	check(Game.fmt(999) == "999", "fmt 999")
	check(Game.fmt(1234) == "1.23k", "fmt 1234 -> %s" % Game.fmt(1234))
	check(Game.fmt(56789) == "56.8k", "fmt 56789 -> %s" % Game.fmt(56789))
	check(Game.fmt(2.5e9) == "2.50B", "fmt 2.5e9 -> %s" % Game.fmt(2.5e9))


func _test_economy() -> void:
	Game.reset()
	check(Game.free_count("can") == 1, "start with one free can")
	var c1 := Game.drum_cost("can")
	Game.resonance = 1000.0
	check(Game.buy_drum("can"), "buy a second can")
	check(Game.drum_cost("can") > c1, "copies get dearer")
	check(is_equal_approx(Game.resonance, 1000.0 - c1), "cost deducted")
	check(not Game.buy_drum("plate"), "cannot afford plate")
	var before := Game.rain_rate()
	Game.resonance = 1e9
	check(Game.buy_upgrade("rain"), "buy rain upgrade")
	check(Game.rain_rate() > before, "rain rate grows")
	Game.levels["echo"] = 1
	check(not Game.can_upgrade("echo"), "echo is capped at 1")
	var m := Game.multiplier()
	var got := Game.earn(10.0)
	check(is_equal_approx(got, 10.0 * m), "earn applies multiplier")


func _test_save_roundtrip() -> void:
	Game.reset()
	Game.resonance = 42.0
	Game.owned["bucket"] = 2
	Game.placed_in_area().append({"id": "bucket", "x": 50.0, "y": 150.0})
	Game.levels["drip"] = 3
	var d: Dictionary = JSON.parse_string(JSON.stringify(Game.to_dict()))
	Game.reset()
	d["saved_at"] = 0.0
	Game.from_dict(d)
	check(is_equal_approx(Game.resonance, 42.0), "resonance survives save")
	check(Game.owned.get("bucket", 0) == 2, "owned survives save")
	check(Game.level("drip") == 3, "levels survive save")
	check(Game.placed_count("bucket") == 1, "placements survive save")
	check(Game.free_count("bucket") == 1, "free count after load")


func _test_scale() -> void:
	check(is_equal_approx(Synth.degree_ratio(0), 1.0), "degree 0")
	check(is_equal_approx(Synth.degree_ratio(5), 2.0), "degree 5 is an octave")
	check(is_equal_approx(Synth.degree_ratio(-5), 0.5), "degree -5 is an octave down")
	check(Synth.degree_ratio(3) > Synth.degree_ratio(2), "scale ascends")


func _test_drum_defs() -> void:
	for id in DrumDefs.ORDER:
		check(DrumDefs.DEFS.has(id), "def exists: " + id)
		var img := DrumDefs.make_image(id)
		check(img.get_width() > 3 and img.get_height() > 3, "sprite size: " + id)
		var lid: Array = DrumDefs.get_def(id).lid
		check(lid[0] >= 0 and lid[1] < img.get_width() and lid[0] <= lid[1], "lid inside sprite: " + id)
	var prev := -1.0
	for id in DrumDefs.ORDER:
		var c: float = DrumDefs.get_def(id).cost
		check(c >= prev, "costs ascend: " + id)
		prev = c


func _test_catch() -> void:
	var d := Drum.new()
	d.setup("bucket")
	d.position = Vector2(100, 150)
	add_child(d)
	var sy := d.surface_y()
	var hits_before := Game.total_earned
	check(d.try_catch(100.0, sy - 2.0, sy + 1.0, 150.0, 1.0), "drop over the lid is caught")
	check(Game.total_earned > hits_before, "catch earns")
	check(not d.try_catch(100.0, sy - 2.0, sy + 1.0, 120.0, 1.0), "drop at other depth passes")
	check(not d.try_catch(60.0, sy - 2.0, sy + 1.0, 150.0, 1.0), "drop beside it passes")
	check(d.contains(Vector2(100, 145)), "contains body pixel")
	d.queue_free()


func _test_synth() -> void:
	for id in DrumDefs.ORDER:
		check(Synth.sample(id, true) != Synth.sample(id), "soft take differs: " + id)
		check(Synth.sample(id, false, 0) != Synth.sample(id, false, 2), "raw take differs: " + id)
		var s := Synth.sample(id)
		check(s.data.size() > 2000, "sample has data: " + id)
		var peak := 0
		for i in range(0, mini(s.data.size(), 20000), 2):
			peak = maxi(peak, absi(s.data.decode_s16(i)))
		check(peak > 8000, "sample is audible: %s (%d)" % [id, peak])


func _test_musicality() -> void:
	Game.reset()
	check(Game.musicality() == 0, "starts as plain rain")
	Game.owned = {"can": 1, "bucket": 1, "helmet": 1}
	check(Game.musicality() == 1, "three kinds: in between")
	Game.owned = {"can": 1, "bucket": 1, "helmet": 1, "pot": 1, "bottle": 1, "drum": 1}
	check(Game.musicality() == 2, "six kinds: music")
	Game.reset()


func _test_capacity() -> void:
	Game.reset()
	check(not Game.area_full(), "empty area is not full")
	for i in Game.capacity():
		Game.placed_in_area().append({"id": "can", "x": 10.0 + i, "y": 150.0})
	check(Game.area_full(), "area full at capacity")
	Game.area = "rail"
	check(not Game.area_full(), "other area has its own room")
	check(Game.capacity() > Game.AREA_CAP["roof"], "deeper areas hold more")
	Game.reset()


func _test_journal() -> void:
	var ids := {}
	for e in Journal.ENTRIES:
		check(not ids.has(e[0]), "journal id unique: " + e[0])
		ids[e[0]] = true
		check(UiKit.text_width(e[1]) <= 290.0, "journal line fits: %s (%d)" % [e[0], UiKit.text_width(e[1])])
	Game.reset()
	check(Journal.reached(0).is_empty(), "nothing reached at start")
	check("first_hit" in Journal.reached(1), "first hit line")


func _test_disk_save() -> void:
	Game.reset()
	Game._no_save = false
	Game.resonance = 777.0
	Game.save_game()
	Game.resonance = 1.0
	Game.save_game() # first save becomes the .bak
	Game.resonance = 0.0
	Game.load_game()
	check(is_equal_approx(Game.resonance, 1.0), "loads latest save")
	# Corrupt the main file: the backup must be used.
	var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	Game.resonance = 0.0
	Game.load_game()
	check(is_equal_approx(Game.resonance, 777.0), "falls back to backup")
	var dir := DirAccess.open("user://")
	for name in [Game.SAVE_PATH.get_file(), Game.SAVE_PATH.get_file() + ".bak"]:
		dir.remove(name)
	Game._no_save = true
	Game.reset()


func _test_distant() -> void:
	for kind in Synth.DISTANT:
		var wav: AudioStreamWAV = Synth._make_distant(kind)
		var peak := 0
		for i in range(0, wav.data.size(), 2):
			peak = maxi(peak, absi(wav.data.decode_s16(i)))
		check(wav.data.size() > 20000 and peak > 10000, "distant sound audible: " + kind)

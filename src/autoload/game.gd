extends Node
## Game state: the 響き (resonance) economy, unlocks, upgrades and saving.

signal changed
signal unlocked(what: String)

const SAVE_PATH := "user://rainpans.save.json"
const SAVE_VERSION := 1
const OFFLINE_CAP_SEC := 8.0 * 3600.0
const OFFLINE_RATE := 0.5

## Upgrades: each has levels with a cost curve. Effects are read via getters.
const UPGRADES := {
	"rain": {
		"name": "雨脚",
		"desc": "雨が少しずつ強くなる。",
		"base": 50.0, "growth": 4.5, "max": 10,
	},
	"drip": {
		"name": "雨樋",
		"desc": "ひさしから落ちるしずくが増える。",
		"base": 300.0, "growth": 5.0, "max": 6,
	},
	"reverb": {
		"name": "残響",
		"desc": "響きが長く残り、すべての響きが増える。",
		"base": 2000.0, "growth": 6.0, "max": 5,
	},
	"echo": {
		"name": "こだま",
		"desc": "遠くの壁から音が返ってくる。響き +50%。",
		"base": 1.0e6, "growth": 1.0, "max": 1,
	},
	"lamp": {
		"name": "灯り",
		"desc": "ランタンの芯を足す。暗がりの響き +25%。",
		"base": 5.0e4, "growth": 12.0, "max": 3,
	},
	"time": {
		"name": "夜をすすめる",
		"desc": "時間が流れはじめる。夕暮れから夜明けまで。",
		"base": 3.0e6, "growth": 1.0, "max": 1,
	},
	"wait": {
		"name": "雨上がりを待つ",
		"desc": "いちばん深い場所で、雨がやむのを待つ。",
		"base": 5.0e12, "growth": 1.0, "max": 1, "requires": "canal",
	},
}

const AREAS := ["roof", "rail", "canal"]
const AREA_COST := {"roof": 0.0, "rail": 5.0e7, "canal": 5.0e10}
## Each deeper place carries sound further: a flat multiplier while you are there.
const AREA_MULT := {"roof": 1.0, "rail": 3.0, "canal": 9.0}
## How many rain drums each place can hold.
const AREA_CAP := {"roof": 20, "rail": 24, "canal": 28}

var resonance := 0.0
var total_earned := 0.0
var levels := {}
## drum id -> number of copies owned (placed or on the shelf)
var owned := {"can": 1}
## area id -> Array of {id, x, y}
var placements := {}
var area := "roof"
var areas_open := ["roof"]
var settings := {"master": 0.8, "drums": 0.9, "ambience": 0.8, "quantize": false}
var play_time := 0.0
var hits_total := 0
var journal: Array = [] # ids of 雨の手帳 lines already seen
var tutorial := 0 # onboarding step (see Hud._tutorial)

## rolling income estimate (per second) used for display and offline gains
var rate := 0.0
var _rate_acc := 0.0
var _rate_t := 0.0
var _save_t := 0.0
var offline_gain := 0.0
var debug_phase := -1.0 # forces time of day (screenshots)
var _no_save := false
var _dirty := false # earn() batches its `changed` signal to once per frame


func _ready() -> void:
	for k in UPGRADES:
		levels[k] = 0
	_no_save = "--no-save" in OS.get_cmdline_user_args()
	if not _no_save:
		load_game()
	apply_audio()


func _process(delta: float) -> void:
	play_time += delta
	if _dirty:
		_dirty = false
		changed.emit()
	_rate_t += delta
	if _rate_t >= 2.0:
		var inst := _rate_acc / _rate_t
		rate = inst if rate == 0.0 else lerpf(rate, inst, 0.25)
		_rate_acc = 0.0
		_rate_t = 0.0
	_save_t += delta
	if _save_t > 15.0:
		_save_t = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


# ------------------------------------------------------------------- economy

func multiplier() -> float:
	var m := 1.0
	# Heavier rain: denser drops (see rain_rate) and weightier ones.
	m *= pow(1.2, level("rain"))
	m *= AREA_MULT.get(area, 1.0)
	m *= 1.0 + 0.2 * level("reverb")
	if level("echo") > 0:
		m *= 1.5
	m *= 1.0 + 0.25 * level("lamp")
	# Every distinct drum type you have placed in this area adds harmony.
	m *= 1.0 + 0.1 * maxi(0, distinct_placed() - 1)
	return m


func earn(base: float) -> float:
	var v := base * multiplier()
	hits_total += 1
	resonance += v
	total_earned += v
	_rate_acc += v
	_dirty = true
	return v


func level(id: String) -> int:
	return levels.get(id, 0)


func upgrade_cost(id: String) -> float:
	var u: Dictionary = UPGRADES[id]
	return u.base * pow(u.growth, level(id))


func upgrade_available(id: String) -> bool:
	var req: String = UPGRADES[id].get("requires", "")
	return req == "" or req in areas_open


func can_upgrade(id: String) -> bool:
	return upgrade_available(id) and level(id) < UPGRADES[id].max and resonance >= upgrade_cost(id)


func buy_upgrade(id: String) -> bool:
	if not can_upgrade(id):
		return false
	resonance -= upgrade_cost(id)
	levels[id] = level(id) + 1
	apply_audio()
	unlocked.emit("upgrade:" + id)
	changed.emit()
	return true


func drum_cost(id: String) -> float:
	var d := DrumDefs.get_def(id)
	var n: int = owned.get(id, 0)
	var base: float = d.cost
	if base <= 0.0:
		base = 10.0
	# The first copy of a new type costs its unlock price; copies get dearer.
	return base * pow(d.growth, n) if n > 0 else base


func drum_visible(id: String) -> bool:
	# A drum shows on the shelf once you could almost afford it.
	var idx := DrumDefs.ORDER.find(id)
	if owned.get(id, 0) > 0 or idx <= 1:
		return true
	var prev: String = DrumDefs.ORDER[idx - 1]
	return owned.get(prev, 0) > 0 and total_earned >= DrumDefs.get_def(id).cost * 0.25


func buy_drum(id: String) -> bool:
	var c := drum_cost(id)
	if resonance < c:
		return false
	resonance -= c
	var first: bool = owned.get(id, 0) == 0
	owned[id] = owned.get(id, 0) + 1
	if first:
		unlocked.emit("drum:" + id)
	changed.emit()
	return true


func placed_in_area() -> Array:
	if not placements.has(area):
		placements[area] = []
	return placements[area]


## Copies of `id` placed in the current area. Each area has its own
## arrangement drawn from the same owned pool.
func placed_count(id: String) -> int:
	var n := 0
	for p in placed_in_area():
		if p.id == id:
			n += 1
	return n


func free_count(id: String) -> int:
	return owned.get(id, 0) - placed_count(id)


func distinct_placed() -> int:
	var seen := {}
	for p in placed_in_area():
		seen[p.id] = true
	return seen.size()


func capacity() -> int:
	return AREA_CAP.get(area, 20)


func area_full() -> bool:
	return placed_in_area().size() >= capacity()


func area_cost(id: String) -> float:
	return AREA_COST[id]


func open_area(id: String) -> bool:
	if id in areas_open:
		return true
	if resonance < area_cost(id):
		return false
	resonance -= area_cost(id)
	areas_open.append(id)
	unlocked.emit("area:" + id)
	changed.emit()
	return true


## Rain intensity in drops/sec for the main (collidable) layer.
## `rain_scale` lets the ending let the rain die away.
var rain_scale := 1.0


func rain_rate() -> float:
	return 110.0 * pow(1.12, level("rain")) * rain_scale


## 0..1 used by visuals/audio to pick drizzle..downpour looks.
func rain_level() -> float:
	return clampf(level("rain") / 10.0, 0.0, 1.0) * 0.85 + 0.15


func apply_audio() -> void:
	if not is_inside_tree():
		return
	var synth := get_node_or_null("/root/Synth")
	if synth == null:
		return
	synth.set_echo(level("echo") > 0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, settings.master)))
	AudioServer.set_bus_volume_db(1, linear_to_db(maxf(0.0001, settings.get("drums", 0.9))))
	AudioServer.set_bus_volume_db(2, linear_to_db(maxf(0.0001, settings.get("ambience", 0.8))))


# ---------------------------------------------------------------- formatting

static func fmt(v: float) -> String:
	if v < 1000.0:
		return str(int(floor(v)))
	var units := ["k", "M", "B", "T", "Qa", "Qi"]
	var i := -1
	while v >= 1000.0 and i < units.size() - 1:
		v /= 1000.0
		i += 1
	if v < 10.0:
		return "%.2f%s" % [v, units[i]]
	if v < 100.0:
		return "%.1f%s" % [v, units[i]]
	return "%d%s" % [int(v), units[i]]


# -------------------------------------------------------------------- saving

func to_dict() -> Dictionary:
	return {
		"v": SAVE_VERSION,
		"resonance": resonance,
		"total": total_earned,
		"levels": levels,
		"owned": owned,
		"placements": placements,
		"area": area,
		"areas_open": areas_open,
		"settings": settings,
		"rate": rate,
		"play_time": play_time,
		"hits": hits_total,
		"journal": journal,
		"tutorial": tutorial,
		"saved_at": Time.get_unix_time_from_system(),
	}


func from_dict(d: Dictionary) -> void:
	resonance = d.get("resonance", 0.0)
	total_earned = d.get("total", 0.0)
	for k in d.get("levels", {}):
		if UPGRADES.has(k):
			levels[k] = int(d.levels[k])
	owned = {}
	for k in d.get("owned", {"can": 1}):
		if DrumDefs.DEFS.has(k):
			owned[k] = int(d.owned[k])
	placements = {}
	var pl: Dictionary = d.get("placements", {})
	for a in pl:
		var arr := []
		for p in pl[a]:
			if DrumDefs.DEFS.has(p.get("id", "")):
				arr.append({"id": p.id, "x": float(p.x), "y": float(p.y), "tune": int(p.get("tune", 0))})
		placements[a] = arr
	area = d.get("area", "roof")
	areas_open = d.get("areas_open", ["roof"])
	var s: Dictionary = d.get("settings", {})
	for k in s:
		settings[k] = s[k]
	rate = d.get("rate", 0.0)
	play_time = d.get("play_time", 0.0)
	hits_total = int(d.get("hits", 0))
	journal = d.get("journal", [])
	tutorial = int(d.get("tutorial", 99))
	var saved_at: float = d.get("saved_at", 0.0)
	if saved_at > 0.0:
		var away := clampf(Time.get_unix_time_from_system() - saved_at, 0.0, OFFLINE_CAP_SEC)
		if away > 60.0 and rate > 0.0:
			offline_gain = rate * away * OFFLINE_RATE
			resonance += offline_gain
			total_earned += offline_gain


## Writes to a temp file first and swaps it in, keeping the previous save as
## a backup, so a crash mid-write never loses progress.
func save_game() -> void:
	if _no_save:
		return
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if FileAccess.file_exists(SAVE_PATH):
		dir.rename(SAVE_PATH.get_file(), SAVE_PATH.get_file() + ".bak")
	dir.rename(tmp.get_file(), SAVE_PATH.get_file())


func load_game() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			from_dict(parsed)
			return


func reset() -> void:
	resonance = 0.0
	total_earned = 0.0
	for k in UPGRADES:
		levels[k] = 0
	owned = {"can": 1}
	placements = {}
	area = "roof"
	areas_open = ["roof"]
	rate = 0.0
	hits_total = 0
	journal = []
	tutorial = 0
	play_time = 0.0
	apply_audio()
	changed.emit()

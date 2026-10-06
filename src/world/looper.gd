class_name Looper
extends Node
## A tiny phrase looper. R starts recording hand-played notes, R again stops
## and the phrase (rounded up to whole beats at 72 BPM) loops quietly under
## the rain. Backspace clears it. Loops are kept per area in the save.

signal state_changed

const BEAT := 60.0 / 72.0
const MAX_BEATS := 32

var stage: Stage
var recording := false
var length := 0.0 # seconds, 0 = no loop
var notes: Array = [] # [time_offset, placement_index, velocity]
var _rec_start := 0.0
var _clock := 0.0
var _pos := 0.0
var _next := 0


func _ready() -> void:
	load_from_save()


func load_from_save() -> void:
	var saved: Dictionary = Game.loops.get(Game.area, {})
	length = saved.get("length", 0.0)
	notes = saved.get("notes", []).duplicate(true)
	recording = false
	_pos = 0.0
	_next = 0
	state_changed.emit()


func _store() -> void:
	if length > 0.0:
		Game.loops[Game.area] = {"length": length, "notes": notes}
	else:
		Game.loops.erase(Game.area)


func toggle_record() -> void:
	if recording:
		recording = false
		var raw := _clock - _rec_start
		if notes.is_empty():
			length = 0.0
		else:
			length = clampf(ceilf(raw / BEAT - 0.25), 1.0, MAX_BEATS) * BEAT
			notes.sort_custom(func(a, b): return a[0] < b[0])
		_pos = 0.0
		_next = 0
		_store()
	else:
		recording = true
		notes.clear()
		length = 0.0
		_rec_start = _clock
	state_changed.emit()


func clear() -> void:
	recording = false
	notes.clear()
	length = 0.0
	_store()
	state_changed.emit()


## Called by the stage whenever the player strikes a drum by hand.
func on_hand_strike(d: Drum, vel: float) -> void:
	if not recording:
		return
	if notes.is_empty():
		_rec_start = _clock # the phrase starts at its first note
	var idx := Game.placed_in_area().find(d.get_meta("entry"))
	if idx >= 0 and _clock - _rec_start < MAX_BEATS * BEAT:
		notes.append([_clock - _rec_start, idx, vel])


func progress() -> float:
	return _pos / length if length > 0.0 else 0.0


func _process(delta: float) -> void:
	_clock += delta
	if recording or length <= 0.0 or notes.is_empty() or stage == null:
		return
	var prev := _pos
	_pos += delta
	if _pos >= length:
		_pos -= length
		_fire_until(prev, length)
		prev = 0.0
		_next = 0
	_fire_until(prev, _pos)


func _fire_until(from: float, to: float) -> void:
	var placed := Game.placed_in_area()
	while _next < notes.size() and notes[_next][0] < to:
		var n: Array = notes[_next]
		_next += 1
		if n[0] < from:
			continue
		var idx: int = n[1]
		if idx >= placed.size():
			continue
		var d := stage.drum_for_entry(placed[idx])
		if d != null:
			# Echoes of your phrase: softer, and they earn like rain.
			d.strike(float(n[2]) * 0.7, false, true)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_R:
		toggle_record()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_BACKSPACE:
		clear()
		get_viewport().set_input_as_handled()

class_name Hud
extends CanvasLayer
## Overlay UI: the 響き counter, buttons, shelf, upgrade panel, info line,
## gentle toasts. Kept quiet and small on purpose.

signal drag_requested(id: String)
signal travel(area_id: String)

var root: Control
var top: TopBar
var shelf: Shelf
var upgrades: UpgradesPanel
var info_line: InfoLine
var settings: SettingsPanel
var stage: Stage


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size = Vector2(320, 180)
	add_child(root)

	top = TopBar.new()
	root.add_child(top)
	top.toggled_shelf.connect(toggle_shelf)
	top.toggled_upgrades.connect(toggle_upgrades)
	top.toggled_settings.connect(toggle_settings)

	shelf = Shelf.new()
	# The shelf hangs under the top bar, over the sky, so the floor stays free.
	shelf.position = Vector2(0, 18)
	shelf.visible = false
	root.add_child(shelf)
	shelf.drag_requested.connect(func(id): drag_requested.emit(id))
	shelf.info.connect(_info)

	upgrades = UpgradesPanel.new()
	upgrades.position = Vector2(320 - 136, 18)
	upgrades.visible = false
	root.add_child(upgrades)
	upgrades.info.connect(_info)
	upgrades.travel.connect(func(a): travel.emit(a))

	info_line = InfoLine.new()
	root.add_child(info_line)
	_layout()
	Game.unlocked.connect(_on_unlocked)


func bind_stage(s: Stage) -> void:
	stage = s
	if not stage.hover_changed.is_connected(_info):
		stage.hover_changed.connect(_info)
	_layout()


func toggle_shelf() -> void:
	shelf.visible = not shelf.visible
	_layout()


func toggle_settings() -> void:
	if settings and is_instance_valid(settings):
		settings.queue_free()
		settings = null
		_info("")
		return
	settings = SettingsPanel.new()
	root.add_child(settings)
	settings.closed.connect(toggle_settings)
	settings.open_journal.connect(func():
		toggle_settings()
		var jp := JournalPanel.new()
		root.add_child(jp))
	settings.info.connect(_info)


func toggle_upgrades() -> void:
	upgrades.visible = not upgrades.visible
	_layout()


func _layout() -> void:
	top.shelf_open = shelf.visible
	top.upgrades_open = upgrades.visible
	top.queue_redraw()
	info_line.position = Vector2(0, 168)
	upgrades.position = Vector2(320 - 136, (18 + Shelf.HEIGHT + 1) if shelf.visible else 18)
	if stage:
		stage.shelf_rect = Rect2(shelf.position, shelf.size) if shelf.visible else Rect2()


func _info(t: String) -> void:
	info_line.show_text(t)


func toast(t: String) -> void:
	info_line.toast(t)


## 雨の手帳 lines: longer, softer, in a cooler colour.
func journal_line(t: String) -> void:
	info_line.toast(t, 7.0, true)


func _on_unlocked(what: String) -> void:
	var parts := what.split(":")
	match parts[0]:
		"drum":
			toast("%s を見つけた" % DrumDefs.get_def(parts[1]).name)
		"area":
			toast("%s への道がひらいた" % AreaLibrary.NAMES[parts[1]])
		"upgrade":
			var u: Dictionary = Game.UPGRADES[parts[1]]
			toast("%s　Lv.%d" % [u.name, Game.level(parts[1])])
	if stage:
		stage.apply_upgrades()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB, KEY_B:
				toggle_shelf()
			KEY_U, KEY_E:
				toggle_upgrades()
			KEY_ESCAPE:
				toggle_settings()


# ---------------------------------------------------------------------------

class TopBar:
	extends Control
	signal toggled_shelf
	signal toggled_upgrades
	signal toggled_settings
	var shelf_open := false
	var upgrades_open := false
	var _shown := 0.0
	var _hover := -1
	const BTN_SET := Rect2(226, 3, 15, 13)
	const BTN_SHELF := Rect2(244, 3, 34, 13)
	const BTN_UP := Rect2(281, 3, 36, 13)

	func _ready() -> void:
		size = Vector2(320, 18)
		mouse_filter = Control.MOUSE_FILTER_PASS
		Game.changed.connect(queue_redraw)

	func _has_point(p: Vector2) -> bool:
		return BTN_SHELF.has_point(p) or BTN_UP.has_point(p) or BTN_SET.has_point(p)

	func _process(delta: float) -> void:
		# The counter eases toward the real value so it never jitters.
		var target := Game.resonance
		_shown = target if absf(target - _shown) < 1.0 else lerpf(_shown, target, minf(1.0, delta * 8.0))
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var h := 0 if BTN_SHELF.has_point(event.position) else (1 if BTN_UP.has_point(event.position) else (2 if BTN_SET.has_point(event.position) else -1))
			if h != _hover:
				_hover = h
				queue_redraw()
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if BTN_SHELF.has_point(event.position):
				toggled_shelf.emit()
				accept_event()
			elif BTN_UP.has_point(event.position):
				toggled_upgrades.emit()
				accept_event()
			elif BTN_SET.has_point(event.position):
				toggled_settings.emit()
				accept_event()

	func _draw() -> void:
		# A small drop icon then the number. No panel: it floats in the rain.
		var icon := ["..o..", ".o3o.", "o343o", "o344o", ".ooo."]
		var key := {"o": Pal.RAIN, "3": Pal.FOG1, "4": Pal.RAIN_HI}
		for y in icon.size():
			for x in icon[y].length():
				var ch: String = icon[y][x]
				if key.has(ch):
					draw_rect(Rect2(5 + x, 5 + y, 1, 1), key[ch])
		UiKit.text(self, Vector2(13, 2), Game.fmt(_shown), Pal.BONE)
		if Game.rate > 0.0:
			UiKit.text(self, Vector2(13, 12), "%s/秒" % Game.fmt(Game.rate), Pal.FOG2)
		_button(BTN_SHELF, "棚", shelf_open, _hover == 0)
		_button(BTN_UP, "手入れ", upgrades_open, _hover == 1)
		_button(BTN_SET, "", false, _hover == 2)
		# A tiny gear-less "settings" glyph: three dots.
		for k in 3:
			draw_rect(Rect2(BTN_SET.position.x + 4 + k * 3, BTN_SET.position.y + 6, 1, 1), Pal.RAIN)

	func _button(r: Rect2, label: String, on: bool, hover: bool) -> void:
		UiKit.panel(self, r, Pal.NIGHT2 if (on or hover) else Pal.NIGHT0, Pal.LAMP3 if on else Pal.NIGHT3)
		var tw := UiKit.text_width(label)
		UiKit.text(self, Vector2(r.position.x + floorf((r.size.x - tw) / 2.0), r.position.y + 1), label, Pal.LAMP1 if on else Pal.RAIN)


class InfoLine:
	extends Control
	var _text := ""
	var _toast := ""
	var _toast_t := 0.0

	func _ready() -> void:
		size = Vector2(320, 12)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func show_text(t: String) -> void:
		_text = t
		queue_redraw()

	var _soft := false
	var _quiet := 0.0

	func toast(t: String, secs := 4.0, soft := false) -> void:
		_toast = t
		_toast_t = secs
		_soft = soft
		_quiet = 0.0
		queue_redraw()

	## True when nothing has been shown for a little while.
	func idle() -> bool:
		return _toast_t <= 0.0 and _quiet > 6.0

	func _process(delta: float) -> void:
		if _toast_t > 0.0:
			_toast_t -= delta
			queue_redraw()
		else:
			_quiet += delta

	func _draw() -> void:
		var t := _text
		var col := Pal.RAIN
		if t == "" and _toast_t > 0.0:
			t = _toast
			col = Pal.LAMP1 if _toast_t > 0.6 or int(_toast_t * 10.0) % 2 == 0 else Pal.LAMP3
			if _soft:
				col = Pal.RAIN_HI if _toast_t > 0.8 else (Pal.RAIN if _toast_t > 0.4 else Pal.FOG1)
		if t == "":
			return
		var tw := UiKit.text_width(t)
		var x := floorf((320.0 - tw) / 2.0)
		UiKit.dither_strip(self, Rect2(x - 4, 0, tw + 8, 12), Pal.INK)
		UiKit.text(self, Vector2(x, 1), t, col)

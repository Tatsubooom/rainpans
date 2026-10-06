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

	shelf = Shelf.new()
	shelf.position = Vector2(0, 180 - Shelf.HEIGHT)
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
	stage.hover_changed.connect(_info)
	_layout()


func toggle_shelf() -> void:
	shelf.visible = not shelf.visible
	_layout()


func toggle_upgrades() -> void:
	upgrades.visible = not upgrades.visible
	_layout()


func _layout() -> void:
	top.shelf_open = shelf.visible
	top.upgrades_open = upgrades.visible
	top.queue_redraw()
	info_line.position = Vector2(0, (180 - Shelf.HEIGHT - 12) if shelf.visible else 168)
	if stage:
		stage.shelf_rect = Rect2(shelf.position, shelf.size) if shelf.visible else Rect2()


func _info(t: String) -> void:
	info_line.show_text(t)


func toast(t: String) -> void:
	info_line.toast(t)


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


# ---------------------------------------------------------------------------

class TopBar:
	extends Control
	signal toggled_shelf
	signal toggled_upgrades
	var shelf_open := false
	var upgrades_open := false
	var _shown := 0.0
	var _hover := -1
	const BTN_SHELF := Rect2(244, 3, 34, 13)
	const BTN_UP := Rect2(281, 3, 36, 13)

	func _ready() -> void:
		size = Vector2(320, 18)
		mouse_filter = Control.MOUSE_FILTER_PASS
		Game.changed.connect(queue_redraw)

	func _has_point(p: Vector2) -> bool:
		return BTN_SHELF.has_point(p) or BTN_UP.has_point(p)

	func _process(delta: float) -> void:
		# The counter eases toward the real value so it never jitters.
		var target := Game.resonance
		_shown = target if absf(target - _shown) < 1.0 else lerpf(_shown, target, minf(1.0, delta * 8.0))
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var h := 0 if BTN_SHELF.has_point(event.position) else (1 if BTN_UP.has_point(event.position) else -1)
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

	func toast(t: String) -> void:
		_toast = t
		_toast_t = 4.0
		queue_redraw()

	func _process(delta: float) -> void:
		if _toast_t > 0.0:
			_toast_t -= delta
			queue_redraw()

	func _draw() -> void:
		var t := _text
		var col := Pal.RAIN
		if t == "" and _toast_t > 0.0:
			t = _toast
			col = Pal.LAMP1 if _toast_t > 0.6 or int(_toast_t * 10.0) % 2 == 0 else Pal.LAMP3
		if t == "":
			return
		var tw := UiKit.text_width(t)
		var x := floorf((320.0 - tw) / 2.0)
		UiKit.dither_strip(self, Rect2(x - 4, 0, tw + 8, 12), Pal.INK)
		UiKit.text(self, Vector2(x, 1), t, col)

class_name UpgradesPanel
extends Control
## 手入れ: upgrades and travel between areas.

signal info(text: String)
signal travel(area_id: String)

const ROW_H := 11
const SEP_H := 5
const ORDER := ["rain", "drip", "reverb", "lamp", "echo", "time", "wait"]

var _hover := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	Game.changed.connect(queue_redraw)
	size = Vector2(132, 16 + (ORDER.size() + Game.AREAS.size()) * ROW_H + SEP_H + 3)


func _rows() -> Array:
	var rows := []
	for id in ORDER:
		rows.append({"kind": "up", "id": id})
	rows.append({"kind": "sep"})
	for a in Game.AREAS:
		rows.append({"kind": "area", "id": a})
	return rows


func _row_y(i: int) -> int:
	# Rows after the separator are shifted by the separator height.
	var sep := ORDER.size()
	if i < sep:
		return 16 + i * ROW_H
	if i == sep:
		return 16 + sep * ROW_H
	return 16 + (i - 1) * ROW_H + SEP_H


func _row_at(p: Vector2) -> int:
	var rows := _rows()
	for i in rows.size():
		var y := _row_y(i)
		var hgt := SEP_H if rows[i].kind == "sep" else ROW_H
		if p.y >= y and p.y < y + hgt:
			return -1 if rows[i].kind == "sep" else i
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var i := _row_at(event.position)
		if i != _hover:
			_hover = i
			queue_redraw()
			info.emit(_describe(i))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _row_at(event.position)
		if i < 0:
			return
		var row: Dictionary = _rows()[i]
		if row.kind == "up":
			Game.buy_upgrade(row.id)
		elif row.kind == "area":
			if row.id in Game.areas_open:
				travel.emit(row.id)
			elif Game.open_area(row.id):
				travel.emit(row.id)
		info.emit(_describe(i))
		accept_event()
	accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover = -1
		info.emit("")
		queue_redraw()


func _describe(i: int) -> String:
	if i < 0:
		return ""
	var row: Dictionary = _rows()[i]
	match row.kind:
		"up":
			var u: Dictionary = Game.UPGRADES[row.id]
			if not Game.upgrade_available(row.id):
				return "？？？　もっと深い場所で"
			if Game.level(row.id) >= u.max:
				return "%s　%s　（これ以上はない）" % [u.name, u.desc]
			return "%s　%s　響き %s" % [u.name, u.desc, Game.fmt(Game.upgrade_cost(row.id))]
		"area":
			var n: String = AreaLibrary.NAMES[row.id]
			if row.id == Game.area:
				return "%s　（いまいる場所）" % n
			if row.id in Game.areas_open:
				return "%s へ移る" % n
			return "%s　響き %s で道がひらく" % [n, Game.fmt(Game.area_cost(row.id))]
	return ""


func _draw() -> void:
	UiKit.panel(self, Rect2(Vector2.ZERO, size))
	UiKit.text(self, Vector2(5, 3), "手入れ", Pal.RAIN)
	var rows := _rows()
	for i in rows.size():
		var row: Dictionary = rows[i]
		var y := _row_y(i)
		if i == _hover and row.kind != "sep":
			draw_rect(Rect2(2, y, size.x - 4, ROW_H), Pal.NIGHT2)
		match row.kind:
			"sep":
				draw_rect(Rect2(5, y + 2, size.x - 10, 1), Pal.NIGHT3)
			"up":
				var u: Dictionary = Game.UPGRADES[row.id]
				var lv := Game.level(row.id)
				var maxed: bool = lv >= u.max
				var cost := Game.upgrade_cost(row.id)
				var name_col := Pal.BONE if lv > 0 else Pal.FOG2
				if not Game.upgrade_available(row.id):
					UiKit.text(self, Vector2(5, y), "？？？", Pal.NIGHT3)
					continue
				UiKit.text(self, Vector2(5, y), u.name, name_col)
				var label := "—" if maxed else Game.fmt(cost)
				var lc := Pal.FOG1 if maxed else (Pal.LAMP1 if Game.resonance >= cost else Pal.FOG1)
				var lw := UiKit.text_width(label)
				UiKit.text(self, Vector2(size.x - 5 - lw, y), label, lc)
				# Level pips sit just left of the price.
				var pips: int = mini(u.max, 10)
				var px0 := size.x - 5 - lw - 4 - pips * 3
				for k in pips:
					var col := Pal.LAMP2 if k < lv else Pal.NIGHT3
					draw_rect(Rect2(px0 + k * 3, y + 5, 2, 2), col)
			"area":
				var n: String = AreaLibrary.NAMES[row.id]
				var open: bool = row.id in Game.areas_open
				var here: bool = row.id == Game.area
				var col := Pal.LAMP1 if here else (Pal.BONE if open else Pal.FOG1)
				UiKit.text(self, Vector2(5, y), ("▸ " if here else "　") + n, col)
				if not open:
					var label := Game.fmt(Game.area_cost(row.id))
					var lc := Pal.LAMP1 if Game.resonance >= Game.area_cost(row.id) else Pal.FOG1
					UiKit.text(self, Vector2(size.x - 5 - UiKit.text_width(label), y), label, lc)

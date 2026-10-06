class_name JournalPanel
extends Control
## Reads back the 雨の手帳 lines found so far. Click to turn the page,
## right-click (or Esc) to close.

const PER_PAGE := 10
const ROW_H := 13

var _page := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(304, 18 + PER_PAGE * ROW_H + 14)
	position = Vector2(8, floorf((180 - size.y) / 2.0))


func _pages() -> int:
	return maxi(1, ceili(Journal.ENTRIES.size() / float(PER_PAGE)))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT or _page + 1 >= _pages():
			queue_free()
		else:
			_page += 1
			queue_redraw()
	accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	UiKit.panel(self, Rect2(Vector2.ZERO, size), Pal.NIGHT0, Pal.NIGHT3)
	UiKit.text(self, Vector2(6, 3), "雨の手帳", Pal.RAIN)
	var pg := "%d / %d" % [_page + 1, _pages()]
	UiKit.text(self, Vector2(size.x - 6 - UiKit.text_width(pg), 3), pg, Pal.FOG1)
	for i in PER_PAGE:
		var idx := _page * PER_PAGE + i
		if idx >= Journal.ENTRIES.size():
			break
		var e: Array = Journal.ENTRIES[idx]
		var y := 18 + i * ROW_H
		if e[0] in Game.journal:
			UiKit.text(self, Vector2(8, y), e[1], Pal.BONE)
		else:
			UiKit.text(self, Vector2(8, y), "・・・", Pal.NIGHT3)
	var hint := "クリックで次へ" if _page + 1 < _pages() else "クリックで閉じる"
	UiKit.text(self, Vector2(size.x - 6 - UiKit.text_width(hint), size.y - 13), hint, Pal.FOG0)

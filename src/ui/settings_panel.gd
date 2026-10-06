class_name SettingsPanel
extends Control
## Quiet settings: volumes, beat quantize, fullscreen, erase the save.

signal closed
signal info(text: String)

const ROW_H := 13
const W := 168

var _hover := -1
var _confirm_reset := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(W, 18 + _rows().size() * ROW_H + 4)
	position = Vector2(floorf((320 - size.x) / 2.0), floorf((180 - size.y) / 2.0))


func _rows() -> Array:
	return ["master", "drums", "ambience", "quantize", "fullscreen", "reset", "close"]


func _label(id: String) -> String:
	var s: Dictionary = Game.settings
	match id:
		"master":
			return "全体の音量　　%3d%%" % int(round(s.master * 100))
		"drums":
			return "雨受けの音　　%3d%%" % int(round(s.get("drums", 0.9) * 100))
		"ambience":
			return "雨そのものの音 %3d%%" % int(round(s.get("ambience", 0.8) * 100))
		"quantize":
			return "拍にそろえる　　" + ("する" if s.get("quantize", false) else "しない")
		"fullscreen":
			var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			return "全画面　　　　　" + ("する" if fs else "しない")
		"reset":
			return "もう一度押すと消える" if _confirm_reset > 0.0 else "記録を消す"
		"close":
			return "閉じる"
	return ""


func _describe(id: String) -> String:
	match id:
		"master", "drums", "ambience":
			return "左クリックで上げる／右クリックで下げる"
		"quantize":
			return "雨粒の音を、ゆっくりした拍にそっと寄せる"
		"reset":
			return "響きも雨受けも、すべて最初から"
	return ""


func _process(delta: float) -> void:
	if _confirm_reset > 0.0:
		_confirm_reset -= delta
		if _confirm_reset <= 0.0:
			queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var rows := _rows()
	if event is InputEventMouseMotion:
		var i := int((event.position.y - 18) / ROW_H) if event.position.y >= 18 else -1
		if i >= rows.size():
			i = -1
		if i != _hover:
			_hover = i
			info.emit(_describe(rows[i]) if i >= 0 else "")
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if _hover < 0:
			accept_event()
			return
		var up: bool = event.button_index == MOUSE_BUTTON_LEFT
		_activate(rows[_hover], up)
		queue_redraw()
	accept_event()


func _activate(id: String, up: bool) -> void:
	var s: Dictionary = Game.settings
	match id:
		"master", "drums", "ambience":
			var v: float = s.get(id, 0.8)
			v = clampf(snappedf(v + (0.1 if up else -0.1), 0.1), 0.0, 1.0)
			s[id] = v
			Game.apply_audio()
			Synth.play("can", 2, Vector2(160, 90), 0.5, -3)
		"quantize":
			s.quantize = not s.get("quantize", false)
		"fullscreen":
			var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		"reset":
			if _confirm_reset > 0.0:
				_confirm_reset = 0.0
				Game.reset()
				Game.save_game()
				get_tree().reload_current_scene()
			else:
				_confirm_reset = 3.0
		"close":
			closed.emit()
	Game.save_game()


func _draw() -> void:
	UiKit.panel(self, Rect2(Vector2.ZERO, size), Pal.NIGHT0, Pal.NIGHT3)
	UiKit.text(self, Vector2(6, 3), "しずかな設定", Pal.RAIN)
	var rows := _rows()
	for i in rows.size():
		var y := 18 + i * ROW_H
		if i == _hover:
			draw_rect(Rect2(2, y, size.x - 4, ROW_H), Pal.NIGHT2)
		var col := Pal.BONE
		if rows[i] == "reset":
			col = Pal.LAMP2 if _confirm_reset > 0.0 else Pal.FOG2
		elif rows[i] == "close":
			col = Pal.RAIN
		UiKit.text(self, Vector2(8, y + 1), _label(rows[i]), col)

class_name HelpPanel
extends Control
## あそびかた: every control on one quiet card. Click or Esc to close.

const LINES := [
	["棚（Tab）", "雨受けを買う。ドラッグで床へ"],
	["手入れ（U）", "雨脚・残響などの強化、場所の移動"],
	["クリック", "置いた雨受けを自分で鳴らす"],
	["ドラッグ", "動かす（左ほど低く、右ほど高い）"],
	["ホイール", "音程を上げ下げする"],
	["右クリック", "棚へ戻す"],
	["上に落とす", "置いてある雨受けと入れ替える"],
	["A〜L・1〜0", "左から順に鳴らす（キーで演奏）"],
	["R", "フレーズを録音、もう一度でループ"],
	["Backspace", "ループを消す"],
	["P", "写真モード（UI を隠す）"],
	["Esc", "設定・雨の手帳"],
]
const ROW_H := 11


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(300, 18 + LINES.size() * ROW_H + 14)
	position = Vector2(10, floorf((180 - size.y) / 2.0))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()
	accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	UiKit.panel(self, Rect2(Vector2.ZERO, size), Pal.NIGHT0, Pal.NIGHT3)
	UiKit.text(self, Vector2(6, 3), "あそびかた", Pal.RAIN)
	for i in LINES.size():
		var y := 17 + i * ROW_H
		UiKit.text(self, Vector2(8, y), LINES[i][0], Pal.LAMP1)
		UiKit.text(self, Vector2(98, y), LINES[i][1], Pal.BONE)
	var hint := "雨は勝手に降る。どこに何を置くかだけ、ゆっくり考えよう。"
	UiKit.text(self, Vector2(floorf((size.x - UiKit.text_width(hint)) / 2.0), size.y - 13), hint, Pal.FOG2)

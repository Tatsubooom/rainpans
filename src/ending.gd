class_name Ending
extends Node
## 雨上がり: the rain thins out and stops, dawn comes up, a quiet title card,
## and after a while the rain returns and play goes on.

var stage: Stage
var hud: Hud
var _t := 0.0
var _card: Control
var _said := {}

const RAIN_OUT := 45.0 # seconds for the rain to die away
const STILL := 40.0 # silence after
const BACK := 20.0 # rain coming back


func _ready() -> void:
	_card = Control.new()
	_card.size = Vector2(320, 180)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_card.draw.connect(_draw_card)
	hud.root.add_child(_card)


func _say(key: String, text: String, journal := false) -> void:
	if _said.has(key):
		return
	_said[key] = true
	if journal:
		hud.journal_line(text)
	else:
		hud.toast(text)


func _process(delta: float) -> void:
	_t += delta
	if _t < RAIN_OUT:
		var k := 1.0 - _t / RAIN_OUT
		Game.rain_scale = k * k
		Game.debug_phase = lerpf(0.55, 0.8, _t / RAIN_OUT)
		if _t > 4.0:
			_say("a", "雨脚が、少しずつ弱くなっていく。", true)
	elif _t < RAIN_OUT + STILL:
		Game.rain_scale = 0.0
		hud.top.visible = _t < RAIN_OUT + 4.0
		Game.debug_phase = lerpf(0.8, 0.86, (_t - RAIN_OUT) / STILL)
		_say("b", "雨が、やんだ。", true)
	elif _t < RAIN_OUT + STILL + BACK:
		hud.top.visible = true
		var k := (_t - RAIN_OUT - STILL) / BACK
		Game.rain_scale = k * k
		_say("c", "……また、雨の音がする。", true)
	else:
		Game.rain_scale = 1.0
		Game.debug_phase = -1.0
		if not "ending" in Game.journal:
			Game.journal.append("ending")
		Game.save_game()
		_card.queue_free()
		queue_free()
		return
	stage.apply_upgrades()
	_card.queue_redraw()


func _draw_card() -> void:
	# The title card fades in during the silence and out as the rain returns.
	var s := _t - RAIN_OUT - 6.0
	if s < 0.0 or s > STILL + 6.0:
		return
	var a := clampf(s / 4.0, 0.0, 1.0) * clampf((STILL + 6.0 - s) / 6.0, 0.0, 1.0)
	var tones := [Pal.NIGHT2, Pal.FOG0, Pal.FOG1, Pal.RAIN_HI]
	var col: Color = tones[mini(3, int(a * 3.99))]
	var lines := ["Rainpans", "", "おしまい", "最後まで聴いてくれて、ありがとう。"]
	if a > 0.3:
		UiKit.dither_strip(_card, Rect2(60, 56, 200, 4 * 13 + 10), Pal.INK)
	var y := 62
	for line in lines:
		if line != "":
			var w := UiKit.text_width(line)
			UiKit.text(_card, Vector2(floorf((320 - w) / 2.0), y), line, col, a > 0.5)
		y += 13

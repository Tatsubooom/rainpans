class_name Intro
extends CanvasLayer
## Opening: black, a title in the rain, then an ordered-dither dissolve
## into the scene. Any click or key skips.

const SHADER := """
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
const float B[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
void fragment() {
	ivec2 p = ivec2(UV * vec2(320.0, 180.0));
	float t = (B[(p.y % 4) * 4 + (p.x % 4)] + 0.5) / 16.0;
	if (t < progress) discard;
	COLOR = vec4(0.027, 0.035, 0.055, 1.0);
}
"""

var _t := 0.0
var _rect: ColorRect
var _text: Control
var _done := false
var title := "Rainpans"
var subtitle := "雨受けの屋上で"


func _ready() -> void:
	layer = 30
	scale = Vector2(UiKit.UI_SCALE, UiKit.UI_SCALE)
	_rect = ColorRect.new()
	_rect.size = Vector2(320, 180)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	mat.shader = sh
	_rect.material = mat
	add_child(_rect)
	_text = Control.new()
	_text.size = Vector2(320, 180)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.draw.connect(_draw_text)
	add_child(_text)
	_rect.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _skip())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_skip()


func _skip() -> void:
	if _t < 3.2:
		_t = 3.2


func _process(delta: float) -> void:
	_t += delta
	var p := clampf((_t - 3.2) / 2.2, 0.0, 1.0)
	(_rect.material as ShaderMaterial).set_shader_parameter("progress", p)
	_text.queue_redraw()
	if p >= 1.0 and not _done:
		_done = true
		queue_free()


func _draw_text() -> void:
	var a := clampf(_t / 1.2, 0.0, 1.0) * clampf((4.2 - _t) / 1.0, 0.0, 1.0)
	if a <= 0.0:
		return
	# Fade by stepping through palette tones instead of alpha.
	var tones := [Pal.NIGHT2, Pal.FOG0, Pal.FOG1, Pal.RAIN]
	var col: Color = tones[mini(3, int(a * 3.99))]
	var sub: Color = [Pal.NIGHT1, Pal.NIGHT3, Pal.FOG0, Pal.FOG1][mini(3, int(a * 3.99))]
	var tw := UiKit.text_width(title)
	UiKit.text(_text, Vector2(floorf((320 - tw) / 2.0), 76), title, col, false)
	var sw := UiKit.text_width(subtitle)
	UiKit.text(_text, Vector2(floorf((320 - sw) / 2.0), 92), subtitle, sub, false)
	# A few drops falling across the title.
	for i in 7:
		var x := 112 + i * 15
		var y := fmod(_t * 70.0 + i * 37.0, 120.0) + 30.0
		_text.draw_rect(Rect2(x, floorf(y), 1, 3), sub)

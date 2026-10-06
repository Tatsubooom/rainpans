class_name Reflection
extends Node2D
## The lantern mirrored on the wet floor: a broken vertical column of warm
## pixels that shivers as rain disturbs the surface.

var lamp := Vector2.ZERO
var floor_y := 130
var length := 26
var energy := 1.0
var _t := 0.0
var _noise := FastNoiseLite.new()


func setup(a: Dictionary) -> void:
	lamp = a.lamp
	floor_y = int(a.floor_y) + 3
	_noise.seed = 12
	_noise.frequency = 0.35


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if energy <= 0.05:
		return
	# Mirror of the lamp sits as far below the floor line as the lamp is above it.
	var mirror_y := floor_y + int((floor_y - lamp.y) * 0.35)
	for k in length:
		var y := mirror_y - length / 2 + k
		if y < floor_y:
			continue
		var fall := 1.0 - absf(float(k) / length * 2.0 - 1.0)
		var wob := _noise.get_noise_2d(k * 3.0, _t * 6.0)
		var w := int(round(fall * 2.5 + wob * 1.5))
		if w <= 0 or (k % 3 == 1 and wob > 0.2):
			continue
		var x0 := floorf(lamp.x + wob * 2.0 - w / 2.0)
		var col := Pal.LAMP2 if fall > 0.7 else (Pal.LAMP3 if fall > 0.35 else Pal.LAMP4)
		draw_rect(Rect2(x0, y, w, 1), Color(col, energy))

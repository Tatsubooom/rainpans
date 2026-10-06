class_name CanalWater
extends Node2D
## Slow-moving highlights on the canal channel.

var y0 := 167
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for row in range(y0 + 2, 180, 2):
		var depth := row - y0
		var speed := 6.0 + depth * 0.6
		var spacing := 21 + depth % 7
		var off := fmod(_t * speed + depth * 13.0, spacing)
		var x := -spacing + off
		while x < 320.0:
			var ln := 2 + int(absf(sin(x * 0.13 + depth)) * 4.0)
			var col := Pal.FOG0 if depth > 6 else Pal.NIGHT4
			draw_rect(Rect2(floorf(x), row, ln, 1), col)
			x += spacing

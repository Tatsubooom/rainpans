class_name PuddleMirror
extends Sprite2D
## Puddles that mirror the scene above them (after Kingdom's water): the
## screen is sampled upside down about the ground line, wobbled a pixel
## row by row as the rain disturbs it, and tinted dark and cool.

const SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float mirror_y = 262.0;   // ground line in world pixels
uniform vec2 view_size = vec2(640.0, 360.0);
uniform float strength = 0.7;
uniform vec4 tint : source_color = vec4(0.8, 0.88, 1.05, 1.0);

void fragment() {
	vec4 mask = texture(TEXTURE, UV);
	if (mask.a < 0.5) {
		discard;
	}
	vec2 p = floor(SCREEN_UV * view_size);
	// Each row of water shivers sideways by up to a pixel.
	float wob = floor(sin(p.y * 1.7 + TIME * 4.0) * 1.2 + sin(p.y * 0.6 - TIME * 2.3) * 0.8 + 0.5);
	vec2 q = vec2(p.x + wob, 2.0 * mirror_y - p.y);
	q = clamp(q, vec2(0.0), view_size - 1.0);
	vec3 refl = texture(screen_tex, (q + 0.5) / view_size).rgb;
	vec3 base = texture(screen_tex, (p + 0.5) / view_size).rgb;
	// Rows nearer the far edge mirror more brightly; the near edge is darker.
	float depth = mask.r;
	vec3 col = mix(base, refl * tint.rgb, strength * depth);
	COLOR = vec4(col, 1.0);
}
"""


## Builds the mirror for an area from its floor art and puddle rects.
func setup(a: Dictionary) -> void:
	var floor_img: Image = a.layers.floor
	var w := floor_img.get_width()
	var h := floor_img.get_height()
	var mask := Image.create(w, h, false, Image.FORMAT_RGBA8)
	mask.fill(Color(0, 0, 0, 0))
	var water := [Pal.NIGHT1, Pal.NIGHT2, Pal.NIGHT3]
	for pr in a.puddles:
		var r: Rect2 = pr
		for y in range(int(r.position.y) - 2, int(r.end.y) + 2):
			for x in range(int(r.position.x) - 2, int(r.end.x) + 2):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				if floor_img.get_pixel(x, y) in water:
					# Red channel carries "how far into the puddle" for shading.
					var t := clampf(1.0 - (y - r.position.y) / maxf(1.0, r.size.y) * 0.6, 0.3, 1.0)
					mask.set_pixel(x, y, Color(t, 0, 0, 1))
	texture = ImageTexture.create_from_image(mask)
	centered = false
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	mat.shader = sh
	mat.set_shader_parameter("mirror_y", float(a.get("mirror_y", a.floor_y)))
	mat.set_shader_parameter("view_size", Vector2(w, h))
	material = mat

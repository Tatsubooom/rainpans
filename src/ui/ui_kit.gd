class_name UiKit
## Shared pixel-UI helpers: the font and a few drawing primitives.

const FONT_SIZE := 10
static var _font: FontFile


static func font() -> FontFile:
	if _font == null:
		_font = load("res://assets/fonts/PixelMplus10-Regular.ttf")
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.hinting = TextServer.HINTING_NONE
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_font.force_autohinter = false
	return _font


## Draws text with its top-left at `pos` (not the baseline).
static func text(ci: CanvasItem, pos: Vector2, s: String, col: Color, shadow := true) -> void:
	var f := font()
	var base := pos + Vector2(0, f.get_ascent(FONT_SIZE))
	base = base.floor()
	if shadow:
		ci.draw_string(f, base + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Pal.INK)
	ci.draw_string(f, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, col)


static func text_width(s: String) -> float:
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


static func panel(ci: CanvasItem, r: Rect2, fill := Pal.NIGHT0, border := Pal.NIGHT3) -> void:
	ci.draw_rect(r, fill)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), border)
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), Pal.INK)
	ci.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), border)
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 1, 0), Vector2(1, r.size.y)), Pal.INK)


## Translucent strip using a checker dither instead of alpha. The caller's
## CanvasItem must have texture_repeat enabled.
static var _checker: ImageTexture


static func dither_strip(ci: CanvasItem, r: Rect2, col: Color) -> void:
	if _checker == null:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		img.set_pixel(0, 0, Color.WHITE)
		img.set_pixel(1, 1, Color.WHITE)
		_checker = ImageTexture.create_from_image(img)
	ci.draw_texture_rect(_checker, r, true, col)

class_name Shelf
extends Control
## The drum shelf along the bottom: buy copies, drag them into the world.

signal drag_requested(id: String)
signal info(text: String)

const SLOT_W := 28
const HEIGHT := 31

var _icons := {}
var _hover := -1
var _flash := {} # id -> time left (highlight just-bought)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	size = Vector2(320, HEIGHT)
	Game.changed.connect(queue_redraw)
	for id in DrumDefs.ORDER:
		_icons[id] = ImageTexture.create_from_image(DrumDefs.make_image(id))


func _slot_at(p: Vector2) -> int:
	var i := int((p.x - 6) / SLOT_W)
	if p.x < 6 or i < 0 or i >= DrumDefs.ORDER.size():
		return -1
	return i


func _process(delta: float) -> void:
	for k in _flash.keys():
		_flash[k] -= delta
		if _flash[k] <= 0.0:
			_flash.erase(k)
	if not _flash.is_empty():
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var i := _slot_at(event.position)
		if i != _hover:
			_hover = i
			queue_redraw()
			info.emit(_describe(i))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _slot_at(event.position)
		if i < 0:
			return
		var id: String = DrumDefs.ORDER[i]
		if not Game.drum_visible(id):
			return
		if Game.free_count(id) <= 0:
			if not Game.buy_drum(id):
				return
			_flash[id] = 0.4
			Synth.play(id, 0, Vector2(160, 90), 0.4, -2)
		drag_requested.emit(id)
		info.emit(_describe(i))
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover = -1
		info.emit("")
		queue_redraw()


func _describe(i: int) -> String:
	if i < 0:
		return ""
	var id: String = DrumDefs.ORDER[i]
	if not Game.drum_visible(id):
		return "？？？　まだ雨の音が足りない"
	var d := DrumDefs.get_def(id)
	var free := Game.free_count(id)
	if free > 0:
		return "%s　%s　（ドラッグで置く　%d/%d）" % [d.name, d.desc, Game.placed_in_area().size(), Game.capacity()]
	return "%s　%s　響き %s で手に入れる" % [d.name, d.desc, Game.fmt(Game.drum_cost(id))]


func _draw() -> void:
	UiKit.panel(self, Rect2(Vector2.ZERO, size), Pal.NIGHT0, Pal.NIGHT3)
	# How full this place is, as a row of pips along the bottom edge.
	var cap := Game.capacity()
	var used := Game.placed_in_area().size()
	for k in cap:
		var px := 6 + k * (308.0 / cap)
		draw_rect(Rect2(floorf(px), HEIGHT - 2, 2, 1), Pal.LAMP2 if k < used else Pal.NIGHT2)
	for i in DrumDefs.ORDER.size():
		var id: String = DrumDefs.ORDER[i]
		var x := 6 + i * SLOT_W
		var r := Rect2(x, 2, SLOT_W - 2, HEIGHT - 4)
		var visible := Game.drum_visible(id)
		var free := Game.free_count(id)
		var cost := Game.drum_cost(id)
		var afford := Game.resonance >= cost
		if i == _hover:
			draw_rect(r, Pal.NIGHT2)
		if _flash.has(id):
			draw_rect(r, Pal.LAMP4)
		var tex: ImageTexture = _icons[id]
		var ts := tex.get_size()
		# Big sprites are shown at half size so every slot fits.
		var scale := 1.0 if ts.x <= SLOT_W - 4 and ts.y <= 16 else 0.5
		var ds := (ts * scale).floor()
		var ip := Vector2(x + floorf((SLOT_W - 2 - ds.x) / 2.0), 2 + floorf(16 - ds.y))
		if not visible:
			draw_texture_rect(tex, Rect2(ip, ds), false, Color(0.0, 0.0, 0.0, 0.85))
			UiKit.text(self, Vector2(x + 10, 19), "?", Pal.FOG0)
			continue
		var mod := Color.WHITE if (free > 0 or afford) else Color(0.45, 0.48, 0.58)
		draw_texture_rect(tex, Rect2(ip, ds), false, mod)
		var label: String
		var col: Color
		if free > 0:
			label = "×%d" % free
			col = Pal.BONE
		else:
			label = Game.fmt(cost)
			col = Pal.LAMP1 if afford else Pal.FOG1
		var tw := UiKit.text_width(label)
		UiKit.text(self, Vector2(x + floorf((SLOT_W - 2 - tw) / 2.0), 19), label, col)

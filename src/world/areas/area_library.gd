class_name AreaLibrary
## Area id -> art + geometry, always in world pixels (640x360).
##
## Areas are composed on a 320x180 grid. They are painted through PixCanvas
## at 2x (fine edges, fine dithering, same design), and their geometry is
## doubled here. An area composed directly on the 640 grid declares "res": 2.

const NAMES := {"roof": "崩れた屋上", "rail": "途切れた高架", "glass": "割れた温室", "canal": "地下水路"}
const W := 640
const H := 360


static func build(id: String) -> Dictionary:
	var a: Dictionary
	PixCanvas.scale_k = 2
	match id:
		"rail":
			a = RailArt.build()
		"glass":
			a = GlassArt.build()
		"canal":
			a = CanalArt.build()
		_:
			a = RoofArt.build()
	PixCanvas.scale_k = 1
	if a.get("res", 1) == 1:
		a = upscale(a, 2)
	return a


## Geometry keys holding plain numbers (y positions) that must scale too.
const SCALAR_KEYS := ["drip_depth", "floor_y", "water_y"]
const SKIP_KEYS := ["name", "ambient", "lamp_color", "bed", "reverb_room", "smoke_steam", "res"]


static func upscale(a: Dictionary, k: int) -> Dictionary:
	var out := {}
	for key in a:
		var v = a[key]
		if key == "layers":
			var layers := {}
			for ln in v:
				var img: Image = v[ln]
				if img.get_width() < W:
					img = img.duplicate()
					img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
				layers[ln] = img
			out[key] = layers
		elif key in SKIP_KEYS:
			out[key] = v
		elif key in SCALAR_KEYS:
			out[key] = float(v) * k
		elif key == "roof_profile":
			var src: PackedFloat32Array = v
			var dst := PackedFloat32Array()
			dst.resize(src.size() * k)
			for i in dst.size():
				dst[i] = src[i / k] * k
			out[key] = dst
		elif key == "wander":
			out[key] = [float(v[0]) * k, float(v[1]) * k, float(v[2]) * k]
		elif key in ["broken", "trickles", "weeds"]:
			# Lists of [position or number, number]: everything is geometry.
			var arr := []
			for b in v:
				arr.append([_scale_value(b[0], k) if not (b[0] is int or b[0] is float) else b[0] * k, b[1] * k])
			out[key] = arr
		else:
			out[key] = _scale_value(v, k)
	out["res"] = k
	return out


static func _scale_value(v, k: int):
	if v is PackedVector2Array:
		var out := PackedVector2Array()
		for p in v:
			out.append(p * k)
		return out
	if v is Vector2:
		return v * k
	if v is Vector2i:
		return v * k
	if v is Rect2:
		return Rect2(v.position * k, v.size * k)
	if v is Array:
		var arr := []
		for e in v:
			# Weeds/blinks/trickles mix positions with sizes and timings:
			# only the geometric parts scale.
			arr.append(_scale_value(e, k) if (e is Vector2 or e is Rect2 or e is Array or e is PackedVector2Array) else e)
		return arr
	return v

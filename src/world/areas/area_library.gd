class_name AreaLibrary
## Area id -> art + geometry.

const NAMES := {"roof": "崩れた屋上", "rail": "途切れた高架", "glass": "割れた温室", "canal": "地下水路"}


static func build(id: String) -> Dictionary:
	match id:
		"rail":
			return RailArt.build()
		"glass":
			return GlassArt.build()
		"canal":
			return CanalArt.build()
		_:
			return RoofArt.build()

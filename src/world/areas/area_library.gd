class_name AreaLibrary
## Area id -> art + geometry.

const NAMES := {"roof": "崩れた屋上", "rail": "途切れた高架", "canal": "地下水路"}


static func build(id: String) -> Dictionary:
	match id:
		"rail":
			return RailArt.build()
		"canal":
			return CanalArt.build()
		_:
			return RoofArt.build()

class_name AreaLibrary
## Area id -> art + geometry.

const NAMES := {"roof": "崩れた屋上", "rail": "途切れた高架", "canal": "地下水路"}


static func build(id: String) -> Dictionary:
	match id:
		_:
			return RoofArt.build()

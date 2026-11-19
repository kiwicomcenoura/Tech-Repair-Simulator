extends RefCounted

const MODELS := [
	{
		"key": "intara_m100", "kind": "case", "model": "Intara Office M100", "brand": "Intara",
		"format": "Micro-ATX", "price": 120, "board_formats": ["micro-ATX"],
		"finish": "Grafite", "paint": "474f58", "accent": "7f969c", "glass": false, "front_glass": false,
		"psu_format": "ATX", "drives_25": 1, "drives_35": 1, "fans": 2,
	},
	{
		"key": "amdera_core_200", "kind": "case", "model": "Amdera Core 200", "brand": "Amdera",
		"format": "ATX Mid Tower", "price": 190, "board_formats": ["ATX", "micro-ATX"],
		"finish": "Preto", "paint": "323943", "accent": "8b9aa8", "glass": false, "front_glass": false,
		"psu_format": "ATX", "drives_25": 2, "drives_35": 2, "fans": 4,
	},
	{
		"key": "amdera_gx500", "kind": "case", "model": "Amdera GX500", "brand": "Amdera",
		"format": "ATX Gamer", "price": 350, "board_formats": ["ATX", "micro-ATX"],
		"finish": "Preto e vermelho", "paint": "29313a", "accent": "d86757", "glass": true, "front_glass": false,
		"psu_format": "ATX", "drives_25": 3, "drives_35": 2, "fans": 6,
	},
	{
		"key": "intara_x700", "kind": "case", "model": "Intara Vision X700", "brand": "Intara",
		"format": "ATX Aquário", "price": 490, "board_formats": ["ATX", "micro-ATX"],
		"finish": "Branco", "paint": "becbd0", "accent": "81c7cb", "glass": true, "front_glass": true,
		"psu_format": "ATX", "drives_25": 3, "drives_35": 2, "fans": 9,
	},
]

const FORMATS := ["ATX", "micro-ATX"]


static func get_model(key: String) -> Dictionary:
	for entry in MODELS:
		if entry.key == key:
			return entry
	return {}


static func board_format(board: Dictionary) -> String:
	if board.has("board_format"):
		return board.board_format if board.board_format in FORMATS else ""
	# Boards in existing saves already encode their form factor in the model.
	var model: Variant = board.get("model", "")
	if not model is String:
		return ""
	for format in FORMATS:
		if model.ends_with(" · " + format):
			return format
	return ""


static func texture(key: String, lid_attached: bool = true) -> Texture2D:
	var suffix := "" if lid_attached else "_open"
	return load("res://Assets/Physical/Cases/%s%s.png" % [key, suffix])


static func inspection_texture(key: String, layer: String) -> Texture2D:
	return load("res://Assets/Inspection/Cases/%s_%s.png" % [key, layer])

extends RefCounted

const MODELS := [
	{
		"key": "intara_m100", "kind": "case", "model": "Intara Office M100", "brand": "Intara",
		"format": "Micro-ATX", "price": 120, "board_formats": ["micro-ATX"],
		"finish": "Grafite", "paint": "474f58", "accent": "7f969c", "glass": false, "front_glass": false,
		"psu_format": "ATX", "drives_25": 1, "drives_35": 1, "fans": 2,
		"gpu_length_mm": 175, "cooler_height_mm": 105, "psu_depth_mm": 140,
		"gpu_slots": 2, "stock_fans": 1,
	},
	{
		"key": "amdera_core_200", "kind": "case", "model": "Amdera Core 200", "brand": "Amdera",
		"format": "ATX Mid Tower", "price": 190, "board_formats": ["ATX", "micro-ATX"],
		"finish": "Preto", "paint": "323943", "accent": "8b9aa8", "glass": false, "front_glass": false,
		"psu_format": "ATX", "drives_25": 2, "drives_35": 2, "fans": 4,
		"gpu_length_mm": 290, "cooler_height_mm": 155, "psu_depth_mm": 160,
		"gpu_slots": 2, "stock_fans": 2,
	},
	{
		"key": "amdera_gx500", "kind": "case", "model": "Amdera GX500", "brand": "Amdera",
		"format": "ATX Gamer", "price": 350, "board_formats": ["ATX", "micro-ATX"],
		"finish": "Preto e vermelho", "paint": "29313a", "accent": "d86757", "glass": true, "front_glass": false,
		"psu_format": "ATX", "drives_25": 3, "drives_35": 2, "fans": 6,
		"gpu_length_mm": 330, "cooler_height_mm": 165, "psu_depth_mm": 180,
		"gpu_slots": 4, "stock_fans": 3,
	},
	{
		"key": "intara_x700", "kind": "case", "model": "Intara Vision X700", "brand": "Intara",
		"format": "ATX Aquário", "price": 490, "board_formats": ["ATX", "micro-ATX"],
		"finish": "Branco", "paint": "becbd0", "accent": "81c7cb", "glass": true, "front_glass": true,
		"psu_format": "ATX", "drives_25": 3, "drives_35": 2, "fans": 9,
		"gpu_length_mm": 380, "cooler_height_mm": 175, "psu_depth_mm": 200,
		"gpu_slots": 4, "stock_fans": 3,
	},
]

const FORMATS := ["ATX", "micro-ATX"]
const CLEARANCES := {"gpu": "gpu_length_mm", "cooling": "cooler_height_mm", "psu": "psu_depth_mm"}


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


static func fit_reason(case_model: Dictionary, part: Dictionary) -> String:
	var kind: String = part.kind
	if kind == "motherboard":
		var format := board_format(part)
		if format not in case_model.board_formats:
			return "Formato incompatível: %s. Este gabinete aceita %s." % [
				"Desconhecido" if format.is_empty() else format, " / ".join(case_model.board_formats)]
	var max_mm: int = case_model.get(CLEARANCES.get(kind, ""), 0)
	var size_mm: int = int(part.get("size_mm", 0))
	if max_mm > 0 and size_mm > max_mm:
		return "A peça de %d mm excede o limite de %d mm deste gabinete." % [size_mm, max_mm]
	if kind == "gpu" and part.get("slots", 2) > case_model.gpu_slots:
		return "A placa ocupa %d slots de expansão e o gabinete comporta %d." % [part.slots, case_model.gpu_slots]
	return ""


static func texture(key: String, lid_attached: bool = true) -> Texture2D:
	var suffix := "" if lid_attached else "_open"
	return load("res://Assets/Physical/Cases/%s%s.png" % [key, suffix])


static func inspection_texture(key: String, layer: String) -> Texture2D:
	return load("res://Assets/Inspection/Cases/%s_%s.png" % [key, layer])

extends RefCounted
## Reuse original pixel assets, trimming transparent world-placement margins.
const AMDERA_CPU := preload("res://Assets/Inspection/Layers/cpu_amdera.png")
const BOARD_ART_SIZE := Vector2(145, 115)
const AMDERA_CPU_SEAT := Rect2(44.5, 23.5, 34, 34)
const INTARA_CPU_SEAT := Rect2(48, 26, 29, 28)
const Ledger := preload("res://Scripts/Gameplay/workshop_ledger.gd")
const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
static var _cache: Dictionary = {}

static func board_texture(variant: String, fallback: Texture2D) -> Texture2D:
	match variant:
		"amdera": return preload("res://Assets/Inspection/Layers/motherboard_amdera.png")
		"intara": return preload("res://Assets/Inspection/Layers/motherboard_intara.png")
	return fallback


static func cpu_seat(variant: String, board_area: Rect2) -> Rect2:
	var source := INTARA_CPU_SEAT if variant == "intara" else AMDERA_CPU_SEAT
	var scale := board_area.size / BOARD_ART_SIZE
	return Rect2(board_area.position + source.position * scale, source.size * scale)


static func icon(part: Dictionary) -> Texture2D:
	var kind: String = part.kind
	var board_art: String = part.get("board_art", "")
	if kind == "cpu" and part.get("socket") == "AX4": return AMDERA_CPU
	var finish: String = part.get("heat_spreader_color", "")
	if Ledger.HEAT_SPREADERS.has(finish): return ram_heat_spreader(finish)
	var case_key: String = part.get("case_key", part.get("key", "") if kind == "case" else "")
	var key := "case:" + case_key if not case_key.is_empty() else kind + ":" + board_art
	if not _cache.has(key):
		var source: Texture2D
		if not case_key.is_empty():
			source = Cases.texture(case_key)
		else:
			source = load("res://Assets/Physical/ram_catalog.png" if kind == "ram" else "res://Assets/Inspection/Layers/" + kind + ".png")
		if kind == "motherboard": source = board_texture(board_art, source)
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = Rect2(source.get_image().get_used_rect())
		_cache[key] = atlas
	return _cache[key]


static func storage_icon(part: Dictionary) -> Texture2D:
	if part.kind == "gpu":
		return preload("res://Assets/Inspection/Layers/gpu_fan_side.svg")
	return icon(part)

static func ram_heat_spreader(finish: String, installed: bool = false) -> Texture2D:
	var key := "heat_spreader:%s:%s" % [finish, installed]
	if _cache.has(key): return _cache[key]
	var paint: Color = Ledger.HEAT_SPREADERS[finish]
	var shade := paint.darkened(0.36)
	var edge := paint.lightened(0.24)
	var art: Image
	if installed:
		art = Image.create(16, 104, false, Image.FORMAT_RGBA8)
		art.fill_rect(Rect2i(1, 2, 14, 100), Color("12191e"))
		art.fill_rect(Rect2i(2, 4, 12, 96), shade)
		art.fill_rect(Rect2i(4, 4, 7, 96), paint)
		art.fill_rect(Rect2i(4, 5, 2, 94), edge)
		for y in [8, 14, 20, 78, 84, 90]:
			art.fill_rect(Rect2i(6, y, 5, 2), shade)
	else:
		art = Image.create(160, 47, false, Image.FORMAT_RGBA8)
		art.fill_rect(Rect2i(3, 10, 154, 35), Color("1c3433"))
		for x in range(5, 155, 3):
			art.fill_rect(Rect2i(x, 39, 2, 6), Color("c8a455"))
		art.fill_rect(Rect2i(88, 39, 4, 6), Color.TRANSPARENT)
		art.fill_rect(Rect2i(2, 11, 156, 29), Color("12191e"))
		for x in [5, 114]:
			art.fill_rect(Rect2i(x, 3, 42, 18), shade)
			art.fill_rect(Rect2i(x + 1, 3, 40, 2), edge)
		art.fill_rect(Rect2i(4, 12, 152, 25), paint)
		art.fill_rect(Rect2i(5, 12, 149, 2), edge)
		art.fill_rect(Rect2i(5, 35, 149, 3), shade)
		for x in [12, 20, 28, 119, 127, 135, 143]:
			for y in range(9):
				art.fill_rect(Rect2i(x + floori(y * 0.5), 18 + y, 2, 1), shade)
		art.fill_rect(Rect2i(54, 21, 50, 2), edge)
		art.fill_rect(Rect2i(54, 25, 32, 2), shade)
	_cache[key] = ImageTexture.create_from_image(art)
	return _cache[key]

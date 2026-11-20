extends RefCounted
## Reuse original pixel assets, trimming transparent world-placement margins.
const AMDERA_CPU := preload("res://Assets/Inspection/Layers/cpu_amdera.png")
const INTARA_CPU := preload("res://Assets/Inspection/Layers/cpu.png")
const BOARD_ART_SIZE := Vector2(145, 115)
const AMDERA_CPU_SEAT := Rect2(44.5, 23.5, 34, 34)
const Art := preload("res://Scripts/UI/hardware_art.gd")
const Ledger := preload("res://Scripts/Gameplay/workshop_ledger.gd")
const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")
const Peripherals := preload("res://Scripts/Equipment/peripheral_catalog.gd")
const PeripheralArt := preload("res://Scripts/UI/peripheral_art.gd")
static var _cache: Dictionary = {}

static func board_texture(variant: String, fallback: Texture2D) -> Texture2D:
	match variant:
		"amdera": return preload("res://Assets/Inspection/Layers/motherboard_amdera.png")
		"intara": return preload("res://Assets/Inspection/Layers/motherboard_intara.png")
	return fallback


static func board_cpu_seat(board: Dictionary) -> Rect2i:
	var spec := Hardware.board_spec(board)
	if spec.is_empty(): return Rect2i(AMDERA_CPU_SEAT)
	return Art.cpu_seat(spec)


static func board_artwork(board: Dictionary, show_slots: bool = true) -> Texture2D:
	var spec := Hardware.board_spec(board)
	if spec.is_empty():
		return board_texture(board.get("board_art", ""), preload("res://Assets/Inspection/Layers/motherboard.png"))
	var key := "board:%s:%s" % [spec.key, show_slots]
	if not _cache.has(key):
		var artwork := Art.motherboard(spec, Hardware.slot_order(board), show_slots)
		_cache[key] = ImageTexture.create_from_image(artwork)
	return _cache[key]


static func socket_contact_label(part: Dictionary, is_board: bool) -> String:
	var socket := Hardware.socket(part.get("socket", ""))
	if Art.has_cpu_pins(socket):
		return "PGA · soquete com furos" if is_board else "PGA · pinos no processador"
	if socket == "AM5" or socket.begins_with("LGA"):
		return "LGA · pinos no soquete" if is_board else "LGA · contatos planos no processador"
	return ""


static func cpu_artwork(part: Dictionary, show_underside: bool = false) -> Texture2D:
	var spec := Hardware.cpu_spec(part)
	if spec.is_empty():
		return AMDERA_CPU if Hardware.socket(part.get("socket", "")) == "AM4" else INTARA_CPU
	var model: String = part.model
	var key := "cpu:%s:%s" % [model, show_underside]
	if not _cache.has(key):
		var top := Art.processor(spec, model)
		var result := top
		if show_underside:
			var back := Art.processor(spec, model, true)
			result = Image.create(top.get_width() * 2 + 10, top.get_height(), false, Image.FORMAT_RGBA8)
			result.blit_rect(top, Rect2i(Vector2i.ZERO, top.get_size()), Vector2i.ZERO)
			result.blit_rect(back, Rect2i(Vector2i.ZERO, back.get_size()), Vector2i(top.get_width() + 10, 0))
		_cache[key] = ImageTexture.create_from_image(result)
	return _cache[key]


static func icon(part: Dictionary) -> Texture2D:
	var kind: String = part.kind
	var board_art: String = part.get("board_art", "")
	if kind == "motherboard": return board_artwork(part)
	if kind == "cpu": return cpu_artwork(part)
	if kind in ["gpu", "storage"] and has_peripheral_art(part): return peripheral_artwork(part)
	if kind == "cooling" and has_distinct_cooler(part): return cooler_artwork(part)
	if kind == "ram" and has_distinct_memory(part): return memory_artwork(part)
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
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = Rect2(source.get_image().get_used_rect())
		_cache[key] = atlas
	return _cache[key]


static func world_icon(part: Dictionary) -> Texture2D:
	var is_cpu: bool = part.kind == "cpu"
	var is_cooler: bool = part.kind == "cooling"
	var is_peripheral := has_peripheral_art(part)
	var spec := Hardware.cpu_spec(part) if is_cpu else Hardware.board_spec(part)
	if spec.is_empty() and not is_cooler and not is_peripheral:
		var legacy_art := "cpu" if is_cpu else "motherboard"
		return load("res://Assets/Physical/%s.png" % legacy_art)
	var key: String = "floor:" + part.model
	if _cache.has(key): return _cache[key]
	var artwork := cpu_artwork(part) if is_cpu else cooler_artwork(part) if is_cooler else peripheral_artwork(part) if is_peripheral else board_artwork(part)
	var source := artwork.get_image()
	var dimensions := Vector2i(ceili((source.get_width() + source.get_height()) * 0.42) + 3,
		ceili((source.get_width() + source.get_height()) * 0.21) + 6)
	var top := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	var edges := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	var y_origin := 2.0 + source.get_width() * 0.21
	# Sample the package on the two diagonal axes of the workshop floor.
	for y in range(dimensions.y - 3):
		for x in range(dimensions.x):
			var sum := (x - 1.0) / 0.42
			var difference := (y - y_origin) / 0.21
			var px := floori((sum - difference) * 0.5)
			var py := floori((sum + difference) * 0.5)
			if px < 0 or px >= source.get_width() or py < 0 or py >= source.get_height(): continue
			var pixel := source.get_pixel(px, py)
			if pixel.a == 0.0: continue
			top.set_pixel(x, y, pixel)
			for depth in range(1, 4):
				edges.set_pixel(x, y + depth, pixel.darkened(0.6))
	edges.blend_rect(top, Rect2i(Vector2i.ZERO, dimensions), Vector2i.ZERO)
	_cache[key] = ImageTexture.create_from_image(edges)
	return _cache[key]


static func has_distinct_cooler(part: Dictionary) -> bool:
	var model: String = part.get("model", "")
	return model.begins_with("Amdera Compact 92") or model.begins_with("Intara Classic 90")


static func cooler_artwork(part: Dictionary) -> Texture2D:
	if not has_distinct_cooler(part): return preload("res://Assets/Inspection/Layers/cooling.png")
	var key: String = "cooler:" + part.model
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(Art.cooler(part.model.begins_with("Amdera")))
	return _cache[key]


static func has_distinct_memory(part: Dictionary) -> bool:
	return part.get("ddr") == "DDR3" or (part.get("ddr") == "DDR5" and Hardware.module_capacity(part) == 48)


static func memory_artwork(part: Dictionary, installed: bool = false) -> Texture2D:
	var finish: String = part.get("heat_spreader_color", "")
	if not has_distinct_memory(part):
		if Ledger.HEAT_SPREADERS.has(finish): return ram_heat_spreader(finish, installed)
		return preload("res://Assets/Inspection/Layers/ram.png") if installed else preload("res://Assets/Physical/ram_catalog.png")
	var capacity := Hardware.module_capacity(part)
	var ddr: String = part.ddr
	var key := "memory:%s:%d:%s:%s" % [ddr, capacity, finish, installed]
	if not _cache.has(key):
		var paint := Color("4d6849") if ddr == "DDR3" else Color("566f79")
		if ddr == "DDR3" and capacity == 8: paint = Color("416d64")
		if Ledger.HEAT_SPREADERS.has(finish): paint = Ledger.HEAT_SPREADERS[finish]
		_cache[key] = ImageTexture.create_from_image(Art.memory_module(capacity, ddr, paint, installed))
	return _cache[key]


static func storage_icon(part: Dictionary) -> Texture2D:
	if part.kind == "gpu":
		return peripheral_artwork(part) if has_peripheral_art(part) else preload("res://Assets/Inspection/Layers/gpu_fan_side.svg")
	return icon(part)


static func has_peripheral_art(part: Dictionary) -> bool:
	return not Peripherals.gpu(part).is_empty() or not Peripherals.hdd(part).is_empty()


static func gpu_side_artwork(part: Dictionary) -> Texture2D:
	var plugs: Array = Peripherals.gpu_profile(part).get("plugs", [])
	var key := "gpu-side:" + ",".join(plugs)
	if not _cache.has(key):
		_cache[key] = PeripheralArt.graphics_card_side(plugs)
	return _cache[key]


static func peripheral_artwork(part: Dictionary) -> Texture2D:
	var gpu := Peripherals.gpu(part)
	var disk := Peripherals.hdd(part)
	if gpu.is_empty() and disk.is_empty():
		return load("res://Assets/Inspection/Layers/%s.png" % part.kind)
	var key := "peripheral:%s" % part.get("catalog_key", part.get("key"))
	if not _cache.has(key):
		var artwork := PeripheralArt.graphics_card(gpu) if not gpu.is_empty() else PeripheralArt.hard_drive(disk)
		_cache[key] = ImageTexture.create_from_image(artwork)
	return _cache[key]


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

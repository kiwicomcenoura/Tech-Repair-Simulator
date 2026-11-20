extends RefCounted
## Pixel geometry shared by the product art and the physical inspection.

const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")
const BOARD_WIDTH := 145
const DIMM_CENTERS := [107, 127, 117, 137]

# Each board has its own socket placement, rear I/O, heatsinks and expansion layout.
# PCI rows contain x, y and length. SATA groups contain x, y, port count and direction.
const BOARDS := {
	"amdera_a320m": {
		"seat": Vector2i(35, 20), "io": [Rect2i(1, 11, 12, 48)], "vrm": [],
		"pci": [Vector3i(15, 77, 100), Vector3i(17, 90, 24)], "sata": Vector4i(125, 79, 2, 1),
		"chip": Rect2i(101, 87, 17, 10), "m2": [], "ink": "b4be9b"},
	"amdera_b450m": {
		"seat": Vector2i(42, 24), "io": [Rect2i(0, 9, 14, 20), Rect2i(1, 34, 10, 35)],
		"vrm": [Rect2i(27, 9, 61, 10)], "pci": [Vector3i(15, 77, 97), Vector3i(24, 91, 62)],
		"sata": Vector4i(126, 73, 3, 1), "chip": Rect2i(105, 85, 19, 13), "m2": [Rect2i(25, 66, 59, 5)], "ink": "b8cbd4"},
	"amdera_ax550": {
		"seat": Vector2i(41, 20), "io": [Rect2i(0, 10, 14, 56)],
		"vrm": [Rect2i(21, 8, 67, 10), Rect2i(19, 21, 14, 34)],
		"pci": [Vector3i(14, 76, 103), Vector3i(15, 92, 34), Vector3i(16, 103, 65)],
		"sata": Vector4i(103, 103, 4, 0), "chip": Rect2i(107, 88, 26, 12), "m2": [Rect2i(37, 65, 59, 6)], "ink": "e9a06a"},
	"amdera_b550_pro": {
		"seat": Vector2i(49, 24), "io": [Rect2i(0, 6, 27, 56), Rect2i(0, 65, 12, 8)],
		"vrm": [Rect2i(23, 4, 74, 12), Rect2i(28, 17, 15, 43)],
		"pci": [Vector3i(15, 76, 106), Vector3i(18, 99, 101)],
		"sata": Vector4i(132, 75, 4, 1), "chip": Rect2i(102, 86, 27, 20), "m2": [Rect2i(35, 67, 63, 6), Rect2i(29, 87, 63, 8)], "ink": "e3e9e4"},
	"amdera_x570_elite": {
		"seat": Vector2i(45, 23), "io": [Rect2i(0, 5, 26, 67)],
		"vrm": [Rect2i(26, 4, 73, 14), Rect2i(27, 20, 13, 41)],
		"pci": [Vector3i(13, 76, 110), Vector3i(18, 91, 90), Vector3i(22, 105, 68)],
		"sata": Vector4i(131, 75, 4, 1), "chip": Rect2i(104, 86, 23, 23), "fan": true,
		"m2": [Rect2i(29, 66, 65, 6), Rect2i(31, 98, 66, 5)], "ink": "c7a5e6"},
	"amdera_a620m": {
		"seat": Vector2i(42, 18), "io": [Rect2i(1, 12, 12, 21), Rect2i(0, 38, 14, 26)],
		"vrm": [Rect2i(19, 23, 15, 31)], "pci": [Vector3i(14, 79, 103), Vector3i(17, 92, 23)],
		"sata": Vector4i(110, 91, 3, 0), "chip": Rect2i(112, 71, 19, 14), "m2": [Rect2i(30, 67, 64, 7)], "ink": "c8ca87"},
	"amdera_b650_gaming": {
		"seat": Vector2i(47, 17), "io": [Rect2i(0, 7, 24, 62)],
		"vrm": [Rect2i(22, 4, 73, 10), Rect2i(23, 20, 17, 34)],
		"pci": [Vector3i(15, 78, 110), Vector3i(22, 98, 99)],
		"sata": Vector4i(128, 78, 4, 1), "chip": Rect2i(101, 85, 23, 23),
		"m2": [Rect2i(29, 67, 71, 8), Rect2i(28, 88, 69, 7)], "ink": "f28873"},
	"amdera_x670_elite": {
		"seat": Vector2i(49, 24), "io": [Rect2i(0, 5, 28, 66)],
		"vrm": [Rect2i(26, 3, 72, 13), Rect2i(28, 18, 14, 39)],
		"pci": [Vector3i(13, 78, 112), Vector3i(13, 103, 109)],
		"sata": Vector4i(131, 77, 4, 1), "chip": Rect2i(103, 88, 24, 21),
		"m2": [Rect2i(25, 66, 75, 9), Rect2i(22, 87, 76, 12)], "ink": "a3ebe0"},
	"intara_h61_classic": {
		"seat": Vector2i(38, 23), "io": [Rect2i(1, 9, 13, 22), Rect2i(1, 37, 14, 30)],
		"vrm": [], "pci": [Vector3i(15, 76, 96), Vector3i(18, 91, 51)], "legacy_pci": true,
		"sata": Vector4i(101, 91, 4, 0), "chip": Rect2i(102, 81, 20, 8), "m2": [], "ink": "ead6a1"},
	"intara_b75m": {
		"seat": Vector2i(43, 18), "io": [Rect2i(0, 12, 14, 47), Rect2i(1, 61, 10, 8)],
		"vrm": [Rect2i(25, 9, 50, 7)], "pci": [Vector3i(15, 74, 103), Vector3i(16, 84, 23), Vector3i(19, 94, 75)],
		"legacy_pci": true, "sata": Vector4i(128, 72, 3, 1), "chip": Rect2i(108, 88, 19, 11), "m2": [], "ink": "b6dbd8"},
	"intara_h110m": {
		"seat": Vector2i(39, 24), "io": [Rect2i(1, 16, 13, 51)],
		"vrm": [], "pci": [Vector3i(14, 79, 106), Vector3i(18, 92, 22)],
		"sata": Vector4i(96, 91, 4, 0), "chip": Rect2i(113, 73, 20, 13), "m2": [], "ink": "baccde"},
	"intara_b360m": {
		"seat": Vector2i(50, 20), "io": [Rect2i(0, 9, 19, 55)],
		"vrm": [Rect2i(25, 19, 15, 33), Rect2i(27, 7, 65, 9)],
		"pci": [Vector3i(14, 77, 109), Vector3i(16, 92, 70)],
		"sata": Vector4i(130, 74, 3, 1), "chip": Rect2i(100, 86, 25, 12), "m2": [Rect2i(26, 66, 61, 7)], "ink": "9bbedf"},
	"intara_h510m": {
		"seat": Vector2i(45, 16), "io": [Rect2i(1, 12, 15, 19), Rect2i(0, 35, 12, 28)],
		"vrm": [Rect2i(21, 7, 58, 8)], "pci": [Vector3i(14, 75, 105), Vector3i(21, 88, 26)],
		"sata": Vector4i(109, 91, 3, 0), "chip": Rect2i(103, 83, 23, 7), "m2": [Rect2i(41, 64, 51, 6)], "ink": "a0d2c6"},
	"intara_ix610": {
		"seat": Vector2i(43, 19), "io": [Rect2i(0, 10, 21, 29), Rect2i(1, 42, 13, 22)],
		"vrm": [Rect2i(24, 4, 66, 12)], "pci": [Vector3i(13, 77, 110), Vector3i(22, 92, 39)],
		"sata": Vector4i(129, 76, 3, 1), "chip": Rect2i(101, 86, 24, 13), "m2": [Rect2i(26, 66, 68, 7)], "ink": "a9d9ff"},
	"intara_b660m": {
		"seat": Vector2i(46, 22), "io": [Rect2i(0, 7, 26, 57)],
		"vrm": [Rect2i(28, 5, 66, 13), Rect2i(26, 21, 13, 33)],
		"pci": [Vector3i(13, 77, 110), Vector3i(16, 91, 84)],
		"sata": Vector4i(130, 73, 3, 1), "chip": Rect2i(105, 85, 20, 13), "m2": [Rect2i(30, 66, 64, 8)], "ink": "b2bafb"},
	"intara_z790_ultra": {
		"seat": Vector2i(48, 20), "io": [Rect2i(0, 5, 29, 65)],
		"vrm": [Rect2i(25, 3, 74, 13), Rect2i(29, 20, 13, 37)],
		"pci": [Vector3i(13, 77, 112), Vector3i(19, 96, 105), Vector3i(28, 106, 62)],
		"sata": Vector4i(130, 72, 5, 1), "chip": Rect2i(103, 84, 24, 26),
		"m2": [Rect2i(23, 65, 78, 9), Rect2i(24, 85, 75, 9)], "ink": "e6caff"},
}

const DIGITS := [
	"75557", "26227", "71747", "71717", "55711",
	"74717", "74757", "71111", "75757", "75717",
]
const GLYPHS := {
	"A": "25755", "B": "65656", "F": "74744", "H": "55755", "I": "72227",
	"K": "55655", "M": "57555", "X": "55255", "Z": "71247",
}


static func has_cpu_pins(socket: String) -> bool:
	return socket == "AM4"


static func cpu_seat(spec: Dictionary) -> Rect2i:
	var place: Vector2i = BOARDS[spec.key].seat
	var size := Vector2i(34, 34)
	match spec.socket:
		"AM5": size = Vector2i(33, 33)
		"LGA1155", "LGA1151", "LGA1200": size = Vector2i(31, 31)
		"LGA1700": size = Vector2i(29, 37)
	return Rect2i(place, size)


static func motherboard(spec: Dictionary, order: Array, show_slots: bool) -> Image:
	var layout: Dictionary = BOARDS[spec.key]
	var height := 115 if spec.board_format == "ATX" else 102
	var image := Image.create(BOARD_WIDTH, height, false, Image.FORMAT_RGBA8)
	var pcb := Color(spec.pcb)
	var accent := Color(spec.accent)
	var ink := Color(layout.ink)
	image.fill_rect(Rect2i(2, 1, 142, height - 1), pcb.darkened(0.50))
	image.fill_rect(Rect2i(2, 0, 141, height - 2), pcb)
	image.fill_rect(Rect2i(4, 1, 136, 1), pcb.lightened(0.15))
	var seat := cpu_seat(spec)
	_draw_traces(image, seat, pcb, height)
	for area: Rect2i in layout.io: _rear_io(image, area, ink)
	for area: Rect2i in layout.vrm: _heatsink(image, area, accent)
	for x in range(seat.position.x + 2, seat.end.x - 1, 6):
		image.fill_rect(Rect2i(x, seat.position.y - 6, 3, 3), Color("b7bdb0"))
	if layout.vrm.is_empty():
		for y in range(seat.position.y - 1, seat.end.y, 6):
			image.fill_rect(Rect2i(seat.position.x - 12, y, 7, 4), Color("161f22"))
			image.fill_rect(Rect2i(seat.position.x - 4, y, 2, 4), Color("b1b7af"))
	for slot: Vector3i in layout.pci:
		var rail := Rect2i(slot.x, slot.y, slot.z, 5)
		var color := Color("c0b8a1") if layout.get("legacy_pci", false) and slot.y > 85 else Color("11191d")
		image.fill_rect(rail, color)
		image.fill_rect(Rect2i(slot.x + 2, slot.y + 1, slot.z - 4, 1), accent.lightened(0.20))
		image.fill_rect(Rect2i(slot.x + 13, slot.y + 1, 2, 3), color.lightened(0.35))
		image.fill_rect(Rect2i(slot.x + slot.z - 2, slot.y + 3, 3, 3), Color("636d73"))
	for area: Rect2i in layout.m2:
		_heatsink(image, area, accent.darkened(0.20))
		image.set_pixelv(area.position + Vector2i(2, 2), Color("ceb37e"))
	_heatsink(image, layout.chip, accent)
	if layout.get("fan", false):
		var center: Vector2i = layout.chip.get_center()
		image.fill_rect(Rect2i(center - Vector2i(7, 7), Vector2i(14, 14)), Color("182024"))
		for tip in [Vector2i(1, -5), Vector2i(4, 0), Vector2i(-1, 4), Vector2i(-4, -1)]:
			image.fill_rect(Rect2i(center + tip, Vector2i(3, 3)), accent)
	_sata(image, layout.sata, ink)
	_socket(image, seat, spec.socket)
	if show_slots: _dimms(image, order, accent)
	var mark: String = spec.model.get_slice(" ", 1)
	_stamp(image, Vector2i(seat.position.x + 3, seat.end.y + 1), mark, ink.lightened(0.18))
	for point in [Vector2i(4, 4), Vector2i(140, 4), Vector2i(4, 70), Vector2i(140, 70), Vector2i(4, height - 3), Vector2i(140, height - 3)]:
		image.fill_rect(Rect2i(point - Vector2i.ONE, Vector2i(3, 3)), Color("a6aa96"))
		image.set_pixelv(point, Color("1d2629"))
	return image


static func _draw_traces(image: Image, seat: Rect2i, pcb: Color, height: int) -> void:
	var trace := pcb.lightened(0.12)
	for index in range(7):
		var y := seat.position.y + index * 5
		image.fill_rect(Rect2i(seat.end.x, y, 98 - seat.end.x, 1), trace)
		image.fill_rect(Rect2i(98, y, 1, 4), trace)
		image.set_pixel(99, y + 3, Color("968250"))
	for index in range(6):
		var x := 16 + index * 12
		var y := height - 9 - index % 2 * 5
		image.fill_rect(Rect2i(x, y, 10, 1), trace)
		image.fill_rect(Rect2i(x, y - 3, 1, 4), trace)


static func _rear_io(image: Image, area: Rect2i, ink: Color) -> void:
	image.fill_rect(area, Color("566167"))
	image.fill_rect(Rect2i(area.position, Vector2i(area.size.x, 2)), Color("a6afb2"))
	for y in range(area.position.y + 4, area.end.y - 4, 7):
		image.fill_rect(Rect2i(area.position.x + 2, y, 8, 4), Color("131d24"))
		image.fill_rect(Rect2i(area.position.x + 3, y + 1, 6, 1), ink.darkened(0.17))
	if area.size.x >= 19:
		image.fill_rect(Rect2i(area.position.x + 11, area.position.y + 3, area.size.x - 13, area.size.y - 6), ink.darkened(0.5))
		image.fill_rect(Rect2i(area.end.x - 5, area.position.y + 3, 2, area.size.y - 6), ink)


static func _heatsink(image: Image, area: Rect2i, paint: Color) -> void:
	image.fill_rect(area, paint.darkened(0.56))
	image.fill_rect(Rect2i(area.position + Vector2i(1, 0), Vector2i(area.size.x - 2, 2)), paint.lightened(0.20))
	for x in range(area.position.x + 2, area.end.x - 1, 4):
		image.fill_rect(Rect2i(x, area.position.y + 2, 2, area.size.y - 3), paint)


static func _sata(image: Image, ports: Vector4i, ink: Color) -> void:
	var origin := Vector2i(ports.x, ports.y)
	var step := Vector2i(8, 0) if ports.w == 0 else Vector2i(0, 7)
	for i in range(ports.z):
		var point := origin + step * i
		image.fill_rect(Rect2i(point, Vector2i(7, 6)), Color("151c21"))
		image.fill_rect(Rect2i(point + Vector2i(1, 1), Vector2i(5, 2)), ink.darkened(0.23))


static func _dimms(image: Image, order: Array, accent: Color) -> void:
	for slot in order:
		var x: int = DIMM_CENTERS[slot]
		image.fill_rect(Rect2i(x - 4, 8, 8, 56), Color("111a20"))
		image.fill_rect(Rect2i(x - 2, 9, 4, 53), accent.darkened(0.29) if slot % 2 else Color("566469"))
		image.fill_rect(Rect2i(x - 4, 5, 8, 3), Color("a1aeae"))
		image.fill_rect(Rect2i(x - 4, 64, 8, 3), Color("a1aeae"))


static func _socket(image: Image, seat: Rect2i, socket: String) -> void:
	var pga := has_cpu_pins(socket)
	var frame := Color("e0d9be") if pga else Color("9daab1")
	var field := seat.grow(-3)
	image.fill_rect(seat.grow(2), Color("182025"))
	image.fill_rect(seat, frame)
	image.fill_rect(field, Color("b1aa91") if pga else Color("312e2c"))
	var center := Rect2i(field.get_center() - Vector2i(4, 4), Vector2i(8, 8))
	for y in range(field.position.y + 1, field.end.y - 1, 2):
		for x in range(field.position.x + 1, field.end.x - 1, 2):
			if center.has_point(Vector2i(x, y)): continue
			image.set_pixel(x, y, Color("282a25") if pga else Color("dec18a"))
			if not pga: image.set_pixel(x + 1, y + 1, Color("8f663e"))
	if not pga:
		image.fill_rect(Rect2i(seat.position - Vector2i(2, 1), Vector2i(seat.size.x + 4, 2)), Color("c3ccd0"))
		image.fill_rect(Rect2i(seat.position - Vector2i(1, 0), Vector2i(2, seat.size.y)), frame.darkened(0.25))
	image.fill_rect(Rect2i(seat.end.x + 1, seat.position.y + 3, 2, seat.size.y - 6), Color("d3d8d5"))
	_corner_marker(image, seat.position + Vector2i(1, 1))


static func processor(spec: Dictionary, model: String, underside: bool = false) -> Image:
	var socket: String = spec.socket
	var pga := has_cpu_pins(socket)
	var size := Vector2i(38, 38)
	match socket:
		"AM5": size = Vector2i(40, 40)
		"LGA1155", "LGA1151", "LGA1200": size = Vector2i(35, 35)
		"LGA1700": size = Vector2i(34, 43)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var body := Rect2i(Vector2i(1, 1), size - Vector2i(2, 2))
	var substrate := Color("375244") if spec.brand == "Amdera" else Color("286154")
	image.fill_rect(body, substrate.darkened(0.45))
	image.fill_rect(Rect2i(body.position, body.size - Vector2i(0, 2)), substrate)
	_corner_marker(image, Vector2i(2, 2))
	if underside:
		_contacts(image, body.grow(-4), pga, socket)
		return image
	var lid := body.grow(-4)
	var metal := Color("b5c0c1") if spec.brand == "Intara" else Color("bbc0b8")
	var tier := 3 if " R3 " in model or " i3" in model else 7 if " R7 " in model or " i7" in model else 5
	if socket == "LGA1155": metal = Color("bab5a5")
	if socket == "LGA1200": metal = Color("aab9c0")
	if tier == 3: metal = metal.darkened(0.07)
	if model.ends_with("K") or model.ends_with("X"): metal = metal.lightened(0.17)
	_metal_cap(image, lid, metal, socket)
	var mark := model.get_slice(" ", model.get_slice_count(" ") - 1)
	if mark.contains("-"): mark = mark.get_slice("-", 1)
	var label_x := floori((size.x - (mark.length() * 4 - 1)) * 0.5)
	_stamp(image, Vector2i(label_x, floori(size.y * 0.49)), mark, Color("263937"))
	var stripe := Color("b65e36") if spec.brand == "Amdera" else Color("467098")
	var stripe_y := floori(size.y * 0.35)
	image.fill_rect(Rect2i(floori(size.x * 0.5) - tier, stripe_y, tier * 2, 2), stripe)
	if tier == 7: image.fill_rect(Rect2i(lid.position.x + 5, lid.end.y - 5, lid.size.x - 10, 1), stripe)
	return image


static func _metal_cap(image: Image, lid: Rect2i, metal: Color, socket: String) -> void:
	image.fill_rect(lid, metal.darkened(0.44))
	image.fill_rect(lid.grow(-1), metal)
	image.fill_rect(Rect2i(lid.position + Vector2i(2, 1), Vector2i(lid.size.x - 4, 2)), metal.lightened(0.27))
	image.fill_rect(Rect2i(lid.position.x + 2, lid.end.y - 3, lid.size.x - 4, 2), metal.darkened(0.17))
	if socket == "AM5":
		for y in [lid.position.y + 4, lid.end.y - 8]:
			for x in [lid.position.x, lid.end.x - 4]:
				image.fill_rect(Rect2i(x, y, 4, 4), Color("355344"))
				image.fill_rect(Rect2i(x + 1, y + 1, 2, 1), Color("c9a568"))
	elif socket == "LGA1700":
		for y in [lid.position.y + 4, lid.end.y - 6]:
			image.fill_rect(Rect2i(lid.position.x, y, 2, 2), Color("526963"))
			image.fill_rect(Rect2i(lid.end.x - 2, y, 2, 2), Color("526963"))


static func _contacts(image: Image, field: Rect2i, pga: bool, socket: String) -> void:
	var island := Rect2i(field.get_center() - Vector2i(4, 6), Vector2i(8, 12))
	var pitch := 4 if pga else 3
	for y in range(field.position.y, field.end.y - 2, pitch):
		for x in range(field.position.x, field.end.x - 1, pitch):
			if island.has_point(Vector2i(x, y)): continue
			if pga:
				image.fill_rect(Rect2i(x + 1, y, 1, 3), Color("977148"))
				image.fill_rect(Rect2i(x, y, 1, 2), Color("f8d38a"))
			else:
				image.fill_rect(Rect2i(x, y, 2, 1), Color("c9a462"))
				image.set_pixel(x, y, Color("ead293"))
	for y in range(island.position.y, island.end.y, 3):
		image.fill_rect(Rect2i(island.position.x + 1, y, 5 if socket == "LGA1700" else 3, 1), Color("b8b5a5"))


static func _corner_marker(image: Image, point: Vector2i) -> void:
	image.fill_rect(Rect2i(point, Vector2i(3, 1)), Color("e9bf65"))
	image.set_pixelv(point + Vector2i(0, 1), Color("e9bf65"))


static func _stamp(image: Image, origin: Vector2i, label: String, ink: Color) -> void:
	for i in range(label.length()):
		var ch := label[i]
		var glyph: String = DIGITS[int(ch)] if ch.is_valid_int() else GLYPHS.get(ch, "")
		for y in range(glyph.length()):
			var row := int(glyph[y])
			for x in range(3):
				if row & (1 << (2 - x)): image.set_pixelv(origin + Vector2i(i * 4 + x, y), ink)


static func memory_module(capacity: int, ddr: String, paint: Color, installed: bool) -> Image:
	var ddr3 := ddr == "DDR3"
	var size := Vector2i(16, 104) if installed else Vector2i(128, 34 if ddr3 else 44)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	if installed:
		image.fill_rect(Rect2i(2, 2, 12, 100), Color("131c20"))
		image.fill_rect(Rect2i(3, 4, 10, 96), paint)
		image.fill_rect(Rect2i(4, 4, 2, 96), paint.lightened(0.23))
		var pitch := 12 if ddr3 and capacity == 8 else 21
		for y in range(8, 93, pitch):
			image.fill_rect(Rect2i(7, y, 4, 5 if ddr3 else 3), paint.darkened(0.48))
		return image
	var height := 25 if ddr3 else 36
	image.fill_rect(Rect2i(2, 3, 124, height), paint.darkened(0.26))
	image.fill_rect(Rect2i(4, 4, 120, height - 5), paint)
	image.fill_rect(Rect2i(4, 4, 120, 2), paint.lightened(0.23))
	if ddr3:
		var chips := 4 if capacity == 4 else 8
		var pitch := 112 / chips
		for index in range(chips):
			var x := 8 + index * pitch
			image.fill_rect(Rect2i(x, 9, pitch - 5, 12), Color("151b1d"))
			image.fill_rect(Rect2i(x + 1, 10, pitch - 7, 1), Color("555d5b"))
		image.fill_rect(Rect2i(48, 7, 29, 9), Color("c8c6a3"))
		_stamp(image, Vector2i(61, 9), str(capacity), Color("283227"))
	else:
		image.fill_rect(Rect2i(2, 1, 124, 14), paint.darkened(0.48))
		image.fill_rect(Rect2i(6, 2, 116, 3), paint.lightened(0.34))
		for x in range(10, 117, 9):
			image.fill_rect(Rect2i(x, 9, 2, 21), paint.darkened(0.23))
		image.fill_rect(Rect2i(53, 19, 24, 12), Color("19242b"))
		_stamp(image, Vector2i(61, 23), "48", Color("bed6df"))
	for x in range(7, 122, 3):
		image.fill_rect(Rect2i(x, height + 1, 2, 4), Color("c7a15c"))
	image.fill_rect(Rect2i(61 if ddr3 else 70, height, 4, 5), Color.TRANSPARENT)
	return image


static func cooler(compact: bool) -> Image:
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var frame := Color("3f4e53") if compact else Color("746c55")
	if compact:
		image.fill_rect(Rect2i(4, 4, 40, 40), Color("151c20"))
		image.fill_rect(Rect2i(5, 5, 38, 38), frame)
		for x in range(8, 41, 4):
			image.fill_rect(Rect2i(x, 2, 2, 44), Color("a6b9ba"))
	else:
		for x in [3, 39]:
			image.fill_rect(Rect2i(x, 18, 6, 13), frame)
		for y in range(3, 45):
			var span := floori(sqrt(maxf(0.0, 21.0 ** 2 - (y - 24) ** 2)))
			if span > 0: image.fill_rect(Rect2i(24 - span, y, span * 2, 1), frame)
	for y in range(7, 41):
		for x in range(7, 41):
			var delta := Vector2(x - 24, y - 24)
			var radius := delta.length()
			if radius >= 17.0: continue
			var blade := fposmod(delta.angle() * 6.0 + radius * 0.33, TAU) < 2.65
			var color := Color("749798") if compact else Color("bc9a60")
			image.set_pixel(x, y, color if blade and radius > 6 else Color("151d24"))
	image.fill_rect(Rect2i(20, 20, 8, 8), frame.darkened(0.24))
	image.fill_rect(Rect2i(22, 22, 4, 3), frame.lightened(0.44))
	return image

extends RefCounted
## Pixel sprites for the original projection and the shop.

const GPU_SIDE := preload("res://Assets/Inspection/Layers/gpu.png")
const GPU_SIDE_SOCKET_X := 548
const FRAME_COUNT := 16
const FAN_SIZE := 24
const DIGITS := [0x7b6f, 0x2c97, 0x73e7, 0x73cf, 0x5bc9, 0x79cf, 0x79ef, 0x7249, 0x7bef, 0x7bcf]
static var _rotors: Array[Texture2D] = []


static func gpu_size(spec: Dictionary) -> Vector2i:
	return Vector2i(roundi(64.0 + spec.size_mm * 0.36), 28 + spec.slots * 4)


static func gpu_rotors(spec: Dictionary) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for index in range(spec.fans):
		positions.append(Vector2(0.12 + 0.80 * (index + 0.5) / spec.fans, 0.50))
	return positions


static func gpu_size_ratio(spec: Dictionary) -> float:
	return 0.70 if spec.fans == 1 else 0.80


static func graphics_card_side(plugs: Array) -> Texture2D:
	if plugs == ["8"]: return GPU_SIDE
	var image := GPU_SIDE.get_image()
	# Restore the PCB strip under the socket before placing the model's plugs.
	var contact_strip := Rect2i(420, 0, 64, 24)
	var replacement := image.get_region(contact_strip)
	image.blit_rect(replacement, Rect2i(Vector2i.ZERO, replacement.get_size()), Vector2i(516, 0))
	var socket_widths: Array[int] = []
	var total_width := 0
	for plug in plugs:
		var width := 32 if plug == "16" else 20 + int(plug)
		socket_widths.append(width)
		total_width += width + 4
	var x := GPU_SIDE_SOCKET_X - total_width / 2
	for width in socket_widths:
		image.fill_rect(Rect2i(x, 0, width, 24), Color("0c151e"))
		image.fill_rect(Rect2i(x + 2, 1, width - 4, 2), Color("42515a"))
		for pin in range(x + 5, x + width - 3, 6):
			image.fill_rect(Rect2i(pin, 5, 2, 10), Color("b5a079"))
		x += width + 4
	return ImageTexture.create_from_image(image)


static func graphics_card(spec: Dictionary) -> Image:
	var size := gpu_size(spec)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var width := size.x
	var height := size.y
	var pcb := Color("263e32") if spec.generation in ["700", "900", "10", "500"] else Color("22252f")
	image.fill_rect(Rect2i(5, 4, width - 9, height - 8), pcb)
	var fingers := 36 + int(spec.lanes) * 4
	image.fill_rect(Rect2i(20, height - 8, fingers, 6), pcb)
	for x in range(22, 20 + fingers, 3):
		if x == 34: continue
		image.fill_rect(Rect2i(x, height - 6, 2, 4), Color("ab8748"))
	image.fill_rect(Rect2i(1, 2, 9, height - 4), Color("8a99a1"))
	image.fill_rect(Rect2i(3, 3, 3, height - 6), Color("4e5960"))
	for y in range(7, height - 6, 7):
		image.fill_rect(Rect2i(2, y, 4, 3), Color("17242e"))
	if spec.fans == 0:
		image.fill_rect(Rect2i(12, 8, width - 25, height - 16), Color("465358"))
		for x in range(13, width - 13, 4):
			image.fill_rect(Rect2i(x, 6, 2, height - 12), Color("9ba8a7"))
		return image
	_draw_shroud(image, spec, pcb)
	for center in gpu_rotors(spec):
		var fan_size := roundi(height * gpu_size_ratio(spec))
		var point := Vector2i((center * Vector2(size)).round()) - Vector2i(fan_size, fan_size) / 2
		var fan_image := _rotor_image(0.0)
		fan_image.resize(fan_size, fan_size, Image.INTERPOLATE_NEAREST)
		image.blend_rect(fan_image, Rect2i(Vector2i.ZERO, fan_image.get_size()), point)
	var plug_x := width - 9
	for plug in spec.plugs:
		var columns := 6 if plug == "16" else int(plug) / 2
		var plug_width := 3 + columns * 2
		plug_x -= plug_width + 2
		image.fill_rect(Rect2i(plug_x, 1, plug_width, 7), Color("131c24"))
		for pin in range(columns):
			image.fill_rect(Rect2i(plug_x + 2 + pin * 2, 2, 1, 3), Color("bfaa73"))
	return image


static func _draw_shroud(image: Image, spec: Dictionary, pcb: Color) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var exposed := 13 if spec.fans == 1 else 5
	var face := Rect2i(10, 6, width - 11 - exposed, height - 12)
	var generation: String = spec.generation
	var palette: Array = {
		"700": ["333839", "7ca75a"], "900": ["282e3b", "86a787"],
		"10": ["384351", "d8a95b"], "16": ["20252d", "7eaa6d"],
		"20": ["49565e", "8dcac1"], "30": ["2b3743", "aabdc1"],
		"40": ["4c5358", "a7bfaa"], "50": ["33495a", "9ed3ea"],
		"500": ["45292e", "ed875b"], "5000": ["343047", "df7d68"],
		"6000": ["34282b", "bd4d43"], "7000": ["41434b", "e3a092"],
		"9000": ["5d444a", "e8b389"],
	}[generation]
	var shell := Color(palette[0])
	var trim := Color(palette[1])
	image.fill_rect(face.grow(1), shell.darkened(0.53))
	image.fill_rect(face, shell)
	var x := face.position.x
	var y := face.position.y
	var end := face.end.x
	var bottom := face.end.y
	match generation:
		"700", "500", "10":
			for rib in range(x + 2 + int(spec.vram_gb) % 3, end - 2, 6):
				image.fill_rect(Rect2i(rib, y + 2, 2, face.size.y - 4), shell.lightened(0.23))
			var panel := 17 if spec.fans == 1 else 24
			image.fill_rect(Rect2i(x, y + 1, panel, face.size.y - 2), trim.darkened(0.47))
			image.fill_rect(Rect2i(x + 2, y + 3, 3, face.size.y - 6), trim)
			for pad in range(end + 3, width - 3, 3):
				image.fill_rect(Rect2i(pad, y + 7, 1, face.size.y - 14), trim.darkened(0.4))
		"900", "16", "5000":
			image.fill_rect(Rect2i(x + 2, bottom - 7, face.size.x - 4, 5), trim.darkened(0.4))
			for vent in range(x + 5, end - 6, 9):
				image.fill_rect(Rect2i(vent, y + 2, 5, face.size.y - 11), shell.darkened(0.31))
			image.fill_rect(Rect2i(end - 9, y + 1, 7, face.size.y - 2), trim)
		"20", "30", "6000":
			image.fill_rect(Rect2i(x + 1, y + 2, face.size.x - 2, 3), trim)
			image.fill_rect(Rect2i(x + 1, bottom - 5, face.size.x - 2, 3), trim.darkened(0.19))
			for rail in [x + 2, x + face.size.x / 2 - 2, end - 6]:
				image.fill_rect(Rect2i(rail, y + 2, 4, face.size.y - 4), trim.darkened(0.3))
		"40", "50", "7000", "9000":
			var span := face.size.x / 2
			for row in range(face.size.y / 2):
				var inset := (face.size.y / 2 - row) / 2
				image.fill_rect(Rect2i(x, y + row, inset, 1), pcb)
				image.fill_rect(Rect2i(end - inset, bottom - row - 1, inset, 1), pcb)
				var notch := x + span - inset if generation in ["40", "9000"] else x + inset * 2
				image.fill_rect(Rect2i(notch, y + row, 5, 1), trim)
				image.fill_rect(Rect2i(width - notch - 3, bottom - row - 1, 5, 1), trim.darkened(0.34))
			if spec.slots >= 3:
				for fin in range(x + 8, end - 4, 5):
					image.fill_rect(Rect2i(fin, y - 2, 2, 4), shell.lightened(0.37))
	var badge_width := 14 if spec.fans > 1 else 9
	image.fill_rect(Rect2i(end - badge_width - 2, bottom - 5, badge_width, 3), shell.darkened(0.58))
	for marker in range(2 + int(spec.vram_gb) % (badge_width - 1)):
		image.set_pixel(end - badge_width - 1 + marker, bottom - 4, trim)


static func hard_drive(spec: Dictionary) -> Image:
	var image := Image.create(46, 61, false, Image.FORMAT_RGBA8)
	var color := Color("6b878e") if spec.rpm == 5400 else Color("889295")
	var accent := Color.from_hsv(float(spec.capacity_gb % 160) / 180.0, 0.4, 0.68)
	image.fill_rect(Rect2i(2, 1, 42, 58), Color("27343b"))
	image.fill_rect(Rect2i(4, 2, 38, 54), color.darkened(0.36))
	image.fill_rect(Rect2i(5, 3, 36, 49), color)
	image.fill_rect(Rect2i(6, 3, 34, 1), color.lightened(0.42))
	for y in range(14, 49):
		for x in range(9, 37):
			var radius := Vector2(x - 23, y - 32).length()
			if radius > 11 and radius < 13: image.set_pixel(x, y, color.darkened(0.19))
	image.fill_rect(Rect2i(9, 8, 28, 17), Color("d3d6ca"))
	image.fill_rect(Rect2i(10, 9, 26, 4), accent)
	var capacity := str(spec.capacity_gb)
	for index in range(capacity.length()):
		var digit: int = DIGITS[capacity[index].to_int()]
		for y in range(5):
			for x in range(3):
				if digit & (1 << (14 - y * 3 - x)):
					image.set_pixel(12 + index * 4 + x, 15 + y, Color("384b4f"))
	for p in [Vector2i(7, 5), Vector2i(38, 5), Vector2i(7, 50), Vector2i(38, 50)]:
		image.fill_rect(Rect2i(p, Vector2i(2, 2)), Color("29373b"))
	for connector in [Rect2i(12, 53, 11, 5), Rect2i(26, 53, 14, 5)]:
		image.fill_rect(connector, Color("151a1e"))
		for x in range(connector.position.x + 2, connector.end.x - 1, 2):
			image.set_pixel(x, 55, Color("b69355"))
	return image


static func rotor(phase: float) -> Texture2D:
	if _rotors.is_empty():
		for index in range(FRAME_COUNT):
			_rotors.append(ImageTexture.create_from_image(_rotor_image(TAU * index / FRAME_COUNT)))
	return _rotors[floori(fposmod(phase, TAU) / TAU * FRAME_COUNT)]


static func _rotor_image(angle: float) -> Image:
	var image := Image.create(FAN_SIZE, FAN_SIZE, false, Image.FORMAT_RGBA8)
	for y in range(FAN_SIZE):
		for x in range(FAN_SIZE):
			var delta := Vector2(x - 11.5, y - 11.5)
			var radius := delta.length()
			if radius > 11.8: continue
			var pixel := Color("0d151b")
			if radius > 10.1: pixel = Color("546467")
			elif radius > 3.4:
				var blade := fposmod((delta.angle() - angle) * 5.0 + radius * 0.42, TAU)
				if blade < 3.45: pixel = Color("7a8c91") if blade < 0.7 else Color("495c65")
			elif radius <= 3.4: pixel = Color("29393e")
			image.set_pixel(x, y, pixel)
	return image

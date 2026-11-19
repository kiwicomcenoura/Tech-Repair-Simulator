extends SceneTree
## Rasterize the original isometric and workbench cabinet sprites.

const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
const DIMENSIONS := {
	"intara_m100": Vector3i(41, 17, 42),
	"amdera_core_200": Vector3i(49, 20, 52),
	"amdera_gx500": Vector3i(51, 24, 54),
	"intara_x700": Vector3i(49, 30, 57),
}

var _image: Image


func _initialize() -> void:
	if "--inspection" in OS.get_cmdline_user_args():
		_build_inspection_art()
		return
	var folder := "res://Assets/Physical/Cases"
	DirAccess.make_dir_recursive_absolute(folder)
	for model in Cases.MODELS:
		for lid_attached in [true, false]:
			_image = Image.create(96, 96, false, Image.FORMAT_RGBA8)
			_draw_case(model, lid_attached)
			var suffix := "" if lid_attached else "_open"
			var result := _image.save_png("%s/%s%s.png" % [folder, model.key, suffix])
			if result != OK:
				push_error(error_string(result))
				quit(1)
				return
	quit()


func _build_inspection_art() -> void:
	var folder := "res://Assets/Inspection/Cases"
	DirAccess.make_dir_recursive_absolute(folder)
	for model in Cases.MODELS:
		for layer in ["chassis", "lid"]:
			_image = Image.create(320, 240, false, Image.FORMAT_RGBA8)
			if layer == "chassis":
				_draw_inspection_chassis(model)
			else:
				_draw_inspection_lid(model)
			var result := _image.save_png("%s/%s_%s.png" % [folder, model.key, layer])
			if result != OK:
				push_error(error_string(result))
				quit(1)
				return
	quit()


func _rect(x: int, y: int, width: int, height: int, color: Color) -> void:
	_image.fill_rect(Rect2i(x, y, width, height), color)


func _draw_inspection_chassis(model: Dictionary) -> void:
	var paint := Color(model.paint)
	var accent := Color(model.accent)
	var edge := paint.lightened(0.27 if not model.front_glass else 0.65)
	var dark := paint.darkened(0.45)
	var front_width: int = {"intara_m100": 20, "amdera_core_200": 34, "amdera_gx500": 40, "intara_x700": 42}[model.key]
	var top := 22 if model.key == "intara_m100" else 16
	var bottom := 200 if model.key == "intara_m100" else 207
	_rect(20, top, 236 + front_width, bottom - top + 4, Color("091116"))
	_rect(22, top + 2, 232 + front_width, bottom - top, paint)
	_rect(23, top + 3, 230 + front_width, 2, edge)
	_rect(24, 24, 228, 172, Color("17242d") if not model.front_glass else Color("263e48"))
	_rect(38, 34, 157, 123, Color("202d36") if not model.front_glass else Color("304a55"))
	_rect(38, 34, 157, 1, dark)
	_rect(195, 37, 10, 152, Color("101b24"))
	for y in [42, 64, 78, 105, 128, 151, 175]:
		_rect(196, y, 7, 4, paint.darkened(0.33))
	for y in [40, 109, 149]:
		for x in [45, 181]:
			_rect(x, y, 4, 4, Color("987b53"))
			_rect(x + 1, y + 1, 2, 2, Color("17242c"))
	for y in range(116, 159, 7):
		_rect(26, y, 12, 5, Color("0d171f"))
		_rect(27, y, 10, 1, paint)
	_rect(26, 159, 167, 34, dark)
	_rect(40, 160, 101, 34, Color("132029"))
	_rect(40, 160, 101, 1, paint)
	_rect(211, 102, 29, 41, dark)
	_rect(213, 104, 25, 37, Color("202f38"))
	_rect(212, 102, 27, 1, paint)
	for y in [106, 138]:
		for x in [214, 236]: _rect(x, y, 2, 2, accent.darkened(0.25))
	_draw_inspection_front(model, paint, accent, edge, front_width)
	_rect(22, 198, 232 + front_width, bottom - 197, dark)
	_rect(23, 198, 228 + front_width, 2, paint)
	_rect(35, bottom + 1, 19, 6, Color("11191e"))
	_rect(223 + front_width, bottom + 1, 21, 6, Color("11191e"))
	_rect(65, 221, 155, 15, Color("2a3c49"))
	_rect(67, 223, 151, 11, Color("0c151e"))


func _draw_inspection_front(model: Dictionary, paint: Color, accent: Color, edge: Color, width: int) -> void:
	if model.front_glass:
		_rect(247, 24, 5, 172, edge)
		_rect(252, 24, width, 172, paint)
		_rect(254, 28, width - 7, 149, Color("17323e"))
		_rect(256, 30, width - 10, 145, Color("325661"))
		_quad(Vector2(256, 32), Vector2(265, 32), Vector2(283, 174), Vector2(277, 174), Color("83aeb75a"))
		_rect(286, 29, 2, 144, accent)
		_rect(254, 178, width - 7, 2, edge)
		_rect(269, 186, 9, 3, Color("6c848a"))
		for y in [46, 72, 98, 154]:
			_rect(220, y, 18, 1, Color("63818a"))
		_rect(207, 34, 2, 158, Color("6b858e"))
		return
	var red_trim: bool = model.glass
	_rect(250, 23, width + 4, 176, paint.darkened(0.33))
	_rect(252, 24, width + 1, 2, edge)
	_rect(253, 29, width - 4, 166, Color("162029"))
	var grille_top := 48 if red_trim else 46
	if model.key == "intara_m100":
		_rect(255, 43, width - 8, 20, paint)
		_rect(256, 47, width - 10, 3, Color("141e26"))
		grille_top = 107
	for y in range(grille_top, 186, 4 if red_trim else 3):
		_rect(255, y, width - 8, 1, paint)
		if model.key == "amdera_core_200":
			for x in range(257, 250 + width - 4, 3):
				_rect(x, y + 1, 1, 1, paint.lightened(0.12))
	if red_trim:
		_quad(Vector2(253, 39), Vector2(256, 40), Vector2(250 + width - 8, 177), Vector2(250 + width - 12, 177), accent)
		_rect(250 + width - 2, 40, 2, 142, accent.darkened(0.18))
	_rect(256, 33, 5, 3, accent)
	_rect(256, 38, 6, 1, edge)


func _draw_inspection_lid(model: Dictionary) -> void:
	var paint := Color(model.paint)
	var accent := Color(model.accent)
	var edge := paint.lightened(0.30)
	_rect(28, 24, 224, 172, paint.darkened(0.36))
	_rect(29, 25, 222, 170, paint)
	_rect(29, 25, 222, 1, edge)
	_rect(29, 193, 222, 1, paint.darkened(0.27))
	if model.glass:
		var tint := Color("487f9340") if model.front_glass else Color("18354074")
		_rect(35, 31, 210, 157, tint)
		_quad(Vector2(49, 32), Vector2(61, 32), Vector2(168, 188), Vector2(157, 188), Color("cfe8ed41"))
		_quad(Vector2(64, 32), Vector2(68, 32), Vector2(175, 188), Vector2(171, 188), Color("cfe8ed29"))
		_rect(35, 31, 210, 1, accent)
		_rect(244, 31, 1, 157, accent.darkened(0.24))
	else:
		_rect(36, 32, 207, 155, paint.lightened(0.065))
		_rect(36, 32, 207, 1, edge)
		_rect(39, 184, 201, 2, paint.darkened(0.16))
		if model.key == "intara_m100":
			for y in range(104, 151, 6):
				_rect(69, y, 111, 2, paint.darkened(0.53))
				_rect(69, y + 2, 111, 1, edge)
		else:
			_rect(69, 87, 122, 66, paint.darkened(0.16))
			for y in range(91, 150, 4):
				for x in range(73, 188, 4):
					_rect(x, y, 2, 2, paint.darkened(0.60))
		_rect(220, 80, 7, 47, paint.darkened(0.23))
		_rect(222, 84, 2, 39, edge)


func _draw_case(model: Dictionary, lid_attached: bool) -> void:
	var dimensions: Vector3i = DIMENSIONS[model.key]
	var side := Vector2(dimensions.x, roundi(dimensions.x * 0.30))
	var front := Vector2(dimensions.y, -roundi(dimensions.y * 0.55))
	var height := Vector2(0, dimensions.z)
	var corner := Vector2((96 - side.x - front.x) * 0.5, 87 - side.y - height.y)
	var turn := corner + side
	var right := turn + front
	var back := corner + front
	var paint := Color(model.paint)
	var accent := Color(model.accent)
	var steel := Color("80949a") if model.front_glass else Color("101922")
	var edge := paint.lightened(0.24)

	_quad(corner + height + Vector2(-3, 5), turn + height + Vector2(2, 6),
		right + height + Vector2(3, 5), back + height + Vector2(-1, 4), Color("11192172"))
	for foot: Vector2 in [corner + height + side * 0.12, turn + height - side * 0.12, right + height - front * 0.13]:
		_image.fill_rect(Rect2i(Vector2i(foot), Vector2i(5, 4)), Color("111921"))
	_quad(back, right, turn, corner, paint.lightened(0.18))
	_panel(back, side, -front, Rect2(0.13, 0.23, 0.6, 0.36), steel)
	for index in range(8):
		_panel(back, side, -front, Rect2(0.15 + index * 0.072, 0.29, 0.026, 0.24), paint)
	_quad(corner, turn, turn + height, corner + height, paint)
	_quad(turn, right, right + height, turn + height, paint.darkened(0.28))
	_draw_side(model, lid_attached, corner, side, height, paint, edge, steel)
	_draw_front(model, turn, front, height, accent, paint, steel)
	_panel(corner, side, height, Rect2(0.0, 0.0, 1.0, 0.024), edge)
	_panel(turn, front, height, Rect2(0.0, 0.0, 1.0, 0.024), edge)
	_panel(turn, front, height, Rect2(0.0, 0.0, 0.07, 1.0), edge)


func _draw_side(model: Dictionary, lid_attached: bool, corner: Vector2, side: Vector2, height: Vector2,
		paint: Color, edge: Color, steel: Color) -> void:
	if not lid_attached or model.glass:
		var interior := Color("445d68") if model.front_glass else Color("14242e")
		_panel(corner, side, height, Rect2(0.06, 0.06, 0.88, 0.87), steel)
		_panel(corner, side, height, Rect2(0.12, 0.13, 0.69, 0.57), interior)
		_panel(corner, side, height, Rect2(0.11, 0.75, 0.77, 0.13), paint.darkened(0.2))
		for x in [0.18, 0.42, 0.66]:
			for y in [0.2, 0.58]:
				_panel(corner, side, height, Rect2(x, y, 0.028, 0.025), edge)
		if lid_attached:
			_panel(corner, side, height, Rect2(0.09, 0.09, 0.82, 0.81),
				Color("75adb75a") if model.front_glass else Color("56758b48"))
			_quad(corner + side * 0.15 + height * 0.1, corner + side * 0.31 + height * 0.1,
				corner + side * 0.6 + height * 0.56, corner + side * 0.5 + height * 0.56, Color("c0dde139"))
		return
	_panel(corner, side, height, Rect2(0.08, 0.11, 0.83, 0.76), paint.lightened(0.08))
	var first_vent := 0.35 if model.key == "intara_m100" else 0.21
	for index in range(6):
		_panel(corner, side, height, Rect2(first_vent, 0.44 + index * 0.045, 0.36, 0.02), steel)
	_panel(corner, side, height, Rect2(0.81, 0.15, 0.05, 0.04), edge)


func _draw_front(model: Dictionary, corner: Vector2, front: Vector2, height: Vector2,
		accent: Color, paint: Color, steel: Color) -> void:
	_panel(corner, front, height, Rect2(0.14, 0.13, 0.74, 0.78), steel)
	if model.front_glass:
		_panel(corner, front, height, Rect2(0.19, 0.14, 0.63, 0.64), Color("4a737d"))
		_panel(corner, front, height, Rect2(0.25, 0.19, 0.09, 0.54), accent)
		_panel(corner, front, height, Rect2(0.14, 0.8, 0.74, 0.08), paint)
	elif model.glass:
		for index in range(13):
			_panel(corner, front, height, Rect2(0.22, 0.2 + index * 0.05, 0.54, 0.016), paint)
		_quad(corner + front * 0.13 + height * 0.16, corner + front * 0.25 + height * 0.16,
			corner + front * 0.48 + height * 0.85, corner + front * 0.34 + height * 0.85, accent)
	elif model.key == "intara_m100":
		_panel(corner, front, height, Rect2(0.14, 0.17, 0.71, 0.33), paint)
		_panel(corner, front, height, Rect2(0.25, 0.23, 0.51, 0.08), steel)
		for index in range(4):
			_panel(corner, front, height, Rect2(0.23, 0.57 + index * 0.065, 0.55, 0.027), paint)
	else:
		for index in range(12):
			_panel(corner, front, height, Rect2(0.21, 0.23 + index * 0.049, 0.59, 0.025), paint)
	_panel(corner, front, height, Rect2(0.47, 0.07, 0.16, 0.055), accent)


func _panel(origin: Vector2, horizontal: Vector2, vertical: Vector2, area: Rect2, color: Color) -> void:
	var top_left := origin + horizontal * area.position.x + vertical * area.position.y
	var width := horizontal * area.size.x
	var height := vertical * area.size.y
	_quad(top_left, top_left + width, top_left + width + height, top_left + height, color)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	var points := PackedVector2Array([a, b, c, d])
	var bounds := Rect2(a, Vector2.ZERO).expand(b).expand(c).expand(d)
	for y in range(maxi(0, floori(bounds.position.y)), mini(_image.get_height(), ceili(bounds.end.y))):
		for x in range(maxi(0, floori(bounds.position.x)), mini(_image.get_width(), ceili(bounds.end.x))):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_image.set_pixel(x, y, _image.get_pixel(x, y).blend(color))

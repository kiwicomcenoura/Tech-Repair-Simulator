extends SceneTree
## Original small pixel-art units and a RAM-editable inspection background.

func rect(img: Image, x: int, y: int, w: int, h: int, color: String) -> void:
	img.fill_rect(Rect2i(x, y, w, h), Color(color))


func polygon(img: Image, points: PackedVector2Array, color: String) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), points): img.set_pixel(x, y, Color(color))


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://Assets/Physical")
	for kind in ["ram", "gpu", "storage", "psu", "cooling", "motherboard", "cpu", "pc", "box", "toolbox"]:
		var img := Image.create(64, 80, false, Image.FORMAT_RGBA8)
		if kind == "pc":
			polygon(img, PackedVector2Array([Vector2(8, 18), Vector2(43, 10), Vector2(57, 18), Vector2(22, 27)]), "596e82")
			polygon(img, PackedVector2Array([Vector2(8, 18), Vector2(22, 27), Vector2(22, 73), Vector2(8, 64)]), "172738")
			polygon(img, PackedVector2Array([Vector2(22, 27), Vector2(57, 18), Vector2(57, 65), Vector2(22, 73)]), "2e475b")
			for y in range(35, 61, 4): rect(img, 28, y, 22, 1, "172b3c")
			rect(img, 50, 25, 3, 3, "6dafc1")
		elif kind in ["box", "toolbox"]:
			var c := "91734e" if kind == "box" else "346177"
			polygon(img, PackedVector2Array([Vector2(8, 46), Vector2(38, 36), Vector2(58, 45), Vector2(29, 56)]), "b4a286" if kind == "box" else "568a9e")
			polygon(img, PackedVector2Array([Vector2(8, 46), Vector2(29, 56), Vector2(29, 74), Vector2(8, 64)]), "574736" if kind == "box" else "203b50")
			polygon(img, PackedVector2Array([Vector2(29, 56), Vector2(58, 45), Vector2(58, 63), Vector2(29, 74)]), c)
			rect(img, 38, 57, 12, 6, "d3d9d7")
		else:
			var widths := {"ram": 38, "gpu": 48, "storage": 30, "psu": 34, "cooling": 32, "motherboard": 46, "cpu": 24}
			var w: int = widths[kind]
			var c := "315b50" if kind in ["ram", "motherboard"] else "3b5266"
			polygon(img, PackedVector2Array([Vector2(7, 60), Vector2(7 + w, 49), Vector2(16 + w, 57), Vector2(16, 69)]), c)
			polygon(img, PackedVector2Array([Vector2(7, 60), Vector2(16, 69), Vector2(16, 73), Vector2(7, 64)]), "142436")
			for i in range(4): rect(img, 17 + i * 6, 58 - i, 4, 4, "172330")
			if kind in ["storage", "cpu", "psu"]: rect(img, 22, 57, 15, 6, "a8b7bd")
			if kind == "ram":
				for i in range(7): rect(img, 17 + i * 4, 68 - i, 2, 2, "c8ac69")
			if kind in ["cooling", "gpu"]:
				for x in range(23, 36):
					for y in range(54, 65):
						if Vector2(x - 29, y - 59).length() < 6: img.set_pixel(x, y, Color("8aa8b6"))
		var result := img.save_png("res://Assets/Physical/" + kind + ".png")
		if result != OK:
			push_error(error_string(result)); quit(1); return
	var editable := Image.load_from_file("res://Assets/Inspection/desktop_open.png")
	rect(editable, 141, 44, 36, 62, "214b48")
	for y in range(48, 105, 11): rect(editable, 141, y, 36, 1, "315e52")
	for x in [145, 156, 167]: rect(editable, x, 48, 6, 53, "101d28")
	editable.save_png("res://Assets/Physical/desktop_editable.png")
	var module := Image.create(12, 52, false, Image.FORMAT_RGBA8)
	rect(module, 2, 1, 8, 50, "3a7c80")
	rect(module, 9, 3, 2, 46, "cdb270")
	for y in range(5, 46, 10): rect(module, 3, y, 5, 7, "172b37")
	module.save_png("res://Assets/Physical/ram_module.png")
	print("Generated ten physical item PNGs, RAM module and editable desktop background.")
	quit()

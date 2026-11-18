extends SceneTree
## Original layered pixel art, 320 x 240. Coordinates match inspection hit areas.

const OUT := "res://Assets/Inspection/"

func box(img: Image, r: Rect2i, color: String) -> void:
	img.fill_rect(r, Color(color))


func line(img: Image, a: Vector2i, b: Vector2i, color: String, width: int = 1) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in range(steps + 1):
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxi(1, steps)).round()
		box(img, Rect2i(Vector2i(p), Vector2i(width, width)), color)


func fan(img: Image, center: Vector2i, radius: int) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var d := x * x + y * y
			if d <= radius * radius:
				var c := "101a23" if d < (radius - 2) * (radius - 2) else "778b98"
				box(img, Rect2i(center + Vector2i(x, y), Vector2i.ONE), c)
	for i in range(6):
		var angle := float(i) * TAU / 6.0
		var a := center + Vector2i(Vector2.from_angle(angle) * 4.0)
		var b := center + Vector2i(Vector2.from_angle(angle + 0.4) * (radius - 4))
		line(img, a, b, "3d6277", 3)
	box(img, Rect2i(center - Vector2i(3, 3), Vector2i(7, 7)), "9db6c2")
	box(img, Rect2i(center - Vector2i.ONE, Vector2i(3, 3)), "54788c")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var pc := Image.create(320, 240, false, Image.FORMAT_RGBA8)
	# Chassis, folded metal rails and front panel.
	box(pc, Rect2i(23, 23, 245, 188), "080f17")
	box(pc, Rect2i(20, 16, 240, 188), "566676")
	box(pc, Rect2i(24, 20, 232, 180), "263341")
	box(pc, Rect2i(29, 25, 222, 170), "101b27")
	box(pc, Rect2i(260, 19, 29, 185), "1c2b3c")
	box(pc, Rect2i(262, 23, 22, 176), "243b50")
	box(pc, Rect2i(286, 23, 4, 179), "0c1723")
	box(pc, Rect2i(25, 17, 231, 2), "b5c3ca")
	box(pc, Rect2i(22, 24, 2, 173), "788e9e")
	for y in range(54, 183, 5):
		box(pc, Rect2i(267, y, 13, 2), "101f2d")
	box(pc, Rect2i(270, 30, 7, 7), "0c1b28")
	box(pc, Rect2i(272, 32, 3, 3), "6abdd1")
	box(pc, Rect2i(267, 43, 6, 2), "738797")
	box(pc, Rect2i(277, 43, 3, 2), "738797")
	for x in [34, 237]:
		box(pc, Rect2i(x, 204, 17, 6), "0c1620")
		box(pc, Rect2i(x + 2, 204, 13, 2), "81919d")
	# Motherboard with plated vias, slots and copper traces.
	box(pc, Rect2i(42, 38, 145, 115), "60837b")
	box(pc, Rect2i(44, 40, 141, 111), "214b48")
	for i in range(9):
		line(pc, Vector2i(50 + i * 14, 46), Vector2i(50 + i * 14, 144), "315e52")
		line(pc, Vector2i(50, 48 + i * 11), Vector2i(178, 48 + i * 11), "315e52")
	for x in [47, 180]:
		for y in [43, 147]:
			box(pc, Rect2i(x, y, 3, 3), "b6b2a0")
	for x in range(52, 80, 7):
		box(pc, Rect2i(x, 46, 4, 13), "a3afb5")
		box(pc, Rect2i(x, 48, 1, 9), "546f7c")
	for x in range(52, 79, 8):
		box(pc, Rect2i(x, 101, 5, 6), "151f2a")
		box(pc, Rect2i(x, 101, 5, 1), "9ab6ae")
	box(pc, Rect2i(81, 56, 46, 48), "151f2a")
	for x in range(82, 127, 3):
		box(pc, Rect2i(x, 58, 1, 44), "71858a")
	fan(pc, Vector2i(104, 80), 22)
	# RAM sticks and retention clips.
	for x in [144, 155, 166]:
		box(pc, Rect2i(x, 46, 7, 57), "101d28")
		box(pc, Rect2i(x + 1, 49, 5, 50), "38818a")
		for y in range(53, 96, 10):
			box(pc, Rect2i(x + 2, y, 3, 6), "172b37")
		box(pc, Rect2i(x, 46, 7, 2), "a1b7c0")
		box(pc, Rect2i(x, 101, 7, 2), "a1b7c0")
	# Graphics card over the PCIe slot.
	box(pc, Rect2i(49, 119, 156, 30), "0a131d")
	box(pc, Rect2i(53, 122, 149, 24), "415a6d")
	box(pc, Rect2i(57, 124, 140, 20), "1b2a38")
	fan(pc, Vector2i(91, 134), 9)
	fan(pc, Vector2i(146, 134), 9)
	box(pc, Rect2i(51, 121, 2, 28), "a1b6c0")
	box(pc, Rect2i(179, 126, 15, 2), "66afbd")
	# SATA storage bay and SSD label.
	box(pc, Rect2i(211, 42, 29, 40), "4d6475")
	box(pc, Rect2i(214, 45, 23, 34), "1e303f")
	box(pc, Rect2i(216, 50, 19, 20), "a4b4bd")
	for y in [54, 58, 62]:
		box(pc, Rect2i(219, y, 13, 1), "4e697d")
	box(pc, Rect2i(211, 103, 29, 40), "52616c")
	box(pc, Rect2i(214, 107, 23, 29), "b0bec5")
	box(pc, Rect2i(217, 112, 17, 7), "2b4b61")
	for y in [123, 126, 129]:
		box(pc, Rect2i(217, y, 15, 1), "688593")
	# Power supply and sleeved cable routes, drawn over the open tray.
	box(pc, Rect2i(41, 160, 99, 34), "697886")
	box(pc, Rect2i(44, 163, 93, 28), "1c2b39")
	for y in range(166, 187, 4):
		box(pc, Rect2i(49, y, 36, 1), "527180")
	box(pc, Rect2i(95, 168, 33, 14), "9eafb8")
	for y in [172, 176]:
		box(pc, Rect2i(100, y, 23, 1), "435a69")
	for i in range(4):
		var x := 140 + i * 3
		var color: String = ["344956", "526875", "936f4e", "344956"][i]
		line(pc, Vector2i(x, 176), Vector2i(193 + i * 2, 176), "080f16", 3)
		line(pc, Vector2i(193 + i * 2, 176), Vector2i(193 + i * 2, 83), "080f16", 3)
		line(pc, Vector2i(x, 176), Vector2i(193 + i * 2, 176), color, 1)
		line(pc, Vector2i(193 + i * 2, 176), Vector2i(193 + i * 2, 83), color, 1)
	line(pc, Vector2i(220, 143), Vector2i(220, 182), "1c141b", 3)
	line(pc, Vector2i(220, 182), Vector2i(167, 182), "804d50", 2)
	line(pc, Vector2i(220, 143), Vector2i(220, 182), "804d50", 1)
	box(pc, Rect2i(182, 75, 6, 16), "94a29b")
	# Removed fastener tray. Its actual contents are drawn interactively.
	box(pc, Rect2i(65, 221, 155, 15), "1b2d3c")
	box(pc, Rect2i(67, 223, 151, 11), "0d1925")
	var lid := Image.create(320, 240, false, Image.FORMAT_RGBA8)
	box(lid, Rect2i(28, 24, 224, 172), "12212e")
	box(lid, Rect2i(30, 26, 220, 168), "405466")
	box(lid, Rect2i(32, 28, 216, 164), "324658")
	box(lid, Rect2i(33, 29, 213, 1), "637d90")
	box(lid, Rect2i(33, 30, 1, 160), "526e82")
	for y in range(57, 157, 5):
		for x in range(71, 190, 6):
			box(lid, Rect2i(x, y, 3, 2), "1f3344")
	box(lid, Rect2i(226, 98, 10, 27), "172b3c")
	box(lid, Rect2i(228, 100, 2, 23), "7890a0")
	# Light, deterministic metal grain kept below component readability.
	for i in range(180):
		var x := 40 + (i * 37) % 175
		var y := 35 + (i * 29) % 147
		if y < 55 or y > 159:
			box(lid, Rect2i(x, y, 1, 1), "3b5062")
	var tool := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	line(tool, Vector2i(10, 36), Vector2i(36, 10), "17232e", 5)
	line(tool, Vector2i(14, 32), Vector2i(37, 9), "afc3ce", 3)
	line(tool, Vector2i(7, 37), Vector2i(20, 24), "15445d", 8)
	line(tool, Vector2i(9, 36), Vector2i(21, 24), "50acc9", 4)
	box(tool, Rect2i(36, 8, 4, 4), "d2e1e8")
	for item in [[pc, "desktop_open.png"], [lid, "desktop_lid.png"], [tool, "phillips.png"]]:
		var result: Error = item[0].save_png(OUT + item[1])
		if result != OK:
			push_error("Could not save inspection art: " + error_string(result))
			quit(1)
			return
	print("Created 3 original transparent inspection PNGs.")
	quit()

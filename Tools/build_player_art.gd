extends SceneTree
## Original, deterministic pixel art. Run with Godot --headless --script.
## Atlas rows: down, up, left, right, down_left, down_right, up_left,
## up_right. Columns: idle x2, walk x8. All diagonals use three-quarter poses.

const OUT := "res://Assets/Characters/TechnicianV1/"
const INK := Color("10131c")
const HAIR := Color("362622")
const HAIR_LIGHT := Color("624637")
const SKIN := Color("d6a07a")
const SKIN_LIGHT := Color("efbb91")
const CLOTH := Color("20232d")
const CLOTH_LIGHT := Color("343b47")
const PANTS := Color("242d3c")
const WHITE := Color("e9edf0")


func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height())), c)


func oval(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(h):
		for xx in range(w):
			var dx := (float(xx) + 0.5 - float(w) / 2.0) / (float(w) / 2.0)
			var dy := (float(yy) + 0.5 - float(h) / 2.0) / (float(h) / 2.0)
			if dx * dx + dy * dy <= 1.0:
				rect(img, x + xx, y + yy, 1, 1, c)


func limb(img: Image, start: Vector2i, end: Vector2i, width: int, c: Color) -> void:
	var steps := maxi(absi(end.x - start.x), absi(end.y - start.y))
	for step in range(steps + 1):
		var t := float(step) / float(maxi(1, steps))
		var pos := Vector2(start).lerp(Vector2(end), t).round()
		rect(img, int(pos.x) - width / 2, int(pos.y), width, width, c)


func leg(img: Image, hip: Vector2i, ankle: Vector2i, side: bool) -> void:
	limb(img, hip, ankle, 5, INK)
	limb(img, hip + Vector2i(0, 1), ankle, 3, PANTS)
	rect(img, ankle.x - 2, ankle.y + 2, 6 if side else 5, 3, INK)
	rect(img, ankle.x - 1, ankle.y + 2, 5 if side else 3, 2, WHITE)
	rect(img, ankle.x - 1, ankle.y + 4, 5 if side else 3, 1, Color("94a4b7"))


func arm(img: Image, start: Vector2i, end: Vector2i, light: bool) -> void:
	limb(img, start, end, 5, INK)
	limb(img, start + Vector2i(0, 1), end, 3, CLOTH_LIGHT if light else CLOTH)
	rect(img, end.x - 1, end.y + 3, 3, 3, SKIN)
	rect(img, end.x - 1, end.y + 3, 2, 1, SKIN_LIGHT)


func diagonal_frame(direction: String, walking: bool, index: int) -> Image:
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	var swing: int = [-2, -1, 0, 1, 2, 1, 0, -1][index] if walking else 0
	var bob: int = [0, -1, -1, 0, 0, -1, -1, 0][index] if walking else index
	var lift_a: int = [0, -1, -2, -1, 0, 0, 0, 0][index] if walking else 0
	var lift_b: int = [0, 0, 0, 0, 0, -1, -2, -1][index] if walking else 0
	var back := direction.begins_with("up_")
	var stride_y := int(swing / 2.0) * (-1 if back else 1)
	oval(img, 6, 43, 21, 4, Color(0.02, 0.03, 0.05, 0.25))
	# Stagger the hips, knees and feet in both axes for a diagonal stride.
	leg(img, Vector2i(13, 32 + bob), Vector2i(13 - swing, 39 + stride_y + lift_a), true)
	arm(img, Vector2i(10, 24 + bob), Vector2i(9 + swing, 30 + bob - stride_y), false)
	leg(img, Vector2i(20, 33 + bob), Vector2i(20 + swing, 40 - stride_y + lift_b), true)
	# A three-quarter torso, wider than profile and asymmetric to front.
	oval(img, 8, 21 + bob, 18, 15, INK)
	rect(img, 10, 25 + bob, 14, 10, INK)
	rect(img, 11, 25 + bob, 12, 8, CLOTH)
	rect(img, 11, 26 + bob, 3, 6, CLOTH_LIGHT)
	rect(img, 12, 33 + bob, 10, 1, Color("131923"))
	if back:
		oval(img, 10, 21 + bob, 13, 7, CLOTH_LIGHT)
		oval(img, 12, 22 + bob, 9, 4, CLOTH)
	else:
		rect(img, 18, 25 + bob, 1, 4, Color("a0acb6"))
		rect(img, 22, 25 + bob, 1, 3, Color("a0acb6"))
		rect(img, 16, 30 + bob, 6, 1, CLOTH_LIGHT)
	rect(img, 16, 20 + bob, 5, 4, INK)
	rect(img, 17, 20 + bob, 3, 3, SKIN)
	oval(img, 7, 4 + bob, 21, 19, INK)
	oval(img, 9, 6 + bob, 17, 15, HAIR)
	if back:
		# Rear three-quarter: hair and nape dominate; only the far cheek
		# and one ear remain visible. This is not a recycled side frame.
		oval(img, 22, 12 + bob, 5, 8, SKIN)
		rect(img, 25, 15 + bob, 3, 2, SKIN)
		oval(img, 9, 9 + bob, 16, 12, HAIR)
		rect(img, 19, 16 + bob, 3, 3, SKIN)
		rect(img, 20, 17 + bob, 1, 1, SKIN_LIGHT)
		rect(img, 13, 19 + bob, 7, 2, Color("261e20"))
	else:
		# Front three-quarter: both eyes, offset jaw, nose and fringe.
		oval(img, 13, 11 + bob, 13, 11, SKIN)
		rect(img, 15, 13 + bob, 10, 5, SKIN_LIGHT)
		rect(img, 17, 15 + bob, 2, 2, INK)
		rect(img, 24, 15 + bob, 1, 2, INK)
		rect(img, 22, 18 + bob, 3, 1, Color("b47861"))
		rect(img, 19, 20 + bob, 4, 1, Color("ae745c"))
		rect(img, 11, 16 + bob, 3, 3, SKIN)
	oval(img, 8, 4 + bob, 18, 11, HAIR)
	rect(img, 11, 5 + bob, 8, 2, HAIR_LIGHT)
	rect(img, 10, 8 + bob, 4, 3, Color("493128"))
	rect(img, 17, 9 + bob, 5, 3, Color("51382c"))
	rect(img, 11, 12 + bob, 3, 4, HAIR)
	if not back:
		rect(img, 18, 12 + bob, 3, 3, HAIR)
	arm(img, Vector2i(23, 25 + bob), Vector2i(23 - swing, 31 + bob + stride_y), true)
	if direction.ends_with("_left"):
		img.flip_x()
	return img


func frame(direction: String, walking: bool, index: int) -> Image:
	if direction.contains("_"):
		return diagonal_frame(direction, walking, index)
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	var swings := [-2, -1, 0, 1, 2, 1, 0, -1]
	var swing: int = swings[index] if walking else 0
	var bob: int = [0, -1, -1, 0, 0, -1, -1, 0][index] if walking else index
	var lift_a: int = [0, -1, -2, -1, 0, 0, 0, 0][index] if walking else 0
	var lift_b: int = [0, 0, 0, 0, 0, -1, -2, -1][index] if walking else 0
	oval(img, 6, 43, 21, 4, Color(0.02, 0.03, 0.05, 0.25))
	var side := direction == "left" or direction == "right"
	var profile_step: int = [-4, -2, 1, 3, 4, 2, -1, -3][index] if walking and side else 0
	if side:
		# In the right-facing master pose the lifted foot advances to the right.
		# The planted foot moves back under the body as the player moves forward.
		leg(img, Vector2i(14, 32 + bob), Vector2i(14 + profile_step, 39 + lift_a), true)
		arm(img, Vector2i(14, 25 + bob), Vector2i(14 - profile_step, 31 + bob), false)
		leg(img, Vector2i(17, 32 + bob), Vector2i(17 - profile_step, 40 + lift_b), true)
	else:
		leg(img, Vector2i(12, 32 + bob), Vector2i(12 - int(swing / 2.0), 40 + lift_a), false)
		leg(img, Vector2i(20, 32 + bob), Vector2i(20 + int(swing / 2.0), 40 + lift_b), false)
		arm(img, Vector2i(9, 25 + bob), Vector2i(8 - int(swing / 2.0), 31 + bob - swing), false)
		arm(img, Vector2i(23, 25 + bob), Vector2i(24 + int(swing / 2.0), 31 + bob + swing), true)
	# Hoodie outline, shoulders, hem and folds.
	oval(img, 7 if not side else 10, 21 + bob, 19 if not side else 13, 15, INK)
	rect(img, 9 if not side else 11, 25 + bob, 15 if not side else 11, 10, INK)
	rect(img, 10 if not side else 12, 25 + bob, 13 if not side else 9, 8, CLOTH)
	rect(img, 10 if not side else 12, 25 + bob, 2, 7, CLOTH_LIGHT)
	rect(img, 11 if not side else 13, 33 + bob, 11 if not side else 8, 1, Color("131923"))
	if direction == "up":
		oval(img, 10, 21 + bob, 13, 7, CLOTH_LIGHT)
		oval(img, 12, 22 + bob, 9, 4, CLOTH)
	else:
		rect(img, 14 if not side else 19, 25 + bob, 1, 4, Color("a0acb6"))
		rect(img, 19 if not side else 21, 25 + bob, 1, 4, Color("a0acb6"))
		rect(img, 13 if not side else 16, 30 + bob, 7 if not side else 4, 1, CLOTH_LIGHT)
	# Neck and large readable head, viewed slightly from above.
	rect(img, 14 if not side else 16, 20 + bob, 5, 4, INK)
	rect(img, 15 if not side else 17, 20 + bob, 3, 3, SKIN)
	oval(img, 6 if not side else 9, 4 + bob, 21 if not side else 17, 19, INK)
	oval(img, 8 if not side else 11, 6 + bob, 17 if not side else 13, 15, HAIR)
	if direction != "up":
		oval(img, 10 if not side else 16, 11 + bob, 13 if not side else 9, 11, SKIN)
		rect(img, 11 if not side else 19, 13 + bob, 10 if not side else 5, 5, SKIN_LIGHT)
		if side:
			rect(img, 24, 15 + bob, 2, 3, SKIN)
			rect(img, 22, 14 + bob, 1, 2, INK)
			rect(img, 15, 16 + bob, 3, 3, SKIN)
			rect(img, 16, 17 + bob, 1, 1, SKIN_LIGHT)
		else:
			rect(img, 12, 15 + bob, 2, 2, INK)
			rect(img, 20, 15 + bob, 2, 2, INK)
			rect(img, 16, 18 + bob, 2, 1, Color("b47861"))
			rect(img, 15, 20 + bob, 4, 1, Color("ae745c"))
	# Uneven fringe, crown highlights and side locks.
	oval(img, 7 if not side else 9, 4 + bob, 19 if not side else 15, 11, HAIR)
	rect(img, 10 if not side else 11, 5 + bob, 8, 2, HAIR_LIGHT)
	rect(img, 8 if not side else 10, 8 + bob, 4, 3, Color("493128"))
	rect(img, 15, 9 + bob, 5, 3, Color("51382c"))
	rect(img, 9 if not side else 11, 12 + bob, 3, 5, HAIR)
	if direction == "down":
		rect(img, 14, 12 + bob, 3, 3, HAIR)
		rect(img, 21, 11 + bob, 3, 5, HAIR)
	if direction == "up":
		oval(img, 8, 10 + bob, 17, 11, HAIR)
		rect(img, 10, 14 + bob, 2, 4, Color("493128"))
		rect(img, 14, 19 + bob, 8, 2, Color("261e20"))
	if side:
		arm(img, Vector2i(16, 25 + bob), Vector2i(16 + profile_step, 31 + bob), true)
	if direction == "left":
		img.flip_x()
	return img


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var atlas := Image.create(320, 384, false, Image.FORMAT_RGBA8)
	var directions := ["down", "up", "left", "right", "down_left", "down_right", "up_left", "up_right"]
	for row in range(directions.size()):
		for col in range(10):
			var sprite := frame(directions[row], col >= 2, col - 2 if col >= 2 else col)
			atlas.blit_rect(sprite, Rect2i(0, 0, 32, 48), Vector2i(col * 32, row * 48))
	var error := atlas.save_png(OUT + "technician_atlas.png")
	if error != OK:
		push_error("Cannot save atlas: " + error_string(error))
		quit(1)
		return
	var preview := atlas.duplicate()
	preview.resize(1280, 1536, Image.INTERPOLATE_NEAREST)
	preview.save_png(OUT + "technician_preview.png")
	print("Created original transparent atlas: 80 frames, 8 directions, 8-frame walk cycles.")
	quit()

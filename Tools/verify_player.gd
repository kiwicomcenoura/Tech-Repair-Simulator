extends SceneTree
## Integration checks against the actual PNG, scenes, input and physics.

var failures: Array[String] = []
var checks := 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame


func release_keys() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)

func shoe_front(atlas: Image, row: int, stride: int, shoe_y: int, left: bool) -> int:
	var frame_start := (stride + 2) * 32
	for offset in range(32):
		var x := offset if left else 31 - offset
		if atlas.get_pixel(frame_start + x, row * 48 + shoe_y).is_equal_approx(Color("e9edf0")):
			return x
	return -1

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var world: Node2D = preload("res://Tools/test_world.gd").create()
	root.add_child(world)
	await ticks(3)
	var player: CharacterBody2D = world.get_node("Actors/Player")
	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	var frames := sprite.sprite_frames
	var texture: Texture2D = load("res://Assets/Characters/TechnicianV1/technician_atlas.png")
	var atlas := texture.get_image()
	check(atlas.get_size() == Vector2i(320, 384), "Atlas dimensions")
	check(atlas.get_pixel(0, 0).a == 0.0, "PNG transparent background")
	var right_back := shoe_front(atlas, 3, 0, 41, false)
	var right_forward := shoe_front(atlas, 3, 3, 40, false)
	var left_back := shoe_front(atlas, 2, 0, 41, true)
	var left_forward := shoe_front(atlas, 2, 3, 40, true)
	check(right_back >= 0 and right_forward > right_back, "Right-facing lifted foot advances in the direction of travel")
	check(left_forward >= 0 and left_forward < left_back, "Left-facing lifted foot advances in the direction of travel")
	check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Nearest filtering")
	check(player.get_node("Camera2D").enabled, "Camera remains enabled")
	check(frames.get_animation_names().size() == 16, "Sixteen animation names")
	var directions := ["down", "up", "left", "right", "down_left", "down_right", "up_left", "up_right"]
	for row in range(directions.size()):
		var dir: String = directions[row]
		check(frames.get_frame_count("idle_" + dir) == 2, "Idle frame count: " + dir)
		check(frames.get_frame_count("walk_" + dir) == 8, "Walk frame count: " + dir)
		check(frames.get_animation_loop("idle_" + dir), "Idle loop: " + dir)
		check(frames.get_animation_loop("walk_" + dir), "Walk loop: " + dir)
		var distinct: Dictionary = {}
		var upper_limbs: Dictionary = {}
		var lower_limbs: Dictionary = {}
		for col in range(2, 10):
			var image := atlas.get_region(Rect2i(col * 32, row * 48, 32, 48))
			distinct[image.get_data().hex_encode().sha256_text()] = true
			upper_limbs[image.get_region(Rect2i(0, 24, 32, 12)).get_data().hex_encode().sha256_text()] = true
			lower_limbs[image.get_region(Rect2i(0, 36, 32, 11)).get_data().hex_encode().sha256_text()] = true
		check(distinct.size() == 8, "Eight genuinely different walk frames: " + dir)
		check(upper_limbs.size() >= 4, "Arm/torso changes: " + dir)
		check(lower_limbs.size() >= 4, "Leg/foot changes: " + dir)
		if dir.contains("_"):
			var diagonal := atlas.get_region(Rect2i(64, row * 48, 32, 48)).get_data()
			for cardinal_row in range(4):
				check(diagonal != atlas.get_region(Rect2i(64, cardinal_row * 48, 32, 48)).get_data(), "Diagonal differs from cardinal sprite: " + dir)
	# Exercise all eight inputs through the real CharacterBody2D script.
	var cases := [
		[["move_down"], "down"], [["move_up"], "up"],
		[["move_left"], "left"], [["move_right"], "right"],
		[["move_up", "move_left"], "up_left"],
		[["move_up", "move_right"], "up_right"],
		[["move_down", "move_left"], "down_left"],
		[["move_down", "move_right"], "down_right"],
	]
	for item in cases:
		release_keys()
		player.global_position = Vector2.ZERO
		await ticks(2)
		for action in item[0]:
			Input.action_press(action)
		await ticks(3)
		check(is_equal_approx(player.velocity.length(), player.speed), "Normalized speed: " + str(item[0]))
		check(sprite.animation == "walk_" + item[1], "Walk facing: " + str(item[0]))
		check(sprite.is_playing(), "Animation playback")
		release_keys()
		await ticks(2)
		check(player.velocity.is_zero_approx(), "Stop after key release")
		check(sprite.animation == "idle_" + item[1], "Idle remembers facing")
	# Keep W held during W+D -> W+A -> W+D; then keep D held
	# during W+D -> S+D. No intermediate release of all keys.
	player.global_position = Vector2.ZERO
	Input.action_press("move_up")
	Input.action_press("move_right")
	await ticks(2)
	check(sprite.animation == "walk_up_right", "W+D uses up-right sprite")
	sprite.set_frame_and_progress(4, 0.25)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await ticks(1)
	check(sprite.animation == "walk_up_left", "W+D to W+A without releasing W")
	check(sprite.frame >= 4, "Turning preserves the current footfall")
	check(player.velocity.x < 0.0 and player.velocity.y < 0.0, "W+A switches movement immediately")
	Input.action_release("move_left")
	Input.action_press("move_right")
	await ticks(1)
	check(sprite.animation == "walk_up_right", "W+A to W+D without releasing W")
	Input.action_release("move_up")
	Input.action_press("move_down")
	await ticks(1)
	check(sprite.animation == "walk_down_right", "W+D to S+D without releasing D")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await ticks(1)
	check(sprite.animation == "walk_down_left", "S+D to S+A without releasing S")
	release_keys()
	await ticks(1)
	check(sprite.animation == "idle_down_left", "Remembers diagonal idle after key release")
	# Approach the repair bench from its front corner.
	var bench: Node2D = world.get_node("Actors/RepairBench")
	player.global_position = bench.global_position + Vector2(0, 45)
	Input.action_press("move_up")
	await ticks(25)
	check(player.global_position.y >= bench.global_position.y + 13.0, "Bench footprint blocks feet")
	check(sprite.animation == "idle_up", "Idle when blocked against bench")
	check(bench.z_index < player.z_index, "Bench behind actor on front face")
	release_keys()
	# Both diagonal faces and rear must sort independently of raw Y.
	for point in [Vector2(-100, -42), Vector2(40, -12)]:
		player.global_position = bench.global_position + point
		await ticks(2)
		check(bench.z_index < player.z_index, "Correct depth at diagonal front face")
	player.global_position = bench.global_position + Vector2(-20, -180)
	await ticks(2)
	check(bench.z_index > player.z_index, "Bench occludes actor at rear")
	for prop_name in ["RepairBench", "WorkComputer", "ServiceCounter", "Shelf"]:
		var prop: Node2D = world.get_node("Actors/" + prop_name)
		var textured := false
		for child in prop.get_children():
			if child is Polygon2D and child.texture != null:
				textured = true
		check(textured, "Textured material: " + prop_name)
		check(prop.has_node("Details"), "Prop details: " + prop_name)
	var computer: Node2D = world.get_node("Actors/WorkComputer")
	check(computer.get_node("Details").find_child("MouseBody*", false, false) != null, "Mouse beside keyboard")
	check(computer.get_node("Details").find_child("Mousepad*", false, false) != null, "Mousepad on desk")
	print("PLAYER CHECKS: ", checks, "; failures: ", failures.size())
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

extends SceneTree

var checks := 0
var failures: Array[String] = []


func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error(description)


func ticks(count: int = 2) -> void:
	for i in range(count):
		await physics_frame
		await process_frame


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1360, 768)
	var world: Node2D = preload("res://Tools/test_world.gd").create()
	root.add_child(world)
	await ticks()
	var player: CharacterBody2D = world.get_node("Actors/Player")
	var bench: Node2D = world.get_node("Actors/RepairBench")
	var ui: CanvasLayer = world.get_node("MaintenanceBenchUI")
	var prompt: Control = ui.get_node("%InteractionPrompt")
	var tabs: TabContainer = ui.get_node("%BenchTabs")
	check(not ui.is_open and not paused, "Starts closed and unpaused")
	check(not prompt.visible, "No prompt far from bench")
	await key(KEY_F)
	check(not ui.is_open, "F does not open bench from a distance")
	player.global_position = bench.global_position + Vector2(0, 35)
	await ticks()
	check(prompt.visible, "Prompt near physical bench footprint")
	await key(KEY_F)
	check(ui.is_open and paused, "F opens and pauses workshop")
	check(not prompt.visible, "Prompt hidden while interface is open")
	check(ui.get_node("%Overlay").visible, "Overlay visible")
	check(tabs.get_tab_count() == 4, "Four tabs")
	check(ui.get_node("%CloseButton").has_focus(), "Keyboard focus enters modal")
	var stopped_at := player.global_position
	Input.action_press("move_right")
	await ticks(4)
	check(player.global_position.is_equal_approx(stopped_at), "WASD movement blocked while open")
	Input.action_release("move_right")
	check(not ui.find_child("Inspect", true, false).disabled, "Inspection can open the empty cabinet selector")
	for name in ["Replace", "Finish", "StartDiagnostic"]:
		var action: Button = ui.find_child(name, true, false)
		check(action.disabled, "Empty action disabled: " + name)
	var capture := "--capture" in OS.get_cmdline_user_args()
	for i in range(4):
		tabs.current_tab = i
		await ticks()
		check(tabs.get_current_tab_control().visible, "Page visible: " + str(i))
		var window: Control = ui.find_child("WorkbenchWindow", true, false)
		var bounds := window.get_global_rect()
		check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= 1361 and bounds.end.y <= 769, "Window fits viewport on page " + str(i))
		if capture:
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			check(not image.is_empty(), "Rendered capture: " + str(i))
			image.save_png("res://.godot/maintenance-preview-" + str(i) + ".png")
	await key(KEY_ESCAPE)
	check(not ui.is_open and not paused, "ESC closes and restores workshop")
	Input.action_press("move_right")
	await ticks(3)
	Input.action_release("move_right")
	check(player.global_position.x > stopped_at.x, "Movement resumes after closing")
	player.global_position = bench.global_position + Vector2(0, 35)
	await ticks()
	await key(KEY_F)
	check(ui.is_open and tabs.current_tab == 0, "Reopen starts on overview")
	ui.get_node("%CloseButton").pressed.emit()
	await ticks()
	check(not ui.is_open and not paused, "X closes and unpauses")
	player.global_position = world.get_node("Actors/WorkComputer").global_position + Vector2(0, 35)
	await ticks()
	await key(KEY_F)
	check(not ui.is_open and not prompt.visible, "Other furniture has no maintenance interaction")
	var personal_ui: CanvasLayer = world.get_node("PersonalComputerUI")
	check(personal_ui.is_open, "F near fixed computer opens personal UI only")
	await key(KEY_ESCAPE)
	check(not personal_ui.is_open and not paused, "ESC closes personal computer and restores game")
	print("MAINTENANCE UI CHECKS: ", checks, "; failures: ", failures.size())
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

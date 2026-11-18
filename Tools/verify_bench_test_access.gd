extends SceneTree

var checks := 0
var failures: Array[String] = []


func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures.append(text)
		push_error(text)


func frames(count: int = 3) -> void:
	for i in range(count): await process_frame


func click(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames()


func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/bench-tests-" + name + ".png")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1360, 768)
	var world: Node2D = preload("res://Tools/test_world.gd").create(true)
	root.add_child(world)
	await frames(5)
	var workshop: Node = world.get_node("PhysicalWorkshop")
	var model: RefCounted = workshop.ledger
	var ui: CanvasLayer = world.get_node("MaintenanceBenchUI")
	ui.open_bench()
	ui.get_node("%BenchTabs").current_tab = 3
	await frames()
	check(ui.find_child("RunPOST", true, false).disabled and ui.find_child("RunRAMTest", true, false).disabled, "Empty bench tests disabled")
	check(not ui.open_inspection(), "No phantom equipment introduced")
	ui.close_bench()
	var pc_id := ""
	for record in model.state.items.values():
		if record.kind == "pc": pc_id = record.id
	world.get_node("Actors/Player").global_position = Vector2(130, -90)
	model.move(pc_id, "bench")
	await frames()
	check(workshop._hint_row.visible, "Nearby interaction hint has a visible panel")
	check(workshop._hint_row.get_child(0).get_theme_stylebox("panel").border_width_left == 1, "Hint has subtle one-pixel border")
	check(not ui.prompt.visible, "Duplicate interaction prompt hidden")
	check(workshop._hint_row.get_child_count() == 2, "Bench actions have separate captions")
	check(workshop._hint_row.get_theme_constant("separation") == 8, "Captions have a short gap")
	await capture("hint")
	ui.open_bench()
	ui.get_node("%BenchTabs").current_tab = 3
	await frames()
	var post: Button = ui.find_child("RunPOST", true, false)
	var ram: Button = ui.find_child("RunRAMTest", true, false)
	var video: Button = ui.find_child("RunVideoTest", true, false)
	var screen: Control = ui.find_child("BenchVideoScreen", true, false)
	var station: Node2D = world.get_node("Actors/RepairBench/TestStation")
	check(screen.status == "off" and station.status == "off" and video.disabled, "Both monitors turn off with the PC")
	check(not post.disabled and ram.disabled, "POST accessible and RAM explains power prerequisite")
	check("Ligue" in ui.find_child("TestPrerequisites", true, false).text, "Visible instructions for blocked RAM test")
	await click(post)
	check(model.item(pc_id).power and post.disabled and ram.disabled, "POST starts and prevents concurrent tests")
	await create_timer(1.3, true).timeout
	await frames()
	check(not model.item(pc_id).boot_ok and not ram.disabled, "Defective RAM does not require successful OS boot to be tested")
	check(screen.status == "no_signal" and station.status == "no_signal", "Bad RAM prevents video on both screens")
	check("ram" in ui.get_node("%BenchTabs").get_tab_control(3).get_node("Content/EmptyTests/Content/Description").text, "POST failure appears in Tests tab")
	await click(ram)
	var installed: String = model.item(pc_id).components.ram
	check(model.item(installed).tested and model.item(installed).health == 8, "Test reveals real faulty module health")
	check(not model.item(pc_id).boot_ok, "Testing does not repair broken RAM or fake a successful boot")
	check("8%" in ui.get_node("%BenchTabs").get_tab_control(3).get_node("Content/EmptyTests/Content/Description").text, "Known result shown persistently in Tests tab")
	for button in [post, ram, video, ui.find_child("TestPower", true, false)]:
		var bounds: Rect2 = button.get_global_rect()
		check(bounds.end.x <= 1361 and bounds.end.y <= 769, "Test action fits viewport: " + str(button.name))
	await capture("results")
	ui.open_inspection()
	await frames()
	check(not ui.inspection.find_child("MemoryTest", true, false).disabled, "Inspection offers same faulty-RAM diagnostic")
	ui.exit_inspection()
	ui.get_node("%BenchTabs").current_tab = 3
	await frames()
	await click(ui.find_child("TestPower", true, false))
	check(not model.item(pc_id).power and ram.disabled and "Ligue" in ram.tooltip_text, "Power-off explains why RAM test is unavailable")
	ui.get_node("%BenchTabs").current_tab = 1
	await frames()
	await click(ui.find_child("StartDiagnostic", true, false))
	check(model.item(pc_id).power and model.item(pc_id).boot_remaining > 0, "Diagnostic tab also runs real POST")
	var pc: Dictionary = model.item(pc_id)
	model.item(installed).health = 96
	model.item(installed).defects.clear()
	var gpu: Dictionary = model.item(pc.components.gpu)
	gpu.health = 8
	model.tick(1.3)
	ui.get_node("%BenchTabs").current_tab = 3
	await frames()
	check(screen.status == "no_signal" and station.status == "no_signal" and not pc.boot_ok, "Dead GPU keeps the monitor dark")
	gpu.health = 45
	model.request_post(pc_id)
	await frames()
	check(screen.status == "sync", "Monitor waits for the graphics signal when starting")
	model.tick(1.3)
	await frames()
	check(screen.status == "artifacts" and station.status == "artifacts" and not pc.boot_ok, "Faulty GPU renders artifacts and fails POST")
	await capture("artifacts")
	await click(video)
	model.tick(2.0)
	await frames()
	check(gpu.tested and "Artefatos" in gpu.test_result, "Video test records observed artifacts")
	gpu.health = 96
	model.request_post(pc_id)
	model.tick(1.3)
	await frames()
	check(screen.status == "desktop" and station.status == "desktop" and pc.boot_ok, "Healthy components restore the client's display")
	await click(video)
	check(screen.status == "pattern" and station.status == "pattern", "Video test displays a color pattern on both screens")
	await capture("video-pattern")
	model.tick(2.0)
	await frames()
	check(screen.status == "desktop" and "estável" in gpu.test_result, "Completing test restores the desktop and saves a stable result")
	ui.open_inspection()
	await frames()
	var access: Button = ui.inspection.find_child("AccessClientOS", true, false)
	var client_screen: Control = ui.inspection.find_child("ClientDisplay", true, false)
	var client_desktop: Control = ui.inspection.find_child("ClientTechOS", true, false)
	check(access.get_index() == ui.inspection.find_child("BenchPower", true, false).get_index() + 1, "Client OS button sits next to the power button")
	await click(access)
	check(client_desktop.is_visible_in_tree() and client_screen.status == "desktop", "Client viewer opens the actual TechOS desktop")
	check(client_desktop.launchers.keys() == ["browser", "explorer", "store"] and client_desktop.open_app("shop") == null, "The client desktop contains only personal apps")
	await click(client_desktop.launchers.browser)
	check(client_desktop.windows.browser.find_child("BrowserAddress", true, false).text == "tech://inicio", "Mouse opens the local browser")
	await click(client_desktop.windows.browser.get_node("%CloseApp"))
	await click(client_desktop.launchers.explorer)
	check(client_desktop.windows.explorer.find_child("ExplorerFiles", true, false).item_count > 0, "Explorer lists client documents")
	await click(client_desktop.windows.explorer.get_node("%CloseApp"))
	await click(client_desktop.launchers.store)
	await click(client_desktop.windows.store.find_child("Install_notes", true, false))
	check("notes" in pc.get("client_apps", []) and client_desktop.launchers.has("notes") and model.valid(model.state), "Store installs an application only on the current PC")
	await click(client_desktop.windows.store.find_child("Install_notes", true, false))
	check(client_desktop.windows.has("notes"), "A newly installed application can be opened from the Store")
	await click(client_desktop.windows.notes.get_node("%MinimizeApp"))
	check(not client_desktop.windows.notes.visible, "Client application can be minimized with the mouse")
	await capture("client-techos")
	gpu.health = 45
	await frames()
	check(client_screen.status == "artifacts" and client_desktop.is_visible_in_tree(), "Artifacts overlay the interactive client desktop")
	await capture("client-os")
	gpu.health = 8
	await frames()
	check(client_screen.status == "no_signal" and not client_desktop.is_visible_in_tree(), "Client viewer stays open with a dark screen when the signal drops")
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	Input.parse_input_event(escape)
	await frames()
	check(ui.inspection.visible and not client_screen.is_visible_in_tree() and pc.power, "Escape returns to inspection without powering off")
	await click(ui.inspection.find_child("BenchPower", true, false))
	check(access.disabled, "The client viewer requires the PC to be powered on")
	ui.close_bench()
	model.item(pc_id).power = false
	model.item(pc_id).boot_remaining = 0.0
	model.move(pc_id, "carried")
	ui.open_bench()
	ui.get_node("%BenchTabs").current_tab = 3
	await frames()
	check(ui.find_child("RunRAMTest", true, false).disabled and "8%" not in ui.get_node("%BenchTabs").get_tab_control(3).get_node("Content/EmptyTests/Content/Description").text, "Removing PC clears old results from empty bench")
	check(screen.status == "off" and station.status == "off" and video.disabled, "Removing equipment clears both displays")
	ui.close_bench()
	print("BENCH TEST ACCESS CHECKS: ", checks, "; failures: ", failures.size())
	world.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)

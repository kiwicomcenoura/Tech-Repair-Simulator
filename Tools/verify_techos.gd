extends SceneTree
## Real GUI events for desktop navigation, window dragging, focus and power.

var checks := 0
var failures: Array[String] = []


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)


func frames(count: int = 3) -> void:
	for i in range(count): await process_frame


func key(code: Key, ctrl: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.ctrl_pressed = ctrl
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()


func mouse_button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames()


func motion(point: Vector2, dragging: bool = false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if dragging else 0
	Input.parse_input_event(event)
	await frames()


func click(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	await motion(point)
	await mouse_button(point, true)
	await mouse_button(point, false)


func drag(window: Control, target: Vector2) -> void:
	var title: Control = window.get_node("%TitleBar")
	var start := title.get_global_transform_with_canvas() * (title.size * 0.5)
	await motion(start)
	await mouse_button(start, true)
	await motion(target, true)
	await mouse_button(target, false)


func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(not image.is_empty(), "Rendered TechOS: " + name)
		image.save_png("res://.godot/techos-" + name + ".png")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1360, 768)
	var world: Node2D = preload("res://Tools/test_world.gd").create()
	root.add_child(world)
	await frames(4)
	var player: CharacterBody2D = world.get_node("Actors/Player")
	var model: Node = world.get_node("Actors/WorkComputer/PersonalComputer")
	var ui: CanvasLayer = world.get_node("PersonalComputerUI")
	var os: Control = ui.get_node("%DesktopScreen")
	var dock: Node2D = world.get_node("Actors/RepairBench/EquipmentDock")
	model.boot_duration = 0.2
	player.global_position = world.get_node("Actors/WorkComputer").global_position + Vector2(0, 35)
	await physics_frame
	await frames()
	await key(KEY_F)
	check(ui.is_open and paused, "Existing F interaction preserved")
	await click(ui.get_node("%PowerToggle"))
	await create_timer(0.35, true).timeout
	await frames()
	check(model.power_state == 2 and os.running and os.is_visible_in_tree(), "Boot enters TechOS")
	check(os.launchers.size() == 6 and os.menu_launchers.size() == 6, "Six desktop and Start shortcuts")
	check(os.windows.is_empty(), "Desktop starts without forced apps")
	check(not dock.has_equipment(), "OS does not populate repair bench")
	await capture("desktop")
	await click(os.get_node("%StartButton"))
	check(os.get_node("%StartMenu").visible, "Start menu opens")
	var menu: Control = os.get_node("%StartMenu")
	check(os.get_global_rect().encloses(menu.get_global_rect()), "Start menu inside desktop bounds")
	await create_timer(0.15, true).timeout
	await capture("start")
	await click(os.menu_launchers.messages)
	check(os.windows.has("messages"), "Start menu opens application")
	check(not menu.visible, "Launching app closes Start menu")
	var messages: Control = os.windows.messages
	check(messages.get_node("%EmptyTitle").text == "Nenhuma conversa", "Honest empty app state")
	var original_id := messages.get_instance_id()
	await click(os.launchers.messages)
	check(os.windows.size() == 1 and os.windows.messages.get_instance_id() == original_id, "Repeated launch focuses one instance")
	await click(os.launchers.clients)
	check(os.active_app == "clients" and os.windows.size() == 2, "Second app becomes active")
	check(os.get_node("%WindowsArea").get_child(-1) == os.windows.clients, "Active window drawn on top")
	var strip := messages.get_global_transform_with_canvas() * Vector2(15, 20)
	await mouse_button(strip, true)
	await mouse_button(strip, false)
	check(os.active_app == "messages", "Clicking exposed window brings it forward")
	os.windows.messages.position = Vector2(8, 65)
	os.windows.clients.position = Vector2(660, 110)
	os.windows.clients.clamp_position()
	os.open_app("clients")
	await create_timer(0.16, true).timeout
	await capture("apps")
	await key(KEY_TAB, true)
	check(os.active_app == "messages", "Ctrl+Tab cycles apps")
	await click(os.task_buttons.clients)
	check(os.active_app == "clients", "Taskbar switches apps")
	await click(os.task_buttons.clients)
	check(not os.windows.clients.visible and os.active_app == "messages", "Active task button minimizes")
	await click(os.task_buttons.clients)
	check(os.windows.clients.visible and os.active_app == "clients", "Taskbar restores minimized app")
	await click(os.windows.clients.get_node("%MinimizeApp"))
	check(not os.windows.clients.visible, "Window minimize button")
	await click(os.task_buttons.clients)
	await click(os.windows.clients.get_node("%CloseApp"))
	check(not os.windows.has("clients") and not os.task_buttons.has("clients"), "Close removes window and task entry")
	var before := messages.position
	var title: Control = messages.get_node("%TitleBar")
	var start := title.get_global_transform_with_canvas() * (title.size * 0.5)
	await drag(messages, start + Vector2(80, 50))
	check(messages.position.distance_to(before) > 20, "Real title-bar drag moves window")
	await drag(messages, Vector2(-1000, -1000))
	check(messages.position.is_equal_approx(Vector2.ZERO), "Drag clamps left and top edges")
	await drag(messages, Vector2(4000, 3000))
	var area: Control = os.get_node("%WindowsArea")
	check(messages.position.x + messages.size.x <= area.size.x + 1 and messages.position.y + messages.size.y <= area.size.y + 1, "Drag clamps right and bottom above taskbar")
	var released_at := messages.position
	await motion(Vector2(20, 20))
	check(messages.position == released_at, "Release stops dragging outside window")
	for id in os.APPS:
		os.open_app(id)
	await frames()
	check(os.windows.size() == 6 and os.task_buttons.size() == 6, "All six apps can coexist")
	for id in os.windows:
		var window: Control = os.windows[id]
		check(Rect2(Vector2.ZERO, area.size).encloses(Rect2(window.position, window.size)), "Window stays in work area: " + id)
		check(not window.get_node("%EmptyDescription").text.is_empty(), "App has explicit empty state: " + id)
	for button_name in ["StartButton", "TaskPower", "DesktopExit"]:
		var button: Control = os.get_node("%" + button_name)
		check(os.get_global_rect().encloses(button.get_global_rect()), "Taskbar control visible: " + button_name)
	await create_timer(0.18, true).timeout
	await capture("windows")
	os.simulated_minutes = 1439.999
	await create_timer(0.05, true).timeout
	check(os.get_node("%ClockText").text == "00:00" and "02" in os.get_node("%ClockDay").text, "Fictional clock rolls into next game day")
	await click(os.get_node("%StartButton"))
	await key(KEY_ESCAPE)
	check(not menu.visible and ui.is_open, "ESC dismisses Start menu first")
	await click(os.get_node("%DesktopExit"))
	check(not ui.is_open and not paused and model.power_state == 2, "Return to game leaves PC on")
	ui.open_computer()
	await frames()
	check(os.windows.size() == 6, "Returning to powered desktop keeps windows")
	await click(os.get_node("%TaskPower"))
	check(model.power_state == 0 and not ui.is_open and not paused, "Shutdown closes interface and restores character control")
	check(os.windows.is_empty() and os.task_buttons.is_empty(), "Shutdown closes all apps")
	var stopped_at := player.global_position
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	await frames()
	Input.action_release("move_right")
	check(player.global_position.x > stopped_at.x, "Character moves after shutdown")
	ui.open_computer()
	await frames()
	await click(ui.get_node("%PowerToggle"))
	await create_timer(0.35, true).timeout
	await click(os.get_node("%StartButton"))
	await click(os.get_node("%MenuPower"))
	check(model.power_state == 0 and not ui.is_open and not paused, "Start-menu shutdown also returns control")
	check(not dock.has_equipment(), "Repair bench still empty after OS navigation")
	print("TECHOS CHECKS: ", checks, "; failures: ", failures.size())
	world.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)

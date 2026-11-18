extends SceneTree
## Exercises real GUI hit testing, tool selection, cover rules and persistence.

var checks := 0
var failures: Array[String] = []
var canvas: Control
var ui: CanvasLayer
var view: Control


func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures.append(text)
		push_error(text)


func frames(count: int = 2) -> void:
	for i in range(count):
		await process_frame


func move_mouse(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	Input.parse_input_event(event)
	await frames()


func click(point: Vector2) -> void:
	await move_mouse(point)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()


func art_click(point: Vector2) -> void:
	await click(canvas.get_global_transform_with_canvas() * canvas.art_to_local(point))


func button_click(button: Control) -> void:
	await click(button.get_global_transform_with_canvas() * (button.size * 0.5))


func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()


func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(not image.is_empty(), "Rendered screenshot: " + name)
		image.save_png("res://.godot/desktop-inspection-" + name + ".png")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1360, 768)
	var world: Node2D = preload("res://Tools/test_world.gd").create()
	root.add_child(world)
	await frames(4)
	ui = world.get_node("MaintenanceBenchUI")
	view = ui.inspection
	canvas = view.get_node("%DesktopCanvas")
	# Never generate a fake computer to exercise the old demonstration.
	# Positive visual interactions require a genuine placed item; startup is empty.
	if not ui.has_equipment():
		ui.open_bench()
		await frames(3)
		check(ui.inspection_session == null, "No default inspection session")
		check(not ui.open_inspection(), "Empty bench rejects inspection API")
		check(not view.visible and not canvas.visible, "No cabinet or screws drawn without equipment")
		check(ui.find_child("Inspect", true, false).disabled, "Inspect disabled without equipment")
		check(ui.equipment_dock.get_equipment_item() == null, "No physical equipment generated")
		ui.close_bench()
		print("EMPTY INSPECTION GUARDS: ", checks, "; failures: ", failures.size())
		print("Positive inspection interactions skipped: no real equipment has been placed. No test computer was created.")
		world.queue_free()
		await frames()
		quit(0 if failures.is_empty() else 1)
		return
	var session: RefCounted = ui.inspection_session
	ui.open_bench()
	await frames(3)
	await button_click(ui.find_child("Inspect", true, false))
	check(view.visible and paused, "Inspect button opens enlarged case and keeps workshop paused")
	check(session.lid_attached and session.installed_count() == 4, "Initial cover and four screws")
	check(canvas.hit_at(Vector2(104, 80)) == &"lid", "Closed cover blocks access to internal components")
	for id in ["ReturnToBench", "Phillips", "Hands", "LidAction"]:
		var button: Control = view.get_node("%" + id)
		var r := button.get_global_rect()
		check(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 1361 and r.end.y <= 769, "Visible and uncut button: " + id)
	await art_click(Vector2(119, 109))
	check(session.lid_attached, "Cover cannot be removed while screwed in")
	check("presa" in view.get_node("%ContextMessage").text, "Clear message for locked cover")
	await art_click(Vector2(34, 30))
	check(session.screws[0], "Cannot remove screw without Phillips")
	check("Phillips" in view.get_node("%ContextMessage").text, "Missing-tool feedback")
	await button_click(view.get_node("%Phillips"))
	check(session.tool == &"phillips", "Select Phillips through GUI")
	for i in range(4):
		await art_click(canvas.SCREWS[i])
		check(not session.screws[i], "Direct visual screw removal: " + str(i))
		check(session.installed_count() == 3 - i, "Correct screw count")
		check(session.selected == StringName("screw_" + str(i)), "Selected screw highlighted")
		if i == 0:
			await capture("closed")
		if i == 2:
			await art_click(Vector2(119, 109))
			check(session.lid_attached, "Three removed screws do not release cover")
	await art_click(Vector2(119, 109))
	check(not session.lid_attached, "All four screws allow visual cover removal")
	check(not session.use_screw(0) and session.installed_count() == 0, "Cannot fix a screw without the cover")
	var targets := [
		[&"cpu", Vector2(104, 80)], [&"ram", Vector2(156, 75)],
		[&"gpu", Vector2(100, 134)], [&"psu", Vector2(80, 175)],
		[&"ssd", Vector2(225, 123)], [&"storage", Vector2(225, 60)],
		[&"cables", Vector2(197, 96)], [&"motherboard", Vector2(58, 85)],
	]
	for item in targets:
		await move_mouse(canvas.get_global_transform_with_canvas() * canvas.art_to_local(item[1]))
		check(canvas.hovered == item[0], "Component hover: " + str(item[0]))
		check(view.get_node("%HoverName").text == canvas.part_name(item[0]), "Component name: " + str(item[0]))
		await art_click(item[1])
		check(session.selected == item[0], "Component selection: " + str(item[0]))
	await art_click(Vector2(100, 134))
	await capture("open")
	await button_click(view.get_node("%ReturnToBench"))
	check(not view.visible and ui.is_open and paused, "Return keeps bench open and workshop paused")
	await button_click(ui.find_child("Inspect", true, false))
	check(not session.lid_attached and session.installed_count() == 0, "State survives view close/reopen")
	await escape()
	check(not view.visible and ui.is_open, "ESC exits inspection first")
	await button_click(ui.find_child("Inspect", true, false))
	await button_click(ui.get_node("%CloseButton"))
	check(not ui.is_open and not paused, "X closes bench while inspecting")
	ui.open_bench()
	await frames(3)
	await button_click(ui.find_child("Inspect", true, false))
	check(not session.lid_attached and session.installed_count() == 0, "State survives entire bench close/reopen")
	await art_click(Vector2(305, 90))
	check(session.lid_attached and session.installed_count() == 0, "Click parked lid to replace without inventing fixed screws")
	for i in range(4):
		await art_click(canvas.SCREWS[i])
		check(session.screws[i], "Refasten screw with Phillips: " + str(i))
	check(session.installed_count() == 4, "All screws refastened")
	await button_click(view.get_node("%LidAction"))
	check(session.lid_attached, "Refastened cover cannot be removed")
	await button_click(view.get_node("%Hands"))
	await art_click(Vector2(34, 30))
	check(session.screws[0], "Switching back to hands blocks screw operation")
	check(not session.use_screw(-1) and not session.use_screw(4), "Invalid screw indices rejected")
	ui.close_bench()
	check(not paused, "Workshop restored after inspection")
	print("DESKTOP INSPECTION CHECKS: ", checks, "; failures: ", failures.size())
	world.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)

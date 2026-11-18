extends SceneTree
## Intentionally creates no EquipmentData instance, equipment item or test PC.

var checks := 0
var failures: Array[String] = []


func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error(description)


func frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame


func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(not image.is_empty(), "Rendered capture: " + name)
		image.save_png("res://.godot/bench-personal-" + name + ".png")


func count_equipment(node: Node) -> int:
	var item_script := preload("res://Scripts/Equipment/equipment_item.gd")
	var result := 1 if node.get_script() == item_script else 0
	for child in node.get_children():
		result += count_equipment(child)
	return result


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1360, 768)
	var world: Node2D = preload("res://Tools/test_world.gd").create()
	root.add_child(world)
	await frames(4)
	var dock: Node2D = world.get_node("Actors/RepairBench/EquipmentDock")
	var bench_ui: CanvasLayer = world.get_node("MaintenanceBenchUI")
	var personal: Node = world.get_node("Actors/WorkComputer/PersonalComputer")
	var personal_ui: CanvasLayer = world.get_node("PersonalComputerUI")
	var desk: Node2D = world.get_node("Actors/WorkComputer")
	var player: Node2D = world.get_node("Actors/Player")
	check(not dock.has_equipment(), "Bench starts empty")
	check(dock.get_equipment() == null and dock.get_equipment_item() == null, "No default data or physical item")
	check(dock.slot.get_child_count() == 0, "Physical slot has no spawned item")
	check(count_equipment(world) == 0, "No equipment items were generated anywhere")
	check(bench_ui.inspection_session == null, "No default screw/cover session")
	check(not dock.place_equipment(null), "Null placement rejected")
	var desk_position := desk.global_position
	check(not dock.place_equipment(desk), "Fixed personal desk cannot become a repair item")
	check(desk.global_position == desk_position and desk.get_parent() == world.get_node("Actors"), "Rejected placement never moves desk")
	check(dock.remove_equipment(world, Vector2.ZERO) == null, "Empty removal returns nothing")
	check(not dock.has_equipment(), "Rejected operations leave bench empty")
	# Inspect resource schema without creating a fictitious equipment resource.
	var properties: Array[String] = []
	var schema: Script = load("res://Scripts/Equipment/equipment_data.gd")
	for property in schema.get_script_property_list():
		properties.append(property.name)
	for field in ["equipment_id", "equipment_type", "owner_id", "owner_name", "components", "condition", "maintenance_state"]:
		check(field in properties, "Reusable equipment schema: " + field)
	bench_ui.open_bench()
	await frames()
	var equipment := bench_ui.get_node("Overlay/SafeMargins/WorkbenchWindow/Layout/Body/EquipmentPanel/Content")
	check(equipment.get_node("EquipmentName").text == "Nenhum equipamento na bancada", "Correct empty message")
	check(not equipment.get_node("EquipmentIllustration").visible, "No cabinet illustration in empty equipment panel")
	var overview: Node = bench_ui.get_node("%BenchTabs").get_tab_control(0).get_node("Content")
	check(not overview.get_node("EquipmentPreview/Content/Blueprint").visible, "No default PC preview")
	for name in ["Inspect", "StartDiagnostic", "Replace", "Finish"]:
		check(bench_ui.find_child(name, true, false).disabled, "Disabled empty action: " + name)
	check(not bench_ui.open_inspection(), "Direct inspection API rejects empty bench")
	bench_ui.find_child("Inspect", true, false).pressed.emit()
	check(not bench_ui.inspection.visible, "Bypassing disabled button cannot open inspection")
	check(not bench_ui.inspection.get_node("%DesktopCanvas").visible, "No screws/components drawn while empty")
	for code in ["CPU", "GPU", "RAM", "MB", "SSD", "PSU", "FAN"]:
		check(bench_ui.get_node("%BenchTabs").get_tab_control(2).get_node("Content/ComponentSlots/Slot" + code + "/Row/Labels/Empty").text == "Slot vazio", "No invented component: " + code)
	await capture("empty")
	bench_ui.close_bench()
	check(not paused, "Closing empty bench restores game")
	check(personal.power_state == 0, "Personal computer starts off")
	personal_ui.open_computer()
	await frames()
	check(personal_ui.is_open and paused and personal_ui.get_node("%OffScreen").visible, "Separate personal off screen")
	check(not bench_ui.is_open, "Personal screen does not open maintenance UI")
	bench_ui.open_bench()
	check(not bench_ui.is_open, "Modals cannot overlap")
	check(personal_ui.get_node("%PowerToggle").text == "Ligar computador", "Power-on button")
	for name in ["PowerToggle", "PersonalClose"]:
		var bounds: Rect2 = personal_ui.get_node("%" + name).get_global_rect()
		check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= 1361 and bounds.end.y <= 769, "Personal button fits 1360x768: " + name)
	await capture("off")
	personal_ui.get_node("%PowerToggle").pressed.emit()
	await create_timer(0.35, true).timeout
	check(personal.power_state == 1, "Power button starts boot")
	check(personal_ui.get_node("%BootScreen").visible, "Boot screen shown")
	check(personal.boot_progress() > 0 and personal.boot_progress() < 1, "Startup progress advances while paused")
	check(personal_ui.get_node("%PowerToggle").text == "Desligar computador", "Power-off available during boot")
	await capture("boot")
	personal_ui.get_node("%PowerToggle").pressed.emit()
	check(personal.power_state == 0 and personal.boot_progress() == 0, "Cancel boot by switching off")
	personal.toggle_power()
	personal_ui.close_computer()
	await create_timer(personal.boot_duration + 0.15, true).timeout
	check(personal.power_state == 2, "Boot completes with screen closed")
	personal_ui.open_computer()
	await frames()
	check(personal_ui.get_node("%DesktopScreen").visible, "Reopen powered computer at desktop")
	var desktop: Control = personal_ui.get_node("%DesktopScreen")
	check(desktop.launchers.size() == 6, "Six TechOS application shortcuts")
	check(desktop.windows.is_empty(), "No fake application content created at startup")
	for app in desktop.launchers.values():
		check(not app.disabled, "App shell can open: " + str(app.name))
		var bounds: Rect2 = app.get_global_rect()
		check(bounds.end.x <= 1361 and bounds.end.y <= 769, "Reserved app fits screen: " + str(app.name))
	var stop_at := player.global_position
	Input.action_press("move_right")
	await frames(4)
	Input.action_release("move_right")
	check(player.global_position == stop_at, "Movement blocked while personal interface is open")
	check(not dock.has_equipment() and bench_ui.inspection_session == null, "Powering personal computer never populates repair bench")
	await capture("desktop")
	personal_ui.get_node("%PowerToggle").pressed.emit()
	check(personal.power_state == 0 and personal_ui.get_node("%OffScreen").visible, "Switch off from desktop")
	check(not personal_ui.is_open and not paused, "Shutdown closes interface and returns character control")
	for child in desk.get_node("Details").get_children():
		if str(child.name).begins_with("ScreenText"):
			check(not child.visible, "World monitor goes dark")
	personal_ui.close_computer()
	check(not paused and not personal_ui.is_open, "Personal close restores workshop")
	print("EQUIPMENT / PERSONAL CHECKS: ", checks, "; failures: ", failures.size())
	world.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)

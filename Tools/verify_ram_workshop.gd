extends SceneTree
## Complete playable slice using the actual receiving content and real inputs.
## Save files are isolated under .godot; never touches the player's user:// save.

var checks := 0
var failures: Array[String] = []
var world: Node2D
var workshop: Node
var ui: CanvasLayer
var view: Control
var canvas: Control
var player: CharacterBody2D


func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error(description)


func frames(count: int = 3) -> void:
	for i in range(count): await process_frame


func key(code: Key, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.shift_pressed = shift
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	await frames()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()


func stand(point: Vector2) -> void:
	player.global_position = point
	await physics_frame
	await frames()


func click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await frames()
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


func click(control: Control) -> void:
	await click_at(control.get_global_transform_with_canvas() * (control.size * 0.5))


func art(point: Vector2) -> void:
	await click_at(canvas.get_global_transform_with_canvas() * canvas.art_to_local(point))


func open_inspection() -> void:
	await stand(Vector2(130, -90))
	await key(KEY_F)
	check(ui.is_open, "F opens bench after physical placement")
	await click(ui.find_child("Inspect", true, false))
	check(view.visible, "Inspect shows the actual placed equipment")


func choose_ram(id: String) -> void:
	var inventory: OptionButton = view.find_child("RAMInventory", true, false)
	var index: int = view._inventory_ids.find(id)
	check(index >= 0, "Physical RAM available in inventory: " + id.substr(0, 8))
	if index >= 0:
		inventory.select(index)
		inventory.item_selected.emit(index)
	await frames()


func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(not image.is_empty(), "Rendered gameplay: " + name)
		image.save_png("res://.godot/playable-" + name + ".png")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1360, 768)
	world = preload("res://Tools/test_world.gd").create(true)
	root.add_child(world)
	await frames(5)
	workshop = world.get_node("PhysicalWorkshop")
	workshop.save_path = "res://.godot/ram_loop_test_" + str(OS.get_process_id()) + ".json"
	player = world.get_node("Actors/Player")
	ui = world.get_node("MaintenanceBenchUI")
	view = ui.inspection
	canvas = view.get_node("%DesktopCanvas")
	var model: RefCounted = workshop.ledger
	var pc_id: String = model.at("floor")[0]
	var spare_id := ""
	for r in model.state.items.values():
		if r.kind == "ram" and r.packaged: spare_id = r.id
	var old_id: String = model.item(pc_id).components.ram
	check(model.valid(model.state), "Initial registry consistent")
	check(model.state.items.size() == 9, "One received PC, seven installed units and one boxed spare")
	check(not workshop.dock.has_equipment(), "Bench remains physically empty before placement")
	check(not model.item(old_id).tested and "desconhecida" in model.known_description(old_id), "Faulty RAM health is not revealed automatically")
	var labels := {0: "Quebrado", 14: "Quebrado", 15: "Ruim", 44: "Ruim", 45: "Mediano", 69: "Mediano", 70: "Bom", 89: "Bom", 90: "Perfeito estado", 100: "Perfeito estado"}
	for health in labels:
		check(preload("res://Scripts/Gameplay/workshop_ledger.gd").condition_label(health) == labels[health], "Health boundary category: " + str(health))
	await capture("receiving")
	await stand(Vector2(-210, 50))
	check(world.get_node("WorkshopMarkers/Toolbox").visible, "Toolbox is visible before first opening")
	await key(KEY_F)
	check(model.state.tools, "F opens physical tool box")
	check(not world.get_node("WorkshopMarkers/Toolbox").visible and not workshop._near_tools(), "Opened toolbox disappears and stops offering interaction")
	await stand(Vector2(230, 130))
	await key(KEY_E)
	check(model.carried() == pc_id, "E picks up the received cabinet")
	check(workshop.actors[pc_id].global_position.distance_to(player.global_position) < 40, "Carried cabinet has a visible world actor")
	check(not model.move(spare_id, "carried"), "Only one unit can be carried")
	await stand(Vector2(80, 20))
	await key(KEY_E)
	check(model.item(pc_id).location == "floor" and model.carried() == "", "E drops same cabinet onto free floor")
	await key(KEY_E)
	check(model.carried() == pc_id, "Same cabinet can be picked up again")
	await stand(Vector2(130, -90))
	await key(KEY_E)
	check(model.bench_id() == pc_id and workshop.dock.has_equipment(), "E physically places cabinet into existing dock")
	check(workshop.dock.get_equipment().equipment_id == pc_id, "Inspection and physical actor share one equipment ID")
	check(workshop.actors[pc_id].z_index > 0, "Placed cabinet renders above bench surface")
	await capture("placed")
	var existing: Node2D = workshop.actors[pc_id]
	check(workshop.dock.remove_equipment(world.get_node("Actors"), Vector2(80, 40)) == existing and model.item(pc_id).location == "floor", "Existing dock removal API updates authoritative location")
	existing.global_position = workshop.dock.slot.global_position
	check(workshop.dock.place_equipment(existing) and model.bench_id() == pc_id, "Existing dock placement API does not create a second ownership source")
	await open_inspection()
	var power: Button = view.find_child("BenchPower", true, false)
	var ram_test: Button = view.find_child("MemoryTest", true, false)
	await click(power)
	await create_timer(1.3, true).timeout
	check(model.item(pc_id).power and not model.item(pc_id).boot_ok, "Original defective RAM produces a POST failure")
	check("ram" in model.item(pc_id).boot_result, "Boot symptom derives from installed RAM")
	var screws_before: Array = model.item(pc_id).screws.duplicate()
	await art(Vector2(34, 30))
	check(model.item(pc_id).screws == screws_before, "Cannot unscrew a powered machine")
	await click(power)
	await click(view.get_node("%Phillips"))
	for point in canvas.SCREWS: await art(point)
	check(model.item(pc_id).screws.count(true) == 0, "Four physical screws removed with Phillips")
	await art(Vector2(119, 109))
	check(not model.item(pc_id).lid, "Side cover is removed after four screws")
	await click(view.get_node("%Hands"))
	await art(Vector2(149, 74))
	check(model.item(pc_id).components.ram == old_id, "Closed RAM latches prevent removal")
	for point in canvas.LATCHES: await art(point)
	check(model.item(pc_id).latches == [false, false], "Both clickable latches opened")
	await art(Vector2(149, 74))
	check(not model.item(pc_id).components.has("ram") and model.item(old_id).location == "tray", "RAM removed to a physical tray, not deleted")
	check(workshop.actors.has(old_id), "Removed RAM now has a world representation")
	await click(power)
	await create_timer(1.3, true).timeout
	check(not model.item(pc_id).boot_ok and "ausente" in model.item(pc_id).boot_result, "Missing RAM is detected during POST")
	await click(power)
	ui.close_bench()
	var tray_point: Vector2 = workshop.actors[old_id].global_position
	tray_point.y = -125.0 - absf(tray_point.x - 130.0) * 0.5 + 20.0
	await stand(tray_point)
	await key(KEY_E)
	check(model.carried() == old_id, "Removed RAM can be physically picked up from outside the bench collision")
	await stand(Vector2(-60, 40))
	await key(KEY_E)
	check(model.item(old_id).location == "floor" and model.item(old_id).id == old_id, "Removed original RAM can be carried away and dropped without losing identity")
	await stand(Vector2(285, 80))
	await key(KEY_F)
	check(model.carried() == "", "F never picks up a floor item")
	await key(KEY_E)
	check(not model.item(spare_id).packaged and model.item(spare_id).location == "floor", "E unpacks delivery without auto-installing")
	await key(KEY_E)
	check(model.carried() == spare_id, "E picks up replacement RAM")
	await stand(Vector2(-250, -5))
	await key(KEY_F)
	check(workshop.storage_ui.is_open, "F opens modern shelf interface")
	for button in workshop.storage_ui.find_children("*", "Button", true, false):
		if button.text == "Guardar peça das mãos":
			await click(button)
			break
	await click(workshop.storage_ui.find_child("Transfer_" + spare_id, true, false))
	check(model.item(spare_id).location == "shelf" and model.carried() == "", "Physical shelf storage integrated with item registry")
	await capture("shelf")
	await click(workshop.storage_ui.find_child("Transfer_" + spare_id, true, false))
	check(model.item(spare_id).location == "inventory", "Shelf returns the same unit to inventory")
	await click(workshop.storage_ui.find_child("Transfer_" + spare_id, true, false))
	check(model.item(spare_id).location == "shelf", "Same unit can be stored again without duplication")
	check(spare_id not in model.available_ram(), "Shelf stock cannot teleport directly into the computer")
	await click(workshop.storage_ui.find_child("Transfer_" + spare_id, true, false))
	workshop.storage_ui.close_storage()
	await key(KEY_I)
	await click(workshop.storage_ui.find_child("Transfer_" + spare_id, true, false))
	workshop.storage_ui.close_storage()
	await stand(Vector2(130, -90))
	await key(KEY_E)
	check(model.item(spare_id).location == "tray" and model.carried() == "", "Replacement is physically carried from shelf to bench tray")
	await open_inspection()
	await choose_ram(spare_id)
	check(not model.item(pc_id).components.has("ram"), "Selecting inventory RAM alone does not install it")
	await art(Vector2(149, 74))
	check(model.item(pc_id).components.ram == spare_id and model.item(spare_id).location == "installed", "Clicking slot manually installs selected DDR4")
	check(not workshop.actors.has(spare_id), "Installed unit is not also duplicated on shelf")
	await click(power)
	await create_timer(1.3, true).timeout
	check(not model.item(pc_id).boot_ok and "travas" in model.item(pc_id).boot_result, "Incomplete latch installation fails POST")
	await click(power)
	for point in canvas.LATCHES: await art(point)
	await click(power)
	await create_timer(1.3, true).timeout
	check(model.item(pc_id).boot_ok, "Compatible RAM and closed latches boot successfully")
	await click(ram_test)
	check(model.item(spare_id).tested and "96%" in model.known_description(spare_id), "Successful memory test discovers actual health")
	check(not model.item(old_id).tested, "Other untested unit's health remains hidden")
	for control in [power, ram_test, view.get_node("%ReturnToBench"), view.find_child("RAMInventory", true, false), view.get_node("%LidAction")]:
		var bounds: Rect2 = control.get_global_rect()
		check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= 1361 and bounds.end.y <= 769, "Inspection control fits 1360x768: " + str(control.name))
	await capture("ram-tested")
	await key(KEY_F5)
	check(FileAccess.file_exists(workshop.save_path), "F5 writes isolated real save")
	await key(KEY_F9)
	check(not ui.is_open and not paused, "F9 safely closes UI before restoring")
	check(model.item(pc_id).components.ram == spare_id and model.item(pc_id).power, "Save restores installed RAM identity and power")
	check(model.item(pc_id).screws == [false, false, false, false] and not model.item(pc_id).lid, "Save restores screws and cover progress")
	check(model.item(spare_id).tested and model.state.items.size() == 9 and model.valid(model.state), "Restore preserves condition and all units exactly once")
	await stand(Vector2(130, -90))
	check("Desligue o PC" in workshop._prompt(), "Workbench explains that a running PC must be shut down")
	await key(KEY_E)
	check(model.bench_id() == pc_id and model.carried() == "", "E cannot pick up a running bench PC")
	await open_inspection()
	await click(view.find_child("BenchPower", true, false))
	ui.close_bench()
	await key(KEY_E, true)
	check(model.carried() == pc_id and not workshop.dock.has_equipment(), "Shift+E removes real cabinet; bench becomes empty")
	await key(KEY_F5)
	await key(KEY_F9)
	check(model.carried() == pc_id and model.item(pc_id).components.ram == spare_id, "Carried equipment and installed parts survive restore")
	await stand(Vector2(130, -90))
	await key(KEY_E)
	check(model.bench_id() == pc_id, "Same persisted cabinet can be placed again")
	await key(KEY_E)
	check(model.carried() == pc_id and not workshop.dock.has_equipment(), "Plain E picks up an unpowered cabinet from the bench")
	await key(KEY_E)
	# A real TechMarket purchase creates a delivery, not an installed module.
	var personal: Node = world.get_node("Actors/WorkComputer/PersonalComputer")
	personal.boot_duration = 0.2
	var personal_ui: CanvasLayer = world.get_node("PersonalComputerUI")
	personal_ui.open_computer()
	await frames(5)
	await click(personal_ui.get_node("%PowerToggle"))
	await create_timer(0.35, true).timeout
	check(personal.power_state == 2, "Personal PC boots before opening TechMarket")
	var desktop: Control = personal_ui.get_node("%DesktopScreen")
	var shop: Control = desktop.open_app("shop")
	check(shop != null, "TechMarket window opens on powered desktop")
	if shop == null:
		ui.close_bench()
		personal_ui.close_computer()
		print("PLAYABLE RAM LOOP CHECKS: ", checks, "; failures: ", failures.size())
		quit(1)
		return
	await frames(5)
	var shop_area: Control = desktop.get_node("%WindowsArea")
	check(Rect2(Vector2.ZERO, shop_area.size).encloses(Rect2(shop.position, shop.size)), "Functional shop window fits TechOS work area")
	await click(shop.find_child("Buy_DDR5", true, false))
	var confirm: CanvasLayer = shop.find_child("PurchaseConfirmation", true, false)
	check(confirm.visible and model.state.credits == 500, "Buying requires confirmation before debit")
	await click(confirm.get_ok_button())
	check(model.state.credits == 320 and model.at("delivery").size() == 1, "TechMarket debits once and queues physical delivery")
	await create_timer(0.15, true).timeout
	await capture("market")
	var incompatible: String = model.at("delivery")[0]
	check(model.item(pc_id).components.ram == spare_id, "Purchase never auto-installs into PC")
	await create_timer(3.15, true).timeout
	check(model.item(incompatible).location == "floor" and model.item(incompatible).packaged and workshop.actors.has(incompatible), "Timed delivery creates physical receiving box")
	personal_ui.close_computer()
	await stand(Vector2(model.item(incompatible).position[0], model.item(incompatible).position[1]))
	await key(KEY_E)
	await key(KEY_E)
	check(model.carried() == incompatible, "Purchased RAM can be unpacked and carried")
	await stand(Vector2(130, -90))
	await key(KEY_E)
	await open_inspection()
	for point in canvas.LATCHES: await art(point)
	await art(Vector2(149, 74))
	await choose_ram(incompatible)
	await art(Vector2(149, 74))
	check(not model.item(pc_id).components.has("ram") and model.item(incompatible).location == "tray", "DDR5 cannot be installed into DDR4 board; unit remains in tray")
	check("Incompatibilidade" in view.get_node("%ContextMessage").text, "Clear compatibility feedback")
	await choose_ram(spare_id)
	await art(Vector2(149, 74))
	for point in canvas.LATCHES: await art(point)
	check(model.item(pc_id).components.ram == spare_id, "Correct module can still be installed after rejected attempt")
	check(model.valid(model.state), "Every transfer preserves ownership invariants")
	var corrupt: Dictionary = model.state.duplicate(true)
	corrupt.items[spare_id].owner_pc = "missing_pc"
	check(not model.valid(corrupt), "Reject orphaned installed unit in save")
	corrupt = model.state.duplicate(true)
	corrupt.items[spare_id].health = "invalid"
	check(not model.valid(corrupt), "Malformed health rejected without crashing loader")
	corrupt = model.state.duplicate(true)
	corrupt.player = ["invalid", 0]
	check(not model.valid(corrupt), "Malformed player position rejected")
	corrupt = model.state.duplicate(true)
	corrupt.items[spare_id].erase("ddr")
	check(not model.valid(corrupt), "Unknown DDR cannot silently pass compatibility checks")
	check(model.purchase_ram("DDR4") and model.purchase_ram("DDR4"), "Multiple affordable purchases create separate units")
	var count_before: int = model.state.items.size()
	check(not model.purchase_ram("DDR4") and model.state.items.size() == count_before and model.state.credits == 20, "Insufficient funds does not spawn or debit extra unit")
	await key(KEY_F5)
	check(model.valid(model.state), "Final state is serializable and internally consistent")
	check(workshop.save_game(false), "Second save preserves a valid backup")
	var saved_count: int = model.state.items.size()
	var damaged := FileAccess.open(workshop.save_path, FileAccess.WRITE)
	damaged.store_string("{ damaged save")
	damaged.close()
	check(workshop.load_game(), "Corrupt primary save recovers from valid backup")
	check(model.state.items.size() == saved_count and model.item(pc_id).components.ram == spare_id, "Recovery retains every physical unit and installed identity")
	check(workshop.save_game(false) and FileAccess.file_exists(workshop.save_path + ".corrupt"), "Saving after recovery preserves corrupt file and valid backup")
	await frames()
	workshop.settings_ui.open_menu()
	await frames()
	await click(workshop.settings_ui.find_child("SaveProgress", true, false))
	check("salvo" in workshop.last_message, "Clickable Save button works without keyboard shortcut")
	await click(workshop.settings_ui.find_child("RestoreProgress", true, false))
	check(model.item(pc_id).components.ram == spare_id and model.valid(model.state), "Clickable Restore button preserves installed units")
	ui.close_bench()
	var reload_path: String = workshop.save_path
	var reload_count: int = model.state.items.size()
	world.queue_free()
	await frames()
	world = preload("res://Tools/test_world.gd").create(true, reload_path)
	root.add_child(world)
	await frames(5)
	var restarted: Node = world.get_node("PhysicalWorkshop")
	check(restarted.ledger.state.tools and not world.get_node("WorkshopMarkers/Toolbox").visible, "Opened toolbox stays hidden when a fresh scene loads the same save")
	check(restarted.ledger.state.items.size() == reload_count and restarted.ledger.item(pc_id).components.ram == spare_id, "A fresh scene resumes same IDs without issuing another starter kit")
	check(restarted.dock.has_equipment() and restarted.dock.get_equipment().equipment_id == pc_id, "Fresh scene reconstructs actual physical bench association")
	print("PLAYABLE RAM LOOP CHECKS: ", checks, "; failures: ", failures.size())
	world.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)

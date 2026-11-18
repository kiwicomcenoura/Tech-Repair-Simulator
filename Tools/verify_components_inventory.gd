extends SceneTree
var checks := 0
var failures: Array[String] = []
var world: Node
var workshop: Node
var ui: Node
var canvas: Control
var model: RefCounted
var pc_id := ""

func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures.append(text)
		push_error(text)

func frames(n: int = 3) -> void:
	for i in range(n): await process_frame

func click(control: Control) -> void:
	await click_at(control.get_global_transform_with_canvas() * (control.size * 0.5))

func key(code: Key) -> void:
	for down in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await frames()

func click_at(point: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	Input.parse_input_event(move)
	for down in [true,false]:
		await mouse_button(point, MOUSE_BUTTON_LEFT, down)

func mouse_button(point: Vector2, button: MouseButton, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = button
	event.pressed = down
	Input.parse_input_event(event)
	await frames(2)

func art(point: Vector2) -> void:
	await click_at(canvas.get_global_transform_with_canvas() * canvas.art_to_local(point))

func capture(label: String) -> void:
	await frames(4)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/components-"+label+".png")

func click_3d(preview: SubViewportContainer, id: StringName) -> bool:
	var tower: Node3D = preview._model
	var camera: Camera3D = preview._camera
	for angle in [
		Vector3.ZERO, Vector3(0.3, -0.4, 0), Vector3(0.3, 0.4, 0),
		Vector3(-0.4, 0.4, 0), Vector3(-0.4, -0.4, 0),
		Vector3(0.70, 0, 0), Vector3(-0.70, 0, 0),
		Vector3(0, PI / 2.0, 0), Vector3(0.25, PI / 2.0, 0)
	]:
		tower.rotation = angle
		for surface: MeshInstance3D in tower._pick_meshes:
			if not surface.is_visible_in_tree() or surface.get_meta(&"pick_id") != id:
				continue
			var viewport_size := camera.get_viewport().get_visible_rect().size
			var point := camera.unproject_position(surface.global_position) * (preview.size / viewport_size)
			if not Rect2(Vector2.ZERO, preview.size).has_point(point):
				continue
			var picked: MeshInstance3D = preview._pick(point)
			if picked != null and picked.get_meta(&"pick_id") == id:
				await click_at(preview.get_global_transform_with_canvas() * point)
				return true
	check(false, "No reachable 3D target: " + id)
	return false

func cable_matches_plugs(tower: Node3D, route_index: int) -> bool:
	var assembly: Node3D = tower._cables
	var route: Dictionary = assembly.ROUTES[route_index]
	var key := "%s:%d" % [route.target, route.port]
	var source: Marker3D = tower._cable_sources[key].wire_exit
	var target: Marker3D = tower._cable_targets[key].wire_exit
	for cable: MeshInstance3D in assembly._bundles[route_index]:
		if cable.visible:
			return tower.to_local(source.global_position).is_equal_approx(cable.get_meta(&"wire_start")) and (
				tower.to_local(target.global_position).is_equal_approx(cable.get_meta(&"wire_end"))
			)
	return false

func verify_3d_assembly(preview: SubViewportContainer, pc: Dictionary, originals: Dictionary) -> void:
	var session: RefCounted = ui.inspection.session
	var picker: OptionButton = ui.inspection.find_child("RAMInventory", true, false)
	model.state.tools = true
	await click_3d(preview, &"lid")
	check(pc.lid, "3D cover refuses removal with its screws installed")
	session.select_tool(&"phillips")
	for i in 4:
		await click_3d(preview, StringName("screw_%d" % i))
		check(not pc.screws[i], "3D cover screw removed")
	session.select_tool(&"hands")
	await click_3d(preview, &"lid")
	check(not pc.lid and preview._model._parked_cover.visible, "3D cover can be removed and rests beside the tower")
	var cables: Node3D = preview._model._cables
	check(cables._bundles.size() == 7 and cables._bundles.all(func(bundle: Array) -> bool:
		return bundle[0].visible), "All seven installed cable routes are visible")
	for route_index in cables._bundles.size():
		check(cable_matches_plugs(preview._model, route_index), "Cable geometry reaches both physical plugs: " + str(route_index))
	await click_3d(preview, &"mount:motherboard:connector:0")
	check(cables._bundles[0][1].visible and not cables._bundles[0][0].visible, "Pulling ATX power moves its cable to the loose plug position")
	check(cable_matches_plugs(preview._model, 0), "ATX cable stays attached to its unplugged connector")
	await click_3d(preview, &"mount:motherboard:connector:0")
	await click_3d(preview, &"mount:psu:connector:0")
	check(cables._bundles[0][2].visible and cables._bundles[2][2].visible, "Disconnecting the PSU harness moves the origin of each power cable")
	for route_index in [0, 1, 2, 3]:
		check(cable_matches_plugs(preview._model, route_index), "The harness stays attached to loose modular plugs")
	await click_3d(preview, &"mount:psu:connector:0")
	check(cables._bundles[0][0].visible and cables._bundles[2][0].visible, "Reconnecting restores cable routing")
	preview.reset_view()
	await capture("3d-repair")
	for i in 2:
		await click_3d(preview, StringName("ram_latch_%d" % i))
	await click_3d(preview, &"ram")
	check(not pc.components.has("ram"), "3D RAM can be removed after opening its clips")
	for kind in ["gpu", "storage", "psu", "cooling", "cpu", "motherboard"]:
		session.select_tool(&"phillips")
		for i in model.FASTENERS[kind]:
			await click_3d(preview, StringName("mount:%s:screw:%d" % [kind, i]))
		session.select_tool(&"hands")
		for i in model.CONNECTIONS[kind].size():
			await click_3d(preview, StringName("mount:%s:connector:%d" % [kind, i]))
		await click_3d(preview, StringName(kind))
		check(not pc.components.has(kind), "3D disassembly removes " + kind)
	for kind in ["motherboard", "cpu", "cooling", "gpu", "storage", "psu", "ram"]:
		var index: int = ui.inspection._inventory_ids.find(originals[kind])
		check(index > 0, "Removed part available in 3D inventory: " + kind)
		if index <= 0:
			continue
		picker.select(index)
		picker.item_selected.emit(index)
		await click_3d(preview, StringName(kind))
		check(pc.components.get(kind) == originals[kind], "3D reassembly reinstalls the same " + kind)
		if kind == "ram":
			for i in 2:
				await click_3d(preview, StringName("ram_latch_%d" % i))
		else:
			for i in model.CONNECTIONS[kind].size():
				await click_3d(preview, StringName("mount:%s:connector:%d" % [kind, i]))
			session.select_tool(&"phillips")
			for i in model.FASTENERS[kind]:
				await click_3d(preview, StringName("mount:%s:screw:%d" % [kind, i]))
			session.select_tool(&"hands")
		check(false not in model.mounts(pc_id, kind).screws and false not in model.mounts(pc_id, kind).connections.values(), "3D reassembly secures " + kind)
	await click_3d(preview, &"lid")
	check(pc.lid, "Clicking the parked cover refits it in 3D")
	session.select_tool(&"phillips")
	for i in 4:
		await click_3d(preview, StringName("screw_%d" % i))
	check(session.installed_count() == 4 and model.valid(model.state), "3D reassembly secures the cover and preserves a valid save")
	preview.reset_view()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1360,768)
	world = preload("res://Tools/test_world.gd").create(true)
	root.add_child(world)
	await frames(5)
	workshop = world.get_node("PhysicalWorkshop")
	model = workshop.ledger
	ui = world.get_node("MaintenanceBenchUI")
	for record in model.state.items.values():
		if record.kind == "pc": pc_id = record.id
	var pc: Dictionary = model.item(pc_id)
	var originals: Dictionary = pc.components.duplicate()
	check(not ui.has_equipment(),"Bench starts empty")
	check(model.move(pc_id,"bench"),"Real equipment placed")
	ui.open_bench()
	check(model.request_post(pc_id),"POST requested")
	model.tick(1.3)
	check(model.test_ram(pc_id),"Broken RAM can be tested")
	ui.tabs.current_tab = 2
	await frames()
	var ram_label: Label = ui.tabs.get_tab_control(2).get_node("Content/ComponentSlots/SlotRAM/Row/Labels/Empty")
	check("8%" in ram_label.text and "Quebrado" in ram_label.text,"Components immediately reflects actual RAM test")
	check(not "ID " in model.known_description(originals.ram),"User descriptions omit technical IDs")
	await capture("tested-ram")
	ui.tabs.current_tab = 3
	for i in range(ui._component_picker.item_count):
		ui._component_picker.select(i)
		await frames()
		var kind: String = ui._component_picker.get_selected_metadata()
		await click(ui._component_test)
		check(pc.has("test_job"),"Actual test button queues "+kind)
		check(not model.test_component(pc_id,kind),"Overlapping tests rejected")
		model.tick(2.0)
		await frames()
		check(model.item(originals[kind]).tested,"Knowledge saved on unit "+kind)
	check(model.test_component(pc_id,"gpu"),"Additional test starts")
	model.toggle_power(pc_id)
	check(not pc.has("test_job"),"Power-off cancels pending test")
	await capture("tests")
	check(ui.open_inspection(),"Inspection opens only for real PC")
	await frames(5)
	canvas = ui.inspection.canvas
	var preview: SubViewportContainer = ui.inspection.preview
	var preview_toggle: Button = ui.inspection.get_node("%PreviewToggle")
	var availability: Label = preview_toggle.get_parent().get_node("PreviewAvailability")
	var button_bottom := preview_toggle.position.y + preview_toggle.size.y
	check(preview_toggle.is_visible_in_tree() and preview_toggle.disabled, "3D button is visible and disabled")
	check(availability.is_visible_in_tree() and availability.text == "Em breve!" and availability.position.y >= button_bottom,
		"Coming soon message appears below the 3D button")
	await click(preview_toggle)
	check(canvas.is_visible_in_tree() and not preview.visible and paused, "Clicking the disabled button leaves 2D inspection open")
	# Exercise the preview directly while the player-facing button is disabled.
	ui.inspection._show_preview(true)
	await frames()
	check(preview.is_visible_in_tree() and not canvas.visible and paused, "3D view renders in the paused bench")
	check(preview._model._cover.visible and preview._model._screws.all(func(screw: Node3D) -> bool: return screw.visible), "3D view reflects the fitted cover and screws")
	var pivot_before: Basis = preview._model.basis
	var camera_size: float = preview._camera.size
	var center := preview.get_global_transform_with_canvas() * (preview.size * 0.5)
	await mouse_button(center, MOUSE_BUTTON_LEFT, true)
	var drag := InputEventMouseMotion.new()
	drag.position = center + Vector2(95, 55)
	drag.global_position = drag.position
	drag.relative = Vector2(95, 55)
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(drag)
	await frames()
	await mouse_button(drag.position, MOUSE_BUTTON_LEFT, false)
	check(not preview._model.basis.is_equal_approx(pivot_before), "Dragging rotates the 3D case through GUI input")
	await mouse_button(center, MOUSE_BUTTON_WHEEL_UP, true)
	await mouse_button(center, MOUSE_BUTTON_WHEEL_UP, false)
	check(preview._camera.size < camera_size, "Scrolling zooms the 3D camera")
	await mouse_button(center, MOUSE_BUTTON_RIGHT, true)
	await mouse_button(center, MOUSE_BUTTON_RIGHT, false)
	check(preview._model.basis.is_equal_approx(pivot_before) and is_equal_approx(preview._camera.size, camera_size), "Right-click restores the 3D view")
	check(preview._model._part_faces.gpu.material_override.albedo_texture != null, "3D hardware uses the game artwork")
	await capture("3d-cover")
	await verify_3d_assembly(preview, pc, originals)
	ui.inspection._show_preview(false)
	await frames()
	check(canvas.visible and not preview.visible, "Returning to the 2D repair view restores its canvas")
	check(canvas.layers.chassis.get_width() == 1280, "Inspection chassis has original 4x resolution")
	for point in canvas.SCREW_POINTS.gpu:
		check(point.x < 40, "GPU screws are on rear bracket, never on heatsink")
	for point in canvas.SCREW_POINTS.psu:
		check(point.x < 40, "PSU mounting screws are on rear chassis, not side label")
	check(canvas.CONNECTOR_POINTS.gpu[1].x > 180, "PCIe retention latch is at end of slot")
	model.state.tools = true
	await key(KEY_2)
	check(ui.inspection.session.tool == &"phillips","2 selects Phillips in inspection")
	for p in canvas.SCREWS: await art(p)
	await art(Vector2(110,110))
	check(not pc.lid,"Four visual screws release lid")
	for corner in [canvas.FIT_BOUNDS.position, canvas.FIT_BOUNDS.end]:
		var projected: Vector2 = canvas.art_to_local(corner)
		check(Rect2(Vector2.ZERO,canvas.size).has_point(projected), "Complete PC, lid and tray fit inside inspection canvas")
	await key(KEY_1)
	check(ui.inspection.session.tool == &"hands","1 selects hands in inspection")
	check(not model.use_component(pc_id,"gpu",""),"GPU cannot bypass screws or connectors")
	check(not model.use_component(pc_id,"cpu",""),"CPU blocked by installed cooler")
	for p in canvas.LATCHES: await art(p)
	await art(Vector2(149,74))
	check(not pc.components.has("ram"),"RAM physically removed via clips")
	ui.inspection._show_preview(true)
	await frames()
	check(not preview._model._cover.visible and not preview._model._parts.ram.visible and preview._model._parts.gpu.visible, "3D view mirrors cover and component removal")
	await capture("3d-interior")
	ui.inspection._show_preview(false)
	await frames()
	for kind in ["gpu","storage","psu","cooling","cpu","motherboard"]:
		ui.inspection.session.select_tool(&"phillips")
		for i in range(model.FASTENERS[kind]):
			var point: Vector2 = canvas.mount_point(kind,i,false)
			check(canvas.hit_at(point) == StringName("mount:%s:screw:%d" % [kind,i]),"Visible screw hit target "+kind+str(i))
			await art(point)
		ui.inspection.session.select_tool(&"hands")
		for i in range(model.CONNECTIONS[kind].size()): await art(canvas.mount_point(kind,i,true))
		var part_point: Vector2 = canvas.MOUNT_RECTS[kind].get_center()
		if kind == "motherboard": part_point = Vector2(65,85)
		await art(part_point)
		check(not pc.components.has(kind),"Visual removal of "+kind)
		check(model.item(originals[kind]).location in ["tray","inventory"],"Removed unit stored exactly once "+kind)
	check(model.FASTENERS.cpu == 0,"CPU uses socket without invented screws")
	check(model.valid(model.state),"Full teardown serializes consistently")
	var latches_before: Array = pc.latches.duplicate()
	for i in range(2):
		check(canvas.hit_at(canvas.LATCHES[i]) != StringName("ram_latch_"+str(i)), "Removed motherboard has no clickable RAM latch")
		check(not model.toggle_latch(pc_id,i), "Model rejects latch operation without motherboard")
	check(pc.latches == latches_before,"Absent-board latch actions preserve stored state")
	check(canvas.hit_at(Vector2(149,74)) != &"ram", "Removed motherboard has no RAM slot hit target")
	check(not model.use_ram_slot(pc_id,originals.ram), "Absent motherboard rejects RAM installation")
	await capture("empty-chassis")
	for kind in ["motherboard","cpu","cooling","gpu","storage","psu","ram"]:
		workshop.selected_part = originals[kind]
		workshop.selected_ram = originals[kind]
		var point: Vector2 = Vector2(149,74) if kind == "ram" else canvas.MOUNT_RECTS[kind].get_center()
		if kind == "motherboard": point = Vector2(65,85)
		await art(point)
		check(pc.components.get(kind,"") == originals[kind],"Manual reinstall same unit "+kind)
		if kind == "motherboard":
			for i in range(2): check(canvas.hit_at(canvas.LATCHES[i]) == StringName("ram_latch_"+str(i)), "Reinstalled motherboard restores RAM latch interaction")
		if kind == "ram":
			for p in canvas.LATCHES: await art(p)
		else:
			ui.inspection.session.select_tool(&"phillips")
			for i in range(model.FASTENERS[kind]): await art(canvas.mount_point(kind,i,false))
			ui.inspection.session.select_tool(&"hands")
			for i in range(model.CONNECTIONS[kind].size()): await art(canvas.mount_point(kind,i,true))
	check(model.valid(model.state),"Reassembly preserves ownership and attachments")
	await capture("inspection")
	ui.close_bench()
	var spare_id := ""
	for record in model.state.items.values():
		if record.kind == "ram" and record.location == "floor": spare_id = record.id
	model.unpack(spare_id)
	model.move(spare_id,"carried")
	workshop.player.global_position = Vector2(-250,-5)
	var stock: Node = workshop.storage_ui
	stock.open_storage(true)
	await frames()
	check(stock.is_open and paused,"Shelf opens modal inventory")
	await click(stock.find_child("StoreHeldPart",true,false))
	check(model.item(spare_id).location == "inventory","UI stores held item in inventory")
	await click(stock.find_child("Transfer_"+spare_id,true,false))
	check(model.item(spare_id).location == "shelf","UI stores held item in selected shelf slot")
	var ram_slot: Button = stock.find_child("Transfer_" + spare_id, true, false)
	var shelf_art: TextureRect = ram_slot.find_child("PartArt", true, false)
	var shelf_name: Label = ram_slot.find_child("PartName", true, false)
	check(shelf_art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and shelf_name.text.contains("DDR4"),
		"Shelf centers RAM art and labels its memory generation")
	var gpu_art := preload("res://Scripts/UI/part_visuals.gd").storage_icon(model.item(originals.gpu))
	check(gpu_art.resource_path.ends_with("gpu_fan_side.svg") and gpu_art.get_width() > gpu_art.get_height(),
		"Shelf GPU shows the fan face with the card's length horizontal")
	await capture("cabinet")
	await click(stock.find_child("Transfer_"+spare_id,true,false))
	check(model.item(spare_id).location == "inventory","UI retrieves selected shelf item into inventory")
	check(not workshop.actors.has(spare_id),"Inventory unit has no duplicate floor actor")
	stock.close_storage()
	stock.open_storage(false)
	await capture("inventory")
	stock.close_storage()
	check(not paused,"Inventory restores player control")
	var personal: Node = world.get_node("Actors/WorkComputer/PersonalComputer")
	personal.boot_duration = 0.1
	var personal_ui: Node = world.get_node("PersonalComputerUI")
	personal_ui.open_computer()
	await frames(5)
	await click(personal_ui.get_node("%PowerToggle"))
	await create_timer(0.2,true).timeout
	var desktop: Node = personal_ui.get_node("%DesktopScreen")
	var shop: Control = desktop.open_app("shop")
	await frames(5)
	var market: Node = shop.find_child("Buy_DDR4",true,false).get_parent().get_parent().get_parent().get_parent()
	check(Rect2(Vector2.ZERO,shop.get_parent().size).encloses(Rect2(shop.position,shop.size)),"Shop fits TechOS work area")
	check(market._buttons.size() == model.CATALOG.size(),"Shop lists every catalog product")
	var categories: Dictionary = {}
	for entry in model.CATALOG: categories[entry.kind] = true
	check(categories.size() == model.PART_NAMES.size(),"All seven component categories have catalog products")
	check(not market._buttons.has("cpu") and not market._buttons.has("motherboard"),"Legacy processor and motherboard are absent from the shop")
	check(market.sidebar.is_ancestor_of(market._categories[""]),"Categories appear inside the TechOS sidebar")
	await click(market._categories["cpu"])
	for entry in model.CATALOG: check(market._buttons[entry.key].visible == (entry.kind == "cpu"),"Category filters "+entry.key)
	await click(market._categories[""])
	check(market._buttons.DDR4.visible and not market._categories.cpu.button_pressed,"All categories restores the full catalog")
	market._buttons.gpu.mouse_entered.emit()
	check(market.preview.texture != null and "TR Vision" in market.preview_name.text,"Hover shows image and product details")
	market._buttons.amdera_ax550.mouse_entered.emit()
	var amdera_preview: Texture2D = market.preview.texture
	check("AX4" in market.preview_name.text and "DDR4" in market.preview_name.text,"Amdera preview shows socket and memory generation")
	market._buttons.intara_ix610.mouse_entered.emit()
	check(market.preview.texture != amdera_preview and "IX1700" in market.preview_name.text and "DDR5" in market.preview_name.text,"Intara has its own preview and platform specs")
	await capture("market")
	var credits: int = model.state.credits
	await click(market._buttons.DDR4)
	check(market.confirmation.visible and model.state.credits == credits,"Click only opens confirmation")
	await capture("confirm")
	check(market.confirmation.get_ok_button().get_theme_stylebox("normal").bg_color.g > market.confirmation.get_ok_button().get_theme_stylebox("normal").bg_color.r,"Yes is green")
	check(market.confirmation.get_cancel_button().get_theme_stylebox("normal").bg_color.r > market.confirmation.get_cancel_button().get_theme_stylebox("normal").bg_color.g,"No is red")
	await click(market.confirmation.get_cancel_button())
	check(model.state.credits == credits and model.at("delivery").is_empty(),"No leaves balance and items untouched")
	market._buy("DDR4")
	await frames()
	await click(market.confirmation.get_ok_button())
	check(model.state.credits == credits-150 and model.at("delivery").size() == 1,"Yes debits once and creates one delivery")
	market._confirm_purchase()
	check(model.state.credits == credits-150,"Repeated confirm cannot duplicate charge")
	market._buy("ddr5_16")
	await frames()
	var picker: OptionButton = market.confirmation._finish
	var finishes: Array[String] = []
	for index in range(picker.item_count): finishes.append(picker.get_item_text(index))
	check(finishes == ["Sem dissipador", "Preto", "Branco", "Azul", "Vermelho"],"DDR5 offers bare RAM or exactly four heat spreader colors")
	var bare_preview: Texture2D = market.confirmation.finish_preview.texture
	picker.select(3)
	picker.item_selected.emit(3)
	check(market.confirmation.finish_preview.texture != bare_preview,"Selecting blue updates the RAM preview")
	await click(market.confirmation.get_ok_button())
	var blue_module := ""
	for record in model.state.items.values():
		if record.get("heat_spreader_color") == "Azul": blue_module = record.id
	check(not blue_module.is_empty() and model.state.credits == credits-395,"Confirmed purchase charges once and delivers blue DDR5")
	market._buy("DDR5")
	await frames()
	check(picker.item_count == 0,"DDR5 without a heat spreader has no color selector")
	await click(market.confirmation.get_cancel_button())
	for key in ["ddr4_16", "ddr4_32"]:
		market._buy(key)
		await frames()
		check(picker.item_count == 5 and picker.selected == 0,"DDR4 %s offers all finishes and defaults to bare RAM" % key)
		await click(market.confirmation.get_cancel_button())
	check(model.valid(model.state),"Expanded save remains valid")
	var restored: Dictionary = JSON.parse_string(JSON.stringify(model.state))
	check(model.valid(restored) and restored.items[spare_id].location == "inventory","Serialized save retains inventory, tests and mounts")
	personal_ui.close_computer()
	workshop.save_path = "res://.godot/components_full_save_" + str(OS.get_process_id()) + ".json"
	model.item(originals.cpu).model = "Amdera Ryvon 5 5500"
	check(workshop.save_game(false),"Expanded state written to isolated save")
	var saved_path: String = workshop.save_path
	workshop.save_path = ""
	check(model.move(spare_id,"carried"),"Move saved inventory unit before restore")
	workshop.save_path = saved_path
	check(workshop.load_game(),"Existing load API restores expanded save")
	check(model.item(originals.cpu).model == "Amdera Ryvon 5 5600","CPU from the previous catalog shows its updated model after loading")
	check(model.item(blue_module).get("heat_spreader_color") == "Azul","Restoring a save retains the selected heat spreader color")
	check(model.item(spare_id).location == "inventory" and model.item(originals.ram).tested,"Restore retains inventory and tested RAM")
	for kind in ["gpu","storage","psu","cooling","motherboard","cpu"]:
		var mount: Dictionary = model.mounts(pc_id,kind)
		check(not false in mount.screws and not false in mount.connections.values(),"Restore retains mounts for "+kind)
		check(model.item(originals[kind]).tested,"Restore retains test result for "+kind)
	check(model.valid(model.state),"Restored expanded state valid")
	verify_platform_catalog()
	world.queue_free()
	await frames()
	await create_timer(0.3).timeout
	print("COMPONENTS / INVENTORY / SHOP CHECKS: ",checks,"; failures: ",failures.size())
	quit(0 if failures.is_empty() else 1)

func verify_platform_catalog() -> void:
	var ledger := preload("res://Scripts/Gameplay/workshop_ledger.gd").new()
	var graphics_count := 0
	for entry in ledger.CATALOG:
		if entry.kind == "gpu": graphics_count += 1
		ledger.new_game(false)
		check(ledger.purchase(entry.key),"Purchase " + entry.key)
		var part := ledger.item(ledger.at("delivery")[0])
		check(part.kind == entry.kind and part.model == entry.model and not part.has("heat_spreader_color"),"Delivery without a selected finish matches " + entry.key)
		for field in ["socket", "alternate_socket", "ddr", "capacity_gb", "board_art"]:
			if entry.has(field): check(part.get(field) == entry[field],"Delivery retains %s for %s" % [field, entry.key])
		check(ledger.valid(JSON.parse_string(JSON.stringify(ledger.state))),"Save accepts " + entry.key)
	check(graphics_count == 1,"Catalog retains its single graphics card")
	ledger.new_game(false)
	check(not ledger.purchase("ddr5_16", "Verde") and not ledger.purchase("DDR4", "Azul"),"Invalid colors and unsupported modules are rejected")
	check(ledger.state.credits == 500 and ledger.at("delivery").is_empty(),"Rejected finishes leave the balance and deliveries intact")
	for key in ["ddr4_16", "ddr4_32"]:
		ledger.new_game(false)
		check(ledger.purchase(key, "Vermelho"),"DDR4 accepts a heat spreader " + key)
		var part := ledger.item(ledger.at("delivery")[0])
		check(part.heat_spreader_color == "Vermelho" and ledger.valid(JSON.parse_string(JSON.stringify(ledger.state))),"DDR4 finish survives serialization " + key)

	ledger.new_game(true)
	var bench_pc := ""
	for record in ledger.state.items.values():
		if record.kind == "pc": bench_pc = record.id
	var pc := ledger.item(bench_pc)
	pc.location = "bench"
	pc.lid = false
	var gpu_id: String = pc.components.gpu
	pc.components.erase("gpu")
	ledger.item(gpu_id).location = "carried"
	ledger.item(gpu_id).owner_pc = ""
	for kind in ["cpu", "cooling", "ram", "motherboard"]:
		ledger.state.items.erase(pc.components[kind])
		pc.components.erase(kind)
	# Fund a platform build in this isolated fixture.
	ledger.state.credits = 2000
	var purchased: Dictionary = {}
	for key in ["amdera_ax550", "intara_coren_i3", "amdera_ryvon_5", "intara_breeze_92", "amdera_frost_120", "ddr5_16", "ddr4_16"]:
		check(ledger.purchase(key),"Fixture purchase " + key)
		var id: String = ledger.at("delivery")[0]
		var part := ledger.item(id)
		part.location = "tray"
		part.packaged = false
		purchased[key] = id
	check(ledger.use_component(bench_pc, "motherboard", purchased.amdera_ax550),"Mount the Amdera motherboard")
	check(ledger.use_component(bench_pc, "gpu", gpu_id),"Reinstall the existing graphics card")
	check(not ledger.use_component(bench_pc, "cpu", purchased.intara_coren_i3),"Reject a processor for the other platform")
	check(ledger.use_component(bench_pc, "cpu", purchased.amdera_ryvon_5),"Mount the matching processor")
	check(not ledger.use_component(bench_pc, "cooling", purchased.intara_breeze_92),"Reject a cooler for the other platform")
	check(ledger.use_component(bench_pc, "cooling", purchased.amdera_frost_120),"Mount the matching cooler")
	ledger.toggle_latch(bench_pc, 0)
	ledger.toggle_latch(bench_pc, 1)
	check(not ledger.use_ram_slot(bench_pc, purchased.ddr5_16),"Reject DDR5 in the DDR4 motherboard")
	check(ledger.use_ram_slot(bench_pc, purchased.ddr4_16),"Mount the matching 16 GB module")
	ledger.toggle_latch(bench_pc, 0)
	ledger.toggle_latch(bench_pc, 1)
	for kind in pc.components:
		var mount := ledger.mounts(bench_pc, kind)
		mount.screws.fill(true)
		for connector in mount.connections: mount.connections[connector] = true
	check(ledger.evaluate_boot(bench_pc).begins_with("POST concluído. Sistema"),"Assembled Amdera platform boots")


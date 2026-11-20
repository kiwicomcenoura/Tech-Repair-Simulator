extends SceneTree
## Exercises real TechOS controls, physical transport, the workbench and an isolated save.

const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
const Ledger := preload("res://Scripts/Gameplay/workshop_ledger.gd")
const Orders := preload("res://Scripts/Gameplay/service_orders.gd")

var checks := 0
var failures := 0
var world: Node2D
var workshop: Node
var ledger: RefCounted
var player: CharacterBody2D
var bench: CanvasLayer
var save_path := "res://.godot/case-assembly-%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, explanation: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(explanation)


func frames() -> void:
	for i in range(3): await process_frame


func key(code: Key, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.shift_pressed = shift
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()


func stand(position: Vector2) -> void:
	player.global_position = position
	await physics_frame
	await frames()


func point_of(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas() * (control.size * 0.5)


func mouse_move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
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


func click_at(point: Vector2) -> void:
	await mouse_move(point)
	await mouse_button(point, true)
	await mouse_button(point, false)


func click(control: Control) -> void:
	await click_at(point_of(control))


func canvas_point(point: Vector2) -> Vector2:
	var canvas: Control = bench.inspection.canvas
	return canvas.get_global_transform_with_canvas() * canvas.art_to_local(point)


func select_part(id: String) -> void:
	var view: Control = bench.inspection
	var index: int = view._inventory_ids.find(id)
	check(index > 0, "The physical part is listed in the original inspection")
	if index > 0:
		view._inventory.select(index)
		view._inventory.item_selected.emit(index)
	await frames()


func delivered_box(id: String) -> void:
	var record: Dictionary = ledger.item(id)
	await stand(Vector2(record.position[0], record.position[1]))
	await key(KEY_E)
	check(not record.packaged and record.location == "floor", "E unboxes the existing physical unit")
	await key(KEY_E)
	check(ledger.carried() == id, "E picks the same physical unit up")


func put_part_on_tray(id: String) -> void:
	await delivered_box(id)
	await stand(Vector2(130, -90))
	await key(KEY_E)
	check(ledger.item(id).location == "tray" and workshop.actors.has(id), "E places the purchased part on the physical bench tray")


func verify_catalog() -> void:
	var model := Ledger.new()
	var artwork: Array[PackedByteArray] = []
	var inspection_chassis: Array[PackedByteArray] = []
	var inspection_lids: Array[PackedByteArray] = []
	var prices := {"intara_m100": 120, "amdera_core_200": 190, "amdera_gx500": 350, "intara_x700": 490}
	for entry in Cases.MODELS:
		model.new_game(false)
		check(entry.price == prices[entry.key] and entry.glass == (entry.price >= 350), "Catalog price and panel type match " + entry.key)
		check(model.purchase(entry.key), "Case is purchasable: " + entry.key)
		var id: String = model.at("delivery")[0]
		var item := model.item(id)
		check(model.state.credits == 500 - entry.price and model.state.transactions.size() == 1
			and model.state.transactions[0].item_id == id and model.state.transactions[0].amount == -entry.price, "One correct debit per case")
		check(item.components.is_empty() and item.case_key == entry.key and item.lid and not item.power and item.packaged, "Purchased case starts fully empty and boxed")
		check(model.bench_id().is_empty() and model.at("floor").is_empty(), "Checkout only queues a delivery")
		check(model.available_purchased_cases().is_empty() and not model.place_purchased_case(id), "Undelivered cases are excluded from the picker")
		model.tick(2.0)
		var restored: Dictionary = JSON.parse_string(JSON.stringify(model.state))
		check(model.valid(restored), "Pending delivery is valid after save serialization")
		model.state = restored
		model.tick(1.1)
		model.tick(20.0)
		check(model.at("floor") == [id] and model.state.items.size() == 1 and model.at("delivery").is_empty(), "Resumed delivery creates exactly one physical case")
		var closed := Cases.texture(entry.key).get_image()
		var opened := Cases.texture(entry.key, false).get_image()
		check(closed.get_used_rect().has_area() and opened.get_used_rect().has_area() and closed.get_data() != opened.get_data(), "Each case has distinct closed and open art")
		check(closed.get_data() not in artwork, "Each model has original art")
		artwork.append(closed.get_data())
		var side := Cases.inspection_texture(entry.key, "chassis").get_image()
		var lid := Cases.inspection_texture(entry.key, "lid").get_image()
		check(side.get_size() == Vector2i(320, 240) and lid.get_size() == Vector2i(320, 240)
			and side.get_data() not in inspection_chassis and lid.get_data() not in inspection_lids,
			"Each model has distinct chassis and lid art fitted to the inspection: " + entry.key)
		var window := lid.get_pixel(200, 90)
		check((window.a > 0.0 and window.a < 1.0) if entry.glass else window.a == 1.0,
			"Glass lids show components and steel lids cover them: " + entry.key)
		inspection_chassis.append(side.get_data())
		inspection_lids.append(lid.get_data())
	check(Cases.get_model("intara_m100").board_formats == ["micro-ATX"], "Office case is micro-ATX only")
	for key: String in ["amdera_core_200", "amdera_gx500", "intara_x700"]:
		check(Cases.get_model(key).board_formats == ["ATX", "micro-ATX"], "ATX case accepts both supported formats: " + key)
	model.new_game(false)
	model.purchase("intara_m100")
	model.purchase("amdera_core_200")
	model.tick(3.1)
	var ids := model.at("floor")
	check(ids.size() == 2 and model.item(ids[0]).position != model.item(ids[1]).position, "Concurrent purchases reserve two different physical delivery spots")
	model.unpack(ids[0])
	model.move(ids[0], "bench")
	model.unpack(ids[1])
	model.move(ids[1], "carried")
	check(not model.move(ids[1], "bench") and model.bench_id() == ids[0] and model.carried() == ids[1], "Bench has one physical cabinet slot")
	model.new_game(true)
	var legacy_pc: Dictionary = model.item(model.at("floor")[0])
	var legacy_board: Dictionary = model.item(legacy_pc.components.motherboard)
	legacy_board.erase("board_format")
	check(model.valid(JSON.parse_string(JSON.stringify(model.state))) and Cases.board_format(legacy_board) == "ATX", "Pre-assembly saves still validate and legacy boards resolve their original format")
	model.new_game(false)
	model.purchase("amdera_core_200")
	model.purchase("amdera_ax550")
	model.tick(3.1)
	ids = model.at("floor")
	var tower: Dictionary = model.item(ids[0])
	model.unpack(tower.id)
	model.move(tower.id, "bench")
	tower.lid = false
	tower.screws = [false, false, false, false]
	model.unpack(ids[1])
	check(not model.use_component(tower.id, "motherboard", ids[1]), "A loose board on the floor is outside the inspection inventory")
	model.move(ids[1], "shelf")
	check(model.use_component(tower.id, "motherboard", ids[1]) and model.valid(model.state), "The ATX tower takes an unpacked board directly from the cabinet")
	check(not model.sell(tower.id) and not model.sell(ids[1]), "Installed boards and the cabinets containing them cannot be sold")
	model.use_component(tower.id, "motherboard", "")
	check(model.sell(tower.id) and model.state.credits == 191 and model.item(ids[1]).location == "tray"
		and model.bench_id().is_empty() and model.valid(model.state), "Empty cabinet sale clears the bench and keeps the separately purchased board")


func buy_in_shop(market: Node, product: String) -> String:
	var credits: int = ledger.state.credits
	var before: int = ledger.state.items.size()
	market.products.get_parent().ensure_control_visible(market._buttons[product])
	await frames()
	await click(market._buttons[product])
	check(market.confirmation.visible and ledger.state.credits == credits, "Checkout waits for confirmation: " + product)
	await click(market.confirmation.get_ok_button())
	check(ledger.state.items.size() == before + 1 and ledger.state.credits < credits, "Shop confirms exactly one purchase: " + product)
	if ledger.state.transactions.is_empty(): return ""
	return ledger.state.transactions.back().item_id


func run() -> void:
	root.size = Vector2i(1360, 768)
	TranslationServer.set_locale("pt")
	verify_catalog()
	world = preload("res://Tools/test_world.gd").create()
	root.add_child(world)
	await frames()
	workshop = world.get_node("PhysicalWorkshop")
	ledger = workshop.ledger
	player = workshop.player
	bench = workshop.bench_ui
	for order in Orders.orders(ledger, "offered"):
		check(Orders.accept(ledger, order.id), "Existing service system supplies valid funds")
	ledger.state.balance_adjustment = 1600
	ledger.state.credits += 1600
	var credits: int = ledger.state.credits
	var personal: Node = world.get_node("Actors/WorkComputer/PersonalComputer")
	var personal_ui: CanvasLayer = world.get_node("PersonalComputerUI")
	personal.boot_duration = 0.05
	personal_ui.open_computer()
	await frames()
	await click(personal_ui.get_node("%PowerToggle"))
	await create_timer(0.12, true).timeout
	var desktop: Control = personal_ui.get_node("%DesktopScreen")
	var shop: Control = desktop.open_app("shop")
	await frames()
	var search := shop.find_child("CatalogSearch", true, false) as LineEdit
	var market: Node = search.get_parent()
	await click(market._categories.case)
	check(market._buttons.intara_m100.visible and not market._buttons.intara_ix610.visible, "Real TechOS Gabinetes category filters only cases")
	search.text = "intara aquario"
	search.text_changed.emit(search.text)
	check(market._buttons.intara_x700.visible and not market._buttons.intara_m100.visible and market.preview.texture != null
		and "Tampa de vidro" in market.preview_name.text and "9 ventoinha" in market.preview_name.text, "Accent-insensitive search and case specifications work")
	search.text = ""
	search.text_changed.emit("")
	var case_id := await buy_in_shop(market, "intara_m100")
	await click(market._categories.motherboard)
	var atx := await buy_in_shop(market, "amdera_ax550")
	var matx := await buy_in_shop(market, "intara_ix610")
	check(ledger.state.credits == credits - 120 - 290 - 310, "Correct balance after buying a case and two boards")
	check(ledger.purchase("amdera_ryvon_3"), "Buy an AX4 processor")
	var ryvon: String = ledger.state.transactions.back().item_id
	check(ledger.purchase("intara_coren_i3"), "Buy an IX1700 processor")
	var coren: String = ledger.state.transactions.back().item_id
	if case_id.is_empty() or atx.is_empty() or matx.is_empty() or failures > 0:
		finish()
		return
	ledger.tick(3.1)
	ledger.tick(3.1)
	check(ledger.bench_id().is_empty() and ledger.at("floor").size() == 5 and workshop.actors.has(case_id), "Purchases arrive as five physical boxes and never occupy the workbench")
	check(ledger.item(case_id).components.is_empty(), "A delivered cabinet contains no components")
	personal_ui.close_computer()
	await frames()
	await stand(Vector2(130, -90))
	await key(KEY_F)
	await click(bench.find_child("Inspect", true, false))
	var view: Control = bench.inspection
	var picker: MenuButton = view.get_node("Workspace/CasePanel/Content/EmptyCaseSlot/AddCase")
	check(view.visible and view.session == null and picker.is_visible_in_tree() and not picker.disabled, "The old inspection opens empty with the cabinet picker")
	var popup := picker.get_popup()
	check(popup.item_count == 1 and popup.get_item_metadata(0) == case_id, "The picker lists the exact delivered purchase by ID")
	await click(picker)
	check(popup.visible, "Clicking Add Case opens its list")
	popup.id_pressed.emit(popup.get_item_id(0))
	await frames()
	check(ledger.bench_id() == case_id and not ledger.item(case_id).packaged and view.session.physical_pc_id == case_id
		and not picker.is_visible_in_tree() and not popup.visible, "Selecting a case unpacks the real unit, opens the inspection and hides the picker")
	check(view.canvas._chassis_art == Cases.inspection_texture("intara_m100", "chassis")
		and view.canvas._lid_art == Cases.inspection_texture("intara_m100", "lid"), "Inspection loads the selected M100 look")
	bench.close_bench()
	await key(KEY_E, true)
	check(ledger.carried() == case_id, "The cabinet placed by the picker is still a physical unit that E can pick up")
	var cabinet_sprite: Sprite2D = workshop.actors[case_id].get_node("Sprite")
	check(cabinet_sprite.scale.x < 0.75 and cabinet_sprite.position.y < 0.0, "Purchased case is scaled down in the world")
	await stand(Vector2(200, 16))
	await key(KEY_E)
	check(ledger.item(case_id).location == "floor" and ledger.carried().is_empty(), "E can put the unboxed case down")
	await stand(Vector2(200, 40))
	await key(KEY_E)
	await stand(Vector2(130, -90))
	await key(KEY_E)
	check(ledger.bench_id() == case_id and workshop.dock.get_equipment().equipment_id == case_id, "E places the same cabinet in the existing physical dock")
	await put_part_on_tray(atx)
	await put_part_on_tray(matx)
	await put_part_on_tray(ryvon)
	await put_part_on_tray(coren)
	await stand(workshop.TOOLBOX_ACCESS_POSITION)
	await key(KEY_F)
	check(ledger.state.tools, "Player obtains the existing Phillips tool via F")
	await stand(Vector2(130, -90))
	await key(KEY_F)
	check(bench.is_open and bench.can_inspect(), "The same inspection is available after placing a cabinet by hand")
	await click(bench.find_child("Inspect", true, false))
	var canvas: Control = view.canvas
	var pc: Dictionary = ledger.item(case_id)
	check(view.visible and canvas.visible and pc.components.is_empty() and not picker.is_visible_in_tree(), "Original inspection shows a real empty cabinet")
	await click_at(canvas_point(Vector2(115, 110)))
	check(ledger.item(case_id).lid, "Fastened lid cannot be pulled away")
	await key(KEY_2)
	for point: Vector2 in canvas.SCREWS:
		await click_at(canvas_point(point))
	await key(KEY_1)
	await click_at(canvas_point(Vector2(115, 110)))
	check(not pc.lid and not true in pc.screws and pc.components.is_empty(), "Four Phillips operations and hands reveal the empty interior")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/case-assembly-empty.png")
	var motherboard_point := Vector2(65, 85)
	await select_part(atx)
	await click_at(canvas_point(motherboard_point))
	check(ledger.item(atx).location == "tray" and ledger.item(case_id).components.is_empty()
		and "Formato incompatível" in view.get_node("%ContextMessage").text, "ATX board is rejected by the micro-ATX case without moving the unit")
	await select_part(matx)
	await click_at(canvas_point(motherboard_point))
	check(ledger.item(case_id).components.get("motherboard") == matx, "Clicking the original mount installs the compatible motherboard")
	if ledger.item(case_id).components.get("motherboard") != matx:
		finish()
		return
	check(ledger.item(matx).location == "installed" and ledger.item(matx).owner_pc == case_id
		and not workshop.actors.has(matx) and matx not in ledger.at("tray"), "Installed board exists only in its case")
	check(not ledger.move(matx, "shelf") and not ledger.move(matx, "floor"), "An installed board cannot be moved through the loose-item API")
	check(not true in ledger.mounts(case_id, "motherboard").screws, "Newly positioned board needs all screws")
	await key(KEY_2)
	for index in range(canvas.SCREW_POINTS.motherboard.size()):
		await click_at(canvas_point(canvas.mount_point("motherboard", index, false)))
	check(not false in ledger.mounts(case_id, "motherboard").screws, "Phillips secures every motherboard screw")
	check(not ledger.toggle_power(case_id) and not ledger.request_post(case_id) and not ledger.item(case_id).power, "A board alone does not permit POST or power on")
	check(ledger.valid(ledger.state) and workshop.dock.get_equipment().components.get("motherboard") == matx, "Equipment record and save share the installed ID")
	var socket_point: Vector2 = canvas.mount_rect("cpu", pc).get_center()
	var latch_point: Vector2 = canvas.mount_point("cpu", 0, true)
	await key(KEY_1)
	await select_part(ryvon)
	await click_at(canvas_point(socket_point))
	check(ledger.item(ryvon).location == "tray" and not ledger.item(case_id).components.has("cpu")
		and "Socket incompatível" in view.get_node("%ContextMessage").text, "The socket rejects the wrong platform and preserves the physical part")
	await select_part(coren)
	await click_at(canvas_point(socket_point))
	check(ledger.item(case_id).components.get("cpu") == coren and not ledger.mounts(case_id, "cpu").connections.socket
		and not workshop.actors.has(coren), "The compatible processor seats in the socket and disappears from the tray")
	await click_at(canvas_point(latch_point))
	check(ledger.mounts(case_id, "cpu").connections.socket and ledger.valid(ledger.state), "The socket latch secures the processor and saves its state")
	check(not ledger.request_post(case_id), "A board and processor still require the other essential components")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/case-assembly-secured.png")
	var invalid: Dictionary = ledger.state.duplicate(true)
	invalid.items[matx].location = "tray"
	check(not ledger.valid(invalid), "Save rejects an installed ID with a second physical location")
	invalid = ledger.state.duplicate(true)
	invalid.items[matx].board_format = "ATX"
	check(not ledger.valid(invalid), "Save rejects an incompatible installed board")
	invalid = ledger.state.duplicate(true)
	invalid.items[coren].socket = "AX4"
	check(not ledger.valid(invalid), "Save rejects an incompatible installed processor")
	workshop.save_path = save_path
	check(workshop.save_game(false), "Assembly saves using the normal workshop writer")
	workshop.save_path = ""
	await key(KEY_1)
	await click_at(canvas_point(motherboard_point))
	check(ledger.item(matx).location == "installed" and "Retire CPU" in view.get_node("%ContextMessage").text, "A board cannot be removed with a processor in its socket")
	await click_at(canvas_point(socket_point))
	check(ledger.item(coren).location == "installed", "The processor cannot be lifted with its socket locked")
	await click_at(canvas_point(latch_point))
	await click_at(canvas_point(socket_point))
	check(ledger.item(coren).location == "tray" and not ledger.item(case_id).components.has("cpu")
		and workshop.actors.has(coren) and ledger.valid(ledger.state), "Opening the latch and lifting the chip returns the same processor to the tray")
	await click_at(canvas_point(motherboard_point))
	check(ledger.item(matx).location == "installed", "Fastened board cannot be pulled away")
	await key(KEY_2)
	for index in range(canvas.SCREW_POINTS.motherboard.size()):
		await click_at(canvas_point(canvas.mount_point("motherboard", index, false)))
	await key(KEY_1)
	await click_at(canvas_point(motherboard_point))
	check(ledger.item(case_id).components.is_empty() and ledger.item(matx).location == "tray"
		and ledger.item(matx).owner_pc.is_empty() and workshop.actors.has(matx) and ledger.valid(ledger.state), "Removal returns the same ID and one actor to the tray")
	workshop.save_path = save_path
	check(workshop.load_game(), "Assembly restores through the normal workshop loader")
	check(ledger.bench_id() == case_id and ledger.item(case_id).components.get("motherboard") == matx
		and not ledger.item(case_id).lid and not false in ledger.mounts(case_id, "motherboard").screws
		and not workshop.actors.has(matx) and ledger.valid(ledger.state), "Restore preserves case, board, lid and fasteners without duplicates")
	check(ledger.item(case_id).components.get("cpu") == coren and ledger.mounts(case_id, "cpu").connections.socket
		and not workshop.actors.has(coren), "Restore preserves the installed processor and socket lock without duplicating the part")
	await stand(Vector2(130, -90))
	await key(KEY_F)
	await click(bench.find_child("Inspect", true, false))
	check(view.visible and view.session.physical_pc_id == case_id and not picker.is_visible_in_tree(), "Restored computer is shown by the original inspection")
	await complete_build(case_id)
	check(ledger.move(case_id, "floor", Vector2(130, -59)), "Remove the first cabinet to inspect a different one")
	check(ledger.purchase("intara_x700"), "Purchase the Vision X700")
	var vision_id: String = ledger.state.transactions.back().item_id
	ledger.tick(3.1)
	check(ledger.place_purchased_case(vision_id), "Place the Vision X700 in the same inspection")
	check(canvas._chassis_art == Cases.inspection_texture("intara_x700", "chassis")
		and canvas._lid_art == Cases.inspection_texture("intara_x700", "lid") and canvas._case_model.front_glass,
		"Switching to the Vision X700 shows its white frame and glass instead of the previous cabinet")
	for i in range(canvas.SCREWS.size()):
		check(canvas.hit_at(canvas.SCREWS[i]) == StringName("screw_%d" % i), "Vision X700 lid screw remains clickable")
	finish()


func complete_build(case_id: String) -> void:
	workshop.save_path = ""
	var view: Control = bench.inspection
	var canvas: Control = view.canvas
	var pc: Dictionary = ledger.item(case_id)
	var products := {"ram": "DDR4", "cooling": "intara_breeze_92", "gpu": "gpu", "storage": "storage", "psu": "psu"}
	for kind in products:
		var bought: bool = ledger.purchase(products[kind])
		check(bought, "Purchase a remaining component for the full build: " + kind)
		if not bought: continue
		var id: String = ledger.state.transactions.back().item_id
		ledger.tick(3.1)
		check(ledger.unpack(id) and ledger.move(id, "inventory"), "Put the unboxed part in inventory: " + kind)
		await key(KEY_1)
		await select_part(id)
		if kind == "ram":
			for latch: Vector2 in canvas.LATCHES: await click_at(canvas_point(latch))
			await click_at(canvas_point(canvas.RAM_SLOT.get_center()))
			for latch: Vector2 in canvas.LATCHES: await click_at(canvas_point(latch))
		else:
			await click_at(canvas_point(canvas.mount_rect(kind, pc).get_center()))
			if pc.components.get(kind) == id:
				await key(KEY_2)
				for index in range(canvas.SCREW_POINTS[kind].size()):
					await click_at(canvas_point(canvas.mount_point(kind, index, false)))
				await key(KEY_1)
				for index in range(canvas.CONNECTOR_POINTS[kind].size()):
					await click_at(canvas_point(canvas.mount_point(kind, index, true)))
		check(pc.components.get(kind) == id and ledger.item(id).owner_pc == case_id and id not in ledger.at("inventory"),
			"Original inspection installs the part into the purchased cabinet without duplication: " + kind)
	check(not ledger.request_post(case_id), "Complete but disconnected build cannot start POST")
	for index in range(canvas.CONNECTOR_POINTS.motherboard.size()):
		await click_at(canvas_point(canvas.mount_point("motherboard", index, true)))
	check(ledger.valid(JSON.parse_string(JSON.stringify(ledger.state))), "All assembled parts and fastenings survive JSON validation")
	check(not view._power.disabled, "Original inspection allows power once the build is complete")
	await click(view._power)
	check(pc.power and ledger.valid(ledger.state), "Complete build powers on from the original inspection")
	ledger.tick(1.3)
	check(ledger.video_status(case_id) == "firmware" and pc.boot_result.begins_with("POST concluído"),
		"Complete build reaches firmware with a store-bought SSD")
	await click(view._power)
	check(not pc.power, "The same inspection can power the assembled PC off")


func finish() -> void:
	if is_instance_valid(world): world.queue_free()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix): DirAccess.remove_absolute(save_path + suffix)
	print("CASE ASSEMBLY CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures > 0 else 0)

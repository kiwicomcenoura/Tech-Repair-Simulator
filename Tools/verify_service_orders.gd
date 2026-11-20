extends SceneTree

const Orders := preload("res://Scripts/Gameplay/service_orders.gd")
const Ledger := preload("res://Scripts/Gameplay/workshop_ledger.gd")
var checks := 0
var failures := 0

func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)

func _initialize() -> void:
	call_deferred("run")

func repair(model: RefCounted, order: Dictionary) -> void:
	var pc: Dictionary = model.item(order.pc_id)
	check(model.move(pc.id, "bench"), "Received PC can be placed on bench")
	pc.lid = false
	pc.screws = [false, false, false, false]
	model.state.tools = true
	for key in Orders.JOBS[order.kind].parts:
		var ram: bool = key in ["ram", "ram2"]
		var slot := 1 if key == "ram2" else 0
		if ram:
			for i in range(2): check(model.toggle_latch(pc.id, i, slot), "RAM clips open")
			if pc.components.has(key): check(model.use_ram_slot(pc.id, "", slot), "Faulty RAM removed")
		else:
			var mount: Dictionary = model.mounts(pc.id, key)
			pc.tool = "phillips"
			for i in range(mount.screws.size()): check(model.operate_mount(pc.id, key, "screw", i), "Component unscrewed")
			pc.tool = "hands"
			for i in range(mount.connections.size()): check(model.operate_mount(pc.id, key, "connector", i), "Component unplugged")
			check(model.use_component(pc.id, key, ""), "Faulty component removed")
		var before: Array = model.state.items.keys()
		check(model.purchase("DDR4" if ram else key), "Customer deposit funds real replacement purchase")
		var replacement := ""
		for id in model.state.items:
			if id not in before: replacement = id
		model.tick(3.1)
		check(model.unpack(replacement), "Purchased replacement arrives packaged")
		check(model.move(replacement, "carried"), "Replacement physically available")
		if ram:
			check(model.use_ram_slot(pc.id, replacement, slot), "Compatible RAM installed")
			for i in range(2): check(model.toggle_latch(pc.id, i, slot), "RAM clips close")
		else:
			check(model.use_component(pc.id, key, replacement), "Replacement installed")
			var mount: Dictionary = model.mounts(pc.id, key)
			pc.tool = "phillips"
			for i in range(mount.screws.size()): check(model.operate_mount(pc.id, key, "screw", i), "Replacement fixed")
			pc.tool = "hands"
			for i in range(mount.connections.size()): check(model.operate_mount(pc.id, key, "connector", i), "Replacement reconnected")
	check(model.request_post(pc.id), "POST requested")
	model.tick(1.3)
	check(pc.boot_ok, "Repaired machine boots")
	var kinds: Array = model.PART_NAMES.keys() if order.kind == "diagnosis" else Orders.JOBS[order.kind].parts
	for kind in kinds:
		check(model.test_component(pc.id, "ram" if kind == "ram2" else kind), "Required component can be tested")
		model.tick(2.0)
	check(model.toggle_power(pc.id), "Machine powered off for handover")
	pc.lid = true
	pc.screws = [true, true, true, true]
	check(not Orders.deliver(model, order.id), "Delivery cannot teleport PC from bench")
	check(model.move(pc.id, "carried"), "Correct machine can be carried to customer")
	for requirement in Orders.requirements(model, order): check(requirement.ok, "Satisfied: " + requirement.text)

func frames() -> void:
	for i in range(4): await process_frame

func key(code: Key, shift: bool = false) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.shift_pressed = shift
		event.pressed = down
		Input.parse_input_event(event)
		await frames()

func stand(workshop: Node, position: Vector2) -> void:
	workshop.player.global_position = position
	await physics_frame
	await frames()

func press_button(parent: Node, button_name: String) -> bool:
	var button := parent.find_child(button_name, true, false) as Button
	var available := is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled
	check(available, "Guided action available: " + button_name)
	if available: button.pressed.emit()
	return available

func finish_guided_job(workshop: Node, order: Dictionary) -> void:
	var guide: Node = workshop.get_node("FirstServiceGuide")
	var model: RefCounted = workshop.ledger
	var pc: Dictionary = model.item(order.pc_id)
	var bench: CanvasLayer = workshop.bench_ui
	var view: Control = bench.inspection
	check("Phillips" in guide._hint.text, "First job leads to the physical toolbox")
	await stand(workshop, workshop.TOOLBOX_ACCESS_POSITION)
	await key(KEY_F)
	check(model.state.tools and "tampo" in guide._hint.text, "Opening the toolbox advances to cabinet placement")
	await stand(workshop, Vector2(130, -90))
	await key(KEY_E)
	await key(KEY_F)
	check(bench.is_open and "Inspecionar" in guide.bench_hint.text, "Guide is visible in the paused bench UI")
	if not press_button(bench, "Inspect"): return
	await frames()
	check("Ligar PC" in guide.bench_hint.text, "Inspection shows the initial power action")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://first-service-inspection.png")
	if not press_button(view, "BenchPower"): return
	await frames()
	check("Aguarde" in guide.bench_hint.text, "Guide waits for the real POST")
	model.tick(1.3)
	await frames()
	check(not pc.boot_ok and "Testar RAM" in guide.bench_hint.text, "A failed POST leads to testing the installed RAM")
	if not press_button(view, "MemoryTest"): return
	await frames()
	check(model.item(order.originals.ram).tested and "Desligar PC" in guide.bench_hint.text, "Diagnosis leads to safely shutting down")
	if not press_button(view, "BenchPower"): return
	check(workshop.load_game(), "A real save can be restored after diagnosing the original RAM")
	await frames()
	check("Loja de Peças" in guide._hint.text, "Restored guide resumes at buying the replacement")
	var personal: CanvasLayer = workshop.get_parent().get_node("PersonalComputerUI")
	personal.computer.boot_duration = 0.1
	await stand(workshop, Vector2(380, 55))
	await key(KEY_F)
	check(personal.is_open and "DDR4" in guide.personal_hint.text, "Office computer shows the shopping hint")
	if not press_button(personal, "PowerToggle"): return
	await create_timer(0.2).timeout
	var shop: Control = personal.get_node("%DesktopScreen").open_app("shop")
	check(is_instance_valid(shop), "Parts shop opens on the office computer")
	if not is_instance_valid(shop): return
	await frames()
	if not press_button(shop, "Buy_DDR4"): return
	var confirmation: CanvasLayer = shop.find_child("PurchaseConfirmation", true, false)
	check(confirmation.visible, "Guided purchase uses the normal order confirmation")
	confirmation.get_ok_button().pressed.emit()
	var deliveries: Array = model.at("delivery")
	check(deliveries.size() == 1, "The purchased RAM is delivered as a physical package")
	if deliveries.is_empty(): return
	var replacement: Dictionary = model.item(deliveries[0])
	personal.close_computer()
	await frames()
	check("Aguarde" in guide._hint.text, "Guide shows where the delivery will arrive")
	model.tick(3.1)
	await stand(workshop, Vector2(replacement.position[0], replacement.position[1]))
	check("abrir a caixa" in guide._hint.text, "Guide leads to the package after delivery")
	await key(KEY_E)
	check("desembalada" in guide._hint.text, "Opening the box advances to pickup")
	await key(KEY_E)
	await stand(workshop, Vector2(130, -90))
	check("lista de peças" in guide._hint.text, "Guide explains direct bench access while carrying the replacement")
	check(model.move(replacement.id, "shelf"), "Store replacement in the cabinet for the direct bench route")
	await frames()
	await key(KEY_F)
	if not press_button(bench, "Inspect"): return
	await frames()
	var session: RefCounted = view.session
	check("quatro parafusos" in guide.bench_hint.text, "Guide explains how to open the case")
	await key(KEY_2)
	for i in range(4): session.interact_with(StringName("screw_%d" % i))
	await frames()
	check("Retirar tampa" in guide.bench_hint.text, "Guide sees the removed screws")
	if not press_button(view, "LidAction"): return
	await key(KEY_1)
	check("abra as duas travas" in guide.bench_hint.text, "Guide identifies the correct RAM slot")
	for i in range(2): session.interact_with(StringName("ram_latch_%d" % i))
	await frames()
	check("retirar a RAM" in guide.bench_hint.text, "Open latches advance to removing old RAM")
	session.interact_with(&"ram")
	await frames()
	check("selecione a RAM DDR4" in guide.bench_hint.text, "Empty slot advances to selecting the replacement")
	var picker: OptionButton = view.find_child("RAMInventory", true, false)
	var index: int = view._inventory_ids.find(replacement.id)
	check(index > 0 and "Armário" in picker.get_item_text(index), "The guided replacement is selectable and identified as cabinet stock")
	if index < 1: return
	picker.select(index)
	picker.item_selected.emit(index)
	session.interact_with(&"ram")
	await frames()
	check("feche as duas travas" in guide.bench_hint.text, "Mounted replacement advances to closing latches")
	for i in range(2): session.interact_with(StringName("ram_latch_%d" % i))
	await frames()
	check("POST" in guide.bench_hint.text, "Closed latches advance to retesting startup")
	if not press_button(view, "BenchPower"): return
	model.tick(1.3)
	await frames()
	check("condição do módulo novo" in guide.bench_hint.text, "Successful POST advances to testing the new RAM")
	if not press_button(view, "MemoryTest") or not press_button(view, "BenchPower"): return
	await frames()
	check("Recolocar tampa" in guide.bench_hint.text, "Guide waits for a closed case")
	if not press_button(view, "LidAction"): return
	await key(KEY_2)
	for i in range(4): session.interact_with(StringName("screw_%d" % i))
	await frames()
	check("Gabinete pronto" in guide.bench_hint.text, "Guide recognises a deliverable PC")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await key(KEY_E, true)
	check("Entregar ao cliente" in guide._hint.text, "Completed PC is directed back to the counter")
	await stand(workshop, Vector2(15, 230))
	await key(KEY_F)
	var balance: int = model.state.credits
	if not press_button(workshop.orders_ui.board, "Deliver_" + order.id): return
	await frames()
	check(Orders.get_order(model, order.id).status == "delivered", "The ordinary delivery action completes the guided order")
	check(model.state.credits == balance + order.reward - order.deposit and not guide._panel.visible, "Delivery pays exactly once and dismisses the guide")

func verify_reserved_budget(model: RefCounted) -> void:
	var budget := Ledger.new()
	budget.state = model.state.duplicate(true)
	var order: Dictionary = Orders.orders(budget, "offered").filter(func(proposal: Dictionary) -> bool: return proposal.kind in ["psu", "gpu"])[0]
	var expansion := budget.next_shelf_expansion()
	while budget.state.credits >= expansion.price:
		check(budget.purchase("cooling"), "Part purchases spend the balance normally")
	check(Orders.accept(budget, order.id) and budget.state.credits >= expansion.price, "An active order supplies the missing amount as a deposit")
	var credits: int = budget.state.credits
	check(not budget.buy_shelf_expansion(expansion.id) and budget.state.credits == credits and budget.shelf_capacity() == 9, "A cabinet expansion cannot use deposits reserved for active repairs")
	check(budget.valid(budget.state), "A refused expansion leaves a valid save")

func verify_previous_orders() -> void:
	var model := Ledger.new()
	model.new_game()
	Orders.ensure(model)
	var offer: Dictionary = Orders.orders(model, "offered")[0]
	var old_job: Dictionary = Orders.JOBS.ram_gpu
	offer.kind = "ram_gpu"
	offer.title = old_job.title
	offer.report = old_job.reports[0]
	offer.deposit = old_job.cost
	offer.reward = old_job.cost + old_job.labor
	model.state.services.bag = ["ram_gpu", "diagnosis"]
	var restored: Dictionary = JSON.parse_string(JSON.stringify(model.state))
	check(model.valid(restored), "An older save can have offers and unused draws from a locked tier")
	model.state = restored
	check(Orders.accept(model, offer.id), "A previously issued advanced offer is still playable")
	Orders.tick(model, 45)
	check(Orders.orders(model, "offered").all(func(order: Dictionary) -> bool: return order.kind in Orders.BASIC_JOBS), "Unassigned locked categories from an old bag cannot bypass progression")

func verify_shelf_expansions(model: RefCounted) -> void:
	var world: Node2D = preload("res://Tools/test_world.gd").create(true)
	root.add_child(world)
	var workshop: Node = world.get_node("PhysicalWorkshop")
	var ui: CanvasLayer = workshop.storage_ui
	workshop.ledger.state = model.state.duplicate(true)
	workshop._sync_nodes()
	workshop.save_path = "res://.godot/workshop-progression-%d.json" % OS.get_process_id()
	await stand(workshop, Vector2(-250, -5))
	await key(KEY_F)
	check(ui.shelf_access and ui._expand_button.is_visible_in_tree(), "The expansion is purchasable from the physical cabinet")
	var first: Dictionary = workshop.ledger.next_shelf_expansion()
	var before: int = workshop.ledger.state.credits
	if not press_button(ui, "BuyShelfExpansion"): return
	check(ui._expansion_confirmation.visible and workshop.ledger.state.credits == before, "Opening the purchase confirmation leaves the balance intact")
	await key(KEY_ESCAPE)
	check(ui.is_open and not ui._expansion_confirmation.visible and workshop.ledger.state.credits == before, "Escape cancels the purchase and keeps the cabinet open")
	if not press_button(ui, "BuyShelfExpansion"): return
	ui._expansion_confirmation.get_ok_button().pressed.emit()
	check(workshop.ledger.shelf_capacity() == 15 and workshop.ledger.state.credits == before - first.price, "Confirming pays once and expands the cabinet to 15 slots")
	check(not workshop.ledger.buy_shelf_expansion(first.id), "A stale confirmation cannot purchase an expansion twice")
	check(ui.columns.find_children("*", "GridContainer", true, false)[1].get_child_count() == 15, "The cabinet displays 15 usable slots after the first expansion")
	var part: Dictionary = workshop.ledger.make_part("cooling", "Reserva", 90, "floor")
	workshop.ledger.state.items[part.id] = part
	check(workshop.ledger.move(part.id, "shelf") and workshop.ledger.arrange_storage(part.id, "shelf", 14), "Transfers can use slots above the original capacity")
	check(not workshop.ledger.arrange_storage(part.id, "shelf", 15), "Slots in the next expansion are still unavailable")
	var tampered: Dictionary = workshop.ledger.state.duplicate(true)
	tampered.transactions.back().amount -= 1
	tampered.credits -= 1
	check(not workshop.ledger.valid(tampered), "The upgrade cost is validated independently of the final balance")
	if not press_button(ui, "BuyShelfExpansion"): return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://workshop-expansion.png")
	ui._expansion_confirmation.get_ok_button().pressed.emit()
	check(workshop.ledger.shelf_capacity() == 24 and workshop.ledger.state.credits == before - 950, "The second expansion charges its own price and adds nine slots")
	check(ui.columns.find_children("*", "GridContainer", true, false)[1].get_child_count() == 24 and not ui._expand_button.visible, "The full expansion shows 24 slots and completes the purchase path")
	check(workshop.ledger.arrange_storage(part.id, "shelf", 23), "The last expanded slot accepts a physical part")
	check(workshop.load_game(), "The autosave restores both cabinet expansions")
	check(workshop.ledger.shelf_capacity() == 24 and workshop.ledger.item(part.id).shelf_slot == 23, "The part remains in its expanded slot after loading")
	check(Orders.completed_count(workshop.ledger.state) == Orders.completed_count(model.state), "Delivery progression also survives the save and load")
	world.queue_free()
	await frames()

func run() -> void:
	TranslationServer.set_locale("pt")
	root.size = Vector2i(1360, 768)
	var fresh := preload("res://Scenes/World/World.tscn").instantiate()
	var fresh_workshop: Node = fresh.get_node("PhysicalWorkshop")
	fresh_workshop.save_path = ""
	root.add_child(fresh)
	await frames()
	check(fresh_workshop.ledger.state.items.is_empty(), "New workshop starts without a starter computer or package")
	check(Orders.orders(fresh_workshop.ledger, "offered").size() == 3, "New workshop has customer orders available")
	var first := Orders.guided_order(fresh_workshop.ledger)
	var fresh_guide: Node = fresh_workshop.get_node("FirstServiceGuide")
	check(first.get("kind") == "ram" and "WASD" in fresh_guide._hint.text and fresh_guide._target.is_finite(), "New players see a marked route to a guided RAM job")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://first-service-workshop.png")
	TranslationServer.set_locale("en")
	await frames()
	check("marked counter" in fresh_guide._hint.text, "The active guide updates when the game language changes")
	TranslationServer.set_locale("pt")
	check(Orders.decline(fresh_workshop.ledger, first.id), "The player can decline the guided proposal")
	await frames()
	check(not fresh_guide._panel.visible and Orders.orders(fresh_workshop.ledger, "offered").size() == 2, "Declining retires the guide and leaves other proposals available")
	fresh.queue_free()
	await frames()
	verify_previous_orders()
	seed(42017)
	var model := Ledger.new()
	model.new_game(false)
	Orders.ensure(model)
	check(Orders.orders(model, "offered").all(func(order: Dictionary) -> bool: return order.kind in Orders.BASIC_JOBS), "New players receive only basic services")
	check(not model.buy_shelf_expansion("shelf_15") and model.state.credits == 500, "The first shelf expansion needs completed deliveries")
	var seen: Array = []
	for round in range(16):
		if Orders.orders(model, "offered").is_empty(): Orders.tick(model, 45)
		var order: Dictionary = Orders.orders(model, "offered")[0]
		check(order.kind in Orders.unlocked_jobs(round), "Draws only from categories unlocked by actual deliveries")
		seen.append(order.kind)
		if order.kind == "gpu": order.report = Orders.GPU_ARTIFACT_REPORT
		check(Orders.accept(model, order.id), "Offer accepted")
		if order.kind == "gpu":
			var customer_pc := model.item(order.pc_id)
			check(model.gpu_output(model.item(customer_pc.components.gpu)) == "artifacts", "A report of colored blocks creates a real artifact fault")
		check(not Orders.accept(model, order.id), "Duplicate reception rejected")
		check(not Orders.deliver(model, order.id), "Unrepaired job rejected")
		check(model.valid(model.state), "Accepted service and deposit pass save validation")
		for part_id in model.at("tray"): model.move(part_id, "floor")
		repair(model, order)
		var balance: int = model.state.credits
		check(Orders.deliver(model, order.id), "Completed job delivered")
		check(model.state.credits == balance+order.reward-order.deposit, "Only outstanding payment credited")
		check(not Orders.deliver(model, order.id), "Cannot collect payment twice")
		check(not model.move(order.pc_id, "floor"), "Returned computer cannot be reclaimed")
		check(model.valid(model.state), "Delivered PC and payment remain valid")
		var restored: Dictionary = JSON.parse_string(JSON.stringify(model.state))
		check(model.valid(restored), "Service state survives JSON round trip")
		if round + 1 == Orders.INTERMEDIATE_DELIVERIES:
			check(Orders.orders(model, "offered").any(func(proposal: Dictionary) -> bool: return proposal.kind in ["psu", "gpu"]), "Two completed jobs immediately introduce intermediate jobs to free slots")
			verify_reserved_budget(model)
		if round + 1 == Orders.ADVANCED_DELIVERIES:
			check(Orders.orders(model, "offered").any(func(proposal: Dictionary) -> bool: return proposal.kind in ["diagnosis", "ram_gpu"]), "Five completed jobs immediately introduce advanced jobs to free slots")
	check(Orders.JOBS.keys().all(func(kind: String) -> bool: return kind in seen), "All seven service categories appear over a career")
	check(Orders.next_milestone(Orders.completed_count(model.state)).is_empty(), "The fifth delivery completes service unlock progression")
	await verify_shelf_expansions(model)
	for proposal in Orders.orders(model, "offered"): Orders.decline(model, proposal.id)
	model.state.services.bag.clear()
	var last_kind := ""
	for cycle in range(2):
		var kinds: Array = []
		for index in range(Orders.JOBS.size()):
			Orders.tick(model, 45)
			var proposal: Dictionary = Orders.orders(model, "offered")[0]
			check(proposal.kind != last_kind and proposal.kind not in kinds, "Full rotation avoids repeated jobs across and within draw cycles")
			last_kind = proposal.kind
			kinds.append(proposal.kind)
			Orders.decline(model, proposal.id)
	var capped := Ledger.new()
	capped.new_game(false)
	Orders.ensure(capped)
	for order in Orders.orders(capped, "offered"): check(Orders.accept(capped, order.id), "Queue receives up to three PCs")
	Orders.tick(capped, 45)
	var extra: Dictionary = Orders.orders(capped, "offered")[0]
	var count: int = capped.state.items.size()
	check(not Orders.accept(capped, extra.id) and capped.state.items.size() == count, "Full queue rejects new PC without duplicating items")
	var active: Array = Orders.orders(capped, "active")
	check(Orders.prioritize(capped, active[2].id) and active[2].priority < active[0].priority, "Queue priority can be changed")
	check(capped.valid(capped.state), "Three active jobs retain unique ownership and valid balance")
	var bad: Dictionary = capped.state.duplicate(true)
	bad.credits += 1
	check(not capped.valid(bad), "Unaccounted service money is rejected")
	var legacy: Dictionary = capped.state.duplicate(true)
	legacy.erase("services")
	legacy.items.clear()
	legacy.credits = 500
	check(capped.valid(legacy), "Pre-service saves remain supported")
	check(Orders.guided_order(capped).is_empty(), "Existing non-guided orders do not acquire a guide")
	var world: Node2D = preload("res://Tools/test_world.gd").create(false)
	var workshop: Node = world.get_node("PhysicalWorkshop")
	workshop.save_path = ""
	root.add_child(world)
	await frames()
	await key(KEY_O)
	check(workshop.orders_ui.is_open and paused, "O opens order board and pauses gameplay")
	var board: Node = workshop.orders_ui.board
	check("2 entregas" in board._progress.text, "The order board displays the next milestone")
	var offered: Dictionary = Orders.orders(workshop.ledger, "offered")[0]
	check(board.find_child("Accept_"+offered.id, true, false).disabled, "Remote acceptance disabled")
	workshop.orders_ui.close_menu()
	workshop.player.global_position = Vector2(15, 230)
	await frames()
	check(workshop._near_counter(), "Counter reachable from customer side")
	await key(KEY_F)
	check(workshop.orders_ui.is_open, "F opens customer reception at counter")
	board.find_child("Accept_"+offered.id, true, false).pressed.emit()
	await frames()
	check(offered.status == "active" and workshop.actors.has(offered.pc_id), "Accept creates a visible physical cabinet")
	check(workshop.ledger.item(offered.pc_id).location == "counter" and workshop.actors[offered.pc_id].get_parent() == workshop.counter, "Customer computer appears on the service counter")
	check(board._filter.selected == 1, "Reception switches to active queue")
	workshop.orders_ui.close_menu()
	workshop.save_path = "res://.godot/service-order-test.json"
	check(workshop.save_game(false), "Real workshop saves active order")
	check(workshop.load_game(), "Real workshop restores service save")
	check(Orders.orders(workshop.ledger, "active").size() == 1 and workshop.actors.has(offered.pc_id), "Restored customer keeps same physical machine")
	var waiting_pc: Dictionary = workshop.ledger.item(offered.pc_id)
	waiting_pc.location = "floor"
	waiting_pc.position = [190, 105]
	waiting_pc.erase("counter_slot")
	var loose_ram: Dictionary = workshop.ledger.make_part("ram", "TR Memory 8 GB DDR5", 96, "floor")
	loose_ram.ddr = "DDR5"
	loose_ram.origin = "receiving"
	loose_ram.position = [285, 80]
	workshop.ledger.state.items[loose_ram.id] = loose_ram
	check(workshop.save_game(false) and workshop.load_game(), "Legacy reception layout can still be loaded")
	check(workshop.ledger.item(offered.pc_id).location == "counter", "Legacy waiting cabinet is moved to the counter")
	check(workshop.ledger.item(loose_ram.id).location == "shelf" and not workshop.actors.has(loose_ram.id), "Legacy loose RAM is stored without losing the item")
	workshop.player.global_position = Vector2(-73, 186)
	await frames()
	check("E — Pegar gabinete" in workshop._prompt(), "Counter pickup prompt remains available from the front")
	workshop.player.global_position = workshop.counter.to_global(Vector2(0, -91))
	await frames()
	check("E — Pegar gabinete" in workshop._prompt(), "Counter pickup is offered from behind the counter")
	await key(KEY_E)
	check(workshop.ledger.carried() == offered.pc_id, "E picks up the cabinet from behind the counter")
	if "--capture" in OS.get_cmdline_user_args():
		workshop.orders_ui.open_menu()
		await frames()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/service-orders.png")
		workshop.orders_ui.close_menu()
	var restored_order: Dictionary = Orders.get_order(workshop.ledger, offered.id)
	await finish_guided_job(workshop, restored_order)
	check(not workshop.actors.has(restored_order.pc_id), "Delivered computer leaves the visible workshop")
	check(workshop.load_game(), "Auto-save restores completed delivery")
	check(Orders.get_order(workshop.ledger, offered.id).status == "delivered" and not workshop.actors.has(offered.pc_id), "Delivered machine does not respawn after loading")
	await frames()
	check(not workshop.get_node("FirstServiceGuide")._panel.visible, "Completed tutorial stays dismissed after restoring the save")
	print("SERVICE ORDER CHECKS: ", checks, "; failures: ", failures)
	await create_timer(0.3).timeout
	quit(1 if failures else 0)

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

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await frames()

func run() -> void:
	var fresh := preload("res://Scenes/World/World.tscn").instantiate()
	var fresh_workshop: Node = fresh.get_node("PhysicalWorkshop")
	fresh_workshop.save_path = ""
	root.add_child(fresh)
	await frames()
	check(fresh_workshop.ledger.state.items.is_empty(), "New workshop starts without a starter computer or package")
	check(Orders.orders(fresh_workshop.ledger, "offered").size() == 3, "New workshop has customer orders available")
	fresh.queue_free()
	await frames()
	var seen: Array = []
	var last_kind := ""
	for round in range(14):
		# Keep one persistent generation stream, resetting physical clutter separately.
		if round == 0: seed(42017)
		var model := Ledger.new()
		model.new_game(false)
		if round > 0: model.state.services = _generation.duplicate(true)
		Orders.ensure(model)
		if Orders.orders(model, "offered").is_empty(): Orders.tick(model, 45)
		var order: Dictionary = Orders.orders(model, "offered")[0]
		var pending: Array = Orders.orders(model, "offered").filter(func(entry: Dictionary) -> bool: return entry.id != order.id)
		check(order.kind != last_kind, "Consecutive customer jobs differ")
		last_kind = order.kind
		seen.append(order.kind)
		# Isolate prior history because this round exercises a new physical ledger.
		model.state.services.orders = [order]
		if order.kind == "gpu": order.report = Orders.GPU_ARTIFACT_REPORT
		check(Orders.accept(model, order.id), "Offer accepted")
		if order.kind == "gpu":
			var customer_pc := model.item(order.pc_id)
			check(model.gpu_output(model.item(customer_pc.components.gpu)) == "artifacts", "A report of colored blocks creates a real artifact fault")
		check(not Orders.accept(model, order.id), "Duplicate reception rejected")
		check(not Orders.deliver(model, order.id), "Unrepaired job rejected")
		check(model.valid(model.state), "Accepted service and deposit pass save validation")
		repair(model, order)
		var balance: int = model.state.credits
		check(Orders.deliver(model, order.id), "Completed job delivered")
		check(model.state.credits == balance+order.reward-order.deposit, "Only outstanding payment credited")
		check(not Orders.deliver(model, order.id), "Cannot collect payment twice")
		check(not model.move(order.pc_id, "floor"), "Returned computer cannot be reclaimed")
		check(model.valid(model.state), "Delivered PC and payment remain valid")
		var restored: Dictionary = JSON.parse_string(JSON.stringify(model.state))
		check(model.valid(restored), "Service state survives JSON round trip")
		_generation = model.state.services.duplicate(true)
		_generation.orders = pending.duplicate(true)
	check(seen.size() == 14 and Orders.JOBS.keys().all(func(kind: String) -> bool: return kind in seen), "All seven service categories appear")
	for start in [0, 7]:
		check(Orders.JOBS.keys().all(func(kind: String) -> bool: return kind in seen.slice(start, start+7)), "Each seven-job cycle includes every service once")
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
	var world: Node2D = preload("res://Tools/test_world.gd").create(false)
	var workshop: Node = world.get_node("PhysicalWorkshop")
	workshop.save_path = ""
	root.add_child(world)
	await frames()
	await key(KEY_O)
	check(workshop.orders_ui.is_open and paused, "O opens order board and pauses gameplay")
	var board: Node = workshop.orders_ui.board
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
	var loose_ram: Dictionary = workshop.ledger.make_part("ram", "TR Memory 8 GB DDR4", 96, "floor")
	loose_ram.ddr = "DDR4"
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
	repair(workshop.ledger, restored_order)
	check(Orders.deliver(workshop.ledger, restored_order.id), "Live workshop completes physical service")
	check(not workshop.actors.has(restored_order.pc_id), "Delivered computer leaves the visible workshop")
	check(workshop.load_game(), "Auto-save restores completed delivery")
	check(Orders.get_order(workshop.ledger, offered.id).status == "delivered" and not workshop.actors.has(offered.pc_id), "Delivered machine does not respawn after loading")
	print("SERVICE ORDER CHECKS: ", checks, "; failures: ", failures)
	await create_timer(0.3).timeout
	quit(1 if failures else 0)

var _generation: Dictionary = {}

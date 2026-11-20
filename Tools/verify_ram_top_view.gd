extends SceneTree

const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")

var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1360, 768)
	var world: Node2D = preload("res://Tools/test_world.gd").create(true)
	var workshop: Node = world.get_node("PhysicalWorkshop")
	workshop.save_path = ""
	root.add_child(world)
	for i in range(4): await process_frame
	var pc_id: String
	for record in workshop.ledger.state.items.values():
		if record.kind == "pc": pc_id = record.id
	workshop.ledger.move(pc_id, "bench")
	var pc: Dictionary = workshop.ledger.item(pc_id)
	pc.lid = false
	pc.screws = [false, false, false, false]
	workshop.bench_ui.open_bench()
	workshop.bench_ui.open_inspection()
	var canvas: Control = workshop.bench_ui.inspection.canvas
	for i in range(4): await process_frame
	check(canvas.layers.ram.get_size() == Vector2(48, 312), "Original top spine texture has detailed 6x resolution")
	check(is_equal_approx(canvas.RAM_INSTALLED.get_center().x, canvas.LATCHES[0].x), "Installed module is centered between retaining clips")
	check(canvas.RAM_SLOT.encloses(canvas.RAM_INSTALLED), "Installed RAM fits completely inside socket hit area")
	check(workshop.ledger.ram_slots(pc_id) == [0, 2, 1, 3], "AX550 has four positions in physical order")
	for slot in range(4):
		var offset: Vector2 = canvas.RAM_OFFSETS[slot]
		check(canvas.hit_at(canvas.RAM_INSTALLED.get_center()+offset) == StringName(Hardware.RAM_KEYS[slot]), "Module center selects the correct position")
		for i in range(2):
			check(canvas.hit_at(canvas.LATCHES[i]+offset) == StringName("%s_latch_%d" % [Hardware.RAM_KEYS[slot], i]), "Each retaining clip remains separately selectable")
	for slot in [1, 2, 3]:
		check(workshop.ledger.purchase("DDR4"), "Buy an additional module through the ledger")
		var module_id: String = workshop.ledger.state.transactions.back().item_id
		workshop.ledger.tick(3.1)
		check(workshop.ledger.unpack(module_id) and workshop.ledger.move(module_id, "tray"), "Move the delivered module to the bench tray")
		workshop.selected_ram = module_id
		_interact_slot(canvas, slot)
		check(pc.components.get(Hardware.RAM_KEYS[slot]) == module_id, "The inspection installs the selected module in its own slot")
	check(workshop.ledger.ram_modules(pc).size() == 4, "The inspection fits four modules in the AX550")
	canvas.session.interact_with(canvas.hit_at(canvas.LATCHES[0] + canvas.RAM_OFFSETS[3]))
	workshop.bench_ui.exit_inspection()
	check(workshop.bench_ui.open_inspection(), "Reopen inspection of the same equipment")
	check(workshop.ledger.ram_latches(pc_id, 3) == [false, true], "B2 retains its clip state when the bench is reopened")
	canvas.session.interact_with(canvas.hit_at(canvas.LATCHES[0] + canvas.RAM_OFFSETS[3]))
	if "--capture" in OS.get_cmdline_user_args():
		canvas.zoom = 1.8
		canvas.pan = (canvas.FIT_BOUNDS.get_center()-Vector2(158,77))*canvas.art_scale()
		canvas.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/ram-top-view.png")
	for slot in [1, 2, 3]:
		_interact_slot(canvas, slot)
		check(not pc.components.has(Hardware.RAM_KEYS[slot]), "The inspection removes each additional module without duplication")
	var board: Dictionary = workshop.ledger.item(pc.components.motherboard)
	board.merge(Hardware.BOARDS[0], true)
	check(workshop.ledger.ram_slots(pc_id) == [0, 1], "A320M exposes only A1 and B1")
	for slot in range(4):
		var offset: Vector2 = canvas.RAM_OFFSETS[slot]
		var hit: StringName = canvas.hit_at(canvas.RAM_INSTALLED.get_center() + offset)
		check((str(hit) in Hardware.RAM_KEYS) == (slot < 2), "The two-slot board has only two interactive socket centers")
		for clip in canvas.LATCHES:
			hit = canvas.hit_at(clip + offset)
			check(str(hit).contains("_latch_") == (slot < 2), "The two-slot board has only its physical retaining clips")
	workshop.bench_ui.close_bench()
	print("RAM TOP VIEW CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)


func _interact_slot(canvas: Control, slot: int) -> void:
	var offset: Vector2 = canvas.RAM_OFFSETS[slot]
	for clip in canvas.LATCHES:
		canvas.session.interact_with(canvas.hit_at(clip + offset))
	canvas.session.interact_with(canvas.hit_at(canvas.RAM_INSTALLED.get_center() + offset))
	for clip in canvas.LATCHES:
		canvas.session.interact_with(canvas.hit_at(clip + offset))

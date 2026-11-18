extends SceneTree

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
	for slot in range(2):
		var offset: Vector2 = canvas.RAM_SLOT_SPACING * slot
		check(canvas.hit_at(canvas.RAM_INSTALLED.get_center()+offset) == (&"ram" if slot == 0 else &"ram2"), "Module center selects correct memory channel")
		for i in range(2):
			check(canvas.hit_at(canvas.LATCHES[i]+offset) == StringName(("ram_latch_" if slot == 0 else "ram2_latch_")+str(i)), "Each retaining clip remains separately selectable")
	if "--capture" in OS.get_cmdline_user_args():
		canvas.zoom = 1.8
		canvas.pan = (canvas.FIT_BOUNDS.get_center()-Vector2(158,77))*canvas.art_scale()
		canvas.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/ram-top-view.png")
	workshop.bench_ui.close_bench()
	print("RAM TOP VIEW CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)

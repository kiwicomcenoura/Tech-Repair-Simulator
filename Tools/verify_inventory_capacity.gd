extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)

func frames() -> void:
	for i in range(3): await process_frame

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await frames()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world: Node2D = preload("res://Tools/test_world.gd").create(true)
	var workshop: Node = world.get_node("PhysicalWorkshop")
	workshop.save_path = ""
	root.add_child(world)
	await frames()
	var ui: CanvasLayer = workshop.storage_ui
	var model: RefCounted = workshop.ledger
	await key(KEY_I)
	check(ui.is_open and not ui.shelf_access and paused, "I opens only personal inventory")
	check(ui.columns.get_child_count() == 1, "No duplicate organization or shelf column")
	check(ui.columns.find_children("*", "GridContainer", true, false)[0].get_child_count() == 3, "Inventory displays exactly three slots")
	await key(KEY_I)
	check(not ui.is_open and not paused, "I closes inventory")
	var spare: Dictionary
	for item in model.state.items.values():
		if item.kind == "ram" and item.location == "floor": spare = item.duplicate(true)
	for i in range(4):
		var record: Dictionary = spare.duplicate(true)
		record.id = "capacity_test_" + str(i)
		model.state.items[record.id] = record
		check(model.move(record.id, "inventory") == (i < 3), "Inventory enforces capacity for item " + str(i))
	check(not model.arrange_storage("capacity_test_0", "inventory", 3), "Fourth slot cannot be used by dragging")
	check(model.arrange_storage("capacity_test_0", "inventory", 0), "Existing item remains organizable in full inventory")
	world.get_node("Actors/Player").global_position = Vector2(-250, -5)
	await key(KEY_F)
	check(ui.shelf_access and ui.columns.get_child_count() == 2, "F at shelf opens inventory and cabinet")
	var grids: Array = ui.columns.find_children("*", "GridContainer", true, false)
	check(grids[0].get_child_count() == 3 and grids[1].get_child_count() == 9, "Cabinet retains nine slots alongside three inventory slots")
	ui.close_storage()
	var legacy: Dictionary = model.state.duplicate(true)
	for i in range(4, 12):
		var record: Dictionary = spare.duplicate(true)
		record.id = "legacy_" + str(i)
		record.location = "inventory"
		record.inventory_slot = i
		legacy.items[record.id] = record
	legacy.items.capacity_test_0.inventory_slot = 11
	check(model.valid(legacy, 12) and not model.valid(legacy), "Legacy save exceeds new capacity")
	workshop.save_path = "res://.godot/inventory-capacity-test.json"
	var file := FileAccess.open(workshop.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(workshop.load_game(), "Legacy save loads without losing items")
	check(model.at("inventory").size() == 3 and model.state.items.size() == legacy.items.size(), "Migration preserves every item and keeps three inventory units")
	check(model.valid(model.state), "Migrated state has valid locations and capacity")
	ui.open_storage(false)
	check(ui.columns.find_children("*", "GridContainer", true, false)[0].get_child_count() == 3, "Legacy slots are remapped into visible inventory")
	print("INVENTORY CAPACITY CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)

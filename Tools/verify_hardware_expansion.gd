extends SceneTree

const Ledger := preload("res://Scripts/Gameplay/workshop_ledger.gd")
const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")
const Visuals := preload("res://Scripts/UI/part_visuals.gd")
const Art := preload("res://Scripts/UI/hardware_art.gd")
const WorldFixture := preload("res://Tools/test_world.gd")

const COMPATIBILITY := {
	"amdera_a320m": "amdera_r3_1200 amdera_r5_1600 amdera_r3_3100 amdera_r5_3600 amdera_r5_5600",
	"amdera_b450m": "amdera_r3_1200 amdera_r5_1600 amdera_r3_3100 amdera_r5_3600 amdera_r5_5600 amdera_r7_5800x",
	"amdera_ax550": "amdera_r3_3100 amdera_r5_3600 amdera_r5_5600 amdera_r7_5800x",
	"amdera_b550_pro": "amdera_r3_3100 amdera_r5_3600 amdera_r5_5600 amdera_r7_5800x",
	"amdera_x570_elite": "amdera_r3_3100 amdera_r5_3600 amdera_r5_5600 amdera_r7_5800x",
	"amdera_a620m": "amdera_r5_7600 amdera_r7_7700 amdera_r7_9700x",
	"amdera_b650_gaming": "amdera_r5_7600 amdera_r7_7700 amdera_r7_9700x",
	"amdera_x670_elite": "amdera_r5_7600 amdera_r7_7700 amdera_r7_9700x",
	"intara_h61_classic": "intara_i3_3220 intara_i5_3470 intara_i7_3770",
	"intara_b75m": "intara_i3_3220 intara_i5_3470 intara_i7_3770",
	"intara_h110m": "intara_i5_6500",
	"intara_b360m": "intara_i5_9400f",
	"intara_h510m": "intara_i5_10400 intara_i5_11400",
	"intara_ix610": "intara_i3_12100f intara_i5_12400f intara_i7_12700k intara_i5_13400f",
	"intara_b660m": "intara_i3_12100f intara_i5_12400f intara_i7_12700k intara_i5_13400f",
	"intara_z790_ultra": "intara_i3_12100f intara_i5_12400f intara_i7_12700k intara_i5_13400f",
}

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)


func _run() -> void:
	var world := WorldFixture.create()
	root.add_child(world)
	var workshop := world.get_node("PhysicalWorkshop")
	var ledger: RefCounted = workshop.ledger
	var shop: Control = preload("res://Scripts/Gameplay/techmarket.gd").new()
	shop.workshop = workshop
	shop.sidebar = PanelContainer.new()
	var sidebar_content := Control.new()
	sidebar_content.name = "Content"
	shop.sidebar.add_child(sidebar_content)
	world.add_child(shop.sidebar)
	world.add_child(shop)
	check(Ledger.CATALOG.size() == shop._buttons.size(), "Each catalog key appears exactly once")
	shop._filter("motherboard")
	check(_visible_products(shop) == 16, "TechMarket shows all 16 motherboards")
	var artwork: Array = []
	for board in Hardware.BOARDS:
		check(shop._buttons[board.key].visible, "Board is visible: " + board.key)
		var supported: PackedStringArray = COMPATIBILITY[board.key].split(" ")
		for cpu in Hardware.CPUS:
			check(Hardware.cpu_reason(board, cpu).is_empty() == (cpu.key in supported), "%s / %s compatibility" % [board.key, cpu.key])
		var image := Visuals.board_artwork(board).get_image()
		var pixels := image.get_data()
		check(pixels not in artwork, "Distinct artwork: " + board.key)
		artwork.append(pixels)
		var seat := Visuals.board_cpu_seat(board)
		var contact := image.get_pixelv(seat.position + Vector2i(4, 4)).to_html(false)
		check(contact == ("282a25" if board.socket == "AM4" else "dec18a"), "Empty socket shows the right contact style: " + board.key)
	shop._filter("cpu")
	artwork.clear()
	for cpu in Hardware.CPUS:
		check(shop._buttons[cpu.key].visible, "CPU is visible: " + cpu.key)
		var top := Visuals.cpu_artwork(cpu).get_image()
		check(top.get_data() not in artwork, "CPU has a distinct top-face sprite: " + cpu.key)
		artwork.append(top.get_data())
		var back := Art.processor(cpu, cpu.model, true)
		var contact := back.get_pixel(5, 5).to_html(false)
		check(contact == ("f8d38a" if cpu.socket == "AM4" else "ead293"), "CPU underside shows pins or flat pads: " + cpu.key)
		check(Visuals.cpu_artwork(cpu, true).get_width() > 2 * top.get_width(), "Store preview includes both sides: " + cpu.key)
		if cpu.model.ends_with("F"): check(not Hardware.has_integrated_graphics(cpu), "F model needs a graphics card")
	shop._search.text = "LGA1151"
	shop._apply_filter()
	check(_visible_products(shop) == 2 and shop._buttons.intara_i5_6500.visible and shop._buttons.intara_i5_9400f.visible, "Both LGA1151 generations are searchable")
	shop._search.clear()
	shop._filter("motherboard")
	_select_filter(shop, "ddr", "DDR5")
	_select_filter(shop, "slot_count", 4)
	check(_visible_products(shop) == 3 and shop._buttons.intara_z790_ultra.visible, "Dropdown filters combine DDR generation and slot count")
	_select_filter(shop, "price", 1450)
	check(_visible_products(shop) == 1 and shop._buttons.intara_z790_ultra.visible, "Price filter combines with other filters")

	artwork.clear()
	for entry in Ledger.CATALOG:
		if entry.key not in ["ddr3_4", "ddr3_8", "ddr5_48", "amdera_compact_92", "intara_legacy_90"]: continue
		var pixels := Visuals.icon(entry).get_image().get_data()
		check(pixels not in artwork, "Individual memory or cooler artwork: " + entry.key)
		artwork.append(pixels)

	_test_four_slots(workshop)
	_test_two_slots(ledger)
	_test_video(ledger)
	_test_legacy(ledger)
	world.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("HARDWARE EXPANSION CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)


func _visible_products(shop: Control) -> int:
	return shop._buttons.values().filter(func(button: Button) -> bool: return button.visible).size()


func _select_filter(shop: Control, field: String, value: Variant) -> void:
	var dropdown: OptionButton = shop._filters[field]
	for index in range(1, dropdown.item_count):
		if dropdown.get_item_metadata(index) != value: continue
		dropdown.select(index)
		dropdown.item_selected.emit(index)
		return
	check(false, "Filter value exists for " + field)


func _reset(ledger: RefCounted) -> void:
	ledger.new_game()
	ledger.state.balance_adjustment = 10000
	ledger.state.credits += 10000


func _buy(ledger: RefCounted, key: String, destination: String = "tray") -> Dictionary:
	var before: int = ledger.state.items.size()
	check(ledger.purchase(key), "Purchase succeeds: " + key)
	if ledger.state.items.size() == before: return {}
	var part: Dictionary = ledger.item(ledger.state.transactions.back().item_id)
	check(ledger.state.items.size() == before + 1 and part.location == "delivery" and part.packaged, "Purchase queues one physical package")
	ledger.tick(3.1)
	check(part.location == "floor" and ledger.unpack(part.id), "Package arrives and can be unpacked")
	check(ledger.move(part.id, destination), "Purchased item moves through the existing inventory")
	return part


func _open_case(ledger: RefCounted, key: String) -> Dictionary:
	var pc := _buy(ledger, key, "bench")
	pc.lid = false
	pc.screws = [false, false, false, false]
	return pc


func _install_ram(ledger: RefCounted, pc: Dictionary, module: Dictionary, slot: int) -> void:
	for clip in range(2):
		check(ledger.toggle_latch(pc.id, clip, slot), "Open the requested clip")
	check(ledger.use_ram_slot(pc.id, module.id, slot), "Install module in an open slot")
	for clip in range(2):
		check(ledger.toggle_latch(pc.id, clip, slot), "Close the requested clip")


func _test_four_slots(workshop: Node) -> void:
	var ledger: RefCounted = workshop.ledger
	_reset(ledger)
	var pc := _open_case(ledger, "amdera_core_200")
	var board := _buy(ledger, "amdera_b550_pro")
	check(ledger.use_component(pc.id, "motherboard", board.id), "Mount ATX board")
	var cpu := _buy(ledger, "amdera_r5_5600")
	check(ledger.use_component(pc.id, "cpu", cpu.id), "Mount compatible AM4 CPU")
	var base := _buy(ledger, "DDR4")
	_install_ram(ledger, pc, base, 0)
	var single: Dictionary = ledger.memory_profile(pc.id)
	check(single.mode == "Single Channel", "One module uses Single Channel")
	_install_ram(ledger, pc, _buy(ledger, "ddr4_16", "inventory"), 2)
	check(ledger.memory_profile(pc.id).mode == "Single Channel", "A1 and A2 share a channel")
	_install_ram(ledger, pc, _buy(ledger, "DDR4"), 1)
	var mixed: Dictionary = ledger.memory_profile(pc.id)
	check(mixed.total_gb == 32 and mixed.dual_gb == 16 and mixed.speed_mt == 2666, "Three unequal modules use asymmetric dual channel at a common speed")
	check(mixed.performance > single.performance, "The active second channel increases estimated performance")
	_install_ram(ledger, pc, _buy(ledger, "ddr4_16"), 3)
	var profile: Dictionary = ledger.memory_profile(pc.id)
	check(profile.total_gb == 48 and profile.dual_gb == 48 and profile.mode == "Dual Channel", "Four modules use both complete channels")
	var ids: Array = pc.components.values()
	check(ids.size() == 6 and ids.size() == ids.duplicate().filter(func(id: String) -> bool: return ids.count(id) == 1).size(), "Each physical module is installed once")
	check(ledger.toggle_latch(pc.id, 0, 3), "Open B2 on the assembled PC")
	check("B2" in ledger.ram_configuration_reason(pc.id), "POST identifies the exact unlocked slot")
	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(ledger.state))
	check(ledger.valid(reloaded), "Four slots with independent latches validate after serialization")
	var duplicate := reloaded.duplicate(true)
	duplicate.items[pc.id].components.ram4 = base.id
	check(not ledger.valid(duplicate), "Save rejects one unit occupying two positions")
	var save_path := "res://.godot/hardware-expansion-%d.json" % OS.get_process_id()
	workshop.save_path = save_path
	check(workshop.save_game(false), "The normal workshop save writes the four-slot build")
	ledger.new_game()
	check(workshop.load_game(), "The normal workshop load restores the four-slot build")
	workshop.save_path = ""
	DirAccess.remove_absolute(save_path)
	check(ledger.ram_modules(ledger.item(pc.id)).size() == 4, "All four purchased modules survive loading")
	check(ledger.ram_latches(pc.id, 3) == [false, true], "B2 retains its independent latch state after loading")
	for slot in [0, 1, 2]:
		check(ledger.ram_latches(pc.id, slot) == [true, true], "Other slots remain locked")
	ledger.item(pc.id).power = true
	check(not ledger.toggle_latch(pc.id, 1, 3) and not ledger.use_ram_slot(pc.id, "", 3), "Powered PC prevents opening or removing RAM")


func _test_two_slots(ledger: RefCounted) -> void:
	_reset(ledger)
	var pc := _open_case(ledger, "intara_m100")
	var atx := _buy(ledger, "amdera_ax550")
	check(not ledger.use_component(pc.id, "motherboard", atx.id), "ATX board is rejected by the Micro-ATX-only case")
	var board := _buy(ledger, "intara_h61_classic")
	check(ledger.use_component(pc.id, "motherboard", board.id), "Micro-ATX board fits")
	check(ledger.ram_slots(pc.id).size() == 2 and not ledger.toggle_latch(pc.id, 0, 2), "No third slot or third retaining clip")
	var ddr4 := _buy(ledger, "DDR4")
	for clip in range(2): ledger.toggle_latch(pc.id, clip)
	check(not ledger.use_ram_slot(pc.id, ddr4.id) and ddr4.location == "tray", "DDR4 cannot be installed in DDR3")
	var excessive := {"ddr": "DDR3", "capacity_gb": 16}
	check("8 GB por módulo" in Hardware.memory_reason(board, {}, [excessive]), "Individual DIMM limit is enforced")
	check(not Hardware.memory_reason(board, {}, [excessive, excessive, excessive]).is_empty(), "Too many DIMMs are rejected")
	var ddr3 := _buy(ledger, "ddr3_8", "inventory")
	check(ledger.use_ram_slot(pc.id, ddr3.id), "DDR3 installs from inventory")
	for clip in range(2): ledger.toggle_latch(pc.id, clip)
	_install_ram(ledger, pc, _buy(ledger, "ddr3_8"), 1)
	check(ledger.memory_profile(pc.id).total_gb == 16 and ledger.memory_profile(pc.id).mode == "Dual Channel", "Two-slot board reaches its 16 GB limit in Dual Channel")
	var high_capacity: Dictionary = Hardware.BOARDS.filter(func(entry: Dictionary) -> bool: return entry.key == "intara_z790_ultra")[0]
	var controller: Dictionary = Hardware.CPUS.filter(func(entry: Dictionary) -> bool: return entry.key == "intara_i7_12700k")[0]
	var dimm := {"ddr": "DDR5", "capacity_gb": 48}
	check("128 GB" in Hardware.memory_reason(high_capacity, controller, [dimm, dimm, dimm]), "Three DIMMs can exceed the CPU controller limit")


func _test_video(ledger: RefCounted) -> void:
	_reset(ledger)
	var pc := _open_case(ledger, "intara_m100")
	var board := _buy(ledger, "intara_ix610")
	check(board.ddr == "DDR4" and ledger.use_component(pc.id, "motherboard", board.id), "New IX610 correctly uses DDR4")
	var cpu := _buy(ledger, "intara_i3_12100f")
	check(ledger.use_component(pc.id, "cpu", cpu.id), "Install an F-suffix processor")
	var tall := _buy(ledger, "intara_breeze_120")
	check(not ledger.use_component(pc.id, "cooling", tall.id), "A cooler exceeding the case clearance is rejected")
	var parts := {"cooling": "intara_breeze_92", "storage": "storage", "psu": "psu"}
	for kind in parts:
		check(ledger.use_component(pc.id, kind, _buy(ledger, parts[kind]).id), "Install essential component: " + kind)
	_install_ram(ledger, pc, _buy(ledger, "DDR4"), 0)
	for kind in pc.components:
		if kind in Hardware.RAM_KEYS: continue
		var mount: Dictionary = ledger.mounts(pc.id, kind)
		mount.screws.fill(true)
		for connector in mount.connections: mount.connections[connector] = true
	check("GPU dedicada" in ledger.assembly_power_block_reason(pc.id), "F series requires a dedicated GPU to start")
	ledger.item(pc.components.storage).bootable = true
	check(ledger.use_component(pc.id, "gpu", _buy(ledger, "gpu").id), "Install the required graphics card")
	var gpu_mount: Dictionary = ledger.mounts(pc.id, "gpu")
	gpu_mount.screws.fill(true)
	for connector in gpu_mount.connections: gpu_mount.connections[connector] = true
	check(ledger.request_post(pc.id), "POST starts after the dedicated video card is mounted")
	ledger.tick(1.3)
	check(pc.boot_ok and ledger.video_status(pc.id) == "desktop", "Dedicated graphics produce a booted desktop")
	check(ledger.toggle_power(pc.id), "Power off before changing video hardware")
	for connector in gpu_mount.connections: gpu_mount.connections[connector] = false
	gpu_mount.screws.fill(false)
	check(ledger.use_component(pc.id, "gpu", ""), "Remove the graphics card")
	var cpu_mount: Dictionary = ledger.mounts(pc.id, "cpu")
	var cooler_mount: Dictionary = ledger.mounts(pc.id, "cooling")
	cooler_mount.screws.fill(false)
	cooler_mount.connections["CPU FAN"] = false
	var cooler_id: String = pc.components.cooling
	check(ledger.use_component(pc.id, "cooling", ""), "Remove cooler before opening the CPU socket")
	cpu_mount.connections.socket = false
	check(ledger.use_component(pc.id, "cpu", ""), "Remove original processor")
	check(ledger.use_component(pc.id, "cpu", _buy(ledger, "intara_i7_12700k", "inventory").id), "Install CPU with integrated graphics")
	ledger.mounts(pc.id, "cpu").connections.socket = true
	check(ledger.use_component(pc.id, "cooling", cooler_id), "Reinstall cooler")
	ledger.mounts(pc.id, "cooling").screws.fill(true)
	ledger.mounts(pc.id, "cooling").connections["CPU FAN"] = true
	check(ledger.request_post(pc.id), "Integrated graphics allow POST without a discrete card")
	ledger.tick(1.3)
	check(pc.boot_ok and ledger.video_status(pc.id) == "desktop", "Integrated graphics produce video")


func _test_legacy(ledger: RefCounted) -> void:
	_reset(ledger)
	var pc := _open_case(ledger, "intara_m100")
	var board := _buy(ledger, "intara_ix610")
	board.erase("catalog_key")
	board.ddr = "DDR5"
	board.socket = "IX1700"
	check(ledger.use_component(pc.id, "motherboard", board.id), "Previously bought IX610 remains mountable")
	check(ledger.use_component(pc.id, "cpu", _buy(ledger, "intara_coren_i3").id), "Previously sold CPU remains compatible")
	_install_ram(ledger, pc, _buy(ledger, "DDR5"), 1)
	check(ledger.valid(JSON.parse_string(JSON.stringify(ledger.state))), "Legacy IX610 with installed DDR5 survives validation")
	check(ledger.memory_profile(pc.id).speed_mt == 4800, "Legacy DDR5 profile remains usable")

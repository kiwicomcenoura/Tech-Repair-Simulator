extends SceneTree

const Ledger := preload("res://Scripts/Gameplay/workshop_ledger.gd")
const Peripherals := preload("res://Scripts/Equipment/peripheral_catalog.gd")
const PartVisuals := preload("res://Scripts/UI/part_visuals.gd")
const Art := preload("res://Scripts/UI/peripheral_art.gd")
const FanMotion := preload("res://Scripts/Equipment/fan_motion.gd")
const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
const GPU_PRICES := [100, 200, 250, 350, 450, 550, 650, 850, 1050, 1500, 1900, 3000, 5500, 8500, 2500, 4000, 200, 300, 400, 550, 750, 950, 1200, 1400, 1650, 2000, 2200, 2900, 3500, 5900, 3100, 4500]
const DRIVE_PRICES := [35, 55, 75, 100, 130, 150, 180, 280]
const DRIVE_CAPACITIES := [120, 256, 360, 500, 750, 940, 1000, 2000]

var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)


func _run() -> void:
	var world := preload("res://Tools/test_world.gd").create()
	root.add_child(world)
	var workshop := world.get_node("PhysicalWorkshop")
	var market: Control = preload("res://Scripts/Gameplay/techmarket.gd").new()
	market.workshop = workshop
	market.sidebar = PanelContainer.new()
	var sidebar_content := Control.new()
	sidebar_content.name = "Content"
	market.sidebar.add_child(sidebar_content)
	world.add_child(market.sidebar)
	world.add_child(market)
	var images: Array = []
	var side_reference := Art.GPU_SIDE.get_image()
	var side_fins := Rect2i(0, 24, side_reference.get_width(), side_reference.get_height() - 24)
	var fin_pixels := side_reference.get_region(side_fins).get_data()
	market._filter("gpu")
	check(Peripherals.GPUS.size() == 32 and market._buttons.gpu.visible, "There are 32 expansion GPUs and the original stays available")
	for index in range(Peripherals.GPUS.size()):
		var gpu: Dictionary = Peripherals.GPUS[index]
		check(market._buttons[gpu.key].visible and gpu.price == GPU_PRICES[index], "GPU visible at the requested price: " + gpu.model)
		check(gpu.brand == ("Nivida GeForce" if index < 16 else "Amdera Radeon"), "Fictional brand: " + gpu.model)
		check(gpu.get("rgb", false) == (gpu.price >= 3000), "RGB on the premium models: " + gpu.model)
		var pixels := PartVisuals.icon(gpu).get_image().get_data()
		check(pixels not in images and Art.gpu_rotors(gpu).size() == gpu.fans, "Unique pixel art and correct rotor count: " + gpu.model)
		var installed := PartVisuals.gpu_side_artwork(gpu).get_image()
		check(installed.get_region(side_fins).get_data() == fin_pixels, "Installed GPU shows the side of the heatsink: " + gpu.model)
		var power_edge := installed.get_region(Rect2i(Art.GPU_SIDE_SOCKET_X - 55, 0, 110, 1))
		check(power_edge.get_used_rect().has_area() == (not gpu.plugs.is_empty()), "Side profile shows auxiliary power only on cards with a socket: " + gpu.model)
		images.append(pixels)
	market._preview(Peripherals.GPUS[13])
	check("24 GB GDDR6X" in market.preview_name.text and "450 W" in market.preview_name.text and "12V-2x6" in market.preview_name.text, "The shop exposes memory, power and plugs")
	check("Iluminação RGB" in market.preview_name.text, "The shop identifies a GPU with RGB lighting")
	market._filter("storage")
	check(Peripherals.DRIVES.size() == 8 and market._buttons.ssd_960.visible, "Exactly eight HDDs alongside the existing SSDs")
	for index in range(Peripherals.DRIVES.size()):
		var disk: Dictionary = Peripherals.DRIVES[index]
		check(market._buttons[disk.key].visible and disk.capacity_gb == DRIVE_CAPACITIES[index] and disk.price == DRIVE_PRICES[index], "Disk visible at the requested capacity and price")
		var pixels := PartVisuals.icon(disk).get_image().get_data()
		check(pixels not in images, "Individual disk artwork: " + disk.model)
		images.append(pixels)
	market._preview(Peripherals.DRIVES[7])
	check("2 TB" in market.preview_name.text and "7200 RPM" in market.preview_name.text and "3,5" in market.preview_name.text, "HDD preview shows type, capacity, bay and spindle")

	_test_assembly()
	_test_case_layout()
	await _test_visual_controls(workshop)
	world.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("PERIPHERAL EXPANSION CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)


func _purchase(ledger: RefCounted, key: String, destination: String) -> Dictionary:
	var previous: int = ledger.state.items.size()
	if not ledger.purchase(key):
		check(false, "Can buy " + key)
		return {}
	var item: Dictionary = ledger.item(ledger.state.transactions.back().item_id)
	check(ledger.state.items.size() == previous + 1 and item.location == "delivery" and item.packaged, "Purchase creates a single physical delivery: " + key)
	ledger.tick(3.1)
	check(item.location == "floor" and ledger.unpack(item.id) and ledger.move(item.id, destination), "Delivery and destination for " + key)
	return item


func _fix(ledger: RefCounted, pc_id: String, kind: String) -> void:
	var mount: Dictionary = ledger.mounts(pc_id, kind)
	mount.screws.fill(true)
	for port in mount.connections: mount.connections[port] = true


func _test_assembly() -> void:
	var ledger := Ledger.new()
	ledger.new_game()
	ledger.state.balance_adjustment = 20000
	ledger.state.credits += 20000
	var pc := _purchase(ledger, "intara_x700", "bench")
	pc.screws.fill(false)
	pc.lid = false
	ledger.state.tools = true
	var parts := {"motherboard": "intara_h61_classic", "cpu": "intara_i7_3770", "cooling": "intara_legacy_90", "psu": "psu"}
	for kind in parts:
		var part := _purchase(ledger, parts[kind], "shelf")
		check(ledger.use_component(pc.id, kind, part.id), "Install " + kind)
		_fix(ledger, pc.id, kind)
	var ram := _purchase(ledger, "ddr3_8", "shelf")
	for clip in range(2): ledger.toggle_latch(pc.id, clip)
	check(ledger.use_ram_slot(pc.id, ram.id), "Use a DDR3 setup for the old platform")
	for clip in range(2): ledger.toggle_latch(pc.id, clip)

	var passive := _purchase(ledger, "nivida_gt_710", "shelf")
	check(not ledger.use_component(pc.id, "gpu", passive.id), "Rear bracket needs removal")
	pc.tool = "phillips"
	check(ledger.operate_gpu_bay(pc.id, "bracket"), "Remove rear expansion cover")
	pc.tool = "hands"
	check(not ledger.use_component(pc.id, "gpu", passive.id), "Empty slot must be unlatched")
	check(ledger.operate_gpu_bay(pc.id, "latch") and ledger.use_component(pc.id, "gpu", passive.id), "Open latch and seat GPU")
	check(not ledger.gpu_has_auxiliary(passive) and ledger.fan_count(pc.id, "gpu") == 0, "The GT 710 is passive and draws power via PCIe")
	check(not ledger.operate_mount(pc.id, "gpu", "connector", 0), "A passive card does not have a fake auxiliary port")
	check(ledger.operate_mount(pc.id, "gpu", "connector", 1), "Close PCIe latch")
	pc.tool = "phillips"
	for index in range(2): check(ledger.operate_mount(pc.id, "gpu", "screw", index), "Secure the GPU bracket")

	var hdd := _purchase(ledger, "hdd_120", "shelf")
	pc.tool = "hands"
	check(ledger.use_component(pc.id, "storage", hdd.id), "Mount a mechanical disk")
	var storage: Dictionary = ledger.mounts(pc.id, "storage")
	storage.screws.fill(true)
	check(ledger.toggle_power(pc.id) and ledger.storage_status(pc.id) == "no_power", "Without its power cable the HDD stays off")
	ledger.tick(1.3)
	check("sem alimentação" in pc.boot_result and ledger.test_component(pc.id, "storage"), "SATA power fault is visible during diagnostics")
	ledger.tick(2.0)
	check(not hdd.tested and "sem alimentação" in hdd.test_result, "Missing power does not reveal hidden condition")
	ledger.toggle_power(pc.id)
	check(ledger.operate_mount(pc.id, "storage", "connector", 1), "Connect SATA power")
	ledger.toggle_power(pc.id)
	ledger.tick(1.3)
	check(ledger.storage_status(pc.id) == "no_data" and "dados" in pc.boot_result, "Without its data cable the HDD is not recognized")
	ledger.toggle_power(pc.id)
	check(ledger.operate_mount(pc.id, "storage", "connector", 0), "Connect SATA data")
	var other := _purchase(ledger, "hdd_940", "inventory")
	check(ledger.use_component(pc.id, "storage2", other.id), "A second 3.5-inch bay and SATA port can be used")
	_fix(ledger, pc.id, "storage2")
	ledger.toggle_power(pc.id)
	ledger.tick(1.3)
	check(ledger.storage_status(pc.id) == "recognized" and ledger.storage_status(pc.id, "storage2") == "recognized", "Both wired SATA disks are recognized")
	check(pc.boot_result == ledger.NO_BOOT_SYSTEM and ledger.video_status(pc.id) == "firmware", "Recognized empty drives do not auto-boot an OS")
	check(hdd.hours_used > 0.0 and other.hours_used > 0.0, "Powered disks accumulate operating hours")
	other.health = 35
	check(ledger.test_component(pc.id, "storage2"), "Secondary HDD can be tested")
	ledger.tick(2.0)
	check(other.tested and "estalos" in other.test_result and "setores defeituosos" in other.test_result, "Read errors, noise and bad sectors appear after the test")
	check(ledger.prepare_install_usb() and ledger.toggle_install_usb(pc.id) and ledger.boot_install_usb(pc.id), "Existing installer accepts the recognized HDD")
	check(ledger.installation_targets(pc.id).size() == 2 and ledger.start_os_install(pc.id, other.id, false), "Select the second mechanical disk for TechOS")
	ledger.tick(4.1)
	check(other.bootable and other.get("system") == "TechOS" and not hdd.bootable, "Only the selected HDD receives the system")
	check(ledger.toggle_install_usb(pc.id) and ledger.restart_after_install(pc.id), "Boot the installed HDD after removing the installation media")
	ledger.tick(1.3)
	check(ledger.video_status(pc.id) == "desktop", "A mechanical disk boots only after installing TechOS")
	ledger.toggle_power(pc.id)

	pc.tool = "phillips"
	for index in range(2): ledger.operate_mount(pc.id, "gpu", "screw", index)
	pc.tool = "hands"
	ledger.operate_mount(pc.id, "gpu", "connector", 1)
	check(ledger.use_component(pc.id, "gpu", "") and passive.location == "tray", "Passive card can be removed without undoing a non-existent cable")
	var modern := _purchase(ledger, "nivida_rtx_4090", "shelf")
	check(ledger.use_component(pc.id, "gpu", modern.id), "Modern GPU can be mounted even with an old processor and PCIe 2")
	ledger.operate_mount(pc.id, "gpu", "connector", 1)
	check(not ledger.operate_mount(pc.id, "gpu", "connector", 0) and "12V-2x6" in ledger.gpu_power_reason(pc), "A PSU without the auxiliary connector cannot cable the GPU")
	var psu_mount: Dictionary = ledger.mounts(pc.id, "psu")
	psu_mount.screws.fill(false)
	psu_mount.connections["chicote de energia"] = false
	check(ledger.use_component(pc.id, "psu", ""), "Remove under-equipped PSU")
	var supply := _purchase(ledger, "psu_1000", "shelf")
	check(ledger.use_component(pc.id, "psu", supply.id), "Fit the higher-power PSU")
	_fix(ledger, pc.id, "psu")
	check(ledger.operate_mount(pc.id, "gpu", "connector", 0), "Connect the required modern GPU cable")
	_fix(ledger, pc.id, "gpu")
	check(not ledger.gpu_rgb_active(pc.id), "RGB starts off while the PC is powered down")
	check(ledger.toggle_power(pc.id), "Working wiring and PSU allow power")
	check(ledger.gpu_rgb_active(pc.id), "A premium card lights up with its slot and cable powered")
	var motion := FanMotion.new()
	motion.advance(ledger, pc.id, 0.2)
	check(motion.speed("gpu") > 0 and motion.speed("case") > 0 and motion.speed("cooling") > 0 and motion.speed("psu") > 0, "Fans ramp up after real power-on")
	ledger.tick(1.3)
	check(ledger.graphics_profile(pc.id).link == 2 and ledger.graphics_profile(pc.id).cpu_limit, "Negotiated previous PCIe generation and CPU bottleneck are reported")
	check(ledger.fan_count(pc.id, "gpu") == 3 and ledger.fan_speed(pc.id, "gpu") == 0.0, "Three GPU fans defined, with Zero RPM at idle")
	check(ledger.gpu_rgb_active(pc.id), "Zero RPM leaves the lighting on")
	var gpu_mount: Dictionary = ledger.mounts(pc.id, "gpu")
	gpu_mount.connections.energia = false
	check(not ledger.gpu_rgb_active(pc.id), "Loss of auxiliary power switches the LEDs off")
	gpu_mount.connections.energia = true
	check(ledger.test_component(pc.id, "gpu") and ledger.fan_speed(pc.id, "gpu") > 0.0, "GPU fans wake under the video test")
	var normal: int = ledger.fan_temperature(pc.id, "gpu")
	modern.fan_fault = "stuck"
	check(ledger.fan_speed(pc.id, "gpu") == 0.0 and ledger.fan_temperature(pc.id, "gpu") > normal, "A stuck rotor stops and increases simulated temperature")
	modern.fan_fault = "slow"
	check(ledger.fan_speed(pc.id, "gpu") < 3.8, "Slow fan is visibly limited")
	supply.health = 8
	motion.advance(ledger, pc.id, 1.0)
	check(motion.speed("case") == 0.0 and motion.speed("gpu") == 0.0, "Electrical failure stops the fans")
	check(not ledger.gpu_rgb_active(pc.id), "A faulty PSU cuts the RGB lighting")
	supply.health = 96
	ledger.toggle_power(pc.id)
	motion.advance(ledger, pc.id, 1.0)
	check(motion.speed("gpu") == 0.0 and motion.speed("cooling") == 0.0, "Power-off leaves the rollers stopped")
	check(not ledger.gpu_rgb_active(pc.id), "Power-off switches the LEDs off")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(ledger.state))
	check(ledger.valid(saved) and saved.items[pc.id].components.storage2 == other.id, "Save round-trip preserves both SATA slots and the new GPU")


func _test_case_layout() -> void:
	var compact := Cases.get_model("intara_m100")
	var core := Cases.get_model("amdera_core_200")
	check("mm" in Cases.fit_reason(compact, Peripherals.GPUS[13]), "Cabinet length is enforced")
	check("slots" in Cases.fit_reason(core, Peripherals.GPUS[25]), "Slot width is enforced even when length fits")
	var ledger := Ledger.new()
	var pc := {"case_key": "intara_m100", "components": {"storage": "occupied"}}
	var disks := {"occupied": Peripherals.DRIVES[0]}
	check("3,5" in ledger._drive_fit_reason(disks, pc, "storage2", Peripherals.DRIVES[1]), "A second 3.5-inch HDD cannot fit when its only HDD bay is occupied")
	var cpu := {"key": "intara_i7_12700k"}
	var small_psu := {"model": "TR Power 450 W"}
	check("precisa" in Peripherals.power_reason(Peripherals.GPUS[8], small_psu, cpu, 2), "Wattage margin includes the other components even when the plugs fit")


func _test_visual_controls(workshop: Node) -> void:
	var ledger: RefCounted = workshop.ledger
	ledger.state.balance_adjustment = 3000
	ledger.state.credits += 3000
	ledger.state.tools = true
	var pc := _purchase(ledger, "intara_x700", "bench")
	pc.lid = false
	pc.screws.fill(false)
	var board := _purchase(ledger, "amdera_ax550", "shelf")
	check(ledger.use_component(pc.id, "motherboard", board.id), "Mount the board for the visual inspection")
	var gpu := _purchase(ledger, "nivida_gt_710", "shelf")
	var hd := _purchase(ledger, "hdd_256", "shelf")
	workshop.bench_ui.open_bench()
	check(workshop.bench_ui.open_inspection(), "Open the actual inspection interface")
	await process_frame
	var view: Control = workshop.bench_ui.inspection
	var canvas: Control = view.canvas
	var session: RefCounted = view.session
	var picker: OptionButton = view.find_child("RAMInventory", true, false)
	var gpu_entry: int = view._inventory_ids.find(gpu.id)
	picker.select(gpu_entry)
	picker.item_selected.emit(gpu_entry)
	session.select_tool(&"phillips")
	var bracket: StringName = canvas.hit_at(canvas.GPU_BAY.bracket)
	check(bracket == &"gpu_bay:bracket", "The real view exposes the rear cover")
	session.interact_with(bracket)
	session.select_tool(&"hands")
	var latch: StringName = canvas.hit_at(canvas.GPU_BAY.latch)
	check(latch == &"gpu_bay:latch", "The real view exposes the empty PCIe latch")
	session.interact_with(latch)
	session.interact_with(canvas.hit_at(canvas.MOUNT_RECTS.gpu.get_center()))
	check(pc.components.get("gpu") == gpu.id, "Mount the selected GPU from its 2D hit box")
	check(canvas.hit_at(canvas.mount_point("gpu", 0, true)) != &"mount:gpu:connector:0", "A passive GPU displays no auxiliary connector")
	var hd_entry: int = view._inventory_ids.find(hd.id)
	picker.select(hd_entry)
	picker.item_selected.emit(hd_entry)
	session.interact_with(canvas.hit_at(canvas.MOUNT_RECTS.storage2.get_center()))
	check(pc.components.get("storage2") == hd.id, "The secondary bay is physically selectable for installation")
	check(canvas.hit_at(canvas.mount_point("storage2", 0, true)) == &"mount:storage2:connector:0", "The second disk has an independent data cable")
	workshop.bench_ui.close_bench()

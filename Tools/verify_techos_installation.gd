extends SceneTree

const WorldFixture := preload("res://Tools/test_world.gd")
const PARTS := {
	"motherboard": "amdera_ax550",
	"cpu": "amdera_r5_5600",
	"cooling": "amdera_frost_120",
	"gpu": "gpu",
	"psu": "psu",
}

var checks := 0
var failures := 0
var world: Node2D
var workshop: Node
var ledger: RefCounted
var save_path := "res://.godot/install-test-%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)


func _frames() -> void:
	for i in range(3): await process_frame


func _click(button: Control) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames()


func _buy(key: String, destination: String) -> String:
	if not ledger.purchase(key):
		check(false, "Buy " + key)
		return ""
	var id: String = ledger.state.transactions.back().item_id
	ledger.tick(3.1)
	check(ledger.unpack(id) and ledger.move(id, destination), "Unpack and move " + key)
	return id


func _build_pc(case_key: String) -> String:
	var id := _buy(case_key, "bench")
	var pc: Dictionary = ledger.item(id)
	pc.lid = false
	pc.screws.fill(false)
	for kind in PARTS:
		_mount(id, kind, _buy(PARTS[kind], "tray"))
	var ram := _buy("DDR4", "tray")
	for clip in range(2): ledger.toggle_latch(id, clip)
	check(ledger.use_ram_slot(id, ram), "Install RAM")
	for clip in range(2): ledger.toggle_latch(id, clip)
	return id


func _mount(pc: String, kind: String, part: String) -> void:
	check(ledger.use_component(pc, kind, part), "Mount " + kind)
	var mount: Dictionary = ledger.mounts(pc, kind)
	mount.screws.fill(true)
	for connector in mount.connections: mount.connections[connector] = true


func _run() -> void:
	root.size = Vector2i(1360, 768)
	world = WorldFixture.create()
	root.add_child(world)
	await _frames()
	workshop = world.get_node("PhysicalWorkshop")
	ledger = workshop.ledger
	ledger.state.balance_adjustment = 10000
	ledger.state.credits += 10000
	var pc_id := _build_pc("amdera_core_200")
	var disk_id := _buy("ssd_480", "tray")
	_mount(pc_id, "storage", disk_id)
	var pc: Dictionary = ledger.item(pc_id)
	check(not ledger.toggle_install_usb(pc_id), "Unprepared USB cannot be plugged in")

	var personal := world.get_node("PersonalComputerUI")
	personal.computer.boot_duration = 0.05
	personal.open_computer()
	await _frames()
	await _click(personal.get_node("%PowerToggle"))
	await create_timer(0.16, true).timeout
	var desktop: Control = personal.get_node("%DesktopScreen")
	await _click(desktop.launchers.installer)
	var media_window: Control = desktop.windows.installer
	var prepare: Button = media_window.find_child("PrepareInstallUSB", true, false)
	await _click(prepare)
	check(ledger.state.install_usb_ready and prepare.disabled, "Workshop desktop prepares exactly one reusable USB drive")
	personal.close_computer()

	var bench := world.get_node("MaintenanceBenchUI")
	bench.open_bench()
	check(bench.open_inspection(), "Open the physical inspection")
	await _frames()
	var view: Control = bench.inspection
	var usb: Button = view.find_child("BenchInstallUSB", true, false)
	check(usb.size.y <= 30 and usb.text == "Conectar USB", "The bench USB action uses the compact button")
	await _click(usb)
	check(pc.get("install_usb", false) and not pc.power, "Connect the USB drive while the PC is off")
	check(not ledger.boot_install_usb(pc_id), "USB boot requires a successful POST")
	await _click(view.find_child("BenchPower", true, false))
	ledger.tick(1.3)
	check(ledger.video_status(pc_id) == "firmware" and pc.boot_result == ledger.NO_BOOT_SYSTEM, "A new SSD reaches POST before installation")
	await _click(view.find_child("AccessClientOS", true, false))
	await _click(view.find_child("BootInstallUSB", true, false))
	check(ledger.video_status(pc_id) == "installer", "Monitor starts the USB installer")
	if not pc.has("installation"):
		await _finish_run()
		return
	var target: OptionButton = view.find_child("InstallTarget", true, false)
	var action: Button = view.find_child("InstallAction", true, false)
	check(action.disabled and "480 GB" in target.get_item_text(1), "Select the real installed SSD by model and capacity")
	check(not ledger.start_os_install(pc_id, "another-disk", true), "Reject installation to an unrelated disk")
	target.select(1)
	target.item_selected.emit(1)
	await _click(action)
	check(pc.installation.phase == "setup", "Selecting a disk still requires confirmation")
	await _click(view.find_child("CancelInstallConfirmation", true, false))
	check(pc.installation.phase == "setup" and not ledger.item(disk_id).bootable, "Cancel leaves the SSD untouched")
	await _click(action)
	await _click(action)
	check(pc.installation.phase == "copying" and not ledger.item(disk_id).bootable, "Copy starts without committing the SSD")
	check(not ledger.toggle_install_usb(pc_id) and not ledger.request_post(pc_id), "Copy protects the USB and blocks a competing restart")
	ledger.tick(1.2)
	workshop.save_path = save_path
	check(workshop.save_game(false) and workshop.load_game(), "Mid-installation save loads through the normal workshop path")
	pc = ledger.item(pc_id)
	check(pc.installation.phase == "copying" and pc.installation.remaining < ledger.INSTALL_DURATION and pc.install_usb, "Save restores progress, disk and USB")
	ledger.tick(5.0)
	check(pc.installation.phase == "complete" and ledger.item(disk_id).system == "TechOS", "Copy finishes and commits TechOS to the physical SSD")
	check(not ledger.restart_after_install(pc_id), "Remove the USB drive before restarting from the SSD")
	bench.open_bench()
	check(bench.open_inspection(), "Return to the monitor after loading")
	await _frames()
	await _click(view.find_child("AccessClientOS", true, false))
	await _click(view.find_child("MonitorInstallUSB", true, false))
	await _click(action)
	ledger.tick(1.3)
	await _frames()
	var client: Control = view.find_child("ClientTechOS", true, false)
	check(pc.boot_ok and client.is_visible_in_tree() and not pc.has("installation"), "Restart boots the interactive desktop from the SSD")
	client.install_client_app("notes")
	check("notes" in ledger.item(disk_id).client_apps and ledger.valid(ledger.state), "Installed apps are stored with the new system on the SSD")
	bench.close_bench()

	check(ledger.toggle_install_usb(pc_id) and ledger.boot_install_usb(pc_id), "Reuse the prepared USB for a reinstall")
	check(not ledger.start_os_install(pc_id, disk_id, false), "An installed system requires overwrite confirmation")
	check(ledger.start_os_install(pc_id, disk_id, true), "Explicit confirmation enables reinstall")
	ledger.tick(0.5)
	check(ledger.toggle_power(pc_id) and not pc.has("installation"), "Power-off cancels copying")
	check(ledger.item(disk_id).bootable and "notes" in ledger.item(disk_id).client_apps, "Power loss preserves the original system and apps")
	check(not ledger.move(pc_id, "floor"), "A connected USB stays at the bench until removed")
	check(ledger.toggle_install_usb(pc_id), "Eject the reusable USB")
	var mount: Dictionary = ledger.mounts(pc_id, "storage")
	mount.screws.fill(false)
	for connector in mount.connections: mount.connections[connector] = false
	check(ledger.use_component(pc_id, "storage", "") and ledger.move(pc_id, "floor"), "Remove the SSD and move the first case")
	var second_pc := _build_pc("amdera_gx500")
	_mount(second_pc, "storage", disk_id)
	check(ledger.toggle_power(second_pc), "Power a different cabinet with the same SSD")
	ledger.tick(1.3)
	check(ledger.video_status(second_pc) == "desktop" and "notes" in ledger.client_apps(second_pc), "TechOS and its apps boot in the other cabinet")
	check(ledger.valid(ledger.state) and ledger.state.install_usb_ready, "The disk and reusable USB are both valid after transfer")
	await _finish_run()


func _finish_run() -> void:
	workshop.save_path = ""
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(save_path + suffix): DirAccess.remove_absolute(save_path + suffix)
	world.queue_free()
	await _frames()
	await create_timer(0.3).timeout
	print("TECHOS INSTALLATION CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)

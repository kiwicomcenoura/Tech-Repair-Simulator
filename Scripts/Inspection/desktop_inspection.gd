extends VBoxContainer

signal return_requested

const VideoScreen := preload("res://Scripts/UI/bench_video_screen.gd")
const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")
const InstallerScreen := preload("res://Scripts/UI/techos_installer.gd")
const PREVIEW_HELP := "Clique para usar a ferramenta · Arraste para girar · Roda para zoom · Botão direito para restaurar."

var session: RefCounted
var _inventory: OptionButton
var _unpack_cabinet: Button
var _inventory_ids: Array = []
var _power: Button
var _access_os: Button
var _os_view: PanelContainer
var _os_screen: Control
var _client_desktop: Control
var _video_effects: Control
var _installer: PanelContainer
var _media_bar: HBoxContainer
var _monitor_usb: Button
var _boot_usb: Button
var _bench_usb: Button
var _memory_test: Button
var _workshop: Node
var _case_picker: MenuButton
@onready var canvas: Control = %DesktopCanvas
@onready var preview: SubViewportContainer = %DesktopPreview3D


func _ready() -> void:
	%ReturnToBench.pressed.connect(func() -> void: return_requested.emit())
	%Phillips.pressed.connect(func() -> void:
		if session != null: session.select_tool(&"phillips"))
	%Hands.pressed.connect(func() -> void:
		if session != null: session.select_tool(&"hands"))
	%LidAction.pressed.connect(func() -> void:
		if session != null: session.use_lid())
	%PreviewToggle.pressed.connect(func() -> void: _show_preview(not preview.visible))
	canvas.hovered_part.connect(func(text: String) -> void:
		if not preview.visible: %HoverName.text = text)
	preview.target_hovered.connect(func(id: StringName) -> void:
		if preview.visible:
			%HoverName.text = canvas.part_name(id) if id != &"" and session != null else PREVIEW_HELP)
	preview.target_activated.connect(func(id: StringName) -> void:
		if session != null: session.interact_with(id))
	_build_physical_controls()
	var area: VBoxContainer = $Workspace/CasePanel/Content
	var empty_slot := CenterContainer.new()
	empty_slot.name = "EmptyCaseSlot"
	empty_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.add_child(empty_slot)
	area.move_child(empty_slot, canvas.get_index())
	_case_picker = MenuButton.new()
	_case_picker.name = "AddCase"
	_case_picker.text = "Adicionar gabinete"
	_case_picker.custom_minimum_size = Vector2(218, 42)
	_case_picker.focus_mode = Control.FOCUS_ALL
	_case_picker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	empty_slot.add_child(_case_picker)
	_case_picker.get_popup().id_pressed.connect(_add_case)
	refresh_case_picker()


func bind_workshop(workshop: Node) -> void:
	_workshop = workshop
	workshop.ledger.changed.connect(refresh_case_picker)
	refresh_case_picker()


func refresh_case_picker() -> void:
	var empty := session == null
	_case_picker.get_parent().visible = empty
	$Workspace/ToolsPanel.visible = not empty
	%PreviewToggle.get_parent().visible = not empty
	if not empty:
		close_case_picker()
		return
	var popup := _case_picker.get_popup()
	popup.clear()
	var available: Array = _workshop.ledger.available_purchased_cases() if is_instance_valid(_workshop) else []
	for id in available:
		var record: Dictionary = _workshop.ledger.item(id)
		var label: String = record.model
		if record.packaged: label += " · " + Prefs.t("Embalado")
		popup.add_item(label)
		popup.set_item_metadata(popup.item_count - 1, id)
	_case_picker.disabled = available.is_empty()
	_case_picker.tooltip_text = "Compre um gabinete na Loja de Peças e aguarde a entrega." if available.is_empty() else ""
	%HoverName.text = "Compre um gabinete na Loja de Peças e aguarde a entrega." if available.is_empty() else "Escolha um gabinete comprado para colocá-lo na bancada."


func focus_entry() -> void:
	if not is_inside_tree(): return
	if session == null and not _case_picker.disabled: _case_picker.grab_focus()
	else: %ReturnToBench.grab_focus()


func close_case_picker() -> bool:
	if not _case_picker.get_popup().visible: return false
	_case_picker.get_popup().hide()
	return true


func _add_case(popup_id: int) -> void:
	if session != null or not is_instance_valid(_workshop): return
	var popup := _case_picker.get_popup()
	var index := popup.get_item_index(popup_id)
	if index < 0: return
	if not _workshop.ledger.place_purchased_case(popup.get_item_metadata(index)):
		_notice(_workshop.last_message, true)


func _build_physical_controls() -> void:
	var header: HBoxContainer = $InspectionHeader
	$InspectionHeader/Titles/Description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_power = Button.new()
	_power.name = "BenchPower"
	_power.text = "Ligar PC"
	_power.custom_minimum_size = Vector2(105, 40)
	header.add_child(_power)
	header.move_child(_power, 1)
	_power.pressed.connect(func() -> void:
		if session != null and is_instance_valid(session.workshop): session.workshop.ledger.toggle_power(session.physical_pc_id))
	_access_os = Button.new()
	_access_os.name = "AccessClientOS"
	_access_os.text = Prefs.t("Abrir monitor")
	_access_os.custom_minimum_size.y = 40
	header.add_child(_access_os)
	header.move_child(_access_os, 2)
	_access_os.pressed.connect(func() -> void: _show_client_os(not _os_view.visible))
	_os_view = PanelContainer.new()
	_os_view.name = "ClientOS"
	_os_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_os_view)
	var monitor := VBoxContainer.new()
	_os_view.add_child(monitor)
	_media_bar = HBoxContainer.new()
	_media_bar.alignment = BoxContainer.ALIGNMENT_END
	monitor.add_child(_media_bar)
	_monitor_usb = _usb_button("MonitorInstallUSB")
	_media_bar.add_child(_monitor_usb)
	_boot_usb = Button.new()
	_boot_usb.name = "BootInstallUSB"
	_boot_usb.text = Prefs.t("Iniciar pelo pendrive")
	_boot_usb.custom_minimum_size.y = 36
	_boot_usb.pressed.connect(func() -> void:
		if session != null and is_instance_valid(session.workshop) and session.workshop.ledger.boot_install_usb(session.physical_pc_id):
			_installer.focus_target())
	_media_bar.add_child(_boot_usb)
	var display := Control.new()
	display.clip_contents = true
	display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	monitor.add_child(display)
	_os_screen = VideoScreen.new()
	_os_screen.name = "ClientDisplay"
	display.add_child(_os_screen)
	_os_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_client_desktop = preload("res://Scenes/UI/TechOS/Desktop.tscn").instantiate()
	_client_desktop.name = "ClientTechOS"
	_client_desktop.client_mode = true
	_client_desktop.custom_minimum_size = Vector2.ZERO
	_client_desktop.exit_requested.connect(func() -> void: close_client_os())
	_client_desktop.shutdown_requested.connect(func() -> void: session.workshop.ledger.toggle_power(session.physical_pc_id))
	_client_desktop.client_app_installed.connect(func(id: String) -> void:
		session.workshop.ledger.install_client_app(session.physical_pc_id, id))
	display.add_child(_client_desktop)
	_client_desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video_effects = VideoScreen.new()
	_video_effects.effects_only = true
	_video_effects.status = "artifacts"
	_video_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.add_child(_video_effects)
	_video_effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_installer = InstallerScreen.new()
	_installer.name = "TechOSInstallerScreen"
	display.add_child(_installer)
	_installer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_os_view.hide()
	_memory_test = Button.new()
	_memory_test.name = "MemoryTest"
	_memory_test.text = "Testar RAM"
	_memory_test.custom_minimum_size = Vector2(110, 40)
	header.add_child(_memory_test)
	header.move_child(_memory_test, 3)
	_memory_test.pressed.connect(func() -> void:
		if session != null and is_instance_valid(session.workshop): session.workshop.ledger.test_ram(session.physical_pc_id))
	var sidebar: VBoxContainer = $Workspace/ToolsPanel/ToolScroll/Content
	var label := Label.new()
	label.name = "RAMStockLabel"
	label.text = Prefs.t("PEÇAS · ARMÁRIO E BANCADA")
	label.theme_type_variation = &"Eyebrow"
	sidebar.add_child(label)
	sidebar.move_child(label, sidebar.get_node("ToolSelection").get_index())
	_inventory = OptionButton.new()
	_inventory.name = "RAMInventory"
	_inventory.custom_minimum_size = Vector2(0, 36)
	_inventory.clip_text = true
	_inventory.fit_to_longest_item = false
	sidebar.add_child(_inventory)
	sidebar.move_child(_inventory, label.get_index() + 1)
	_unpack_cabinet = Button.new()
	_unpack_cabinet.name = "UnpackCabinetPart"
	_unpack_cabinet.text = Prefs.t("Desembalar peça")
	_unpack_cabinet.hide()
	_unpack_cabinet.pressed.connect(func() -> void:
		if session == null or not is_instance_valid(session.workshop): return
		var ledger: RefCounted = session.workshop.ledger
		var part: Dictionary = ledger.item(session.workshop.selected_part)
		if part.get("location") == "shelf" and ledger.unpack(part.id) and part.kind == "ram":
			session.workshop.selected_ram = part.id)
	sidebar.add_child(_unpack_cabinet)
	sidebar.move_child(_unpack_cabinet, _inventory.get_index() + 1)
	_inventory.item_selected.connect(func(index: int) -> void:
		if session == null or not is_instance_valid(session.workshop) or index >= _inventory_ids.size(): return
		var id: String = _inventory_ids[index]
		var ledger: RefCounted = session.workshop.ledger
		var part: Dictionary = ledger.item(id)
		session.workshop.selected_part = id
		session.workshop.selected_ram = id if id in ledger.available_ram() else ""
		if preview.visible: preview.show_session(session)
		_update_selected_stock(ledger, part)
		if part.is_empty(): return
		var hint := "Desembale a peça do armário para instalar." if part.packaged else "Peça selecionada. Com Mãos, clique no encaixe vazio correspondente; depois fixe e reconecte."
		session.notice.emit(Prefs.t(hint), false))
	_bench_usb = _usb_button("BenchInstallUSB")
	var case_header: HBoxContainer = $Workspace/CasePanel/Content/Header
	case_header.add_child(_bench_usb)
	case_header.move_child(_bench_usb, %PreviewToggle.get_parent().get_index())


func _usb_button(node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size.y = 28
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 12)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style: StyleBox = get_theme_stylebox(state, "Button").duplicate()
		for side in [SIDE_TOP, SIDE_BOTTOM]: style.set_content_margin(side, 4.0)
		for side in [SIDE_LEFT, SIDE_RIGHT]: style.set_content_margin(side, 8.0)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(func() -> void:
		if session != null and is_instance_valid(session.workshop):
			session.workshop.ledger.toggle_install_usb(session.physical_pc_id))
	return button


func _refresh_usb_buttons(model: RefCounted, pc: Dictionary) -> void:
	var ready: bool = model.state.get("install_usb_ready", false)
	var connected: bool = pc.get("install_usb", false)
	var busy: bool = pc.get("installation", {}).get("phase") == "copying"
	for button in [_bench_usb, _monitor_usb]:
		button.text = Prefs.t("Retirar USB" if connected else "Conectar USB")
		button.tooltip_text = Prefs.t("Retirar pendrive" if connected else "Conectar pendrive")
		button.disabled = busy
	_bench_usb.visible = ready
	_media_bar.visible = ready
	_boot_usb.visible = not pc.has("installation")
	_boot_usb.disabled = not model.can_boot_install_usb(pc.id)
	_boot_usb.tooltip_text = Prefs.t("Conecte o pendrive e conclua o POST.") if _boot_usb.disabled else ""


func _refresh_physical() -> void:
	var physical := session != null and is_instance_valid(session.workshop)
	_power.visible = physical
	_access_os.visible = physical
	_bench_usb.visible = false
	_memory_test.visible = physical and not _os_view.visible
	_inventory.visible = physical
	_unpack_cabinet.hide()
	_inventory.get_parent().get_node("RAMStockLabel").visible = physical
	%SelectedInfo.visible = not physical
	%SelectedName.get_parent().get_node("SelectionHeading").visible = not physical
	if not physical: return
	var model: RefCounted = session.workshop.ledger
	var pc: Dictionary = model.item(session.physical_pc_id)
	_refresh_usb_buttons(model, pc)
	_client_desktop.set_running(pc.power and not pc.has("installation"))
	var apps: Array = model.client_apps(pc.id)
	if _client_desktop.installed_apps != apps: _client_desktop.set_client_apps(apps)
	_power.text = "Desligar PC" if pc.power else "Ligar PC"
	var power_reason: String = model.assembly_power_block_reason(session.physical_pc_id)
	_power.disabled = not power_reason.is_empty()
	_power.tooltip_text = power_reason
	_access_os.disabled = not pc.power and not _os_view.visible
	_access_os.tooltip_text = Prefs.t("Ligue o PC para acessar o monitor.") if _access_os.disabled else ""
	var test_reason: String = model.ram_test_block_reason(session.physical_pc_id)
	_memory_test.disabled = not test_reason.is_empty()
	_memory_test.tooltip_text = test_reason if not test_reason.is_empty() else "Diagnóstico de memória após o POST; também identifica módulos defeituosos que impedem o boot."
	if _os_view.visible:
		_update_client_display()
	else:
		$InspectionHeader/Titles/Description.text = model.localized_boot_result(pc)
		$InspectionHeader/Titles/Eyebrow.text = Prefs.t("INSPEÇÃO VISUAL  /  %s") % pc.model if pc.has("case_key") else "INSPEÇÃO VISUAL  /  DESKTOP ATX"
	%Phillips.disabled = not model.state.tools
	_inventory.clear()
	var available: Array = model.available_parts("", true)
	available.sort_custom(func(a: String, b: String) -> bool:
		var left: Dictionary = model.item(a)
		var right: Dictionary = model.item(b)
		var left_rank: int = model.BENCH_PART_LOCATIONS.find(left.location)
		var right_rank: int = model.BENCH_PART_LOCATIONS.find(right.location)
		if left_rank != right_rank: return left_rank < right_rank
		if left.location == "shelf": return int(left.shelf_slot) < int(right.shelf_slot)
		return str(left.model).naturalnocasecmp_to(str(right.model)) < 0)
	_inventory_ids = [""]
	_inventory.add_item(Prefs.t("Selecione uma peça" if not available.is_empty() else "Nenhuma peça disponível"))
	for id in available:
		_inventory_ids.append(id)
		var record: Dictionary = model.item(id)
		var source := Prefs.t({"shelf": "Armário", "inventory": "Inventário", "tray": "Bandeja", "carried": "Nas mãos"}[record.location])
		if record.location == "shelf": source += " %02d" % (int(record.shelf_slot) + 1)
		if record.packaged: source += " · " + Prefs.t("Embalado")
		_inventory.add_item("%s · %s" % [source, record.model])
		_inventory.get_popup().set_item_tooltip(_inventory.item_count - 1, model.known_description(id))
	_inventory.disabled = available.is_empty()
	var selected: int = _inventory_ids.find(session.workshop.selected_part)
	if selected >= 0:
		_inventory.select(selected)
	else:
		_inventory.select(0)
	_update_selected_stock(model, model.item(session.workshop.selected_part))


func _update_selected_stock(model: RefCounted, part: Dictionary) -> void:
	_unpack_cabinet.visible = part.get("location") == "shelf" and part.get("packaged", false)
	_inventory.tooltip_text = "" if part.is_empty() else model.known_description(part.id)


func configure(value: RefCounted) -> void:
	var device_changed := session != value
	if device_changed:
		close_client_os(false)
		_client_desktop.set_running(false)
	if session != null:
		if session.changed.is_connected(_refresh): session.changed.disconnect(_refresh)
		if session.notice.is_connected(_notice): session.notice.disconnect(_notice)
	session = value
	if device_changed:
		var apps: Array = []
		if session != null and is_instance_valid(session.workshop):
			apps = session.workshop.ledger.client_apps(session.physical_pc_id)
		_client_desktop.set_client_apps(apps)
	canvas.configure(session)
	if device_changed:
		preview.reset_view()
	_show_preview(preview.visible and not device_changed)
	refresh_case_picker()
	%Phillips.disabled = session == null
	%Hands.disabled = session == null
	%LidAction.disabled = session == null
	if session == null:
		$InspectionHeader/Titles/Eyebrow.text = "INSPEÇÃO VISUAL"
		$InspectionHeader/Titles/Description.text = "Nenhum equipamento na bancada."
		%ScrewCount.text = "—"
		%LidStatus.text = "Nenhum equipamento"
		%SelectedName.text = "Nenhum equipamento na bancada"
		%SelectedInfo.text = "Coloque um equipamento físico na bancada para inspecionar."
		%ContextMessage.text = "Nenhum equipamento na bancada."
		_refresh_physical()
		return
	session.changed.connect(_refresh)
	session.notice.connect(_notice)
	%ContextMessage.text = "Aguardando teste ou manuseio do gabinete." if is_instance_valid(session.workshop) else "Selecione a chave Phillips e clique nos parafusos."
	_refresh()


func _show_preview(active: bool) -> void:
	active = active and session != null
	%PreviewToggle.text = "Vista 2D" if active else "Vista 3D"
	%Title.text = "Nenhum equipamento na bancada" if session == null else "Gabinete — vista 3D" if active else "Gabinete — lateral esquerda"
	preview.visible = active
	canvas.visible = session != null and not active
	if active:
		preview.show_session(session)
	%HoverName.text = PREVIEW_HELP if active else "Passe o mouse sobre o gabinete."
	if session != null and is_instance_valid(session.workshop):
		$Workspace/ToolsPanel/ToolScroll/Content/ToolHelp.text = (
			"1 · Mãos: peças, conectores e travas\n2 · Phillips: parafusos\nConectores soltos ficam fora do encaixe."
			if active else
			"1 · Mãos: peças e conectores\nRoda: zoom · Meio: arrastar\nBotão direito: restaurar vista\n2 · Phillips: parafusos\nCiano: conectado · Âmbar: solto\nClique nos pontos do gabinete."
		)


func _process(_delta: float) -> void:
	if _os_view.visible and is_visible_in_tree(): _update_client_display()


func _update_client_display() -> void:
	var model: RefCounted = session.workshop.ledger
	var status: String = model.video_status(session.physical_pc_id)
	_os_screen.status = status
	_client_desktop.visible = status in ["desktop", "artifacts"]
	_os_screen.visible = not _client_desktop.visible and status != "installer"
	_video_effects.visible = status == "artifacts"
	_installer.update_screen(model, session.physical_pc_id)
	_installer.visible = status == "installer"
	var description := Prefs.t(VideoScreen.STATUS[status])
	if status == "firmware":
		var pc: Dictionary = model.item(session.physical_pc_id)
		description = model.localized_boot_result(pc)
		if pc.boot_result == model.NO_BOOT_SYSTEM and not model.state.get("install_usb_ready", false):
			description += " " + Prefs.t("Prepare o pendrive no Instalador TechOS do computador da oficina.")
	$InspectionHeader/Titles/Description.text = description


func _show_client_os(active: bool, restore_focus: bool = true) -> void:
	_os_view.visible = active
	$Workspace.visible = not active
	$ContextPanel.visible = not active
	_access_os.text = Prefs.t("Voltar à inspeção" if active else "Abrir monitor")
	$InspectionHeader/Titles/Eyebrow.text = Prefs.t("MONITOR DA BANCADA") if active else "INSPEÇÃO VISUAL  /  DESKTOP ATX"
	_refresh_physical()
	if not restore_focus: return
	if _access_os.disabled: _power.grab_focus()
	else: _access_os.grab_focus()


func close_client_os(restore_focus: bool = true) -> bool:
	if not _os_view.visible: return false
	_show_client_os(false, restore_focus)
	return true


func handle_client_escape() -> bool:
	return _os_view.visible and (_installer.cancel_confirmation() or _client_desktop.dismiss_popup() or close_client_os())


func _refresh() -> void:
	_refresh_physical()
	if preview.visible:
		preview.show_session(session)
	%Phillips.set_pressed_no_signal(session.tool == &"phillips")
	%Hands.set_pressed_no_signal(session.tool == &"hands")
	%ScrewCount.text = Prefs.t("%d / 4 parafusos retirados") % (4 - session.installed_count())
	for i in range(4):
		var label: Label = get_node("%Screw" + str(i))
		label.text = "%d  %s" % [i + 1, Prefs.t("Fixado" if session.screws[i] else "Retirado")]
		label.modulate = Color("9aabbc") if session.screws[i] else Color("74d1e1")
	%LidStatus.text = "Tampa instalada" if session.lid_attached else "Tampa retirada"
	%LidAction.text = "Retirar tampa" if session.lid_attached else "Recolocar tampa"
	%SelectedName.text = canvas.part_name(session.selected)
	var ram_slot := Hardware.RAM_KEYS.find(str(session.selected))
	if is_instance_valid(session.workshop) and ram_slot >= 0:
		var pc: Dictionary = session.workshop.ledger.item(session.physical_pc_id)
		var ram: Dictionary = session.workshop.ledger.item(pc.components.get(str(session.selected), ""))
		%SelectedName.text = "Slot %s vazio" % Hardware.RAM_LABELS[ram_slot] if ram.is_empty() else ram.model
	if String(session.selected).begins_with("screw_"):
		var index := int(String(session.selected).trim_prefix("screw_"))
		%SelectedName.text = "Parafuso %d — %s" % [index + 1, "fixado" if session.screws[index] else "retirado"]
		%SelectedInfo.text = "Use a Phillips para soltar ou fixar."
	elif session.selected == &"lid":
		%SelectedName.text = "Tampa lateral"
		%SelectedInfo.text = "Retirada e apoiada ao lado." if not session.lid_attached else "Retire os quatro parafusos para liberar."
	else:
		%SelectedInfo.text = "Libere parafusos, conectores e travas antes de retirar. CPU: alavanca do socket, sem parafusos."


func _notice(text: String, failed: bool) -> void:
	%ContextMessage.text = text
	%ContextMessage.modulate = Color("f0c17c") if failed else Color("9ed9e5")


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or session == null or _os_view.visible: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_1, KEY_2]:
		session.select_tool(&"hands" if event.physical_keycode == KEY_1 else &"phillips")
		get_viewport().set_input_as_handled()


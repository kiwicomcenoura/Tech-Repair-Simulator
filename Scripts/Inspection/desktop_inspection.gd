extends VBoxContainer

signal return_requested

const VideoScreen := preload("res://Scripts/UI/bench_video_screen.gd")
const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const PREVIEW_HELP := "Clique para usar a ferramenta · Arraste para girar · Roda para zoom · Botão direito para restaurar."

var session: RefCounted
var _inventory: OptionButton
var _inventory_ids: Array = []
var _power: Button
var _access_os: Button
var _os_view: PanelContainer
var _os_screen: Control
var _client_desktop: Control
var _video_effects: Control
var _memory_test: Button
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
	_access_os.text = "Acessar SO"
	_access_os.custom_minimum_size.y = 40
	header.add_child(_access_os)
	header.move_child(_access_os, 2)
	_access_os.pressed.connect(func() -> void: _show_client_os(not _os_view.visible))
	_os_view = PanelContainer.new()
	_os_view.name = "ClientOS"
	_os_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_os_view)
	var display := Control.new()
	display.clip_contents = true
	_os_view.add_child(display)
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
		var pc: Dictionary = session.workshop.ledger.item(session.physical_pc_id)
		if not pc.has("client_apps"): pc.client_apps = []
		pc.client_apps.append(id))
	display.add_child(_client_desktop)
	_client_desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video_effects = VideoScreen.new()
	_video_effects.effects_only = true
	_video_effects.status = "artifacts"
	_video_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.add_child(_video_effects)
	_video_effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	label.text = "PEÇAS · INVENTÁRIO / BANDEJA"
	label.theme_type_variation = &"Eyebrow"
	sidebar.add_child(label)
	sidebar.move_child(label, sidebar.get_node("SelectionDivider").get_index())
	_inventory = OptionButton.new()
	_inventory.name = "RAMInventory"
	_inventory.custom_minimum_size = Vector2(0, 36)
	_inventory.clip_text = true
	sidebar.add_child(_inventory)
	sidebar.move_child(_inventory, label.get_index() + 1)
	_inventory.item_selected.connect(func(index: int) -> void:
		if session == null or not is_instance_valid(session.workshop) or index >= _inventory_ids.size(): return
		session.workshop.selected_ram = _inventory_ids[index]
		session.workshop.selected_part = _inventory_ids[index]
		if preview.visible: preview.show_session(session)
		if _inventory_ids[index] == "": return
		_inventory.tooltip_text = session.workshop.ledger.known_description(_inventory_ids[index])
		session.notice.emit("Peça selecionada. Com Mãos, clique no encaixe vazio correspondente; depois fixe e reconecte.", false))


func _refresh_physical() -> void:
	var physical := session != null and is_instance_valid(session.workshop)
	_power.visible = physical
	_access_os.visible = physical
	_memory_test.visible = physical and not _os_view.visible
	_inventory.visible = physical
	_inventory.get_parent().get_node("RAMStockLabel").visible = physical
	%SelectedInfo.visible = not physical
	%SelectedName.get_parent().get_node("SelectionHeading").visible = not physical
	if not physical: return
	var model: RefCounted = session.workshop.ledger
	var pc: Dictionary = model.item(session.physical_pc_id)
	_client_desktop.set_running(pc.power)
	_power.text = "Desligar PC" if pc.power else "Ligar PC"
	_access_os.disabled = not pc.power and not _os_view.visible
	_access_os.tooltip_text = "Ligue o PC para acessar a tela do cliente." if _access_os.disabled else ""
	var test_reason: String = model.ram_test_block_reason(session.physical_pc_id)
	_memory_test.disabled = not test_reason.is_empty()
	_memory_test.tooltip_text = test_reason if not test_reason.is_empty() else "Diagnóstico de memória após o POST; também identifica módulos defeituosos que impedem o boot."
	if _os_view.visible:
		_update_client_display()
	else:
		$InspectionHeader/Titles/Description.text = model.localized_boot_result(pc)
	%Phillips.disabled = not model.state.tools
	_inventory.clear()
	var available: Array = model.available_parts()
	_inventory_ids = [""]
	_inventory.add_item("Selecione uma peça" if not available.is_empty() else "Traga uma peça desembalada")
	for id in available:
		_inventory_ids.append(id)
		var record: Dictionary = model.item(id)
		var origin := Prefs.t({"installed": "retirada do PC", "receiving": "kit recebido", "purchase": "comprada"}.get(record.get("origin", ""), ""))
		_inventory.add_item(record.model + " · " + origin)
		_inventory.get_popup().set_item_tooltip(_inventory.item_count - 1, model.known_description(id))
	_inventory.disabled = available.is_empty()
	var selected: int = _inventory_ids.find(session.workshop.selected_part)
	if selected >= 0:
		_inventory.select(selected)
	else:
		_inventory.select(0)


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
			apps = session.workshop.ledger.item(session.physical_pc_id).get("client_apps", [])
		_client_desktop.set_client_apps(apps)
	canvas.configure(session)
	if device_changed:
		preview.reset_view()
	_show_preview(preview.visible and not device_changed)
	%Phillips.disabled = session == null
	%Hands.disabled = session == null
	%LidAction.disabled = session == null
	if session == null:
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
	%Title.text = "Gabinete — vista 3D" if active else "Gabinete — lateral esquerda"
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
	var status: String = session.workshop.ledger.video_status(session.physical_pc_id)
	_os_screen.status = status
	_client_desktop.visible = status in ["desktop", "artifacts"]
	_os_screen.visible = not _client_desktop.visible
	_video_effects.visible = status == "artifacts"
	$InspectionHeader/Titles/Description.text = VideoScreen.STATUS[status]


func _show_client_os(active: bool, restore_focus: bool = true) -> void:
	_os_view.visible = active
	$Workspace.visible = not active
	$ContextPanel.visible = not active
	_access_os.text = "Voltar à inspeção" if active else "Acessar SO"
	$InspectionHeader/Titles/Eyebrow.text = "TELA DO PC DO CLIENTE" if active else "INSPEÇÃO VISUAL  /  DESKTOP ATX"
	_refresh_physical()
	if not restore_focus: return
	if _access_os.disabled: _power.grab_focus()
	else: _access_os.grab_focus()


func close_client_os(restore_focus: bool = true) -> bool:
	if not _os_view.visible: return false
	_show_client_os(false, restore_focus)
	return true


func handle_client_escape() -> bool:
	return _os_view.visible and (_client_desktop.dismiss_popup() or close_client_os())


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
	if is_instance_valid(session.workshop) and session.selected in [&"ram",&"ram2"]:
		var pc: Dictionary = session.workshop.ledger.item(session.physical_pc_id)
		var ram: Dictionary = session.workshop.ledger.item(pc.components.get(str(session.selected), ""))
		%SelectedName.text = ("Slot A1 vazio" if session.selected == &"ram" else "Slot A2 vazio") if ram.is_empty() else ram.model
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


extends CanvasLayer
## The physical dock is the only source of equipment. Never spawn a default PC.

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const VideoScreen := preload("res://Scripts/UI/bench_video_screen.gd")
const Cases := preload("res://Scripts/Equipment/case_catalog.gd")

signal opened
signal closed

@export var equipment_dock_path: NodePath = ^"../Actors/RepairBench/EquipmentDock"
var is_open := false
var _previous_pause := false
var _previous_focus: Control
var inspection_session: RefCounted
var _bound_equipment: Resource
var equipment_dock: Node2D
var _post_button: Button
var _test_power_button: Button
var _ram_test_button: Button
var _test_help: Label
var _component_picker: OptionButton
var _component_test: Button
var _video_test: Button
var _video_screen: Control
var _video_status: Label
var _component_codes := {"CPU": "cpu", "GPU": "gpu", "RAM": "ram", "MB": "motherboard", "SSD": "storage", "PSU": "psu", "FAN": "cooling"}

@onready var overlay: Control = %Overlay
@onready var prompt: Control = %InteractionPrompt
@onready var close_button: Button = %CloseButton
@onready var tabs: TabContainer = %BenchTabs
@onready var _layout: VBoxContainer = $Overlay/SafeMargins/WorkbenchWindow/Layout
@onready var inspection: Control = _layout.get_node("InspectionView")


func _ready() -> void:
	close_button.pressed.connect(close_bench)
	inspection.return_requested.connect(exit_inspection)
	_layout.get_node("Actions/Inspect").pressed.connect(open_inspection)
	_layout.get_node("Actions/Replace").pressed.connect(open_inspection)
	_build_test_controls()
	find_child("StartDiagnostic", true, false).pressed.connect(_run_post)
	equipment_dock = get_node_or_null(equipment_dock_path) as Node2D
	if equipment_dock != null:
		equipment_dock.equipment_changed.connect(_refresh_equipment)
	_refresh_equipment()
	overlay.hide()
	prompt.hide()


func _process(_delta: float) -> void:
	if inspection.visible and has_equipment() and not can_inspect():
		_refresh_equipment()
	if is_open:
		_update_tests()
		_update_component_results()


func _build_test_controls() -> void:
	var content: VBoxContainer = tabs.get_tab_control(3).get_node("Content")
	var video: VBoxContainer = content.get_node("Metrics/Stability/Content")
	video.get_node("Name").text = "MONITOR DE TESTE"
	video.get_node("Value").hide()
	_video_status = video.get_node("Status")
	_video_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_video_screen = VideoScreen.new()
	_video_screen.name = "BenchVideoScreen"
	_video_screen.custom_minimum_size = Vector2(150, 80)
	_video_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_video_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video.add_child(_video_screen)
	video.move_child(_video_screen, _video_status.get_index())
	var row := HBoxContainer.new()
	row.name = "FunctionalTests"
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	content.move_child(row, 2)
	for kind in ["post", "power", "ram"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(145, 40)
		button.name = "RunPOST" if kind == "post" else "TestPower" if kind == "power" else "RunRAMTest"
		row.add_child(button)
		if kind == "post":
			_post_button = button
			button.text = "Iniciar POST"
			button.pressed.connect(_run_post)
		elif kind == "power":
			_test_power_button = button
			button.pressed.connect(func() -> void:
				var s := _physical_test_session()
				if s != null: s.workshop.ledger.toggle_power(s.physical_pc_id))
		else:
			_ram_test_button = button
			button.text = "Testar RAM"
			button.pressed.connect(func() -> void:
				var s := _physical_test_session()
				if s != null: s.workshop.ledger.test_ram(s.physical_pc_id))
	_test_help = Label.new()
	_test_help.name = "TestPrerequisites"
	_test_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_test_help.theme_type_variation = &"Muted"
	content.add_child(_test_help)
	content.move_child(_test_help, 3)
	var extra := HBoxContainer.new()
	extra.name = "ComponentTests"
	content.add_child(extra)
	content.move_child(extra, 4)
	_component_picker = OptionButton.new()
	_component_picker.name = "ComponentTestPicker"
	_component_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for kind in ["cpu", "gpu", "motherboard", "storage", "psu", "cooling"]:
		_component_picker.add_item(preload("res://Scripts/Gameplay/workshop_ledger.gd").PART_NAMES[kind])
		_component_picker.set_item_metadata(_component_picker.item_count - 1, kind)
	extra.add_child(_component_picker)
	_component_test = Button.new()
	_component_test.name = "RunComponentTest"
	_component_test.text = "Testar componente"
	_component_test.pressed.connect(func() -> void:
		var s := _physical_test_session()
		if s != null: s.workshop.ledger.test_component(s.physical_pc_id, _component_picker.get_selected_metadata()))
	extra.add_child(_component_test)
	_video_test = Button.new()
	_video_test.name = "RunVideoTest"
	_video_test.text = "Testar vídeo"
	_video_test.pressed.connect(func() -> void:
		var s := _physical_test_session()
		if s != null: s.workshop.ledger.test_component(s.physical_pc_id, "gpu"))
	extra.add_child(_video_test)


func _physical_test_session() -> RefCounted:
	if not has_equipment() or inspection_session == null or not is_instance_valid(inspection_session.workshop): return null
	return inspection_session


func _run_post() -> void:
	var s := _physical_test_session()
	if s != null:
		s.workshop.ledger.request_post(s.physical_pc_id)
		_update_tests()


func _update_tests() -> void:
	var s := _physical_test_session()
	var available := s != null
	_component_test.disabled = not available
	var replace_button: Button = _layout.get_node("Actions/Replace")
	replace_button.disabled = not available
	replace_button.text = "Trocar componente"
	replace_button.tooltip_text = "Abrir a inspeção para desmontar e encaixar peças manualmente." if available else "Coloque um computador físico na bancada."
	var content: Node = tabs.get_tab_control(3).get_node("Content")
	var diagnostic: Button = find_child("StartDiagnostic", true, false)
	_post_button.disabled = not available
	_test_power_button.disabled = not available
	diagnostic.disabled = not available
	diagnostic.text = "Iniciar POST" if available else "Iniciar diagnóstico"
	_test_power_button.text = "Ligar PC"
	if not available:
		_update_video("off", "Coloque um computador na bancada.")
		_ram_test_button.disabled = true
		_test_help.text = "Coloque um computador físico na bancada para liberar os testes."
		content.get_node("Description").text = "Indicadores de operação. Nenhum teste foi executado."
		content.get_node("EmptyTests/Content/Title").text = "Aguardando equipamento"
		content.get_node("EmptyTests/Content/Description").text = "Os resultados aparecerão depois que um equipamento for colocado e testado."
		content.get_node("Metrics/Operation/Content/Value").text = "—"
		content.get_node("Metrics/Operation/Content/Status").text = "Sem medição"
		tabs.get_tab_control(1).get_node("Content/EmptyFindings/Content/Title").text = "Nenhum diagnóstico disponível"
		tabs.get_tab_control(1).get_node("Content/EmptyFindings/Content/Description").text = "Coloque um equipamento para executar a verificação de inicialização."
		return
	var model: RefCounted = s.workshop.ledger
	var pc: Dictionary = model.item(s.physical_pc_id)
	_update_video(model.video_status(s.physical_pc_id), model.component_test_block_reason(s.physical_pc_id, "gpu"))
	_layout.get_node("Actions/Context/Reason").text = "Inspeção, desmontagem e testes de componentes."
	var busy := float(pc.boot_remaining) > 0
	var test_kind: String = _component_picker.get_selected_metadata()
	var test_reason: String = model.component_test_block_reason(s.physical_pc_id, test_kind)
	_component_test.disabled = not test_reason.is_empty()
	_component_test.tooltip_text = test_reason
	_component_test.text = "Testando…" if pc.has("test_job") else "Testar componente"
	_post_button.disabled = busy
	diagnostic.disabled = busy
	_test_power_button.text = "Desligar PC" if pc.power else "Ligar PC"
	var power_reason: String = model.assembly_power_block_reason(s.physical_pc_id)
	_post_button.disabled = busy or not power_reason.is_empty()
	diagnostic.disabled = _post_button.disabled
	_test_power_button.disabled = not power_reason.is_empty()
	_post_button.tooltip_text = power_reason
	diagnostic.tooltip_text = power_reason
	_test_power_button.tooltip_text = power_reason
	var reason: String = model.ram_test_block_reason(s.physical_pc_id)
	_ram_test_button.disabled = not reason.is_empty()
	_ram_test_button.tooltip_text = reason if not reason.is_empty() else "Avaliar a RAM instalada, mesmo se ela impedir a inicialização do sistema."
	_test_help.text = reason if not reason.is_empty() else "Pronto para testar a RAM. O teste revela sua condição e não realiza reparos."
	if pc.has("test_job"): _test_help.text = Prefs.t("Verificando %s · %.1f s restantes") % [Prefs.t(model.PART_NAMES[pc.test_job.kind]), pc.test_job.remaining]
	content.get_node("Description").text = "Verificações básicas da bancada. Resultados ficam salvos em cada peça."
	var result: Label = content.get_node("EmptyTests/Content/Description")
	result.text = model.localized_boot_result(pc)
	content.get_node("EmptyTests/Content/Title").text = "Resultado do equipamento"
	var operation: Node = content.get_node("Metrics/Operation/Content")
	operation.get_node("Value").text = "Em teste" if busy else "POST OK" if pc.power and pc.boot_ok else "Falhou" if pc.power else "Desligado"
	operation.get_node("Value").add_theme_font_size_override("font_size", 22)
	operation.get_node("Status").text = "Inicialização" if pc.power else "Clique em Iniciar POST"
	var ram: Dictionary = model.item(pc.components.get("ram", ""))
	if not ram.is_empty() and ram.tested:
		result.text += "\nRAM A1: " + model.known_description(ram.id)
	var second_ram: Dictionary = model.item(pc.components.get("ram2",""))
	if second_ram.get("tested",false): result.text += "\nRAM A2: "+model.known_description(second_ram.id)
	var selected_kind: String = _component_picker.get_selected_metadata()
	var tested_part: Dictionary = model.item(pc.components.get(selected_kind, ""))
	if tested_part.get("tested", false): result.text += "\n" + tested_part.get("test_result", model.known_description(tested_part.id))
	var gpu: Dictionary = model.item(pc.components.get("gpu", ""))
	if selected_kind != "gpu" and gpu.has("test_result"): result.text += "\n" + gpu.test_result
	content.get_node("Metrics/Temperature/Content/Status").text = "Teste térmico indisponível"
	var diagnosis: Node = tabs.get_tab_control(1).get_node("Content")
	diagnosis.get_node("EmptyFindings/Content/Title").text = "Verificação de inicialização (POST)"
	diagnosis.get_node("EmptyFindings/Content/Description").text = model.localized_boot_result(pc)
	diagnosis.get_node("DiagnosisNote/Text").text = "Teste disponível também na aba Testes. Nenhuma peça é corrigida automaticamente."


func _update_video(status: String, prerequisite: String) -> void:
	_video_screen.status = status
	_video_status.text = VideoScreen.STATUS[status]
	_video_test.disabled = not prerequisite.is_empty()
	_video_test.tooltip_text = prerequisite if _video_test.disabled else "Verifique a saída de vídeo e exiba um padrão de cores quando o sinal estiver estável."


func show_prompt(available: bool) -> void:
	prompt.visible = available and not is_open and not get_tree().paused
	var physical: Node = get_parent().get_node_or_null("PhysicalWorkshop")
	if physical != null and is_instance_valid(physical._hint_row) and physical._hint_row.visible:
		prompt.hide()


func has_equipment() -> bool:
	return is_instance_valid(equipment_dock) and equipment_dock.has_equipment()


func can_inspect() -> bool:
	var data: Resource = equipment_dock.get_equipment() if has_equipment() else null
	return data != null and data == _bound_equipment and data.supports_inspection() and inspection_session != null


func open_bench() -> void:
	if is_open or get_tree().paused:
		return
	_refresh_equipment()
	is_open = true
	_previous_pause = get_tree().paused
	_previous_focus = get_viewport().gui_get_focus_owner()
	prompt.hide()
	tabs.current_tab = 0
	overlay.show()
	get_tree().paused = true
	close_button.grab_focus()
	opened.emit()


func close_bench() -> void:
	if not is_open:
		return
	exit_inspection()
	is_open = false
	overlay.hide()
	get_tree().paused = _previous_pause
	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus()
	closed.emit()


func open_inspection() -> bool:
	if not is_open or (has_equipment() and not can_inspect()):
		_layout.get_node("Actions/Context/Reason").text = "Nenhum equipamento na bancada." if not has_equipment() else "Este equipamento ainda não possui um perfil de inspeção compatível."
		return false
	_set_overview_visible(false)
	inspection.show()
	inspection.focus_entry()
	return true


func exit_inspection() -> void:
	if not inspection.visible:
		return
	inspection.close_case_picker()
	inspection.close_client_os(false)
	inspection.hide()
	_set_overview_visible(true)
	if close_button.is_inside_tree(): close_button.grab_focus()


func _set_overview_visible(value: bool) -> void:
	_layout.get_node("Body").visible = value
	_layout.get_node("Actions").visible = value
	_layout.get_node("FooterDivider").visible = value


func _refresh_equipment() -> void:
	var data: Resource = equipment_dock.get_equipment() if has_equipment() else null
	if data != null and not data.supports_inspection():
		exit_inspection()
	var was_empty := inspection_session == null
	_bound_equipment = data
	inspection_session = data.get_inspection_session() if data != null else null
	inspection.configure(inspection_session)
	if inspection.visible and was_empty != (inspection_session == null):
		inspection.focus_entry()
	var present := data != null
	var assembly_case: bool = present and not data.case_key.is_empty()
	var equipment := _layout.get_node("Body/EquipmentPanel/Content")
	equipment.get_node("EquipmentName").text = (data.display_name if not data.display_name.is_empty() else data.equipment_id) if present else "Nenhum equipamento na bancada"
	equipment.get_node("EquipmentIllustration").visible = present and not assembly_case
	equipment.get_node("EmptyExplanation").text = "Equipamento físico associado à área de apoio." if present else "Coloque um equipamento físico na bancada para consultar seus dados."
	equipment.get_node("Type/Value").text = "Gabinete" if assembly_case else str(data.equipment_type).capitalize() if present else "—"
	equipment.get_node("Condition/Value").text = data.condition if present else "—"
	equipment.get_node("Status/Value").text = data.maintenance_state if present else "Aguardando equipamento"
	equipment.get_node("Status/Value").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_layout.get_node("Header/Status/Text").text = "○  EQUIPAMENTO ASSOCIADO" if present else "○  SEM EQUIPAMENTO"
	_layout.get_node("Actions/Context/Reason").text = ("Inspeção visual disponível. Reparos e testes indisponíveis." if can_inspect() else "Perfil de inspeção não disponível para este equipamento.") if present else "Abra a inspeção para escolher um gabinete comprado."
	var overview := tabs.get_tab_control(0).get_node("Content")
	overview.get_node("InformationCards/Identification/Content/Value").text = Cases.get_model(data.case_key).format if assembly_case else "Desktop · ATX" if present else "—"
	overview.get_node("InformationCards/Identification/Content/Caption").text = (Prefs.t("Proprietário: %s") % (data.owner_name if not data.owner_name.is_empty() else data.owner_id)) if present else "Nome, modelo e número de série"
	overview.get_node("InformationCards/Condition/Content/Value").text = data.condition if present else "—"
	overview.get_node("InformationCards/Condition/Content/Caption").text = "Sem diagnóstico ou testes executados" if present else "Estado e situação de manutenção"
	overview.get_node("EquipmentPreview/Content/Blueprint").visible = present and not assembly_case
	overview.get_node("EquipmentPreview/Content/EmptyTitle").text = equipment.get_node("EquipmentName").text
	overview.get_node("EquipmentPreview/Content/EmptyCaption").text = "Use Inspecionar para acessar o equipamento compatível." if present else "Abra a inspeção para escolher um gabinete comprado."
	var component_keys := {"CPU": "cpu", "GPU": "gpu", "RAM": "ram", "MB": "motherboard", "SSD": "storage", "PSU": "psu", "FAN": "cooling"}
	for code in component_keys:
		var value := "Slot vazio"
		if present:
			value = "Presente · não testado" if data.components.has(component_keys[code]) and data.components[component_keys[code]] != null else "Slot vazio" if assembly_case else "Não informado"
			if code == "RAM" and inspection_session != null and is_instance_valid(inspection_session.workshop) and not data.components.has("ram"):
				value = "Slot vazio"
		tabs.get_tab_control(2).get_node("Content/ComponentSlots/Slot" + code + "/Row/Labels/Empty").text = value
	tabs.get_tab_control(1).get_node("Content/DiagnosisNote/Text").text = "Nenhum diagnóstico executado." if present else "Aguardando equipamento para análise."
	tabs.get_tab_control(3).get_node("Content/EmptyTests/Content/Title").text = "Nenhum teste executado" if present else "Aguardando equipamento"
	var inspect_button: Button = _layout.get_node("Actions/Inspect")
	inspect_button.disabled = present and not can_inspect()
	inspect_button.tooltip_text = "Abrir inspeção visual" if not inspect_button.disabled else "Indisponível: coloque um equipamento físico compatível na bancada."
	for name in ["Replace", "Finish", "StartDiagnostic"]:
		find_child(name, true, false).disabled = true
		find_child(name, true, false).tooltip_text = "Operação ainda não implementada." if present else "Indisponível: nenhum equipamento na bancada."
	_update_tests()


func _input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if inspection.visible:
			if not inspection.close_case_picker() and not inspection.handle_client_escape(): exit_inspection()
		else:
			close_bench()


func _exit_tree() -> void:
	if is_open:
		get_tree().paused = _previous_pause


func _update_component_results() -> void:
	var s := _physical_test_session()
	if s == null: return
	var model: RefCounted = s.workshop.ledger
	var pc: Dictionary = model.item(s.physical_pc_id)
	for code in _component_codes:
		var record: Dictionary = model.item(pc.components.get(_component_codes[code], ""))
		var label: Label = tabs.get_tab_control(2).get_node("Content/ComponentSlots/Slot" + code + "/Row/Labels/Empty")
		label.text = "Slot vazio" if record.is_empty() else ("%d%% · %s" % [record.health, Prefs.t(model.condition_label(record.health))] if record.tested else "Presente · não testado")
		label.tooltip_text = "" if record.is_empty() else model.known_description(record.id)
		if code == "RAM":
			var lines: Array[String] = []
			for key in ["ram","ram2"]:
				var module: Dictionary = model.item(pc.components.get(key,""))
				lines.append(("A1: " if key == "ram" else "A2: ")+(Prefs.t("Vazio") if module.is_empty() else "%d%% · %s" % [module.health, Prefs.t(model.condition_label(module.health))] if module.tested else Prefs.t("Presente · não testado")))
			label.text = "\n".join(lines)
			label.add_theme_font_size_override("font_size",12)


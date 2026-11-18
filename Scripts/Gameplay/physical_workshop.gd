extends Node

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
## Physical controller, persistence and derived views of WorkshopLedger.

const Orders := preload("res://Scripts/Gameplay/service_orders.gd")
const Ledger := preload("res://Scripts/Gameplay/workshop_ledger.gd")
const Data := preload("res://Scripts/Equipment/equipment_data.gd")
const Session := preload("res://Scripts/Inspection/inspection_session.gd")
const Actor := preload("res://Scenes/Items/PhysicalItem.tscn")
const Proximity := preload("res://Scripts/World/interaction_range.gd")
const TOOLBOX_ACCESS_POSITION := Vector2(-210, 50)

@export var save_path: String = "user://workshop_save_v1.json"
@export var start_with_delivery := false
var ledger := Ledger.new()
var actors: Dictionary = {}
var equipment_views: Dictionary = {}
var selected_ram := ""
var selected_part := ""
var storage_ui: CanvasLayer
var decoration_ui: CanvasLayer
var settings_ui: CanvasLayer
var orders_ui: CanvasLayer
var last_message := "Abra Pedidos (O) para receber seu primeiro gabinete. As ferramentas ficam junto à prateleira."
var _syncing := false
var _hud: CanvasLayer
var _hint_row: HBoxContainer
var _hint_style: StyleBoxFlat
var _hint_text := ""
var _status: Label

@onready var player: CharacterBody2D = get_parent().get_node("Actors/Player")
@onready var dock: Node2D = get_parent().get_node("Actors/RepairBench/EquipmentDock")
@onready var test_station: Node2D = dock.get_parent().get_node("TestStation")
@onready var bench_ui: CanvasLayer = get_parent().get_node("MaintenanceBenchUI")
@onready var actor_parent: Node2D = get_parent().get_node("Actors")
@onready var counter: Node2D = actor_parent.get_node("ServiceCounter")


func _ready() -> void:
	ledger.changed.connect(_on_changed)
	ledger.feedback.connect(_feedback)
	ledger.new_game(false)
	_make_hud()
	storage_ui = preload("res://Scenes/UI/StorageInventory.tscn").instantiate()
	storage_ui.workshop = self
	add_child(storage_ui)
	decoration_ui = preload("res://Scripts/UI/workshop_customization.gd").new()
	decoration_ui.workshop = self
	add_child(decoration_ui)
	settings_ui = preload("res://Scripts/UI/settings_menu.gd").new()
	settings_ui.workshop = self
	add_child(settings_ui)
	if not save_path.is_empty() and (FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak") or FileAccess.file_exists(save_path + ".tmp")):
		if not load_game(): last_message = "Salvamento inválido; cópias preservadas. Nenhum equipamento novo foi gerado. F9 tenta restaurar novamente."
	else:
		ledger.new_game(start_with_delivery)
		Orders.ensure(ledger, not start_with_delivery)
	Orders.ensure(ledger)
	orders_ui = preload("res://Scripts/UI/service_orders_ui.gd").new()
	orders_ui.workshop = self
	add_child(orders_ui)
	_sync_nodes()
	var guide := preload("res://Scripts/Gameplay/first_service_guide.gd").new()
	guide.name = "FirstServiceGuide"
	add_child(guide)
	preload("res://Scripts/World/workshop_appearance.gd").apply(get_parent(),ledger.state.get("decoration",{}))
	bench_ui.inspection.return_requested.connect(bench_ui._refresh_equipment, CONNECT_DEFERRED)
	var markers := Node2D.new()
	markers.set_script(preload("res://Scripts/Gameplay/workshop_markers.gd"))
	markers.name = "WorkshopMarkers"
	markers.workshop = self
	get_parent().add_child.call_deferred(markers)


func _make_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 6
	add_child(_hud)
	var balance := PanelContainer.new()
	balance.name = "Wallet"
	balance.position = Vector2(20, 16)
	var wallet_style := StyleBoxFlat.new()
	wallet_style.bg_color = Color("0d1d2b")
	wallet_style.border_color = Color("47738b")
	wallet_style.set_border_width_all(1)
	wallet_style.set_corner_radius_all(8)
	wallet_style.content_margin_left = 14
	wallet_style.content_margin_right = 14
	wallet_style.content_margin_top = 8
	wallet_style.content_margin_bottom = 8
	balance.add_theme_stylebox_override("panel", wallet_style)
	_hud.add_child(balance)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 17)
	balance.add_child(_status)
	var hint_center := CenterContainer.new()
	_hud.add_child(hint_center)
	hint_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_center.offset_left = 24
	hint_center.offset_right = -24
	hint_center.offset_top = -148
	hint_center.offset_bottom = -96
	hint_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color(0.055, 0.10, 0.15, 0.96)
	hint_style.border_color = Color("47647b")
	hint_style.set_border_width_all(1)
	hint_style.set_corner_radius_all(8)
	hint_style.content_margin_left = 16
	hint_style.content_margin_right = 16
	hint_style.content_margin_top = 10
	hint_style.content_margin_bottom = 10
	hint_style.shadow_color = Color(0, 0, 0, 0.25)
	hint_style.shadow_size = 4
	_hint_row = HBoxContainer.new()
	_hint_row.add_theme_constant_override("separation", 8)
	hint_center.add_child(_hint_row)
	_hint_style = hint_style
	var settings := Button.new()
	settings.name = "OpenSettings"
	settings.theme = preload("res://Themes/maintenance_bench.tres")
	_hud.add_child(settings)
	settings.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	settings.offset_left = -200
	settings.offset_right = -20
	settings.offset_top = 16
	settings.offset_bottom = 58
	settings.text = "Configurações (Esc)"
	settings.pressed.connect(func() -> void: settings_ui.open_menu())
	var jobs := Button.new()
	jobs.name = "OpenOrders"
	jobs.theme = settings.theme
	_hud.add_child(jobs)
	jobs.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	jobs.offset_left = -358
	jobs.offset_right = -212
	jobs.offset_top = 16
	jobs.offset_bottom = 58
	jobs.text = "Pedidos (O)"
	jobs.pressed.connect(func() -> void: orders_ui.open_menu())

func _process(delta: float) -> void:
	ledger.tick(delta)
	test_station.status = ledger.video_status(ledger.bench_id())
	if not get_tree().paused: Orders.tick(ledger, delta)
	var held := ledger.carried()
	if held != "" and actors.has(held):
		actors[held].global_position = player.global_position + Vector2(22, -20)
		actors[held].z_index = 3
	_hud.visible = not get_tree().paused
	_status.text = Prefs.money(ledger.state.credits)
	var text := Prefs.t(_prompt())
	if text != _hint_text:
		_hint_text = text
		for child in _hint_row.get_children():
			_hint_row.remove_child(child)
			child.queue_free()
		for caption in text.split("\n", false):
			var panel := PanelContainer.new()
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_theme_stylebox_override("panel", _hint_style)
			var label := Label.new()
			label.text = caption
			label.add_theme_font_size_override("font_size", 16)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(label)
			_hint_row.add_child(panel)
	_hint_row.visible = not text.is_empty()
	if _hint_row.visible:
		bench_ui.prompt.hide()
		get_parent().get_node("PersonalComputerUI").get_node("%PersonalPrompt").hide()

func _bench_distance() -> float:
	return Proximity.distance_to_item(player, dock.get_parent().get_node("Body/Solid19"))


func _near_shelf() -> bool:
	return player.global_position.distance_to(Vector2(-250, -5)) < 50.0


func _near_tools() -> bool:
	return not ledger.state.tools and player.global_position.distance_to(TOOLBOX_ACCESS_POSITION) < 42.0


func _near_counter() -> bool:
	return Proximity.distance_to_item(player, actor_parent.get_node("ServiceCounter/Body/Solid54")) <= 48.0


func _nearest_item() -> String:
	var result := ""
	var distance := 40.0
	for id in actors:
		var r: Dictionary = ledger.item(id)
		if r.location not in ["floor", "tray"]: continue
		var interaction_point: Vector2 = actors[id].global_position
		if r.location == "tray":
			# Project the tabletop unit to a reachable point in front of its
			# diagonal bench face. Do not require standing inside the furniture.
			var bench_position: Vector2 = dock.get_parent().global_position
			interaction_point.y = bench_position.y - absf(interaction_point.x - bench_position.x) * 0.5 + 20.0
		var d := player.global_position.distance_to(interaction_point)
		if d < distance:
			distance = d
			result = id
	return result


func _counter_pickup() -> String:
	if not _near_counter():
		return ""
	var nearest := INF
	var result := ""
	for id in ledger.at("counter"):
		var slot := int(ledger.item(id).counter_slot)
		# Compare slots on the floor plane. The counter footprint handles reach from either side.
		var slot_position := counter.to_global(Vector2(-88 + slot * 46, -76 + slot * 23))
		var distance := player.global_position.distance_squared_to(slot_position)
		if distance < nearest:
			nearest = distance
			result = id
	return result


func _bench_pickup() -> String:
	return ledger.bench_id() if _bench_distance() <= 48.0 else ""


func _prompt() -> String:
	var held := ledger.carried()
	if _near_counter():
		if held.is_empty() and not _counter_pickup().is_empty(): return "F — Atendimento e pedidos\nE — Pegar gabinete"
		return "F — Atendimento e pedidos"
	if held != "":
		if _bench_distance() <= 48: return "E — Colocar gabinete na bancada" if ledger.item(held).kind == "pc" else "E — Guardar componente na bandeja"
		if _near_shelf(): return "F — Abrir armário para guardar peça"
		return Prefs.t("Carregando: %s\nE — Soltar") % ledger.item(held).model
	if _near_tools(): return "F — Abrir caixa de ferramentas"
	if _near_shelf(): return "F — Abrir armário\nI — Inventário"
	var nearest := _nearest_item()
	if nearest != "":
		var item_hint := Prefs.t("E — Abrir embalagem · " if ledger.item(nearest).packaged else "E — Pegar · ") + ledger.known_description(nearest)
		if not _bench_pickup().is_empty():
			item_hint += "\n" + Prefs.t("Shift+E — Pegar gabinete")
		return item_hint
	var bench_pc := _bench_pickup()
	if not bench_pc.is_empty():
		return "F — Abrir bancada\nDesligue o PC para transportá-lo" if ledger.item(bench_pc).power else "F — Abrir bancada\nE — Pegar gabinete"
	return ""


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE and not get_tree().paused:
			get_viewport().set_input_as_handled(); settings_ui.open_menu(); return
		if event.physical_keycode == KEY_F2 and not get_tree().paused:
			get_viewport().set_input_as_handled(); decoration_ui.open_menu(); return
		if event.physical_keycode == KEY_O and not get_tree().paused:
			get_viewport().set_input_as_handled(); orders_ui.open_menu(); return
		if event.physical_keycode == KEY_I and not get_tree().paused:
			get_viewport().set_input_as_handled(); storage_ui.open_storage(false); return
		if event.physical_keycode == KEY_F5:
			get_viewport().set_input_as_handled(); save_game(); return
		if event.physical_keycode == KEY_F9:
			get_viewport().set_input_as_handled(); load_game(); return
	if get_tree().paused or event.is_echo(): return
	if event.is_action_pressed("interact"):
		if _near_counter():
			get_viewport().set_input_as_handled(); orders_ui.open_menu(); return
		if _near_tools():
			get_viewport().set_input_as_handled()
			ledger.state.tools = true
			ledger.done("Caixa aberta: chave Phillips liberada na inspeção.", "package")
		elif _near_shelf():
			get_viewport().set_input_as_handled()
			storage_ui.open_storage(true)
		return
	if not event.is_action_pressed("handle_item"): return
	var held := ledger.carried()
	if held != "":
		get_viewport().set_input_as_handled()
		if _bench_distance() <= 48:
			ledger.move(held, "bench" if ledger.item(held).kind == "pc" else "tray")
		else:
			var target := player.global_position + Vector2(0, 24)
			if _can_drop(target): ledger.move(held, "floor", target)
			else: ledger.fail("Não há espaço livre para soltar o item aqui.")
		return
	var bench_pc := _bench_pickup()
	var nearest := _counter_pickup()
	if event is InputEventKey and event.shift_pressed and not bench_pc.is_empty():
		nearest = bench_pc
	elif nearest.is_empty():
		nearest = _nearest_item()
		if nearest.is_empty():
			nearest = bench_pc
	if nearest != "":
		get_viewport().set_input_as_handled()
		if ledger.item(nearest).packaged: ledger.unpack(nearest)
		else: ledger.move(nearest, "carried")


func _can_drop(point: Vector2) -> bool:
	if absf(point.y + point.x * 0.5) > 260 or absf(point.y - point.x * 0.5) > 260: return false
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	query.shape = circle
	query.transform = Transform2D(0, point)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _on_changed() -> void:
	_syncing = true
	_sync_nodes()
	if selected_ram not in ledger.available_ram(): selected_ram = ""
	for data in equipment_views.values():
		var session: RefCounted = data.get_inspection_session()
		if session != null: session.changed.emit()
	_syncing = false
	save_game(false)


func _session_changed(_pc_id: String) -> void:
	if _syncing: return
	_sync_nodes()
	save_game(false)


func _feedback(text: String, failed: bool) -> void:
	last_message = text
	var id := ledger.bench_id()
	if id != "" and equipment_views.has(id):
		var session: RefCounted = equipment_views[id].get_inspection_session()
		if session != null: session.notice.emit(text, failed)


func _sync_nodes() -> void:
	for id in actors.keys():
		var r: Dictionary = ledger.item(id)
		if r.is_empty() or r.location in ["installed", "delivery", "inventory", "shelf", "returned"]:
			var old: Node2D = actors[id]
			if old.get_parent() != null: old.get_parent().remove_child(old)
			old.queue_free()
			actors.erase(id)
	for r in ledger.state.items.values():
		if r.kind == "pc": _sync_equipment(r)
		if r.location in ["installed", "delivery", "inventory", "shelf", "returned"]: continue
		if not actors.has(r.id):
			var actor: Node2D = Actor.instantiate()
			actor.item_id = r.id
			actor.set_meta("workshop_controller", self)
			actor_parent.add_child(actor)
			actors[r.id] = actor
		var node: Node2D = actors[r.id]
		node.show_record(r)
		node.z_index = 0
		if r.kind == "pc": node.equipment_data = equipment_views[r.id]
		if r.location == "bench":
			node.z_index = 1
			if node.get_parent() != dock.slot:
				node.global_position = dock.slot.global_position
				var was_syncing := _syncing
				_syncing = true
				dock.place_equipment(node)
				_syncing = was_syncing
		elif r.location == "counter":
			if node.get_parent() != counter: node.reparent(counter, true)
			var slot := int(r.counter_slot)
			node.position = Vector2(-88 + slot * 46, -129 + slot * 23)
		else:
			if node.get_parent() != actor_parent:
				node.reparent(actor_parent, true)
			match r.location:
				"carried": node.global_position = player.global_position + Vector2(22, -20); node.z_index = 3
				"tray":
					var index: int = ledger.at("tray").find(r.id)
					node.global_position = dock.slot.global_position + Vector2(-42 + index * 20, 19)
				_: node.global_position = Vector2(r.position[0], r.position[1])


func _sync_equipment(pc: Dictionary) -> void:
	if not equipment_views.has(pc.id):
		var data := Data.new()
		data.equipment_id = pc.id
		data.equipment_type = &"desktop"
		data.inspection_profile = &"desktop_atx"
		data.owner_id = "recebimento"
		data.owner_name = Orders.get_order(ledger, pc.get("service_order", "")).get("client", "Equipamento recebido")
		var session := Session.new()
		session.bind_workshop(self, pc.id)
		session.changed.connect(_session_changed.bind(pc.id))
		data._inspection_session = session
		equipment_views[pc.id] = data
	var resource: Resource = equipment_views[pc.id]
	resource.display_name = pc.model
	resource.components = pc.components.duplicate()
	resource.maintenance_state = "Inicialização aprovada" if pc.boot_ok else "Em manutenção"


func place_via_dock(item: Node2D) -> bool:
	var id: String = item.item_id
	if actors.get(id) != item or ledger.item(id).get("kind") != "pc": return false
	return ledger.move(id, "bench")


func remove_via_dock(item: Node2D, world_position: Vector2) -> Node2D:
	var id: String = item.item_id
	if actors.get(id) != item or ledger.bench_id() != id: return null
	if not _can_drop(world_position):
		ledger.fail("Não há espaço livre para retirar o gabinete nessa posição.")
		return null
	return item if ledger.move(id, "floor", world_position) else null


func save_game(notify: bool = true) -> bool:
	if save_path.is_empty(): return true
	ledger.state.player = [player.global_position.x, player.global_position.y]
	if not ledger.valid(ledger.state):
		_feedback("Estado inconsistente: salvamento bloqueado para proteger seus itens.", true)
		return false
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		_feedback("Falha ao salvar. O progresso continua em memória; tente F5 novamente.", true)
		return false
	file.store_string(JSON.stringify(ledger.state))
	file.flush()
	file.close()
	if FileAccess.file_exists(save_path):
		var previous := FileAccess.open(save_path, FileAccess.READ)
		var parsed: Variant = _parse_json(previous.get_as_text()) if previous != null else null
		if previous != null: previous.close()
		var suffix := ".bak" if parsed is Dictionary and ledger.valid(parsed) else ".corrupt"
		if FileAccess.file_exists(save_path + suffix): DirAccess.remove_absolute(save_path + suffix)
		if DirAccess.rename_absolute(save_path, save_path + suffix) != OK:
			_feedback("Falha ao preservar o arquivo anterior. O progresso continua em memória; tente F5.", true)
			return false
	if DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK:
		if FileAccess.file_exists(save_path + ".bak"): DirAccess.rename_absolute(save_path + ".bak", save_path)
		_feedback("Não foi possível concluir o salvamento; a cópia anterior foi preservada.", true)
		return false
	if notify: _feedback("Progresso salvo: equipamentos, inventário e posições.", false)
	return true


func load_game() -> bool:
	if save_path.is_empty(): return false
	var candidate: Variant = null
	for path in [save_path, save_path + ".bak", save_path + ".tmp"]:
		if not FileAccess.file_exists(path): continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null: continue
		var parsed: Variant = _parse_json(file.get_as_text())
		if parsed is Dictionary and ledger.valid(parsed, 12):
			# Keep legacy inventory contents reachable after reducing capacity.
			var inventory_slot := 0
			var used_slots: Array[int] = []
			for record in parsed.items.values():
				if record.location != "inventory": continue
				if inventory_slot < ledger.INVENTORY_CAPACITY:
					var slot := int(record.get("inventory_slot", -1))
					if slot < 0 or slot >= ledger.INVENTORY_CAPACITY or slot in used_slots:
						slot = 0
						while slot in used_slots: slot += 1
					record.inventory_slot = slot
					used_slots.append(slot)
				else:
					record.location = "floor"
					record.position = [210 + (inventory_slot % 3) * 12, 90 + floori(inventory_slot / 3.0) * 12]
				inventory_slot += 1
			candidate = parsed
			break
	if candidate == null:
		_feedback("Não há salvamento válido. O estado atual foi preservado.", true)
		return false
	bench_ui.close_bench()
	if is_instance_valid(orders_ui): orders_ui.close_menu()
	if is_instance_valid(decoration_ui): decoration_ui.close_menu()
	if is_instance_valid(storage_ui): storage_ui.close_storage()
	get_parent().get_node("PersonalComputerUI").close_computer()
	for node in actors.values():
		if node.get_parent() != null: node.get_parent().remove_child(node)
		node.queue_free()
	actors.clear()
	equipment_views.clear()
	selected_ram = ""
	ledger.state = candidate
	ledger.update_cpu_models()
	_store_legacy_ram()
	_restore_legacy_reception()
	preload("res://Scripts/World/workshop_appearance.gd").apply(get_parent(),ledger.state.get("decoration",{}))
	player.global_position = Vector2(candidate.player[0], candidate.player[1])
	_sync_nodes()
	bench_ui._refresh_equipment()
	_feedback("Progresso restaurado sem gerar novas unidades.", false)
	return true


func _store_legacy_ram() -> void:
	if ledger.at("shelf").size() >= ledger.shelf_capacity(): return
	for id in ledger.at("floor"):
		var part: Dictionary = ledger.item(id)
		if part.kind != "ram" or part.get("origin") != "receiving": continue
		var used: Array = []
		for stored in ledger.at("shelf"): used.append(int(ledger.item(stored).shelf_slot))
		var slot := 0
		while slot in used: slot += 1
		part.location = "shelf"
		part.shelf_slot = slot
		return


func _restore_legacy_reception() -> void:
	var old_positions := [Vector2(190, 105), Vector2(230, 80), Vector2(270, 55), Vector2(190, 145), Vector2(230, 120), Vector2(270, 95)]
	var used: Array = []
	for id in ledger.at("counter"): used.append(int(ledger.item(id).counter_slot))
	for id in ledger.at("floor"):
		var pc: Dictionary = ledger.item(id)
		if not pc.has("service_order") or Vector2(pc.position[0], pc.position[1]) not in old_positions: continue
		var slot := 0
		while slot in used: slot += 1
		if slot >= ledger.COUNTER_CAPACITY: return
		pc.location = "counter"
		pc.counter_slot = slot
		used.append(slot)


func _parse_json(text: String) -> Variant:
	var parser := JSON.new()
	return parser.data if parser.parse(text) == OK else null

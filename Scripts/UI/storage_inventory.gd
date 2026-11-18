extends CanvasLayer
## Views transfer the same unit between exclusive physical locations.
const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const PartVisuals := preload("res://Scripts/UI/part_visuals.gd")
var workshop: Node
var is_open := false
var shelf_access := false
var overlay: Control
var columns: HBoxContainer
var heading: Label
var message: Label
var category: OptionButton
var _previous_pause := false
var _expansion_row: HBoxContainer
var _expansion_summary: Label
var _expand_button: Button
var _expansion_confirmation: CanvasLayer
var _pending_expansion := ""

func _ready() -> void:
	overlay = Control.new()
	overlay.theme = preload("res://Themes/maintenance_bench.tres")
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.025,0.045,0.84)
	overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margins := MarginContainer.new()
	overlay.add_child(margins)
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right"]: margins.add_theme_constant_override("margin_"+edge,64)
	for edge in ["top","bottom"]: margins.add_theme_constant_override("margin_"+edge,64)
	var panel := PanelContainer.new()
	margins.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0f1c29")
	style.border_color = Color("365567")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel",style)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",16)
	panel.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size",24)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := Button.new()
	close.text = "Fechar · ESC"
	close.pressed.connect(close_storage)
	header.add_child(close)
	_build_expansion_controls(layout)
	category = OptionButton.new()
	category.add_item("Todas as categorias")
	for kind in workshop.ledger.PART_NAMES: category.add_item(workshop.ledger.PART_NAMES[kind])
	category.item_selected.connect(func(_index: int) -> void: refresh())
	layout.add_child(category)
	columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation",20)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(columns)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(message)
	workshop.ledger.changed.connect(refresh)
	workshop.ledger.feedback.connect(func(text: String, _failed: bool) -> void:
		if is_open: message.text = text)
	overlay.hide()

func _build_expansion_controls(layout: VBoxContainer) -> void:
	_expansion_row = HBoxContainer.new()
	_expansion_row.add_theme_constant_override("separation", 16)
	layout.add_child(_expansion_row)
	_expansion_summary = Label.new()
	_expansion_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_expansion_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_expansion_row.add_child(_expansion_summary)
	_expand_button = Button.new()
	_expand_button.name = "BuyShelfExpansion"
	_expand_button.pressed.connect(_ask_for_expansion)
	_expansion_row.add_child(_expand_button)
	_expansion_confirmation = preload("res://Scenes/UI/PurchaseConfirmation.tscn").instantiate()
	_expansion_confirmation.heading_text = "CONFIRMAR COMPRA / ARMÁRIO"
	_expansion_confirmation.confirmed.connect(_confirm_expansion)
	_expansion_confirmation.canceled.connect(func() -> void: _pending_expansion = "")
	add_child(_expansion_confirmation)

func _refresh_expansion() -> void:
	_expansion_row.visible = shelf_access
	if not shelf_access: return
	var expansion: Dictionary = workshop.ledger.next_shelf_expansion()
	_expand_button.visible = not expansion.is_empty()
	if expansion.is_empty():
		_expansion_summary.text = Prefs.t("Capacidade máxima do armário alcançada.")
		return
	var reason: String = workshop.ledger.shelf_expansion_block_reason(expansion)
	_expand_button.disabled = not reason.is_empty()
	_expand_button.text = Prefs.t("Ampliar armário · %s") % Prefs.money(expansion.price)
	_expansion_summary.text = Prefs.t("Amplie o armário de %d para %d espaços.") % [workshop.ledger.shelf_capacity(), expansion.capacity]
	if not reason.is_empty(): _expansion_summary.text += " " + reason

func _ask_for_expansion() -> void:
	if not is_open or not shelf_access or not workshop._near_shelf() or _expansion_confirmation.visible: return
	var expansion: Dictionary = workshop.ledger.next_shelf_expansion()
	if expansion.is_empty() or not workshop.ledger.shelf_expansion_block_reason(expansion).is_empty(): return
	_pending_expansion = expansion.id
	_expansion_confirmation.dialog_text = Prefs.t("Ampliar o armário para %d espaços por %s?") % [expansion.capacity, Prefs.money(expansion.price)]
	_expansion_confirmation.popup_centered()

func _confirm_expansion() -> void:
	var id := _pending_expansion
	_pending_expansion = ""
	if not id.is_empty() and is_open and shelf_access and workshop._near_shelf():
		workshop.ledger.buy_shelf_expansion(id)

func open_storage(near_shelf: bool) -> void:
	if is_open: return
	if near_shelf and not workshop._near_shelf(): return
	shelf_access = near_shelf
	_previous_pause = get_tree().paused
	is_open = true
	get_tree().paused = true
	overlay.show()
	message.text = "Selecione uma peça para transferir. Gabinetes são transportados nas mãos."
	refresh()

func close_storage() -> void:
	if not is_open: return
	is_open = false
	overlay.hide()
	_expansion_confirmation.hide()
	_pending_expansion = ""
	get_tree().paused = _previous_pause

func _input(event: InputEvent) -> void:
	if _expansion_confirmation.visible: return
	if is_open and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE,KEY_I]:
		get_viewport().set_input_as_handled()
		close_storage()

func refresh() -> void:
	if not is_open: return
	for child in columns.get_children():
		columns.remove_child(child)
		child.queue_free()
	heading.text = "Armário de peças" if shelf_access else "Inventário da oficina"
	_refresh_expansion()
	_build_column(Prefs.t("INVENTÁRIO · %d / %d") % [workshop.ledger.at("inventory").size(), workshop.ledger.INVENTORY_CAPACITY], ["inventory","carried"], "shelf" if shelf_access else "carried")
	if shelf_access: _build_column(Prefs.t("ARMÁRIO · %d / %d") % [workshop.ledger.at("shelf").size(), workshop.ledger.shelf_capacity()],["shelf"],"inventory")

func _build_column(title: String, locations: Array, destination: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var label := Label.new()
	label.text = title
	layout.add_child(label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	scroll.add_child(grid)
	var location := "shelf" if locations == ["shelf"] else "inventory"
	var capacity: int = workshop.ledger.shelf_capacity() if location == "shelf" else workshop.ledger.INVENTORY_CAPACITY
	var slots: Dictionary = {}
	for id in workshop.ledger.at(location):
		var record: Dictionary = workshop.ledger.item(id)
		var index := int(record.get("shelf_slot" if location == "shelf" else "inventory_slot", -1))
		if index < 0 or index >= capacity or slots.has(index):
			index = 0
			while slots.has(index): index += 1
		slots[index] = id
		record["shelf_slot" if location == "shelf" else "inventory_slot"] = index
	for i in range(capacity):
		var button := preload("res://Scripts/UI/storage_slot.gd").new()
		button.inventory = self
		button.location = location
		button.slot = i
		button.custom_minimum_size = Vector2(100,100)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.item_id = slots.get(i,"")
		button.tooltip_text = Prefs.t("Espaço %02d · Arraste uma peça aqui") % (i+1)
		if not button.item_id.is_empty():
			var record: Dictionary = workshop.ledger.item(button.item_id)
			button.name = "Transfer_"+button.item_id
			var caption: String = record.model
			if record.kind == "ram":
				var ddr: String = record.get("ddr", "")
				if not ddr.is_empty() and not caption.containsn(ddr):
					caption += " · " + ddr
			button.display_part(PartVisuals.storage_icon(record), caption)
			button.tooltip_text = workshop.ledger.known_description(button.item_id)
			button.pressed.connect(_transfer.bind(button.item_id,destination))
		grid.add_child(button)
	# A carried part remains available for storing via this explicit action.
	if location == "inventory" and workshop.ledger.carried() != "":
		var held: String = workshop.ledger.carried()
		if workshop.ledger.item(held).kind != "pc":
			var store := Button.new()
			store.name = "StoreHeldPart"
			store.text = "Guardar peça das mãos"
			store.pressed.connect(_transfer.bind(held,"inventory"))
			layout.add_child(store)

func drop_item(id: String, destination: String, slot: int) -> void:
	if destination == "shelf" and (not shelf_access or not workshop._near_shelf()): return
	workshop.ledger.arrange_storage(id,destination,slot)

func _transfer(id: String, destination: String) -> void:
	if shelf_access and not workshop._near_shelf():
		message.text = "Aproxime-se do armário."
		return
	workshop.ledger.move(id,destination)



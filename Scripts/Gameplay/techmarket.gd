extends VBoxContainer

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
## Catalog views never debit credits until explicit confirmation.
var workshop: Node
var sidebar: PanelContainer
var _balance: Label
var _feedback: RichTextLabel
var _buttons: Dictionary = {}
var _categories: Dictionary = {}
var products: VBoxContainer
var preview: TextureRect
var preview_name: Label
var confirmation: CanvasLayer
var pending_product := ""
var _previewed: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation",10)
	_balance = Label.new()
	_balance.add_theme_font_size_override("font_size",18)
	add_child(_balance)
	var subtitle := Label.new()
	subtitle.text = "TechMarket / Componentes · Entrega física em 3 s"
	subtitle.add_theme_font_size_override("font_size",12)
	add_child(subtitle)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(body)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(240,160)
	body.add_child(scroll)
	products = VBoxContainer.new()
	products.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	products.add_theme_constant_override("separation",8)
	scroll.add_child(products)
	for entry in workshop.ledger.CATALOG:
		var button := Button.new()
		button.name = "Buy_" + entry.key
		button.custom_minimum_size.y = 62
		button.add_theme_font_size_override("font_size",12)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.pressed.connect(_buy.bind(entry.key))
		button.mouse_entered.connect(_preview.bind(entry))
		button.focus_entered.connect(_preview.bind(entry))
		products.add_child(button)
		_buttons[entry.key] = button
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 190
	body.add_child(card)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation",8)
	card.add_child(detail)
	preview = TextureRect.new()
	preview.name = "ProductPreview"
	preview.custom_minimum_size = Vector2(170,80)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail.add_child(preview)
	preview_name = Label.new()
	preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_name.add_theme_font_size_override("font_size",13)
	detail.add_child(preview_name)
	_feedback = RichTextLabel.new()
	_feedback.custom_minimum_size.y = 52
	_feedback.add_theme_font_size_override("normal_font_size",12)
	_feedback.text = "Passe o mouse sobre um produto para ver a imagem e sua categoria."
	add_child(_feedback)
	confirmation = preload("res://Scenes/UI/PurchaseConfirmation.tscn").instantiate()
	confirmation.name = "PurchaseConfirmation"
	confirmation.confirmed.connect(_confirm_purchase)
	confirmation.canceled.connect(func() -> void: pending_product = "")
	confirmation.finish_selected.connect(func(finish: String) -> void:
		confirmation.finish_preview.texture = preload("res://Scripts/UI/part_visuals.gd").icon({"kind": "ram", "heat_spreader_color": finish}))
	add_child(confirmation)
	_color_button(confirmation.get_ok_button(), Color("206c50"))
	_color_button(confirmation.get_cancel_button(), Color("923e4c"))
	workshop.ledger.changed.connect(_refresh)
	workshop.ledger.feedback.connect(_notice)
	Prefs.on_change(_refresh_preferences)
	_build_categories()
	_filter("")
	_refresh()

func _build_categories() -> void:
	sidebar.get_node("Content").hide()
	sidebar.custom_minimum_size.x = 176
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",8)
	sidebar.add_child(layout)
	var heading := Label.new()
	heading.text = "CATEGORIAS"
	heading.theme_type_variation = &"Accent"
	layout.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var group := ButtonGroup.new()
	var labels := {"": "Todos os Componentes"}
	labels.merge(workshop.ledger.PART_NAMES)
	for kind in labels:
		var button := Button.new()
		button.text = labels[kind]
		button.custom_minimum_size.y = 30
		button.add_theme_font_size_override("font_size",13)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = group
		button.set_pressed_no_signal(kind.is_empty())
		button.pressed.connect(_filter.bind(kind))
		rows.add_child(button)
		_categories[kind] = button

func _color_button(button: Button, color: Color) -> void:
	button.custom_minimum_size = Vector2(120,40)
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.lightened(0.13) if state == "hover" else color
		style.set_corner_radius_all(7)
		style.set_border_width_all(1)
		style.border_color = color.lightened(0.3)
		button.add_theme_stylebox_override(state,style)
	button.add_theme_color_override("font_color", Color.WHITE)

func _preview(entry: Dictionary) -> void:
	_previewed = entry
	var display := entry.duplicate()
	if entry.get("heat_spreader", false): display.heat_spreader_color = "Preto"
	preview.texture = preload("res://Scripts/UI/part_visuals.gd").icon(display)
	var specs: Array[String] = [workshop.ledger.PART_NAMES[entry.kind]]
	if entry.kind in ["cpu", "motherboard", "cooling"]:
		specs.append(Prefs.t("Soquete %s") % " / ".join(workshop.ledger.mounting_sockets(entry)))
	if entry.kind == "motherboard": specs.append(entry.ddr)
	if entry.get("heat_spreader", false): specs.append("Dissipador opcional · 4 cores")
	preview_name.text = Prefs.t("%s\n%s\n%s\n\nEntrega embalada.\nInstalação manual.") % [entry.model, " · ".join(specs.map(Prefs.t)), Prefs.money(entry.price)]

func _refresh_preferences() -> void:
	_refresh()
	if not _previewed.is_empty(): _preview(_previewed)
func _filter(kind: String) -> void:
	var first: Dictionary = {}
	for entry in workshop.ledger.CATALOG:
		var matches: bool = kind.is_empty() or entry.kind == kind
		_buttons[entry.key].visible = matches
		if matches and first.is_empty(): first = entry
	if not first.is_empty(): _preview(first)
	products.get_parent().set_deferred("scroll_vertical", 0)

func _refresh() -> void:
	_balance.text = Prefs.t("Saldo disponível · %s") % Prefs.money(workshop.ledger.state.credits)
	for entry in workshop.ledger.CATALOG:
		var button: Button = _buttons[entry.key]
		button.disabled = workshop.ledger.state.credits < entry.price
		button.text = "%s\n%s · %s" % [entry.model, Prefs.money(entry.price), Prefs.t("Comprar")]
		button.tooltip_text = entry.model + " · " + Prefs.money(entry.price)

func _buy(key: String) -> void:
	if confirmation.visible: return
	for entry in workshop.ledger.CATALOG:
		if entry.key != key: continue
		pending_product = key
		confirmation.set_finishes(workshop.ledger.HEAT_SPREADERS if entry.get("heat_spreader", false) else {})
		confirmation.dialog_text = Prefs.t("Você tem certeza que quer comprar esse item?\n\n%s\nValor: %s · Entrega na oficina") % [entry.model, Prefs.money(entry.price)]
		confirmation.popup_centered(Vector2i(540,200))
		confirmation.get_cancel_button().grab_focus()
		return

func _confirm_purchase() -> void:
	var key := pending_product
	pending_product = ""
	if not key.is_empty(): workshop.ledger.purchase(key, confirmation.selected_finish())

func _notice(text: String, failed: bool) -> void:
	_feedback.text = text
	_feedback.modulate = Color("edbd85") if failed else Color("a5d7e5")

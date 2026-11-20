extends VBoxContainer

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
const PartVisuals := preload("res://Scripts/UI/part_visuals.gd")
const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")
const Peripherals := preload("res://Scripts/Equipment/peripheral_catalog.gd")
const CONFIRMATION := preload("res://Scenes/UI/PurchaseConfirmation.tscn")
const SALE_LOCATION_LABELS := {
	"floor": "Chão", "carried": "Nas mãos", "shelf": "Armário",
	"tray": "Bandeja da bancada", "bench": "Bancada", "inventory": "Inventário",
}
var workshop: Node
var sidebar: PanelContainer
var _balance: Label
var _subtitle: Label
var _feedback: RichTextLabel
var _buttons: Dictionary = {}
var _categories: Dictionary = {}
var _filters: Dictionary = {}
var products: VBoxContainer
var preview: TextureRect
var preview_name: Label
var confirmation: CanvasLayer
var pending_product := ""
var pending_sale := ""
var _previewed: Dictionary = {}
var _kind := ""
var _search: LineEdit
var _selling := false
var _mode_button: Button
var _sale_items: VBoxContainer
var _sale_buttons: Dictionary = {}
var _previewed_sale := ""

func _ready() -> void:
	add_theme_constant_override("separation",10)
	var header := HBoxContainer.new()
	add_child(header)
	_balance = Label.new()
	_balance.add_theme_font_size_override("font_size",18)
	_balance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_balance)
	_mode_button = Button.new()
	_mode_button.name = "SellItems"
	_mode_button.text = "Vender"
	_mode_button.custom_minimum_size.x = 94
	_mode_button.pressed.connect(_toggle_selling)
	header.add_child(_mode_button)
	_subtitle = Label.new()
	_subtitle.text = "TechMarket / Componentes · Entrega física em 3 s"
	_subtitle.add_theme_font_size_override("font_size",12)
	add_child(_subtitle)
	_search = LineEdit.new()
	_search.name = "CatalogSearch"
	_search.placeholder_text = "Pesquisar por nome ou especificação"
	_search.clear_button_enabled = true
	_search.text_changed.connect(func(_query: String) -> void: _apply_filter())
	add_child(_search)
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
	_sale_items = VBoxContainer.new()
	_sale_items.add_theme_constant_override("separation", 8)
	_sale_items.hide()
	products.add_child(_sale_items)
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 218
	body.add_child(card)
	var details_scroll := ScrollContainer.new()
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(details_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation",8)
	details_scroll.add_child(detail)
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
	confirmation = CONFIRMATION.instantiate()
	confirmation.name = "PurchaseConfirmation"
	confirmation.confirmed.connect(_confirm_transaction)
	confirmation.canceled.connect(_clear_confirmation)
	confirmation.finish_selected.connect(func(finish: String) -> void:
		if _previewed.get("kind") != "ram": return
		var module := _previewed.duplicate()
		module.heat_spreader_color = finish
		confirmation.finish_preview.texture = PartVisuals.icon(module))
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
	labels.merge({"motherboard": "Placas-mãe", "cpu": "Processadores", "gpu": "Placas de vídeo", "psu": "Fontes"}, true)
	labels["case"] = "Gabinetes"
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
	var filters := Label.new()
	filters.text = "FILTROS"
	filters.theme_type_variation = &"Accent"
	rows.add_child(filters)
	var field_names := {"brand": "Marca", "socket": "Soquete", "generation": "Geração", "ddr": "Tipo de memória", "slot_count": "Slots", "price": "Preço", "format": "Formato"}
	for field in field_names:
		var dropdown := OptionButton.new()
		dropdown.name = "Filter_" + field
		dropdown.fit_to_longest_item = false
		dropdown.clip_text = true
		dropdown.tooltip_text = Prefs.t(field_names[field])
		dropdown.add_item(Prefs.t(field_names[field]) + " · " + Prefs.t("Todos"))
		var values: Array = []
		for entry in workshop.ledger.CATALOG:
			for value in _filter_values(entry, field):
				if value not in values: values.append(value)
		values.sort()
		for value in values:
			var label := str(value)
			if field == "price": label = Prefs.money(value)
			dropdown.add_item(label)
			dropdown.set_item_metadata(dropdown.item_count - 1, value)
		dropdown.item_selected.connect(func(_index: int) -> void: _apply_filter())
		rows.add_child(dropdown)
		_filters[field] = dropdown


func _filter_values(entry: Dictionary, field: String) -> Array:
	match field:
		"brand":
			return [entry.get("brand", str(entry.model).get_slice(" ", 0))]
		"socket":
			return Array(workshop.ledger.mounting_sockets(entry)) if entry.has("socket") else []
		"ddr":
			if entry.has("ddr"): return [entry.ddr]
			if entry.kind != "cpu": return []
			var spec := Hardware.cpu_spec(entry)
			var types: Array = []
			if spec.get("ddr_legacy_mt", 0) > 0: types.append("DDR3" if spec.socket == "LGA1155" else "DDR4")
			if spec.get("ddr5_mt", 0) > 0: types.append("DDR5")
			return types
		"generation":
			if entry.kind == "motherboard":
				var generations: Array = []
				for cpu in Hardware.CPUS:
					if cpu.family in entry.cpu_families and cpu.generation not in generations:
						generations.append(cpu.generation)
				return generations
			var spec := Hardware.cpu_spec(entry)
			return [spec.generation] if not spec.is_empty() else []
		"format":
			return [str(entry.get("board_format", entry.get("format", ""))).replace("micro-ATX", "Micro-ATX")] if entry.kind in ["motherboard", "case"] else []
		_:
			return [entry[field]] if entry.has(field) else []

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
	preview.texture = PartVisuals.cpu_artwork(display, true) if entry.kind == "cpu" else PartVisuals.icon(display)
	if entry.kind == "case":
		preview_name.text = "\n".join([
			entry.model, "%s · %s" % [entry.brand, Prefs.t(entry.format)], Prefs.money(entry.price), "",
			Prefs.t("Acabamento: %s · %s") % [Prefs.t(entry.finish), Prefs.t("Tampa de vidro" if entry.glass else "Tampa de aço")],
			Prefs.t("Placas-mãe: %s") % " / ".join(entry.board_formats),
			Prefs.t("Espaço para fonte: %s") % entry.psu_format,
			"Limites: GPU %d mm · cooler %d mm · fonte %d mm" % [entry.gpu_length_mm, entry.cooler_height_mm, entry.psu_depth_mm],
			"GPU até %d slots · %d ventoinhas de fábrica" % [entry.gpu_slots, entry.stock_fans],
			Prefs.t("Baias: %d × 2,5″ · %d × 3,5″") % [entry.drives_25, entry.drives_35],
			Prefs.t("Suporta %d ventoinha(s)") % entry.fans,
			Prefs.t("Entrega embalada, gabinete vazio."),
		])
		return
	var specs: Array[String] = [workshop.ledger.PART_NAMES[entry.kind]]
	if entry.kind in ["cpu", "motherboard", "cooling"]:
		specs.append(Prefs.t("Soquete %s") % " / ".join(workshop.ledger.mounting_sockets(entry)))
	if entry.kind in ["cpu", "motherboard"]:
		specs.append(PartVisuals.socket_contact_label(entry, entry.kind == "motherboard"))
	if entry.kind == "motherboard":
		specs.append("%s · %s · %d slots" % [Cases.board_format(entry), entry.ddr, entry.slot_count])
		specs.append("Até %d GB · %d MT/s" % [entry.max_memory_gb, entry.max_memory_mt])
		specs.append("Gerações: %s" % ", ".join(_filter_values(entry, "generation")))
		var bus := Peripherals.board_bus(entry)
		specs.append("PCIe %d x16 · %d portas SATA" % [bus[0], bus[1]])
		specs.append(entry.condition)
	if entry.kind == "cpu":
		var spec := Hardware.cpu_spec(entry)
		specs.append("Geração %s · %d núcleos / %d threads" % [spec.generation, spec.cores, spec.threads])
		specs.append("%.1f GHz base · %.1f GHz turbo" % [spec.base_ghz, spec.turbo_ghz])
		specs.append("TDP %d W · até %d W · %d °C sim." % [spec.tdp_w, spec.draw_w, spec.temp_c])
		specs.append("Desempenho %d · %s" % [spec.performance, spec.condition])
		specs.append("Vídeo integrado" if Hardware.has_integrated_graphics(entry) else "Requer GPU dedicada")
		specs.append("%s · até %d GB" % [" / ".join(_filter_values(entry, "ddr")), spec.max_memory_gb])
	if entry.kind == "ram":
		specs.append("%s · %d GB · %d MT/s" % [entry.ddr, Hardware.module_capacity(entry), Hardware.module_speed(entry)])
	if entry.kind == "gpu":
		var gpu := Peripherals.gpu_profile(entry)
		specs.append("PCIe %d x%d · %d slots" % [gpu.pcie, gpu.lanes, gpu.slots])
		specs.append("%d W · %s" % [gpu.watts, Peripherals.plugs_label(gpu.plugs)])
		if gpu.has("vram_gb"):
			specs.append("%s · Série %s · %d GB %s" % [gpu.brand, gpu.generation, gpu.vram_gb, gpu.vram_type])
		specs.append("Desempenho %d · %d °C sim." % [gpu.performance, gpu.temp_c])
		specs.append("Passiva" if gpu.fans == 0 else "%d ventoinha(s)%s" % [gpu.fans, " · Zero RPM" if gpu.get("zero_rpm", false) else ""])
		if gpu.get("rgb", false): specs.append(Prefs.t("Iluminação RGB"))
	if entry.kind == "storage":
		var hdd := Peripherals.hdd(entry)
		specs.append("SSD SATA · 2,5″ · sem sistema" if hdd.is_empty() else "HD mecânico SATA · 3,5″ · %s" % Peripherals.capacity_label(hdd.capacity_gb))
		if not hdd.is_empty():
			specs.append("%d RPM · %d/%d MB/s · %d °C sim." % [hdd.rpm, hdd.read_mb, hdd.write_mb, hdd.temp_c])
	if entry.kind == "psu":
		var psu := Peripherals.psu(entry)
		specs.append("%d W · %d cabo(s) PCIe 6+2 · %d cabo(s) 12V-2x6" % [psu.watts, psu.six_eight, psu.high_power])
	if entry.has("size_mm"):
		var dimension: String = {"gpu": "Comprimento", "cooling": "Altura", "psu": "Profundidade"}[entry.kind]
		specs.append("%s · %d mm" % [dimension, entry.size_mm])
	if entry.get("heat_spreader", false): specs.append("Dissipador opcional · 4 cores")
	preview_name.text = Prefs.t("%s\n%s\n%s\n\nEntrega embalada.\nInstalação manual.") % [entry.model, "\n".join(specs.map(Prefs.t)), Prefs.money(entry.price)]

func _refresh_preferences() -> void:
	_refresh()
	if not _selling and not _previewed.is_empty(): _preview(_previewed)

func _filter(kind: String) -> void:
	_kind = kind
	_apply_filter()

func _apply_filter() -> void:
	if _selling:
		_refresh_sales()
		return
	var terms := _query_terms()
	var first: Dictionary = {}
	for entry in workshop.ledger.CATALOG:
		var matches: bool = _kind.is_empty() or entry.kind == _kind
		for field in _filters:
			var filter: OptionButton = _filters[field]
			if filter.selected > 0 and filter.get_selected_metadata() not in _filter_values(entry, field):
				matches = false
				break
		if matches and not terms.is_empty():
			var category: String = "Gabinetes" if entry.kind == "case" else workshop.ledger.PART_NAMES[entry.kind]
			var fields := [entry.model, Prefs.t(category)]
			for field in ["vram_gb", "vram_type", "capacity_gb", "interface", "rpm", "watts"]:
				if entry.has(field): fields.append(str(entry[field]))
			if entry.kind == "storage": fields.append("ssd sata" if Peripherals.hdd(entry).is_empty() else "hd hdd mecânico sata")
			for field in _filters:
				for value in _filter_values(entry, field):
					fields.append(str(value))
			var searchable := _search_terms(" ".join(fields))
			matches = terms.all(func(term: String) -> bool: return term in searchable)
		_buttons[entry.key].visible = matches
		if matches and first.is_empty(): first = entry
	if first.is_empty():
		_previewed = {}
		preview.texture = null
		preview_name.text = "Nenhum produto encontrado."
	else:
		_preview(first)
	products.get_parent().set_deferred("scroll_vertical", 0)

func _search_terms(value: String) -> String:
	return value.to_lower().replace("á", "a").replace("ã", "a").replace("ç", "c")

func _query_terms() -> Array:
	return Array(_search_terms(_search.text.strip_edges()).split(" ", false))

func _refresh() -> void:
	_balance.text = Prefs.t("Saldo disponível · %s") % Prefs.money(workshop.ledger.state.credits)
	if _selling:
		_refresh_sales()
		return
	for entry in workshop.ledger.CATALOG:
		var button: Button = _buttons[entry.key]
		button.disabled = workshop.ledger.state.credits < entry.price
		button.text = "%s\n%s · %s" % [entry.model, Prefs.money(entry.price), Prefs.t("Comprar")]
		button.tooltip_text = entry.model + " · " + Prefs.money(entry.price)

func _buy(key: String) -> void:
	if confirmation.visible: return
	for entry in workshop.ledger.CATALOG:
		if entry.key != key: continue
		_preview(entry)
		pending_product = key
		confirmation.heading_text = "CONFIRMAR COMPRA / TECHMARKET"
		confirmation.set_finishes(workshop.ledger.HEAT_SPREADERS if entry.get("heat_spreader", false) else {})
		confirmation.dialog_text = Prefs.t("Você tem certeza que quer comprar esse item?\n\n%s\nValor: %s · Entrega na oficina") % [entry.model, Prefs.money(entry.price)]
		confirmation.popup_centered(Vector2i(540,200))
		confirmation.get_cancel_button().grab_focus()
		return

func _confirm_purchase() -> void:
	var key := pending_product
	pending_product = ""
	if not key.is_empty(): workshop.ledger.purchase(key, confirmation.selected_finish())


func _toggle_selling() -> void:
	_selling = not _selling
	_sale_items.visible = _selling
	_mode_button.text = "Comprar" if _selling else "Vender"
	_subtitle.text = "Receba 90% do valor pago por cada item." if _selling else "TechMarket / Componentes · Entrega física em 3 s"
	_search.text = ""
	_search.placeholder_text = "Pesquisar seus itens" if _selling else "Pesquisar por nome, marca ou formato"
	if _selling:
		for button in _buttons.values(): button.hide()
	else:
		_refresh()
	_apply_filter()
	products.get_parent().set_deferred("scroll_vertical", 0)


func _refresh_sales() -> void:
	for row in _sale_items.get_children():
		_sale_items.remove_child(row)
		row.queue_free()
	_sale_buttons.clear()
	var offers: Dictionary = workshop.ledger.sale_offers()
	var terms := _query_terms()
	for id in offers:
		var record: Dictionary = workshop.ledger.item(id)
		var kind: String = "case" if record.kind == "pc" else record.kind
		if not _kind.is_empty() and kind != _kind: continue
		var searchable := _search_terms(record.model)
		if not terms.all(func(term: String) -> bool: return term in searchable): continue
		var button := Button.new()
		button.name = "Sell_" + id
		button.custom_minimum_size.y = 62
		button.add_theme_font_size_override("font_size", 12)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.text = "%s\n%s · %s" % [record.model, Prefs.money(offers[id]), Prefs.t("Vender")]
		button.tooltip_text = record.model
		button.pressed.connect(_offer_sale.bind(id))
		button.mouse_entered.connect(_preview_sale.bind(id, offers[id]))
		button.focus_entered.connect(_preview_sale.bind(id, offers[id]))
		_sale_items.add_child(button)
		_sale_buttons[id] = button
	if _sale_buttons.is_empty():
		_previewed_sale = ""
		preview.texture = null
		preview_name.text = "Nenhum item comprado disponível para venda." if offers.is_empty() else "Nenhum item corresponde ao filtro."
		return
	var id: String = _previewed_sale if _sale_buttons.has(_previewed_sale) else _sale_buttons.keys()[0]
	_preview_sale(id, offers[id])


func _preview_sale(id: String, price: float) -> void:
	var record: Dictionary = workshop.ledger.item(id)
	_previewed_sale = id
	preview.texture = PartVisuals.icon(record)
	preview_name.text = "%s\n%s\n%s" % [
		record.model, Prefs.t(SALE_LOCATION_LABELS[record.location]),
		Prefs.t("Recebe %s pela venda.") % Prefs.money(price),
	]


func _offer_sale(id: String) -> void:
	if confirmation.visible: return
	var price: float = workshop.ledger.sale_offers().get(id, 0.0)
	if price <= 0.0: return
	var record: Dictionary = workshop.ledger.item(id)
	pending_sale = id
	confirmation.heading_text = "CONFIRMAR VENDA / TECHMARKET"
	confirmation.set_finishes({})
	confirmation.dialog_text = Prefs.t("Vender %s por %s?") % [record.model, Prefs.money(price)]
	confirmation.popup_centered()


func _clear_confirmation() -> void:
	pending_product = ""
	pending_sale = ""


func _confirm_transaction() -> void:
	if pending_sale.is_empty():
		_confirm_purchase()
	else:
		var id := pending_sale
		_clear_confirmation()
		workshop.ledger.sell(id)


func _notice(text: String, failed: bool) -> void:
	_feedback.text = text
	_feedback.modulate = Color("edbd85") if failed else Color("a5d7e5")

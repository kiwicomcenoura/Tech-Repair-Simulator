extends CanvasLayer
const Appearance := preload("res://Scripts/World/workshop_appearance.gd")
const Prefs := preload("res://Scripts/UI/player_preferences.gd")
var workshop: Node
var is_open := false
var working: Dictionary = {}
var panel: PanelContainer
var target_picker: OptionButton
var color_picker: ColorPickerButton
var status: Label
var styles: Dictionary = {}
var _pause_before := false
var _updating := false

func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.theme = preload("res://Themes/maintenance_bench.tres")
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -420
	panel.offset_right = -20
	panel.offset_top = 74
	panel.offset_bottom = -26
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0d1d2b")
	box.border_color = Color("47738b")
	box.set_border_width_all(1)
	box.set_corner_radius_all(14)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel",box)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",12)
	panel.add_child(layout)
	var heading := Label.new()
	heading.text = "Personalizar oficina"
	heading.add_theme_font_size_override("font_size",22)
	layout.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "Escolha uma superfície. Veja a mudança na oficina."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size",12)
	layout.add_child(subtitle)
	target_picker = OptionButton.new()
	target_picker.name = "DecorationTarget"
	for target in Appearance.TARGETS:
		target_picker.add_item(Appearance.TARGETS[target])
		target_picker.set_item_metadata(target_picker.item_count-1,target)
	target_picker.item_selected.connect(func(_index: int) -> void: _refresh())
	layout.add_child(target_picker)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	scroll.add_child(content)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	content.add_child(grid)
	for key in Appearance.STYLES:
		var button := Button.new()
		button.name = "Style_"+key
		button.text = Appearance.STYLES[key][0]
		button.custom_minimum_size = Vector2(172,48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",12)
		button.icon = Appearance.texture(key)
		for state in ["normal","hover","pressed","focus"]:
			button.add_theme_color_override("icon_"+state+"_color",Color(Appearance.STYLES[key][1]))
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",26)
		button.toggle_mode = true
		button.pressed.connect(select_style.bind(key))
		grid.add_child(button)
		styles[key] = button
	var label := Label.new()
	label.text = "COR DO ACABAMENTO"
	label.add_theme_font_size_override("font_size",12)
	content.add_child(label)
	var palette := HBoxContainer.new()
	palette.add_theme_constant_override("separation",6)
	content.add_child(palette)
	for tone in ["b9c7cf","4c6375","294c68","af8558","4b6a5c","9b5961"]:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(38,30)
		swatch.tooltip_text = Prefs.t("Aplicar cor #%s") % tone
		var paint := StyleBoxFlat.new()
		paint.bg_color = Color(tone)
		paint.set_corner_radius_all(5)
		swatch.add_theme_stylebox_override("normal",paint)
		swatch.pressed.connect(select_color.bind(Color(tone)))
		palette.add_child(swatch)
	color_picker = ColorPickerButton.new()
	color_picker.text = "Escolher outra cor"
	color_picker.edit_alpha = false
	color_picker.color_changed.connect(select_color)
	content.add_child(color_picker)
	var reset := Button.new()
	reset.text = "Restaurar esta superfície"
	reset.pressed.connect(func() -> void:
		working.erase(target())
		_preview()
		_refresh())
	content.add_child(reset)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size",12)
	layout.add_child(status)
	var actions := HBoxContainer.new()
	layout.add_child(actions)
	for action in ["apply","cancel"]:
		var button := Button.new()
		button.name = "ApplyDecoration" if action == "apply" else "CancelDecoration"
		button.text = "Aplicar e salvar" if action == "apply" else "Cancelar · ESC"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",13)
		button.pressed.connect(apply_changes if action == "apply" else close_menu)
		actions.add_child(button)
	hide()

func target() -> String: return target_picker.get_selected_metadata()

func open_menu() -> void:
	if is_open or get_tree().paused: return
	working = workshop.ledger.state.get("decoration",{}).duplicate(true)
	_pause_before = get_tree().paused
	get_tree().paused = true
	is_open = true
	show()
	_refresh()
	target_picker.grab_focus()

func close_menu() -> void:
	if not is_open: return
	Appearance.apply(workshop.get_parent(),workshop.ledger.state.get("decoration",{}))
	is_open = false
	hide()
	get_tree().paused = _pause_before

func select_style(key: String) -> void:
	working[target()] = {"style":key,"tint":Appearance.STYLES[key][1]}
	_preview()
	_refresh()

func select_color(color: Color) -> void:
	if _updating or not is_open: return
	var entry: Dictionary = working.get(target(),{"style":"modern","tint":"ffffff"}).duplicate()
	if entry.style == "original": entry.style = "modern"
	entry.tint = color.to_html(false)
	working[target()] = entry
	_preview()
	_refresh()

func _preview() -> void:
	Appearance.apply(workshop.get_parent(),working)

func _refresh() -> void:
	_updating = true
	# Keep the selected furniture visible while previewing it.
	var left_side := target() == "desk"
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE if left_side else Control.PRESET_RIGHT_WIDE)
	panel.offset_left = 20 if left_side else -420
	panel.offset_right = 420 if left_side else -20
	panel.offset_top = 74
	panel.offset_bottom = -26
	var entry: Dictionary = working.get(target(),{"style":"original","tint":"ffffff"})
	for key in styles: styles[key].set_pressed_no_signal(key == entry.style)
	color_picker.color = Color(entry.tint)
	status.text = Prefs.t("Prévia · %s\nAplicar salva; Cancelar mantém o visual anterior.") % Prefs.t(Appearance.TARGETS[target()])
	_updating = false

func apply_changes() -> void:
	if not Appearance.valid(working): return
	workshop.ledger.state.decoration = working.duplicate(true)
	workshop.ledger.done("Personalização da oficina salva.")
	close_menu()

func _input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE,KEY_F2]:
		if color_picker.get_popup().visible: return
		get_viewport().set_input_as_handled()
		close_menu()

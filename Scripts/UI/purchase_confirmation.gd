extends CanvasLayer
signal confirmed
signal canceled
signal finish_selected(finish: String)
var heading_text := "CONFIRMAR COMPRA / TECHMARKET"
var dialog_text := ""
var _yes: Button
var _no: Button
var _message: Label
var _finish_row: HBoxContainer
var _finish: OptionButton
var finish_preview: TextureRect

func _ready() -> void:
	var root := Control.new()
	root.theme = preload("res://Themes/maintenance_bench.tres")
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.025,0.045,0.78)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560,280)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("122333")
	style.border_color = Color("3f657b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel",style)
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",20)
	panel.add_child(layout)
	var label := Label.new()
	label.text = heading_text
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",Color("72d5e6"))
	layout.add_child(label)
	_message = Label.new()
	_message.custom_minimum_size.x = 500
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_message)
	_finish_row = HBoxContainer.new()
	_finish_row.add_theme_constant_override("separation",12)
	layout.add_child(_finish_row)
	var finish_label := Label.new()
	finish_label.text = "Dissipador"
	_finish_row.add_child(finish_label)
	_finish = OptionButton.new()
	_finish.item_selected.connect(func(_index: int) -> void: finish_selected.emit(selected_finish()))
	_finish_row.add_child(_finish)
	finish_preview = TextureRect.new()
	finish_preview.custom_minimum_size = Vector2(144,44)
	finish_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	finish_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	finish_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_finish_row.add_child(finish_preview)
	_finish_row.hide()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation",12)
	layout.add_child(row)
	_yes = Button.new()
	_yes.text = "Sim"
	_yes.custom_minimum_size = Vector2(140,44)
	_yes.pressed.connect(func() -> void:
		hide()
		confirmed.emit())
	row.add_child(_yes)
	_no = Button.new()
	_no.text = "Não"
	_no.custom_minimum_size = Vector2(140,44)
	_no.pressed.connect(_cancel)
	row.add_child(_no)
	hide()

func get_ok_button() -> Button: return _yes
func get_cancel_button() -> Button: return _no

func set_finishes(colors: Dictionary) -> void:
	_finish.clear()
	_finish_row.visible = not colors.is_empty()
	if colors.is_empty(): return
	_finish.add_item("Sem dissipador")
	for finish in colors:
		var swatch := Image.create(16,16,false,Image.FORMAT_RGBA8)
		swatch.fill(colors[finish])
		_finish.add_icon_item(ImageTexture.create_from_image(swatch), finish)
	_finish.select(0)
	finish_selected.emit(selected_finish())

func selected_finish() -> String:
	return _finish.get_item_text(_finish.selected) if _finish.selected > 0 else ""

func popup_centered(_size: Vector2i = Vector2i.ZERO) -> void:
	_message.text = dialog_text
	show()
	_no.grab_focus()

func _cancel() -> void:
	hide()
	canceled.emit()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()

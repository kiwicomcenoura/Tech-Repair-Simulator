extends CanvasLayer

var workshop: Node
var is_open := false
var _pause_before := false
var _overlay: Control
var board: VBoxContainer

func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = Control.new()
	_overlay.theme = preload("res://Themes/maintenance_bench.tres")
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.045, 0.86)
	_overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	_overlay.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_"+side, 40)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d1d2b")
	style.border_color = Color("47738b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	panel.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "Atendimento · Ordens de serviço"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.name = "CloseOrders"
	close.text = "Voltar · Esc"
	close.pressed.connect(close_menu)
	header.add_child(close)
	board = preload("res://Scripts/UI/service_orders_board.gd").new()
	board.workshop = workshop
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(board)
	_overlay.hide()

func open_menu() -> void:
	if is_open: return
	_pause_before = get_tree().paused
	is_open = true
	get_tree().paused = true
	workshop._hud.hide()
	board.refresh()
	_overlay.show()

func close_menu() -> void:
	if not is_open: return
	is_open = false
	_overlay.hide()
	get_tree().paused = _pause_before
	workshop._hud.visible = not get_tree().paused

func _input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE, KEY_O]:
		get_viewport().set_input_as_handled()
		close_menu()

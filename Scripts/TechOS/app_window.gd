extends PanelContainer
## One reusable window; no business logic or external services.

signal focus_requested(app_id: String)
signal close_requested(app_id: String)
signal minimize_requested(app_id: String)

var app_id := ""
var _dragging := false
var _drag_offset := Vector2.ZERO
var _open_tween: Tween
var preferred_size := Vector2(650, 420)


func _ready() -> void:
	# Real application content can change the minimum size after layout.
	resized.connect(clamp_position)
	minimum_size_changed.connect(func() -> void: fit_to_area.call_deferred())
	%TitleBar.gui_input.connect(_title_input)
	%CloseApp.pressed.connect(func() -> void: close_requested.emit(app_id))
	%MinimizeApp.pressed.connect(func() -> void: minimize_requested.emit(app_id))
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed: focus_requested.emit(app_id))


func configure(id: String, definition: Dictionary) -> void:
	app_id = id
	%AppTitle.text = definition.title
	%AppIcon.app_id = id
	%EmptyIcon.app_id = id
	%SectionTitle.text = definition.title
	%EmptyTitle.text = definition.empty_title
	%EmptyDescription.text = definition.description
	modulate.a = 0.0
	_open_tween = create_tween()
	_open_tween.tween_property(self, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_SINE)


func set_active(active: bool) -> void:
	var box := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	box.border_color = Color("548aa6") if active else Color("2d4053")
	add_theme_stylebox_override("panel", box)
	%AppTitle.modulate = Color.WHITE if active else Color("91a5b9")


func fit_to_area() -> void:
	var area := get_parent() as Control
	if area == null:
		return
	size = Vector2(minf(preferred_size.x, area.size.x), minf(preferred_size.y, area.size.y))
	clamp_position()


func clamp_position() -> void:
	var area := get_parent() as Control
	if area == null: return
	position.x = clampf(position.x, 0.0, maxf(0.0, area.size.x - size.x))
	position.y = clampf(position.y, 0.0, maxf(0.0, area.size.y - size.y))


func _title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			focus_requested.emit(app_id)
			var viewport_point: Vector2 = %TitleBar.get_global_transform_with_canvas() * event.position
			_drag_offset = get_global_transform_with_canvas().affine_inverse() * viewport_point
			_dragging = true
		else:
			_dragging = false
		%TitleBar.accept_event()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_dragging = false
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		var area := get_parent() as Control
		position = area.get_global_transform_with_canvas().affine_inverse() * event.position - _drag_offset
		clamp_position()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false

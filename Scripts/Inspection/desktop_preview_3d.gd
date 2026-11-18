extends SubViewportContainer

signal target_hovered(id: StringName)
signal target_activated(id: StringName)

const DesktopModel := preload("res://Scripts/Inspection/desktop_model.gd")
const INITIAL_ROTATION := Vector3(0.19, -0.45, 0.0)

var _model: Node3D
var _camera: Camera3D
var _zoom := 1.0
var _pointer_down := false
var _press_position := Vector2.ZERO
var _dragging := false


func _ready() -> void:
	resized.connect(_fit_camera)
	visibility_changed.connect(reset_pointer)
	mouse_exited.connect(_clear_hover)


func show_session(session: RefCounted) -> void:
	if _model == null:
		_build_viewport()
	_model.update_parts(session)


func reset_view() -> void:
	reset_pointer()
	_zoom = 1.0
	if _model != null:
		_model.rotation = INITIAL_ROTATION
	_fit_camera()


func _build_viewport() -> void:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)

	var studio := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("16171c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("efebe2")
	environment.ambient_light_energy = 0.59
	studio.environment = environment
	viewport.add_child(studio)

	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.position = Vector3(0.0, 0.0, 6.0)
	viewport.add_child(_camera)
	_camera.make_current()

	_add_light(viewport, Vector3(-38, -22, 0), Color("fff1df"), 1.24, true)
	_add_light(viewport, Vector3(12, 63, 0), Color("d9e2fd"), 0.53)
	_add_light(viewport, Vector3(-55, 157, 0), Color("f9d4ac"), 0.78)
	_model = DesktopModel.new()
	viewport.add_child(_model)
	reset_view()


func _add_light(viewport: SubViewport, angles: Vector3, color: Color, energy: float, casts_shadows := false) -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = angles
	light.light_color = color
	light.light_energy = energy
	light.shadow_enabled = casts_shadows
	light.shadow_opacity = 0.52
	light.directional_shadow_max_distance = 11.0
	viewport.add_child(light)


func _fit_camera() -> void:
	if _camera != null:
		_camera.size = 3.28 * maxf(1.0, size.y / maxf(size.x, 1.0)) / _zoom


func reset_pointer() -> void:
	_pointer_down = false
	_dragging = false
	_clear_hover()


func _clear_hover() -> void:
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	target_hovered.emit(&"")


func _pick(local_position: Vector2) -> MeshInstance3D:
	var viewport_size := Vector2(_camera.get_viewport().get_visible_rect().size)
	var point := local_position * viewport_size / size.max(Vector2.ONE)
	return _model.pick_mesh(_camera.project_ray_origin(point), _camera.project_ray_normal(point))


func _show_hover(local_position: Vector2) -> void:
	var instance := _pick(local_position)
	var id: StringName = instance.get_meta(&"pick_id") if instance != null else &""
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if id != &"" else Control.CURSOR_DRAG
	target_hovered.emit(id)


func _gui_input(event: InputEvent) -> void:
	if _model == null:
		return
	if event is InputEventMouseMotion:
		if not event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_pointer_down = false
			_dragging = false
		if _pointer_down and (_dragging or event.position.distance_to(_press_position) > 5.0):
			if not _dragging:
				_clear_hover()
			_dragging = true
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			var sensitivity := PI / maxf(minf(size.x, size.y), 1.0)
			# Rotate in camera coordinates, so dragging also works when looking from below.
			var yaw := Basis(Vector3.UP, event.relative.x * sensitivity)
			var pitch := Basis(Vector3.RIGHT, event.relative.y * sensitivity)
			_model.basis = (yaw * pitch * _model.basis).orthonormalized()
		elif not _pointer_down:
			_show_hover(event.position)
		accept_event()
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_pointer_down = true
					_press_position = event.position
				else:
					var inside := Rect2(Vector2.ZERO, size).has_point(event.position)
					var clicked := _pointer_down and not _dragging and inside
					_pointer_down = false
					_dragging = false
					if clicked:
						var instance := _pick(event.position)
						if instance != null:
							var id: StringName = instance.get_meta(&"pick_id")
							if id != &"":
								target_activated.emit(id)
					if inside:
						_show_hover(event.position)
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					var factor := 1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15
					_zoom = clampf(_zoom * factor, 0.75, 2.7)
					_fit_camera()
					_show_hover(event.position)
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					reset_view()
			_:
				return
		accept_event()

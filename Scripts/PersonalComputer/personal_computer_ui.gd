extends CanvasLayer
## TechOS host: physical interaction, power and returning control to the game.

@export var computer_path: NodePath = ^"../Actors/WorkComputer/PersonalComputer"
var is_open := false
var _previous_pause := false
var computer: Node
var _last_power_state := 0
var _normal_style: StyleBox
var _desktop_style: StyleBoxFlat


func _ready() -> void:
	computer = get_node_or_null(computer_path)
	%PersonalClose.pressed.connect(close_computer)
	%PowerToggle.pressed.connect(_toggle_power)
	%DesktopScreen.shutdown_requested.connect(_toggle_power)
	%DesktopScreen.exit_requested.connect(close_computer)
	var window: PanelContainer = $PersonalOverlay/Margins/PersonalWindow
	_normal_style = window.get_theme_stylebox("panel")
	_desktop_style = StyleBoxFlat.new()
	_desktop_style.bg_color = Color("081523")
	_desktop_style.border_color = Color("38536a")
	_desktop_style.set_border_width_all(1)
	_desktop_style.set_corner_radius_all(10)
	if computer != null:
		computer.power_changed.connect(_refresh)
	%PersonalOverlay.hide()
	%PersonalPrompt.hide()
	_refresh(0, 0.0, "Computador desligado")


func show_prompt(nearby: bool) -> void:
	%PersonalPrompt.visible = nearby and not is_open and not get_tree().paused


func open_computer() -> void:
	if is_open or computer == null or get_tree().paused:
		return
	is_open = true
	_previous_pause = get_tree().paused
	%PersonalPrompt.hide()
	%PersonalOverlay.show()
	_refresh(computer.power_state, computer.boot_progress(), computer.status_text())
	get_tree().paused = true
	if computer.power_state == 2:
		%DesktopScreen.get_node("%StartButton").grab_focus()
	else:
		%PowerToggle.grab_focus()


func close_computer() -> void:
	if not is_open:
		return
	is_open = false
	%DesktopScreen.dismiss_popup()
	%PersonalOverlay.hide()
	get_tree().paused = _previous_pause


func _refresh(state: int, progress: float, status: String) -> void:
	var powered_down := state == 0 and _last_power_state != 0
	_last_power_state = state
	%OffScreen.visible = state == 0
	%BootScreen.visible = state == 1
	%DesktopScreen.visible = state == 2
	%DesktopScreen.set_running(state == 2)
	_set_desktop_layout(state == 2)
	%PersonalStatus.text = ["DESLIGADO", "INICIALIZANDO", "LIGADO"][state]
	%PowerToggle.text = "Ligar computador" if state == 0 else "Desligar computador"
	%BootProgress.value = progress * 100.0
	%BootStatus.text = status
	if powered_down:
		close_computer()


func _toggle_power() -> void:
	if is_instance_valid(computer):
		computer.toggle_power()


func _set_desktop_layout(desktop: bool) -> void:
	var layout: VBoxContainer = $PersonalOverlay/Margins/PersonalWindow/Layout
	layout.get_node("Header").visible = not desktop
	layout.get_node("Divider").visible = not desktop
	layout.get_node("Footer").visible = not desktop
	layout.add_theme_constant_override("separation", 0 if desktop else 18)
	var margins: MarginContainer = $PersonalOverlay/Margins
	for edge in ["left", "right"]:
		margins.add_theme_constant_override("margin_" + edge, 24 if desktop else 64)
	for edge in ["top", "bottom"]:
		margins.add_theme_constant_override("margin_" + edge, 24 if desktop else 44)
	var window: PanelContainer = $PersonalOverlay/Margins/PersonalWindow
	window.add_theme_stylebox_override("panel", _desktop_style if desktop else _normal_style)


func _input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if %DesktopScreen.dismiss_popup():
			return
		close_computer()


func _exit_tree() -> void:
	if is_open:
		get_tree().paused = _previous_pause

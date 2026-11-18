extends Node
## The fixed administration PC. Never an EquipmentItem or a repair target.

signal power_changed(state: int, progress: float, status: String)

enum PowerState { OFF, BOOTING, ON }
const InteractionRange := preload("res://Scripts/World/interaction_range.gd")
const Audio := preload("res://Scripts/Gameplay/workshop_audio.gd")
@export var boot_duration: float = 3.2
@export var interaction_distance: float = 48.0
@export var player_path: NodePath = ^"../../Player"
@export var interface_path: NodePath = ^"../../../PersonalComputerUI"
var power_state: PowerState = PowerState.OFF
var _boot_elapsed := 0.0
var _last_percent := -1
var _original_colors: Dictionary = {}

@onready var _player: CharacterBody2D = get_node_or_null(player_path) as CharacterBody2D
@onready var _interface: CanvasLayer = get_node_or_null(interface_path) as CanvasLayer
@onready var _footprint: CollisionPolygon2D = get_parent().get_node("Body/Solid41")


func _ready() -> void:
	add_to_group("workshop_interactions")
	for child in get_parent().get_node("Details").get_children():
		if child is Polygon2D:
			_original_colors[child] = child.color
	_update_monitor()


func interaction_distance_to_player() -> float:
	return InteractionRange.distance_to_item(_player, _footprint)


func _process(delta: float) -> void:
	if is_instance_valid(_interface):
		_interface.show_prompt(not get_tree().paused and InteractionRange.is_closest(self, interaction_distance))
	if power_state == PowerState.BOOTING:
		_boot_elapsed = minf(_boot_elapsed + delta, maxf(boot_duration, 0.1))
		if _boot_elapsed >= maxf(boot_duration, 0.1):
			power_state = PowerState.ON
			Audio.play("boot_ok")
			_update_monitor()
		var percent := int(boot_progress() * 100.0)
		if percent != _last_percent:
			_last_percent = percent
			_emit_power()


func _unhandled_key_input(event: InputEvent) -> void:
	if get_tree().paused or not is_instance_valid(_interface):
		return
	if event.is_action_pressed("interact") and not event.is_echo() and InteractionRange.is_closest(self, interaction_distance):
		get_viewport().set_input_as_handled()
		_player.velocity = Vector2.ZERO
		_player.get_node("AnimatedSprite2D").play("idle_" + str(_player.get("facing")))
		_interface.open_computer()


func toggle_power() -> void:
	if power_state == PowerState.OFF:
		power_state = PowerState.BOOTING
		_boot_elapsed = 0.0
		_last_percent = -1
	else:
		power_state = PowerState.OFF
		_boot_elapsed = 0.0
		_last_percent = -1
	_update_monitor()
	_emit_power()
	Audio.play("power_off" if power_state == PowerState.OFF else "power_on")


func boot_progress() -> float:
	return clampf(_boot_elapsed / maxf(boot_duration, 0.1), 0.0, 1.0)


func status_text() -> String:
	if power_state == PowerState.OFF:
		return "Computador desligado"
	if power_state == PowerState.ON:
		return "TechOS pronto"
	if boot_progress() < 0.25:
		return "Inicializando o TechOS…"
	if boot_progress() < 0.6:
		return "Preparando o ambiente local…"
	return "Carregando a área de trabalho…"


func _emit_power() -> void:
	power_changed.emit(power_state, boot_progress(), status_text())


func _update_monitor() -> void:
	var powered := power_state != PowerState.OFF
	for child in _original_colors:
		var name_text := str(child.name)
		if name_text.begins_with("ScreenGlass"):
			child.color = _original_colors[child] if powered else Color("0c1620")
		elif name_text.begins_with("Screen"):
			child.visible = powered
		elif name_text.begins_with("PowerLED"):
			child.color = _original_colors[child] if powered else Color("34495b")
	get_parent().get_node("Surface31").modulate = Color.WHITE if powered else Color("475763")

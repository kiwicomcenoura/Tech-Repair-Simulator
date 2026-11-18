extends Node
## Distance to the physical footprint, not to the prop's front corner.

@export var player_path: NodePath = ^"../../Player"
@export var interface_path: NodePath = ^"../../../MaintenanceBenchUI"
@export var interaction_distance: float = 48.0
const InteractionRange := preload("res://Scripts/World/interaction_range.gd")

var available := false
@onready var _bench: Node2D = get_parent() as Node2D
@onready var _player: CharacterBody2D = get_node_or_null(player_path) as CharacterBody2D
@onready var _interface: CanvasLayer = get_node_or_null(interface_path) as CanvasLayer
@onready var _footprint: CollisionPolygon2D = _bench.get_node("Body/Solid19")


func _ready() -> void:
	add_to_group("workshop_interactions")


func _physics_process(_delta: float) -> void:
	available = _is_near()
	if is_instance_valid(_interface):
		_interface.show_prompt(available)


func _is_near() -> bool:
	if not is_instance_valid(_player) or not is_instance_valid(_interface):
		return false
	return InteractionRange.is_closest(self, interaction_distance)


func interaction_distance_to_player() -> float:
	return InteractionRange.distance_to_item(_player, _footprint)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and _is_near():
		get_viewport().set_input_as_handled()
		# Settle the character into idle before pausing the workshop.
		_player.velocity = Vector2.ZERO
		var sprite: AnimatedSprite2D = _player.get_node("AnimatedSprite2D")
		sprite.speed_scale = 1.0
		sprite.play("idle_" + str(_player.get("facing")))
		_interface.open_bench()

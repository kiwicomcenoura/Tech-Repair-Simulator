extends Node2D
## Draw a solid isometric prop relative to the player's feet.
## The origin must be the front corner of its floor footprint.
## Both front edges have a screen slope of 1:2 in this workshop.

@export var actor_path: NodePath = ^"../Player"

@onready var _actor: Node2D = get_node_or_null(actor_path) as Node2D


func _process(_delta: float) -> void:
	if not is_instance_valid(_actor):
		return

	var feet: Vector2 = to_local(_actor.global_position)
	# The front boundary is a V: y = -abs(x) / 2. Comparing only Y
	# with this prop's origin incorrectly hides actors beside either face.
	var in_front: bool = feet.y + absf(feet.x) * 0.5 >= 0.0
	z_index = _actor.z_index - 1 if in_front else _actor.z_index + 1

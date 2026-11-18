extends CharacterBody2D

@export var speed: float = 180.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing: String = "down"


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	if not direction.is_zero_approx():
		# Re-evaluate both axes every physics tick, including while a key
		# stays held. Input.get_vector keeps diagonal speed normalized.
		if not is_zero_approx(direction.x) and not is_zero_approx(direction.y):
			facing = ("up_" if direction.y < 0.0 else "down_") + ("left" if direction.x < 0.0 else "right")
		elif not is_zero_approx(direction.x):
			facing = "right" if direction.x > 0.0 else "left"
		else:
			facing = "down" if direction.y > 0.0 else "up"

	# Use real displacement so pushing against a wall plays idle.
	var walking := not direction.is_zero_approx() and get_position_delta().length_squared() > 0.001
	var next_animation := ("walk_" if walking else "idle_") + facing
	if animated_sprite.animation != next_animation:
		# Keep the same footfall when turning instead of restarting the
		# first pose on every W+D / W+A transition.
		var keep_stride := walking and String(animated_sprite.animation).begins_with("walk_")
		var stride_frame := animated_sprite.frame
		var stride_progress := animated_sprite.frame_progress
		animated_sprite.play(next_animation)
		if keep_stride:
			animated_sprite.set_frame_and_progress(stride_frame, stride_progress)
	animated_sprite.speed_scale = clampf(get_real_velocity().length() / speed, 0.25, 1.0) if walking else 1.0

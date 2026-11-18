extends RefCounted
## Regression fixtures never read or modify the player's actual save.

static func create(receiving: bool = false, path: String = "") -> Node2D:
	var world: Node2D = load("res://Scenes/World/World.tscn").instantiate()
	var workshop: Node = world.get_node("PhysicalWorkshop")
	workshop.start_with_delivery = receiving
	workshop.save_path = path
	return world

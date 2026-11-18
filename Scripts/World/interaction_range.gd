extends RefCounted
## Shared proximity only; no connection between equipment and administration.

static func distance_to_item(player: Node2D, footprint: CollisionPolygon2D) -> float:
	if not is_instance_valid(player) or not is_instance_valid(footprint):
		return INF
	var point := footprint.to_local(player.global_position)
	var polygon := footprint.polygon
	if Geometry2D.is_point_in_polygon(point, polygon):
		return 0.0
	var nearest := INF
	for i in range(polygon.size()):
		var closest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
		nearest = minf(nearest, footprint.to_global(closest).distance_to(player.global_position))
	return nearest


static func is_closest(interactor: Node, radius: float) -> bool:
	var distance: float = interactor.interaction_distance_to_player()
	if distance > radius:
		return false
	for other in interactor.get_tree().get_nodes_in_group("workshop_interactions"):
		if other == interactor:
			continue
		var other_distance: float = other.interaction_distance_to_player()
		if other_distance < distance or (is_equal_approx(other_distance, distance) and other.get_instance_id() < interactor.get_instance_id()):
			return false
	return true

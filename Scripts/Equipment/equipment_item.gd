extends Node2D
## Attach to an actual, visible, transportable equipment scene.
## The personal desk computer intentionally does not use this script.

const EquipmentData := preload("res://Scripts/Equipment/equipment_data.gd")
@export var equipment_data: Resource


func is_valid_equipment() -> bool:
	return equipment_data is EquipmentData and equipment_data.is_valid() and is_inside_tree() and is_visible_in_tree() and _has_art(self)


func _has_art(node: Node) -> bool:
	if node is CanvasItem and (not node.is_visible_in_tree() or node.modulate.a <= 0.0):
		return false
	if node is Node2D and is_zero_approx(node.global_transform.determinant()):
		return false
	if node is Sprite2D and node.texture != null and node.self_modulate.a > 0.0 and not is_zero_approx(node.global_transform.determinant()):
		return true
	if node is Polygon2D and node.polygon.size() >= 3 and node.self_modulate.a > 0.0:
		return true
	if node is AnimatedSprite2D and node.sprite_frames != null:
		if node.sprite_frames.has_animation(node.animation) and node.frame < node.sprite_frames.get_frame_count(node.animation):
			if node.self_modulate.a > 0.0 and node.sprite_frames.get_frame_texture(node.animation, node.frame) != null:
				return true
	for child in node.get_children():
		if _has_art(child):
			return true
	return false

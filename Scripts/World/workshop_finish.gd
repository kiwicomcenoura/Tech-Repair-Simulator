extends Node2D
## Visual-only surface edges and contact shadows; existing collision/depth is untouched.
func _ready() -> void:
	var prop := get_parent()
	for node in prop.get_children():
		if not node is Polygon2D or node.polygon.size() < 3: continue
		node.antialiased = true
		var points: PackedVector2Array = node.polygon
		var area := 0.0
		for i in range(points.size()): area += points[i].cross(points[(i+1)%points.size()])
		if absf(area)*0.5 < 400: continue
		var edge := Line2D.new()
		edge.points = points
		edge.closed = true
		edge.width = 0.45
		edge.antialiased = true
		edge.default_color = Color(0.67,0.79,0.87,0.08)
		node.add_child(edge)
	var body := prop.get_node_or_null("Body")
	if body != null:
		for solid in body.get_children():
			if not solid is CollisionPolygon2D: continue
			var shadow := Polygon2D.new()
			shadow.polygon = solid.polygon
			shadow.position = solid.position+body.position+Vector2(6,4)
			shadow.color = Color(0.015,0.025,0.04,0.23)
			shadow.z_index = -1
			shadow.antialiased = true
			prop.add_child.call_deferred(shadow)

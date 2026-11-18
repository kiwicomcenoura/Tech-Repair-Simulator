@tool
extends Control

var client_mode := false:
	set(value):
		client_mode = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if client_mode:
		if size.x <= 0 or size.y <= 0: return
		draw_rect(Rect2(Vector2.ZERO, size), Color("132432"))
		for i in range(18, 0, -1):
			draw_circle(size * Vector2(0.77, 0.32), float(i) * size.y * 0.031, Color(0.24, 0.44, 0.46, 0.025))
		for i in range(4):
			var height := size.y * (0.56 + i * 0.09)
			draw_colored_polygon(PackedVector2Array([Vector2(0, minf(height + size.y * 0.24, size.y * 0.97)), Vector2(size.x * 0.35, height), Vector2(size.x * 0.55, minf(height + size.y * 0.18, size.y * 0.97)), Vector2(size.x, height - size.y * 0.16), size, Vector2(0, size.y)]), Color("284c55").darkened(i * 0.13))
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("081523"))
	var center := Vector2(size.x * 0.77, size.y * 0.52)
	for i in range(14, 0, -1):
		var radius := float(i) * size.y * 0.06
		draw_circle(center, radius, Color(0.05, 0.16, 0.29, 0.035))
	var a := PackedVector2Array([Vector2(size.x * 0.42, 0), Vector2(size.x * 0.73, 0), Vector2(size.x, size.y * 0.68), Vector2(size.x, size.y)])
	draw_colored_polygon(a, Color(0.07, 0.18, 0.30, 0.55))
	draw_line(a[0], a[2], Color(0.20, 0.51, 0.70, 0.30), 1.0)
	draw_line(Vector2(size.x * 0.55, 0), Vector2(size.x, size.y * 0.64), Color(0.20, 0.51, 0.70, 0.13), 1.0)
	for x in range(24, int(size.x), 40):
		for y in range(24, int(size.y), 40):
			draw_circle(Vector2(x, y), 0.65, Color(0.37, 0.60, 0.75, 0.09))

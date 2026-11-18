@tool
extends Control
## Original, scalable software icons drawn with Godot primitives.

@export var app_id: String = "messages":
	set(value):
		app_id = value
		queue_redraw()

const COLORS := {"messages": "5fc5df", "clients": "7da6ec", "shop": "87c8ca", "finances": "7bceab", "marketing": "bd9ae6", "files": "e4bd83"}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var factor := minf(size.x, size.y) / 48.0
	var origin := (size - Vector2.ONE * 48.0 * factor) * 0.5
	draw_set_transform(origin, 0.0, Vector2.ONE * factor)
	var c := Color(COLORS.get(app_id, "5fc5df"))
	var tile := StyleBoxFlat.new()
	tile.bg_color = Color(c.r * 0.18, c.g * 0.18, c.b * 0.18, 0.96)
	tile.border_color = Color(c, 0.35)
	tile.set_border_width_all(1)
	tile.set_corner_radius_all(10)
	draw_style_box(tile, Rect2(1, 1, 46, 46))
	match app_id:
		"messages":
			draw_rect(Rect2(11, 13, 26, 19), c, false, 2.0)
			draw_polyline(PackedVector2Array([Vector2(13, 32), Vector2(13, 37), Vector2(20, 32)]), c, 2.0)
			for x in [18, 24, 30]: draw_circle(Vector2(x, 23), 1.5, c)
		"clients":
			draw_circle(Vector2(24, 17), 5, c, false, 2.0)
			draw_arc(Vector2(24, 33), 9, PI, TAU, 20, c, 2.0)
			draw_circle(Vector2(12, 22), 3, c, false, 1.5)
			draw_circle(Vector2(36, 22), 3, c, false, 1.5)
			draw_line(Vector2(8, 31), Vector2(11, 28), c, 2.0)
			draw_line(Vector2(37, 28), Vector2(40, 31), c, 2.0)
		"shop", "store":
			draw_rect(Rect2(12, 19, 24, 18), c, false, 2.0)
			draw_arc(Vector2(24, 19), 7, PI, TAU, 16, c, 2.0)
			draw_line(Vector2(20, 27), Vector2(28, 27), c, 2.0)
		"finances":
			for i in range(3): draw_rect(Rect2(12 + i * 9, 28 - i * 7, 5, 9 + i * 7), c)
			draw_line(Vector2(10, 39), Vector2(38, 39), c, 1.5)
		"marketing":
			draw_polyline(PackedVector2Array([Vector2(12, 21), Vector2(34, 12), Vector2(34, 34), Vector2(12, 26), Vector2(12, 21)]), c, 2.0)
			draw_line(Vector2(17, 29), Vector2(21, 38), c, 3.0)
			draw_line(Vector2(39, 19), Vector2(43, 17), c, 1.5)
			draw_line(Vector2(39, 27), Vector2(43, 29), c, 1.5)
		"files", "explorer":
			draw_polyline(PackedVector2Array([Vector2(10, 16), Vector2(21, 16), Vector2(25, 20), Vector2(38, 20), Vector2(38, 36), Vector2(10, 36), Vector2(10, 16)]), c, 2.0)
			draw_line(Vector2(13, 25), Vector2(35, 25), c, 1.5)
		"browser":
			draw_circle(Vector2(24, 24), 13, c, false, 2)
			draw_arc(Vector2(24, 24), 6, 0, TAU, 24, c, 1.5)
			draw_line(Vector2(11, 24), Vector2(37, 24), c, 1.5)
		"notes":
			draw_rect(Rect2(14, 11, 20, 26), c, false, 2)
			for y in [18, 24, 30]: draw_line(Vector2(18,y), Vector2(30,y), c)
		"colors":
			for i in range(3): draw_rect(Rect2(12 + i * 8, 14, 7, 20), [Color("e87780"), Color("74c490"), Color("6c9add")][i])
	draw_set_transform(Vector2.ZERO)

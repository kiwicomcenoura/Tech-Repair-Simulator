@tool
extends Control
## Scalable, code-native empty PC illustration; no asset downloads.

func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var scale_factor := minf(size.x / 240.0, size.y / 170.0)
	var origin := size * 0.5 - Vector2(120, 85) * scale_factor
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	var subtle := Color("263b4d")
	var accent := Color("4e91a8")
	for x in range(0, 241, 20):
		for y in range(0, 171, 20):
			draw_circle(Vector2(x, y), 0.65, subtle)
	draw_style_box(_panel(Color("142536"), accent), Rect2(86, 19, 70, 119))
	draw_rect(Rect2(96, 31, 50, 66), subtle, false, 1.0)
	draw_rect(Rect2(105, 40, 25, 25), accent, false, 1.0)
	for y in [77, 84, 110, 116, 122]:
		draw_line(Vector2(101, y), Vector2(140, y), subtle, 2.0)
	draw_circle(Vector2(143, 27), 2, Color("70bcd1"))
	draw_line(Vector2(66, 147), Vector2(176, 147), subtle, 1.0)
	draw_line(Vector2(170, 40), Vector2(191, 40), accent, 1.0)
	draw_line(Vector2(180, 30), Vector2(180, 50), accent, 1.0)
	draw_set_transform(Vector2.ZERO)


func _panel(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

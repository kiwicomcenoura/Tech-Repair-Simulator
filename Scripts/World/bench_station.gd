extends Node2D

const Screen := preload("res://Scripts/UI/bench_video_screen.gd")
const SCREEN_ORIGIN := Vector2(-20, -161)
const SCREEN_PROJECTION := Transform2D(Vector2(0.42, 0.21), Vector2(0, 0.42), SCREEN_ORIGIN)

var status := "off":
	set(value):
		if status == value: return
		status = value
		queue_redraw()


func _process(_delta: float) -> void:
	if status == "artifacts": queue_redraw()


func _draw() -> void:
	# The customer cabinet docks over the mat. Keep the right side clear for the test station.
	var mat := PackedVector2Array([Vector2(-90,-136),Vector2(-22,-102),Vector2(-62,-82),Vector2(-130,-116)])
	draw_colored_polygon(mat, Color("254649"))
	mat.append(mat[0])
	draw_polyline(mat, Color("4a706d"), 1.2, true)
	for i in range(5):
		var mark := Vector2(-124 + i * 5, -116 + i * 2.5)
		draw_line(mark, mark + Vector2(3,-1.5), Color("74a19a"), 0.75)
	# Shallow magnetic screw tray.
	var tray := PackedVector2Array([Vector2(-118,-142),Vector2(-93,-129.5),Vector2(-107,-122.5),Vector2(-132,-135)])
	draw_colored_polygon(tray, Color("17242b"))
	tray.append(tray[0])
	draw_polyline(tray, Color("59686c"), 1.5, true)
	draw_line(Vector2(-122,-136), Vector2(-109,-129.5), Color("35484b"), 1.0, true)
	# The stand and keyboard share the perspective of the tabletop.
	draw_colored_polygon(PackedVector2Array([Vector2(17,-99),Vector2(35,-90),Vector2(19,-82),Vector2(1,-91)]), Color("19262d"))
	draw_line(Vector2(18,-101), Vector2(18,-91), Color("526670"), 5)
	draw_colored_polygon(PackedVector2Array([Vector2(-3,-97),Vector2(23,-84),Vector2(11,-78),Vector2(-15,-91)]), Color("212c33"))
	for row in range(2):
		for key in range(7):
			var start := Vector2(-4 + key * 3.1 - row * 4, -95.5 + key * 1.55 + row * 2)
			draw_line(start, start + Vector2(2,1), Color("67808d"), 1, true)
	# Rear shell, bezel and indicator sit around the shared signal renderer.
	draw_set_transform_matrix(SCREEN_PROJECTION)
	draw_rect(Rect2(-6, -9, 175, 107), Color("34444b"))
	draw_rect(Rect2(-8, -5, 174, 104), Color("101a21"))
	draw_rect(Rect2(-7, -5, 172, 3), Color("52636a"))
	Screen.paint(self, status, float(Time.get_ticks_msec()) / 1000.0)
	var led := Color("56616c")
	if status in ["sync", "no_signal"]: led = Color("b18452")
	elif status != "off": led = Color("76c9b4")
	draw_rect(Rect2(149, 93, 6, 2), led)

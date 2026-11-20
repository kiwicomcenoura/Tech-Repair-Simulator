extends Node2D

const Screen := preload("res://Scripts/UI/bench_video_screen.gd")
const SCREEN_PROJECTION := Transform2D(Vector2(0.45, 0.225), Vector2(0, 0.45), Vector2(-18, -166))
const FRAME := Rect2(-5, -6, 170, 102)
const SHELL_DEPTH := Vector2(4, -2)
const KEYBOARD_PROJECTION := Transform2D(Vector2(1, 0.5), Vector2(-1, 0.5), Vector2(-4, -101))

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
	_draw_monitor_stand()
	_draw_monitor()
	_draw_keyboard()


func _draw_monitor_stand() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(15,-100), Vector2(38,-89), Vector2(20,-80), Vector2(-3,-91)]), Color(0.03, 0.07, 0.10, 0.34))
	draw_colored_polygon(PackedVector2Array([Vector2(14,-99), Vector2(32,-90), Vector2(17,-82.5), Vector2(-1,-91.5)]), Color("23313b"))
	draw_polyline(PackedVector2Array([Vector2(-1,-91.5), Vector2(17,-82.5), Vector2(32,-90)]), Color("101a22"), 1.6)
	draw_colored_polygon(PackedVector2Array([Vector2(13,-108), Vector2(19,-105), Vector2(19,-91), Vector2(13,-94)]), Color("445763"))
	draw_colored_polygon(PackedVector2Array([Vector2(19,-105), Vector2(22,-106.5), Vector2(22,-92.5), Vector2(19,-91)]), Color("243440"))


func _draw_monitor() -> void:
	var top_left := SCREEN_PROJECTION * FRAME.position
	var top_right := SCREEN_PROJECTION * Vector2(FRAME.end.x, FRAME.position.y)
	var bottom_right := SCREEN_PROJECTION * FRAME.end
	draw_colored_polygon(PackedVector2Array([top_left, top_left + SHELL_DEPTH, top_right + SHELL_DEPTH, top_right]), Color("586773"))
	draw_colored_polygon(PackedVector2Array([top_right, top_right + SHELL_DEPTH, bottom_right + SHELL_DEPTH, bottom_right]), Color("283742"))
	draw_set_transform_matrix(SCREEN_PROJECTION)
	draw_rect(FRAME, Color("17232d"))
	draw_rect(Rect2(-5, -6, 170, 2), Color("6b7c85"))
	draw_rect(Rect2(-5, -4, 2, 98), Color("465862"))
	draw_rect(Rect2(-3, -3, 166, 96), Color("080e16"))
	Screen.paint(self, status, float(Time.get_ticks_msec()) / 1000.0)
	if status in ["off", "sync", "no_signal"]:
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(7, 0), Vector2(35, 90), Vector2(27, 90)]), Color(0.16, 0.24, 0.30, 0.16))
	draw_rect(Rect2(-5, 94, 170, 2), Color("30424f"))
	var led := Color("56616c")
	if status in ["sync", "no_signal"]: led = Color("b18452")
	elif status != "off": led = Color("76c9b4")
	draw_rect(Rect2(151, 92, 4, 2), led)
	draw_set_transform(Vector2.ZERO)


func _draw_keyboard() -> void:
	draw_set_transform_matrix(KEYBOARD_PROJECTION)
	draw_rect(Rect2(2, 1, 29, 12), Color(0.03, 0.07, 0.10, 0.38))
	draw_rect(Rect2(0, 0, 29, 11), Color("23313b"))
	draw_rect(Rect2(1, 0, 27, 1), Color("5a6e78"))
	for row in range(2):
		for col in range(8):
			draw_rect(Rect2(2 + col * 3, 2 + row * 2.5, 2, 1.5), Color("58707c"))
	draw_rect(Rect2(8, 7, 11, 1.5), Color("68818a"))
	draw_rect(Rect2(22, 7, 4, 1.5), Color("4e6572"))
	draw_set_transform(Vector2.ZERO)

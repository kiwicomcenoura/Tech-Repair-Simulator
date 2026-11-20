extends Control

const DISPLAY_SIZE := Vector2(160, 90)
const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const STATUS := {
	"off": "Desligado",
	"sync": "Aguardando sincronização",
	"no_signal": "Sem sinal",
	"post": "Inicialização",
	"firmware": "Sinal ativo · Verifique o POST",
	"desktop": "Imagem estável",
	"installer": "Instalador TechOS",
	"pattern": "Teste de vídeo em andamento",
	"artifacts": "Anomalias · Sinal intermitente",
}
const TEST_COLORS := [Color("d5dde4"), Color("ddbd54"), Color("61c5c9"), Color("72b486"), Color("c779b9"), Color("c26668"), Color("5b7ebd")]

var status := "off":
	set(value):
		if status == value: return
		status = value
		queue_redraw()
var effects_only := false


func _process(_delta: float) -> void:
	if is_visible_in_tree() and status == "artifacts": queue_redraw()


func _draw() -> void:
	if effects_only:
		draw_set_transform(Vector2.ZERO, 0.0, size / DISPLAY_SIZE)
		paint_artifacts(self, float(Time.get_ticks_msec()) / 1000.0, false)
		return
	var scale_factor := minf(size.x / DISPLAY_SIZE.x, size.y / DISPLAY_SIZE.y)
	var display := DISPLAY_SIZE * scale_factor
	draw_set_transform((size - display) * 0.5, 0.0, Vector2.ONE * scale_factor)
	paint(self, status, float(Time.get_ticks_msec()) / 1000.0)


static func paint(canvas: CanvasItem, state: String, seconds: float) -> void:
	var bounds := Rect2(Vector2.ZERO, DISPLAY_SIZE)
	canvas.draw_rect(bounds, Color("080d13"))
	var interrupted := state == "artifacts" and fmod(seconds, 1.8) > 1.48
	if state in ["off", "sync", "no_signal"] or interrupted:
		canvas.draw_line(Vector2(5, 2), Vector2(46, 2), Color("202b32"), 1)
		return
	if state == "pattern":
		for i in range(TEST_COLORS.size()):
			canvas.draw_rect(Rect2(i * 22, 3, 22, 63), TEST_COLORS[i])
			var gray := 1.0 - float(i) / 7.0
			canvas.draw_rect(Rect2(i * 22, 66, 22, 21), Color(gray, gray, gray))
		return
	var font := ThemeDB.fallback_font
	if state == "installer":
		canvas.draw_string(font, Vector2(9, 27), Prefs.t("Instalador TechOS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a0d7d0"))
		return
	if state in ["post", "firmware"]:
		canvas.draw_string(font, Vector2(9, 22), "OFICINA BIOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a0d7d0"))
		canvas.draw_string(font, Vector2(9, 42), Prefs.t("POST em execução" if state == "post" else "Consulte o diagnóstico"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("98aebd"))
		return
	canvas.draw_rect(bounds, Color("17334a"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(39,90), Vector2(105,0), Vector2(160,0), Vector2(160,90)]), Color("214861"))
	canvas.draw_rect(Rect2(0, 76, 160, 14), Color("112233"))
	for i in range(3):
		canvas.draw_rect(Rect2(10 + i * 17, 80, 8, 5), Color("7096ac"))
	canvas.draw_string(font, Vector2(10, 22), Prefs.t("Sistema do cliente"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c0dbe9"))
	if state != "artifacts": return
	paint_artifacts(canvas, seconds)


static func paint_artifacts(canvas: CanvasItem, seconds: float, show_warning: bool = true) -> void:
	if fmod(seconds, 1.8) > 1.48:
		canvas.draw_rect(Rect2(Vector2.ZERO, DISPLAY_SIZE), Color("080d13"))
		return
	var phase := floori(seconds * 4.0)
	for i in range(9):
		var x := (i * 31 + phase * 11) % 123
		var y := 6 + (i * 17 + phase * 3) % 75
		var color: Color = TEST_COLORS[(i + phase) % TEST_COLORS.size()]
		canvas.draw_rect(Rect2(x, y, 8 + i * 3, 2 + i % 3), color)
	if show_warning:
		canvas.draw_rect(Rect2(40, 32, 80, 22), Color("22293c"))
		canvas.draw_string(ThemeDB.fallback_font, Vector2(44, 47), Prefs.t("ANOMALIAS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("efb56c"))

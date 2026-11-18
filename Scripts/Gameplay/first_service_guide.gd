extends Node2D
## Shows the next action for the guided order using the same records as delivery.

const Orders := preload("res://Scripts/Gameplay/service_orders.gd")
const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const ACCENT := Color("96d4dc")

var _panel: PanelContainer
var _hint: Label
var _target := Vector2.INF

@onready var workshop: Node = get_parent()
@onready var model: RefCounted = workshop.ledger
@onready var bench: CanvasLayer = workshop.bench_ui
@onready var personal: CanvasLayer = workshop.get_parent().get_node("PersonalComputerUI")
@onready var bench_hint: Label = bench.get_node("%FirstServiceHint")
@onready var personal_hint: Label = personal.get_node("%FirstServiceHint")
@onready var computer: Node2D = workshop.actor_parent.get_node("WorkComputer")


func _ready() -> void:
	z_index = 8
	_panel = PanelContainer.new()
	_panel.name = "FirstServicePanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.theme = preload("res://Themes/maintenance_bench.tres")
	workshop._hud.add_child(_panel)
	_panel.position = Vector2(20, 62)
	_panel.size.x = 380
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.13, 0.18, 0.96)
	style.border_color = ACCENT.darkened(0.42)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 4)
	_panel.add_child(content)
	var title := Label.new()
	title.text = "Primeira ordem guiada"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", ACCENT)
	content.add_child(title)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 15)
	content.add_child(_hint)
	_process(0.0)


func _process(_delta: float) -> void:
	var world_text := ""
	var bench_text := ""
	var personal_text := ""
	var order := Orders.guided_order(model)
	var previous_target := _target
	_target = Vector2.INF
	if order.get("status") == "offered":
		_target = _counter_marker()
		world_text = "Use WASD para ir ao balcão marcado. Pressione F e escolha Receber serviço na ordem guiada."
	elif order.get("status") == "active":
		var pc: Dictionary = model.item(order.pc_id)
		var installed: Dictionary = model.item(pc.components.get("ram", ""))
		var replaced := Orders.valid_replacement(order, "ram", installed)
		var ready_to_return: bool = replaced and installed.tested and not pc.power and pc.lid and not false in pc.screws and Orders.post_verified(model, pc)
		if not model.state.tools:
			_target = workshop.TOOLBOX_ACCESS_POSITION + Vector2(0, -59)
			world_text = "Vá à caixa de ferramentas junto ao armário e pressione F para pegar a chave Phillips."
			bench_text = "Feche a bancada e abra a caixa de ferramentas junto ao armário com F."
		elif pc.location != "bench":
			world_text = _transport_step(pc, ready_to_return)
		elif ready_to_return:
			_target = _bench_marker()
			world_text = "Pegue o gabinete fechado com Shift+E e leve-o de volta ao balcão."
			bench_text = "Gabinete pronto. Feche a bancada e pressione Shift+E para pegá-lo."
		else:
			var original_in_slot: bool = installed.get("id", "") == order.originals.get("ram")
			var diagnosed: bool = not original_in_slot or installed.tested
			var replacement := _find_replacement(order) if not replaced and diagnosed else {}
			if diagnosed and not replaced and not pc.power and replacement.get("location", "") not in ["tray", "inventory", "carried"]:
				world_text = _supply_step(replacement)
				bench_text = "Feche a bancada para buscar uma RAM DDR4 de reposição."
				if replacement.is_empty():
					personal_text = "Abra Loja de Peças no TechOS e compre uma RAM DDR4. A entrega chega na área de recebimento."
				else:
					personal_text = "Feche o TechOS com Esc e siga o marcador para buscar a RAM DDR4."
			else:
				_target = _bench_marker()
				world_text = "Aproxime-se da bancada e pressione F para abrir a manutenção."
				if replacement.get("location") == "carried":
					world_text = "Leve a RAM até a bancada e pressione E para colocá-la na bandeja. Depois pressione F."
				bench_text = _inspection_step(pc, installed, replacement, diagnosed, replaced)
				if not bench.inspection.visible:
					bench_text = "Clique em Inspecionar para continuar o conserto do PC."
				elif bench.inspection.get_node("ClientOS").visible:
					bench_text = "Volte à inspeção para continuar o conserto do PC."
	_show_hint(_hint, world_text)
	_panel.visible = not world_text.is_empty()
	_show_hint(bench_hint, bench_text if order.get("pc_id") == model.bench_id() else "")
	_show_hint(personal_hint, personal_text)
	if get_tree().paused: _target = Vector2.INF
	if _target != previous_target: queue_redraw()


func _show_hint(label: Label, hint: String) -> void:
	var translated := Prefs.t(hint) if not hint.is_empty() else ""
	if label.text != translated: label.text = translated
	label.visible = not translated.is_empty()


func _transport_step(pc: Dictionary, ready_to_return: bool) -> String:
	if pc.location != "carried":
		_target = workshop.actors[pc.id].global_position + Vector2(0, -52)
		return "Aproxime-se do gabinete do cliente e pressione E para pegá-lo."
	if ready_to_return:
		_target = _counter_marker()
		return "Leve o gabinete ao balcão. Pressione F e escolha Entregar ao cliente."
	_target = _bench_marker()
	if not model.bench_id().is_empty():
		return "A bancada está ocupada. Deixe este gabinete no chão com E e libere a bancada."
	return "Leve o gabinete até a bancada marcada e pressione E para colocá-lo no tampo."


func _find_replacement(order: Dictionary) -> Dictionary:
	var locations := ["inventory", "tray", "carried", "floor", "delivery", "shelf"]
	var closest := locations.size()
	var replacement := {}
	for item in model.state.items.values():
		if item.kind != "ram" or item.get("ddr") != "DDR4" or not Orders.valid_replacement(order, "ram", item):
			continue
		var rank := locations.find(item.location)
		if rank >= 0 and rank < closest:
			replacement = item
			closest = rank
	return replacement


func _supply_step(replacement: Dictionary) -> String:
	match replacement.get("location", ""):
		"floor":
			_target = workshop.actors[replacement.id].global_position + Vector2(0, -46)
			if replacement.packaged: return "Vá até a entrega e pressione E para abrir a caixa de RAM DDR4."
			return "Pressione E ao lado da RAM DDR4 desembalada para pegá-la."
		"delivery":
			_target = Vector2(replacement.position[0], replacement.position[1] - 46)
			return "A RAM DDR4 foi comprada. Aguarde a caixa chegar à área de recebimento."
		"shelf":
			_target = workshop.actor_parent.get_node("Shelf").global_position + Vector2(36, -75)
			return "Vá ao armário, pressione F e mova a RAM DDR4 do armário para o inventário."
		_:
			_target = computer.global_position + Vector2(0, -83)
			return "Pressione F no computador da oficina. Ligue-o e compre RAM DDR4 em Loja de Peças."


func _inspection_step(pc: Dictionary, installed: Dictionary, replacement: Dictionary, diagnosed: bool, replaced: bool) -> String:
	if float(pc.boot_remaining) > 0:
		return "Aguarde a verificação de inicialização (POST)."
	if not diagnosed and not false in pc.latches:
		if not pc.power: return "Clique em Ligar PC para verificar a inicialização do gabinete do cliente."
		return "Clique em Testar RAM para identificar o problema de memória, mesmo com o POST falhando."
	if not replaced or false in pc.latches:
		if pc.power: return "Clique em Desligar PC antes de mexer no gabinete."
		if pc.lid:
			if true in pc.screws: return "Selecione Phillips (2) e clique nos quatro parafusos da tampa para soltá-los."
			return "Clique em Retirar tampa para acessar os componentes."
		if replaced or not diagnosed: return "Selecione Mãos (1) e feche as duas travas do slot A1, ao lado do cooler."
		if true in pc.latches: return "Selecione Mãos (1) e abra as duas travas do slot A1, ao lado do cooler."
		if not installed.is_empty(): return "Com Mãos (1), clique no módulo A1 para retirar a RAM defeituosa."
		if workshop.selected_ram != replacement.get("id"):
			return "Role a coluna Ferramentas até Peças e selecione a RAM DDR4. Com Mãos (1), clique no slot A1 vazio."
		return "Com Mãos (1), clique no slot A1 vazio para instalar a RAM selecionada."
	if not Orders.post_verified(model, pc):
		if not pc.power: return "Clique em Ligar PC e confirme que o POST agora passa com a nova RAM."
		return "Confira as peças e fixações indicadas no resultado do POST. Desligue o PC antes de ajustá-las."
	if not installed.tested:
		if not pc.power: return "Ligue o PC para testar a RAM de reposição."
		return "Clique em Testar RAM para registrar a condição do módulo novo."
	if pc.power: return "Clique em Desligar PC antes de fechar o gabinete."
	if not pc.lid: return "Clique em Recolocar tampa para fechar o gabinete."
	return "Selecione Phillips (2) e fixe os quatro parafusos da tampa."


func _bench_marker() -> Vector2:
	return workshop.dock.slot.global_position + Vector2(0, -46)


func _counter_marker() -> Vector2:
	return workshop.counter.global_position + Vector2(0, -116)


func _draw() -> void:
	if not _target.is_finite(): return
	var point := to_local(_target)
	var arrow := PackedVector2Array([point + Vector2(-10, -12), point + Vector2(10, -12), point])
	draw_colored_polygon(arrow, ACCENT)
	arrow.append(arrow[0])
	draw_polyline(arrow, Color("10222d"), 2.0, true)

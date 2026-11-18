extends Control
## Fictional local desktop with workshop clients and component shopping.

signal shutdown_requested
signal exit_requested
signal client_app_installed(id: String)

const ClientApps := preload("res://Scripts/TechOS/client_apps.gd")
const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const WINDOW := preload("res://Scenes/UI/TechOS/AppWindow.tscn")
const ICON := preload("res://Scripts/TechOS/app_icon.gd")
const APPS := {
	"messages": {"title": "Mensagens", "empty_title": "Nenhuma conversa", "description": "As conversas simuladas da oficina aparecerão aqui.\nO aplicativo ainda não possui mensagens ou conexão externa."},
	"clients": {"title": "Clientes", "empty_title": "Nenhum cliente cadastrado", "description": "Este espaço está preparado para os futuros clientes e pedidos de manutenção.\nNenhum cadastro foi criado."},
	"shop": {"title": "Loja de Peças", "empty_title": "Catálogo indisponível", "description": "A loja de peças será disponibilizada em uma etapa futura.\nNenhuma compra pode ser realizada."},
	"finances": {"title": "Finanças", "empty_title": "Extrato em preparação", "description": "O relatório financeiro detalhado ainda não foi implementado.\nAs compras de RAM são debitadas no saldo do TechMarket."},
	"marketing": {"title": "Marketing", "empty_title": "Nenhuma campanha", "description": "Um espaço para as futuras ações de divulgação da oficina.\nNenhuma campanha está ativa."},
	"files": {"title": "Arquivos", "empty_title": "Esta pasta está vazia", "description": "Os arquivos fictícios do jogo ficarão organizados aqui.\nEste aplicativo não acessa os arquivos reais do computador."},
}

var windows: Dictionary = {}
var task_buttons: Dictionary = {}
var launchers: Dictionary = {}
var menu_launchers: Dictionary = {}
var active_app := ""
var running := false
var simulated_minutes := 540.0
var _last_minute := -1
var _menu_tween: Tween
var client_mode := false
var installed_apps: Array = []


func _ready() -> void:
	if client_mode:
		$Brand.text = "TechOS / CLIENTE"
		$Wallpaper.client_mode = true
		%DesktopExit.text = "Voltar à inspeção"
		$StartMenu/Content/User.text = "Sessão do cliente"
	for id in ClientApps.BUILT_IN if client_mode else APPS:
		_add_shortcuts(id)
	%StartButton.pressed.connect(toggle_start)
	%TaskPower.pressed.connect(func() -> void: shutdown_requested.emit())
	%MenuPower.pressed.connect(func() -> void: shutdown_requested.emit())
	%DesktopExit.pressed.connect(func() -> void: exit_requested.emit())
	%WindowsArea.resized.connect(_resize_windows)
	%StartMenu.hide()
	_update_clock()

func _add_shortcuts(id: String) -> void:
	if launchers.has(id): return
	var shortcut := _make_launcher(id, false)
	%IconGrid.add_child(shortcut)
	launchers[id] = shortcut
	var menu_shortcut := _make_launcher(id, true)
	%MenuApps.add_child(menu_shortcut)
	menu_launchers[id] = menu_shortcut


func set_client_apps(ids: Array) -> void:
	for id in ClientApps.OPTIONAL:
		if launchers.has(id) and id not in ids:
			close_app(id)
			for button in [launchers[id], menu_launchers[id]]:
				button.get_parent().remove_child(button)
				button.queue_free()
			launchers.erase(id)
			menu_launchers.erase(id)
		elif id in ids:
			_add_shortcuts(id)
	installed_apps = ids.duplicate()


func install_client_app(id: String) -> void:
	if not client_mode or not ClientApps.OPTIONAL.has(id) or id in installed_apps: return
	set_client_apps(installed_apps + [id])
	client_app_installed.emit(id)


func _definition(id: String) -> Dictionary:
	return ClientApps.definition(id) if client_mode else APPS.get(id, {})


func _make_launcher(id: String, menu: bool) -> Button:
	var button := Button.new()
	button.name = ("Menu_" if menu else "Icon_") + id
	button.theme_type_variation = &"LauncherButton"
	button.custom_minimum_size = Vector2(0, 42) if menu else Vector2(104, 94)
	button.tooltip_text = _definition(id).title
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var container: BoxContainer = HBoxContainer.new() if menu else VBoxContainer.new()
	button.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.offset_left = 7
	container.offset_top = 5
	container.offset_right = -7
	container.offset_bottom = -5
	container.add_theme_constant_override("separation", 8 if menu else 5)
	var icon: Control = ICON.new()
	icon.app_id = id
	icon.custom_minimum_size = Vector2.ONE * (30 if menu else 46)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.add_child(icon)
	var label := Label.new()
	label.text = _definition(id).title
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if menu else HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	if not menu:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 88
	container.add_child(label)
	_ignore_mouse(container)
	button.pressed.connect(open_app.bind(id))
	return button


func _ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control: _ignore_mouse(child)


func set_running(value: bool) -> void:
	if running == value:
		return
	running = value
	if not running:
		close_all_apps()
		dismiss_popup()


func open_app(id: String) -> Control:
	if not running or not launchers.has(id):
		return null
	dismiss_popup()
	if windows.has(id):
		windows[id].show()
		_activate(id)
		return windows[id]
	var window: PanelContainer = WINDOW.instantiate()
	window.name = "Window_" + id
	%WindowsArea.add_child(window)
	window.configure(id, _definition(id))
	if client_mode:
		window.preferred_size = Vector2(650, 350)
		window.get_node("Layout/FooterMargin").hide()
		window.get_node("Layout/BodyMargin/Body/Sidebar").hide()
		var main := window.get_node("Layout/BodyMargin/Body/Main")
		main.get_node("EmptyCard").hide()
		main.add_child(ClientApps.build(id, self))
	if id == "clients":
		var workshop: Node = get_tree().root.find_child("PhysicalWorkshop", true, false)
		if workshop != null:
			window.preferred_size = Vector2(940, 620)
			window.get_node("Layout/FooterMargin/Footer").text = "Ordens de serviço · Recebimento e entrega no balcão"
			window.get_node("Layout/BodyMargin/Body/Main/EmptyCard").hide()
			var board := preload("res://Scripts/UI/service_orders_board.gd").new()
			board.workshop = workshop
			board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			board.size_flags_vertical = Control.SIZE_EXPAND_FILL
			window.get_node("Layout/BodyMargin/Body/Main").add_child(board)
	if id == "shop":
		var workshop: Node = get_tree().root.find_child("PhysicalWorkshop", true, false)
		if workshop != null:
			window.preferred_size = Vector2(940, 620)
			window.get_node("Layout/FooterMargin/Footer").text = "TechMarket · Compras locais e entregas físicas"
			window.get_node("Layout/BodyMargin/Body/Main/EmptyCard").hide()
			var market: VBoxContainer = preload("res://Scripts/Gameplay/techmarket.gd").new()
			market.workshop = workshop
			market.sidebar = window.get_node("Layout/BodyMargin/Body/Sidebar")
			var scroll := ScrollContainer.new()
			scroll.name = "MarketScroll"
			scroll.custom_minimum_size = Vector2(0, 220)
			scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
			scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			market.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			market.size_flags_vertical = Control.SIZE_EXPAND_FILL
			window.get_node("Layout/BodyMargin/Body/Main").add_child(scroll)
			scroll.add_child(market)
	window.fit_to_area()
	window.position = Vector2(235 + windows.size() * 24, 34 + windows.size() * 22) if client_mode else Vector2(250 + windows.size() * 30, 48 + windows.size() * 25)
	window.clamp_position()
	window.focus_requested.connect(_activate)
	window.close_requested.connect(close_app)
	window.minimize_requested.connect(minimize_app)
	windows[id] = window
	var task := Button.new()
	task.name = "Task_" + id
	task.text = _definition(id).title
	task.custom_minimum_size = Vector2(100, 36)
	task.toggle_mode = true
	task.tooltip_text = task.text + " · alternar / minimizar"
	task.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	task.add_theme_font_size_override("font_size", 12)
	task.pressed.connect(_task_clicked.bind(id))
	%OpenApps.add_child(task)
	task_buttons[id] = task
	_activate(id)
	return window


func _activate(id: String) -> void:
	if not windows.has(id):
		return
	active_app = id
	%WindowsArea.move_child(windows[id], -1)
	for key in windows:
		windows[key].set_active(key == id)
		task_buttons[key].set_pressed_no_signal(key == id and windows[key].visible)


func _task_clicked(id: String) -> void:
	if not windows.has(id):
		return
	if active_app == id and windows[id].visible:
		minimize_app(id)
	else:
		windows[id].show()
		_activate(id)


func minimize_app(id: String) -> void:
	if not windows.has(id):
		return
	windows[id].hide()
	task_buttons[id].set_pressed_no_signal(false)
	_activate_top_visible()


func _activate_top_visible() -> void:
	active_app = ""
	var children := %WindowsArea.get_children()
	children.reverse()
	for child in children:
		if child.visible:
			_activate(child.app_id)
			return


func close_app(id: String) -> void:
	if not windows.has(id):
		return
	var window: Control = windows[id]
	%WindowsArea.remove_child(window)
	window.queue_free()
	var task: Button = task_buttons[id]
	%OpenApps.remove_child(task)
	task.queue_free()
	windows.erase(id)
	task_buttons.erase(id)
	_activate_top_visible()


func close_all_apps() -> void:
	for id in windows.keys():
		close_app(id)


func toggle_start() -> void:
	if not running:
		return
	if dismiss_popup():
		return
	var menu: Control = %StartMenu
	menu.size = Vector2(340, minf(450, size.y - 80))
	menu.position = Vector2(12, maxf(4, size.y - 68 - menu.size.y))
	menu.modulate.a = 0.0
	menu.show()
	%StartButton.set_pressed_no_signal(true)
	_menu_tween = create_tween()
	_menu_tween.tween_property(menu, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE)


func dismiss_popup() -> bool:
	if not %StartMenu.visible:
		return false
	if is_instance_valid(_menu_tween): _menu_tween.kill()
	%StartMenu.hide()
	%StartButton.set_pressed_no_signal(false)
	return true


func _resize_windows() -> void:
	for window in windows.values():
		window.fit_to_area()
	dismiss_popup()


func _process(delta: float) -> void:
	# Session time keeps advancing even when the PC is switched off.
	simulated_minutes += delta / 6.0
	if running:
		# Fictional game time, never the host clock. One game minute / 6 seconds.
		_update_clock()


func _update_clock() -> void:
	var total := floori(simulated_minutes)
	if total == _last_minute:
		return
	_last_minute = total
	%ClockText.text = "%02d:%02d" % [floori(float(total % 1440) / 60.0), total % 60]
	%ClockDay.text = Prefs.t("Dia %02d · local") % (floori(float(total) / 1440.0) + 1)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_last_minute = -1
		_update_clock()


func _input(event: InputEvent) -> void:
	if not running or not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.pressed:
		if %StartMenu.visible:
			if %StartMenu.get_global_rect().has_point(event.position) or %StartButton.get_global_rect().has_point(event.position):
				return
			dismiss_popup()
		# Clicking any visible part of the topmost window brings it forward.
		var children := %WindowsArea.get_children()
		children.reverse()
		for window in children:
			if window.visible and window.get_global_rect().has_point(event.position):
				_activate(window.app_id)
				break
	elif event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.keycode == KEY_TAB:
		var ids := windows.keys()
		if not ids.is_empty():
			var next := (ids.find(active_app) + 1) % ids.size()
			windows[ids[next]].show()
			_activate(ids[next])
		get_viewport().set_input_as_handled()


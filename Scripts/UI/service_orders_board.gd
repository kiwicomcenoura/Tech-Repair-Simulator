extends VBoxContainer

const Prefs := preload("res://Scripts/UI/player_preferences.gd")

const Orders := preload("res://Scripts/Gameplay/service_orders.gd")
var workshop: Node
var _filter: OptionButton
var _summary: Label
var _progress: Label
var _notice: Label
var _list: VBoxContainer
var _scroll: ScrollContainer
var _refresh_pending := false

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 18)
	add_child(_summary)
	_progress = _label(self, "", 14)
	_progress.modulate = Color("96d4dc")
	var help := Label.new()
	help.text = "Receba e entregue no balcão (F). Consulte a fila com O. O adiantamento cobre as peças; a mão de obra é paga na entrega."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 13)
	add_child(help)
	_filter = OptionButton.new()
	_filter.name = "OrderFilter"
	for title in ["Propostas de clientes", "Fila de serviços", "Entregas concluídas"]: _filter.add_item(title)
	_filter.item_selected.connect(func(_index: int) -> void: refresh())
	add_child(_filter)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size.y = 160
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 12)
	_scroll.add_child(_list)
	_notice = Label.new()
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.add_theme_font_size_override("font_size", 13)
	add_child(_notice)
	workshop.ledger.changed.connect(_schedule_refresh)
	workshop.ledger.feedback.connect(_feedback)
	Prefs.on_change(_schedule_refresh)
	refresh()

func _schedule_refresh() -> void:
	if _refresh_pending: return
	_refresh_pending = true
	refresh.call_deferred()

func _feedback(text: String, failed: bool) -> void:
	_notice.text = text
	_notice.modulate = Color("efbf95") if failed else Color("96d4c8")

func refresh() -> void:
	_refresh_pending = false
	if not is_node_ready(): return
	Orders.ensure(workshop.ledger)
	var completed := Orders.completed_count(workshop.ledger.state)
	_summary.text = Prefs.t("%d / %d serviços ativos · %d entregas · %s") % [Orders.orders(workshop.ledger, "active").size(), Orders.MAX_ACTIVE, completed, Prefs.money(workshop.ledger.state.credits)]
	var milestone := Orders.next_milestone(completed)
	_progress.text = Prefs.t("Todos os tipos de serviço foram desbloqueados.")
	if not milestone.is_empty():
		_progress.text = Prefs.t("Conclua %d entregas para liberar %s e uma expansão do armário.") % [milestone.deliveries, Prefs.t(milestone.services)]
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var status: String = ["offered", "active", "delivered"][_filter.selected]
	var entries: Array = Orders.orders(workshop.ledger, status)
	if status == "active": entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority < b.priority)
	if status == "delivered": entries.reverse()
	if entries.is_empty():
		_label(_list, {"offered": "Nenhuma proposta agora. Novos clientes chegam enquanto você trabalha na oficina.", "active": "A fila está vazia. Receba um serviço no balcão para começar.", "delivered": "Seus serviços concluídos aparecerão aqui."}[status], 15)
	var number := 0
	for order in entries:
		number += 1
		if status == "delivered" and number > 20: break
		_card(order, number)

func _label(parent: Node, text: String, font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _action(parent: Node, text: String, id: String, callback: Callable, reason: String = "") -> void:
	var button := Button.new()
	button.name = id
	button.text = text
	button.custom_minimum_size = Vector2(0, 36)
	button.disabled = not reason.is_empty()
	button.tooltip_text = reason
	button.pressed.connect(callback)
	parent.add_child(button)

func _card(order: Dictionary, number: int) -> void:
	var panel := PanelContainer.new()
	panel.name = order.id
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172733")
	style.border_color = Color("344f61")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	_list.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	var prefix := "%dº na fila · " % number if order.status == "active" else ""
	_label(body, prefix+order.id+" · "+order.client, 18).modulate = Color("96d4dc")
	_label(body, order.title, 16)
	if order.get("guided", false) and order.status != "delivered":
		_label(body, "Primeira ordem guiada", 13).modulate = Color("96d4dc")
	_label(body, "“"+Orders.localized_report(order)+"”", 14)
	_label(body, Prefs.t("Total: %s · Adiantamento para peças: %s · Na entrega: %s") % [Prefs.money(order.reward), Prefs.money(order.deposit), Prefs.money(order.reward-order.deposit)], 13)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	var at_counter: bool = workshop._near_counter()
	if order.status == "offered":
		_label(body, "O gabinete será recebido fisicamente ao aceitar. Peças são compradas à parte no TechMarket.", 13)
		body.add_child(actions)
		var reason := "Aproxime-se do balcão para receber o cliente." if not at_counter else ""
		if Orders.orders(workshop.ledger, "active").size() >= Orders.MAX_ACTIVE: reason = "Conclua um pedido para liberar espaço na fila."
		_action(actions, "Receber serviço", "Accept_"+order.id, _accept.bind(order.id), reason)
		_action(actions, "Recusar proposta", "Decline_"+order.id, func() -> void: Orders.decline(workshop.ledger, order.id))
	elif order.status == "active":
		var requirements: Array = Orders.requirements(workshop.ledger, order)
		var ready := true
		for requirement in requirements:
			_label(body, ("✓ " if requirement.ok else "○ ") + Prefs.t(requirement.text), 13).modulate = Color("9cd4ba") if requirement.ok else Color("c7d0d7")
			if not requirement.ok: ready = false
		body.add_child(actions)
		_action(actions, "Priorizar", "Prioritize_"+order.id, func() -> void: Orders.prioritize(workshop.ledger, order.id))
		var reason := "Conclua os itens da lista antes de entregar." if not ready else ""
		if not at_counter: reason = "Leve o gabinete até o balcão."
		_action(actions, "Entregar ao cliente", "Deliver_"+order.id, _deliver.bind(order.id), reason)
	else:
		_label(body, "Entregue · Pagamento concluído", 14).modulate = Color("9cd4ba")

func _accept(id: String) -> void:
	if not workshop._near_counter():
		workshop.ledger.fail("Receba o cliente no balcão de atendimento.")
		return
	if Orders.accept(workshop.ledger, id):
		_filter.select(1)
		_schedule_refresh()

func _deliver(id: String) -> void:
	if not workshop._near_counter():
		workshop.ledger.fail("A entrega deve ser feita no balcão.")
		return
	if Orders.deliver(workshop.ledger, id):
		_filter.select(2)
		_schedule_refresh()

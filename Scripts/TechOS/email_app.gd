extends HSplitContainer

const Mail := preload("res://Scripts/Gameplay/workshop_mail.gd")
const Replies := preload("res://Scripts/Gameplay/mail_replies.gd")
const Prefs := preload("res://Scripts/UI/player_preferences.gd")

var ledger: RefCounted
var desktop: Control
var _thread_id := 0
var _previous_thread := 0
var _composing := false
var _drafts: Dictionary = {}
var _mailbox: Dictionary = {}
var _rendered_id := 0
var _rendered_messages := 0
var _rendered_last: Dictionary = {}
var _search: LineEdit
var _filter: OptionButton
var _threads: VBoxContainer
var _thread_buttons: Dictionary = {}
var _heading: Label
var _contact: Label
var _history_scroll: ScrollContainer
var _history: VBoxContainer
var _recipient: OptionButton
var _subject: LineEdit
var _editor: TextEdit
var _send: Button
var _cancel: Button
var _info: Label
var _send_error := ""


func _ready() -> void:
	name = "WorkshopEmail"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 16)
	_build_inbox()
	_build_reader()
	ledger.mail_changed.connect(refresh)
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree() and _thread_id != 0: _mark_open_read.call_deferred(_thread_id))
	refresh()


func _build_inbox() -> void:
	var inbox := VBoxContainer.new()
	inbox.custom_minimum_size.x = 204
	inbox.add_theme_constant_override("separation", 8)
	add_child(inbox)
	var write := Button.new()
	write.name = "NewEmail"
	write.text = Prefs.t("Escrever email")
	write.custom_minimum_size.y = 36
	write.pressed.connect(_compose)
	inbox.add_child(write)
	_search = LineEdit.new()
	_search.name = "SearchEmail"
	_search.placeholder_text = Prefs.t("Buscar conversas")
	_search.clear_button_enabled = true
	_search.text_changed.connect(func(_text: String) -> void: _refresh_inbox())
	inbox.add_child(_search)
	_filter = OptionButton.new()
	_filter.name = "EmailFilter"
	_filter.add_item(Prefs.t("Todas as conversas"))
	_filter.add_item(Prefs.t("Não lidas"))
	_filter.add_item(Prefs.t("Enviadas"))
	_filter.item_selected.connect(func(_index: int) -> void: _refresh_inbox())
	inbox.add_child(_filter)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	inbox.add_child(scroll)
	_threads = VBoxContainer.new()
	_threads.name = "EmailThreads"
	_threads.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_threads.add_theme_constant_override("separation", 4)
	scroll.add_child(_threads)


func _build_reader() -> void:
	var reader := VBoxContainer.new()
	reader.custom_minimum_size.x = 275
	reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reader.add_theme_constant_override("separation", 8)
	add_child(reader)
	_heading = Label.new()
	_heading.name = "EmailSubjectTitle"
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_heading.add_theme_font_size_override("font_size", 19)
	reader.add_child(_heading)
	_contact = Label.new()
	_contact.theme_type_variation = &"Muted"
	_contact.clip_text = true
	reader.add_child(_contact)
	_history_scroll = ScrollContainer.new()
	_history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reader.add_child(_history_scroll)
	_history = VBoxContainer.new()
	_history.name = "EmailHistory"
	_history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_history.add_theme_constant_override("separation", 8)
	_history_scroll.add_child(_history)
	_recipient = OptionButton.new()
	_recipient.name = "EmailRecipient"
	_recipient.fit_to_longest_item = false
	_recipient.clip_text = true
	_recipient.item_selected.connect(func(_index: int) -> void: _update_send())
	reader.add_child(_recipient)
	_subject = LineEdit.new()
	_subject.name = "EmailSubject"
	_subject.placeholder_text = Prefs.t("Assunto")
	_subject.max_length = Mail.MAX_SUBJECT
	_subject.text_changed.connect(func(_text: String) -> void: _update_send())
	reader.add_child(_subject)
	_editor = TextEdit.new()
	_editor.name = "EmailBody"
	_editor.custom_minimum_size.y = 92
	_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_editor.text_changed.connect(_update_send)
	_editor.gui_input.connect(_editor_input)
	reader.add_child(_editor)
	var footer := HBoxContainer.new()
	reader.add_child(footer)
	_info = Label.new()
	_info.name = "EmailStatus"
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.theme_type_variation = &"Muted"
	footer.add_child(_info)
	_cancel = Button.new()
	_cancel.name = "CancelEmailDraft"
	_cancel.text = Prefs.t("Voltar")
	_cancel.pressed.connect(func() -> void: _open_thread(_previous_thread if not Mail.thread(ledger.state, _previous_thread).is_empty() else 0))
	footer.add_child(_cancel)
	_send = Button.new()
	_send.name = "SendEmail"
	_send.text = Prefs.t("Enviar")
	_send.tooltip_text = "Ctrl+Enter"
	_send.custom_minimum_size = Vector2(78, 33)
	_send.pressed.connect(_send_email)
	footer.add_child(_send)


func refresh() -> void:
	var mailbox: Dictionary = ledger.state.get("mail", {})
	if not is_same(_mailbox, mailbox):
		if not _mailbox.is_empty():
			_drafts.clear()
			_composing = false
			_send_error = ""
			_editor.clear()
			_subject.clear()
		_mailbox = mailbox
	if _thread_id != 0 and Mail.thread(ledger.state, _thread_id).is_empty(): _thread_id = 0
	_refresh_inbox()
	_refresh_reader()
	if not _composing and _thread_id != 0: _mark_open_read.call_deferred(_thread_id)


func _refresh_inbox() -> void:
	var entries: Array = Mail.threads(ledger.state).duplicate()
	entries.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var last_left: float = left.messages.back().at
		var last_right: float = right.messages.back().at
		return left.id > right.id if last_left == last_right else last_left > last_right)
	var unread := 0
	_thread_buttons.clear()
	for row in _threads.get_children():
		_threads.remove_child(row)
		row.queue_free()
	var query := Replies.normalize(_search.text)
	for entry in entries:
		if entry.unread: unread += 1
		if _filter.selected == 1 and not entry.unread: continue
		if _filter.selected == 2 and not entry.messages.any(func(message: Dictionary) -> bool: return message.from == "player"): continue
		var person := Mail.contact(ledger.state, entry.contact)
		if person.is_empty(): continue
		if not query.is_empty() and query not in Replies.normalize("%s %s %s" % [person.name, person.role, entry.subject]):
			if not entry.messages.any(func(message: Dictionary) -> bool: return query in Replies.normalize(message.text)): continue
		_add_thread_row(entry, person.name)
	_filter.set_item_text(1, Prefs.t("Não lidas") + " (%d)" % unread)
	if _thread_buttons.is_empty():
		var empty := Label.new()
		empty.text = Prefs.t("Nenhuma conversa encontrada.")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.theme_type_variation = &"Muted"
		_threads.add_child(empty)


func _add_thread_row(entry: Dictionary, sender: String) -> void:
	var id := int(entry.id)
	var button := Button.new()
	button.name = "EmailThread_%d" % id
	button.custom_minimum_size.y = 55
	button.theme_type_variation = &"LauncherButton"
	button.toggle_mode = true
	button.set_pressed_no_signal(id == _thread_id and not _composing)
	button.tooltip_text = "%s · %s" % [sender, entry.subject]
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_open_thread.bind(id))
	_threads.add_child(button)
	_thread_buttons[id] = button
	var labels := VBoxContainer.new()
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_theme_constant_override("separation", 2)
	button.add_child(labels)
	labels.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	labels.offset_left = 9
	labels.offset_right = -9
	labels.offset_top = 7
	labels.offset_bottom = -6
	var name_label := Label.new()
	name_label.text = "● " + sender if entry.unread else sender
	if entry.unread: name_label.add_theme_color_override("font_color", Color("8ed9ec"))
	name_label.clip_text = true
	labels.add_child(name_label)
	var subject := Label.new()
	subject.text = entry.subject
	subject.theme_type_variation = &"Muted"
	subject.clip_text = true
	subject.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	labels.add_child(subject)


func _refresh_reader() -> void:
	var entry := Mail.thread(ledger.state, _thread_id)
	var viewing := not _composing and not entry.is_empty()
	_recipient.visible = _composing
	_subject.visible = _composing
	_contact.visible = viewing
	_history_scroll.visible = not _composing
	_editor.visible = viewing or _composing
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL if _composing else Control.SIZE_FILL
	_send.visible = _editor.visible
	_cancel.visible = _composing
	_update_send()
	if _composing:
		_heading.text = Prefs.t("Novo email")
		_editor.placeholder_text = Prefs.t("Escreva sua mensagem…")
		return
	if viewing:
		_heading.text = entry.subject
		var person := Mail.contact(ledger.state, entry.contact)
		_contact.text = "%s · %s" % [person.name, person.role]
		_editor.placeholder_text = Prefs.t("Escreva sua resposta…")
		if _rendered_id == _thread_id and _rendered_messages == entry.messages.size() and is_same(_rendered_last, entry.messages.back()): return
		_show_history(entry, person.name)
	else:
		_heading.text = Prefs.t("Caixa de entrada")
		if _rendered_id == 0 and _history.get_child_count() > 0: return
		_clear_history()
		var empty := Label.new()
		empty.text = Prefs.t("Selecione uma conversa ou escreva para um contato da oficina.")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.theme_type_variation = &"Muted"
		_history.add_child(empty)
		_rendered_id = 0


func _show_history(entry: Dictionary, sender: String) -> void:
	_clear_history()
	for message in entry.messages:
		var sent: bool = message.from == "player"
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("173244") if sent else Color("122432")
		style.set_corner_radius_all(7)
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: style.set_content_margin(side, 10)
		panel.add_theme_stylebox_override("panel", style)
		_history.add_child(panel)
		var content := VBoxContainer.new()
		panel.add_child(content)
		var label := Label.new()
		var minutes := int(540.0 + float(message.at) / 6.0)
		label.text = "%s · %02d:%02d" % [Prefs.t("Você") if sent else sender, (minutes / 60) % 24, minutes % 60]
		label.theme_type_variation = &"Muted"
		content.add_child(label)
		var body := Label.new()
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.text = message.text
		content.add_child(body)
	_rendered_id = _thread_id
	_rendered_messages = entry.messages.size()
	_rendered_last = entry.messages.back()
	_scroll_to_end.call_deferred()


func _clear_history() -> void:
	for node in _history.get_children():
		_history.remove_child(node)
		node.queue_free()


func _scroll_to_end() -> void:
	_history_scroll.scroll_vertical = int(_history_scroll.get_v_scroll_bar().max_value)


func _compose() -> void:
	if _composing: return
	_save_draft()
	_previous_thread = _thread_id
	_thread_id = 0
	_composing = true
	_send_error = ""
	var previous_recipient: Variant = _recipient.get_selected_metadata() if _recipient.selected > 0 else null
	_recipient.clear()
	_recipient.add_item(Prefs.t("Para: escolha um contato"))
	var people := Mail.contacts(ledger.state)
	for id in people:
		var person: Dictionary = people[id]
		_recipient.add_item("%s · %s" % [person.name, person.role])
		_recipient.set_item_metadata(_recipient.item_count - 1, id)
		if id == previous_recipient: _recipient.select(_recipient.item_count - 1)
	_editor.text = _drafts.get(0, "")
	refresh()
	_recipient.grab_focus()


func _open_thread(id: int) -> void:
	if not _composing and _thread_id == id:
		if _thread_buttons.has(id): _thread_buttons[id].set_pressed_no_signal(true)
		_mark_open_read(id)
		return
	_save_draft()
	_thread_id = id
	_composing = false
	_send_error = ""
	_editor.text = _drafts.get(id, "")
	refresh()


func _save_draft() -> void:
	if _thread_id != 0 or _composing: _drafts[_thread_id] = _editor.text


func _mark_open_read(id: int) -> void:
	if id != _thread_id or _composing or desktop.active_app != "messages" or not is_visible_in_tree(): return
	Mail.read(ledger, id)


func _update_send() -> void:
	var length := _editor.text.strip_edges().length()
	var missing_contact: bool = _composing and (_recipient.selected <= 0 or _subject.text.strip_edges().is_empty())
	_send.disabled = length == 0 or length > Mail.MAX_BODY or missing_contact or (not _composing and _thread_id == 0)
	var entry := Mail.thread(ledger.state, _thread_id)
	var status := Prefs.t("Aguardando resposta…") if not entry.get("pending", []).is_empty() else ""
	if length > Mail.MAX_BODY: status = Prefs.t("Limite de %d caracteres.") % Mail.MAX_BODY
	if not _send_error.is_empty(): status = _send_error
	_info.text = status


func _send_email() -> void:
	if _send.disabled: return
	var recipient: String = _recipient.get_selected_metadata() if _composing else ""
	var result := Mail.send(ledger, recipient, _subject.text, _editor.text, _thread_id)
	if result.has("error"):
		_send_error = Prefs.t(result.error)
		_update_send()
		return
	_drafts.erase(_thread_id)
	if _composing: _subject.clear()
	_thread_id = int(result.id)
	_composing = false
	_send_error = ""
	_editor.clear()
	_search.clear()
	_filter.select(0)
	refresh()
	_editor.grab_focus()


func _editor_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_editor.accept_event()
		_send_email()

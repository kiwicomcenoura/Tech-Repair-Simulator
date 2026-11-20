extends SceneTree

const Fixture := preload("res://Tools/test_world.gd")
const Mail := preload("res://Scripts/Gameplay/workshop_mail.gd")
const Orders := preload("res://Scripts/Gameplay/service_orders.gd")
const Prefs := preload("res://Scripts/UI/player_preferences.gd")

var checks := 0
var failures := 0
var save_path := "res://.godot/mail-test-%d.json" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)


func _frames() -> void:
	for i in range(3): await process_frame


func _click(button: Control) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames()


func _key(code: Key, character: int = 0, ctrl: bool = false) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.unicode = character
		event.ctrl_pressed = ctrl
		event.pressed = pressed
		Input.parse_input_event(event)


func _choose(list: OptionButton, value: Variant) -> void:
	for index in range(list.item_count):
		if list.get_item_metadata(index) != value: continue
		list.select(index)
		list.item_selected.emit(index)
		return


func _run() -> void:
	root.size = Vector2i(1360, 768)
	var world := Fixture.create()
	root.add_child(world)
	await _frames()
	var workshop := world.get_node("PhysicalWorkshop")
	var ledger: RefCounted = workshop.ledger
	check(ledger.valid(ledger.state), "Initial mailbox with real customer orders validates")
	var offer: Dictionary = Orders.orders(ledger, "offered")[0]
	var mail_threads := Mail.threads(ledger.state)
	check(mail_threads.size() == 4 and mail_threads[0].contact == "bia", "Welcome and three work orders generate incoming mail")
	var customer: Dictionary = mail_threads.filter(func(entry: Dictionary) -> bool: return entry.contact == "order:" + offer.id)[0]
	check(customer.unread and customer.messages[0].text.contains(offer.report), "Customer email contains the real service report")
	check(Mail.send(ledger, "invalid", "Subject", "Body").has("error"), "Unknown recipient is rejected")
	check(Mail.send(ledger, "leo", "Subject", " ").has("error"), "Empty messages are rejected")
	check(Mail.send(ledger, "leo", "Subject", "x".repeat(Mail.MAX_BODY + 1)).has("error"), "The character limit applies to saved mail")

	var personal := world.get_node("PersonalComputerUI")
	personal.computer.boot_duration = 0.05
	personal.open_computer()
	await _frames()
	await _click(personal.get_node("%PowerToggle"))
	await create_timer(0.2, true).timeout
	var desktop: Control = personal.get_node("%DesktopScreen")
	await _click(desktop.launchers.messages)
	var window: Control = desktop.windows.messages
	var app: Control = window.find_child("WorkshopEmail", true, false)
	check(app._thread_buttons.size() == 4, "The TechOS shortcut opens a populated inbox")
	await _click(app.find_child("NewEmail", true, false))
	var recipient: OptionButton = app.find_child("EmailRecipient", true, false)
	_choose(recipient, "leo")
	var subject: LineEdit = app.find_child("EmailSubject", true, false)
	subject.text = "Dúvida sobre armazenamento"
	var body: TextEdit = app.find_child("EmailBody", true, false)
	body.grab_focus()
	for character in "Qual é o preço do SSD 480 GB?":
		_key(KEY_NONE, character.unicode_at(0))
	await _frames()
	check(body.text == "Qual é o preço do SSD 480 GB?", "The player can type accented free text in the real editor")
	_key(KEY_ENTER, 0, true)
	await _frames()
	var id: int = app._thread_id
	var entry := Mail.thread(ledger.state, id)
	check(not entry.is_empty() and entry.contact == "leo" and entry.messages.size() == 1, "Ctrl+Enter sends a new conversation to Léo")
	if entry.is_empty():
		world.queue_free()
		quit(1)
		return
	check("Aguardando" in app.find_child("EmailStatus", true, false).text, "The sent message stays visible while a reply is pending")
	body.text = "E em quanto tempo chega?"
	body.text_changed.emit()
	await _click(app.find_child("SendEmail", true, false))
	check(entry.pending.size() == 2, "A second email queues its own reply instead of replacing the first")
	workshop.save_path = save_path
	check(workshop.save_game(false) and workshop.load_game(), "A save restores queued replies through the real workshop loader")
	entry = Mail.thread(ledger.state, id)
	check(entry.pending.size() == 2 and entry.messages.size() == 2, "Pending replies and exact outgoing messages survive loading")
	ledger.tick(6.0)
	check(entry.messages.size() == 4 and not entry.has("pending") and entry.unread, "The contact replies twice while the computer UI is closed")
	check("480 GB" in entry.messages[2].text and Prefs.money(145) in entry.messages[2].text, "Quotation uses the actual catalog model and price")
	check("480 GB" in entry.messages[3].text and "três segundos" in entry.messages[3].text, "Follow-up about timing remembers the product")
	check(ledger.valid(ledger.state), "The completed exchange validates as saved game data")
	personal.open_computer()
	await _frames()
	var search: LineEdit = app.find_child("SearchEmail", true, false)
	search.text = "LEO"
	search.text_changed.emit(search.text)
	check(app._thread_buttons.size() == 1 and app._thread_buttons.has(id), "Search matches contacts without accents")
	await _frames()
	await _click(app._thread_buttons[id])
	await _frames()
	check(not entry.unread and app.find_child("EmailHistory", true, false).get_child_count() == 4, "Opening the thread marks it read and displays the full exchange")
	search.text = "três segundos"
	search.text_changed.emit(search.text)
	check(app._thread_buttons.size() == 1, "Search also finds words inside a reply")
	personal.close_computer()

	check(Orders.accept(ledger, offer.id), "Accept the real service order")
	var followup := Mail.send(ledger, "", "", "Quando posso retirar o computador?", int(customer.id))
	ledger.tick(5.0)
	var thread := Mail.thread(ledger.state, followup.get("id", 0))
	check(not thread.is_empty() and "já está com a oficina" in thread.messages.back().text, "The same customer reacts to the live order status")
	Orders.tick(ledger, 46.0)
	check(Mail.threads(ledger.state).size() == 6, "The next service offer sends a new email to the inbox")

	var support := Mail.send(ledger, "bia", "Montagem", "O Intara i5 9400F é compatível com a H110M?")
	ledger.tick(3.2)
	var support_thread := Mail.thread(ledger.state, support.get("id", 0))
	check(not support_thread.is_empty() and "incompatível" in support_thread.messages.back().text, "Technician checks the actual motherboard generation")
	var clarification := Mail.send(ledger, "bia", "Outra montagem", "O i5 9400F serve nesta placa?")
	ledger.tick(3.2)
	var clarification_id: int = clarification.get("id", 0)
	Mail.send(ledger, "", "", "É uma B360M.", clarification_id)
	ledger.tick(3.2)
	check("são compatíveis" in Mail.thread(ledger.state, clarification_id).messages.back().text, "Naming the motherboard later answers the technician's question in context")
	var invalid: Dictionary = ledger.state.duplicate(true)
	invalid.mail.threads[1].id = invalid.mail.threads[0].id
	check(not ledger.valid(invalid), "The save validator rejects duplicate email identities")
	check(ledger.valid(ledger.state), "Mailbox remains valid after service updates and more replies")

	workshop.save_path = ""
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(save_path + suffix): DirAccess.remove_absolute(save_path + suffix)
	world.queue_free()
	await _frames()
	print("WORKSHOP EMAIL CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)

extends RefCounted
## Local mailbox for the office computer. Its clock and queued replies survive a load.

const Replies := preload("res://Scripts/Gameplay/mail_replies.gd")
const MAX_SUBJECT := 100
const MAX_BODY := 1600
const CONTACTS := {
	"bia": {"name": "Bia Moraes", "role": "Técnica de bancada", "delay": 3.0},
	"leo": {"name": "Léo Takahashi", "role": "Atendimento da TechMarket", "delay": 4.0},
	"clara": {"name": "Clara Nunes", "role": "Cliente da oficina", "delay": 5.0},
}


static func initialize(state: Dictionary) -> void:
	if state.has("mail"): return
	state.mail = {"clock": 0.0, "serial": 0, "threads": []}
	var welcome := _new_thread(state.mail, "bia", "Bem-vindo à bancada")
	_receive(state.mail, welcome, "Oi! Sou a Bia, da bancada. Se alguma montagem emperrar, pode me escrever por aqui. Me conta o que você está tentando montar e o que aconteceu no teste.")
	sync_orders(state)


static func contacts(state: Dictionary) -> Dictionary:
	var result := CONTACTS.duplicate()
	for order in state.get("services", {}).get("orders", []):
		result["order:" + order.id] = _order_contact(order)
	return result


static func contact(state: Dictionary, id: String) -> Dictionary:
	if CONTACTS.has(id): return CONTACTS[id]
	if not id.begins_with("order:"): return {}
	for order in state.get("services", {}).get("orders", []):
		if id == "order:" + order.id: return _order_contact(order)
	return {}


static func _order_contact(order: Dictionary) -> Dictionary:
	return {"name": order.client, "role": order.id, "order": order, "delay": 4.0}


static func threads(state: Dictionary) -> Array:
	return state.get("mail", {}).get("threads", [])


static func thread(state: Dictionary, id: int) -> Dictionary:
	for entry in threads(state):
		if entry.id == id: return entry
	return {}


static func send(ledger: RefCounted, recipient: String, subject: String, body: String, thread_id: int = 0) -> Dictionary:
	subject = subject.strip_edges()
	body = body.strip_edges()
	var existing := thread(ledger.state, thread_id)
	if thread_id != 0 and existing.is_empty(): return {"error": "A conversa não está mais disponível."}
	if not existing.is_empty():
		recipient = existing.contact
		subject = existing.subject
	var person := contact(ledger.state, recipient)
	if person.is_empty(): return {"error": "Escolha um contato."}
	if subject.is_empty() or subject.length() > MAX_SUBJECT: return {"error": "Escreva um assunto de até %d caracteres." % MAX_SUBJECT}
	if body.is_empty() or body.length() > MAX_BODY: return {"error": "Escreva uma mensagem de até %d caracteres." % MAX_BODY}
	initialize(ledger.state)
	var box: Dictionary = ledger.state.mail
	if existing.is_empty(): existing = _new_thread(box, recipient, subject)
	existing.messages.append({"from": "player", "text": body, "at": box.clock})
	var pending: Array = existing.get("pending", [])
	var due: float = box.clock + person.delay
	if not pending.is_empty(): due = maxf(due, float(pending.back().at) + 0.65)
	pending.append({"index": existing.messages.size() - 1, "at": due})
	existing.pending = pending
	ledger.mail_changed.emit()
	return {"id": int(existing.id)}


static func read(ledger: RefCounted, id: int) -> void:
	var entry := thread(ledger.state, id)
	if not entry.get("unread", false): return
	entry.unread = false
	ledger.mail_changed.emit()


static func tick(ledger: RefCounted, delta: float) -> void:
	if not ledger.state.has("mail"): return
	var box: Dictionary = ledger.state.mail
	box.clock += maxf(delta, 0.0)
	var received := false
	for entry in box.threads:
		var pending: Array = entry.get("pending", [])
		if pending.is_empty(): continue
		var person := contact(ledger.state, entry.contact)
		while not pending.is_empty() and float(pending.front().at) <= float(box.clock):
			var reply: Dictionary = pending.pop_front()
			if not person.is_empty():
				_receive(box, entry, Replies.answer(ledger, entry, person, int(reply.index)))
				received = true
		if pending.is_empty(): entry.erase("pending")
	if received: ledger.mail_changed.emit()


static func sync_orders(state: Dictionary) -> bool:
	if not state.has("mail"): return false
	var box: Dictionary = state.mail
	var discussions := {}
	for entry in box.threads:
		if entry.has("order_status"): discussions[entry.contact] = entry
	var changed := false
	for order in state.get("services", {}).get("orders", []):
		var key: String = "order:" + order.id
		var entry: Dictionary = discussions.get(key, {})
		if entry.is_empty():
			if order.status not in ["offered", "active"]: continue
			entry = _new_thread(box, key, "%s · %s" % [order.id, order.title])
			_receive(box, entry, "Oi, aqui é %s. %s\n\nSe precisar de mais detalhes sobre o computador, pode me responder por aqui." % [order.client, order.report])
		elif entry.order_status == order.status:
			continue
		elif order.status == "delivered":
			_receive(box, entry, "Passei no balcão e estou com o computador de volta. Obrigado pelo atendimento! Se precisar falar comigo sobre o serviço, pode usar esta conversa.")
		entry.order_status = order.status
		changed = true
	return changed


static func _new_thread(box: Dictionary, recipient: String, subject: String) -> Dictionary:
	box.serial = int(box.serial) + 1
	var entry := {"id": box.serial, "contact": recipient, "subject": subject.left(MAX_SUBJECT), "messages": [], "unread": false}
	box.threads.append(entry)
	return entry


static func _receive(box: Dictionary, entry: Dictionary, text: String) -> void:
	entry.messages.append({"from": "contact", "text": text.left(MAX_BODY), "at": box.clock})
	entry.unread = true


static func valid(state: Dictionary) -> bool:
	if not state.has("mail"): return true
	var box: Variant = state.mail
	if not box is Dictionary or not _time(box.get("clock")) or not box.get("threads") is Array: return false
	if not _time(box.get("serial")) or int(box.serial) != box.serial: return false
	var people := contacts(state)
	var ids := {}
	var order_threads := {}
	for entry in box.threads:
		if not entry is Dictionary or not _time(entry.get("id")) or int(entry.id) != entry.id: return false
		var id := int(entry.id)
		if id <= 0 or id > box.serial or ids.has(id): return false
		ids[id] = true
		if not entry.get("contact") is String or not people.has(entry.contact): return false
		if not _text(entry.get("subject"), MAX_SUBJECT) or not entry.get("unread") is bool: return false
		if not entry.get("messages") is Array or entry.messages.is_empty(): return false
		var previous := 0.0
		for message in entry.messages:
			if not message is Dictionary or message.get("from") not in ["player", "contact"]: return false
			if not _text(message.get("text"), MAX_BODY) or not _time(message.get("at")): return false
			if message.at < previous or message.at > box.clock: return false
			previous = message.at
		var pending: Variant = entry.get("pending", [])
		if not pending is Array: return false
		var previous_index := -1
		var previous_due := 0.0
		for reply in pending:
			if not reply is Dictionary or not _time(reply.get("index")) or int(reply.index) != reply.index: return false
			var index := int(reply.index)
			if index <= previous_index or index >= entry.messages.size() or entry.messages[index].from != "player": return false
			if not _time(reply.get("at")) or reply.at < previous_due or reply.at < entry.messages[index].at: return false
			previous_index = index
			previous_due = reply.at
		if entry.has("order_status"):
			if not people[entry.contact].has("order") or order_threads.has(entry.contact): return false
			if entry.order_status not in ["offered", "active", "declined", "delivered"]: return false
			order_threads[entry.contact] = true
	return true


static func _time(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0


static func _text(value: Variant, limit: int) -> bool:
	return value is String and not value.strip_edges().is_empty() and value.length() <= limit

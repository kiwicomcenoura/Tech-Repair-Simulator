extends RefCounted

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
## Customer jobs share the physical ledger; accepting never repairs a machine.

const MAX_ACTIVE := 3
const GPU_ARTIFACT_REPORT := "Aparecem blocos coloridos na tela e a imagem some por instantes."
const FIRST_NAMES := ["Ana", "Bruno", "Camila", "Diego", "Elisa", "Felipe", "Gabriela", "Henrique", "Iara", "João", "Lívia", "Marcos", "Nina", "Otávio", "Paula", "Rafael", "Sofia", "Tiago", "Valéria", "Caio"]
const SURNAMES := ["Almeida", "Barbosa", "Costa", "Dias", "Freitas", "Gomes", "Lima", "Mendes", "Oliveira", "Ribeiro", "Santos", "Teixeira"]
const CONTEXTS := ["Uso este computador para trabalhar em casa.", "É o computador dos meus estudos.", "Uso a máquina para editar meus projetos.", "É o computador da minha pequena loja.", "Gosto de jogar nas horas vagas.", "Minha família usa este computador todos os dias."]
const JOBS := {
	"ram": {"title": "Corrigir erros de memória", "parts": ["ram"], "cost": 150, "labor": 110, "reports": ["O computador trava e mostra telas de erro quando abro vários programas.", "Meus aplicativos fecham sozinhos e às vezes o computador não inicia.", "Começaram a aparecer erros de memória e reinicializações inesperadas."]},
	"psu": {"title": "Restabelecer a alimentação", "parts": ["psu"], "cost": 160, "labor": 130, "reports": ["Aperto o botão e a máquina não dá sinal de vida.", "Depois de uma queda de energia, o computador parou de ligar.", "O computador desligou durante o uso e não ligou mais."]},
	"gpu": {"title": "Recuperar a saída de vídeo", "parts": ["gpu"], "cost": 250, "labor": 150, "reports": ["O monitor fica sem imagem, mesmo com o computador ligado.", GPU_ARTIFACT_REPORT, "Já testei outro monitor, mas continuo sem vídeo."]},
	"cooling": {"title": "Trocar a refrigeração defeituosa", "parts": ["cooling"], "cost": 80, "labor": 100, "reports": ["A ventoinha do processador parou de funcionar.", "O cooler faz muito barulho e a máquina desliga.", "A refrigeração começou a falhar; preciso voltar a usar o computador."]},
	"upgrade": {"title": "Ampliar a memória para 16 GB", "parts": ["ram2"], "cost": 150, "labor": 100, "reports": ["Quero mais memória para abrir vários programas: instale um segundo módulo de 8 GB DDR4.", "Preciso de 16 GB de RAM no total, mantendo meu módulo atual de 8 GB.", "Adicione mais 8 GB DDR4 no segundo slot para melhorar minha rotina."]},
	"diagnosis": {"title": "Revisão e diagnóstico completo", "parts": [], "cost": 0, "labor": 140, "reports": ["Comprei este computador usado. Quero conferir todos os componentes antes de usá-lo.", "Vou passar o computador para outra pessoa e preciso de uma revisão completa.", "A máquina está funcionando, mas quero uma verificação de todas as peças."]},
	"ram_gpu": {"title": "Resolver falhas de vídeo e memória", "parts": ["ram", "gpu"], "cost": 400, "labor": 210, "reports": ["Além de não dar vídeo, a máquina já apresentava erros de memória.", "O computador perdeu a imagem; antes disso, também travava com erros de RAM.", "Preciso corrigir dois problemas: falhas de vídeo e de memória."]}
}

static func ensure(ledger: RefCounted) -> void:
	if ledger.state.has("services"): return
	ledger.state.services = {"orders": [], "bag": [], "serial": 0, "arrival": 45.0, "last_kind": ""}
	for i in range(3): _offer(ledger)

static func orders(ledger: RefCounted, status: String = "") -> Array:
	ensure(ledger)
	var result: Array = []
	for order in ledger.state.services.orders:
		if status.is_empty() or order.status == status: result.append(order)
	return result

static func get_order(ledger: RefCounted, id: String) -> Dictionary:
	for order in orders(ledger):
		if order.id == id: return order
	return {}

static func localized_report(order: Dictionary) -> String:
	var report: String = order.report
	for context in CONTEXTS:
		if report.ends_with(" " + context):
			return Prefs.t(report.trim_suffix(" " + context)) + " " + Prefs.t(context)
	return Prefs.t(report)

static func _offer(ledger: RefCounted) -> void:
	var service: Dictionary = ledger.state.services
	if service.bag.is_empty():
		service.bag = JOBS.keys()
		service.bag.shuffle()
		if service.bag.back() == service.last_kind:
			var first: Variant = service.bag[0]
			service.bag[0] = service.bag[-1]
			service.bag[-1] = first
	var kind: String = service.bag.pop_back()
	service.last_kind = kind
	service.serial += 1
	var client := ""
	for attempt in range(30):
		client = FIRST_NAMES.pick_random() + " " + SURNAMES.pick_random()
		var duplicate := false
		for order in service.orders:
			if order.client == client and order.status in ["offered", "active"]: duplicate = true
		if not duplicate: break
	var job: Dictionary = JOBS[kind]
	var labor: int = job.labor + randi_range(0, 4)*10
	service.orders.append({"id": "OS-%04d" % service.serial, "client": client, "kind": kind, "title": job.title, "report": job.reports.pick_random()+" "+CONTEXTS.pick_random(), "status": "offered", "pc_id": "", "deposit": job.cost, "reward": job.cost+labor, "priority": service.serial, "originals": {}})

static func tick(ledger: RefCounted, delta: float) -> void:
	ensure(ledger)
	if orders(ledger, "offered").size() >= 3: return
	ledger.state.services.arrival = maxf(0, float(ledger.state.services.arrival)-delta)
	if ledger.state.services.arrival == 0:
		_offer(ledger)
		ledger.state.services.arrival = 45.0
		ledger.done("Novo cliente: uma proposta chegou ao balcão de atendimento.")

static func accept(ledger: RefCounted, id: String) -> bool:
	var order := get_order(ledger, id)
	if order.get("status") != "offered": return ledger.fail("Esta proposta não está disponível.")
	if orders(ledger, "active").size() >= MAX_ACTIVE: return ledger.fail("Conclua um serviço: a fila aceita até três pedidos ativos.")
	var occupied: Array = []
	for waiting in ledger.at("counter"): occupied.append(int(ledger.item(waiting).counter_slot))
	var slot := 0
	while slot in occupied: slot += 1
	if slot >= ledger.COUNTER_CAPACITY: return ledger.fail("Libere espaço no balcão de atendimento.")
	# Reuse the real computer schema, but allocate fresh IDs for every unit.
	var fixture: RefCounted = ledger.get_script().new()
	fixture.new_game(true)
	var pc: Dictionary
	for record in fixture.state.items.values():
		if record.kind == "pc": pc = record.duplicate(true)
	pc.id = ledger.uid()
	pc.model = "%s · %s · Desktop DDR4" % [order.id, order.client]
	pc.location = "counter"
	pc.counter_slot = slot
	pc.components = {}
	pc.service_order = order.id
	ledger.state.items[pc.id] = pc
	for record in fixture.state.items.values():
		if record.location != "installed": continue
		var part: Dictionary = record.duplicate(true)
		part.id = ledger.uid()
		part.owner_pc = pc.id
		part.health = randi_range(85, 100)
		part.defects = []
		if record.kind in JOBS[order.kind].parts:
			part.health = randi_range(2, 10)
			part.defects = ["Falha persistente confirmada no componente"]
			if record.kind == "gpu" and order.kind == "gpu" and order.report.begins_with(GPU_ARTIFACT_REPORT):
				part.health = randi_range(30, 55)
				part.defects = ["Artefatos gráficos e perdas intermitentes de sinal"]
		ledger.state.items[part.id] = part
		pc.components[part.kind] = part.id
	order.originals = pc.components.duplicate()
	order.pc_id = pc.id
	order.status = "active"
	ledger.state.credits += int(order.deposit)
	return ledger.done(Prefs.t("%s recebido. Gabinete no balcão; adiantamento de %s para peças.") % [order.id, Prefs.money(order.deposit)], "delivery")

static func decline(ledger: RefCounted, id: String) -> bool:
	var order := get_order(ledger, id)
	if order.get("status") != "offered": return ledger.fail("Somente propostas podem ser recusadas.")
	order.status = "declined"
	return ledger.done("Proposta recusada. Outro cliente poderá chegar em breve.")

static func prioritize(ledger: RefCounted, id: String) -> bool:
	var order := get_order(ledger, id)
	if order.get("status") != "active": return false
	var priority := 0
	for active in orders(ledger, "active"): priority = mini(priority, int(active.priority))
	order.priority = priority - 1
	return ledger.done(Prefs.t("%s movido para o início da fila.") % id)

static func signature(ledger: RefCounted, pc: Dictionary) -> String:
	var parts: Array = []
	var keys: Array = pc.components.keys()
	keys.sort()
	for key in keys:
		var part: Dictionary = ledger.item(pc.components[key])
		parts.append([key, part.get("id"), part.get("health")])
		# Materialize default mounts before taking evidence, so opening a test
		# panel later cannot invalidate a successful POST by lazy initialization.
		if key != "ram2": ledger.mounts(pc.id, key)
	return JSON.stringify([parts, pc.get("mounts", {}), pc.latches, pc.get("ram2_latches", [true, true])])

static func requirements(ledger: RefCounted, order: Dictionary) -> Array:
	var result: Array = []
	var pc: Dictionary = ledger.item(order.get("pc_id", ""))
	if pc.is_empty(): return result
	var job: Dictionary = JOBS[order.kind]
	for key in job.parts:
		var part: Dictionary = ledger.item(pc.components.get(key, ""))
		var label: String = Prefs.t("Segundo módulo de 8 GB DDR4") if key == "ram2" else Prefs.t("Substituir %s") % Prefs.t(ledger.PART_NAMES[key]).to_lower()
		var good: bool = not part.is_empty() and int(part.health) >= 70 and part.defects.is_empty() and part.id != order.originals.get(key, "")
		if key == "ram2": good = good and part.get("ddr") == "DDR4" and part.get("capacity_gb", 8) == 8
		result.append({"text": label, "ok": good})
		result.append({"text": Prefs.t("Testar %s") % Prefs.t("a memória instalada" if key in ["ram", "ram2"] else ledger.PART_NAMES[key]).to_lower(), "ok": part.get("tested", false) and good})
	if order.kind == "diagnosis":
		for key in ledger.PART_NAMES:
			result.append({"text": Prefs.t("Verificar %s") % Prefs.t(ledger.PART_NAMES[key]).to_lower(), "ok": ledger.item(pc.components.get(key, "")).get("tested", false)})
	if order.kind == "upgrade":
		result.append({"text": "Manter o módulo original no primeiro slot", "ok": pc.components.get("ram") == order.originals.get("ram")})
	result.append({"text": "Inicialização aprovada após o serviço", "ok": pc.get("service_post", "") == signature(ledger, pc) and ledger.evaluate_boot(pc.id).begins_with("POST concluído. Sistema")})
	result.append({"text": "Desligar e fechar o gabinete com os quatro parafusos", "ok": not pc.power and pc.lid and not false in pc.screws})
	result.append({"text": "Trazer o gabinete correto nas mãos ao balcão", "ok": ledger.carried() == pc.id})
	return result

static func deliver(ledger: RefCounted, id: String) -> bool:
	var order := get_order(ledger, id)
	if order.get("status") != "active": return ledger.fail("Este pedido não está em andamento.")
	for requirement in requirements(ledger, order):
		if not requirement.ok: return ledger.fail(Prefs.t("Entrega pendente: %s.") % Prefs.t(requirement.text))
	var pc: Dictionary = ledger.item(order.pc_id)
	pc.location = "returned"
	order.status = "delivered"
	ledger.state.credits += int(order.reward) - int(order.deposit)
	return ledger.done(Prefs.t("%s entregue a %s! Recebidos %s restantes.") % [order.id, order.client, Prefs.money(order.reward-order.deposit)], "purchase")

static func earnings(candidate: Dictionary) -> int:
	var total := 0
	for order in candidate.get("services", {}).get("orders", []):
		if order.status == "active": total += int(order.deposit)
		elif order.status == "delivered": total += int(order.reward)
	return total

static func valid(candidate: Dictionary) -> bool:
	if not candidate.has("services"):
		for record in candidate.items.values():
			if record.get("location") == "returned": return false
		return true
	var service: Variant = candidate.services
	if not service is Dictionary or not service.get("orders") is Array or not service.get("bag") is Array: return false
	if not service.get("serial") is int and not service.get("serial") is float: return false
	if not service.get("arrival") is int and not service.get("arrival") is float: return false
	if not is_finite(float(service.arrival)) or service.arrival < 0 or service.arrival > 45: return false
	if not service.get("last_kind") is String: return false
	if service.last_kind != "" and not JOBS.has(service.last_kind): return false
	if int(service.serial) != service.serial or service.serial < service.orders.size(): return false
	var seen: Dictionary = {}
	var computers: Dictionary = {}
	var active := 0
	var offers := 0
	var bag_kinds: Array = []
	for kind in service.bag:
		if not kind is String or not JOBS.has(kind): return false
		if kind in bag_kinds: return false
		bag_kinds.append(kind)
	for order in service.orders:
		if not order is Dictionary or not order.get("id") is String or seen.has(order.id): return false
		seen[order.id] = true
		if not JOBS.has(order.get("kind", "")) or order.get("status") not in ["offered", "active", "delivered", "declined"]: return false
		for field in ["client", "title", "report", "pc_id"]:
			if not order.get(field) is String: return false
		for field in ["deposit", "reward", "priority"]:
			if not (order.get(field) is int or order.get(field) is float) or not is_finite(float(order[field])) or order[field] != int(order[field]): return false
		if order.deposit != JOBS[order.kind].cost or order.reward < order.deposit+JOBS[order.kind].labor or order.reward > order.deposit+JOBS[order.kind].labor+40: return false
		if not order.get("originals") is Dictionary: return false
		for key in order.originals:
			if key not in ["cpu", "motherboard", "ram", "gpu", "storage", "psu", "cooling"]: return false
			var original: Variant = candidate.items.get(order.originals[key])
			if not original is Dictionary or original.get("kind") != key: return false
		if order.status in ["active", "delivered"]:
			var pc: Variant = candidate.items.get(order.pc_id)
			if not pc is Dictionary or pc.get("kind") != "pc" or pc.get("service_order") != order.id or computers.has(order.pc_id): return false
			computers[order.pc_id] = true
			if order.originals.size() != 7: return false
			if (order.status == "delivered") != (pc.location == "returned"): return false
			if order.status == "active": active += 1
		elif not order.pc_id.is_empty(): return false
		if order.status == "offered": offers += 1
	for record in candidate.items.values():
		if record.get("location") == "returned" and not computers.has(record.id): return false
	return active <= MAX_ACTIVE and offers <= 3

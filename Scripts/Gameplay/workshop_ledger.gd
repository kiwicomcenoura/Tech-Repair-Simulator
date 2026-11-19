extends RefCounted
## Single authoritative registry: one record and one location for every unit ID.
## Scene actors, inventory rows and equipment Resources are derived views.

signal changed
signal feedback(text: String, failed: bool)

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const Audio := preload("res://Scripts/Gameplay/workshop_audio.gd")
const Orders := preload("res://Scripts/Gameplay/service_orders.gd")
const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
const PHYSICAL_LOCATIONS := ["floor", "carried", "shelf", "tray", "bench", "counter", "delivery", "installed", "inventory", "returned", "sold"]
const SELLABLE_LOCATIONS := ["floor", "carried", "shelf", "tray", "bench", "inventory"]
const RESALE_CENTS_PER_CREDIT := 90
const COUNTER_CAPACITY := 3
const SHELF_CAPACITY := 9
const SHELF_EXPANSIONS := [
	{"id": "shelf_15", "capacity": 15, "deliveries": Orders.INTERMEDIATE_DELIVERIES, "price": 350},
	{"id": "shelf_24", "capacity": 24, "deliveries": Orders.ADVANCED_DELIVERIES, "price": 600},
]
const INVENTORY_CAPACITY := 3
const PART_NAMES := {"cpu": "Processador", "cooling": "Refrigeração", "motherboard": "Placa-mãe", "ram": "Memória RAM", "gpu": "Placa de vídeo", "storage": "Armazenamento", "psu": "Fonte"}
const ESSENTIAL_PARTS := ["motherboard", "cpu", "psu", "cooling", "gpu", "storage"]
const FASTENERS := {"cpu": 0, "ram": 0, "gpu": 2, "storage": 4, "psu": 4, "cooling": 4, "motherboard": 6}
const CONNECTIONS := {"cpu": ["socket"], "ram": [], "gpu": ["energia", "trava PCIe"], "storage": ["SATA dados", "SATA energia"], "psu": ["chicote de energia"], "cooling": ["CPU FAN"], "motherboard": ["ATX 24 pinos", "EPS CPU", "painel frontal"]}
const HEAT_SPREADERS := {"Preto": Color("313943"), "Branco": Color("c9d0d8"), "Azul": Color("2865b0"), "Vermelho": Color("aa333a")}
const RYVON_3_MODEL := "Amdera Ryvon 3 3200"
const RYVON_5_MODEL := "Amdera Ryvon 5 5600"
const RYVON_7_MODEL := "Amdera Ryvon 7 7800"
const COREN_I3_MODEL := "Intara Coren i3 6100"
const COREN_I5_MODEL := "Intara Coren i5 9400"
const COREN_I7_MODEL := "Intara Coren i7 12700"
const CPU_MODEL_UPDATES := {
	"Amdera Ryvon 5 · 6 núcleos": RYVON_5_MODEL,
	"Amdera Ryvon 7 · 8 núcleos": RYVON_7_MODEL,
	"Intara Coren i3 · 4 núcleos": COREN_I3_MODEL,
	"Intara Coren i5 · 10 núcleos": COREN_I5_MODEL,
	"Amdera Ryvon 3 5300": RYVON_3_MODEL,
	"Amdera Ryvon 5 5500": RYVON_5_MODEL,
	"Amdera Ryvon 7 5700": RYVON_7_MODEL,
	"Intara Coren i3 12100": COREN_I3_MODEL,
	"Intara Coren i5 13400": COREN_I5_MODEL,
	"Intara Coren i7 13700": COREN_I7_MODEL,
}
const CATALOG := [
	{"key": "DDR4", "kind": "ram", "model": "TR Memory 8 GB DDR4", "price": 150, "ddr": "DDR4"},
	{"key": "DDR5", "kind": "ram", "model": "TR Memory 8 GB DDR5", "price": 180, "ddr": "DDR5"},
	{"key": "gpu", "kind": "gpu", "model": "TR Vision 2 · PCIe", "price": 250},
	{"key": "storage", "kind": "storage", "model": "TR SATA 240 GB · sem sistema", "price": 100},
	{"key": "psu", "kind": "psu", "model": "TR Power 450 W · ATX", "price": 160},
	{"key": "cooling", "kind": "cooling", "model": "TR Air 90 · 90 mm", "price": 80, "socket": "TR4", "alternate_socket": "AX4"},
	{"key": "amdera_ax550", "kind": "motherboard", "model": "Amdera AX550 · ATX", "price": 290, "socket": "AX4", "ddr": "DDR4", "board_art": "amdera", "board_format": "ATX"},
	{"key": "intara_ix610", "kind": "motherboard", "model": "Intara IX610 · micro-ATX", "price": 310, "socket": "IX1700", "ddr": "DDR5", "board_art": "intara", "board_format": "micro-ATX"},
	{"key": "amdera_ryvon_3", "kind": "cpu", "model": RYVON_3_MODEL, "price": 185, "socket": "AX4"},
	{"key": "amdera_ryvon_5", "kind": "cpu", "model": RYVON_5_MODEL, "price": 250, "socket": "AX4"},
	{"key": "amdera_ryvon_7", "kind": "cpu", "model": RYVON_7_MODEL, "price": 380, "socket": "AX4"},
	{"key": "intara_coren_i3", "kind": "cpu", "model": COREN_I3_MODEL, "price": 210, "socket": "IX1700"},
	{"key": "intara_coren_i5", "kind": "cpu", "model": COREN_I5_MODEL, "price": 340, "socket": "IX1700"},
	{"key": "intara_coren_i7", "kind": "cpu", "model": COREN_I7_MODEL, "price": 460, "socket": "IX1700"},
	{"key": "ddr4_16", "kind": "ram", "model": "TR Memory 16 GB DDR4", "price": 205, "ddr": "DDR4", "capacity_gb": 16, "heat_spreader": true},
	{"key": "ddr4_32", "kind": "ram", "model": "TR Memory 32 GB DDR4", "price": 295, "ddr": "DDR4", "capacity_gb": 32, "heat_spreader": true},
	{"key": "ddr5_16", "kind": "ram", "model": "TR Memory 16 GB DDR5", "price": 245, "ddr": "DDR5", "capacity_gb": 16, "heat_spreader": true},
	{"key": "ddr5_32", "kind": "ram", "model": "TR Memory 32 GB DDR5", "price": 345, "ddr": "DDR5", "capacity_gb": 32, "heat_spreader": true},
	{"key": "amdera_frost_120", "kind": "cooling", "model": "Amdera Frost 120 · 120 mm", "price": 125, "socket": "AX4"},
	{"key": "intara_breeze_92", "kind": "cooling", "model": "Intara Breeze 92 · 92 mm", "price": 90, "socket": "IX1700"},
	{"key": "intara_breeze_120", "kind": "cooling", "model": "Intara Breeze 120 · 120 mm", "price": 140, "socket": "IX1700"},
	{"key": "ssd_480", "kind": "storage", "model": "TR SSD SATA 480 GB · sem sistema", "price": 145},
	{"key": "ssd_960", "kind": "storage", "model": "TR SSD SATA 960 GB · sem sistema", "price": 215},
	{"key": "psu_550", "kind": "psu", "model": "TR Power 550 W · ATX", "price": 210},
	{"key": "psu_650", "kind": "psu", "model": "TR Power 650 W · ATX", "price": 270}
] + Cases.MODELS
var state: Dictionary = {}


func uid() -> String:
	var value := Crypto.new().generate_random_bytes(12).hex_encode()
	while state.get("items", {}).has(value):
		value = Crypto.new().generate_random_bytes(12).hex_encode()
	return value


func new_game(receiving: bool = false) -> void:
	state = {"version": 1, "items": {}, "credits": 500, "transactions": [], "tools": false, "player": [0.0, 0.0]}
	if not receiving:
		return
	var pc := uid()
	state.items[pc] = {"id": pc, "kind": "pc", "model": "Desktop recebido · ATX DDR4", "health": 100, "tested": false, "defects": [], "location": "floor", "position": [230.0, 130.0], "packaged": false, "components": {}, "lid": true, "screws": [true, true, true, true], "latches": [true, true], "power": false, "boot_remaining": 0.0, "boot_ok": false, "boot_result": "Não testado", "tool": "hands"}
	var specs := {"cpu": [RYVON_5_MODEL, 98], "motherboard": ["Amdera AX550 · ATX", 97], "ram": ["TR Memory 8 GB DDR4", 8], "gpu": ["TR Vision 2", 95], "storage": ["TR SATA 240 GB", 96], "psu": ["TR Power 450", 98], "cooling": ["TR Air 90", 99]}
	for kind in specs:
		var part := make_part(kind, specs[kind][0], specs[kind][1], "installed")
		part.owner_pc = pc
		part.origin = "installed"
		if kind == "ram" or kind == "motherboard": part.ddr = "DDR4"
		if kind in ["cpu", "motherboard", "cooling"]: part.socket = "AX4"
		if kind == "motherboard":
			part.board_art = "amdera"
			part.board_format = "ATX"
		if kind == "ram": part.defects = ["Falha persistente de leitura"]
		if kind == "storage": part.bootable = true
		state.items[part.id] = part
		state.items[pc].components[kind] = part.id
	var spare := make_part("ram", "TR Memory 8 GB DDR4", 96, "floor")
	spare.ddr = "DDR4"
	spare.origin = "receiving"
	spare.packaged = true
	spare.position = [285.0, 80.0]
	state.items[spare.id] = spare


func make_part(kind: String, model: String, health: int, location: String) -> Dictionary:
	return {"id": uid(), "kind": kind, "model": model, "health": health, "tested": false, "defects": [], "location": location, "owner_pc": "", "position": [0.0, 0.0], "packaged": false}


func item(id: String) -> Dictionary:
	return state.items.get(id, {})


func update_cpu_models() -> void:
	for part in state.items.values():
		if part.kind == "cpu" and CPU_MODEL_UPDATES.has(part.model):
			part.model = CPU_MODEL_UPDATES[part.model]
	for transaction in state.transactions:
		var description: Variant = transaction.get("description")
		if CPU_MODEL_UPDATES.has(description):
			transaction.description = CPU_MODEL_UPDATES[description]


func at(location: String) -> Array:
	var result: Array = []
	for record in state.items.values():
		if record.location == location: result.append(record.id)
	if location == "shelf": result.sort_custom(func(a: String, b: String) -> bool: return int(item(a).shelf_slot) < int(item(b).shelf_slot))
	return result


func _shelf_level() -> int:
	var level := 0
	for transaction in state.transactions:
		if transaction.has("shelf_expansion"): level += 1
	return level


func shelf_capacity() -> int:
	return _capacity_for_shelf_level(_shelf_level())


static func _capacity_for_shelf_level(level: int) -> int:
	return SHELF_CAPACITY if level == 0 else SHELF_EXPANSIONS[level - 1].capacity


func next_shelf_expansion() -> Dictionary:
	var level := _shelf_level()
	return SHELF_EXPANSIONS[level] if level < SHELF_EXPANSIONS.size() else {}


func shelf_expansion_block_reason(expansion: Dictionary) -> String:
	if Orders.completed_count(state) < expansion.deliveries:
		return Prefs.t("Desbloqueia com %d entregas.") % expansion.deliveries
	var spendable: float = state.credits
	for order in Orders.orders(self, "active"):
		spendable -= int(order.deposit)
	if spendable < expansion.price:
		return Prefs.t("Você pode usar %s na expansão. Os adiantamentos ficam reservados para os pedidos.") % Prefs.money(maxf(0, spendable))
	return ""


func buy_shelf_expansion(id: String) -> bool:
	var expansion := next_shelf_expansion()
	if expansion.get("id") != id: return fail("Esta expansão do armário não está disponível.")
	var reason := shelf_expansion_block_reason(expansion)
	if not reason.is_empty(): return fail(reason)
	state.credits -= int(expansion.price)
	state.transactions.append({"id": uid(), "shelf_expansion": id, "amount": -int(expansion.price)})
	return done(Prefs.t("Armário ampliado para %d espaços.") % expansion.capacity, "purchase")


func carried() -> String:
	var ids := at("carried")
	return str(ids[0]) if not ids.is_empty() else ""


func bench_id() -> String:
	var ids := at("bench")
	return str(ids[0]) if not ids.is_empty() else ""


func available_purchased_cases() -> Array[String]:
	var result: Array[String] = []
	for record in state.get("items", {}).values():
		if record.has("case_key") and record.get("origin") == "purchase" and record.location in ["floor", "carried"] and not record.power:
			result.append(record.id)
	return result


func place_purchased_case(id: String) -> bool:
	if not bench_id().is_empty(): return fail("A bancada já está ocupada.")
	if id not in available_purchased_cases(): return fail("Este gabinete ainda não está disponível para colocar na bancada.")
	var record := item(id)
	record.packaged = false
	return move(id, "bench")


func fail(text: String) -> bool:
	Audio.play("error")
	feedback.emit(Prefs.t(text), true)
	return false


func done(text: String, cue: String = "") -> bool:
	Audio.play(cue)
	changed.emit()
	feedback.emit(Prefs.t(text), false)
	return true


func move(id: String, location: String, position: Vector2 = Vector2.ZERO) -> bool:
	var record := item(id)
	if record.is_empty() or location not in ["floor", "carried", "shelf", "tray", "bench", "inventory"]:
		return fail("Item ou destino inválido.")
	if not position.is_finite() or (location == "floor" and (absf(position.y + position.x * 0.5) > 265 or absf(position.y - position.x * 0.5) > 265)):
		return fail("O destino deve ficar dentro da oficina.")
	if record.location in ["installed", "delivery", "returned"]:
		return fail("Retire o componente ou aguarde a entrega antes de transportá-lo.")
	if record.location == "sold": return fail("Este item já foi vendido.")
	if record.has("case_key") and record.packaged:
		return fail("Abra a embalagem antes de transportar o gabinete.")
	if record.get("power", false): return fail("Desligue o computador antes de transportá-lo.")
	if location == "inventory" and (record.kind == "pc" or at("inventory").size() >= INVENTORY_CAPACITY): return fail("Inventário: até 3 peças; transporte gabinetes nas mãos.")
	if location == "carried" and carried() != "" and carried() != id:
		return fail("Você só pode carregar um item por vez.")
	if location == "bench" and (record.kind != "pc" or (bench_id() != "" and bench_id() != id)):
		return fail("A bancada já está ocupada ou o item não é um gabinete.")
	if location == "tray" and (record.kind == "pc" or at("tray").size() >= 4):
		return fail("A bandeja aceita até quatro componentes.")
	if location == "shelf":
		var capacity := shelf_capacity()
		var stored := at("shelf")
		if record.kind == "pc" or stored.size() >= capacity:
			return fail(Prefs.t("O armário aceita até %d componentes; gabinetes não cabem.") % capacity)
		var used: Array = []
		for key in stored: used.append(item(key).get("shelf_slot", -1))
		for slot in range(capacity):
			if slot not in used:
				record.shelf_slot = slot
				break
	if location == "inventory":
		record.inventory_slot = _free_inventory_slot(id)
	record.location = location
	record.position = [position.x, position.y]
	return done("%s — %s" % [record.model, {"floor": "solto no chão", "carried": "carregando", "bench": "colocado na bancada", "shelf": "guardado na prateleira", "tray": "colocado na bandeja", "inventory": "no inventário"}[location]], "pickup" if location == "carried" else "place")


func _free_inventory_slot(item_id: String) -> int:
	var used: Array[int] = []
	for id in at("inventory"):
		if id != item_id: used.append(int(item(id).get("inventory_slot", -1)))
	for slot in range(INVENTORY_CAPACITY):
		if slot not in used: return slot
	return -1


func unpack(id: String) -> bool:
	var record := item(id)
	if record.is_empty() or record.location != "floor" or not record.packaged:
		return fail("Não há embalagem disponível aqui.")
	record.packaged = false
	return done("Embalagem aberta. O componente continua aqui: pressione E para pegá-lo.", "package")

func arrange_storage(id: String, destination: String, slot: int) -> bool:
	var record := item(id)
	if record.is_empty() or record.kind == "pc" or record.location not in ["inventory","shelf"]: return fail("Peça indisponível para organizar.")
	var capacity := shelf_capacity() if destination == "shelf" else INVENTORY_CAPACITY
	if destination not in ["inventory","shelf"] or slot < 0 or slot >= capacity: return false
	var field := "shelf_slot" if destination == "shelf" else "inventory_slot"
	for other_id in at(destination):
		if other_id != id and int(item(other_id).get(field,-1)) == slot: return fail("Este espaço está ocupado. Escolha um espaço vazio.")
	if record.location != destination:
		if at(destination).size() >= capacity: return fail("Destino cheio.")
	record.location = destination
	record[field] = slot
	return done("Peça organizada no espaço %02d." % (slot+1))


func safe_to_work(pc_id: String) -> bool:
	var pc := item(pc_id)
	if pc.is_empty() or pc.kind != "pc" or pc.location != "bench": return fail("Coloque o gabinete na bancada.")
	if pc.power: return fail("Desligue o computador antes de tocar na tampa, travas ou componentes.")
	return true


func toggle_latch(pc_id: String, index: int, slot: int = 0) -> bool:
	if not safe_to_work(pc_id): return false
	var pc := item(pc_id)
	if not pc.components.has("motherboard"): return fail("Instale a placa-mãe para acessar as travas da RAM.")
	if pc.lid: return fail("Retire a tampa antes de abrir as travas da RAM.")
	if index not in [0, 1]: return false
	if slot not in [0,1]: return false
	var clips := ram_latches(pc_id,slot)
	clips[index] = not clips[index]
	return done("RAM A%d · trava %s %s." % [slot+1,"superior" if index == 0 else "inferior", "fechada" if clips[index] else "aberta"], "latch")


func available_ram() -> Array:
	var result: Array = []
	for record in state.items.values():
		if record.kind == "ram" and record.location in ["tray", "carried", "inventory"] and not record.packaged:
			result.append(record.id)
	return result

func ram_latches(pc_id: String, slot: int) -> Array:
	var pc := item(pc_id)
	if slot == 0: return pc.latches
	if not pc.has("ram2_latches"): pc.ram2_latches = [true,true]
	return pc.ram2_latches

func ram_configuration_reason(pc_id: String) -> String:
	var pc := item(pc_id)
	var count := 0
	var board := item(pc.components.get("motherboard",""))
	for slot in range(2):
		var module := item(pc.components.get("ram" if slot == 0 else "ram2",""))
		if module.is_empty(): continue
		count += 1
		var clips := ram_latches(pc_id,slot)
		if not clips[0] or not clips[1]: return "RAM A%d sem as duas travas fechadas." % (slot+1)
		if module.get("ddr","") not in ["DDR4","DDR5"] or module.get("ddr","") != board.get("ddr","?"): return "RAM A%d incompatível com a placa-mãe." % (slot+1)
	return "Componente essencial ausente — RAM: instale um módulo em A1 ou A2." if count == 0 else ""


func use_ram_slot(pc_id: String, selected_id: String, slot: int = 0) -> bool:
	if not safe_to_work(pc_id): return false
	var pc := item(pc_id)
	if not pc.components.has("motherboard"): return fail("Instale a placa-mãe para acessar o slot de RAM.")
	if pc.lid: return fail("Retire a tampa lateral.")
	if slot not in [0,1]: return false
	var clips := ram_latches(pc_id,slot)
	var key := "ram" if slot == 0 else "ram2"
	if clips[0] or clips[1]: return fail("Abra as duas travas deste slot antes de retirar ou encaixar a RAM.")
	var installed: String = pc.components.get(key, "")
	if installed != "":
		var destination := "tray" if at("tray").size() < 4 else "inventory"
		if destination == "inventory" and at("inventory").size() >= INVENTORY_CAPACITY: return fail("Bandeja e inventário cheios. Guarde peças no armário.")
		_release_installed_part(installed, destination)
		pc.components.erase(key)
		pc.boot_ok = false
		return done("RAM retirada para %s. Selecione outro módulo e clique no slot vazio." % ("a bandeja" if destination == "tray" else "o inventário"))
	if selected_id not in available_ram(): return fail("Traga uma RAM desembalada da prateleira até a bandeja da bancada antes de selecioná-la.")
	var ram := item(selected_id)
	var board := item(pc.components.get("motherboard", ""))
	if board.is_empty() or board.get("ddr", "") not in ["DDR4", "DDR5"] or ram.get("ddr", "") != board.get("ddr", ""):
		return fail("Incompatibilidade: o módulo %s não encaixa nesta placa-mãe %s." % [ram.get("ddr", "?"), board.get("ddr", "?")])
	ram.location = "installed"
	ram.owner_pc = pc_id
	pc.components[key] = selected_id
	pc.boot_ok = false
	return done("RAM encaixada. Feche as duas travas antes de ligar o computador.", "latch")


func toggle_power(pc_id: String) -> bool:
	var pc := item(pc_id)
	if pc.is_empty() or pc.location != "bench": return fail("Nenhum computador na bancada.")
	var reason := assembly_power_block_reason(pc_id)
	if not reason.is_empty(): return fail(reason)
	pc.power = not pc.power
	if not pc.power: pc.erase("test_job")
	pc.boot_ok = false
	pc.boot_remaining = 1.2 if pc.power else 0.0
	pc.boot_result = "Executando POST…" if pc.power else "Computador desligado"
	return done(pc.boot_result, "power_on" if pc.power else "power_off")


func request_post(pc_id: String) -> bool:
	var pc := item(pc_id)
	if pc.is_empty() or pc.kind != "pc" or pc.location != "bench": return fail("Coloque um computador na bancada antes de testar.")
	if pc.has("test_job"): return fail("Aguarde o teste de componente em andamento.")
	if float(pc.boot_remaining) > 0: return fail("Aguarde o POST em andamento.")
	var reason := assembly_power_block_reason(pc_id)
	if not reason.is_empty(): return fail(reason)
	pc.power = true
	pc.boot_ok = false
	pc.boot_remaining = 1.2
	pc.boot_result = "Executando POST…"
	return done("POST iniciado. Aguarde a verificação dos componentes instalados.", "power_on")


func assembly_power_block_reason(pc_id: String) -> String:
	var pc := item(pc_id)
	if not pc.has("case_key") or pc.power: return ""
	for kind in ESSENTIAL_PARTS:
		if not pc.components.has(kind):
			return Prefs.t("Instale o componente essencial antes de ligar: %s.") % Prefs.t(PART_NAMES[kind])
	for kind in ESSENTIAL_PARTS:
		var mount: Dictionary = pc.get("mounts", {}).get(kind, {})
		if mount.is_empty() or false in mount.screws or false in mount.connections.values():
			return Prefs.t("Fixe e reconecte o componente antes de ligar: %s.") % Prefs.t(PART_NAMES[kind])
	return ram_configuration_reason(pc_id)


func evaluate_boot(pc_id: String) -> String:
	var pc := item(pc_id)
	if pc.has("mounts"):
		for kind in pc.components:
			if kind in ["ram", "ram2"]: continue
			var mount: Dictionary = mounts(pc_id, kind)
			if false in mount.screws or false in mount.connections.values(): return "Falha no POST: fixe e reconecte " + PART_NAMES.get(kind, kind)
	for kind in ESSENTIAL_PARTS:
		var part := item(pc.components.get(kind, ""))
		if part.is_empty(): return "Falha no POST: componente essencial ausente — " + kind
		if int(part.health) < (45 if kind == "ram" else 15):
			return "Falha no POST: erros detectados em " + kind + (". Saúde confirmada: %d%%." % part.health if part.tested else ". Condição exata ainda não avaliada.")
	var reason := ram_configuration_reason(pc_id)
	if not reason.is_empty(): return "Falha no POST: " + reason
	for key in ["ram","ram2"]:
		var ram := item(pc.components.get(key,""))
		if not ram.is_empty() and int(ram.health) < 45: return "Falha no POST: erros detectados em ram " + ("A1" if key == "ram" else "A2")
	if gpu_output(item(pc.components.gpu)) == "artifacts":
		return "POST com falha de vídeo: o monitor detectou artefatos e perda intermitente de sinal."
	if not item(pc.components.storage).get("bootable", false): return "POST concluído, mas nenhum sistema inicializável foi encontrado."
	return "POST concluído. Sistema inicializado; componentes essenciais reconhecidos."


func gpu_output(gpu: Dictionary) -> String:
	var health := int(gpu.get("health", 0))
	if health < 15: return "no_signal"
	if health < 70: return "artifacts"
	return "stable"


func video_status(pc_id: String) -> String:
	var pc := item(pc_id)
	if not pc.get("power", false): return "off"
	for kind in ["motherboard", "psu", "cpu", "gpu"]:
		var part := item(pc.components.get(kind, ""))
		var mount: Dictionary = pc.get("mounts", {}).get(kind, {})
		var connections: Dictionary = mount.get("connections", {})
		if int(part.get("health", 0)) < 15 or false in connections.values(): return "no_signal"
	if not ram_configuration_reason(pc_id).is_empty(): return "no_signal"
	for key in ["ram", "ram2"]:
		var ram := item(pc.components.get(key, ""))
		if not ram.is_empty() and int(ram.health) < 45: return "no_signal"
	if float(pc.boot_remaining) > 0.85: return "sync"
	if gpu_output(item(pc.components.gpu)) == "artifacts": return "artifacts"
	if pc.get("test_job", {}).get("kind") == "gpu": return "pattern"
	if float(pc.boot_remaining) > 0: return "post"
	return "desktop" if pc.boot_ok else "firmware"


func test_ram(pc_id: String) -> bool:
	var reason := ram_test_block_reason(pc_id)
	if not reason.is_empty(): return fail(reason)
	var pc := item(pc_id)
	var results: Array[String] = []
	for key in ["ram","ram2"]:
		var ram := item(pc.components.get(key,""))
		if ram.is_empty(): continue
		ram.tested = true
		ram.test_result = "%s: %d%% · %s" % ["A1" if key == "ram" else "A2",ram.health,condition_label(ram.health)]
		results.append(ram.test_result)
	pc.boot_result = evaluate_boot(pc_id)
	return done("Teste de memória concluído: "+"; ".join(results))


func ram_test_block_reason(pc_id: String) -> String:
	var pc := item(pc_id)
	if pc.is_empty() or pc.kind != "pc" or pc.location != "bench": return "Coloque um computador na bancada."
	if pc.has("test_job"): return "Aguarde o teste de componente em andamento."
	if not pc.power: return "Ligue o PC ou clique em Iniciar POST antes de testar a RAM."
	if float(pc.boot_remaining) > 0: return "Aguarde o término do POST para testar a RAM."
	for kind in ["motherboard", "cpu", "psu", "cooling"]:
		var essential := item(pc.components.get(kind, ""))
		if essential.is_empty() or int(essential.health) < 15: return "Corrija o componente essencial antes do teste: " + kind
	return ram_configuration_reason(pc_id)


func purchase_ram(ddr: String) -> bool:
	return purchase(ddr)


func purchase(key: String, heat_spreader_color: String = "") -> bool:
	var product: Dictionary = {}
	for entry in CATALOG:
		if entry.key == key: product = entry
	if product.is_empty(): return fail("Produto indisponível.")
	if not heat_spreader_color.is_empty():
		if not product.get("heat_spreader", false): return fail("Este componente não oferece escolha de cor.")
		if not HEAT_SPREADERS.has(heat_spreader_color): return fail("Cor de dissipador indisponível.")
	var price: int = product.price
	if state.credits < price: return fail("Créditos insuficientes. Nenhuma compra realizada.")
	var part := make_part("pc" if product.kind == "case" else product.kind, product.model, 100 if product.kind == "case" else 96, "delivery")
	if product.kind == "case":
		part.merge({
			"case_key": key, "components": {}, "lid": true, "screws": [true, true, true, true],
			"latches": [true, true], "tool": "hands", "power": false, "boot_remaining": 0.0,
			"boot_ok": false, "boot_result": "Não testado",
		})
	for field in ["ddr", "capacity_gb", "board_art", "board_format", "socket", "alternate_socket"]:
		if product.has(field): part[field] = product[field]
	if not heat_spreader_color.is_empty():
		part.heat_spreader_color = heat_spreader_color
		part.model += " · " + heat_spreader_color
	if product.kind == "storage": part.bootable = false
	part.origin = "purchase"
	part.packaged = true
	part.delivery_remaining = 3.0
	var position := _delivery_position()
	if not position.is_finite(): return fail("Libere espaço na área de recebimento antes de comprar.")
	part.position = [position.x, position.y]
	state.items[part.id] = part
	state.credits -= price
	state.transactions.append({"id": uid(), "item_id": part.id, "amount": -price, "description": part.model})
	return done("Compra registrada. A caixa chegará em três segundos.", "purchase")


func sale_offers() -> Dictionary:
	var offers := {}
	for transaction in state.transactions:
		if not transaction.has("item_id") or transaction.amount >= 0: continue
		var record := item(transaction.item_id)
		if record.get("location") in SELLABLE_LOCATIONS and _can_sell_record(record):
			offers[record.id] = _resale_cents(-int(transaction.amount)) / 100.0
	return offers


func sell(id: String) -> bool:
	var price: float = sale_offers().get(id, 0.0)
	if price <= 0.0: return fail("Este item não está disponível para venda.")
	var record := item(id)
	record.location = "sold"
	state.credits = (roundi(state.credits * 100.0) + roundi(price * 100.0)) / 100.0
	state.transactions.append({"id": uid(), "item_id": id, "type": "sale", "amount": price, "description": record.model})
	return done(Prefs.t("Vendido: %s · %s recebidos.") % [record.model, Prefs.money(price)], "purchase")


static func _can_sell_record(record: Dictionary) -> bool:
	# A cabinet sale transfers the shell only. Installed parts must be removed first.
	return record.kind != "pc" or (record.has("case_key") and record.components.is_empty())


static func _resale_cents(purchase_price: int) -> int:
	return purchase_price * RESALE_CENTS_PER_CREDIT


func _delivery_position() -> Vector2:
	var occupied: Array[Vector2] = []
	for record in state.items.values():
		if record.location in ["floor", "delivery"]:
			occupied.append(Vector2(record.position[0], record.position[1]))
	for y in [80, 48, 16, -16]:
		for x in [285, 317, 253, 221]:
			var position := Vector2(x, y)
			if not occupied.any(func(other: Vector2) -> bool: return other.distance_squared_to(position) < 28.0 ** 2):
				return position
	return Vector2.INF


func tick(delta: float) -> void:
	for record in state.items.values():
		if record.kind == "pc" and record.has("test_job"):
			var job: Dictionary = record.test_job
			job.remaining = maxf(0.0, float(job.remaining) - delta)
			if not record.power:
				record.erase("test_job")
			elif job.remaining == 0:
				var tested_part := item(job.part_id)
				tested_part.tested = true
				tested_part.test_result = "%s: %d%% · %s. %s" % [PART_NAMES[job.kind], tested_part.health, condition_label(tested_part.health), "Sem falhas detectadas nesta verificação." if tested_part.defects.is_empty() else ", ".join(tested_part.defects)]
				if job.kind == "gpu":
					var output := gpu_output(tested_part)
					var observed: String = {"no_signal": "A placa não gera sinal.", "artifacts": "Artefatos e perda intermitente de sinal.", "stable": "Saída da placa estável."}[output]
					tested_part.test_result += " " + observed
				record.erase("test_job")
				done(tested_part.test_result)
		if record.location == "delivery":
			record.delivery_remaining = maxf(0.0, float(record.delivery_remaining) - delta)
			if record.delivery_remaining == 0:
				record.location = "floor"
				done("Entrega recebida. Abra a caixa com E.", "delivery")
		elif record.kind == "pc" and record.power and float(record.boot_remaining) > 0:
			record.boot_remaining = maxf(0.0, float(record.boot_remaining) - delta)
			if record.boot_remaining == 0:
				record.boot_result = evaluate_boot(record.id)
				record.boot_ok = record.boot_result.begins_with("POST concluído. Sistema")
				if record.boot_ok: record.service_post = Orders.signature(self, record)
				done(record.boot_result, "boot_ok" if record.boot_ok else "boot_fail")


static func condition_label(health: int) -> String:
	if health >= 90: return "Perfeito estado"
	if health >= 70: return "Bom"
	if health >= 45: return "Mediano"
	if health >= 15: return "Ruim"
	return "Quebrado"


func known_description(id: String) -> String:
	var record := item(id)
	if record.is_empty(): return "Nenhum item"
	return "%s · %s" % [record.model, ("%d%% — %s" % [record.health, Prefs.t(condition_label(record.health))]) if record.tested else Prefs.t("Condição desconhecida")]


func localized_boot_result(pc: Dictionary) -> String:
	var result: String = pc.boot_result
	for prefix in ["Falha no POST: erros detectados em ram ", "Falha no POST: "]:
		if result.begins_with(prefix):
			return Prefs.t(prefix) + Prefs.t(result.trim_prefix(prefix))
	return Prefs.t(result)


func valid(candidate: Dictionary, inventory_limit: int = INVENTORY_CAPACITY) -> bool:
	if not preload("res://Scripts/World/workshop_appearance.gd").valid(candidate.get("decoration",{})): return false
	if candidate.get("version") != 1 or not candidate.get("items") is Dictionary or not candidate.get("transactions") is Array: return false
	if not money_value(candidate.get("credits")) or candidate.credits < 0: return false
	var balance_adjustment: Variant = candidate.get("balance_adjustment", 0)
	if not money_value(balance_adjustment) or balance_adjustment < 0: return false
	if not candidate.get("tools") is bool or not candidate.get("player") is Array or candidate.player.size() != 2: return false
	for coordinate in candidate.player:
		if not numeric(coordinate) or absf(float(coordinate)) > 2000: return false
	var carries := 0
	var benches := 0
	var counter_slots: Array[int] = []
	var trays := 0
	var inventory_count := 0
	var referenced: Dictionary = {}
	var shelves: Array = []
	for id in candidate.items:
		var r = candidate.items[id]
		if not id is String or id.is_empty() or not r is Dictionary or r.get("id") != id or r.get("location") not in PHYSICAL_LOCATIONS: return false
		if not r.get("model") is String or not numeric(r.get("health")) or r.health < 0 or r.health > 100 or int(r.health) != r.health: return false
		if not r.get("tested") is bool or not r.get("packaged") is bool or not r.get("defects") is Array: return false
		if r.get("kind") not in ["pc", "ram", "gpu", "storage", "psu", "cooling", "motherboard", "cpu"]: return false
		if r.kind in ["ram", "motherboard"] and r.get("ddr", "") not in ["DDR4", "DDR5"]: return false
		if r.has("board_format") and (r.kind != "motherboard" or r.board_format not in Cases.FORMATS): return false
		if r.has("case_key") and (r.kind != "pc" or not r.case_key is String): return false
		if r.has("heat_spreader_color") and (r.kind != "ram" or not HEAT_SPREADERS.has(r.heat_spreader_color)): return false
		if not r.get("position") is Array or r.position.size() != 2: return false
		for coordinate in r.position:
			if not numeric(coordinate) or absf(float(coordinate)) > 2000: return false
		if r.location == "floor" and (absf(r.position[1] + r.position[0] * 0.5) > 265 or absf(r.position[1] - r.position[0] * 0.5) > 265): return false
		if r.location == "delivery" and (not numeric(r.get("delivery_remaining")) or r.delivery_remaining < 0 or not r.packaged): return false
		if r.location == "tray":
			trays += 1
			if r.kind == "pc": return false
		if r.location == "inventory":
			inventory_count += 1
			if r.kind == "pc": return false
		if r.location == "carried": carries += 1
		if r.location == "bench":
			benches += 1
			if r.kind != "pc": return false
		if r.location == "counter":
			if r.kind != "pc" or not numeric(r.get("counter_slot")): return false
			var slot := int(r.counter_slot)
			if r.counter_slot != slot or slot < 0 or slot >= COUNTER_CAPACITY or slot in counter_slots: return false
			counter_slots.append(slot)
		if r.location == "shelf":
			if r.kind == "pc" or not numeric(r.get("shelf_slot")): return false
			var slot := int(r.shelf_slot)
			if r.shelf_slot != slot or slot < 0 or slot in shelves: return false
			shelves.append(slot)
		if r.kind == "pc":
			if r.has("ram2_latches"):
				if not r.ram2_latches is Array or r.ram2_latches.size() != 2: return false
				for flag in r.ram2_latches:
					if not flag is bool: return false
			if r.has("test_job"):
				var job: Variant = r.test_job
				if not job is Dictionary or not numeric(job.get("remaining")) or job.remaining < 0 or job.get("kind") not in PART_NAMES: return false
				if not r.get("components") is Dictionary or r.components.get(job.kind) != job.get("part_id") or not r.get("power", false): return false
			if r.has("mounts"):
				if not r.mounts is Dictionary: return false
				for kind in r.mounts:
					if not FASTENERS.has(kind): return false
					var mount: Variant = r.mounts[kind]
					if not mount is Dictionary or not mount.get("screws") is Array or mount.screws.size() != FASTENERS[kind] or not mount.get("connections") is Dictionary: return false
					for flag in mount.screws + mount.connections.values():
						if not flag is bool: return false
					if mount.connections.size() != CONNECTIONS[kind].size(): return false
					for connector in CONNECTIONS[kind]:
						if not mount.connections.has(connector): return false
			if not r.get("components") is Dictionary or not r.get("screws") is Array or r.screws.size() != 4 or not r.get("latches") is Array or r.latches.size() != 2: return false
			if r.has("client_apps"):
				if not r.client_apps is Array: return false
				var installed := {}
				for app in r.client_apps:
					if app not in preload("res://Scripts/TechOS/client_apps.gd").OPTIONAL or installed.has(app): return false
					installed[app] = true
			if not r.get("lid") is bool or not r.get("power") is bool or not r.get("boot_ok") is bool or not r.get("boot_result") is String or r.get("tool") not in ["hands", "phillips"]: return false
			if r.tool == "phillips" and not candidate.tools: return false
			if not numeric(r.get("boot_remaining")) or r.boot_remaining < 0: return false
			for flag in r.screws + r.latches:
				if not flag is bool: return false
			var case_model := Cases.get_model(r.case_key) if r.has("case_key") else {}
			if r.has("case_key"):
				if case_model.is_empty() or r.get("origin") != "purchase": return false
				if r.location not in ["delivery", "floor", "carried", "bench", "sold"] or r.has("service_order"): return false
				if r.location != "bench" and r.power: return false
				if r.packaged and (r.location not in ["delivery", "floor", "sold"] or not r.components.is_empty() or not r.lid): return false
				if not r.lid and true in r.screws: return false
			for kind in r.components:
				if not r.components[kind] is String: return false
				var child_id: String = r.components[kind]
				if not candidate.items.has(child_id) or referenced.has(child_id): return false
				if not candidate.items[child_id] is Dictionary: return false
				var child: Dictionary = candidate.items[child_id]
				if child.get("kind") != ("ram" if kind == "ram2" else kind) or child.get("location") != "installed" or child.get("owner_pc") != id: return false
				if not case_model.is_empty() and not _valid_assembly_part(candidate.items, r, case_model, kind, child): return false
				referenced[child_id] = id
	for id in candidate.items:
		if candidate.items[id].location == "installed" and not referenced.has(id): return false
	if not Orders.valid(candidate): return false
	var credit_total_cents := (500 + Orders.earnings(candidate)) * 100 + roundi(balance_adjustment * 100.0)
	var deliveries := Orders.completed_count(candidate)
	var shelf_level := 0
	var transaction_ids: Dictionary = {}
	var purchased_ids: Dictionary = {}
	var sold_ids: Dictionary = {}
	for transaction in candidate.transactions:
		if not transaction is Dictionary or not transaction.get("id") is String or transaction_ids.has(transaction.id): return false
		if not money_value(transaction.get("amount")): return false
		var amount_cents := roundi(transaction.amount * 100.0)
		var sale: bool = transaction.get("type") == "sale"
		if sale:
			if amount_cents <= 0 or transaction.has("shelf_expansion"): return false
		elif amount_cents >= 0 or amount_cents % 100 != 0:
			return false
		transaction_ids[transaction.id] = true
		if transaction.has("shelf_expansion"):
			if transaction.has("item_id") or shelf_level >= SHELF_EXPANSIONS.size(): return false
			var expansion: Dictionary = SHELF_EXPANSIONS[shelf_level]
			if not transaction.shelf_expansion is String or transaction.shelf_expansion != expansion.id or transaction.amount != -expansion.price or deliveries < expansion.deliveries: return false
			shelf_level += 1
		else:
			var item_id: Variant = transaction.get("item_id")
			if not item_id is String or not candidate.items.has(item_id): return false
			if sale:
				if not purchased_ids.has(item_id) or sold_ids.has(item_id) or amount_cents != _resale_cents(purchased_ids[item_id]): return false
				var record: Dictionary = candidate.items[item_id]
				if record.location != "sold" or not _can_sell_record(record): return false
				sold_ids[item_id] = true
			else:
				if purchased_ids.has(item_id): return false
				purchased_ids[item_id] = -int(transaction.amount)
		credit_total_cents += amount_cents
	for id in candidate.items:
		if candidate.items[id].has("case_key") and not purchased_ids.has(id): return false
		if candidate.items[id].location == "sold" and not sold_ids.has(id): return false
	var capacity := _capacity_for_shelf_level(shelf_level)
	if shelves.any(func(slot: int) -> bool: return slot >= capacity): return false
	return carries <= 1 and benches <= 1 and trays <= 4 and inventory_count <= inventory_limit and credit_total_cents == roundi(candidate.credits * 100.0)


static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func money_value(value: Variant) -> bool:
	return numeric(value) and absf(float(value) * 100.0 - roundf(float(value) * 100.0)) < 0.00001


func _valid_assembly_part(items: Dictionary, pc: Dictionary, case_model: Dictionary, kind: String, part: Dictionary) -> bool:
	if part.get("packaged") != false or (not PART_NAMES.has(kind) and kind != "ram2"): return false
	if kind not in ["ram", "ram2"] and not pc.get("mounts", {}).has(kind): return false
	if kind == "motherboard": return Cases.board_format(part) in case_model.board_formats
	if kind in ["psu", "storage"]: return true
	var board_id: Variant = pc.components.get("motherboard")
	if not board_id is String: return false
	var board: Variant = items.get(board_id)
	if not board is Dictionary: return false
	if kind == "gpu": return true
	if kind in ["ram", "ram2"]: return part.get("ddr") == board.get("ddr")
	if kind == "cooling" and not pc.components.has("cpu"): return false
	var board_socket: Variant = board.get("socket", "TR4")
	var part_socket: Variant = part.get("socket", "TR4")
	return board_socket is String and part_socket is String and (part_socket == board_socket or part.get("alternate_socket") == board_socket)


func mounts(pc_id: String, kind: String) -> Dictionary:
	# Lazy migration: existing saves retain all units and their test knowledge.
	var pc := item(pc_id)
	if not pc.has("mounts"): pc.mounts = {}
	if not pc.mounts.has(kind):
		var fixed: bool = pc.components.has(kind)
		var screws: Array = []
		for i in range(FASTENERS.get(kind, 0)): screws.append(fixed)
		var connections := {}
		for connector in CONNECTIONS.get(kind, []): connections[connector] = fixed
		pc.mounts[kind] = {"screws": screws, "connections": connections}
	return pc.mounts[kind]


func available_parts() -> Array:
	var result: Array = []
	for record in state.items.values():
		if record.kind != "pc" and record.location in ["tray", "carried", "inventory"] and not record.packaged: result.append(record.id)
	return result


func operate_mount(pc_id: String, kind: String, action: String, index: int) -> bool:
	if not safe_to_work(pc_id): return false
	var pc := item(pc_id)
	if pc.lid: return fail("Retire a tampa para acessar as fixações.")
	if not PART_NAMES.has(kind): return false
	if kind == "cpu" and pc.components.has("cooling"): return fail("Retire o cooler para acessar a alavanca do socket.")
	if not pc.components.has(kind): return fail("Encaixe a peça antes de reconectar ou fixar.")
	var mount := mounts(pc_id, kind)
	var cue := "latch"
	if action == "screw":
		if pc.tool != "phillips": return fail("Selecione a Phillips (2) para operar este parafuso.")
		if index < 0 or index >= mount.screws.size(): return false
		mount.screws[index] = not mount.screws[index]
		cue = "screw" if mount.screws[index] else "unscrew"
	else:
		if pc.tool != "hands": return fail("Selecione Mãos (1) para operar conectores e travas.")
		var keys: Array = CONNECTIONS[kind]
		if index < 0 or index >= keys.size(): return false
		var connector: String = keys[index]
		mount.connections[connector] = not mount.connections[connector]
		if mount.connections[connector] and connector not in ["socket", "trava PCIe"]:
			cue = "cable_click"
	pc.boot_ok = false
	return done("%s: %s atualizado. Desligado durante toda a desmontagem." % [PART_NAMES[kind], "parafuso" if action == "screw" else "conector / trava"], cue)


func use_component(pc_id: String, kind: String, selected_id: String) -> bool:
	if kind == "ram": return use_ram_slot(pc_id, selected_id)
	if not safe_to_work(pc_id): return false
	var pc := item(pc_id)
	if pc.lid: return fail("Retire a tampa lateral.")
	if pc.tool != "hands": return fail("Selecione Mãos (1) para manusear peças.")
	if not PART_NAMES.has(kind): return false
	var installed: String = pc.components.get(kind, "")
	if kind == "cpu" and pc.components.has("cooling"): return fail("Retire o cooler antes do processador; o processador usa socket, sem parafusos.")
	if kind == "motherboard":
		for child in ["cpu", "ram", "ram2", "gpu", "cooling"]:
			if pc.components.has(child): return fail("Retire CPU, cooler, RAM e GPU antes de retirar a placa-mãe.")
	if installed != "":
		var mount := mounts(pc_id, kind)
		if true in mount.screws: return fail("Solte os %d parafuso(s) restantes de %s." % [mount.screws.count(true), PART_NAMES[kind]])
		if true in mount.connections.values(): return fail("Libere os conectores / travas de " + PART_NAMES[kind] + ": " + ", ".join(CONNECTIONS[kind]))
		var destination := "tray" if at("tray").size() < 4 else "inventory"
		if destination == "inventory" and at("inventory").size() >= INVENTORY_CAPACITY: return fail("Bandeja e inventário cheios. Guarde peças no armário.")
		_release_installed_part(installed, destination)
		pc.components.erase(kind)
		pc.mounts.erase(kind)
		pc.boot_ok = false
		return done(PART_NAMES[kind] + " retirada para " + ("a bandeja." if destination == "tray" else "o inventário."))
	if selected_id not in available_parts() or item(selected_id).kind != kind: return fail("Selecione uma peça compatível no inventário da inspeção.")
	var part := item(selected_id)
	var board := item(pc.components.get("motherboard", ""))
	if kind == "motherboard" and pc.has("case_key"):
		var format := Cases.board_format(part)
		var supported: Array = Cases.get_model(pc.case_key).board_formats
		if format not in supported:
			return fail(Prefs.t("Formato incompatível: %s. Este gabinete aceita %s.") % [
				Prefs.t("Desconhecido") if format.is_empty() else format, " / ".join(supported),
			])
	if kind in ["cpu", "ram", "gpu", "cooling"] and board.is_empty(): return fail("Instale a placa-mãe primeiro.")
	if kind == "cooling" and not pc.components.has("cpu"): return fail("Encaixe o processador antes do cooler.")
	if kind in ["cpu", "cooling"]:
		var board_socket: String = board.get("socket", "TR4")
		var sockets := mounting_sockets(part)
		if board_socket not in sockets:
			return fail("Socket incompatível: a peça usa %s e a placa-mãe usa %s." % [" / ".join(sockets), board_socket])
	mounts(pc_id, kind)
	part.location = "installed"
	part.owner_pc = pc_id
	pc.components[kind] = selected_id
	pc.boot_ok = false
	return done(PART_NAMES[kind] + " encaixada. Reconecte e fixe todos os pontos destacados.")


func _release_installed_part(id: String, destination: String) -> void:
	var part := item(id)
	part.location = destination
	part.owner_pc = ""
	if destination == "inventory":
		part.inventory_slot = _free_inventory_slot(id)


func mounting_sockets(part: Dictionary) -> PackedStringArray:
	var sockets := PackedStringArray([part.get("socket", "TR4")])
	if part.has("alternate_socket"): sockets.append(part.alternate_socket)
	return sockets


func test_component(pc_id: String, kind: String) -> bool:
	if kind == "ram": return test_ram(pc_id)
	var reason := component_test_block_reason(pc_id, kind)
	if not reason.is_empty(): return fail(reason)
	var pc := item(pc_id)
	var part := item(pc.components.get(kind, ""))
	pc.test_job = {"kind": kind, "part_id": part.id, "remaining": 1.8}
	return done("Teste de %s iniciado. Aguarde a verificação da bancada." % PART_NAMES[kind])


func component_test_block_reason(pc_id: String, kind: String) -> String:
	var pc := item(pc_id)
	if pc.is_empty() or pc.location != "bench": return "Coloque um computador na bancada."
	if pc.has("test_job"): return "Teste em andamento. Aguarde ou desligue o PC para cancelar."
	if not pc.power or float(pc.boot_remaining) > 0: return "Ligue o computador e aguarde o POST antes do teste."
	var part := item(pc.components.get(kind, ""))
	if part.is_empty(): return "Componente não instalado: " + PART_NAMES.get(kind, kind)
	for dependency in ["motherboard", "psu"]:
		if dependency == kind: continue
		var support := item(pc.components.get(dependency, ""))
		if support.is_empty() or int(support.health) < 15: return "Teste bloqueado pela alimentação/placa-mãe: " + PART_NAMES[dependency]
	var mount := mounts(pc_id, kind)
	if false in mount.screws or false in mount.connections.values(): return "Fixe e reconecte a peça antes do teste."
	return ""

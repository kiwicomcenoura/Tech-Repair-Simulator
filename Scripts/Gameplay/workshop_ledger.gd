extends RefCounted
## Single authoritative registry: one record and one location for every unit ID.
## Scene actors, inventory rows and equipment Resources are derived views.

signal changed
signal feedback(text: String, failed: bool)
signal mail_changed

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const Audio := preload("res://Scripts/Gameplay/workshop_audio.gd")
const Orders := preload("res://Scripts/Gameplay/service_orders.gd")
const Mail := preload("res://Scripts/Gameplay/workshop_mail.gd")
const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")
const Peripherals := preload("res://Scripts/Equipment/peripheral_catalog.gd")
const ClientApps := preload("res://Scripts/TechOS/client_apps.gd")
const INSTALL_DURATION := 4.0
const NO_BOOT_SYSTEM := "POST concluído, mas nenhum sistema inicializável foi encontrado."
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
const BENCH_PART_LOCATIONS := ["shelf", "inventory", "tray", "carried"]
const PART_NAMES := {"cpu": "Processador", "cooling": "Refrigeração", "motherboard": "Placa-mãe", "ram": "Memória RAM", "gpu": "Placa de vídeo", "storage": "Armazenamento", "psu": "Fonte"}
const STORAGE_SLOTS := ["storage", "storage2"]
const ESSENTIAL_PARTS := ["motherboard", "cpu", "psu", "cooling", "storage"]
const FASTENERS := {"cpu": 0, "ram": 0, "gpu": 2, "storage": 4, "storage2": 4, "psu": 4, "cooling": 4, "motherboard": 6}
const CONNECTIONS := {"cpu": ["socket"], "ram": [], "gpu": ["energia", "trava PCIe"], "storage": ["SATA dados", "SATA energia"], "storage2": ["SATA dados", "SATA energia"], "psu": ["chicote de energia"], "cooling": ["CPU FAN"], "motherboard": ["ATX 24 pinos", "EPS CPU", "painel frontal"]}
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
	{"key": "ddr3_4", "kind": "ram", "model": "TR Memory 4 GB DDR3", "price": 65, "ddr": "DDR3", "capacity_gb": 4, "speed_mt": 1333},
	{"key": "ddr3_8", "kind": "ram", "model": "TR Memory 8 GB DDR3", "price": 95, "ddr": "DDR3", "capacity_gb": 8},
	{"key": "gpu", "kind": "gpu", "model": "TR Vision 2 · PCIe", "price": 250, "size_mm": 155},
	{"key": "storage", "kind": "storage", "model": "TR SATA 240 GB · sem sistema", "price": 100},
	{"key": "psu", "kind": "psu", "model": "TR Power 450 W · ATX", "price": 160, "size_mm": 140},
	{"key": "cooling", "kind": "cooling", "model": "TR Air 90 · 90 mm", "price": 80, "socket": "TR4", "alternate_socket": "AX4", "size_mm": 94},
	{"key": "amdera_ryvon_3", "kind": "cpu", "model": RYVON_3_MODEL, "price": 185, "socket": "AX4"},
	{"key": "amdera_ryvon_5", "kind": "cpu", "model": RYVON_5_MODEL, "price": 250, "socket": "AX4"},
	{"key": "amdera_ryvon_7", "kind": "cpu", "model": RYVON_7_MODEL, "price": 380, "socket": "AX4"},
	{"key": "intara_coren_i3", "kind": "cpu", "model": COREN_I3_MODEL, "price": 210, "socket": "IX1700"},
	{"key": "intara_coren_i5", "kind": "cpu", "model": COREN_I5_MODEL, "price": 340, "socket": "IX1700"},
	{"key": "intara_coren_i7", "kind": "cpu", "model": COREN_I7_MODEL, "price": 460, "socket": "IX1700"},
	{"key": "ddr4_16", "kind": "ram", "model": "TR Memory 16 GB DDR4", "price": 205, "ddr": "DDR4", "capacity_gb": 16, "speed_mt": 2666, "heat_spreader": true},
	{"key": "ddr4_32", "kind": "ram", "model": "TR Memory 32 GB DDR4", "price": 295, "ddr": "DDR4", "capacity_gb": 32, "heat_spreader": true},
	{"key": "ddr5_16", "kind": "ram", "model": "TR Memory 16 GB DDR5", "price": 245, "ddr": "DDR5", "capacity_gb": 16, "heat_spreader": true},
	{"key": "ddr5_32", "kind": "ram", "model": "TR Memory 32 GB DDR5", "price": 345, "ddr": "DDR5", "capacity_gb": 32, "heat_spreader": true},
	{"key": "ddr5_48", "kind": "ram", "model": "TR Memory 48 GB DDR5", "price": 475, "ddr": "DDR5", "capacity_gb": 48, "speed_mt": 6000, "heat_spreader": true},
	{"key": "amdera_frost_120", "kind": "cooling", "model": "Amdera Frost 120 · 120 mm", "price": 125, "socket": "AX4", "alternate_socket": "AM5", "size_mm": 148},
	{"key": "amdera_compact_92", "kind": "cooling", "model": "Amdera Compact 92 · 92 mm", "price": 100, "socket": "AM4", "alternate_socket": "AM5", "size_mm": 96},
	{"key": "intara_legacy_90", "kind": "cooling", "model": "Intara Classic 90 · 90 mm", "price": 80, "socket": "LGA1155", "alternate_socket": "LGA1151", "extra_socket": "LGA1200", "size_mm": 92},
	{"key": "intara_breeze_92", "kind": "cooling", "model": "Intara Breeze 92 · 92 mm", "price": 90, "socket": "IX1700", "size_mm": 98},
	{"key": "intara_breeze_120", "kind": "cooling", "model": "Intara Breeze 120 · 120 mm", "price": 140, "socket": "IX1700", "size_mm": 149},
	{"key": "ssd_480", "kind": "storage", "model": "TR SSD SATA 480 GB · sem sistema", "price": 145},
	{"key": "ssd_960", "kind": "storage", "model": "TR SSD SATA 960 GB · sem sistema", "price": 215},
	{"key": "psu_550", "kind": "psu", "model": "TR Power 550 W · ATX", "price": 210, "size_mm": 140},
	{"key": "psu_650", "kind": "psu", "model": "TR Power 650 W · ATX", "price": 270, "size_mm": 150},
	{"key": "psu_850", "kind": "psu", "model": "TR Power 850 W · ATX", "price": 520, "size_mm": 160},
	{"key": "psu_1000", "kind": "psu", "model": "TR Power 1000 W · ATX", "price": 780, "size_mm": 175},
] + Hardware.BOARDS + Hardware.CPUS + Peripherals.GPUS + Peripherals.DRIVES + Cases.MODELS
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
	if record.get("install_usb", false) and location != "bench":
		return fail("Retire o pendrive de instalação antes de transportar o computador.")
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
	if record.is_empty() or record.location not in ["floor", "shelf"] or not record.packaged:
		return fail("Não há embalagem disponível aqui.")
	record.packaged = false
	if record.location == "shelf": return done("Embalagem aberta. A peça do armário pode ser instalada pela bancada.", "package")
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
	if slot not in ram_slots(pc_id): return false
	var clips := ram_latches(pc_id,slot)
	clips[index] = not clips[index]
	pc[Hardware.LATCH_KEYS[slot]] = clips
	return done("RAM %s · trava %s %s." % [Hardware.RAM_LABELS[slot], "superior" if index == 0 else "inferior", "fechada" if clips[index] else "aberta"], "latch")


func available_ram() -> Array:
	return available_parts("ram")

func ram_slots(pc_id: String) -> Array:
	return Hardware.slot_order(item(item(pc_id).get("components", {}).get("motherboard", "")))


func ram_latches(pc_id: String, slot: int) -> Array:
	return item(pc_id).get(Hardware.LATCH_KEYS[slot], [true, true])


func ram_modules(pc: Dictionary) -> Array:
	return _ram_modules(state.items, pc)


static func _ram_modules(items: Dictionary, pc: Dictionary) -> Array:
	var modules: Array = []
	for key in Hardware.RAM_KEYS:
		var module: Dictionary = items.get(pc.components.get(key, ""), {})
		if not module.is_empty(): modules.append(module)
	return modules


func memory_profile(pc_id: String) -> Dictionary:
	var pc := item(pc_id)
	var board := item(pc.components.get("motherboard", ""))
	var cpu := item(pc.components.get("cpu", ""))
	var channels := [0, 0]
	var speed := Hardware.memory_limit_mt(board, cpu)
	for slot in ram_slots(pc_id):
		var module := item(pc.components.get(Hardware.RAM_KEYS[slot], ""))
		if module.is_empty(): continue
		channels[slot % 2] += Hardware.module_capacity(module)
		speed = mini(speed, Hardware.module_speed(module))
	var total: int = channels[0] + channels[1]
	if total == 0: return {}
	var dual := 2 * mini(channels[0], channels[1])
	return {"total_gb": total, "dual_gb": dual, "speed_mt": speed,
		"mode": "Single Channel" if dual == 0 else "Dual Channel" if dual == total else "Dual Channel assimétrico",
		"bandwidth_gbs": speed * 0.008 * (1.0 + float(dual) / total),
		"performance": roundi(cpu.get("performance", Hardware.cpu_spec(cpu).get("performance", 50)) * (1.0 + 0.12 * float(dual) / total))}

func ram_configuration_reason(pc_id: String) -> String:
	var pc := item(pc_id)
	var board := item(pc.components.get("motherboard",""))
	var modules := ram_modules(pc)
	if modules.is_empty(): return "Componente essencial ausente — RAM: instale um módulo."
	var reason := Hardware.memory_reason(board, item(pc.components.get("cpu", "")), modules)
	if not reason.is_empty(): return reason
	for slot in ram_slots(pc_id):
		if not pc.components.has(Hardware.RAM_KEYS[slot]): continue
		var clips := ram_latches(pc_id,slot)
		if not clips[0] or not clips[1]: return "RAM %s sem as duas travas fechadas." % Hardware.RAM_LABELS[slot]
	return ""


func use_ram_slot(pc_id: String, selected_id: String, slot: int = 0) -> bool:
	if not safe_to_work(pc_id): return false
	var pc := item(pc_id)
	if not pc.components.has("motherboard"): return fail("Instale a placa-mãe para acessar o slot de RAM.")
	if pc.lid: return fail("Retire a tampa lateral.")
	if slot not in ram_slots(pc_id): return false
	var clips := ram_latches(pc_id,slot)
	var key: String = Hardware.RAM_KEYS[slot]
	if clips[0] or clips[1]: return fail("Abra as duas travas deste slot antes de retirar ou encaixar a RAM.")
	var installed: String = pc.components.get(key, "")
	if installed != "":
		var destination := "tray" if at("tray").size() < 4 else "inventory"
		if destination == "inventory" and at("inventory").size() >= INVENTORY_CAPACITY: return fail("Bandeja e inventário cheios. Guarde peças no armário.")
		_release_installed_part(installed, destination)
		pc.components.erase(key)
		pc.boot_ok = false
		return done("RAM retirada para %s. Selecione outro módulo e clique no slot vazio." % ("a bandeja" if destination == "tray" else "o inventário"))
	if selected_id not in available_ram(): return fail("Selecione uma RAM desembalada na lista de peças da bancada.")
	var ram := item(selected_id)
	var board := item(pc.components.get("motherboard", ""))
	var reason := Hardware.memory_reason(board, item(pc.components.get("cpu", "")), ram_modules(pc) + [ram])
	if not reason.is_empty(): return fail(reason)
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
	if not pc.power:
		_begin_post(pc)
		return done(pc.boot_result, "power_on")
	pc.power = false
	pc.erase("test_job")
	var interrupted: bool = pc.get("installation", {}).get("phase") == "copying"
	pc.erase("installation")
	pc.boot_ok = false
	pc.boot_remaining = 0.0
	pc.boot_result = "Computador desligado"
	return done("Instalação interrompida. O conteúdo do disco foi preservado." if interrupted else pc.boot_result, "power_off")


func request_post(pc_id: String) -> bool:
	var pc := item(pc_id)
	if pc.is_empty() or pc.kind != "pc" or pc.location != "bench": return fail("Coloque um computador na bancada antes de testar.")
	if pc.has("installation"): return fail("Saia do instalador ou desligue o computador antes de iniciar outro POST.")
	if pc.has("test_job"): return fail("Aguarde o teste de componente em andamento.")
	if float(pc.boot_remaining) > 0: return fail("Aguarde o POST em andamento.")
	var reason := assembly_power_block_reason(pc_id)
	if not reason.is_empty(): return fail(reason)
	_begin_post(pc)
	return done("POST iniciado. Aguarde a verificação dos componentes instalados.", "power_on")


func _begin_post(pc: Dictionary) -> void:
	pc.power = true
	pc.boot_ok = false
	pc.boot_remaining = 1.2
	pc.boot_result = "Executando POST…"


func prepare_install_usb() -> bool:
	if state.get("install_usb_ready", false): return fail("O pendrive da oficina já está pronto.")
	state.install_usb_ready = true
	return done("Pendrive de instalação do TechOS pronto para usar na bancada.")


func toggle_install_usb(pc_id: String) -> bool:
	var pc := item(pc_id)
	if pc.get("location") != "bench": return fail("Coloque um computador na bancada.")
	if not state.get("install_usb_ready", false): return fail("Prepare o pendrive no TechOS da oficina.")
	var installation: Dictionary = pc.get("installation", {})
	if installation.get("phase") == "copying": return fail("Aguarde o término da instalação para retirar o pendrive.")
	if not pc.get("install_usb", false):
		pc.install_usb = true
		return done("Pendrive de instalação conectado.", "cable_click")
	pc.erase("install_usb")
	if installation.get("phase") == "setup":
		pc.erase("installation")
		_begin_post(pc)
	elif installation.get("phase") == "complete":
		pc.boot_result = "TechOS instalado. Reinicie pelo disco."
	return done("Pendrive de instalação retirado.", "cable_click")


func can_boot_install_usb(pc_id: String) -> bool:
	var pc := item(pc_id)
	return pc.get("location") == "bench" and pc.get("install_usb", false) and pc.power \
		and float(pc.boot_remaining) == 0.0 and not pc.has("installation") and not pc.has("test_job") \
		and (pc.boot_ok or pc.boot_result == NO_BOOT_SYSTEM)


func boot_install_usb(pc_id: String) -> bool:
	if not can_boot_install_usb(pc_id): return fail("Conecte o pendrive e aguarde um POST bem-sucedido.")
	var reason := _post_failure(pc_id)
	if not reason.is_empty(): return fail(reason)
	var pc := item(pc_id)
	var disk := boot_drive(pc_id, false)
	if disk.is_empty(): return fail("Nenhum disco SATA reconhecido para instalar o TechOS.")
	pc.installation = {"phase": "setup", "disk": disk.id}
	pc.boot_ok = false
	pc.boot_result = "Instalador do TechOS iniciado pelo pendrive."
	return done(pc.boot_result)


func start_os_install(pc_id: String, disk_id: String, overwrite: bool) -> bool:
	var pc := item(pc_id)
	var installation: Dictionary = pc.get("installation", {})
	if installation.get("phase") != "setup" or not pc.get("install_usb", false) or not pc.get("power", false):
		return fail("Inicie pelo pendrive antes de instalar o TechOS.")
	if disk_id.is_empty() or storage_status(pc_id, drive_slot(pc, disk_id)) != "recognized":
		return fail("Selecione o disco instalado e reconhecido neste computador.")
	var reason := _post_failure(pc_id)
	if not reason.is_empty(): return fail(reason)
	var disk := item(disk_id)
	if disk.get("bootable", false) and not overwrite:
		return fail("Confirme a substituição do sistema que já está no disco.")
	installation.disk = disk_id
	installation.phase = "copying"
	installation.remaining = INSTALL_DURATION
	pc.boot_result = "Instalando o TechOS no disco…"
	return done(pc.boot_result)


func restart_after_install(pc_id: String) -> bool:
	var pc := item(pc_id)
	if pc.get("installation", {}).get("phase") != "complete":
		return fail("Conclua a instalação antes de reiniciar.")
	if pc.get("install_usb", false): return fail("Retire o pendrive antes de reiniciar pelo disco.")
	pc.erase("installation")
	_begin_post(pc)
	return done("Reiniciando pelo disco.", "power_on")


func _finish_os_install(pc: Dictionary) -> void:
	var disk := item(pc.installation.disk)
	var reason := _post_failure(pc.id)
	if not reason.is_empty() or storage_status(pc.id, drive_slot(pc, disk.get("id", ""))) != "recognized":
		pc.installation.phase = "setup"
		pc.installation.erase("remaining")
		pc.boot_result = "A instalação foi interrompida. Verifique o disco e os componentes."
		done(pc.boot_result, "boot_fail")
		return
	disk.bootable = true
	disk.system = "TechOS"
	disk.model = str(disk.model).trim_suffix(" · sem sistema")
	disk.client_apps = []
	pc.erase("client_apps")
	pc.erase("service_post")
	pc.installation.phase = "complete"
	pc.installation.erase("remaining")
	pc.boot_result = "TechOS instalado. Retire o pendrive e reinicie pelo disco."
	done(pc.boot_result, "boot_ok")


func client_apps(pc_id: String) -> Array:
	var pc := item(pc_id)
	var disk := boot_drive(pc_id)
	if disk.is_empty():
		for slot in STORAGE_SLOTS:
			var part := item(pc.get("components", {}).get(slot, ""))
			if part.get("bootable", false):
				disk = part
				break
	var system_record := disk if disk.get("system") == "TechOS" else pc
	return system_record.get("client_apps", [])


func install_client_app(pc_id: String, app: String) -> void:
	var pc := item(pc_id)
	if not pc.get("boot_ok", false) or app not in ClientApps.OPTIONAL or app in client_apps(pc_id): return
	var disk := boot_drive(pc_id)
	var system_record := disk if disk.get("system") == "TechOS" else pc
	system_record.client_apps = client_apps(pc_id) + [app]
	done("Aplicativo instalado no TechOS.")


func storage_description(disk: Dictionary) -> String:
	var model := str(disk.get("model", "")).trim_suffix(" · sem sistema")
	var hdd := Peripherals.hdd(disk)
	return model if hdd.is_empty() else "%s · %s" % [hdd.model, Peripherals.capacity_label(hdd.capacity_gb)]


func drive_count(pc: Dictionary) -> int:
	var components: Dictionary = pc.get("components", {})
	return int(components.has("storage")) + int(components.has("storage2"))


func drive_slot(pc: Dictionary, disk_id: String) -> String:
	for slot in STORAGE_SLOTS:
		if pc.components.get(slot) == disk_id: return slot
	return ""


func boot_drive(pc_id: String, require_system: bool = true, assume_power: bool = false) -> Dictionary:
	var pc := item(pc_id)
	for slot in STORAGE_SLOTS:
		if storage_status(pc_id, slot, assume_power) != "recognized": continue
		var disk := item(pc.components[slot])
		if not require_system or disk.get("bootable", false): return disk
	return {}


func installation_targets(pc_id: String) -> Array:
	var pc := item(pc_id)
	var disks: Array = []
	for slot in STORAGE_SLOTS:
		if storage_status(pc_id, slot) == "recognized": disks.append(item(pc.components[slot]))
	return disks


func storage_status(pc_id: String, slot: String = "storage", assume_power: bool = false) -> String:
	var pc := item(pc_id)
	var disk := item(pc.get("components", {}).get(slot, ""))
	if disk.is_empty(): return "missing"
	if (not assume_power and not pc.get("power", false)) or int(item(pc.components.get("psu", "")).get("health", 0)) < 15 or not _connected(pc, "psu", "chicote de energia") or not _connected(pc, slot, "SATA energia"):
		return "no_power"
	if not _connected(pc, slot, "SATA dados"): return "no_data"
	if false in pc.get("mounts", {}).get(slot, {}).get("screws", []): return "unfixed"
	if int(disk.health) < 15: return "failed"
	return "recognized"


func _connected(pc: Dictionary, kind: String, plug: String) -> bool:
	return pc.get("mounts", {}).get(kind, {}).get("connections", {}).get(plug, pc.components.has(kind))


func _storage_problem(status: String) -> String:
	return {"no_power": "Armazenamento sem alimentação SATA.", "no_data": "Cabo SATA de dados desconectado; disco não reconhecido.", "failed": "Disco não reconhecido mesmo com os cabos conectados.", "unfixed": "Disco solto na baia.", "missing": "Armazenamento ausente."}.get(status, "")


func gpu_power_reason(pc: Dictionary) -> String:
	return Peripherals.power_reason(item(pc.components.get("gpu", "")), item(pc.components.get("psu", "")), item(pc.components.get("cpu", "")), drive_count(pc))


func _psu_supplies_power(pc: Dictionary) -> bool:
	if not pc.get("power", false): return false
	var psu := item(pc.components.get("psu", ""))
	return int(psu.get("health", 0)) >= 15 and _connected(pc, "psu", "chicote de energia")


func _board_receives_power(pc: Dictionary) -> bool:
	var board := item(pc.components.get("motherboard", ""))
	return int(board.get("health", 0)) >= 15 and _connected(pc, "motherboard", "ATX 24 pinos")


func _gpu_receives_power(pc: Dictionary, card: Dictionary) -> bool:
	return _connected(pc, "gpu", "trava PCIe") and gpu_power_reason(pc).is_empty() and (
		not gpu_has_auxiliary(card) or _connected(pc, "gpu", "energia"))


func gpu_rgb_active(pc_id: String) -> bool:
	var pc := item(pc_id)
	if not _psu_supplies_power(pc): return false
	var card := item(pc.components.get("gpu", ""))
	return Peripherals.gpu(card).get("rgb", false) and card.health >= 15 and (
		_board_receives_power(pc) and _gpu_receives_power(pc, card))


func graphics_profile(pc_id: String) -> Dictionary:
	var pc := item(pc_id)
	return Peripherals.performance(item(pc.components.get("gpu", "")), item(pc.components.get("motherboard", "")), item(pc.components.get("cpu", "")))


func fan_count(pc_id: String, kind: String) -> int:
	var pc := item(pc_id)
	if pc.is_empty(): return 0
	if kind == "case": return Cases.get_model(pc.get("case_key", "")).get("stock_fans", 1)
	var part := item(pc.components.get(kind, ""))
	if kind == "gpu": return Peripherals.gpu_profile(part).get("fans", 0)
	return int(not part.is_empty())


func fan_fault(part: Dictionary) -> String:
	if part.is_empty(): return ""
	if part.has("fan_fault"): return part.fan_fault
	if part.kind != "cooling": return ""
	if part.health < 15: return "stuck"
	if part.health < 35: return "irregular"
	if part.health < 55: return "slow"
	if part.health < 70: return "noisy"
	return ""


func fan_temperature(pc_id: String, kind: String) -> int:
	var pc := item(pc_id)
	var part := item(pc.components.get(kind, "")) if kind != "case" else pc
	var load: bool = pc.get("test_job", {}).get("kind") == kind
	var starting: bool = float(pc.get("boot_remaining", 0.0)) > 0
	var idle := 35 if kind == "gpu" else 40
	var under_load: int = Peripherals.gpu_profile(part).get("temp_c", 60) if kind == "gpu" else Hardware.cpu_spec(item(pc.components.get("cpu", ""))).get("temp_c", 60)
	var temp: int = under_load if load else 53 if starting else idle
	var fault := fan_fault(part)
	if fault in ["stuck", "unplugged"]: temp += 23
	elif fault in ["slow", "irregular"]: temp += 12
	if fan_fault(pc) in ["stuck", "unplugged"]: temp += 5
	return temp


func fan_speed(pc_id: String, kind: String, time: float = 0.0) -> float:
	var pc := item(pc_id)
	if not _psu_supplies_power(pc) or fan_count(pc_id, kind) == 0: return 0.0
	if kind != "psu" and not _board_receives_power(pc): return 0.0
	var part := pc if kind == "case" else item(pc.components.get(kind, ""))
	if kind == "cooling" and not _connected(pc, "cooling", "CPU FAN"): return 0.0
	if kind == "gpu" and not _gpu_receives_power(pc, part): return 0.0
	var fault := fan_fault(part)
	if fault in ["stuck", "unplugged"]: return 0.0
	var temp := fan_temperature(pc_id, kind)
	if kind == "gpu" and Peripherals.gpu_profile(part).get("zero_rpm", false) and temp < 50: return 0.0
	var speed: float = {"case": 2.2, "cooling": 3.6, "gpu": 3.8, "psu": 2.6}[kind]
	speed *= 1.0 + maxf(0.0, temp - 45.0) / 70.0
	if fault == "slow": speed *= 0.4
	if fault == "irregular": speed *= 0.45 + absf(sin(time * 5.4)) * 0.36
	return speed


func assembly_power_block_reason(pc_id: String) -> String:
	var pc := item(pc_id)
	if not pc.has("case_key") or pc.power: return ""
	for kind in ESSENTIAL_PARTS:
		if kind == "storage" and pc.components.has("storage2"): continue
		if not pc.components.has(kind):
			return Prefs.t("Instale o componente essencial antes de ligar: %s.") % Prefs.t(PART_NAMES[kind])
	var cpu := item(pc.components.cpu)
	var reason := Hardware.cpu_reason(item(pc.components.motherboard), cpu)
	if not reason.is_empty(): return reason
	if not _has_video_hardware(pc): return "GPU dedicada necessária para saída de vídeo."
	reason = gpu_power_reason(pc)
	if not reason.is_empty(): return reason
	var required := ESSENTIAL_PARTS.duplicate()
	if not pc.components.has("storage"): required.erase("storage")
	if pc.components.has("gpu"): required.append("gpu")
	for kind in required:
		var mount: Dictionary = pc.get("mounts", {}).get(kind, {})
		if kind == "storage" and not Peripherals.hdd(item(pc.components.storage)).is_empty():
			if mount.is_empty() or false in mount.screws: return "Fixe o HD na baia antes de ligar."
			continue
		if mount.is_empty() or false in mount.screws or false in mount.connections.values():
			return Prefs.t("Fixe e reconecte o componente antes de ligar: %s.") % Prefs.t(PART_NAMES[kind])
	return ram_configuration_reason(pc_id)


func evaluate_boot(pc_id: String) -> String:
	var reason := _post_failure(pc_id)
	if not reason.is_empty(): return reason
	if boot_drive(pc_id, true, true).is_empty():
		if boot_drive(pc_id, false, true).is_empty():
			var pc := item(pc_id)
			var slot := "storage" if pc.components.has("storage") else "storage2"
			return "POST concluído. " + _storage_problem(storage_status(pc_id, slot, true))
		return NO_BOOT_SYSTEM
	return "POST concluído. Sistema inicializado; componentes essenciais reconhecidos."


func _post_failure(pc_id: String) -> String:
	var pc := item(pc_id)
	if pc.has("mounts"):
		for kind in pc.components:
			if kind in Hardware.RAM_KEYS or kind in STORAGE_SLOTS: continue
			var mount: Dictionary = mounts(pc_id, kind)
			if false in mount.screws or false in mount.connections.values(): return "Falha no POST: fixe e reconecte " + PART_NAMES.get(kind, kind)
	for kind in ESSENTIAL_PARTS:
		if kind == "storage" and drive_count(pc) > 0: continue
		var part := item(pc.components.get(kind, ""))
		if part.is_empty(): return "Falha no POST: componente essencial ausente — " + kind
		if int(part.health) < 15:
			return "Falha no POST: erros detectados em " + kind + (". Saúde confirmada: %d%%." % part.health if part.tested else ". Condição exata ainda não avaliada.")
	var reason := Hardware.cpu_reason(item(pc.components.motherboard), item(pc.components.cpu))
	if not reason.is_empty(): return "Falha no POST: " + reason
	if not _has_video_hardware(pc): return "Falha no POST: GPU dedicada necessária para saída de vídeo."
	reason = gpu_power_reason(pc)
	if not reason.is_empty(): return "Falha no POST: " + reason
	reason = ram_configuration_reason(pc_id)
	if not reason.is_empty(): return "Falha no POST: " + reason
	for slot in ram_slots(pc_id):
		var ram := item(pc.components.get(Hardware.RAM_KEYS[slot], ""))
		if not ram.is_empty() and int(ram.health) < 45: return "Falha no POST: erros detectados em ram " + Hardware.RAM_LABELS[slot]
	var gpu := item(pc.components.get("gpu", ""))
	if not gpu.is_empty() and gpu_output(gpu) == "no_signal": return "Falha no POST: erros detectados em gpu."
	if not gpu.is_empty() and gpu_output(gpu) == "artifacts":
		return "POST com falha de vídeo: o monitor detectou artefatos e perda intermitente de sinal."
	return ""


func _has_video_hardware(pc: Dictionary) -> bool:
	return pc.components.has("gpu") or Hardware.has_integrated_graphics(item(pc.components.get("cpu", "")))


func gpu_output(gpu: Dictionary) -> String:
	var health := int(gpu.get("health", 0))
	if health < 15: return "no_signal"
	if health < 70: return "artifacts"
	return "stable"


func video_status(pc_id: String) -> String:
	var pc := item(pc_id)
	if not pc.get("power", false): return "off"
	if not _has_video_hardware(pc): return "no_signal"
	if not gpu_power_reason(pc).is_empty(): return "no_signal"
	if not Hardware.cpu_reason(item(pc.components.get("motherboard", "")), item(pc.components.get("cpu", ""))).is_empty(): return "no_signal"
	var video_parts := ["motherboard", "psu", "cpu"]
	if pc.components.has("gpu"): video_parts.append("gpu")
	for kind in video_parts:
		var part := item(pc.components.get(kind, ""))
		var mount: Dictionary = pc.get("mounts", {}).get(kind, {})
		var connections: Dictionary = mount.get("connections", {})
		if int(part.get("health", 0)) < 15 or false in connections.values(): return "no_signal"
	if not ram_configuration_reason(pc_id).is_empty(): return "no_signal"
	for ram in ram_modules(pc):
		if int(ram.health) < 45: return "no_signal"
	if float(pc.boot_remaining) > 0.85: return "sync"
	if pc.components.has("gpu") and gpu_output(item(pc.components.gpu)) == "artifacts": return "artifacts"
	if pc.get("test_job", {}).get("kind") == "gpu": return "pattern"
	if float(pc.boot_remaining) > 0: return "post"
	if pc.has("installation"): return "installer"
	return "desktop" if pc.boot_ok else "firmware"


func test_ram(pc_id: String) -> bool:
	var reason := ram_test_block_reason(pc_id)
	if not reason.is_empty(): return fail(reason)
	var pc := item(pc_id)
	var results: Array[String] = []
	for slot in ram_slots(pc_id):
		var ram := item(pc.components.get(Hardware.RAM_KEYS[slot], ""))
		if ram.is_empty(): continue
		ram.tested = true
		ram.test_result = "%s: %d%% · %s" % [Hardware.RAM_LABELS[slot], ram.health, condition_label(ram.health)]
		results.append(ram.test_result)
	pc.boot_result = evaluate_boot(pc_id)
	return done("Teste de memória concluído: "+"; ".join(results))


func ram_test_block_reason(pc_id: String) -> String:
	var pc := item(pc_id)
	if pc.is_empty() or pc.kind != "pc" or pc.location != "bench": return "Coloque um computador na bancada."
	if pc.has("installation"): return "Saia do instalador para testar o computador."
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
	for field in ["ddr", "capacity_gb", "speed_mt", "board_art", "board_format", "socket", "alternate_socket", "extra_socket", "size_mm", "slots"]:
		if product.has(field): part[field] = product[field]
	if product.kind in ["motherboard", "cpu", "gpu", "storage"]: part.catalog_key = key
	if not heat_spreader_color.is_empty():
		part.heat_spreader_color = heat_spreader_color
		part.model += " · " + heat_spreader_color
	if product.kind == "storage":
		part.bootable = false
		if not Peripherals.hdd(part).is_empty(): part.hours_used = 0.0
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
	return record.kind != "pc" or (record.has("case_key") and record.components.is_empty() and not record.get("install_usb", false))


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
				tested_part.test_result = "%s: %d%% · %s. %s" % [component_label(job.kind), tested_part.health, condition_label(tested_part.health), "Sem falhas detectadas nesta verificação." if tested_part.defects.is_empty() else ", ".join(tested_part.defects)]
				if job.kind in STORAGE_SLOTS and not Peripherals.hdd(tested_part).is_empty():
					var status := storage_status(record.id, job.kind)
					if status not in ["recognized", "failed"]: tested_part.tested = false
					tested_part.test_result = _hdd_report(tested_part, status)
					if status in ["recognized", "failed"] and tested_part.health < 42: Audio.play("hdd_click")
				if job.kind == "gpu":
					var output := gpu_output(tested_part)
					var observed: String = {"no_signal": "A placa não gera sinal.", "artifacts": "Artefatos e perda intermitente de sinal.", "stable": "Saída da placa estável."}[output]
					tested_part.test_result += " " + observed
					var profile := graphics_profile(record.id)
					if not profile.is_empty():
						tested_part.test_result += " PCIe %d x%d · %d pontos%s." % [profile.link, profile.lanes, profile.score, " (limitado pelo processador)" if profile.cpu_limit else ""]
				if job.kind in ["gpu", "cooling", "psu"]:
					tested_part.test_result += " Temperatura simulada: %d °C." % fan_temperature(record.id, job.kind)
					var fault := fan_fault(tested_part)
					if not fault.is_empty():
						tested_part.test_result += " " + {"stuck": "Ventoinha travada.", "slow": "Ventoinha com rotação baixa.", "irregular": "Rotação irregular.", "noisy": "Ruído anormal na ventoinha.", "unplugged": "Ventoinha desconectada."}[fault]
						if fault == "noisy" and fan_speed(record.id, job.kind) > 0: Audio.play("fan_rattle")
				record.erase("test_job")
				done(tested_part.test_result)
		if record.kind == "pc" and record.power:
			for slot in STORAGE_SLOTS:
				var disk := item(record.components.get(slot, ""))
				if not Peripherals.hdd(disk).is_empty() and disk.health >= 15 and storage_status(record.id, slot) in ["recognized", "no_data"]:
					var previous: float = disk.get("hours_used", 0.0)
					disk.hours_used = previous + delta / 60.0
					var wear := floori(disk.hours_used / 500.0) - floori(previous / 500.0)
					if wear > 0: disk.health = maxi(0, int(disk.health) - wear)
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
		elif record.kind == "pc" and record.get("installation", {}).get("phase") == "copying":
			var installation: Dictionary = record.installation
			installation.remaining = maxf(0.0, float(installation.remaining) - delta)
			if installation.remaining == 0.0: _finish_os_install(record)
	Mail.tick(self, delta)


func _hdd_report(disk: Dictionary, status: String) -> String:
	if status == "failed": return "HD não reconhecido com os cabos conectados. Verifique ruído mecânico, falha de leitura e partida do motor."
	if status != "recognized": return _storage_problem(status)
	var spec := Peripherals.hdd(disk)
	var health := int(disk.health)
	var bad_sectors := maxi(0, 75 - health) * 3
	var rate := clampf(health / 90.0, 0.25, 1.0)
	var symptoms := "Leitura e escrita estáveis."
	if health < 75: symptoms = "Leitura lenta com setores defeituosos."
	if health < 42: symptoms = "Erros de leitura e estalos mecânicos durante a verificação."
	return "%s · Saúde %d%% · %d °C · %.1f h · %d setores defeituosos · %d/%d MB/s. %s" % [
		"Inicializável" if disk.get("bootable", false) else "Reconhecido, sem sistema",
		health, spec.temp_c + (100 - health) / 8, disk.get("hours_used", 0.0),
		bad_sectors, roundi(spec.read_mb * rate), roundi(spec.write_mb * rate), symptoms]


static func component_label(kind: String) -> String:
	return "Armazenamento · SATA 2" if kind == "storage2" else PART_NAMES.get(kind, kind)


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
	if not candidate.get("install_usb_ready", false) is bool: return false
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
		if r.has("system") and (r.kind != "storage" or r.system != "TechOS" or r.get("bootable") != true): return false
		if r.has("client_apps"):
			if r.kind != "pc" and r.get("system") != "TechOS": return false
			if not r.client_apps is Array: return false
			var installed := {}
			for app in r.client_apps:
				if app not in ClientApps.OPTIONAL or installed.has(app): return false
				installed[app] = true
		if r.has("install_usb"):
			if r.install_usb != true or r.kind != "pc" or r.location != "bench" or not candidate.get("install_usb_ready", false): return false
		if r.has("installation") and (r.kind != "pc" or not _valid_installation(candidate.items, r)): return false
		if r.kind in ["ram", "motherboard"] and r.get("ddr", "") not in Hardware.DDR_TYPES: return false
		if r.has("catalog_key") and (r.kind not in ["cpu", "motherboard", "gpu", "storage"] or not r.catalog_key is String): return false
		if r.has("slots") and (r.kind != "gpu" or not numeric(r.slots) or int(r.slots) != r.slots or r.slots < 1 or r.slots > 4): return false
		if r.has("hours_used") and (Peripherals.hdd(r).is_empty() or not numeric(r.hours_used) or r.hours_used < 0): return false
		if r.has("fan_fault") and (r.kind not in ["cooling", "gpu", "psu", "pc"] or r.fan_fault not in ["stuck", "slow", "irregular", "noisy", "unplugged"]): return false
		for field in ["socket", "alternate_socket", "extra_socket"]:
			if r.has(field) and not r[field] is String: return false
		for field in ["capacity_gb", "speed_mt"]:
			if not r.has(field): continue
			if r.kind != "ram" and not (field == "capacity_gb" and not Peripherals.hdd(r).is_empty()): return false
			if not numeric(r[field]) or r[field] <= 0 or r[field] != int(r[field]): return false
		if r.has("size_mm") and (not Cases.CLEARANCES.has(r.kind) or not numeric(r.size_mm) or r.size_mm <= 0 or r.size_mm != int(r.size_mm)): return false
		if r.has("board_format") and (r.kind != "motherboard" or r.board_format not in Cases.FORMATS): return false
		if r.has("stored_ram_latches"):
			if r.kind != "motherboard" or r.location == "installed" or not r.stored_ram_latches is Dictionary: return false
			for field in r.stored_ram_latches:
				if field not in Hardware.LATCH_KEYS or not _valid_ram_clips(r.stored_ram_latches[field]): return false
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
			for flag in ["gpu_bracket_open", "gpu_slot_open"]:
				if r.has(flag) and not r[flag] is bool: return false
			for field in Hardware.LATCH_KEYS:
				if not r.has(field): continue
				if not _valid_ram_clips(r[field]): return false
			if r.has("test_job"):
				var job: Variant = r.test_job
				if not job is Dictionary or not numeric(job.get("remaining")) or job.remaining < 0 or not FASTENERS.has(job.get("kind")): return false
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
				if child.get("kind") != ("ram" if kind in Hardware.RAM_KEYS else "storage" if kind in STORAGE_SLOTS else kind) or child.get("location") != "installed" or child.get("owner_pc") != id: return false
				if not case_model.is_empty() and not _valid_assembly_part(candidate.items, r, case_model, kind, child): return false
				referenced[child_id] = id
	for id in candidate.items:
		var record: Dictionary = candidate.items[id]
		if record.location == "installed" and not referenced.has(id): return false
		if record.kind != "pc": continue
		var board: Dictionary = candidate.items.get(record.components.get("motherboard", ""), {})
		var cpu: Dictionary = candidate.items.get(record.components.get("cpu", ""), {})
		var slots := Hardware.slot_order(board)
		for slot in range(Hardware.RAM_KEYS.size()):
			if record.components.has(Hardware.RAM_KEYS[slot]) and slot not in slots: return false
		if not Hardware.memory_reason(board, cpu, _ram_modules(candidate.items, record)).is_empty(): return false
	if not Orders.valid(candidate): return false
	if not Mail.valid(candidate): return false
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


static func _valid_ram_clips(clips: Variant) -> bool:
	return clips is Array and clips.size() == 2 and clips[0] is bool and clips[1] is bool


static func _valid_installation(items: Dictionary, pc: Dictionary) -> bool:
	var installation: Variant = pc.installation
	if not installation is Dictionary or pc.location != "bench" or pc.get("power") != true: return false
	if pc.get("boot_ok") != false or pc.get("boot_remaining") != 0 or pc.has("test_job"): return false
	if not pc.get("components") is Dictionary or not installation.get("disk") is String: return false
	if pc.components.get("storage") != installation.disk and pc.components.get("storage2") != installation.disk: return false
	var disk: Variant = items.get(installation.disk)
	if not disk is Dictionary or disk.get("kind") != "storage": return false
	match installation.get("phase"):
		"setup":
			return pc.get("install_usb", false) == true and not installation.has("remaining")
		"copying":
			return pc.get("install_usb", false) == true and numeric(installation.get("remaining")) \
				and installation.remaining > 0 and installation.remaining <= INSTALL_DURATION
		"complete":
			return disk.get("system") == "TechOS" and not installation.has("remaining")
	return false


func _valid_assembly_part(items: Dictionary, pc: Dictionary, case_model: Dictionary, kind: String, part: Dictionary) -> bool:
	if part.get("packaged") != false or (not FASTENERS.has(kind) and kind not in Hardware.RAM_KEYS): return false
	if kind not in Hardware.RAM_KEYS and not pc.get("mounts", {}).has(kind): return false
	if not Cases.fit_reason(case_model, part).is_empty(): return false
	if kind == "motherboard": return true
	if kind in STORAGE_SLOTS: return _drive_fit_reason(items, pc, kind, part).is_empty()
	if kind == "psu": return true
	var board_id: Variant = pc.components.get("motherboard")
	if not board_id is String: return false
	var board: Variant = items.get(board_id)
	if not board is Dictionary: return false
	if kind == "gpu": return Peripherals.board_bus(board)[0] > 0
	if kind in Hardware.RAM_KEYS: return part.get("ddr") == board.get("ddr")
	if kind == "cpu": return Hardware.cpu_reason(board, part).is_empty()
	if kind == "cooling" and not pc.components.has("cpu"): return false
	var board_socket: Variant = board.get("socket", "TR4")
	return board_socket is String and Hardware.socket(board_socket) in mounting_sockets(part)


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


func available_parts(kind: String = "", include_boxed_cabinet: bool = false) -> Array:
	var result: Array = []
	for record in state.items.values():
		if record.kind == "pc" or (not kind.is_empty() and record.kind != kind): continue
		if record.location not in BENCH_PART_LOCATIONS: continue
		if not record.packaged or (include_boxed_cabinet and record.location == "shelf"): result.append(record.id)
	return result


func _drive_fit_reason(items: Dictionary, pc: Dictionary, slot: String, part: Dictionary) -> String:
	var is_hdd := not Peripherals.hdd(part).is_empty()
	var case_model := Cases.get_model(pc.get("case_key", ""))
	var bay_limit: int = case_model.get("drives_35" if is_hdd else "drives_25", 1)
	var bays_used := 0
	var ports_used := 0
	for other in STORAGE_SLOTS:
		if other == slot: continue
		var drive: Dictionary = items.get(pc.components.get(other, ""), {})
		if drive.is_empty(): continue
		ports_used += 1
		if is_hdd == (not Peripherals.hdd(drive).is_empty()): bays_used += 1
	if bays_used >= bay_limit:
		return "Não há baia de %s″ livre neste gabinete." % ("3,5" if is_hdd else "2,5")
	var board: Dictionary = items.get(pc.components.get("motherboard", ""), {})
	if not board.is_empty() and ports_used >= int(Peripherals.board_bus(board)[1]):
		return "Não há porta SATA livre na placa-mãe."
	return ""


func operate_gpu_bay(pc_id: String, action: String) -> bool:
	if not safe_to_work(pc_id): return false
	var pc := item(pc_id)
	if pc.lid: return fail("Retire a tampa lateral.")
	if pc.components.has("gpu"): return fail("Retire a placa de vídeo antes de operar a baia vazia.")
	if action == "bracket":
		if pc.tool != "phillips": return fail("Use a Phillips para remover ou recolocar a proteção traseira.")
		pc.gpu_bracket_open = not pc.get("gpu_bracket_open", false)
		return done("Proteção traseira removida." if pc.gpu_bracket_open else "Proteção traseira recolocada.", "screw")
	if not pc.components.has("motherboard"): return fail("Instale a placa-mãe antes de abrir a trava PCIe.")
	if pc.tool != "hands": return fail("Use Mãos para operar a trava do PCIe.")
	pc.gpu_slot_open = not pc.get("gpu_slot_open", false)
	return done("Trava PCIe aberta." if pc.gpu_slot_open else "Trava PCIe fechada.", "latch")


func gpu_has_auxiliary(card: Dictionary) -> bool:
	return not Peripherals.gpu_profile(card).get("plugs", []).is_empty()


func operate_mount(pc_id: String, kind: String, action: String, index: int) -> bool:
	if not safe_to_work(pc_id): return false
	var pc := item(pc_id)
	if pc.lid: return fail("Retire a tampa para acessar as fixações.")
	if not FASTENERS.has(kind): return false
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
		if kind == "gpu" and connector == "energia" and not gpu_has_auxiliary(item(pc.components.gpu)): return false
		if kind == "gpu" and connector == "energia" and not mount.connections.energia:
			var reason := gpu_power_reason(pc)
			if not reason.is_empty(): return fail(reason)
		mount.connections[connector] = not mount.connections[connector]
		if mount.connections[connector] and connector not in ["socket", "trava PCIe"]:
			cue = "cable_click"
	pc.boot_ok = false
	return done("%s: %s atualizado. Desligado durante toda a desmontagem." % [component_label(kind), "parafuso" if action == "screw" else "conector / trava"], cue)


func use_component(pc_id: String, kind: String, selected_id: String) -> bool:
	if kind == "ram": return use_ram_slot(pc_id, selected_id)
	if not safe_to_work(pc_id): return false
	var pc := item(pc_id)
	if pc.lid: return fail("Retire a tampa lateral.")
	if pc.tool != "hands": return fail("Selecione Mãos (1) para manusear peças.")
	if not FASTENERS.has(kind): return false
	var installed: String = pc.components.get(kind, "")
	if kind == "cpu" and pc.components.has("cooling"): return fail("Retire o cooler antes do processador; o processador usa socket, sem parafusos.")
	if kind == "motherboard":
		for child in ["cpu", "gpu", "cooling"] + Hardware.RAM_KEYS:
			if pc.components.has(child): return fail("Retire CPU, cooler, RAM e GPU antes de retirar a placa-mãe.")
	if installed != "":
		var mount := mounts(pc_id, kind)
		if true in mount.screws: return fail("Solte os %d parafuso(s) restantes de %s." % [mount.screws.count(true), component_label(kind)])
		var locked: Dictionary = mount.connections.duplicate()
		if kind == "gpu" and not gpu_has_auxiliary(item(installed)): locked.erase("energia")
		if true in locked.values(): return fail("Libere os conectores / travas de " + component_label(kind) + ": " + ", ".join(locked.keys()))
		var destination := "tray" if at("tray").size() < 4 else "inventory"
		if destination == "inventory" and at("inventory").size() >= INVENTORY_CAPACITY: return fail("Bandeja e inventário cheios. Guarde peças no armário.")
		_release_installed_part(installed, destination)
		pc.components.erase(kind)
		if kind == "gpu" and not Peripherals.gpu(item(installed)).is_empty(): pc.gpu_slot_open = true
		if kind == "motherboard":
			var stored := {}
			for field in Hardware.LATCH_KEYS:
				if pc.has(field) and false in pc[field]: stored[field] = pc[field]
				pc.erase(field)
			pc.latches = [true, true]
			if not stored.is_empty(): item(installed).stored_ram_latches = stored
		pc.mounts.erase(kind)
		pc.boot_ok = false
		return done(component_label(kind) + " retirada para " + ("a bandeja." if destination == "tray" else "o inventário."))
	var expected := "storage" if kind in STORAGE_SLOTS else kind
	if selected_id not in available_parts() or item(selected_id).kind != expected: return fail("Selecione uma peça compatível no inventário da inspeção.")
	var part := item(selected_id)
	var board := item(pc.components.get("motherboard", ""))
	if pc.has("case_key"):
		var fit := Cases.fit_reason(Cases.get_model(pc.case_key), part)
		if not fit.is_empty(): return fail(fit)
	if kind in ["cpu", "ram", "gpu", "cooling"] and board.is_empty(): return fail("Instale a placa-mãe primeiro.")
	if kind in STORAGE_SLOTS:
		var reason := _drive_fit_reason(state.items, pc, kind, part)
		if not reason.is_empty(): return fail(reason)
	if kind == "gpu" and not Peripherals.gpu(part).is_empty():
		if int(Peripherals.board_bus(board)[0]) == 0: return fail("A placa-mãe precisa de um slot PCI Express disponível.")
		if not pc.get("gpu_bracket_open", false): return fail("Remova a proteção traseira do gabinete com a Phillips.")
		if not pc.get("gpu_slot_open", false): return fail("Abra a trava do slot PCIe com Mãos antes de encaixar a GPU.")
	if kind == "cooling" and not pc.components.has("cpu"): return fail("Encaixe o processador antes do cooler.")
	if kind == "cpu":
		var reason := Hardware.cpu_reason(board, part)
		if reason.is_empty(): reason = Hardware.memory_reason(board, part, ram_modules(pc))
		if not reason.is_empty(): return fail(reason)
	if kind == "cooling":
		var board_socket := Hardware.socket(board.get("socket", "TR4"))
		var sockets := mounting_sockets(part)
		if board_socket not in sockets:
			return fail("Socket incompatível: a peça usa %s e a placa-mãe usa %s." % [" / ".join(sockets), board_socket])
	var mount := mounts(pc_id, kind)
	if kind == "gpu" and not gpu_has_auxiliary(part): mount.connections.energia = true
	part.location = "installed"
	part.owner_pc = pc_id
	pc.components[kind] = selected_id
	if kind == "motherboard" and part.has("stored_ram_latches"):
		pc.merge(part.stored_ram_latches, true)
		part.erase("stored_ram_latches")
	pc.boot_ok = false
	return done(component_label(kind) + " encaixada. Reconecte e fixe todos os pontos destacados.")


func _release_installed_part(id: String, destination: String) -> void:
	var part := item(id)
	part.location = destination
	part.owner_pc = ""
	if destination == "inventory":
		part.inventory_slot = _free_inventory_slot(id)


func mounting_sockets(part: Dictionary) -> PackedStringArray:
	var sockets := PackedStringArray([Hardware.socket(part.get("socket", "TR4"))])
	for field in ["alternate_socket", "extra_socket"]:
		if part.has(field): sockets.append(Hardware.socket(part[field]))
	return sockets


func test_component(pc_id: String, kind: String) -> bool:
	if kind == "ram": return test_ram(pc_id)
	var reason := component_test_block_reason(pc_id, kind)
	if not reason.is_empty(): return fail(reason)
	var pc := item(pc_id)
	var part := item(pc.components.get(kind, ""))
	pc.test_job = {"kind": kind, "part_id": part.id, "remaining": 1.8}
	return done("Teste de %s iniciado. Aguarde a verificação da bancada." % component_label(kind))


func component_test_block_reason(pc_id: String, kind: String) -> String:
	var pc := item(pc_id)
	if pc.is_empty() or pc.location != "bench": return "Coloque um computador na bancada."
	if pc.has("installation"): return "Saia do instalador para testar o computador."
	if pc.has("test_job"): return "Teste em andamento. Aguarde ou desligue o PC para cancelar."
	if not pc.power or float(pc.boot_remaining) > 0: return "Ligue o computador e aguarde o POST antes do teste."
	var part := item(pc.components.get(kind, ""))
	if part.is_empty(): return "Componente não instalado: " + PART_NAMES.get(kind, kind)
	for dependency in ["motherboard", "psu"]:
		if dependency == kind: continue
		var support := item(pc.components.get(dependency, ""))
		if support.is_empty() or int(support.health) < 15: return "Teste bloqueado pela alimentação/placa-mãe: " + PART_NAMES[dependency]
	if kind in STORAGE_SLOTS and not Peripherals.hdd(part).is_empty(): return ""
	var mount := mounts(pc_id, kind)
	if false in mount.screws or false in mount.connections.values(): return "Fixe e reconecte a peça antes do teste."
	return ""

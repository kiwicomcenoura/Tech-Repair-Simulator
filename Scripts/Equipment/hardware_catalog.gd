extends RefCounted

const BOARDS := [
	{"key": "amdera_a320m",
		"kind": "motherboard", "model": "Amdera A320M", "brand": "Amdera",
		"socket": "AM4", "ddr": "DDR4",
		"slot_count": 2, "max_memory_gb": 32, "board_format": "micro-ATX", "price": 220, "max_memory_mt": 3200,
		"cpu_families": ["a100", "a200", "a300", "a500"],
		"board_art": "amdera", "pcb": "435a3b", "accent": "9ca777", "condition": "Nova"},
	{"key": "amdera_b450m",
		"kind": "motherboard", "model": "Amdera B450M", "brand": "Amdera",
		"socket": "AM4", "ddr": "DDR4",
		"slot_count": 4, "max_memory_gb": 64, "board_format": "micro-ATX", "price": 350, "max_memory_mt": 3600,
		"cpu_families": ["a100", "a200", "a300", "a500", "a500_high"],
		"board_art": "amdera", "pcb": "284357", "accent": "5fabbe", "condition": "Nova"},
	{"key": "amdera_ax550",
		"kind": "motherboard", "model": "Amdera AX550 · ATX", "brand": "Amdera",
		"socket": "AM4", "ddr": "DDR4",
		"slot_count": 4, "max_memory_gb": 128, "board_format": "ATX", "price": 290, "max_memory_mt": 3600,
		"cpu_families": ["a300", "a500", "a500_high"],
		"board_art": "amdera", "pcb": "263c32", "accent": "dc7c45", "condition": "Nova"},
	{"key": "amdera_b550_pro",
		"kind": "motherboard", "model": "Amdera B550 Pro", "brand": "Amdera",
		"socket": "AM4", "ddr": "DDR4",
		"slot_count": 4, "max_memory_gb": 128, "board_format": "ATX", "price": 590, "max_memory_mt": 4000,
		"cpu_families": ["a300", "a500", "a500_high"],
		"board_art": "amdera", "pcb": "546469", "accent": "dbe3df", "condition": "Nova"},
	{"key": "amdera_x570_elite",
		"kind": "motherboard", "model": "Amdera X570 Elite", "brand": "Amdera",
		"socket": "AM4", "ddr": "DDR4",
		"slot_count": 4, "max_memory_gb": 128, "board_format": "ATX", "price": 890, "max_memory_mt": 4400,
		"cpu_families": ["a300", "a500", "a500_high"],
		"board_art": "amdera", "pcb": "332941", "accent": "ae78c5", "condition": "Nova"},
	{"key": "amdera_a620m",
		"kind": "motherboard", "model": "Amdera A620M", "brand": "Amdera",
		"socket": "AM5", "ddr": "DDR5",
		"slot_count": 2, "max_memory_gb": 96, "board_format": "micro-ATX", "price": 650, "max_memory_mt": 5600,
		"cpu_families": ["a700", "a900"],
		"board_art": "amdera", "pcb": "45452c", "accent": "b9ae58", "condition": "Nova"},
	{"key": "amdera_b650_gaming",
		"kind": "motherboard", "model": "Amdera B650 Gaming", "brand": "Amdera",
		"socket": "AM5", "ddr": "DDR5",
		"slot_count": 4, "max_memory_gb": 192, "board_format": "ATX", "price": 990, "max_memory_mt": 6400,
		"cpu_families": ["a700", "a900"],
		"board_art": "amdera", "pcb": "413037", "accent": "e87861", "condition": "Nova"},
	{"key": "amdera_x670_elite",
		"kind": "motherboard", "model": "Amdera X670 Elite", "brand": "Amdera",
		"socket": "AM5", "ddr": "DDR5",
		"slot_count": 4, "max_memory_gb": 192, "board_format": "ATX", "price": 1490, "max_memory_mt": 6800,
		"cpu_families": ["a700", "a900"],
		"board_art": "amdera", "pcb": "25464b", "accent": "69cfbd", "condition": "Nova"},
	{"key": "intara_h61_classic",
		"kind": "motherboard", "model": "Intara H61 Classic", "brand": "Intara",
		"socket": "LGA1155", "ddr": "DDR3",
		"slot_count": 2, "max_memory_gb": 16, "board_format": "micro-ATX", "price": 150, "max_memory_mt": 1600,
		"cpu_families": ["i3"],
		"board_art": "intara", "pcb": "34533a", "accent": "c1a362", "condition": "Nova"},
	{"key": "intara_b75m",
		"kind": "motherboard", "model": "Intara B75M", "brand": "Intara",
		"socket": "LGA1155", "ddr": "DDR3",
		"slot_count": 4, "max_memory_gb": 32, "board_format": "micro-ATX", "price": 220, "max_memory_mt": 1600,
		"cpu_families": ["i3"],
		"board_art": "intara", "pcb": "315568", "accent": "7bc6b6", "condition": "Nova"},
	{"key": "intara_h110m",
		"kind": "motherboard", "model": "Intara H110M", "brand": "Intara",
		"socket": "LGA1151", "ddr": "DDR4",
		"slot_count": 2, "max_memory_gb": 32, "board_format": "micro-ATX", "price": 270, "max_memory_mt": 2133,
		"cpu_families": ["i6"],
		"board_art": "intara", "pcb": "373f43", "accent": "9eabb2", "condition": "Nova"},
	{"key": "intara_b360m",
		"kind": "motherboard", "model": "Intara B360M", "brand": "Intara",
		"socket": "LGA1151", "ddr": "DDR4",
		"slot_count": 4, "max_memory_gb": 64, "board_format": "micro-ATX", "price": 340, "max_memory_mt": 2666,
		"cpu_families": ["i9"],
		"board_art": "intara", "pcb": "293650", "accent": "78a5da", "condition": "Nova"},
	{"key": "intara_h510m",
		"kind": "motherboard", "model": "Intara H510M", "brand": "Intara",
		"socket": "LGA1200", "ddr": "DDR4",
		"slot_count": 2, "max_memory_gb": 64, "board_format": "micro-ATX", "price": 410, "max_memory_mt": 3200,
		"cpu_families": ["i10", "i11"],
		"board_art": "intara", "pcb": "31534b", "accent": "86bcb0", "condition": "Nova"},
	{"key": "intara_ix610",
		"kind": "motherboard", "model": "Intara IX610 · micro-ATX", "brand": "Intara",
		"socket": "LGA1700", "ddr": "DDR4",
		"slot_count": 2, "max_memory_gb": 64, "board_format": "micro-ATX", "price": 310, "max_memory_mt": 3200,
		"cpu_families": ["i12", "i13"],
		"board_art": "intara", "pcb": "293b55", "accent": "639fd4", "condition": "Nova"},
	{"key": "intara_b660m",
		"kind": "motherboard", "model": "Intara B660M", "brand": "Intara",
		"socket": "LGA1700", "ddr": "DDR4",
		"slot_count": 4, "max_memory_gb": 128, "board_format": "micro-ATX", "price": 650, "max_memory_mt": 3600,
		"cpu_families": ["i12", "i13"],
		"board_art": "intara", "pcb": "35334c", "accent": "a69bed", "condition": "Nova"},
	{"key": "intara_z790_ultra",
		"kind": "motherboard", "model": "Intara Z790 Ultra", "brand": "Intara",
		"socket": "LGA1700", "ddr": "DDR5",
		"slot_count": 4, "max_memory_gb": 192, "board_format": "ATX", "price": 1450, "max_memory_mt": 6800,
		"cpu_families": ["i12", "i13"],
		"board_art": "intara", "pcb": "55536b", "accent": "d9b9e5", "condition": "Nova"},
]

const CPUS := [
	{"key": "amdera_r3_1200",
		"kind": "cpu", "model": "Amdera R3 1200", "brand": "Amdera",
		"socket": "AM4",
		"generation": "1000", "family": "a100",
		"cores": 4, "threads": 4,
		"base_ghz": 3.1, "turbo_ghz": 3.4,
		"tdp_w": 65, "draw_w": 76,
		"integrated_graphics": false, "temp_c": 58, "performance": 35, "price": 120,
		"ddr_legacy_mt": 2666, "ddr5_mt": 0, "max_memory_gb": 64, "condition": "Novo"},
	{"key": "amdera_r5_1600",
		"kind": "cpu", "model": "Amdera R5 1600", "brand": "Amdera",
		"socket": "AM4",
		"generation": "1000", "family": "a200",
		"cores": 6, "threads": 12,
		"base_ghz": 3.2, "turbo_ghz": 3.6,
		"tdp_w": 65, "draw_w": 88,
		"integrated_graphics": false, "temp_c": 64, "performance": 47, "price": 200,
		"ddr_legacy_mt": 2666, "ddr5_mt": 0, "max_memory_gb": 64, "condition": "Novo"},
	{"key": "amdera_r3_3100",
		"kind": "cpu", "model": "Amdera R3 3100", "brand": "Amdera",
		"socket": "AM4",
		"generation": "3000", "family": "a300",
		"cores": 4, "threads": 8,
		"base_ghz": 3.6, "turbo_ghz": 3.9,
		"tdp_w": 65, "draw_w": 78,
		"integrated_graphics": false, "temp_c": 57, "performance": 48, "price": 250,
		"ddr_legacy_mt": 3200, "ddr5_mt": 0, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "amdera_r5_3600",
		"kind": "cpu", "model": "Amdera R5 3600", "brand": "Amdera",
		"socket": "AM4",
		"generation": "3000", "family": "a300",
		"cores": 6, "threads": 12,
		"base_ghz": 3.6, "turbo_ghz": 4.2,
		"tdp_w": 65, "draw_w": 88,
		"integrated_graphics": false, "temp_c": 68, "performance": 63, "price": 390,
		"ddr_legacy_mt": 3200, "ddr5_mt": 0, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "amdera_r5_5600",
		"kind": "cpu", "model": "Amdera R5 5600", "brand": "Amdera",
		"socket": "AM4",
		"generation": "5000", "family": "a500",
		"cores": 6, "threads": 12,
		"base_ghz": 3.5, "turbo_ghz": 4.4,
		"tdp_w": 65, "draw_w": 88,
		"integrated_graphics": false, "temp_c": 63, "performance": 73, "price": 580,
		"ddr_legacy_mt": 3200, "ddr5_mt": 0, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "amdera_r7_5800x",
		"kind": "cpu", "model": "Amdera R7 5800X", "brand": "Amdera",
		"socket": "AM4",
		"generation": "5000", "family": "a500_high",
		"cores": 8, "threads": 16,
		"base_ghz": 3.8, "turbo_ghz": 4.7,
		"tdp_w": 105, "draw_w": 142,
		"integrated_graphics": false, "temp_c": 82, "performance": 85, "price": 890,
		"ddr_legacy_mt": 3200, "ddr5_mt": 0, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "amdera_r5_7600",
		"kind": "cpu", "model": "Amdera R5 7600", "brand": "Amdera",
		"socket": "AM5",
		"generation": "7000", "family": "a700",
		"cores": 6, "threads": 12,
		"base_ghz": 3.8, "turbo_ghz": 5.1,
		"tdp_w": 65, "draw_w": 88,
		"integrated_graphics": true, "temp_c": 70, "performance": 86, "price": 1100,
		"ddr_legacy_mt": 0, "ddr5_mt": 5200, "max_memory_gb": 192, "condition": "Novo"},
	{"key": "amdera_r7_7700",
		"kind": "cpu", "model": "Amdera R7 7700", "brand": "Amdera",
		"socket": "AM5",
		"generation": "7000", "family": "a700",
		"cores": 8, "threads": 16,
		"base_ghz": 3.8, "turbo_ghz": 5.3,
		"tdp_w": 65, "draw_w": 88,
		"integrated_graphics": true, "temp_c": 73, "performance": 93, "price": 1550,
		"ddr_legacy_mt": 0, "ddr5_mt": 5200, "max_memory_gb": 192, "condition": "Novo"},
	{"key": "amdera_r7_9700x",
		"kind": "cpu", "model": "Amdera R7 9700X", "brand": "Amdera",
		"socket": "AM5",
		"generation": "9000", "family": "a900",
		"cores": 8, "threads": 16,
		"base_ghz": 3.8, "turbo_ghz": 5.5,
		"tdp_w": 65, "draw_w": 88,
		"integrated_graphics": true, "temp_c": 66, "performance": 100, "price": 1950,
		"ddr_legacy_mt": 0, "ddr5_mt": 5600, "max_memory_gb": 192, "condition": "Novo"},
	{"key": "intara_i3_3220",
		"kind": "cpu", "model": "Intara Core i3-3220", "brand": "Intara",
		"socket": "LGA1155",
		"generation": "3ª", "family": "i3",
		"cores": 2, "threads": 4,
		"base_ghz": 3.3, "turbo_ghz": 3.3,
		"tdp_w": 55, "draw_w": 55,
		"integrated_graphics": true, "temp_c": 53, "performance": 24, "price": 100,
		"ddr_legacy_mt": 1600, "ddr5_mt": 0, "max_memory_gb": 32, "condition": "Novo"},
	{"key": "intara_i5_3470",
		"kind": "cpu", "model": "Intara Core i5-3470", "brand": "Intara",
		"socket": "LGA1155",
		"generation": "3ª", "family": "i3",
		"cores": 4, "threads": 4,
		"base_ghz": 3.2, "turbo_ghz": 3.6,
		"tdp_w": 77, "draw_w": 77,
		"integrated_graphics": true, "temp_c": 62, "performance": 33, "price": 170,
		"ddr_legacy_mt": 1600, "ddr5_mt": 0, "max_memory_gb": 32, "condition": "Novo"},
	{"key": "intara_i7_3770",
		"kind": "cpu", "model": "Intara Core i7-3770", "brand": "Intara",
		"socket": "LGA1155",
		"generation": "3ª", "family": "i3",
		"cores": 4, "threads": 8,
		"base_ghz": 3.4, "turbo_ghz": 3.9,
		"tdp_w": 77, "draw_w": 77,
		"integrated_graphics": true, "temp_c": 67, "performance": 43, "price": 280,
		"ddr_legacy_mt": 1600, "ddr5_mt": 0, "max_memory_gb": 32, "condition": "Novo"},
	{"key": "intara_i5_6500",
		"kind": "cpu", "model": "Intara Core i5-6500", "brand": "Intara",
		"socket": "LGA1151",
		"generation": "6ª", "family": "i6",
		"cores": 4, "threads": 4,
		"base_ghz": 3.2, "turbo_ghz": 3.6,
		"tdp_w": 65, "draw_w": 65,
		"integrated_graphics": true, "temp_c": 57, "performance": 42, "price": 230,
		"ddr_legacy_mt": 2133, "ddr5_mt": 0, "max_memory_gb": 64, "condition": "Novo"},
	{"key": "intara_i5_9400f",
		"kind": "cpu", "model": "Intara Core i5-9400F", "brand": "Intara",
		"socket": "LGA1151",
		"generation": "9ª", "family": "i9",
		"cores": 6, "threads": 6,
		"base_ghz": 2.9, "turbo_ghz": 4.1,
		"tdp_w": 65, "draw_w": 78,
		"integrated_graphics": false, "temp_c": 63, "performance": 55, "price": 380,
		"ddr_legacy_mt": 2666, "ddr5_mt": 0, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "intara_i5_10400",
		"kind": "cpu", "model": "Intara Core i5-10400", "brand": "Intara",
		"socket": "LGA1200",
		"generation": "10ª", "family": "i10",
		"cores": 6, "threads": 12,
		"base_ghz": 2.9, "turbo_ghz": 4.3,
		"tdp_w": 65, "draw_w": 95,
		"integrated_graphics": true, "temp_c": 66, "performance": 64, "price": 490,
		"ddr_legacy_mt": 2666, "ddr5_mt": 0, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "intara_i5_11400",
		"kind": "cpu", "model": "Intara Core i5-11400", "brand": "Intara",
		"socket": "LGA1200",
		"generation": "11ª", "family": "i11",
		"cores": 6, "threads": 12,
		"base_ghz": 2.6, "turbo_ghz": 4.4,
		"tdp_w": 65, "draw_w": 110,
		"integrated_graphics": true, "temp_c": 70, "performance": 70, "price": 620,
		"ddr_legacy_mt": 3200, "ddr5_mt": 0, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "intara_i3_12100f",
		"kind": "cpu", "model": "Intara Core i3-12100F", "brand": "Intara",
		"socket": "LGA1700",
		"generation": "12ª", "family": "i12",
		"cores": 4, "threads": 8,
		"base_ghz": 3.3, "turbo_ghz": 4.3,
		"tdp_w": 58, "draw_w": 89,
		"integrated_graphics": false, "temp_c": 61, "performance": 67, "price": 450,
		"ddr_legacy_mt": 3200, "ddr5_mt": 4800, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "intara_i5_12400f",
		"kind": "cpu", "model": "Intara Core i5-12400F", "brand": "Intara",
		"socket": "LGA1700",
		"generation": "12ª", "family": "i12",
		"cores": 6, "threads": 12,
		"base_ghz": 2.5, "turbo_ghz": 4.4,
		"tdp_w": 65, "draw_w": 117,
		"integrated_graphics": false, "temp_c": 69, "performance": 78, "price": 780,
		"ddr_legacy_mt": 3200, "ddr5_mt": 4800, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "intara_i7_12700k",
		"kind": "cpu", "model": "Intara Core i7-12700K", "brand": "Intara",
		"socket": "LGA1700",
		"generation": "12ª", "family": "i12",
		"cores": 12, "threads": 20,
		"base_ghz": 3.6, "turbo_ghz": 5,
		"tdp_w": 125, "draw_w": 190,
		"integrated_graphics": true, "temp_c": 86, "performance": 96, "price": 1350,
		"ddr_legacy_mt": 3200, "ddr5_mt": 4800, "max_memory_gb": 128, "condition": "Novo"},
	{"key": "intara_i5_13400f",
		"kind": "cpu", "model": "Intara Core i5-13400F", "brand": "Intara",
		"socket": "LGA1700",
		"generation": "13ª", "family": "i13",
		"cores": 10, "threads": 16,
		"base_ghz": 2.5, "turbo_ghz": 4.6,
		"tdp_w": 65, "draw_w": 148,
		"integrated_graphics": false, "temp_c": 77, "performance": 88, "price": 1050,
		"ddr_legacy_mt": 3200, "ddr5_mt": 4800, "max_memory_gb": 192, "condition": "Novo"},
]

const DDR_TYPES := ["DDR3", "DDR4", "DDR5"]
const RAM_KEYS := ["ram", "ram2", "ram3", "ram4"]
const LATCH_KEYS := ["latches", "ram2_latches", "ram3_latches", "ram4_latches"]
# Keep the first two saved modules in different channels.
const RAM_LABELS := ["A1", "B1", "A2", "B2"]
const FOUR_SLOT_ORDER := [0, 2, 1, 3]
const TWO_SLOT_ORDER := [0, 1]
const MODULE_SPEEDS := {"DDR3": 1600, "DDR4": 3200, "DDR5": 5600}
const LEGACY_CPU_EQUIVALENTS := {
	"Amdera Ryvon 3 3200": "amdera_r3_3100",
	"Amdera Ryvon 5 5600": "amdera_r5_5600",
	"Amdera Ryvon 7 7800": "amdera_r7_5800x",
	"Intara Coren i3 6100": "intara_i3_12100f",
	"Intara Coren i5 9400": "intara_i5_13400f",
	"Intara Coren i7 12700": "intara_i7_12700k",
}
const SOCKET_ALIASES := {"AX4": "AM4", "IX1700": "LGA1700"}


static func board_spec(board: Dictionary) -> Dictionary:
	var key: Variant = board.get("catalog_key", board.get("key", ""))
	var model: Variant = board.get("model", "")
	for entry in BOARDS:
		if entry.key == key or (key == "" and entry.model == model):
			return entry
	return {}


static func cpu_spec(cpu: Dictionary) -> Dictionary:
	var key: Variant = cpu.get("catalog_key", cpu.get("key", ""))
	key = LEGACY_CPU_EQUIVALENTS.get(cpu.get("model", ""), key)
	for entry in CPUS:
		if entry.key == key: return entry
	return {}


static func socket(value: Variant) -> String:
	return SOCKET_ALIASES.get(value, value) if value is String else ""


static func cpu_reason(board: Dictionary, cpu: Dictionary) -> String:
	var board_socket := socket(board.get("socket", "TR4"))
	var cpu_socket := socket(cpu.get("socket", "TR4"))
	if board_socket.is_empty() or board_socket != cpu_socket:
		return "Socket incompatível: a peça usa %s e a placa-mãe usa %s." % [cpu_socket, board_socket]
	var board_data := board_spec(board)
	var cpu_data := cpu_spec(cpu)
	if not board_data.is_empty() and not cpu_data.is_empty() and cpu_data.family not in board_data.cpu_families:
		return "Processador incompatível com a geração suportada por esta placa-mãe."
	return ""


static func has_integrated_graphics(cpu: Dictionary) -> bool:
	# Older catalog CPUs originally required a dedicated card.
	return not LEGACY_CPU_EQUIVALENTS.has(cpu.get("model", "")) and cpu_spec(cpu).get("integrated_graphics", false)


static func slot_order(board: Dictionary) -> Array:
	if board.is_empty(): return []
	return FOUR_SLOT_ORDER if board_spec(board).get("slot_count", 2) == 4 else TWO_SLOT_ORDER


static func module_capacity(module: Dictionary) -> int:
	return int(module.get("capacity_gb", 8))


static func module_speed(module: Dictionary) -> int:
	return int(module.get("speed_mt", MODULE_SPEEDS.get(module.get("ddr", ""), 0)))


static func max_memory(board: Dictionary, cpu: Dictionary) -> int:
	return mini(board_spec(board).get("max_memory_gb", 128), cpu_spec(cpu).get("max_memory_gb", 192))


static func memory_limit_mt(board: Dictionary, cpu: Dictionary) -> int:
	var ddr: String = board.get("ddr", "")
	var board_data := board_spec(board)
	var limit: int = board_data.get("max_memory_mt", MODULE_SPEEDS.get(ddr, 0))
	if ddr == "DDR5" and board_data.get("key") == "intara_ix610": limit = 4800
	var cpu_data := cpu_spec(cpu)
	return mini(limit, cpu_data.get("ddr5_mt" if ddr == "DDR5" else "ddr_legacy_mt", limit))


static func memory_reason(board: Dictionary, cpu: Dictionary, modules: Array) -> String:
	if modules.is_empty(): return ""
	if modules.size() > slot_order(board).size(): return "A placa-mãe não possui slots suficientes."
	var max_gb := max_memory(board, cpu)
	var module_limit := int(board_spec(board).get("max_memory_gb", 128)) / slot_order(board).size()
	var total := 0
	for module in modules:
		if module.get("ddr") != board.get("ddr"):
			return "Incompatibilidade: o módulo %s não encaixa nesta placa-mãe %s." % [module.get("ddr", "?"), board.get("ddr", "?")]
		var capacity := module_capacity(module)
		if capacity <= 0 or capacity > module_limit:
			return "A placa-mãe aceita até %d GB por módulo." % module_limit
		if module_speed(module) <= 0: return "Frequência de memória inválida."
		total += capacity
	if total > max_gb: return "Esta configuração aceita no máximo %d GB de RAM." % max_gb
	if memory_limit_mt(board, cpu) <= 0: return "O controlador do processador não suporta este tipo de memória."
	return ""

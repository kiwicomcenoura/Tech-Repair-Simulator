extends RefCounted
## Fictional graphics, SATA storage and electrical specifications.

const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")
const GPUS := [
	{"key": "nivida_gt_710", "kind": "gpu", "model": "Nivida GT 710", "brand": "Nivida GeForce", "generation": "700",
		"vram_gb": 2, "vram_type": "DDR3", "price": 100, "performance": 10, "watts": 19, "plugs": [],
		"size_mm": 145, "slots": 1, "fans": 0, "pcie": 2, "lanes": 8, "temp_c": 49, "zero_rpm": false},
	{"key": "nivida_gt_1030", "kind": "gpu", "model": "Nivida GT 1030", "brand": "Nivida GeForce", "generation": "10",
		"vram_gb": 2, "vram_type": "GDDR5", "price": 200, "performance": 17, "watts": 30, "plugs": [],
		"size_mm": 152, "slots": 1, "fans": 1, "pcie": 3, "lanes": 4, "temp_c": 52, "zero_rpm": false},
	{"key": "nivida_gtx_750_ti", "kind": "gpu", "model": "Nivida GTX 750 Ti", "brand": "Nivida GeForce", "generation": "700",
		"vram_gb": 2, "vram_type": "GDDR5", "price": 250, "performance": 22, "watts": 60, "plugs": [],
		"size_mm": 163, "slots": 2, "fans": 1, "pcie": 3, "lanes": 16, "temp_c": 61, "zero_rpm": false},
	{"key": "nivida_gtx_960", "kind": "gpu", "model": "Nivida GTX 960", "brand": "Nivida GeForce", "generation": "900",
		"vram_gb": 4, "vram_type": "GDDR5", "price": 350, "performance": 28, "watts": 120, "plugs": ["6"],
		"size_mm": 218, "slots": 2, "fans": 2, "pcie": 3, "lanes": 16, "temp_c": 67, "zero_rpm": false},
	{"key": "nivida_gtx_1050_ti", "kind": "gpu", "model": "Nivida GTX 1050 Ti", "brand": "Nivida GeForce", "generation": "10",
		"vram_gb": 4, "vram_type": "GDDR5", "price": 450, "performance": 33, "watts": 75, "plugs": [],
		"size_mm": 175, "slots": 2, "fans": 1, "pcie": 3, "lanes": 16, "temp_c": 62, "zero_rpm": false},
	{"key": "nivida_gtx_1060", "kind": "gpu", "model": "Nivida GTX 1060", "brand": "Nivida GeForce", "generation": "10",
		"vram_gb": 6, "vram_type": "GDDR5", "price": 550, "performance": 43, "watts": 120, "plugs": ["6"],
		"size_mm": 237, "slots": 2, "fans": 2, "pcie": 3, "lanes": 16, "temp_c": 67, "zero_rpm": false},
	{"key": "nivida_gtx_1650", "kind": "gpu", "model": "Nivida GTX 1650", "brand": "Nivida GeForce", "generation": "16",
		"vram_gb": 4, "vram_type": "GDDR6", "price": 650, "performance": 39, "watts": 75, "plugs": [],
		"size_mm": 181, "slots": 2, "fans": 1, "pcie": 3, "lanes": 16, "temp_c": 60, "zero_rpm": false},
	{"key": "nivida_gtx_1660_super", "kind": "gpu", "model": "Nivida GTX 1660 Super", "brand": "Nivida GeForce", "generation": "16",
		"vram_gb": 6, "vram_type": "GDDR6", "price": 850, "performance": 49, "watts": 125, "plugs": ["8"],
		"size_mm": 229, "slots": 2, "fans": 2, "pcie": 3, "lanes": 16, "temp_c": 66, "zero_rpm": false},
	{"key": "nivida_rtx_2060", "kind": "gpu", "model": "Nivida RTX 2060", "brand": "Nivida GeForce", "generation": "20",
		"vram_gb": 6, "vram_type": "GDDR6", "price": 1050, "performance": 54, "watts": 160, "plugs": ["8"],
		"size_mm": 244, "slots": 2, "fans": 2, "pcie": 3, "lanes": 16, "temp_c": 72, "zero_rpm": false},
	{"key": "nivida_rtx_3060", "kind": "gpu", "model": "Nivida RTX 3060", "brand": "Nivida GeForce", "generation": "30",
		"vram_gb": 12, "vram_type": "GDDR6", "price": 1500, "performance": 64, "watts": 170, "plugs": ["8"],
		"size_mm": 245, "slots": 2, "fans": 2, "pcie": 4, "lanes": 16, "temp_c": 69, "zero_rpm": true},
	{"key": "nivida_rtx_4060", "kind": "gpu", "model": "Nivida RTX 4060", "brand": "Nivida GeForce", "generation": "40",
		"vram_gb": 8, "vram_type": "GDDR6", "price": 1900, "performance": 72, "watts": 115, "plugs": ["8"],
		"size_mm": 228, "slots": 2, "fans": 2, "pcie": 4, "lanes": 8, "temp_c": 64, "zero_rpm": true},
	{"key": "nivida_rtx_4070", "kind": "gpu", "model": "Nivida RTX 4070", "brand": "Nivida GeForce", "generation": "40",
		"vram_gb": 12, "vram_type": "GDDR6X", "price": 3000, "performance": 87, "watts": 200, "plugs": ["8"],
		"size_mm": 268, "slots": 2, "fans": 2, "pcie": 4, "lanes": 16, "temp_c": 71, "zero_rpm": true, "rgb": true},
	{"key": "nivida_rtx_4080", "kind": "gpu", "model": "Nivida RTX 4080", "brand": "Nivida GeForce", "generation": "40",
		"vram_gb": 16, "vram_type": "GDDR6X", "price": 5500, "performance": 107, "watts": 320, "plugs": ["16"],
		"size_mm": 325, "slots": 3, "fans": 3, "pcie": 4, "lanes": 16, "temp_c": 74, "zero_rpm": true, "rgb": true},
	{"key": "nivida_rtx_4090", "kind": "gpu", "model": "Nivida RTX 4090", "brand": "Nivida GeForce", "generation": "40",
		"vram_gb": 24, "vram_type": "GDDR6X", "price": 8500, "performance": 126, "watts": 450, "plugs": ["16"],
		"size_mm": 350, "slots": 4, "fans": 3, "pcie": 4, "lanes": 16, "temp_c": 79, "zero_rpm": true, "rgb": true},
	{"key": "nivida_rtx_5060", "kind": "gpu", "model": "Nivida RTX 5060", "brand": "Nivida GeForce", "generation": "50",
		"vram_gb": 8, "vram_type": "GDDR7", "price": 2500, "performance": 78, "watts": 145, "plugs": ["8"],
		"size_mm": 234, "slots": 2, "fans": 2, "pcie": 5, "lanes": 8, "temp_c": 66, "zero_rpm": true},
	{"key": "nivida_rtx_5070", "kind": "gpu", "model": "Nivida RTX 5070", "brand": "Nivida GeForce", "generation": "50",
		"vram_gb": 12, "vram_type": "GDDR7", "price": 4000, "performance": 95, "watts": 250, "plugs": ["16"],
		"size_mm": 302, "slots": 3, "fans": 3, "pcie": 5, "lanes": 16, "temp_c": 73, "zero_rpm": true, "rgb": true},
	{"key": "amdera_rx_550", "kind": "gpu", "model": "Amdera RX 550", "brand": "Amdera Radeon", "generation": "500",
		"vram_gb": 4, "vram_type": "GDDR5", "price": 200, "performance": 18, "watts": 50, "plugs": [],
		"size_mm": 153, "slots": 1, "fans": 1, "pcie": 3, "lanes": 8, "temp_c": 60, "zero_rpm": false},
	{"key": "amdera_rx_560", "kind": "gpu", "model": "Amdera RX 560", "brand": "Amdera Radeon", "generation": "500",
		"vram_gb": 4, "vram_type": "GDDR5", "price": 300, "performance": 25, "watts": 80, "plugs": ["6"],
		"size_mm": 174, "slots": 2, "fans": 1, "pcie": 3, "lanes": 8, "temp_c": 65, "zero_rpm": false},
	{"key": "amdera_rx_570", "kind": "gpu", "model": "Amdera RX 570", "brand": "Amdera Radeon", "generation": "500",
		"vram_gb": 4, "vram_type": "GDDR5", "price": 400, "performance": 34, "watts": 150, "plugs": ["8"],
		"size_mm": 225, "slots": 2, "fans": 2, "pcie": 3, "lanes": 16, "temp_c": 72, "zero_rpm": false},
	{"key": "amdera_rx_580", "kind": "gpu", "model": "Amdera RX 580", "brand": "Amdera Radeon", "generation": "500",
		"vram_gb": 8, "vram_type": "GDDR5", "price": 550, "performance": 41, "watts": 185, "plugs": ["8"],
		"size_mm": 245, "slots": 2, "fans": 2, "pcie": 3, "lanes": 16, "temp_c": 77, "zero_rpm": false},
	{"key": "amdera_rx_5500_xt", "kind": "gpu", "model": "Amdera RX 5500 XT", "brand": "Amdera Radeon", "generation": "5000",
		"vram_gb": 8, "vram_type": "GDDR6", "price": 750, "performance": 44, "watts": 130, "plugs": ["8"],
		"size_mm": 213, "slots": 2, "fans": 2, "pcie": 4, "lanes": 8, "temp_c": 69, "zero_rpm": false},
	{"key": "amdera_rx_5600_xt", "kind": "gpu", "model": "Amdera RX 5600 XT", "brand": "Amdera Radeon", "generation": "5000",
		"vram_gb": 6, "vram_type": "GDDR6", "price": 950, "performance": 52, "watts": 150, "plugs": ["8"],
		"size_mm": 232, "slots": 2, "fans": 2, "pcie": 4, "lanes": 16, "temp_c": 71, "zero_rpm": false},
	{"key": "amdera_rx_5700_xt", "kind": "gpu", "model": "Amdera RX 5700 XT", "brand": "Amdera Radeon", "generation": "5000",
		"vram_gb": 8, "vram_type": "GDDR6", "price": 1200, "performance": 60, "watts": 225, "plugs": ["8", "6"],
		"size_mm": 279, "slots": 2, "fans": 2, "pcie": 4, "lanes": 16, "temp_c": 77, "zero_rpm": false},
	{"key": "amdera_rx_6600", "kind": "gpu", "model": "Amdera RX 6600", "brand": "Amdera Radeon", "generation": "6000",
		"vram_gb": 8, "vram_type": "GDDR6", "price": 1400, "performance": 62, "watts": 132, "plugs": ["8"],
		"size_mm": 221, "slots": 2, "fans": 2, "pcie": 4, "lanes": 8, "temp_c": 64, "zero_rpm": true},
	{"key": "amdera_rx_6650_xt", "kind": "gpu", "model": "Amdera RX 6650 XT", "brand": "Amdera Radeon", "generation": "6000",
		"vram_gb": 8, "vram_type": "GDDR6", "price": 1650, "performance": 68, "watts": 176, "plugs": ["8"],
		"size_mm": 246, "slots": 2, "fans": 2, "pcie": 4, "lanes": 8, "temp_c": 69, "zero_rpm": true},
	{"key": "amdera_rx_6700_xt", "kind": "gpu", "model": "Amdera RX 6700 XT", "brand": "Amdera Radeon", "generation": "6000",
		"vram_gb": 12, "vram_type": "GDDR6", "price": 2000, "performance": 77, "watts": 230, "plugs": ["8", "6"],
		"size_mm": 266, "slots": 3, "fans": 2, "pcie": 4, "lanes": 16, "temp_c": 72, "zero_rpm": true},
	{"key": "amdera_rx_7600", "kind": "gpu", "model": "Amdera RX 7600", "brand": "Amdera Radeon", "generation": "7000",
		"vram_gb": 8, "vram_type": "GDDR6", "price": 2200, "performance": 70, "watts": 165, "plugs": ["8"],
		"size_mm": 231, "slots": 2, "fans": 2, "pcie": 4, "lanes": 8, "temp_c": 66, "zero_rpm": true},
	{"key": "amdera_rx_7700_xt", "kind": "gpu", "model": "Amdera RX 7700 XT", "brand": "Amdera Radeon", "generation": "7000",
		"vram_gb": 12, "vram_type": "GDDR6", "price": 2900, "performance": 86, "watts": 245, "plugs": ["8", "8"],
		"size_mm": 287, "slots": 3, "fans": 3, "pcie": 4, "lanes": 16, "temp_c": 72, "zero_rpm": true},
	{"key": "amdera_rx_7800_xt", "kind": "gpu", "model": "Amdera RX 7800 XT", "brand": "Amdera Radeon", "generation": "7000",
		"vram_gb": 16, "vram_type": "GDDR6", "price": 3500, "performance": 94, "watts": 263, "plugs": ["8", "8"],
		"size_mm": 311, "slots": 3, "fans": 3, "pcie": 4, "lanes": 16, "temp_c": 74, "zero_rpm": true, "rgb": true},
	{"key": "amdera_rx_7900_xtx", "kind": "gpu", "model": "Amdera RX 7900 XTX", "brand": "Amdera Radeon", "generation": "7000",
		"vram_gb": 24, "vram_type": "GDDR6", "price": 5900, "performance": 114, "watts": 355, "plugs": ["8", "8", "8"],
		"size_mm": 330, "slots": 4, "fans": 3, "pcie": 4, "lanes": 16, "temp_c": 78, "zero_rpm": true, "rgb": true},
	{"key": "amdera_rx_9060_xt", "kind": "gpu", "model": "Amdera RX 9060 XT", "brand": "Amdera Radeon", "generation": "9000",
		"vram_gb": 16, "vram_type": "GDDR6", "price": 3100, "performance": 82, "watts": 160, "plugs": ["8"],
		"size_mm": 259, "slots": 2, "fans": 2, "pcie": 5, "lanes": 16, "temp_c": 65, "zero_rpm": true, "rgb": true},
	{"key": "amdera_rx_9070_xt", "kind": "gpu", "model": "Amdera RX 9070 XT", "brand": "Amdera Radeon", "generation": "9000",
		"vram_gb": 16, "vram_type": "GDDR6", "price": 4500, "performance": 108, "watts": 304, "plugs": ["8", "8", "8"],
		"size_mm": 321, "slots": 3, "fans": 3, "pcie": 5, "lanes": 16, "temp_c": 73, "zero_rpm": true, "rgb": true},
]
const DRIVES := [
	{"key": "hdd_120", "kind": "storage", "model": "TechDisk HDD 120", "brand": "TechDisk", "price": 35,
		"capacity_gb": 120, "interface": "SATA", "bay": "3.5", "rpm": 5400, "read_mb": 75, "write_mb": 62, "temp_c": 43},
	{"key": "hdd_256", "kind": "storage", "model": "TechDisk HDD 256", "brand": "TechDisk", "price": 55,
		"capacity_gb": 256, "interface": "SATA", "bay": "3.5", "rpm": 5400, "read_mb": 90, "write_mb": 76, "temp_c": 42},
	{"key": "hdd_360", "kind": "storage", "model": "TechDisk HDD 360", "brand": "TechDisk", "price": 75,
		"capacity_gb": 360, "interface": "SATA", "bay": "3.5", "rpm": 7200, "read_mb": 109, "write_mb": 93, "temp_c": 45},
	{"key": "hdd_500", "kind": "storage", "model": "TechDisk HDD 500", "brand": "TechDisk", "price": 100,
		"capacity_gb": 500, "interface": "SATA", "bay": "3.5", "rpm": 7200, "read_mb": 128, "write_mb": 112, "temp_c": 44},
	{"key": "hdd_750", "kind": "storage", "model": "TechDisk HDD 750", "brand": "TechDisk", "price": 130,
		"capacity_gb": 750, "interface": "SATA", "bay": "3.5", "rpm": 5400, "read_mb": 118, "write_mb": 103, "temp_c": 41},
	{"key": "hdd_940", "kind": "storage", "model": "TechDisk HDD 940", "brand": "TechDisk", "price": 150,
		"capacity_gb": 940, "interface": "SATA", "bay": "3.5", "rpm": 7200, "read_mb": 149, "write_mb": 131, "temp_c": 47},
	{"key": "hdd_1000", "kind": "storage", "model": "TechDisk HDD 1000", "brand": "TechDisk", "price": 180,
		"capacity_gb": 1000, "interface": "SATA", "bay": "3.5", "rpm": 7200, "read_mb": 173, "write_mb": 153, "temp_c": 46},
	{"key": "hdd_2000", "kind": "storage", "model": "TechDisk HDD 2000", "brand": "TechDisk", "price": 280,
		"capacity_gb": 2000, "interface": "SATA", "bay": "3.5", "rpm": 7200, "read_mb": 199, "write_mb": 179, "temp_c": 48},
]

const LEGACY_GPU := {"watts": 110, "plugs": ["8"], "size_mm": 155, "slots": 2, "fans": 2, "pcie": 3, "lanes": 16, "performance": 36, "temp_c": 65}
const PSU_SPECS := {
	"450": {"watts": 450, "six_eight": 1, "high_power": 0},
	"550": {"watts": 550, "six_eight": 2, "high_power": 0},
	"650": {"watts": 650, "six_eight": 2, "high_power": 0},
	"850": {"watts": 850, "six_eight": 3, "high_power": 1},
	"1000": {"watts": 1000, "six_eight": 4, "high_power": 1},
}
const BOARD_BUSES := {
	"intara_h61_classic": [2, 2], "intara_b75m": [3, 4], "intara_h110m": [3, 4],
	"intara_b360m": [3, 6], "intara_h510m": [4, 4], "intara_ix610": [4, 4],
	"intara_b660m": [4, 4], "intara_z790_ultra": [5, 6],
	"amdera_a320m": [3, 4], "amdera_b450m": [3, 4], "amdera_ax550": [4, 6],
	"amdera_b550_pro": [4, 6], "amdera_x570_elite": [4, 6], "amdera_a620m": [4, 4],
	"amdera_b650_gaming": [4, 4], "amdera_x670_elite": [5, 6],
}

static func gpu(part: Dictionary) -> Dictionary:
	return _entry(GPUS, part)


static func hdd(part: Dictionary) -> Dictionary:
	return _entry(DRIVES, part)


static func _entry(entries: Array, part: Dictionary) -> Dictionary:
	var key: Variant = part.get("catalog_key", part.get("key", ""))
	if key == "": return {}
	for entry in entries:
		if entry.key == key: return entry
	return {}


static func gpu_profile(part: Dictionary) -> Dictionary:
	if part.is_empty(): return {}
	var spec := gpu(part)
	return LEGACY_GPU if spec.is_empty() else spec


static func psu(part: Dictionary) -> Dictionary:
	for watts in PSU_SPECS:
		if str(part.get("model", "")).contains(watts): return PSU_SPECS[watts]
	return PSU_SPECS["450"]


static func board_bus(board: Dictionary) -> Array:
	if board.is_empty(): return [0, 0]
	return BOARD_BUSES.get(Hardware.board_spec(board).get("key"), [3, 2])


static func plugs_label(plugs: Array) -> String:
	var names: Array[String] = []
	for plug in plugs: names.append("12V-2x6" if plug == "16" else "%s pinos" % plug)
	return "Somente pelo PCIe" if names.is_empty() else " + ".join(names)


static func capacity_label(gb: int) -> String:
	return "%d TB" % int(gb / 1000) if gb >= 1000 and gb % 1000 == 0 else "%d GB" % gb


static func power_reason(card: Dictionary, supply: Dictionary, cpu: Dictionary, drive_count: int) -> String:
	var profile := gpu_profile(card)
	if profile.is_empty() or supply.is_empty(): return ""
	var supply_data := psu(supply)
	if profile.plugs.count("16") > supply_data.high_power or profile.plugs.size() - profile.plugs.count("16") > supply_data.six_eight:
		return "A fonte não tem os conectores da GPU: %s." % plugs_label(profile.plugs)
	var cpu_data := Hardware.cpu_spec(cpu)
	var required := int(ceil(float(profile.watts + cpu_data.get("draw_w", 88) + 45 + drive_count * 9) * 1.20))
	return "Fonte insuficiente: a montagem precisa de %d W com margem, mas a fonte entrega %d W." % [required, supply_data.watts] if required > supply_data.watts else ""


static func performance(card: Dictionary, board: Dictionary, cpu: Dictionary) -> Dictionary:
	var profile := gpu_profile(card)
	if profile.is_empty(): return {}
	var link := mini(int(profile.pcie), int(board_bus(board)[0]))
	var penalty := 1.0 - 0.05 * (int(profile.pcie) - link) * (2.0 if profile.lanes <= 8 else 1.0)
	var cpu_limit: int = int(Hardware.cpu_spec(cpu).get("performance", 55) * 1.3)
	return {"link": link, "lanes": profile.lanes, "score": mini(roundi(profile.performance * penalty), cpu_limit), "cpu_limit": cpu_limit < roundi(profile.performance * penalty)}

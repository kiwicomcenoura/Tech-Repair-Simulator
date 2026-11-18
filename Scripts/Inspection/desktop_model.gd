extends Node3D
## The inspection model follows the same installed parts and fasteners as the bench.

const PartVisuals := preload("res://Scripts/UI/part_visuals.gd")
const Ledger := preload("res://Scripts/Gameplay/workshop_ledger.gd")
const DesktopCables := preload("res://Scripts/Inspection/desktop_cables.gd")
const CHASSIS_ART := preload("res://Assets/Inspection/Layers/chassis.png")
const COVER_ART := preload("res://Assets/Inspection/Layers/lid.png")
const PART_ART := {
	"motherboard": preload("res://Assets/Inspection/Layers/motherboard.png"),
	"cooling": preload("res://Assets/Inspection/Layers/cooling.png"),
	"cpu": preload("res://Assets/Inspection/Layers/cpu.png"),
	"gpu": preload("res://Assets/Inspection/Layers/gpu.png"),
	"psu": preload("res://Assets/Inspection/Layers/psu.png"),
	"storage": preload("res://Assets/Inspection/Layers/storage.png"),
	"ram": preload("res://Assets/Inspection/Layers/ram.png"),
}
const BOARD_FACE_Z := -0.371
const GPU_BACKPLATE_Y := -0.1275
const GPU_POWER_FACE_X := 0.305
const COOLER_FRAME_EDGE_X := -0.295
const SSD_BOTTOM_Y := -0.395
const PSU_PANEL_X := -0.119
const COOLER_FACE_Z := 0.047
const FRONT_INSIDE_X := 1.09
const SCREW_ANCHORS := {
	"gpu": [Vector3(-1.295, -0.19, 0.41), Vector3(-1.295, -0.34, 0.41)],
	"psu": [Vector3(-1.29, -0.57, -0.32), Vector3(-1.29, -0.57, 0.31),
		Vector3(-1.29, -0.88, -0.32), Vector3(-1.29, -0.88, 0.31)],
	"storage": [Vector3(0.62, 0.182, -0.163), Vector3(0.98, 0.182, -0.163),
		Vector3(0.62, -0.34, -0.163), Vector3(0.98, -0.34, -0.163)],
	"cooling": [Vector3(-0.73, 0.71, 0.051), Vector3(-0.33, 0.71, 0.051),
		Vector3(-0.73, 0.31, 0.051), Vector3(-0.33, 0.31, 0.051)],
	"motherboard": [Vector3(-1.00, 0.83, -0.354), Vector3(0.34, 0.83, -0.354),
		Vector3(-1.00, 0.38, -0.354), Vector3(0.34, 0.38, -0.354),
		Vector3(-1.00, -0.13, -0.354), Vector3(0.34, -0.13, -0.354)],
}
const CONNECTOR_ANCHORS := {
	"gpu": [Vector3(GPU_POWER_FACE_X, -0.222, 0.144), Vector3(0.276, -0.10, -0.315)],
	"psu": [],
	"storage": [Vector3(0.681, SSD_BOTTOM_Y, -0.244), Vector3(0.919, SSD_BOTTOM_Y, -0.244)],
	"cooling": [Vector3(-0.208, 0.706, BOARD_FACE_Z)],
	"cpu": [Vector3(-0.28, 0.52, -0.28)],
	"motherboard": [Vector3(0.352, 0.58, BOARD_FACE_Z), Vector3(-0.86, 0.837, BOARD_FACE_Z),
		Vector3(0.195, -0.158, BOARD_FACE_Z)],
}
const PLUG_PINS := {
	"motherboard:0": Vector2i(2, 12), "motherboard:1": Vector2i(4, 2),
	"motherboard:2": Vector2i(4, 1), "gpu:0": Vector2i(4, 2),
	"storage:0": Vector2i(5, 1),
	"storage:1": Vector2i(7, 1), "cooling:0": Vector2i(4, 1),
}
const CABLE_PORT_ROTATIONS := {
	"gpu:0": Vector3(0, PI / 2.0, 0),
	"storage:0": Vector3(PI / 2.0, 0, 0),
	"storage:1": Vector3(PI / 2.0, 0, 0),
}
const UNPLUGGED_OFFSETS := {
	"motherboard:0": Vector3(0.078, -0.026, 0.087),
	"motherboard:1": Vector3(0.099, 0.063, 0.084),
	"motherboard:2": Vector3(0.085, -0.042, 0.088),
	"gpu:0": Vector3(-0.034, -0.032, 0.105),
	"storage:0": Vector3(-0.023, -0.018, 0.090),
	"storage:1": Vector3(0.021, -0.024, 0.090),
	"cooling:0": Vector3(0.047, -0.074, 0.105),
}
const EMPTY_MOUNTS := {
	"motherboard": [Vector3(-0.52, 0.29, -0.415), Vector2(1.24, 0.96)],
	"cooling": [Vector3(-0.53, 0.51, -0.23), Vector2(0.48, 0.48)],
	"cpu": [Vector3(-0.53, 0.51, -0.31), Vector2(0.34, 0.34)],
	"gpu": [Vector3(-0.42, -0.24, 0.32), Vector2(1.32, 0.15)],
	"psu": [Vector3(-0.64, -0.72, 0.416), Vector2(0.95, 0.35)],
	"storage": [Vector3(0.80, -0.08, -0.17), Vector2(0.44, 0.60)],
	"ram": [Vector3(0.03, 0.51, -0.21), Vector2(0.09, 0.55)],
	"ram2": [Vector3(0.21, 0.51, -0.21), Vector2(0.09, 0.55)],
}
const GRAPHITE := Color("303137")
const STEEL := Color("959ba0")
const BLACK := Color("1c1c20")
const PCB := Color("293d34")
const GOLD := Color("a78356")
const PLASTIC := Color("494545")
const LED := Color("a7cc91")

var _materials: Dictionary = {}
var _texture_materials: Dictionary = {}
var _parts: Dictionary = {}
var _part_faces: Dictionary = {}
var _mounts: Dictionary = {}
var _empty_mounts: Dictionary = {}
var _ram_latches: Array[Node3D] = []
var _cable_sources: Dictionary = {}
var _cable_targets: Dictionary = {}
var _pick_meshes: Array[MeshInstance3D] = []
var _cables: DesktopCables
var _metal_normal: NoiseTexture2D
var _cover: Node3D
var _parked_cover: Node3D
var _screws: Array[Node3D] = []
var _power_led: MeshInstance3D


func _ready() -> void:
	_build_metal_finish()
	_build_case()
	_build_front()
	_build_rear()
	_build_cover()
	_build_components()
	_build_mounts()
	_cables = DesktopCables.new()
	add_child(_cables)
	_cables.build(self, _cable_sources, _cable_targets)


func update_parts(session: RefCounted) -> void:
	var installed: Dictionary = {}
	var powered := false
	var ledger: RefCounted
	var selected_kind := ""
	var pc_id: String = session.physical_pc_id
	if is_instance_valid(session.workshop):
		ledger = session.workshop.ledger
		var pc: Dictionary = ledger.item(pc_id)
		installed = pc.get("components", {})
		powered = pc.get("power", false)
		selected_kind = ledger.item(session.workshop.selected_part).get("kind", "")
	_cover.visible = session.lid_attached
	_parked_cover.visible = not session.lid_attached
	var accessible: bool = ledger != null and not session.lid_attached
	var connected_ports := {}
	for index in _screws.size():
		_screws[index].visible = session.screws[index]
	for kind in _parts:
		var present := installed.has(kind)
		_parts[kind].visible = present
		if present:
			_part_faces[kind].material_override = _texture_material(_part_art(kind, ledger.item(installed[kind])))
		var is_ram: bool = kind in ["ram", "ram2"]
		_empty_mounts[kind].visible = accessible and not present and (
			installed.has("motherboard") if is_ram else selected_kind == kind
		) and (kind != "cpu" or not installed.has("cooling"))
		if not _mounts.has(kind):
			continue
		var controls: Dictionary = _mounts[kind]
		controls.group.visible = accessible and present and (kind != "cpu" or not installed.has("cooling"))
		if not controls.group.visible:
			continue
		var state: Dictionary = ledger.mounts(pc_id, kind)
		for i in controls.screws.size():
			controls.screws[i].visible = state.screws[i]
		var ports: Array[bool] = []
		for i in controls.connectors.size():
			var connected: bool = state.connections[Ledger.CONNECTIONS[kind][i]]
			var connector: Dictionary = controls.connectors[i]
			if connector.has("ends"):
				for end: Dictionary in connector.ends:
					end.plug.position = Vector3.ZERO if connected else end.offset
			else:
				connector.lever.rotation.x = 0.0 if connected else -0.94
			ports.append(connected)
		connected_ports[kind] = ports
	_cables.visible = accessible
	if accessible:
		_cables.sync(installed, connected_ports)
	if ledger != null and installed.has("motherboard"):
		for slot in 2:
			var clips: Array = ledger.ram_latches(pc_id, slot)
			for i in 2:
				var clip := _ram_latches[slot * 2 + i]
				clip.rotation.x = 0.0 if clips[i] else (-0.83 if i == 0 else 0.83)
	_power_led.material_override = _material(LED if powered else STEEL)


func _build_case() -> void:
	_box(self, Vector3(0, 0, -0.47), Vector3(2.4, 1.94, 0.07), GRAPHITE)
	var back := _face(self, Vector3(0, 0, -0.433), Vector2(2.19, 1.84))
	back.material_override = _texture_material(CHASSIS_ART, Rect2i(156, 100, 844, 680))
	for height in [-0.98, 0.98]:
		_box(self, Vector3(0, height, 0), Vector3(2.4, 0.08, 1.0), GRAPHITE)
		for side in [-0.48, 0.48]:
			_box(self, Vector3(0, height, side), Vector3(2.42, 0.09, 0.06), STEEL)
	for x in [-1.15, 1.15]:
		_box(self, Vector3(x, 0, 0.47), Vector3(0.10, 2.0, 0.08), GRAPHITE)
	for x in [-0.91, 0.91]:
		for side in [-0.32, 0.32]:
			_box(self, Vector3(x, -1.045, side), Vector3(0.27, 0.09, 0.24), BLACK)
	_box(self, Vector3(-0.18, 1.023, 0), Vector3(1.55, 0.016, 0.68), BLACK)
	for index in 16:
		_box(self, Vector3(-0.88 + index * 0.093, 1.035, 0), Vector3(0.037, 0.012, 0.58), GRAPHITE)
	_box(self, Vector3(0, -0.02, -0.519), Vector3(1.96, 1.54, 0.028), BLACK)
	_box(self, Vector3(0, -0.02, -0.535), Vector3(1.84, 1.42, 0.026), GRAPHITE)


func _build_front() -> void:
	_box(self, Vector3(FRONT_INSIDE_X + 0.08, 0, 0), Vector3(0.16, 1.98, 0.97), GRAPHITE)
	_cable_sources["motherboard:2"] = _connector(
		self, &"", Vector3(FRONT_INSIDE_X, 0.78, -0.24), Vector2i(4, 1), Vector3.ZERO, Vector3(0, -PI / 2.0, 0)
	)
	_box(self, Vector3(1.26, -0.10, 0), Vector3(0.035, 1.57, 0.79), BLACK)
	for y in [-0.46, 0.29]:
		_fan(self, Vector3(1.29, y, 0), 0.30, Vector3(0, 0, -PI / 2.0))
	for index in 17:
		_box(self, Vector3(1.35, -0.83 + float(index) * 0.089, 0), Vector3(0.02, 0.017, 0.75), GRAPHITE)
	_box(self, Vector3(1.272, 0.78, 0), Vector3(0.035, 0.21, 0.81), BLACK)
	_disk(self, Vector3(1.301, 0.78, -0.24), 0.066, 0.022, STEEL, Vector3(0, 0, PI / 2.0))
	_power_led = _disk(self, Vector3(1.315, 0.78, -0.24), 0.030, 0.009, LED, Vector3(0, 0, PI / 2.0))
	for z in [0.02, 0.18]:
		_box(self, Vector3(1.295, 0.78, z), Vector3(0.014, 0.059, 0.118), STEEL)
		_box(self, Vector3(1.305, 0.78, z), Vector3(0.014, 0.031, 0.090), PCB)
	_disk(self, Vector3(1.301, 0.78, 0.32), 0.025, 0.016, STEEL, Vector3(0, 0, PI / 2.0))


func _build_rear() -> void:
	_box(self, Vector3(-1.19, 0, 0), Vector3(0.07, 1.96, 0.94), STEEL)
	_box(self, Vector3(-1.238, 0.50, -0.25), Vector3(0.035, 0.77, 0.24), GRAPHITE)
	for i in 5:
		var center := Vector3(-1.264, 0.23 + 0.13 * i, -0.25)
		_box(self, center, Vector3(0.025, 0.08, 0.16), BLACK)
		_box(self, center + Vector3(-0.014, -0.018, 0), Vector3(0.012, 0.012, 0.12), PCB)
	_fan(self, Vector3(-1.26, 0.55, 0.12), 0.23, Vector3(0, 0, PI / 2.0))
	for i in 5:
		var y := -0.36 + 0.109 * i
		_box(self, Vector3(-1.238, y, 0.02), Vector3(0.025, 0.078, 0.72), GRAPHITE)
		for j in 7:
			_box(self, Vector3(-1.257, y, -0.25 + 0.085 * j), Vector3(0.013, 0.027, 0.048), BLACK)
	_box(self, Vector3(-1.24, -0.72, 0), Vector3(0.042, 0.37, 0.78), GRAPHITE)


func _build_cover() -> void:
	_cover = _group(self, &"lid")
	_parked_cover = _group(self, &"lid")
	_parked_cover.transform = Transform3D(
		Basis(Vector3.UP, -0.72).scaled(Vector3.ONE * 0.60), Vector3(2.10, -0.36, 0.51)
	)
	_cover_face(_cover, 0.51)
	_cover_face(_parked_cover, 0.0)
	for y in [0.82, -0.82]:
		for x in [-1.02, 1.02]:
			var id := StringName("screw_%d" % _screws.size())
			_screws.append(_mount_screw(_cover, id, Vector3(x, y, 0.567)))


func _cover_face(parent: Node3D, z: float) -> void:
	_box(parent, Vector3(0, 0, z), Vector3(2.18, 1.84, 0.065), GRAPHITE)
	var surface := _face(parent, Vector3(0, 0, z + 0.034), Vector2(2.18, 1.84))
	surface.material_override = _texture_material(COVER_ART)


func _build_components() -> void:
	var board := _part("motherboard")
	_box(board, Vector3(-0.33, 0.34, -0.395), Vector3(1.46, 1.09, 0.045), PCB)
	_build_board_electronics(board)
	for i in 3:
		_box(board, Vector3(-0.36, -0.10 + 0.080 * i, -0.35), Vector3(1.02, 0.032, 0.04), BLACK)
	_box(board, Vector3(0.223, -0.10, -0.35), Vector3(0.23, 0.032, 0.071), BLACK)
	for i in 5:
		_box(board, Vector3(-0.91, 0.22 + 0.107 * i, -0.345), Vector3(0.095, 0.067, 0.052), STEEL)
	_box(board, Vector3(-0.53, 0.51, -0.345), Vector3(0.43, 0.43, 0.06), BLACK)
	_part_faces.motherboard = _face(board, Vector3(-0.33, 0.34, BOARD_FACE_Z), Vector2(1.46, 1.09))
	_cable_sources["storage:0"] = _connector(board, &"", Vector3(0.337, -0.014, BOARD_FACE_Z), Vector2i(5, 1), Vector3.ZERO)
	var cpu := _part("cpu")
	_box(cpu, Vector3(-0.53, 0.51, -0.291), Vector3(0.34, 0.34, 0.05), GOLD)
	_part_faces.cpu = _face(cpu, Vector3(-0.53, 0.51, -0.264), Vector2(0.34, 0.34))
	var cooler := _part("cooling")
	for i in 8:
		_box(cooler, Vector3(-0.53, 0.51, -0.278 + i * 0.032), Vector3(0.47, 0.47, 0.021), STEEL)
	_box(cooler, Vector3(COOLER_FRAME_EDGE_X - 0.235, 0.51, 0.015), Vector3(0.47, 0.47, 0.060), BLACK)
	_part_faces.cooling = _face(cooler, Vector3(-0.53, 0.51, COOLER_FACE_Z), Vector2(0.47, 0.47))
	# The fan's fixed lead exits a molded strain relief in the side of the frame.
	var fan_lead := _group(cooler)
	fan_lead.position = Vector3(COOLER_FRAME_EDGE_X, 0.655, 0.013)
	fan_lead.rotation.y = PI / 2.0
	_box(fan_lead, Vector3(0, 0, 0.008), Vector3(0.029, 0.025, 0.022), BLACK)
	var fan_exit := Marker3D.new()
	fan_exit.position.z = 0.016
	fan_lead.add_child(fan_exit)
	_cable_sources["cooling:0"] = {"wire_exit": fan_exit}
	for slot in 2:
		var x := 0.03 + 0.18 * slot
		_box(board, Vector3(x, 0.51, -0.344), Vector3(0.105, 0.64, 0.038), BLACK)
		var kind := "ram" if slot == 0 else "ram2"
		var ram := _part(kind)
		_box(ram, Vector3(x, 0.51, -0.277), Vector3(0.075, 0.56, 0.112), PCB)
		_part_faces[kind] = _face(ram, Vector3(x, 0.51, -0.209), Vector2(0.088, 0.56))
		for i in 4:
			_box(ram, Vector3(x - 0.042, 0.33 + 0.118 * i, -0.277), Vector3(0.016, 0.077, 0.065), BLACK)
	var gpu := _part("gpu")
	_box(gpu, Vector3(GPU_POWER_FACE_X - 0.735, -0.23, -0.04), Vector3(1.47, 0.14, 0.66), GRAPHITE)
	_box(gpu, Vector3(-0.43, -0.153, -0.04), Vector3(1.43, 0.020, 0.62), PCB)
	_box(gpu, Vector3(-0.43, GPU_BACKPLATE_Y - 0.0095, -0.04), Vector3(1.36, 0.019, 0.57), GRAPHITE)
	for i in 8:
		var vent := _box(gpu, Vector3(-0.07 + i * 0.043, -0.125, -0.062), Vector3(0.020, 0.007, 0.26), BLACK)
		vent.rotation.y = 0.26
	for x in [-1.01, 0.19]:
		for z in [-0.26, 0.18]:
			_disk(gpu, Vector3(x, -0.123, z), 0.022, 0.008, STEEL)
	_box(gpu, Vector3(-0.72, -0.125, 0.11), Vector3(0.49, 0.008, 0.025), GOLD.darkened(0.26))
	_print_detail(gpu, Vector3(-0.72, -0.121, 0.065), "PCIe  /  x16", 0.00145, Vector3(-PI / 2.0, 0, 0))
	_part_faces.gpu = _face(gpu, Vector3(-0.43, -0.23, 0.292), Vector2(1.47, 0.14))
	for x in [-0.78, -0.09]:
		_fan(gpu, Vector3(x, -0.315, -0.04), 0.24, Vector3(PI, 0, 0))
	var power := _part("psu")
	_box(power, Vector3(-0.66, -0.72, 0), Vector3(1.04, 0.43, 0.81), BLACK)
	_fan(power, Vector3(-0.69, -0.486, 0), 0.28, Vector3.ZERO)
	_part_faces.psu = _face(power, Vector3(-0.66, -0.72, 0.407), Vector2(1.04, 0.43))
	_box(power, Vector3(-1.218, -0.72, -0.18), Vector3(0.09, 0.205, 0.26), BLACK)
	_box(power, Vector3(PSU_PANEL_X - 0.016, -0.72, 0), Vector3(0.032, 0.33, 0.67), GRAPHITE)
	var drive := _part("storage")
	_box(drive, Vector3(0.80, SSD_BOTTOM_Y + 0.315, -0.28), Vector3(0.46, 0.63, 0.17), STEEL)
	_part_faces.storage = _face(drive, Vector3(0.80, -0.08, -0.193), Vector2(0.46, 0.63))
	for x in [0.572, 1.028]:
		_box(drive, Vector3(x, -0.078, -0.209), Vector3(0.020, 0.59, 0.034), GRAPHITE)


func _build_board_electronics(board: Node3D) -> void:
	# Soldered details share the PCB's picking ID and move with it as one part.
	for i in 9:
		var x := -0.70 + 0.081 * i
		_box(board, Vector3(x, 0.796, -0.346), Vector3(0.054, 0.070, 0.041), GRAPHITE)
		_box(board, Vector3(x, 0.80, -0.321), Vector3(0.031, 0.047, 0.011), STEEL.darkened(0.35))
		_disk(board, Vector3(x, 0.706, -0.345), 0.022, 0.042, BLACK, Vector3(PI / 2.0, 0, 0))
		_disk(board, Vector3(x, 0.706, -0.321), 0.019, 0.009, STEEL, Vector3(PI / 2.0, 0, 0))
	var chipset := Vector3(0.16, 0.055, -0.341)
	_box(board, chipset, Vector3(0.31, 0.25, 0.068), GRAPHITE)
	for i in 7:
		_box(board, chipset + Vector3((i - 3) * 0.037, 0, 0.040), Vector3(0.013, 0.214, 0.015), STEEL.darkened(0.43))
	_box(board, Vector3(-0.734, 0.126, -0.345), Vector3(0.16, 0.12, 0.050), BLACK)
	for i in 6:
		var y := 0.082 + i * 0.016
		for x in [-0.819, -0.649]:
			_box(board, Vector3(x, y, -0.36), Vector3(0.027, 0.007, 0.010), GOLD)
	_print_detail(board, Vector3(-0.57, 0.078, -0.365), "ATX  /  REV 2.1", 0.00105)
	_print_detail(board, Vector3(0.126, 0.881, -0.363), "DIMM A1 · A2", 0.0008)
	_print_detail(board, Vector3(0.317, 0.686, -0.362), "ATX_PWR", 0.0008)


func _print_detail(parent: Node3D, center: Vector3, text: String, pixel_size: float, angles := Vector3.ZERO) -> void:
	var marking := Label3D.new()
	marking.text = text
	marking.font_size = 28
	marking.outline_size = 0
	marking.pixel_size = pixel_size
	marking.modulate = Color("b0a999")
	marking.position = center
	marking.rotation = angles
	parent.add_child(marking)


func _build_mounts() -> void:
	for kind in EMPTY_MOUNTS:
		var anchor: Array = EMPTY_MOUNTS[kind]
		var mount := _group(self, StringName(kind))
		var center: Vector3 = anchor[0]
		var span: Vector2 = anchor[1]
		var click_area := _face(mount, center, span)
		var hidden := StandardMaterial3D.new()
		hidden.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hidden.albedo_color = Color.TRANSPARENT
		click_area.material_override = hidden
		click_area.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for x in [-1.0, 1.0]:
			for y in [-1.0, 1.0]:
				var corner := center + Vector3(span.x * x * 0.48, span.y * y * 0.48, 0.002)
				var edge := minf(span.x, span.y) * 0.18
				_box(mount, corner - Vector3(x * edge * 0.45, 0, 0), Vector3(edge, 0.012, 0.014), GOLD)
				_box(mount, corner - Vector3(0, y * edge * 0.45, 0), Vector3(0.012, edge, 0.014), GOLD)
		_empty_mounts[kind] = mount
	for kind in CONNECTOR_ANCHORS:
		var group := _group(self)
		var screws: Array[Node3D] = []
		var connectors: Array[Dictionary] = []
		var rear_angle := -PI / 2.0 if kind in ["gpu", "psu"] else 0.0
		var anchors: Array = SCREW_ANCHORS.get(kind, [])
		for i in anchors.size():
			var id := StringName("mount:%s:screw:%d" % [kind, i])
			screws.append(_mount_screw(group, id, anchors[i], rear_angle))
		for i in CONNECTOR_ANCHORS[kind].size():
			var id := StringName("mount:%s:connector:%d" % [kind, i])
			var key := "%s:%d" % [kind, i]
			var anchor: Vector3 = CONNECTOR_ANCHORS[kind][i]
			if PLUG_PINS.has(key):
				var endpoint := _connector(group, id, anchor, PLUG_PINS[key], UNPLUGGED_OFFSETS[key],
					CABLE_PORT_ROTATIONS.get(key, Vector3.ZERO), 0.63 if key == "cooling:0" else 1.0)
				_cable_targets[key] = endpoint
				connectors.append({"ends": [endpoint]})
			else:
				connectors.append({"lever": _latch(group, id, anchor, kind == "cpu")})
		if kind == "psu":
			connectors.append({"ends": _build_psu_ports(group)})
		_mounts[kind] = {"group": group, "screws": screws, "connectors": connectors}
	for slot in 2:
		for i in 2:
			var id := StringName(("ram_latch_" if slot == 0 else "ram2_latch_") + str(i))
			var anchor := Vector3(0.03 + 0.18 * slot, 0.835 if i == 0 else 0.185, -0.236)
			_ram_latches.append(_latch(_parts.motherboard, id, anchor, false))


func _build_psu_ports(parent: Node3D) -> Array[Dictionary]:
	var ends: Array[Dictionary] = []
	var ports := {
		"motherboard:0": Vector2(-0.64, 0.032),
		"motherboard:1": Vector2(-0.66, -0.221),
		"gpu:0": Vector2(-0.58, 0.212),
		"storage:1": Vector2(-0.815, 0.181),
	}
	for key in ports:
		var at: Vector2 = ports[key]
		var endpoint := _connector(parent, &"mount:psu:connector:0", Vector3(PSU_PANEL_X, at.x, at.y),
			Vector2i(4, 2), Vector3(-0.019, -0.022, 0.111), Vector3(0, PI / 2.0, 0))
		_cable_sources[key] = endpoint
		ends.append(endpoint)
	return ends


func _mount_screw(parent: Node3D, id: StringName, center: Vector3, angle := 0.0) -> Node3D:
	var group := _group(parent, id)
	group.position = center
	group.rotation.y = angle
	_disk(group, Vector3.ZERO, 0.053, 0.023, STEEL, Vector3(PI / 2.0, 0, 0))
	_disk(group, Vector3(0, 0, 0.013), 0.033, 0.008, BLACK, Vector3(PI / 2.0, 0, 0))
	var head := _group(group)
	_fastener(head, Vector3(0, 0, 0.023))
	return head


func _connector(parent: Node3D, id: StringName, surface: Vector3, pins: Vector2i,
		offset: Vector3, angles := Vector3.ZERO, size_factor := 1.0) -> Dictionary:
	var group := _group(parent, id)
	group.rotation = angles
	group.scale = Vector3.ONE * size_factor
	group.position = surface + group.basis.z * 0.010
	var spacing := minf(0.013, 0.112 / pins.y)
	var width := maxf(0.080, 0.022 + pins.x * spacing)
	var height := maxf(0.062, 0.022 + pins.y * spacing)
	var jack := _box(group, Vector3.ZERO, Vector3(width, height, 0.028), BLACK)
	for column in pins.x:
		for row in pins.y:
			var x := (column - (pins.x - 1) * 0.5) * spacing
			var y := (row - (pins.y - 1) * 0.5) * spacing
			_box(group, Vector3(x, y, 0.017), Vector3(spacing * 0.47, spacing * 0.47, 0.006), GOLD)
	var plug := _group(group)
	_box(plug, Vector3(0, 0, 0.030), Vector3(width - 0.014, height - 0.013, 0.035), PLASTIC)
	_box(plug, Vector3(0, 0, 0.050), Vector3(width * 0.63, height * 0.65, 0.012), GRAPHITE)
	_box(plug, Vector3(width * 0.37, 0, 0.050), Vector3(0.018, height * 0.53, 0.025), PLASTIC)
	for grip in [-0.20, 0.0, 0.20]:
		_box(plug, Vector3(0, height * grip, 0.057), Vector3(width * 0.56, 0.006, 0.006), STEEL.darkened(0.39))
	_box(plug, Vector3(0, 0, 0.064), Vector3(width * 0.71, height * 0.69, 0.026), BLACK)
	var wire_exit := Marker3D.new()
	wire_exit.position.z = 0.070
	plug.add_child(wire_exit)
	return {"jack": jack, "plug": plug, "offset": offset, "wire_exit": wire_exit}


func _latch(parent: Node3D, id: StringName, center: Vector3, metal: bool) -> Node3D:
	var group := _group(parent, id)
	group.position = center
	_box(group, Vector3.ZERO, Vector3(0.086, 0.061, 0.042), BLACK)
	var lever := _group(group)
	lever.position = Vector3(0, -0.014, 0.019)
	var finish := STEEL if metal else PLASTIC
	_box(lever, Vector3(0, 0.024, 0.011), Vector3(0.060, 0.067, 0.018), finish)
	_box(lever, Vector3(0, 0.052, 0.022), Vector3(0.064, 0.019, 0.020), finish.lightened(0.19))
	return lever


func pick_mesh(origin: Vector3, direction: Vector3) -> MeshInstance3D:
	var closest: MeshInstance3D
	var distance := INF
	for instance in _pick_meshes:
		if not instance.is_visible_in_tree():
			continue
		var inverse := instance.global_transform.affine_inverse()
		var hit: Variant = instance.get_aabb().grow(0.002).intersects_ray(inverse * origin, inverse.basis * direction)
		if hit == null:
			continue
		var hit_distance := direction.dot(instance.global_transform * hit - origin)
		if hit_distance < distance:
			closest = instance
			distance = hit_distance
	return closest


func _part_art(kind: String, record: Dictionary) -> Texture2D:
	match kind:
		"motherboard":
			return PartVisuals.board_texture(record.get("board_art", ""), PART_ART.motherboard)
		"cpu":
			if record.get("socket") == "AX4":
				return PartVisuals.AMDERA_CPU
		"ram", "ram2":
			var finish: String = record.get("heat_spreader_color", "")
			return PartVisuals.ram_heat_spreader(finish, true) if Ledger.HEAT_SPREADERS.has(finish) else PART_ART.ram
	return PART_ART[kind]


func _texture_material(source: Texture2D, region := Rect2i()) -> StandardMaterial3D:
	if not _texture_materials.has(source):
		var image := source.get_image()
		var cropped := image.get_region(image.get_used_rect() if not region.has_area() else region)
		cropped.generate_mipmaps()
		var material := StandardMaterial3D.new()
		material.albedo_texture = ImageTexture.create_from_image(cropped)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		material.texture_repeat = false
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.roughness = 0.59
		if source in [CHASSIS_ART, COVER_ART]:
			material.normal_enabled = true
			material.normal_texture = _metal_normal
			material.normal_scale = 0.22
			material.metallic = 0.25
		_texture_materials[source] = material
	return _texture_materials[source]


func _build_metal_finish() -> void:
	var grain := FastNoiseLite.new()
	grain.frequency = 0.235
	grain.fractal_octaves = 2
	_metal_normal = NoiseTexture2D.new()
	_metal_normal.width = 256
	_metal_normal.height = 96
	_metal_normal.noise = grain
	_metal_normal.seamless = true
	_metal_normal.as_normal_map = true
	_metal_normal.bump_strength = 1.5


func _fan(parent: Node3D, center: Vector3, radius: float, rotation_angles: Vector3) -> void:
	var fan := _group(parent)
	fan.position = center
	fan.rotation = rotation_angles
	_disk(fan, Vector3.ZERO, radius, 0.026, BLACK)
	for i in 7:
		var blade := _group(fan)
		blade.rotation.y = TAU * float(i) / 7.0
		var mesh := _box(blade, Vector3(radius * 0.55, 0.020, 0), Vector3(radius * 0.62, 0.018, radius * 0.22), STEEL)
		mesh.rotation.y = -0.35
	_disk(fan, Vector3(0, 0.033, 0), radius * 0.26, 0.021, GRAPHITE)


func _fastener(parent: Node3D, center: Vector3) -> void:
	_disk(parent, center, 0.042, 0.020, STEEL, Vector3(PI / 2.0, 0, 0))
	_box(parent, center + Vector3(0, 0, 0.012), Vector3(0.048, 0.010, 0.008), BLACK)
	_box(parent, center + Vector3(0, 0, 0.012), Vector3(0.010, 0.048, 0.008), BLACK)


func _part(kind: String) -> Node3D:
	var node := _group(self, StringName(kind))
	_parts[kind] = node
	return node


func _group(parent: Node3D, id: StringName = &"") -> Node3D:
	var group := Node3D.new()
	group.set_meta(&"pick_id", id if id != &"" else parent.get_meta(&"pick_id", &""))
	parent.add_child(group)
	return group


func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.53 if color in [STEEL, GOLD] else 0.74
		material.metallic = 0.44 if color in [STEEL, GOLD] else 0.08
		if color in [STEEL, GRAPHITE]:
			material.normal_enabled = true
			material.normal_texture = _metal_normal
			material.normal_scale = 0.23
		if color == LED:
			material.emission_enabled = true
			material.emission = color
			material.emission_energy_multiplier = 0.25
		_materials[color] = material
	return _materials[color]


func _box(parent: Node3D, center: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = dimensions
	return _mesh(parent, center, shape, color)


func _face(parent: Node3D, center: Vector3, dimensions: Vector2) -> MeshInstance3D:
	var shape := QuadMesh.new()
	shape.size = dimensions
	return _mesh(parent, center, shape, STEEL)


func _disk(parent: Node3D, center: Vector3, radius: float, depth: float, color: Color, rotation_angles := Vector3.ZERO) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = depth
	shape.radial_segments = 24
	shape.rings = 0
	var instance := _mesh(parent, center, shape, color)
	instance.rotation = rotation_angles
	return instance


func _mesh(parent: Node3D, center: Vector3, shape: Mesh, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = _material(color)
	instance.position = center
	instance.set_meta(&"pick_id", parent.get_meta(&"pick_id", &""))
	_pick_meshes.append(instance)
	parent.add_child(instance)
	return instance

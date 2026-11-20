extends Control
## Pixel-art image and matching visual hit areas share a 320 x 240 space.

signal hovered_part(name: String)

const CASE_ART := preload("res://Assets/Inspection/desktop_open.png")
const LID_ART := preload("res://Assets/Inspection/desktop_lid.png")
const EDITABLE_ART := preload("res://Assets/Physical/desktop_editable.png")
const RAM_ART := preload("res://Assets/Physical/ram_module.png")
const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
const PartVisuals := preload("res://Scripts/UI/part_visuals.gd")
const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")
const Peripherals := preload("res://Scripts/Equipment/peripheral_catalog.gd")
const PeripheralArt := preload("res://Scripts/UI/peripheral_art.gd")
const FanMotion := preload("res://Scripts/Equipment/fan_motion.gd")
const LATCHES := [Vector2(149, 45), Vector2(149, 103)]
const RAM_SLOT := Rect2(144, 43, 10, 64)
const RAM_INSTALLED := Rect2(146, 48, 6, 52)
const RAM_OFFSETS := [Vector2.ZERO, Vector2(20, 0), Vector2(10, 0), Vector2(30, 0)]
const BOARD_AREA := Rect2(Vector2(42, 38), PartVisuals.BOARD_ART_SIZE)
const CPU_SEAT := Rect2(BOARD_AREA.position + PartVisuals.AMDERA_CPU_SEAT.position, PartVisuals.AMDERA_CPU_SEAT.size)
const MOUNT_RECTS := {"motherboard": BOARD_AREA, "cooling": Rect2(80,55,49,51), "cpu": CPU_SEAT, "gpu": Rect2(32,119,173,30), "psu": Rect2(41,160,99,34), "storage": Rect2(211,103,29,40), "storage2": Rect2(211,42,29,40)}
const GPU_BAY := {"bracket": Vector2(34, 132), "latch": Vector2(186, 116)}
const INTERACTIVE_MOUNTS := ["cooling", "cpu", "gpu", "storage", "storage2", "psu", "motherboard"]
const SCREW_POINTS := {
	"gpu": [Vector2(33,121),Vector2(33,144)],
	"psu": [Vector2(28,164),Vector2(37,164),Vector2(28,191),Vector2(37,191)],
	"motherboard": [Vector2(46,42),Vector2(183,42),Vector2(46,108),Vector2(183,108),Vector2(46,151),Vector2(183,151)],
	"cooling": [Vector2(84,58),Vector2(125,58),Vector2(84,102),Vector2(125,102)],
	"storage": [Vector2(214,106),Vector2(237,106),Vector2(214,139),Vector2(237,139)]
}
const CONNECTOR_POINTS := {
	"gpu": [Vector2(184,121),Vector2(186,116)],
	"psu": [Vector2(141,176)],
	"motherboard": [Vector2(185,83),Vector2(67,41),Vector2(169,151)],
	"cooling": [Vector2(130,52)],
	"cpu": [Vector2(126,80)],
	"storage": [Vector2(218,143),Vector2(232,143)]
}
var layers: Dictionary = {}
var _case_model: Dictionary = {}
var _chassis_art: Texture2D
var _lid_art: Texture2D
const SCREWS := [Vector2(34, 30), Vector2(246, 30), Vector2(34, 190), Vector2(246, 190)]
const LID_RECT := Rect2(28, 24, 224, 172)
const PARKED_LID := Rect2(299, 26, 12, 171)
const PARTS := [
	[&"cpu", "CPU / cooler", Rect2(80, 55, 49, 51)],
	[&"ram", "Memória RAM", Rect2(142, 44, 33, 61)],
	[&"gpu", "Placa de vídeo (GPU)", Rect2(49, 119, 156, 30)],
	[&"psu", "Fonte de alimentação", Rect2(41, 160, 99, 34)],
	[&"ssd", "Armazenamento / SSD", Rect2(211, 103, 29, 40)],
	[&"storage", "Baia de armazenamento", Rect2(211, 42, 29, 40)],
	[&"cables", "Cabos de energia e dados", Rect2(188, 75, 20, 110)],
	[&"motherboard", "Placa-mãe", Rect2(42, 38, 145, 115)],
]

var session: RefCounted
var hovered: StringName = &""
var zoom := 1.0
var pan := Vector2.ZERO
var _panning := false
var _fans := FanMotion.new()
var _gpu_rgb_lit := false
var _gpu_rgb_time := 0.0
const FIT_BOUNDS := Rect2(20, 16, 296, 220)
const GPU_RGB_ZONES := 18
const GPU_RGB_PERIOD := 6.0


func _ready() -> void:
	clip_contents = true
	for kind in ["chassis", "motherboard", "cooling", "cpu", "gpu", "psu", "storage", "ram", "lid"]:
		layers[kind] = load("res://Assets/Inspection/Layers/" + kind + ".png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)
	mouse_exited.connect(_clear_hover)


func _process(delta: float) -> void:
	if session == null or not is_instance_valid(session.workshop): return
	var ledger: RefCounted = session.workshop.ledger
	var moved := _fans.advance(ledger, session.physical_pc_id, delta)
	if not is_visible_in_tree() or (session.lid_attached and not _case_model.get("glass", false)): return
	var lit: bool = ledger.gpu_rgb_active(session.physical_pc_id)
	_gpu_rgb_time = fposmod(_gpu_rgb_time + delta, GPU_RGB_PERIOD) if lit else 0.0
	if moved or lit or lit != _gpu_rgb_lit: queue_redraw()
	_gpu_rgb_lit = lit


func configure(value: RefCounted) -> void:
	if value != session:
		zoom = 1.0
		pan = Vector2.ZERO
		_panning = false
		_gpu_rgb_lit = false
		_gpu_rgb_time = 0.0
		_configure_case_art(value)
	if session != null and session.changed.is_connected(_state_changed):
		session.changed.disconnect(_state_changed)
	session = value
	if session != null:
		session.changed.connect(_state_changed)
	_clear_hover()
	queue_redraw()


func _configure_case_art(value: RefCounted) -> void:
	var key := ""
	if value != null and is_instance_valid(value.workshop):
		var pc: Dictionary = value.workshop.ledger.item(value.physical_pc_id)
		key = pc.get("case_key", "")
	_case_model = Cases.get_model(key)
	if _case_model.is_empty():
		_chassis_art = layers.chassis
		_lid_art = layers.lid
	else:
		_chassis_art = Cases.inspection_texture(key, "chassis")
		_lid_art = Cases.inspection_texture(key, "lid")


func _state_changed() -> void:
	# Invalidate old hit feedback when the cover occludes or exposes parts.
	_clear_hover()
	queue_redraw()


func art_scale() -> float:
	# Fit the complete chassis, parked lid and fastener tray with a safe margin.
	var available := (size - Vector2(16, 16)).max(Vector2.ONE)
	return minf(available.x / FIT_BOUNDS.size.x, available.y / FIT_BOUNDS.size.y) * zoom


func art_origin() -> Vector2:
	return size * 0.5 - FIT_BOUNDS.get_center() * art_scale() + pan


func art_to_local(point: Vector2) -> Vector2:
	return art_origin() + point * art_scale()


func local_to_art(point: Vector2) -> Vector2:
	return (point - art_origin()) / maxf(0.001, art_scale())


func hit_at(point: Vector2) -> StringName:
	if session == null:
		return &""
	if session.lid_attached:
		for i in range(4):
			if point.distance_to(SCREWS[i]) <= 8.0:
				return StringName("screw_" + str(i))
		if LID_RECT.has_point(point):
			return &"lid"
	else:
		if PARKED_LID.grow(3).has_point(point):
			return &"lid"
		if is_instance_valid(session.workshop):
			var pc: Dictionary = session.workshop.ledger.item(session.physical_pc_id)
			if _shows_gpu_bay(pc):
				for control in GPU_BAY:
					if point.distance_to(GPU_BAY[control]) < 6.0: return StringName("gpu_bay:" + control)
			for kind in INTERACTIVE_MOUNTS:
				if kind == "cpu" and pc.components.has("cooling"): continue
				if not pc.components.has(kind): continue
				var mount: Dictionary = session.workshop.ledger.mounts(session.physical_pc_id, kind)
				for i in range(mount.screws.size()):
					if point.distance_to(mount_point(kind, i, false)) <= 3.5: return StringName("mount:%s:screw:%d" % [kind, i])
				for i in range(mount.connections.size()):
					if not _shows_connector(pc, kind, i): continue
					if point.distance_to(mount_point(kind, i, true)) <= 4: return StringName("mount:%s:connector:%d" % [kind, i])
			for slot in session.workshop.ledger.ram_slots(session.physical_pc_id):
				var offset: Vector2 = RAM_OFFSETS[slot]
				for i in range(2):
					if point.distance_to(LATCHES[i] + offset) <= 5: return StringName("%s_latch_%d" % [Hardware.RAM_KEYS[slot], i])
				if ram_rect(slot).has_point(point): return StringName(Hardware.RAM_KEYS[slot])
			var selected: Dictionary = session.workshop.ledger.item(session.workshop.selected_part)
			if not selected.is_empty() and selected.kind != "storage" and MOUNT_RECTS.has(selected.kind) and not pc.components.has(selected.kind) and mount_rect(selected.kind, pc).has_point(point): return StringName(selected.kind)
			for kind in INTERACTIVE_MOUNTS:
				if kind == "cpu" and pc.components.has("cooling"): continue
				if kind == "cooling" and not pc.components.has("cooling") and mount_rect("cpu", pc).has_point(point): continue
				if mount_rect(kind, pc).has_point(point): return StringName(kind)
		for item in PARTS:
			if item[0] == &"ram" and is_instance_valid(session.workshop): continue
			if item[2].has_point(point):
				return item[0]
	return &""


func part_name(id: StringName) -> String:
	if session != null and is_instance_valid(session.workshop):
		var record: Dictionary = session.workshop.ledger.item(session.physical_pc_id)
		if String(id).begins_with("gpu_bay:"):
			if id == &"gpu_bay:bracket": return "Proteção traseira PCIe · " + ("removida" if record.get("gpu_bracket_open", false) else "Phillips para remover")
			return "Trava PCIe vazia · " + ("aberta" if record.get("gpu_slot_open", false) else "Mãos para abrir")
		if String(id).begins_with("mount:"):
			var bits := String(id).split(":")
			var kind: String = bits[1]
			var index := int(bits[3])
			var mount: Dictionary = session.workshop.ledger.mounts(session.physical_pc_id, kind)
			var part := Prefs.t(session.workshop.ledger.component_label(kind))
			if bits[2] == "screw" and kind in ["gpu", "psu"]:
				return Prefs.t("%s · parafuso %d do suporte TRASEIRO · %s") % [part, index+1, Prefs.t("fixado" if mount.screws[index] else "retirado")]
			if bits[2] == "screw":
				return "%s · %s %s" % [part, Prefs.t("Parafuso %d") % (index + 1), Prefs.t("fixado" if mount.screws[index] else "solto")]
			var connector: String = session.workshop.ledger.CONNECTIONS[kind][index]
			var label := Prefs.t(connector)
			if kind == "gpu" and connector == "energia":
				var gpu: Dictionary = session.workshop.ledger.item(record.components.get("gpu", ""))
				label = Peripherals.plugs_label(Peripherals.gpu_profile(gpu).get("plugs", []))
			return "%s · %s %s" % [part, label, Prefs.t("conectado / travado" if mount.connections[connector] else "liberado")]
		var target := String(id)
		var slot := Hardware.RAM_KEYS.find(target.get_slice("_latch_", 0))
		if slot >= 0:
			if slot not in session.workshop.ledger.ram_slots(session.physical_pc_id): return "Slot indisponível."
			var label: String = Hardware.RAM_LABELS[slot]
			if target.contains("_latch_"):
				var clip := int(target.get_slice("_latch_", 1))
				var closed: bool = session.workshop.ledger.ram_latches(session.physical_pc_id, slot)[clip]
				return Prefs.t("RAM %s · trava %s · %s") % [label, Prefs.t("superior" if clip == 0 else "inferior"), Prefs.t("fechada" if closed else "aberta")]
			var installed: String = record.components.get(target, "")
			return "RAM %s · %s" % [label, Prefs.t("Slot vazio — selecione um módulo e clique") if installed.is_empty() else session.workshop.ledger.known_description(installed)]
		var keys := {&"cpu": "cpu", &"cooling": "cooling", &"gpu": "gpu", &"psu": "psu", &"ssd": "storage", &"storage": "storage", &"storage2": "storage2", &"motherboard": "motherboard"}
		if keys.has(id):
			var installed: String = record.components.get(keys[id], "")
			if id == &"cpu" and installed.is_empty() and record.components.has("motherboard"):
				return PartVisuals.socket_contact_label(session.workshop.ledger.item(record.components.motherboard), true)
			if id == &"storage2" and installed.is_empty(): return "Baia SATA 2 · selecione um disco"
			return session.workshop.ledger.known_description(installed) if installed != "" else "Encaixe vazio — selecione a peça e clique para instalar"
	if id == &"lid":
		return "Tampa lateral" if session.lid_attached else "Tampa retirada — clique para recolocar"
	if String(id).begins_with("screw_"):
		var index := int(String(id).trim_prefix("screw_"))
		return Prefs.t("Parafuso %d — %s") % [index + 1, Prefs.t("fixado" if session.screws[index] else "retirado; clique para fixar")]
	for item in PARTS:
		if item[0] == id:
			return item[1]
	return "Nenhuma peça selecionada"


func _get_tooltip(at_position: Vector2) -> String:
	var id := hit_at(local_to_art(at_position))
	return Prefs.t(part_name(id)) if id != &"" else ""


func _clear_hover() -> void:
	hovered = &""
	hovered_part.emit("Passe o mouse sobre o gabinete.")
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if session == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_panning = event.pressed and session.tool == &"hands"
		accept_event()
		return
	if event is InputEventMouseMotion and _panning:
		if session.tool == &"hands" and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			pan += event.relative
			pan = pan.clamp(-size * 0.8, size * 0.8)
			queue_redraw()
			accept_event()
			return
		_panning = false
	if event is InputEventMouseButton and event.pressed and session.tool == &"hands":
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var anchor := local_to_art(event.position)
			zoom = clampf(zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), 1.0, 3.0)
			pan += event.position - art_to_local(anchor)
			if zoom == 1.0: pan = Vector2.ZERO
			queue_redraw()
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_RIGHT:
			zoom = 1.0
			pan = Vector2.ZERO
			queue_redraw()
			accept_event()
			return
	if event is InputEventMouse:
		var id := hit_at(local_to_art(event.position))
		if event is InputEventMouseMotion:
			hovered = id
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if id != &"" else Control.CURSOR_ARROW
			hovered_part.emit(part_name(id) if id != &"" else "Passe o mouse sobre o gabinete.")
			queue_redraw()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			session.interact_with(id)


func _draw_screw(point: Vector2, installed: bool, active: bool) -> void:
	var r := Rect2(point - Vector2(2, 2), Vector2(4, 4))
	draw_circle(point, 2.4, Color("0a1722"))
	if installed:
		draw_circle(point, 1.8, Color("a9bdc9"))
		draw_line(point + Vector2(-1.1, 0), point + Vector2(1.1, 0), Color("314959"), 0.5)
		draw_line(point + Vector2(0, -1.1), point + Vector2(0, 1.1), Color("314959"), 0.5)
	else:
		draw_rect(r, Color("344e60"), false, 1.0)
	if active:
		draw_rect(r.grow(3), Color("71dded"), false, 1.0)


func _draw() -> void:
	if session == null:
		return
	draw_set_transform(art_origin(), 0.0, Vector2.ONE * art_scale())
	var physical := is_instance_valid(session.workshop)
	if physical:
		draw_texture_rect(_chassis_art, Rect2(0,0,320,240), false)
		var pc: Dictionary = session.workshop.ledger.item(session.physical_pc_id)
		var show_internals: bool = not session.lid_attached or _case_model.get("glass", false)
		for kind in ["motherboard", "cpu", "cooling", "gpu", "psu", "storage", "storage2"]:
			if not pc.components.has(kind): continue
			var texture: Texture2D = layers["storage" if kind == "storage2" else kind]
			var has_rgb := false
			if kind == "motherboard":
				var board: Dictionary = session.workshop.ledger.item(pc.components[kind])
				texture = PartVisuals.board_artwork(board, false)
			elif kind == "cpu":
				var cpu: Dictionary = session.workshop.ledger.item(pc.components[kind])
				texture = PartVisuals.icon(cpu)
			elif kind == "cooling":
				texture = PartVisuals.cooler_artwork(session.workshop.ledger.item(pc.components[kind]))
			elif kind == "gpu":
				var card: Dictionary = session.workshop.ledger.item(pc.components.gpu)
				texture = PartVisuals.gpu_side_artwork(card)
				has_rgb = Peripherals.gpu(card).get("rgb", false)
			elif kind in ["storage", "storage2"]:
				texture = PartVisuals.peripheral_artwork(session.workshop.ledger.item(pc.components[kind]))
			var rect := mount_rect(kind, pc)
			draw_texture_rect(texture, rect, false)
			if has_rgb and show_internals: _draw_gpu_rgb(rect)
		if show_internals: _draw_fans(pc)
		if session.lid_attached and _case_model.get("glass", false):
			_draw_cables(pc)
			_draw_ram_slots(pc, false)
	else:
		draw_texture(CASE_ART, Vector2.ZERO)
	if session.lid_attached:
		if physical: draw_texture_rect(_lid_art, Rect2(0,0,320,240), false)
		else: draw_texture(LID_ART, Vector2.ZERO)
		if hovered == &"lid" or session.selected == &"lid":
			draw_rect(LID_RECT, Color("71dded"), false, 1.0)
		for i in range(4):
			var id := StringName("screw_" + str(i))
			_draw_screw(SCREWS[i], session.screws[i], hovered == id or session.selected == id)
	else:
		if physical:
			var record: Dictionary = session.workshop.ledger.item(session.physical_pc_id)
			_draw_cables(record)
			if _shows_gpu_bay(record): _draw_gpu_bay(record)
			for kind in MOUNT_RECTS:
				if kind == "cpu" and record.components.has("cooling"): continue
				var rect := mount_rect(kind, record)
				if kind in ["storage", "storage2"]:
					draw_string(ThemeDB.fallback_font, rect.position - Vector2(0, 3), "SATA 1" if kind == "storage" else "SATA 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("91acb2"))
				if hovered == StringName(kind) or session.selected == StringName(kind): draw_rect(rect, Color("71dded"), false, 1)
				if not record.components.has(kind):
					draw_rect(rect, Color("284455"), false, 1)
					continue
				var mount: Dictionary = session.workshop.ledger.mounts(session.physical_pc_id, kind)
				for i in range(mount.screws.size()):
					_draw_screw(mount_point(kind,i,false), mount.screws[i], hovered == StringName("mount:%s:screw:%d" % [kind,i]))
				for i in range(mount.connections.size()):
					if not _shows_connector(record, kind, i): continue
					var p := mount_point(kind,i,true)
					var connected: bool = mount.connections[session.workshop.ledger.CONNECTIONS[kind][i]]
					if kind == "cpu":
						_draw_socket_retention(record, p, connected)
					else:
						draw_rect(Rect2(p - Vector2(3,2),Vector2(6,4)),Color("6bbdc9") if connected else Color("dca56b"))
					if hovered == StringName("mount:%s:connector:%d" % [kind,i]): draw_rect(Rect2(p - Vector2(4,4),Vector2(8,8)),Color("71dded"),false,1)
			_draw_ram_slots(record)
		# The removed lid rests edge-on beside the chassis, and is clickable.
		_draw_parked_lid()
		if hovered == &"lid" or session.selected == &"lid":
			draw_rect(PARKED_LID.grow(2), Color("71dded"), false, 1.0)
		if not physical:
			for item in PARTS:
				if hovered == item[0] or session.selected == item[0]:
					draw_rect(item[2].grow(2), Color("71dded"), false, 1.0)
	var tray_index := 0
	for installed in session.screws:
		if not installed:
			_draw_screw(Vector2(89 + tray_index * 34, 228), true, false)
			tray_index += 1
	draw_set_transform(Vector2.ZERO)


func _draw_parked_lid() -> void:
	if _case_model.is_empty():
		draw_rect(PARKED_LID, Color("4b6479"))
		draw_rect(Rect2(301, 28, 2, 166), Color("8ca5b6"))
		return
	var paint := Color(_case_model.paint)
	var edge := paint.lightened(0.35)
	var panel := PARKED_LID.grow(-2)
	draw_rect(PARKED_LID, paint)
	draw_rect(Rect2(PARKED_LID.position, Vector2(2, PARKED_LID.size.y)), edge)
	if _case_model.glass:
		var glass := Color(_case_model.accent).darkened(0.46)
		draw_rect(panel, glass)
		draw_line(panel.position, Vector2(panel.get_center().x, panel.end.y), glass.lightened(0.22), 1.0)
	else:
		draw_rect(panel, paint.darkened(0.19))


func mount_rect(kind: String, pc: Dictionary) -> Rect2:
	if kind == "gpu":
		var card: Dictionary = session.workshop.ledger.item(pc.components.get("gpu", ""))
		var spec := Peripherals.gpu(card)
		if not spec.is_empty():
			return Rect2(MOUNT_RECTS.gpu.position, Vector2(roundf(173.0 * spec.size_mm / 350.0), 25 + spec.slots * 4))
	if kind in ["motherboard", "cpu", "cooling"]:
		var board: Dictionary = session.workshop.ledger.item(pc.components.get("motherboard", ""))
		if board.is_empty(): return MOUNT_RECTS[kind]
		if kind == "motherboard":
			return Rect2(BOARD_AREA.position, Vector2(BOARD_AREA.size.x, 102)) if Cases.board_format(board) == "micro-ATX" else BOARD_AREA
		var seat := Rect2(PartVisuals.board_cpu_seat(board))
		seat.position += BOARD_AREA.position
		if kind == "cpu": return seat
		return Rect2(seat.get_center() - MOUNT_RECTS.cooling.size * 0.5, MOUNT_RECTS.cooling.size)
	return MOUNT_RECTS[kind]


func mount_point(kind: String, index: int, connector: bool) -> Vector2:
	var pc: Dictionary = session.workshop.ledger.item(session.physical_pc_id)
	if kind == "storage2":
		return (CONNECTOR_POINTS.storage[index] if connector else SCREW_POINTS.storage[index]) + Vector2(0, -61)
	if kind == "gpu" and connector:
		var card: Dictionary = session.workshop.ledger.item(pc.components.get("gpu", ""))
		if not Peripherals.gpu(card).is_empty() and index == 0:
			var card_rect := mount_rect(kind, pc)
			var connector_x := float(PeripheralArt.GPU_SIDE_SOCKET_X) / PeripheralArt.GPU_SIDE.get_width()
			return card_rect.position + Vector2(roundf(card_rect.size.x * connector_x), 4)
	if kind == "motherboard" and (index >= 4 or (connector and index == 2)):
		var point: Vector2 = CONNECTOR_POINTS[kind][index] if connector else SCREW_POINTS[kind][index]
		return Vector2(point.x, mount_rect(kind, pc).end.y - 3)
	if kind == "cpu" and connector:
		var seat := mount_rect(kind, pc)
		return Vector2(seat.end.x + 5, seat.get_center().y)
	if kind == "cooling":
		var offset := mount_rect(kind, pc).position - MOUNT_RECTS.cooling.position
		return (CONNECTOR_POINTS[kind][index] if connector else SCREW_POINTS[kind][index]) + offset
	return CONNECTOR_POINTS[kind][index] if connector else SCREW_POINTS[kind][index]


func _shows_connector(pc: Dictionary, kind: String, index: int) -> bool:
	if kind != "gpu" or index != 0: return true
	return session.workshop.ledger.gpu_has_auxiliary(session.workshop.ledger.item(pc.components.gpu))


func _shows_gpu_bay(pc: Dictionary) -> bool:
	if pc.components.has("gpu") or not pc.components.has("motherboard"): return false
	return pc.has("gpu_bracket_open") or pc.has("gpu_slot_open") or not Peripherals.gpu(session.workshop.ledger.item(session.workshop.selected_part)).is_empty()


func _draw_gpu_bay(pc: Dictionary) -> void:
	for control in GPU_BAY:
		var state: bool = pc.get("gpu_bracket_open" if control == "bracket" else "gpu_slot_open", false)
		var point: Vector2 = GPU_BAY[control]
		draw_rect(Rect2(point - Vector2(4, 5), Vector2(8, 10)), Color("314550") if state else Color("c2966d"))
		if hovered == StringName("gpu_bay:" + control):
			draw_rect(Rect2(point - Vector2(6, 6), Vector2(12, 12)), Color("71dded"), false, 1.0)


func _draw_gpu_rgb(card: Rect2) -> void:
	var origin := (card.position + card.size * Vector2(0.19, 0.83)).round()
	var strip := Rect2(origin, Vector2(roundf(card.size.x * 0.60), 2))
	draw_rect(strip.grow(1), Color("19262e"))
	draw_rect(strip, Color("3f4c53"))
	if not _gpu_rgb_lit: return
	for index in range(GPU_RGB_ZONES):
		var position := float(index) / GPU_RGB_ZONES
		var start := roundf(strip.size.x * position)
		var end := roundf(strip.size.x * (index + 1) / GPU_RGB_ZONES)
		var color := Color.from_hsv(fposmod(position * 0.83 - _gpu_rgb_time / GPU_RGB_PERIOD, 1.0), 0.77, 1.0)
		var segment := Rect2(strip.position + Vector2(start, 0), Vector2(end - start, strip.size.y))
		draw_rect(segment.grow_individual(0, 2, 0, 2), Color(color, 0.21))
		draw_rect(segment, color)
		draw_rect(Rect2(segment.position, Vector2(segment.size.x, 1)), color.lerp(Color.WHITE, 0.26))


func _draw_fans(pc: Dictionary) -> void:
	var ledger: RefCounted = session.workshop.ledger
	for index in range(ledger.fan_count(pc.id, "case")):
		_draw_rotor("case", index, Vector2(264, 54 + index * 37), 21.0)
	for kind in ["cooling", "psu"]:
		if not pc.components.has(kind): continue
		var rect := mount_rect(kind, pc)
		var center := rect.get_center() if kind == "cooling" else rect.position + Vector2(26, 17)
		_draw_rotor(kind, 0, center, minf(rect.size.x, rect.size.y) * 0.78)


func _draw_rotor(group: String, index: int, center: Vector2, radius: float) -> void:
	var size := Vector2.ONE * radius
	draw_texture_rect(PeripheralArt.rotor(_fans.phase(group, index)), Rect2(center - size * 0.5, size), false)


func ram_rect(slot: int) -> Rect2:
	return Rect2(RAM_SLOT.position + RAM_OFFSETS[slot], RAM_SLOT.size)


func _draw_socket_retention(pc: Dictionary, handle: Vector2, closed: bool) -> void:
	var board: Dictionary = session.workshop.ledger.item(pc.components.motherboard)
	var socket := Hardware.socket(board.get("socket", ""))
	var seat := mount_rect("cpu", pc)
	var top := Vector2(handle.x - 4, seat.position.y + 3)
	# LGA uses a load plate. The AM4 ZIF socket uses only a side lever.
	if socket == "AM5" or socket.begins_with("LGA"):
		var metal := Color("b9c3c8")
		if closed:
			draw_rect(seat.grow(-1), metal, false, 1.0)
			draw_line(seat.position + Vector2(3, 2), Vector2(seat.end.x - 3, seat.position.y + 2), metal, 2.0)
		else:
			var hinge := seat.position + Vector2(0, 1)
			draw_rect(Rect2(hinge - Vector2(8, 0), Vector2(7, seat.size.y)), metal, false, 1.0)
	var tip := Vector2(handle.x, handle.y) if closed else Vector2(handle.x + 3, handle.y - 4)
	draw_line(top, tip, Color("b9d9dc") if closed else Color("e4bd87"), 1.0)
	draw_line(tip, tip + Vector2(-3, 0), Color("f0f0df"), 1.0)


func _draw_ram_slots(record: Dictionary, show_highlights: bool = true) -> void:
	var slots: Array = session.workshop.ledger.ram_slots(session.physical_pc_id)
	for slot in slots:
		var offset: Vector2 = RAM_OFFSETS[slot]
		var key: String = Hardware.RAM_KEYS[slot]
		var clips: Array = session.workshop.ledger.ram_latches(session.physical_pc_id,slot)
		var channel_color := Color("89b8bf") if slot % 2 else Color("c2c9a4")
		draw_string(ThemeDB.fallback_font,Vector2(145,114)+offset,Hardware.RAM_LABELS[slot],HORIZONTAL_ALIGNMENT_LEFT,-1,6,channel_color)
		# Socket, key and installed module share one top-down center line.
		draw_rect(Rect2(Vector2(145,47)+offset,Vector2(8,54)),Color("10191e"))
		draw_rect(Rect2(Vector2(146,48)+offset,Vector2(6,52)),channel_color.darkened(0.65))
		draw_rect(Rect2(Vector2(147,48)+offset,Vector2(4,52)),Color("080e12"))
		if record.components.has(key):
			# Orthographic view of the heat spreader's upper spine; no PCB face.
			var module_rect := Rect2(RAM_INSTALLED.position + offset, RAM_INSTALLED.size)
			draw_rect(Rect2(module_rect.position + Vector2(1,0.5), module_rect.size),Color(0,0,0,0.35))
			var module: Dictionary = session.workshop.ledger.item(record.components[key])
			var art := PartVisuals.memory_artwork(module, true)
			draw_texture_rect(art, module_rect, false)
		else:
			for y in range(50,99,2):
				draw_rect(Rect2(Vector2(147,y)+offset,Vector2(0.65,0.6)),Color("b99a54"))
				draw_rect(Rect2(Vector2(150.35,y)+offset,Vector2(0.65,0.6)),Color("8e773e"))
			draw_rect(Rect2(Vector2(147,78)+offset,Vector2(4,2)),Color("64716b"))
		for i in range(2):
			var p: Vector2 = LATCHES[i]+offset
			var closed: bool = clips[i]
			var direction := -1.0 if i == 0 else 1.0
			var clip_center := p + Vector2(0,0 if closed else direction*3)
			draw_rect(Rect2(clip_center-Vector2(4,2),Vector2(8,4)),Color("26333b"))
			draw_rect(Rect2(clip_center-Vector2(3,1.5),Vector2(6,2.5)),Color("9bafb3") if closed else Color("c9b28c"))
			draw_line(clip_center+Vector2(-3,-1),clip_center+Vector2(3,-1),Color("d0dcdb"),0.5)
			draw_rect(Rect2(clip_center+Vector2(-1,-1),Vector2(2,2)),Color("53636a"))
			var id := StringName("%s_latch_%d" % [key, i])
			if show_highlights and (hovered == id or session.selected == id): draw_rect(Rect2(p-Vector2(5,5),Vector2(10,10)),Color("71dded"),false,1)
		if show_highlights and (hovered == StringName(key) or session.selected == StringName(key)): draw_rect(ram_rect(slot),Color("71dded"),false,1)

func _draw_cables(record: Dictionary) -> void:
	var routes := {
		"gpu": [[Vector2(184,121),Vector2(198,121),Vector2(198,176),Vector2(141,176)]],
		"storage": [[Vector2(218,143),Vector2(218,184),Vector2(165,184),Vector2(165,151)], [Vector2(232,143),Vector2(232,178),Vector2(141,178)]],
		"storage2": [[Vector2(218,82),Vector2(209,82),Vector2(209,151),Vector2(165,151)], [Vector2(232,82),Vector2(242,100),Vector2(242,178),Vector2(141,178)]],
		"motherboard": [[Vector2(182,83),Vector2(194,83),Vector2(194,174),Vector2(141,174)], [Vector2(67,41),Vector2(67,29),Vector2(203,29),Vector2(203,172),Vector2(141,172)], [Vector2(169,151),Vector2(208,151),Vector2(208,190),Vector2(246,190)]],
		"cooling": [[Vector2(130,52),Vector2(135,52),Vector2(135,76),Vector2(128,76)]]
	}
	for kind in routes:
		if not record.components.has(kind): continue
		var mount: Dictionary = session.workshop.ledger.mounts(session.physical_pc_id,kind)
		for i in range(routes[kind].size()):
			if not _shows_connector(record, kind, i): continue
			if not mount.connections[session.workshop.ledger.CONNECTIONS[kind][i]]: continue
			var points := PackedVector2Array(routes[kind][i])
			points[0] = mount_point(kind, i, true)
			draw_polyline(points,Color("080f16"),2.5)
			draw_polyline(points,Color("7c6053") if kind == "storage" and i == 0 else Color("445767"),1.1)



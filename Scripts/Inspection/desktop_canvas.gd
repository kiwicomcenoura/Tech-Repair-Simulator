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
const LATCHES := [Vector2(149, 45), Vector2(149, 103)]
const RAM_SLOT := Rect2(144, 43, 10, 64)
const RAM_INSTALLED := Rect2(145, 48, 8, 52)
const RAM_SLOT_SPACING := Vector2(20, 0)
const BOARD_AREA := Rect2(Vector2(42, 38), PartVisuals.BOARD_ART_SIZE)
const CPU_SEAT := Rect2(BOARD_AREA.position + PartVisuals.AMDERA_CPU_SEAT.position, PartVisuals.AMDERA_CPU_SEAT.size)
const MOUNT_RECTS := {"motherboard": BOARD_AREA, "cooling": Rect2(80,55,49,51), "cpu": CPU_SEAT, "gpu": Rect2(32,119,173,30), "psu": Rect2(41,160,99,34), "storage": Rect2(211,103,29,40)}
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
	"motherboard": [Vector2(182,83),Vector2(67,41),Vector2(169,151)],
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
const FIT_BOUNDS := Rect2(20, 16, 296, 220)


func _ready() -> void:
	clip_contents = true
	for kind in ["chassis", "motherboard", "cooling", "cpu", "gpu", "psu", "storage", "ram", "lid"]:
		layers[kind] = load("res://Assets/Inspection/Layers/" + kind + ".png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)
	mouse_exited.connect(_clear_hover)


func configure(value: RefCounted) -> void:
	if value != session:
		zoom = 1.0
		pan = Vector2.ZERO
		_panning = false
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
			for kind in ["cooling", "cpu", "gpu", "storage", "psu", "motherboard"]:
				if kind == "cpu" and pc.components.has("cooling"): continue
				if not pc.components.has(kind): continue
				var mount: Dictionary = session.workshop.ledger.mounts(session.physical_pc_id, kind)
				for i in range(mount.screws.size()):
					if point.distance_to(mount_point(kind, i, false)) <= 3.5: return StringName("mount:%s:screw:%d" % [kind, i])
				for i in range(mount.connections.size()):
					if point.distance_to(mount_point(kind, i, true)) <= 4: return StringName("mount:%s:connector:%d" % [kind, i])
			if pc.components.has("motherboard"):
				for slot in range(2):
					var offset := RAM_SLOT_SPACING * slot
					for i in range(2):
						if point.distance_to(LATCHES[i]+offset) <= 6: return StringName(("ram_latch_" if slot == 0 else "ram2_latch_")+str(i))
					if Rect2(RAM_SLOT.position+offset,RAM_SLOT.size).has_point(point): return &"ram" if slot == 0 else &"ram2"
			var selected: Dictionary = session.workshop.ledger.item(session.workshop.selected_part)
			if not selected.is_empty() and MOUNT_RECTS.has(selected.kind) and not pc.components.has(selected.kind) and mount_rect(selected.kind, pc).has_point(point): return StringName(selected.kind)
			for kind in ["cooling", "cpu", "gpu", "storage", "psu", "motherboard"]:
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
		if String(id).begins_with("mount:"):
			var bits := String(id).split(":")
			var kind: String = bits[1]
			var index := int(bits[3])
			var mount: Dictionary = session.workshop.ledger.mounts(session.physical_pc_id, kind)
			var part := Prefs.t(session.workshop.ledger.PART_NAMES[kind])
			if bits[2] == "screw" and kind in ["gpu", "psu"]:
				return Prefs.t("%s · parafuso %d do suporte TRASEIRO · %s") % [part, index+1, Prefs.t("fixado" if mount.screws[index] else "retirado")]
			if bits[2] == "screw":
				return "%s · %s %s" % [part, Prefs.t("Parafuso %d") % (index + 1), Prefs.t("fixado" if mount.screws[index] else "solto")]
			var connector: String = session.workshop.ledger.CONNECTIONS[kind][index]
			return "%s · %s %s" % [part, Prefs.t(connector), Prefs.t("conectado / travado" if mount.connections[connector] else "liberado")]
		if String(id).begins_with("ram2_latch_"):
			if not record.components.has("motherboard"): return "Instale a placa-mãe."
			var index := int(String(id).trim_prefix("ram2_latch_"))
			return Prefs.t("RAM A2 · trava %s · %s") % [Prefs.t("superior" if index == 0 else "inferior"), Prefs.t("fechada" if session.workshop.ledger.ram_latches(session.physical_pc_id,1)[index] else "aberta")]
		if id == &"ram2":
			var installed: String = record.components.get("ram2","")
			return "RAM A2 · slot vazio — selecione uma RAM e clique" if installed.is_empty() else "RAM A2 · "+session.workshop.ledger.known_description(installed)
		if String(id).begins_with("ram_latch_"):
			if not record.components.has("motherboard"): return "Instale a placa-mãe para acessar as travas da RAM."
			var index := int(String(id).trim_prefix("ram_latch_"))
			return Prefs.t("Trava %s da RAM — %s") % [Prefs.t("superior" if index == 0 else "inferior"), Prefs.t("fechada" if record.latches[index] else "aberta")]
		if id == &"ram":
			if not record.components.has("motherboard"): return "Instale a placa-mãe para acessar o slot de RAM."
			var installed: String = record.components.get("ram", "")
			return "Slot RAM A1 vazio — selecione um módulo e clique para encaixar" if installed == "" else "RAM A1 · "+session.workshop.ledger.known_description(installed)
		var keys := {&"cpu": "cpu", &"cooling": "cooling", &"gpu": "gpu", &"psu": "psu", &"ssd": "storage", &"storage": "storage", &"motherboard": "motherboard"}
		if keys.has(id):
			var installed: String = record.components.get(keys[id], "")
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
		for kind in ["motherboard", "cpu", "cooling", "gpu", "psu", "storage"]:
			if not pc.components.has(kind): continue
			var texture: Texture2D = layers[kind]
			if kind == "motherboard":
				var board: Dictionary = session.workshop.ledger.item(pc.components[kind])
				texture = PartVisuals.board_texture(board.get("board_art", ""), texture)
			elif kind == "cpu":
				var cpu: Dictionary = session.workshop.ledger.item(pc.components[kind])
				if cpu.get("socket") == "AX4": texture = PartVisuals.AMDERA_CPU
			draw_texture_rect(texture, mount_rect(kind, pc), false)
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
			for kind in MOUNT_RECTS:
				if kind == "cpu" and record.components.has("cooling"): continue
				var rect := mount_rect(kind, record)
				if hovered == StringName(kind) or session.selected == StringName(kind): draw_rect(rect, Color("71dded"), false, 1)
				if not record.components.has(kind):
					draw_rect(rect, Color("284455"), false, 1)
					continue
				var mount: Dictionary = session.workshop.ledger.mounts(session.physical_pc_id, kind)
				for i in range(mount.screws.size()):
					_draw_screw(mount_point(kind,i,false), mount.screws[i], hovered == StringName("mount:%s:screw:%d" % [kind,i]))
				for i in range(mount.connections.size()):
					var p := mount_point(kind,i,true)
					var connected: bool = mount.connections[session.workshop.ledger.CONNECTIONS[kind][i]]
					draw_rect(Rect2(p - Vector2(3,2),Vector2(6,4)),Color("6bbdc9") if connected else Color("dca56b"))
					if hovered == StringName("mount:%s:connector:%d" % [kind,i]): draw_rect(Rect2(p - Vector2(4,4),Vector2(8,8)),Color("71dded"),false,1)
			_draw_ram_slots(record)
		# The removed lid rests edge-on beside the chassis, and is clickable.
		_draw_parked_lid()
		if hovered == &"lid" or session.selected == &"lid":
			draw_rect(PARKED_LID.grow(2), Color("71dded"), false, 1.0)
		for item in PARTS:
			if physical and item[0] != &"ram": continue
			if physical and not session.workshop.ledger.item(session.physical_pc_id).components.has("motherboard"): continue
			if hovered == item[0] or session.selected == item[0]:
				draw_rect((RAM_SLOT if physical and item[0] == &"ram" else item[2]).grow(2), Color("71dded"), false, 1.0)
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
	if kind == "cpu":
		var board: Dictionary = session.workshop.ledger.item(pc.components.get("motherboard", ""))
		return PartVisuals.cpu_seat(board.get("board_art", ""), BOARD_AREA)
	return MOUNT_RECTS[kind]


func mount_point(kind: String, index: int, connector: bool) -> Vector2:
	return CONNECTOR_POINTS[kind][index] if connector else SCREW_POINTS[kind][index]

func _draw_ram_slots(record: Dictionary, show_highlights: bool = true) -> void:
	if not record.components.has("motherboard"): return
	for slot in range(2):
		var offset := RAM_SLOT_SPACING * slot
		var key := "ram" if slot == 0 else "ram2"
		var clips: Array = session.workshop.ledger.ram_latches(session.physical_pc_id,slot)
		draw_string(ThemeDB.fallback_font,Vector2(144,114)+offset,"A1" if slot == 0 else "A2",HORIZONTAL_ALIGNMENT_LEFT,-1,4,Color("98aca5"))
		# Socket, key and installed module share one top-down center line.
		draw_rect(Rect2(Vector2(143,47)+offset,Vector2(12,54)),Color("10191e"))
		draw_rect(Rect2(Vector2(144,48)+offset,Vector2(10,52)),Color("303c40"))
		draw_rect(Rect2(Vector2(147,48)+offset,Vector2(4,52)),Color("080e12"))
		if record.components.has(key):
			# Orthographic view of the heat spreader's upper spine; no PCB face.
			draw_rect(Rect2(RAM_INSTALLED.position+offset+Vector2(1,0.5),RAM_INSTALLED.size),Color(0,0,0,0.35))
			var module: Dictionary = session.workshop.ledger.item(record.components[key])
			var finish: String = module.get("heat_spreader_color", "")
			var art: Texture2D = layers.ram if finish.is_empty() else PartVisuals.ram_heat_spreader(finish, true)
			draw_texture_rect(art,Rect2(RAM_INSTALLED.position+offset,RAM_INSTALLED.size),false)
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
			draw_rect(Rect2(clip_center-Vector2(5,2),Vector2(10,4)),Color("26333b"))
			draw_rect(Rect2(clip_center-Vector2(4,1.5),Vector2(8,2.5)),Color("9bafb3") if closed else Color("c9b28c"))
			draw_line(clip_center+Vector2(-3,-1),clip_center+Vector2(3,-1),Color("d0dcdb"),0.5)
			draw_rect(Rect2(clip_center+Vector2(-1,-1),Vector2(2,2)),Color("53636a"))
			var id := StringName(("ram_latch_" if slot == 0 else "ram2_latch_")+str(i))
			if show_highlights and (hovered == id or session.selected == id): draw_rect(Rect2(p-Vector2(7,5),Vector2(14,10)),Color("71dded"),false,1)
		if show_highlights and (hovered == StringName(key) or session.selected == StringName(key)): draw_rect(Rect2(RAM_SLOT.position+offset,RAM_SLOT.size),Color("71dded"),false,1)

func _draw_cables(record: Dictionary) -> void:
	var routes := {
		"gpu": [[Vector2(184,121),Vector2(198,121),Vector2(198,176),Vector2(141,176)]],
		"storage": [[Vector2(218,143),Vector2(218,184),Vector2(165,184),Vector2(165,151)], [Vector2(232,143),Vector2(232,178),Vector2(141,178)]],
		"motherboard": [[Vector2(182,83),Vector2(194,83),Vector2(194,174),Vector2(141,174)], [Vector2(67,41),Vector2(67,29),Vector2(203,29),Vector2(203,172),Vector2(141,172)], [Vector2(169,151),Vector2(208,151),Vector2(208,190),Vector2(246,190)]],
		"cooling": [[Vector2(130,52),Vector2(135,52),Vector2(135,76),Vector2(128,76)]]
	}
	for kind in routes:
		if not record.components.has(kind): continue
		var mount: Dictionary = session.workshop.ledger.mounts(session.physical_pc_id,kind)
		for i in range(routes[kind].size()):
			if not mount.connections[session.workshop.ledger.CONNECTIONS[kind][i]]: continue
			var points := PackedVector2Array(routes[kind][i])
			draw_polyline(points,Color("080f16"),2.5)
			draw_polyline(points,Color("7c6053") if kind == "storage" and i == 0 else Color("445767"),1.1)



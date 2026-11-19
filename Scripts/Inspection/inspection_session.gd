extends RefCounted
## One maintenance session, owned by the bench UI rather than by its view.
## Removed screws remain in a local tray; this is not an inventory system.

signal changed
signal notice(text: String, failed: bool)

const Audio := preload("res://Scripts/Gameplay/workshop_audio.gd")
var workshop: Node
var physical_pc_id := ""
var _lid := true
var _screws: Array = [true, true, true, true]
var _tool: StringName = &"hands"
var lid_attached: bool:
	get: return _record().get("lid", _lid)
	set(value):
		if is_instance_valid(workshop): _record().lid = value
		else: _lid = value
var screws: Array:
	get: return _record().get("screws", _screws)
	set(value):
		if is_instance_valid(workshop): _record().screws = value
		else: _screws = value
var tool: StringName:
	get: return StringName(_record().get("tool", str(_tool)))
	set(value):
		if is_instance_valid(workshop): _record().tool = str(value)
		else: _tool = value
var selected: StringName = &""


func bind_workshop(value: Node, pc_id: String) -> void:
	workshop = value
	physical_pc_id = pc_id


func _record() -> Dictionary:
	return workshop.ledger.item(physical_pc_id) if is_instance_valid(workshop) else {}


func use_ram_latch(index: int, slot: int = 0) -> void:
	if not is_instance_valid(workshop): return
	selected = StringName(("ram_latch_" if slot == 0 else "ram2_latch_") + str(index))
	if tool != &"hands":
		notice.emit("Selecione Mãos para operar as travas sem danificar a RAM.", true)
		return
	workshop.ledger.toggle_latch(physical_pc_id, index, slot)


func use_ram_component(slot: int = 0) -> void:
	if not is_instance_valid(workshop): return
	selected = &"ram" if slot == 0 else &"ram2"
	if tool != &"hands":
		notice.emit("Selecione Mãos para retirar ou encaixar um módulo de RAM.", true)
		return
	workshop.ledger.use_ram_slot(physical_pc_id, workshop.selected_ram, slot)


func installed_count() -> int:
	return screws.count(true)


func interact_with(id: StringName) -> void:
	var target := String(id)
	var physical := is_instance_valid(workshop)
	if physical and target.begins_with("mount:"):
		var fields := target.split(":")
		workshop.ledger.operate_mount(physical_pc_id, fields[1], fields[2], int(fields[3]))
	elif physical and target.begins_with("ram2_latch_"):
		use_ram_latch(int(target.trim_prefix("ram2_latch_")), 1)
	elif physical and target.begins_with("ram_latch_"):
		use_ram_latch(int(target.trim_prefix("ram_latch_")))
	elif physical and id in [&"ram", &"ram2"]:
		use_ram_component(1 if id == &"ram2" else 0)
	elif physical and target in workshop.ledger.PART_NAMES:
		selected = id
		workshop.ledger.use_component(physical_pc_id, target, workshop.selected_part)
	elif target.begins_with("screw_"):
		use_screw(int(target.trim_prefix("screw_")))
	elif id == &"lid":
		use_lid()
	elif id != &"":
		select_component(id)


func select_tool(value: StringName) -> void:
	if value not in [&"hands", &"phillips"]:
		return
	if value == &"phillips" and is_instance_valid(workshop) and not workshop.ledger.state.tools:
		notice.emit("Abra a caixa de ferramentas da oficina com F para obter acesso à Phillips.", true)
		return
	tool = value
	changed.emit()
	var hands_hint := "Mãos (1): conectores, travas, peças e encaixes. Libere as fixações antes de retirar." if is_instance_valid(workshop) else "Mãos livres. Clique na tampa para manuseá-la."
	notice.emit("Phillips (2): clique nos parafusos da tampa ou de cada componente." if tool == &"phillips" else hands_hint, false)


func use_screw(index: int) -> bool:
	if index < 0 or index >= screws.size():
		return false
	if is_instance_valid(workshop) and not workshop.ledger.safe_to_work(physical_pc_id): return false
	selected = StringName("screw_" + str(index))
	changed.emit()
	if not lid_attached:
		notice.emit("Recoloque a tampa antes de fixar seus parafusos.", true)
		return false
	if tool != &"phillips":
		notice.emit("Selecione a chave Phillips para soltar ou fixar este parafuso.", true)
		return false
	screws[index] = not screws[index]
	Audio.play("screw" if screws[index] else "unscrew")
	changed.emit()
	if screws[index]:
		notice.emit(TranslationServer.translate("Parafuso %d fixado na tampa.") % (index + 1), false)
	elif installed_count() == 0:
		notice.emit("Os quatro parafusos foram retirados. Clique na tampa para removê-la.", false)
	else:
		notice.emit(TranslationServer.translate("Parafuso %d retirado. Faltam %d para liberar a tampa.") % [index + 1, installed_count()], false)
	return true


func use_lid() -> bool:
	if is_instance_valid(workshop) and not workshop.ledger.safe_to_work(physical_pc_id): return false
	var assembly: bool = _record().has("case_key")
	if assembly and tool != &"hands":
		notice.emit("Selecione Mãos (1) para manusear a tampa.", true)
		return false
	selected = &"lid"
	changed.emit()
	if lid_attached and installed_count() > 0:
		notice.emit(TranslationServer.translate("A tampa ainda está presa: retire os %d parafuso(s) restantes com a chave Phillips.") % installed_count(), true)
		return false
	lid_attached = not lid_attached
	Audio.play("place")
	changed.emit()
	if lid_attached:
		notice.emit("Tampa recolocada, ainda sem fixação. Use a Phillips nos quatro pontos para prender a tampa.", false)
	elif assembly:
		notice.emit("Tampa retirada. Selecione uma peça e clique no encaixe.", false)
	else:
		notice.emit("Tampa retirada. Selecione Mãos, abra as duas travas da RAM e clique no módulo." if is_instance_valid(workshop) else "Tampa retirada e apoiada ao lado. Passe o mouse sobre as peças para identificá-las.", false)
	return true


func select_component(id: StringName) -> void:
	if lid_attached:
		notice.emit("Retire a tampa para acessar os componentes internos.", true)
		return
	selected = id
	changed.emit()
	notice.emit("Componente selecionado. Apenas identificação visual está disponível nesta etapa.", false)

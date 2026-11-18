extends Node2D
## Physical placement contract. No spawn, sample item or default resource.

signal equipment_changed
signal placement_rejected(reason: String)

const EquipmentItem := preload("res://Scripts/Equipment/equipment_item.gd")
@export var placement_radius: float = 28.0
var _item: Node2D
var _data: Resource
@onready var slot: Marker2D = $EquipmentSlot


func _process(_delta: float) -> void:
	# Also runs while a modal is open. Removing/freeing/moving/hiding the
	# physical item invalidates inspection immediately, even during pause.
	if _item != null and not has_equipment():
		_clear_association()


func has_equipment() -> bool:
	return is_instance_valid(_item) and _item is EquipmentItem and _item.is_valid_equipment() and _item.equipment_data == _data and _item.get_parent() == slot and _item.global_position.distance_to(slot.global_position) <= placement_radius


func get_equipment() -> Resource:
	return _data if has_equipment() else null


func get_equipment_item() -> Node2D:
	return _item if has_equipment() else null


func place_equipment(item: Node2D) -> bool:
	if has_equipment():
		placement_rejected.emit("A bancada já está ocupada.")
		return false
	if not is_instance_valid(item) or not item is EquipmentItem or not item.is_valid_equipment():
		placement_rejected.emit("É necessário um equipamento físico visível com dados válidos.")
		return false
	if item.get_tree() != get_tree() or item.global_position.distance_to(slot.global_position) > placement_radius:
		placement_rejected.emit("Coloque o equipamento na área de apoio da bancada antes de associá-lo.")
		return false
	if item.is_ancestor_of(self):
		return false
	var controller: Node = item.get_meta("workshop_controller", null)
	if is_instance_valid(controller) and not controller._syncing:
		return controller.place_via_dock(item)
	_clear_association(false)
	if item.get_parent() != slot:
		item.reparent(slot, true)
	item.position = Vector2.ZERO
	_item = item
	_data = item.equipment_data
	_item.tree_exiting.connect(_on_item_exiting)
	_data.changed.connect(_on_data_changed)
	equipment_changed.emit()
	return true


func remove_equipment(destination: Node2D, world_position: Vector2) -> Node2D:
	if not has_equipment() or not is_instance_valid(destination) or not destination.is_inside_tree() or destination.get_tree() != get_tree() or not world_position.is_finite():
		return null
	if destination == _item or _item.is_ancestor_of(destination):
		return null
	if destination == slot:
		return null
	if world_position.distance_to(slot.global_position) <= placement_radius:
		placement_rejected.emit("Retire fisicamente o equipamento da área de apoio para desassociá-lo.")
		return null
	var controller: Node = _item.get_meta("workshop_controller", null)
	if is_instance_valid(controller) and not controller._syncing:
		return controller.remove_via_dock(_item, world_position)
	var removed := _item
	_clear_association()
	removed.reparent(destination, true)
	removed.global_position = world_position
	return removed


func _on_item_exiting() -> void:
	_clear_association()


func _on_data_changed() -> void:
	if not has_equipment():
		_clear_association()
	else:
		equipment_changed.emit()


func _clear_association(notify: bool = true) -> void:
	if is_instance_valid(_item) and _item.tree_exiting.is_connected(_on_item_exiting):
		_item.tree_exiting.disconnect(_on_item_exiting)
	if is_instance_valid(_data) and _data.changed.is_connected(_on_data_changed):
		_data.changed.disconnect(_on_data_changed)
	_item = null
	_data = null
	if notify:
		equipment_changed.emit()

extends "res://Scripts/Equipment/equipment_item.gd"
## A derived world representation; identity/location belong to WorkshopLedger.

const Cases := preload("res://Scripts/Equipment/case_catalog.gd")
const PartVisuals := preload("res://Scripts/UI/part_visuals.gd")
const PeripheralArt := preload("res://Scripts/UI/peripheral_art.gd")
const FanMotion := preload("res://Scripts/Equipment/fan_motion.gd")
const CASE_SCALE := 0.64

var item_id := ""
var _fans := FanMotion.new()
var _fan_layer: Node2D
var _fans_visible := false
var _at_bench := false


func _ready() -> void:
	_fan_layer = Node2D.new()
	_fan_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_fan_layer)
	_fan_layer.draw.connect(_draw_fans)


func _process(delta: float) -> void:
	if not _at_bench: return
	var workshop: Node = get_meta("workshop_controller", null)
	if not is_instance_valid(workshop): return
	var moved := _fans.advance(workshop.ledger, item_id, delta)
	if moved and _fans_visible: _fan_layer.queue_redraw()


func show_record(record: Dictionary) -> void:
	var kind: String = "box" if record.get("packaged", false) else record.kind
	var case_key: String = record.get("case_key", "")
	var glass: bool = Cases.get_model(case_key).get("glass", false)
	_at_bench = kind == "pc" and record.location == "bench"
	_fans_visible = kind == "pc" and (not record.get("lid", true) or glass)
	_fan_layer.visible = _fans_visible
	_fan_layer.queue_redraw()
	$Sprite.texture = Cases.texture(case_key, record.lid) if kind == "pc" and not case_key.is_empty() else load("res://Assets/Physical/" + kind + ".png")
	if kind in ["motherboard", "cpu"] or (kind == "cooling" and PartVisuals.has_distinct_cooler(record)) or (kind in ["gpu", "storage"] and PartVisuals.has_peripheral_art(record)):
		$Sprite.texture = PartVisuals.world_icon(record)
	elif kind == "ram" and (record.has("heat_spreader_color") or PartVisuals.has_distinct_memory(record)):
		$Sprite.texture = PartVisuals.icon(record)
	$Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite.position = Vector2(0, -38 if record.kind == "pc" else -22)
	$Sprite.scale = Vector2.ONE * (1.0 if record.kind == "pc" else 0.65)
	if not case_key.is_empty():
		$Sprite.position.y = -28.0 if kind == "box" else -44.0 * CASE_SCALE
		$Sprite.scale = Vector2.ONE * (0.8 if kind == "box" else CASE_SCALE)
	if kind == "ram":
		$Sprite.scale *= 64.0 / $Sprite.texture.get_width()
		if record.location == "floor":
			$Sprite.position.y = -$Sprite.texture.get_height() * $Sprite.scale.y * 0.5 + 3.0
	if kind == "cpu": $Sprite.scale *= 40.0 / $Sprite.texture.get_width()
	if kind == "motherboard": $Sprite.scale *= 78.0 / $Sprite.texture.get_width()
	if kind == "cooling" and PartVisuals.has_distinct_cooler(record): $Sprite.scale *= 50.0 / $Sprite.texture.get_width()
	if kind == "gpu" and PartVisuals.has_peripheral_art(record):
		$Sprite.scale *= (42.0 + float(record.size_mm - 145) * 0.13) / $Sprite.texture.get_width()
	if kind == "storage" and PartVisuals.has_peripheral_art(record): $Sprite.scale *= 42.0 / $Sprite.texture.get_width()
	modulate = Color.WHITE
	$Body/Collision.set_deferred("disabled", record.kind != "pc" or record.location != "floor" or (kind == "box" and not case_key.is_empty()))


func _draw_fans() -> void:
	var workshop: Node = get_meta("workshop_controller", null)
	if not _fans_visible or not is_instance_valid(workshop): return
	var ledger: RefCounted = workshop.ledger
	var pc: Dictionary = ledger.item(item_id)
	var tint := Color("819fa8") if pc.get("lid", false) else Color("b1c5c9")
	var origin: Vector2 = $Sprite.position
	var scale_factor: float = $Sprite.scale.x
	for group in ["case", "cooling", "psu"]:
		var count: int = ledger.fan_count(item_id, group)
		for index in range(count):
			var point := Vector2(-19, -16 + index * 11) if group == "case" else Vector2(-7, -9) if group == "cooling" else Vector2(-12, 15)
			var size := Vector2(8, 9) * scale_factor
			var projection := Transform2D(Vector2(1, 0.45), Vector2(0, 1), origin + point * scale_factor)
			_fan_layer.draw_set_transform_matrix(projection)
			_fan_layer.draw_texture_rect(PeripheralArt.rotor(_fans.phase(group, index)), Rect2(-size * 0.5, size), false, tint)
	_fan_layer.draw_set_transform(Vector2.ZERO)

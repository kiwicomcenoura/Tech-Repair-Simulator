extends "res://Scripts/Equipment/equipment_item.gd"
## A derived world representation; identity/location belong to WorkshopLedger.

var item_id := ""


func show_record(record: Dictionary) -> void:
	var kind: String = "box" if record.get("packaged", false) else record.kind
	$Sprite.texture = load("res://Assets/Physical/" + kind + ".png")
	if (kind == "ram" and record.has("heat_spreader_color")) or (kind == "cpu" and record.get("socket") == "AX4"):
		$Sprite.texture = preload("res://Scripts/UI/part_visuals.gd").icon(record)
	$Sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite.position = Vector2(0, -38 if record.kind == "pc" else -22)
	$Sprite.scale = Vector2.ONE * (1.0 if record.kind == "pc" else 0.65)
	if kind == "ram":
		$Sprite.scale *= 64.0 / $Sprite.texture.get_width()
		if record.location == "floor":
			$Sprite.position.y = -$Sprite.texture.get_height() * $Sprite.scale.y * 0.5 + 3.0
	if kind == "cpu" and record.get("socket") == "AX4": $Sprite.scale *= 40.0 / $Sprite.texture.get_width()
	modulate = Color.WHITE
	$Body/Collision.set_deferred("disabled", record.kind != "pc" or record.location != "floor")

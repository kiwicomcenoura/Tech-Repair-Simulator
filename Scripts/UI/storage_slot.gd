extends Button
var inventory: Node
var item_id := ""
var location := ""
var slot := 0
var _part_texture: Texture2D


func display_part(texture: Texture2D, caption: String) -> void:
	_part_texture = texture
	var contents := VBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 3)
	add_child(contents)
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left = 8.0
	contents.offset_right = -8.0
	contents.offset_top = 7.0
	contents.offset_bottom = -5.0
	var art := _art_view()
	art.name = "PartArt"
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contents.add_child(art)
	var label := Label.new()
	label.name = "PartName"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 2
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size.y = 19
	label.add_theme_font_size_override("font_size", 12)
	contents.add_child(label)


func _art_view() -> TextureRect:
	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = _part_texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return art

func _get_drag_data(_position: Vector2) -> Variant:
	if item_id.is_empty(): return null
	var preview := _art_view()
	preview.custom_minimum_size = Vector2(72, 72)
	set_drag_preview(preview)
	return {"storage_item": item_id, "inventory": inventory}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("inventory") == inventory and data.has("storage_item")

func _drop_data(_position: Vector2, data: Variant) -> void:
	inventory.drop_item(data.storage_item, location, slot)

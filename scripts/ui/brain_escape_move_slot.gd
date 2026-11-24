extends Button

signal swapped(from_index: int, to_index: int)

var slot_index := -1

func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot_index < 0:
		return null
	var preview := Label.new()
	preview.text = text
	preview.add_theme_font_size_override("font_size", 20)
	preview.add_theme_color_override("font_color", Color("#14213d"))
	preview.add_theme_stylebox_override("normal", _preview_style())
	set_drag_preview(preview)
	return {"slot_index": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("slot_index") and int(data.slot_index) != slot_index

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	swapped.emit(int(data.slot_index), slot_index)

func _preview_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff7df")
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

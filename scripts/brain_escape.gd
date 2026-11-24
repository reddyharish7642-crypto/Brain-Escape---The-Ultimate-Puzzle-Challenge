extends Control

const Levels = preload("res://scripts/brain_escape_levels.gd")
const AudioDirector = preload("res://scripts/brain_escape_audio.gd")
const MoveSlot = preload("res://scripts/ui/brain_escape_move_slot.gd")
const BACKDROP: Texture2D = preload("res://assets/brain_escape/puzzle_vault_background.jpg")
const ICON: Texture2D = preload("res://assets/share/favicon.png")
const DOOR_ART: Texture2D = preload("res://assets/brain_escape/vault_door_runtime.png")
const SAVE_PATH := "user://brain_escape.cfg"
const INK := Color("#14213D")
const MUTED := Color("#68758E")
const TEAL := Color("#39BBA7")
const CORAL := Color("#F27879")
const GOLD := Color("#E7B94F")
const PAPER := Color("#FFF9ED")
const TILE := Color("#F0F5F8")
const RUNE_ICONS := ["●", "▲", "◆", "★"]
const PIPE_GLYPHS := ["│", "└", "─", "┌"]

var _audio: Node
var _save := ConfigFile.new()
var _save_ok := false
var _page: ScrollContainer
var _page_content: VBoxContainer
var _current_page := "home"
var _level := 1
var _unlocked := 1
var _coins := 0
var _total_score := 0
var _stars: Dictionary = {}
var _music_level := 0.72
var _sfx_level := 0.82
var _music_on := true
var _sfx_on := true
var _reduce_motion := false
var _level_data: Dictionary = {}
var _mechanic: Dictionary = {}
var _time_left := 120.0
var _elapsed := 0.0
var _last_tick := -1
var _hint_used := false
var _wrong_count := 0
var _paused := false
var _finished := false
var _timer_label: Label
var _feedback_label: Label
var _hint_button: Button
var _shape_art: Label
var _memory_label: Label
var _memory_buttons: Array[Button] = []
var _wire_buttons: Array[Button] = []
var _pipe_buttons: Array[Button] = []
var _move_buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_configure_backdrop()
	_load_progress()
	_audio = AudioDirector.new()
	_audio.name = "BrainEscapeAudio"
	_audio.music_level = _music_level
	_audio.sfx_level = _sfx_level
	_audio.music_enabled = _music_on
	_audio.sfx_enabled = _sfx_on
	add_child(_audio)
	_build_home()
	get_viewport().size_changed.connect(_on_viewport_changed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed or event is InputEventScreenTouch and event.pressed or event is InputEventKey and event.pressed:
		if is_instance_valid(_audio):
			_audio.start_music_from_gesture()

func _process(delta: float) -> void:
	if _current_page != "game" or _paused or _finished:
		return
	_elapsed += delta
	var seconds := maxi(0, int(ceil(_time_left - _elapsed)))
	if seconds != _last_tick:
		_last_tick = seconds
		if is_instance_valid(_timer_label):
			_timer_label.text = "TIME  %s" % _format_time(seconds)
	if seconds == 0:
		_finish_timeout()

func _configure_backdrop() -> void:
	var image := TextureRect.new()
	image.name = "VaultBackdrop"
	image.texture = BACKDROP
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.modulate = Color(0.52, 0.59, 0.72, 1.0)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.055, 0.12, 0.52)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

func _load_progress() -> void:
	if _save.load(SAVE_PATH) != OK:
		return
	_save_ok = true
	_unlocked = clampi(int(_save.get_value("progress", "unlocked", 1)), 1, 50)
	_coins = maxi(0, int(_save.get_value("progress", "coins", 0)))
	_total_score = maxi(0, int(_save.get_value("progress", "score", 0)))
	_stars = _save.get_value("progress", "stars", {})
	_music_level = clampf(float(_save.get_value("settings", "music_level", 0.72)), 0.0, 1.0)
	_sfx_level = clampf(float(_save.get_value("settings", "sfx_level", 0.82)), 0.0, 1.0)
	_music_on = bool(_save.get_value("settings", "music_on", true))
	_sfx_on = bool(_save.get_value("settings", "sfx_on", true))
	_reduce_motion = bool(_save.get_value("settings", "reduce_motion", false))

func _persist() -> void:
	_save.set_value("progress", "unlocked", _unlocked)
	_save.set_value("progress", "coins", _coins)
	_save.set_value("progress", "score", _total_score)
	_save.set_value("progress", "stars", _stars)
	_save.set_value("settings", "music_level", _music_level)
	_save.set_value("settings", "sfx_level", _sfx_level)
	_save.set_value("settings", "music_on", _music_on)
	_save.set_value("settings", "sfx_on", _sfx_on)
	_save.set_value("settings", "reduce_motion", _reduce_motion)
	_save.save(SAVE_PATH)

func _on_viewport_changed() -> void:
	if _current_page == "home": _build_home()
	elif _current_page == "levels": _build_levels()
	elif _current_page == "settings": _build_settings()
	elif _current_page == "game": _build_game_screen(false)
	elif _current_page == "pause": _build_pause()

func _open_page(page_name: String) -> VBoxContainer:
	_current_page = page_name
	if is_instance_valid(_page):
		remove_child(_page)
		_page.queue_free()
	_page = ScrollContainer.new()
	_page.name = "ScreenScroll"
	var viewport_size := get_viewport_rect().size
	var portrait_scale := 2.0 if viewport_size.x / maxf(viewport_size.y, 1.0) < 0.75 else 1.0
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page.pivot_offset = viewport_size / 2.0
	_page.scale = Vector2.ONE * portrait_scale
	_page.offset_left = 12
	_page.offset_top = 16
	_page.offset_right = -12
	_page.offset_bottom = -16
	_page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_page.follow_focus = true
	_page.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_page)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "PagePanel"
	var width := clampf(get_viewport_rect().size.x / portrait_scale - 42.0, 260.0, 940.0)
	panel.custom_minimum_size = Vector2(width, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.98, 0.97, 0.93, 0.97)))
	center.add_child(panel)
	var margins := MarginContainer.new()
	for key in ["margin_left", "margin_right"]: margins.add_theme_constant_override(key, 26)
	for key in ["margin_top", "margin_bottom"]: margins.add_theme_constant_override(key, 24)
	panel.add_child(margins)
	_page_content = VBoxContainer.new()
	_page_content.add_theme_constant_override("separation", 14)
	_page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.add_child(_page_content)
	return _page_content

func _panel_style(color: Color, radius: int = 22) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1, 1, 1, 0.75)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _card(parent: Control, tint: Color = TILE) -> VBoxContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _panel_style(tint, 18))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	box.add_child(inner)
	return inner

func _label(text: String, size: int = 18, color: Color = INK, bold: bool = false) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if bold: item.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	return item

func _button(text: String, action: Callable = Callable(), primary: bool = false, minimum: Vector2 = Vector2(124, 48)) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size = minimum
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.focus_mode = Control.FOCUS_ALL
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var base := TEAL if primary else Color("#E7EDF2")
	var hover := Color("#2EA894") if primary else Color("#DCE7EF")
	item.add_theme_stylebox_override("normal", _button_style(base))
	item.add_theme_stylebox_override("hover", _button_style(hover))
	item.add_theme_stylebox_override("pressed", _button_style(Color("#248E80") if primary else Color("#C9D8E3")))
	item.add_theme_stylebox_override("focus", _button_style(Color(0.9, 0.76, 0.35, 0.32)))
	item.add_theme_color_override("font_color", INK if not primary else Color.WHITE)
	item.add_theme_color_override("font_hover_color", INK if not primary else Color.WHITE)
	item.add_theme_font_size_override("font_size", 16)
	if action.is_valid(): item.pressed.connect(action)
	return item

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

func _build_home() -> void:
	var body := _open_page("home")
	var brand := HBoxContainer.new()
	brand.add_theme_constant_override("separation", 16)
	body.add_child(brand)
	var mark := TextureRect.new()
	mark.texture = ICON
	mark.custom_minimum_size = Vector2(66, 66)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand.add_child(mark)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_child(title_box)
	title_box.add_child(_label("BRAIN ESCAPE", 36, INK, true))
	title_box.add_child(_label("THE ULTIMATE PUZZLE CHALLENGE", 13, MUTED, true))
	var intro := _label("Every lock has a logic. Every room has a way out.", 18, MUTED)
	body.add_child(intro)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	body.add_child(stats)
	stats.add_child(_stat_card("UNLOCKED", "%d / 50" % _unlocked, TEAL))
	stats.add_child(_stat_card("BEST SCORE", str(_total_score), GOLD))
	stats.add_child(_stat_card("COINS", str(_coins), CORAL))
	var hero := _card(body, Color("#FFF4D6"))
	hero.add_child(_label("50 rooms. 10 kinds of brain-teaser. One way out.", 23, INK, true))
	hero.add_child(_label("Crack number codes, spot hidden clues, route the wires, remember the sequence and move the relics into place.", 16, MUTED))
	var play := _button("PLAY  →", Callable(self, "_play_next"), true, Vector2(200, 58))
	body.add_child(play)
	var nav := HBoxContainer.new()
	nav.add_child(_button("LEVELS", Callable(self, "_build_levels")))
	nav.add_child(_button("SETTINGS", Callable(self, "_build_settings")))
	nav.add_child(_button("EXIT", Callable(self, "_exit_game")))
	body.add_child(nav)
	body.add_child(_label("Progress saves automatically on this device.", 13, MUTED))
	_animate(body)

func _stat_card(title: String, value: String, accent: Color) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.91, 0.95, 0.97, 1), 14))
	var column := VBoxContainer.new()
	column.add_child(_label(title, 11, MUTED, true))
	column.add_child(_label(value, 21, accent, true))
	card.add_child(column)
	return card

func _play_next() -> void:
	_start_level(_unlocked)

func _build_levels() -> void:
	var body := _open_page("levels")
	var header := HBoxContainer.new()
	header.add_child(_button("← HOME", Callable(self, "_build_home"), false, Vector2(100, 44)))
	header.add_child(_label("CHOOSE A ROOM", 27, INK, true))
	body.add_child(header)
	body.add_child(_label("Five wings of rising difficulty. Clear a room to open the next.", 15, MUTED))
	var progress := ProgressBar.new()
	progress.max_value = 50
	progress.value = minf(_unlocked, 50)
	progress.show_percentage = false
	progress.custom_minimum_size.y = 12
	body.add_child(progress)
	var grid := GridContainer.new()
	grid.columns = 5 if get_viewport_rect().size.x >= 700 else 3
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	body.add_child(grid)
	for n in range(1, 51):
		var stars := int(_stars.get(str(n), 0))
		var unlocked := n <= _unlocked
		var label := "%02d\n%s" % [n, "★".repeat(stars) if stars > 0 else ("OPEN" if unlocked else "LOCK")]
		var tile := _button(label, Callable(self, "_start_level").bind(n) if unlocked else Callable(), false, Vector2(58, 64))
		tile.disabled = not unlocked
		tile.add_theme_font_size_override("font_size", 14)
		if unlocked:
			tile.add_theme_stylebox_override("normal", _button_style(Color("#FFF2C9") if stars > 0 else Color("#E6F5F0")))
			tile.add_theme_color_override("font_color", INK)
		else:
			tile.add_theme_color_override("font_color", Color("#8490A3"))
		grid.add_child(tile)
	for tier in range(5):
		var start := tier * 10 + 1
		body.add_child(_label("%02d–%02d  ·  %s" % [start, start + 9, Levels.get_level(start).section.to_upper()], 13, MUTED, true))
	body.add_child(_button("BACK TO HOME", Callable(self, "_build_home")))
	_animate(body)

func _build_settings() -> void:
	var body := _open_page("settings")
	var header := HBoxContainer.new()
	header.add_child(_button("← HOME", Callable(self, "_build_home"), false, Vector2(100, 44)))
	header.add_child(_label("SETTINGS", 28, INK, true))
	body.add_child(header)
	body.add_child(_label("Tune the sound and movement to your preference.", 15, MUTED))
	var music_row := HBoxContainer.new()
	music_row.add_child(_label("Background music", 16, INK, true))
	music_row.add_child(_button("ON" if _music_on else "OFF", Callable(self, "_toggle_music"), _music_on, Vector2(80, 44)))
	body.add_child(music_row)
	var music := HSlider.new()
	music.min_value = 0
	music.max_value = 1
	music.step = 0.01
	music.value = _music_level
	music.value_changed.connect(_set_music_volume)
	body.add_child(music)
	var sfx_row := HBoxContainer.new()
	sfx_row.add_child(_label("Puzzle sound effects", 16, INK, true))
	sfx_row.add_child(_button("ON" if _sfx_on else "OFF", Callable(self, "_toggle_sfx"), _sfx_on, Vector2(80, 44)))
	body.add_child(sfx_row)
	var sfx := HSlider.new()
	sfx.min_value = 0
	sfx.max_value = 1
	sfx.step = 0.01
	sfx.value = _sfx_level
	sfx.value_changed.connect(_set_sfx_volume)
	body.add_child(sfx)
	var motion := HBoxContainer.new()
	motion.add_child(_label("Reduce animations", 16, INK, true))
	motion.add_child(_button("ON" if _reduce_motion else "OFF", Callable(self, "_toggle_motion"), _reduce_motion, Vector2(80, 44)))
	body.add_child(motion)
	body.add_child(_label("Sound starts after your first tap or click. Settings and progress are saved automatically.", 14, MUTED))
	body.add_child(_button("DONE", Callable(self, "_build_home"), true))
	_animate(body)

func _toggle_music() -> void:
	_music_on = not _music_on
	_audio.set_music_enabled(_music_on)
	_persist()
	_build_settings()

func _toggle_sfx() -> void:
	_sfx_on = not _sfx_on
	_audio.set_sfx_enabled(_sfx_on)
	_persist()
	_build_settings()

func _toggle_motion() -> void:
	_reduce_motion = not _reduce_motion
	_persist()
	_build_settings()

func _set_music_volume(value: float) -> void:
	_music_level = value
	_audio.set_music_level(value)
	_persist()

func _set_sfx_volume(value: float) -> void:
	_sfx_level = value
	_audio.set_sfx_level(value)
	_persist()

func _start_level(number: int) -> void:
	_level = clampi(number, 1, min(50, _unlocked))
	_level_data = Levels.get_level(_level)
	_mechanic = {}
	_elapsed = 0.0
	_time_left = float(_level_data.time_limit)
	_last_tick = -1
	_hint_used = false
	_wrong_count = 0
	_paused = false
	_finished = false
	match _level_data.kind:
		"wires": _mechanic["rotations"] = _zeroes(_level_data.answer.size())
		"water": _mechanic["rotations"] = _zeroes(_level_data.answer.size())
		"shape": _mechanic["rotation"] = 0
		"memory": _mechanic["sequence"] = []
		"door": _mechanic["entry"] = ""
		"move": _mechanic["slots"] = _level_data.pieces.duplicate()
	_current_page = "game"
	_build_game_screen(true)
	_audio.pause_music(false)

func _build_game_screen(reset_clock: bool = false) -> void:
	if reset_clock: _last_tick = -1
	var body := _open_page("game")
	var header := HBoxContainer.new()
	header.add_child(_button("← LEVELS", Callable(self, "_build_levels"), false, Vector2(104, 44)))
	var title := _label("ROOM %02d / 50" % _level, 18, INK, true)
	header.add_child(title)
	_timer_label = _label("TIME  %s" % _format_time(maxi(0, int(ceil(_time_left - _elapsed)))), 15, CORAL, true)
	header.add_child(_timer_label)
	header.add_child(_button("PAUSE", Callable(self, "_build_pause"), false, Vector2(82, 44)))
	body.add_child(header)
	var progress := ProgressBar.new()
	progress.max_value = 50
	progress.value = _level
	progress.show_percentage = false
	progress.custom_minimum_size.y = 10
	body.add_child(progress)
	var band := _label("%s  ·  %s  ·  %s" % [_level_data.difficulty, _level_data.section.to_upper(), _level_data.category], 12, TEAL, true)
	body.add_child(band)
	body.add_child(_label(_level_data.title, 27, INK, true))
	var puzzle_card := _card(body, PAPER)
	puzzle_card.add_child(_label(_level_data.prompt, 18, INK))
	_feedback_label = _label("", 14, MUTED)
	puzzle_card.add_child(_feedback_label)
	_render_mechanic(puzzle_card)
	var actions := HBoxContainer.new()
	_hint_button = _button("HINT", Callable(self, "_show_hint"), false, Vector2(100, 44))
	_hint_button.disabled = _hint_used
	actions.add_child(_hint_button)
	actions.add_child(_button("RESTART", Callable(self, "_restart_level"), false, Vector2(108, 44)))
	body.add_child(actions)
	var status := _label("SCORE  %d     COINS  %d     STARS  %s" % [_total_score, _coins, "★".repeat(int(_stars.get(str(_level), 0)))], 13, MUTED, true)
	body.add_child(status)
	_animate(body)

func _render_mechanic(parent: VBoxContainer) -> void:
	match _level_data.kind:
		"number", "hidden", "pattern", "missing": _render_choices(parent)
		"door": _render_keypad(parent)
		"wires": _render_wires(parent)
		"water": _render_water(parent)
		"shape": _render_shape(parent)
		"memory": _render_memory(parent)
		"move": _render_move(parent)

func _render_choices(parent: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 2 if get_viewport_rect().size.x >= 520 else 1
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)
	for option in _level_data.options:
		var pick := _button(str(option), Callable(self, "_submit_answer").bind(str(option)), false, Vector2(90, 52))
		pick.add_theme_font_size_override("font_size", 18)
		grid.add_child(pick)

func _render_keypad(parent: VBoxContainer) -> void:
	parent.add_child(_illustration(DOOR_ART, Vector2(110, 136)))
	var display := _label("CODE  %s" % str(_mechanic.entry), 22, TEAL, true)
	parent.add_child(display)
	var keypad := GridContainer.new()
	keypad.columns = 3
	keypad.add_theme_constant_override("h_separation", 8)
	keypad.add_theme_constant_override("v_separation", 8)
	parent.add_child(keypad)
	for digit in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✓"]:
		var button := _button(digit, Callable(self, "_keypad_press").bind(digit), digit == "✓", Vector2(64, 48))
		keypad.add_child(button)

func _keypad_press(digit: String) -> void:
	var entry := str(_mechanic.entry)
	if digit == "⌫": entry = entry.substr(0, maxi(0, entry.length() - 1))
	elif digit == "✓": _submit_answer(entry); return
	elif entry.length() < int(_level_data.code_length): entry += digit
	_mechanic.entry = entry
	_build_game_screen(false)

func _render_wires(parent: VBoxContainer) -> void:
	_wire_buttons.clear()
	for i in range(_level_data.answer.size()):
		var row := HBoxContainer.new()
		row.add_child(_label("%s  ●" % _level_data.wire_names[i], 13, INK, true))
		var button := _button("━━" if int(_mechanic.rotations[i]) == 0 else "╲╱", Callable(self, "_rotate_wire").bind(i), false, Vector2(100, 42))
		row.add_child(button)
		row.add_child(_label("●  %s" % _level_data.wire_names[i], 13, INK, true))
		_wire_buttons.append(button)
		parent.add_child(row)
	parent.add_child(_button("CHECK CIRCUIT", Callable(self, "_check_mechanic"), true))

func _rotate_wire(index: int) -> void:
	var rotations: Array = _mechanic.rotations
	rotations[index] = 1 - int(rotations[index])
	_mechanic.rotations = rotations
	_wire_buttons[index].text = "━━" if int(rotations[index]) == 0 else "╲╱"

func _render_water(parent: VBoxContainer) -> void:
	_pipe_buttons.clear()
	var route := HBoxContainer.new()
	route.add_child(_label("INLET", 12, TEAL, true))
	parent.add_child(route)
	var pipes := HBoxContainer.new()
	pipes.add_theme_constant_override("separation", 5)
	parent.add_child(pipes)
	for i in range(_level_data.answer.size()):
		var index := i
		var turn := int(_mechanic.rotations[i])
		var button := _button(PIPE_GLYPHS[turn], Callable(self, "_rotate_pipe").bind(index), false, Vector2(48, 56))
		button.add_theme_font_size_override("font_size", 25)
		_pipe_buttons.append(button)
		pipes.add_child(button)
	route.add_child(_label("TANK", 12, GOLD, true))
	parent.add_child(_button("CHECK FLOW", Callable(self, "_check_mechanic"), true))

func _rotate_pipe(index: int) -> void:
	var rotations: Array = _mechanic.rotations
	rotations[index] = (int(rotations[index]) + 1) % 4
	_mechanic.rotations = rotations
	_pipe_buttons[index].text = PIPE_GLYPHS[int(rotations[index])]

func _render_shape(parent: VBoxContainer) -> void:
	_shape_art = _label("▲", 66, CORAL, true)
	_shape_art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shape_art.rotation = 0
	parent.add_child(_shape_art)
	parent.add_child(_label("Target turn: %d quarter-turns clockwise" % int(_level_data.answer), 14, MUTED))
	parent.add_child(_button("ROTATE  ↻", Callable(self, "_rotate_shape"), false, Vector2(150, 48)))
	parent.add_child(_button("CHECK SHAPE", Callable(self, "_check_mechanic"), true))

func _rotate_shape() -> void:
	_mechanic.rotation = (int(_mechanic.rotation) + 1) % 4
	var forms := ["▲", "▶", "▼", "◀"]
	_shape_art.text = forms[int(_mechanic.rotation)]

func _render_memory(parent: VBoxContainer) -> void:
	_memory_label = _label("Watch closely…  %s" % _join_words(_memory_names(_level_data.memory_sequence), "  "), 19, TEAL, true)
	_memory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(_memory_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	_memory_buttons.clear()
	for i in range(4):
		var button := _button(RUNE_ICONS[i], Callable(self, "_memory_tap").bind(i), false, Vector2(58, 54))
		button.add_theme_font_size_override("font_size", 22)
		button.disabled = true
		_memory_buttons.append(button)
		row.add_child(button)
	var submit := _button("CHECK SEQUENCE", Callable(self, "_check_mechanic"), true)
	submit.name = "MemoryCheck"
	parent.add_child(submit)
	_show_memory_sequence()

func _memory_names(sequence: Array) -> Array[String]:
	var names: Array[String] = []
	for value in sequence: names.append(RUNE_ICONS[int(value)])
	return names

func _show_memory_sequence() -> void:
	var expected_level := _level
	await get_tree().create_timer(2.4).timeout
	if not is_inside_tree() or _current_page != "game" or _level != expected_level or _level_data.kind != "memory": return
	_memory_label.text = "Repeat the sequence"
	for button in _memory_buttons: button.disabled = false

func _memory_tap(value: int) -> void:
	var sequence: Array = _mechanic.sequence
	if sequence.size() < _level_data.memory_sequence.size():
		sequence.append(value)
		_mechanic.sequence = sequence
		_memory_label.text = "Your sequence: %s" % _join_words(_memory_names(sequence), "  ")

func _render_move(parent: VBoxContainer) -> void:
	_move_buttons.clear()
	var target_row := HBoxContainer.new()
	target_row.add_child(_label("TARGET", 12, TEAL, true))
	for piece in _level_data.answer: target_row.add_child(_label(str(piece), 11, MUTED, true))
	parent.add_child(target_row)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	parent.add_child(row)
	for i in range(_mechanic.slots.size()):
		var slot: Button = MoveSlot.new()
		slot.slot_index = i
		slot.text = str(_mechanic.slots[i])
		slot.custom_minimum_size = Vector2(66, 56)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.swapped.connect(_on_move_swapped)
		slot.pressed.connect(_move_slot.bind(i))
		_move_buttons.append(slot)
		row.add_child(slot)
	parent.add_child(_button("CHECK ORDER", Callable(self, "_check_mechanic"), true))

func _move_slot(index: int) -> void:
	var selected := int(_mechanic.get("selected", -1))
	if selected < 0:
		_mechanic.selected = index
		_move_buttons[index].add_theme_stylebox_override("normal", _button_style(Color("#FFE2B6")))
	else:
		_on_move_swapped(selected, index)

func _on_move_swapped(from_index: int, to_index: int) -> void:
	var slots: Array = _mechanic.slots
	if from_index >= 0 and to_index >= 0 and from_index < slots.size() and to_index < slots.size():
		var moved_piece: Variant = slots[from_index]
		slots[from_index] = slots[to_index]
		slots[to_index] = moved_piece
	_mechanic.slots = slots
	_mechanic.selected = -1
	for i in range(_move_buttons.size()): _move_buttons[i].text = str(slots[i])

func _check_mechanic() -> void:
	match _level_data.kind:
		"wires", "water": _submit_answer(_mechanic.rotations)
		"shape": _submit_answer(int(_mechanic.rotation))
		"memory": _submit_answer(_mechanic.sequence)
		"move": _submit_answer(_mechanic.slots)

func _show_hint() -> void:
	if _hint_used: return
	_hint_used = true
	_elapsed += 12.0
	_hint_button.disabled = true
	_feedback_label.text = "HINT  ·  " + str(_level_data.hint)
	_feedback_label.add_theme_color_override("font_color", TEAL)

func _submit_answer(guess: Variant) -> void:
	if _finished: return
	if Levels.answer_is_correct(_level_data, guess):
		_finish_win()
	else:
		_wrong_count += 1
		_feedback_label.text = "Not quite. Study the clue and try another move."
		_feedback_label.add_theme_color_override("font_color", CORAL)
		_audio.play_retry()
		if not _reduce_motion:
			var tween := create_tween()
			tween.tween_property(_feedback_label, "position:x", _feedback_label.position.x + 5.0, 0.05)
			tween.tween_property(_feedback_label, "position:x", _feedback_label.position.x, 0.05)

func _finish_win() -> void:
	_finished = true
	var ratio := maxf(0.0, (_time_left - _elapsed) / _time_left)
	var stars := 3 if ratio >= 0.55 and not _hint_used else (2 if ratio >= 0.20 else 1)
	if _hint_used: stars = mini(stars, 2)
	var reward := 40 + stars * 10 + maxi(0, int((_time_left - _elapsed) * 1.5))
	var coin_reward := 12 + stars * 4
	_stars[str(_level)] = maxi(stars, int(_stars.get(str(_level), 0)))
	_total_score += reward
	_coins += coin_reward
	_unlocked = mini(50, maxi(_unlocked, _level + 1))
	_persist()
	_audio.play_success()
	_build_result(true, stars, reward, coin_reward)

func _finish_timeout() -> void:
	if _finished: return
	_finished = true
	_audio.play_retry()
	_build_result(false, 0, 0, 0)

func _build_result(won: bool, stars: int, reward: int, coin_reward: int) -> void:
	var body := _open_page("result")
	var box := _card(body, Color("#FFF3D5") if won else Color("#FCE8E7"))
	box.add_child(_label("ROOM CLEARED!" if won else "TIME'S UP", 32, TEAL if won else CORAL, true))
	box.add_child(_label(_level_data.title, 20, INK, true))
	if won:
		box.add_child(_illustration(DOOR_ART, Vector2(82, 104)))
		box.add_child(_label("★".repeat(stars) + "☆".repeat(3 - stars), 38, GOLD, true))
		box.add_child(_label("+%d points     +%d coins" % [reward, coin_reward], 18, INK, true))
		box.add_child(_label("A new room is ready." if _level < 50 else "You escaped every room. The vault is yours!", 16, MUTED))
		if _level < 50: body.add_child(_button("NEXT ROOM  →", Callable(self, "_start_level").bind(_level + 1), true))
		else: body.add_child(_button("BACK TO LEVELS", Callable(self, "_build_levels"), true))
	else:
		box.add_child(_label("The vault door is still locked. Reset the puzzle and take another run.", 16, MUTED))
		body.add_child(_button("TRY AGAIN", Callable(self, "_restart_level"), true))
	body.add_child(_button("LEVELS", Callable(self, "_build_levels")))
	body.add_child(_button("HOME", Callable(self, "_build_home")))
	_animate(body)

func _build_pause() -> void:
	_paused = true
	_audio.pause_music(true)
	var body := _open_page("pause")
	var box := _card(body, Color("#EAF3F4"))
	box.add_child(_label("PAUSED", 32, INK, true))
	box.add_child(_label("Room %02d is waiting. Your timer is stopped." % _level, 16, MUTED))
	body.add_child(_button("RESUME", Callable(self, "_resume_game"), true))
	body.add_child(_button("RESTART ROOM", Callable(self, "_restart_level")))
	body.add_child(_button("LEVELS", Callable(self, "_build_levels")))
	body.add_child(_button("HOME", Callable(self, "_build_home")))

func _resume_game() -> void:
	_paused = false
	_audio.pause_music(false)
	_build_game_screen(false)

func _restart_level() -> void:
	_start_level(_level)

func _exit_game() -> void:
	if OS.has_feature("web"):
		var body := _open_page("home")
		body.add_child(_label("Thanks for playing Brain Escape. You can close this tab when you're ready.", 22, INK, true))
		body.add_child(_button("BACK", Callable(self, "_build_home"), true))
	else:
		get_tree().quit()

func _animate(node: Control) -> void:
	if _reduce_motion: return
	node.modulate.a = 0.0
	node.scale = Vector2(0.985, 0.985)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, 0.22)
	tween.tween_property(node, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _zeroes(count: int) -> Array[int]:
	var values: Array[int] = []
	for _i in range(count): values.append(0)
	return values

func _format_time(seconds: int) -> String:
	return "%02d:%02d" % [int(seconds / 60), seconds % 60]

func _join_words(words: Array, separator: String) -> String:
	var text := ""
	for i in range(words.size()):
		if i > 0: text += separator
		text += str(words[i])
	return text

func _illustration(texture: Texture2D, target_size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = target_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

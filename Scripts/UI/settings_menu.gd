extends CanvasLayer

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const Audio := preload("res://Scripts/Gameplay/workshop_audio.gd")
## Paused workshop menu and explicit exit confirmation.

var workshop: Node
var is_open := false
var _pause_before := false
var _overlay: Control
var _menu: VBoxContainer
var _confirmation: VBoxContainer
var _status: Label
var _resume: Button
var _cancel: Button
var _regional: VBoxContainer
var _language: OptionButton
var _currency: OptionButton
var _effects_volume: HSlider
var _display_mode: OptionButton
var _resolution: OptionButton


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = Control.new()
	_overlay.theme = preload("res://Themes/maintenance_bench.tres")
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.045, 0.8)
	_overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 360
	center.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d1d2b")
	style.border_color = Color("47738b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	panel.add_child(content)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 10)
	content.add_child(_menu)
	_heading(_menu, "Configurações")
	var version := Label.new()
	version.name = "GameVersion"
	version.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_color_override("font_color", Color("96d4dc"))
	_menu.add_child(version)
	_button(_menu, "SaveProgress", "Salvar (F5)", _save)
	_button(_menu, "RestoreProgress", "Restaurar (F9)", _restore)
	_button(_menu, "CustomizeWorkshop", "Decorar (F2)", _decorate)
	_button(_menu, "RegionalSettings", "Idioma e moeda", _open_regional)
	var display_grid := GridContainer.new()
	display_grid.columns = 2
	_menu.add_child(display_grid)
	_display_mode = _picker(display_grid, "DisplayMode", "Modo de exibição", Prefs.WINDOW_MODES.values())
	_display_mode.item_selected.connect(_select_display_mode)
	_resolution = _picker(display_grid, "WindowResolution", "Resolução da janela", [])
	_resolution.allow_reselect = true
	for size in Prefs.WINDOW_RESOLUTIONS:
		_resolution.add_item("%d × %d" % [size.x, size.y])
	_resolution.item_selected.connect(_select_resolution)
	get_window().size_changed.connect(func() -> void:
		if is_open and _menu.visible:
			_sync_resolution())
	var audio_row := HBoxContainer.new()
	_menu.add_child(audio_row)
	var audio_label := Label.new()
	audio_label.text = "Volume dos efeitos"
	audio_row.add_child(audio_label)
	_effects_volume = HSlider.new()
	_effects_volume.name = "EffectsVolume"
	_effects_volume.max_value = 100
	_effects_volume.step = 5
	_effects_volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effects_volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_effects_volume.custom_minimum_size.y = 30
	audio_row.add_child(_effects_volume)
	_effects_volume.value_changed.connect(func(value: float) -> void:
		Prefs.set_effects_volume(value / 100.0)
		Audio.play("click"))
	_button(_menu, "ExitGame", "Sair do jogo", _ask_exit)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 13)
	_menu.add_child(_status)
	_resume = _button(_menu, "ResumeGame", "Voltar ao jogo", close_menu)
	_confirmation = VBoxContainer.new()
	_confirmation.add_theme_constant_override("separation", 14)
	content.add_child(_confirmation)
	_heading(_confirmation, "Sair do jogo?")
	var question := Label.new()
	question.text = "Tem certeza de que deseja sair?"
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirmation.add_child(question)
	_cancel = _button(_confirmation, "CancelExit", "Cancelar", _cancel_exit)
	_button(_confirmation, "ConfirmExit", "Sair", _confirm_exit)
	_regional = VBoxContainer.new()
	_regional.add_theme_constant_override("separation", 10)
	content.add_child(_regional)
	_heading(_regional, "Idioma e moeda")
	_language = _picker(_regional, "Language", "Idioma", Prefs.LANGUAGES.values())
	_currency = _picker(_regional, "Currency", "Moeda", Prefs.CURRENCIES)
	_language.item_selected.connect(func(index: int) -> void: Prefs.select(Prefs.LANGUAGES.keys()[index], Prefs.currency))
	_currency.item_selected.connect(func(index: int) -> void: Prefs.select(Prefs.language, Prefs.CURRENCIES[index]))
	_button(_regional, "BackFromRegional", "Voltar", _close_regional)
	_regional.hide()
	_overlay.hide()
	_confirmation.hide()


func _select_display_mode(index: int) -> void:
	Prefs.set_window_mode(Prefs.WINDOW_MODES.keys()[index])
	_sync_resolution()


func _select_resolution(index: int) -> void:
	if index < Prefs.WINDOW_RESOLUTIONS.size():
		Prefs.set_window_resolution(Prefs.WINDOW_RESOLUTIONS[index])
	_sync_resolution()


func _sync_resolution() -> void:
	var window := get_window()
	var resolutions := Prefs.WINDOW_RESOLUTIONS
	var is_windowed := Prefs.window_mode == Window.MODE_WINDOWED
	_resolution.disabled = not is_windowed
	_resolution.tooltip_text = "Resoluções maiores são ajustadas à área útil do monitor." if is_windowed else "Neste modo, o jogo usa a resolução do monitor."
	if _resolution.item_count > resolutions.size():
		_resolution.remove_item(resolutions.size())
	var screen_size := DisplayServer.screen_get_size(window.current_screen)
	var size := window.size if is_windowed or screen_size == Vector2i.ZERO else screen_size
	var selected := resolutions.find(size)
	if selected == -1:
		selected = resolutions.size()
		_resolution.add_item("%d × %d" % [size.x, size.y])
		_resolution.set_item_disabled(selected, true)
	_resolution.select(selected)


func _picker(parent: Control, id: String, caption: String, entries: Array) -> OptionButton:
	var label := Label.new()
	label.text = caption
	parent.add_child(label)
	var picker := OptionButton.new()
	picker.name = id
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.custom_minimum_size.y = 30
	for entry in entries: picker.add_item(entry)
	parent.add_child(picker)
	return picker


func _open_regional() -> void:
	_menu.hide()
	_language.select(Prefs.LANGUAGES.keys().find(Prefs.language))
	_currency.select(Prefs.CURRENCIES.find(Prefs.currency))
	_regional.show()
	_language.grab_focus()


func _close_regional() -> void:
	_regional.hide()
	_menu.show()
	find_child("RegionalSettings", true, false).grab_focus()

func _heading(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	parent.add_child(label)


func _button(parent: Control, id: String, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.text = text
	button.custom_minimum_size.y = 42
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func open_menu() -> void:
	if is_open: return
	_pause_before = get_tree().paused
	is_open = true
	get_tree().paused = true
	workshop._hud.hide()
	_status.text = ""
	_display_mode.select(Prefs.WINDOW_MODES.keys().find(Prefs.window_mode))
	_sync_resolution()
	_effects_volume.set_value_no_signal(Prefs.effects_volume * 100.0)
	_menu.show()
	_confirmation.hide()
	_regional.hide()
	_overlay.show()
	_resume.grab_focus()



func close_menu() -> void:
	if not is_open: return
	is_open = false
	_overlay.hide()
	get_tree().paused = _pause_before
	workshop._hud.visible = not get_tree().paused


func _save() -> void:
	_status.text = "Progresso salvo." if workshop.save_game() else "Não foi possível salvar."


func _restore() -> void:
	close_menu()
	workshop.load_game()


func _decorate() -> void:
	close_menu()
	workshop.decoration_ui.open_menu()


func _ask_exit() -> void:
	_menu.hide()
	_confirmation.show()
	_cancel.grab_focus()


func _cancel_exit() -> void:
	_confirmation.hide()
	_menu.show()
	find_child("ExitGame", true, false).grab_focus()


func _confirm_exit() -> void:
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if not is_open or not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_ESCAPE:
			if _confirmation.visible: _cancel_exit()
			elif _regional.visible: _close_regional()
			else: close_menu()
		KEY_F5:
			if _menu.visible: _save()
		KEY_F9:
			if _menu.visible: _restore()
		KEY_F2:
			if _menu.visible: _decorate()
		_: return
	get_viewport().set_input_as_handled()

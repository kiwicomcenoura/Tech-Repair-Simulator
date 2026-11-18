extends SceneTree

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
var checks := 0
var failures := 0


func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)


func frames() -> void:
	for i in range(3): await process_frame


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1360, 768)
	var world: Node2D = preload("res://Tools/test_world.gd").create()
	var workshop: Node = world.get_node("PhysicalWorkshop")
	workshop.save_path = "res://.godot/settings-menu-test.json"
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(workshop.save_path + suffix):
			DirAccess.remove_absolute(workshop.save_path + suffix)
	root.add_child(world)
	await frames()
	var menu: CanvasLayer = workshop.settings_ui
	check(not menu.is_open and not paused, "Menu starts closed")
	check(workshop._hud.find_child("SaveProgress", true, false) == null, "Old toolbar actions moved into settings")
	workshop._hud.find_child("OpenSettings", true, false).pressed.emit()
	await frames()
	check(menu.is_open and paused and not workshop._hud.visible, "Settings button opens modal and pauses workshop")
	for id in ["SaveProgress", "RestoreProgress", "CustomizeWorkshop", "ExitGame"]:
		check(menu.find_child(id, true, false).is_visible_in_tree(), "Settings includes " + id)
	var original_path := Prefs.config_path
	var original_language := Prefs.language
	var original_currency := Prefs.currency
	Prefs.config_path = "res://.godot/test-preferences.cfg"
	var original_volume := Prefs.effects_volume
	var audio: Node = root.get_node("WorkshopAudio")
	var click_player: AudioStreamPlayer = audio._players.click
	check(click_player.stream.get_length() > 0.0 and audio.process_mode == Node.PROCESS_MODE_ALWAYS, "Sound effects are generated and can play while menus pause the game")
	menu._effects_volume.value = 0
	click_player.stop()
	audio.play("click")
	check(Prefs.effects_volume == 0.0 and not click_player.playing, "Volume slider can mute playback")
	menu._effects_volume.value = 50
	var config := ConfigFile.new()
	check(click_player.playing and config.load(Prefs.config_path) == OK and config.get_value("audio", "effects_volume") == 0.5, "Volume slider previews the sound and persists the selected level")
	var display_picker: OptionButton = menu.find_child("DisplayMode", true, false)
	var resolution_picker: OptionButton = menu.find_child("WindowResolution", true, false)
	var original_size := root.size
	var original_mode := Prefs.window_mode
	var original_resolution := Prefs.window_resolution
	display_picker.item_selected.emit(0)
	var small_resolution := Vector2i(800, 600)
	var small_index := Prefs.WINDOW_RESOLUTIONS.find(small_resolution)
	check(resolution_picker.is_visible_in_tree() and not resolution_picker.disabled and not resolution_picker.is_item_disabled(small_index), "Windowed settings expose 800 × 600")
	resolution_picker.show_popup()
	await frames()
	check(resolution_picker.get_popup().visible, "The resolution dropdown opens")
	resolution_picker.get_popup().hide()
	var large_resolution := Vector2i(3840, 2160)
	var large_index := Prefs.WINDOW_RESOLUTIONS.find(large_resolution)
	check(not resolution_picker.is_item_disabled(large_index), "Large resolutions remain selectable in windowed mode")
	resolution_picker.item_selected.emit(large_index)
	await frames()
	if DisplayServer.get_name() != "headless":
		var outer_rect := Rect2i(root.get_position_with_decorations(), root.get_size_with_decorations())
		check(DisplayServer.screen_get_usable_rect(root.current_screen).encloses(outer_rect), "Large resolutions fit inside the monitor work area")
	resolution_picker.select(small_index)
	resolution_picker.item_selected.emit(small_index)
	await frames()
	check(config.load(Prefs.config_path) == OK and config.get_value("display", "window_resolution") == small_resolution and config.get_value("audio", "effects_volume") == 0.5, "Resolution selection saves alongside audio preferences")
	if DisplayServer.get_name() != "headless":
		check(root.size == small_resolution and resolution_picker.selected == small_index, "Selecting a resolution resizes the window immediately")
		check(root.get_visible_rect().encloses(menu._menu.get_global_rect()), "Settings remain visible at 800 × 600")
	check(resolution_picker.get_item_text(Prefs.WINDOW_RESOLUTIONS.find(Vector2i(1280, 768))) == "1280 × 768", "Settings includes the 1280 × 768 preset")
	for mode in [Window.MODE_EXCLUSIVE_FULLSCREEN, Window.MODE_FULLSCREEN]:
		display_picker.item_selected.emit(Prefs.WINDOW_MODES.keys().find(mode))
		await frames()
		check(resolution_picker.disabled and Prefs.window_mode == mode and config.load(Prefs.config_path) == OK and config.get_value("display", "window_mode") == mode and config.get_value("display", "window_resolution") == small_resolution, "Fullscreen modes preserve the windowed resolution and save the display mode")
		if DisplayServer.get_name() != "headless":
			check(root.mode == mode and resolution_picker.text == "%d × %d" % [DisplayServer.screen_get_size(root.current_screen).x, DisplayServer.screen_get_size(root.current_screen).y], "Fullscreen modes use the monitor resolution")
	display_picker.item_selected.emit(0)
	await frames()
	if DisplayServer.get_name() != "headless":
		check(root.mode == Window.MODE_WINDOWED and root.size == small_resolution, "Returning to windowed mode restores 800 × 600")
	check(not resolution_picker.disabled, "Returning to windowed mode re-enables the resolution dropdown")
	Prefs.window_resolution = original_resolution
	Prefs.set_window_mode(original_mode)
	root.size = original_size
	Prefs.set_effects_volume(original_volume)
	menu.find_child("RegionalSettings", true, false).pressed.emit()
	await frames()
	check(menu._regional.visible and menu._language.item_count == 3 and menu._currency.item_count == 3, "Regional settings expose three independent language and currency choices")
	menu._language.select(1)
	menu._language.item_selected.emit(1)
	menu._currency.select(1)
	menu._currency.item_selected.emit(1)
	check(Prefs.t("Configurações") == "Settings" and Prefs.money(1300) == "$ 1,300.00", "English and dollar formatting apply from the selectors")
	menu._language.select(2)
	menu._language.item_selected.emit(2)
	check(Prefs.t("Bancada de Manutenção") == "Banco de mantenimiento" and Prefs.currency == "$", "Spanish selection leaves the currency unchanged")
	menu._currency.select(2)
	menu._currency.item_selected.emit(2)
	check(Prefs.money(300) == "€ 300,00" and FileAccess.file_exists(Prefs.config_path), "Euro formatting applies and preferences are saved")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/regional-settings.png")
	await key(KEY_ESCAPE)
	check(menu._menu.visible and paused, "Esc returns from regional preferences to settings")
	Prefs.select(original_language, original_currency)
	Prefs.config_path = original_path
	menu.find_child("SaveProgress", true, false).pressed.emit()
	check(FileAccess.file_exists(workshop.save_path) and paused, "Save works while settings stay open")
	var credits: int = workshop.ledger.state.credits
	workshop.ledger.state.credits += 20
	menu.find_child("RestoreProgress", true, false).pressed.emit()
	await frames()
	check(not menu.is_open and not paused and workshop.ledger.state.credits == credits, "Restore loads saved state and resumes")
	check(workshop._status.text == Prefs.money(credits) and workshop._status.get_parent().name == "Wallet", "HUD shows only the bordered, formatted balance")
	await key(KEY_ESCAPE)
	check(menu.is_open and paused, "Esc opens settings from gameplay")
	menu.find_child("CustomizeWorkshop", true, false).pressed.emit()
	check(not menu.is_open and workshop.decoration_ui.is_open and paused, "Decorate transfers control to decoration menu")
	workshop.decoration_ui.close_menu()
	check(not paused, "Closing decoration resumes gameplay")
	menu.open_menu()
	menu.find_child("ExitGame", true, false).pressed.emit()
	check(menu._confirmation.visible and not menu._menu.visible and paused, "Exit only opens confirmation")
	check(menu._cancel.has_focus() and menu._confirmation.find_children("*", "Button", true, false).size() == 2, "Confirmation offers two choices and focuses Cancel")
	menu.find_child("CancelExit", true, false).pressed.emit()
	check(menu._menu.visible and not menu._confirmation.visible and menu.is_open, "Cancel returns to settings")
	menu.find_child("ExitGame", true, false).pressed.emit()
	await key(KEY_ESCAPE)
	check(menu._menu.visible and menu.is_open, "Esc cancels exit confirmation")
	await key(KEY_ESCAPE)
	check(not menu.is_open and not paused and workshop._hud.visible, "Esc closes settings and restores HUD")
	menu.open_menu()
	await key(KEY_F5)
	check(menu.is_open and paused, "Save shortcut works in settings")
	menu.find_child("ExitGame", true, false).pressed.emit()
	print("SETTINGS MENU CHECKS: ", checks, "; failures: ", failures)
	if failures > 0:
		quit(1)
	else:
		menu.find_child("ConfirmExit", true, false).pressed.emit()

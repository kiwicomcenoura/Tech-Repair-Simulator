extends Node

signal changed

static var config_path := "user://preferences.cfg"
const LANGUAGES := {"pt": "Português", "en": "English", "es": "Español"}
const CURRENCIES := ["R$", "$", "€"]
const WINDOW_MODES := {
	Window.MODE_WINDOWED: "Janela",
	Window.MODE_EXCLUSIVE_FULLSCREEN: "Tela cheia",
	Window.MODE_FULLSCREEN: "Janela sem borda",
}
const WINDOW_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(800, 600), Vector2i(960, 540), Vector2i(1024, 768),
	Vector2i(1128, 634), Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1280, 768),
	Vector2i(1360, 768), Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(2560, 1440), Vector2i(3840, 2160),
]
static var language := "pt"
static var currency := "R$"
static var effects_volume := 0.65
static var window_mode := Window.MODE_WINDOWED
static var window_resolution := Vector2i.ZERO
static var _instance: Node


func _ready() -> void:
	_instance = self
	var config := ConfigFile.new()
	if config.load(config_path) == OK:
		var stored_language: Variant = config.get_value("display", "language", "pt")
		var stored_currency: Variant = config.get_value("display", "currency", "R$")
		if stored_language in LANGUAGES: language = stored_language
		if stored_currency in CURRENCIES: currency = stored_currency
		var stored_volume: Variant = config.get_value("audio", "effects_volume", effects_volume)
		if (stored_volume is float or stored_volume is int) and is_finite(stored_volume):
			effects_volume = clampf(stored_volume, 0.0, 1.0)
		var stored_resolution: Variant = config.get_value("display", "window_resolution", Vector2i.ZERO)
		if stored_resolution is Vector2i and stored_resolution in WINDOW_RESOLUTIONS:
			window_resolution = stored_resolution
		var stored_mode: Variant = config.get_value("display", "window_mode", Window.MODE_WINDOWED)
		if stored_mode is int and stored_mode in WINDOW_MODES:
			window_mode = stored_mode
	_apply_display_settings()
	var catalog := preload("res://Scripts/UI/translations.gd").catalog()
	for locale in catalog:
		var translation := Translation.new()
		translation.locale = locale
		var messages: Dictionary = catalog[locale]
		for original in messages: translation.add_message(original, messages[original])
		TranslationServer.add_translation(translation)
	TranslationServer.set_locale(language)


static func select(new_language: String, new_currency: String) -> void:
	if new_language not in LANGUAGES or new_currency not in CURRENCIES: return
	language = new_language
	currency = new_currency
	TranslationServer.set_locale(language)
	_save()
	if is_instance_valid(_instance): _instance.changed.emit()


static func set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	_save()


static func set_window_mode(mode: Window.Mode) -> void:
	if mode not in WINDOW_MODES or not is_instance_valid(_instance):
		return
	window_mode = mode
	_instance._apply_display_settings()
	_save()


static func set_window_resolution(resolution: Vector2i) -> void:
	if resolution not in WINDOW_RESOLUTIONS or window_mode != Window.MODE_WINDOWED or not is_instance_valid(_instance):
		return
	window_resolution = resolution
	_instance._apply_display_settings()
	_save()


func _apply_display_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	var usable_rect := DisplayServer.screen_get_usable_rect(window.current_screen)
	window.mode = window_mode
	if window_mode != Window.MODE_WINDOWED:
		return
	var requested := window_resolution if window_resolution != Vector2i.ZERO else window.content_scale_size
	var frame_size := (window.get_size_with_decorations() - window.size).max(Vector2i.ZERO)
	var available := usable_rect.size - frame_size
	if available.x > 0 and available.y > 0:
		var scale := minf(1.0, minf(float(available.x) / requested.x, float(available.y) / requested.y))
		window.size = Vector2i(Vector2(requested) * scale)
	var outer_rect := Rect2i(window.get_position_with_decorations(), window.get_size_with_decorations())
	window.position += usable_rect.get_center() - outer_rect.get_center()


static func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "language", language)
	config.set_value("display", "currency", currency)
	config.set_value("display", "window_mode", window_mode)
	if window_resolution != Vector2i.ZERO:
		config.set_value("display", "window_resolution", window_resolution)
	config.set_value("audio", "effects_volume", effects_volume)
	config.save(config_path)


static func on_change(callback: Callable) -> void:
	if is_instance_valid(_instance): _instance.changed.connect(callback)


static func t(message: String) -> String:
	return TranslationServer.translate(message)


static func money(amount: int) -> String:
	var separator := "," if currency == "$" else "."
	var digits := str(absi(amount))
	var grouped := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0: grouped += separator
		grouped += digits[i]
	return ("%s%s %s%s00" % ["-" if amount < 0 else "", currency, grouped, "." if currency == "$" else ","])

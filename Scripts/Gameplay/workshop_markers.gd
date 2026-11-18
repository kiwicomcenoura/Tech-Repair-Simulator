extends Node2D

const Prefs := preload("res://Scripts/UI/player_preferences.gd")

var workshop: Node
var _toolbox: Sprite2D
var _tools_visible := false

func _ready() -> void:
	z_index = -3
	_toolbox = Sprite2D.new()
	_toolbox.name = "Toolbox"
	_toolbox.texture = load("res://Assets/Physical/toolbox.png")
	_toolbox.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_toolbox.position = Vector2(-210, 12)
	add_child(_toolbox)
	workshop.ledger.changed.connect(_refresh_tools)
	# Loading a save replaces the ledger state and emits feedback.
	workshop.ledger.feedback.connect(func(_text: String, _failed: bool) -> void: _refresh_tools())
	_refresh_tools()


func _refresh_tools() -> void:
	var show_tools: bool = not workshop.ledger.state.tools
	_toolbox.visible = show_tools
	if _tools_visible != show_tools:
		_tools_visible = show_tools
		queue_redraw()


func _draw() -> void:
	if _tools_visible:
		draw_string(ThemeDB.fallback_font, Vector2(-250, 76), Prefs.t("FERRAMENTAS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b2c2cc"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED: queue_redraw()

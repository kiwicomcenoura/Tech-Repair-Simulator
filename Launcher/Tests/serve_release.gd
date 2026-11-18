extends SceneTree

const Server := preload("res://Tests/fixture_server.gd")
const Release := preload("res://release_info.gd")
var _server := Server.new()


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3 or not args[0].is_valid_int() or Release.version_parts(args[1]).is_empty():
		printerr("Uso: -- PORTA vMAJOR.MINOR.PATCH CAMINHO_DO_ZIP [truncate|digest]")
		quit(1)
		return
	var package := FileAccess.get_file_as_bytes(args[2])
	if package.is_empty():
		printerr("Não foi possível ler o ZIP de teste.")
		quit(1)
		return
	_server.version = args[1]
	if args.size() > 3:
		_server.fault = args[3]
	var port := int(args[0])
	if port < 1024 or port > 65535 or _server.start(port, package) != OK:
		printerr("Não foi possível abrir a porta local.")
		quit(1)
		return
	process_frame.connect(_server.tick)
	print("Fixture disponível apenas em 127.0.0.1:", port, " · ", _server.version)

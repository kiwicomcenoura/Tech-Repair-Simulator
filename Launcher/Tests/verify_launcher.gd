extends SceneTree

const Server := preload("res://Tests/fixture_server.gd")
const Release := preload("res://release_info.gd")
const Store := preload("res://install_store.gd")

var _server := Server.new()
var _failures := 0


func _initialize() -> void:
	run.call_deferred()


func check(value: bool, description: String) -> void:
	if not value:
		_failures += 1
		push_error(description)


func settled(launcher: Control) -> bool:
	var deadline := Time.get_ticks_msec() + 15000
	while launcher._job != launcher.Job.IDLE and Time.get_ticks_msec() < deadline:
		await create_timer(0.015).timeout
	return launcher._job == launcher.Job.IDLE


func run() -> void:
	var launcher: Control = preload("res://Launcher.tscn").instantiate()
	var port: int = launcher._get_fixture_port()
	if port == 0:
		printerr("Acrescente -- --fixture-port=47813 na chamada.")
		quit(1)
		return
	var temporary := ProjectSettings.globalize_path("user://launcher-test-%d.zip" % OS.get_process_id())
	var fake_executable := PackedByteArray()
	fake_executable.resize(8192)
	fake_executable.encode_u16(0, 0x5a4d)
	fake_executable.encode_u32(0x3c, 64)
	fake_executable.encode_u32(64, 0x4550)
	fake_executable.encode_u16(68, 0x8664)
	fake_executable.encode_u16(88, 0x20b)
	var zip := ZIPPacker.new()
	if zip.open(temporary) != OK:
		printerr("Não foi possível criar o pacote de teste.")
		quit(1)
		return
	zip.start_file(Store.GAME_EXE)
	zip.write_file(fake_executable)
	zip.close_file()
	zip.close()
	var package := FileAccess.get_file_as_bytes(temporary)
	DirAccess.remove_absolute(temporary)
	if _server.start(port, package) != OK:
		printerr("Porta de fixture indisponível.")
		quit(1)
		return
	process_frame.connect(_server.tick)
	root.add_child(launcher)
	await process_frame
	check(await settled(launcher) and launcher._install_button.visible and launcher._install_button.text == "Instalar", "First run offers installation")
	check(launcher._installed.is_empty(), "Run tests in a fresh temporary APPDATA profile")
	launcher._download()
	check(await settled(launcher) and launcher._installed.get("version") == "v0.1.0", "Verified package is installed over HTTP")
	check("abriria o jogo v0.1.0" in launcher._status.text, "Installation triggers launch intent")
	launcher._check_release()
	check(await settled(launcher) and "abriria o jogo v0.1.0" in launcher._status.text, "Current version automatically triggers launch intent")

	_server.version = "v0.2.0"
	_server.fault = "truncate"
	launcher._check_release()
	check(await settled(launcher) and launcher._install_button.text == "Atualizar", "New release offers update")
	launcher._download()
	check(await settled(launcher) and launcher._install_button.text == "Tentar novamente", "Interrupted download is retryable")
	check(launcher._store.installed().get("version") == "v0.1.0", "Interrupted download preserves the previous installation")
	_server.fault = "digest"
	launcher._check_release()
	check(await settled(launcher), "Digest test release loaded")
	launcher._download()
	check(await settled(launcher) and "SHA-256 falhou" in launcher._status.text, "Bad digest is rejected")
	check(launcher._store.installed().get("version") == "v0.1.0", "Invalid package preserves installed version")
	_server.fault = ""
	launcher._check_release()
	check(await settled(launcher), "Clean release loaded")
	launcher._download()
	check(await settled(launcher) and launcher._store.installed().get("version") == "v0.2.0", "Update commits a new installation")
	_server.stop()
	process_frame.disconnect(_server.tick)
	launcher._check_release()
	check(await settled(launcher) and not launcher._offline.disabled, "Connection error enables offline mode")
	launcher._launch_game()
	check("abriria o jogo v0.2.0" in launcher._status.text, "Offline launches the installed version")
	check(Release.is_newer("v0.10.0", "v0.9.0") and not Release.is_newer("v0.2.0-beta", "v0.1.0"), "Version comparison is numeric and stable")
	print("LAUNCHER TESTS · failures: ", _failures)
	quit(1 if _failures > 0 else 0)

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


func make_package(build: int) -> PackedByteArray:
	var temporary := ProjectSettings.globalize_path("user://launcher-test-%d.zip" % OS.get_process_id())
	var fake_executable := PackedByteArray()
	fake_executable.resize(8192)
	fake_executable.encode_u16(0, 0x5a4d)
	fake_executable.encode_u32(0x3c, 64)
	fake_executable.encode_u32(64, 0x4550)
	fake_executable.encode_u16(68, 0x8664)
	fake_executable.encode_u16(88, 0x20b)
	fake_executable[1024] = build
	var zip := ZIPPacker.new()
	if zip.open(temporary) != OK:
		return PackedByteArray()
	zip.start_file(Store.GAME_EXE)
	zip.write_file(fake_executable)
	zip.close_file()
	zip.close()
	var package := FileAccess.get_file_as_bytes(temporary)
	DirAccess.remove_absolute(temporary)
	return package


func run() -> void:
	var launcher: Control = preload("res://Launcher.tscn").instantiate()
	var port: int = launcher._get_fixture_port()
	if port == 0:
		printerr("Acrescente -- --fixture-port=47813 na chamada.")
		quit(1)
		return
	var first_package := make_package(0)
	var update_package := make_package(1)
	if first_package.is_empty() or update_package.is_empty():
		printerr("Não foi possível criar os pacotes de teste.")
		quit(1)
		return
	if _server.start(port, first_package) != OK:
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
	var original_executable: String = launcher._installed.get("executable", "")
	var original_hash := FileAccess.get_sha256(original_executable)
	launcher._check_release()
	check(await settled(launcher) and not launcher._install_button.visible, "Current version offers no update")
	check("abriria o jogo v0.1.0" in launcher._status.text, "Current version automatically triggers launch intent")

	_server.stop()
	_server.version = "v0.1.1"
	if _server.start(port, update_package) != OK:
		printerr("Não foi possível iniciar o servidor com o pacote de atualização.")
		quit(1)
		return
	_server.fault = "truncate"
	launcher._check_release()
	var update_button: Button = launcher._install_button
	check(await settled(launcher) and update_button.visible and not update_button.disabled and update_button.text == "Atualizar",
		"v0.1.1 offers an enabled update button")
	launcher._install_button.pressed.emit()
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
	check(await settled(launcher), "Update completes")
	var updated: Dictionary = launcher._store.installed()
	check(updated.get("version") == "v0.1.1" and launcher._installed == updated, "The launcher and install store select v0.1.1")
	var updated_executable: String = updated.get("executable", "")
	var updated_bytes := FileAccess.get_file_as_bytes(updated_executable)
	check(updated_executable != original_executable and updated_bytes.size() == 8192 and updated_bytes[1024] == 1,
		"The active executable comes from the new package")
	check(not original_hash.is_empty() and FileAccess.get_sha256(original_executable) == original_hash,
		"The previous executable remains intact")
	_server.stop()
	process_frame.disconnect(_server.tick)
	launcher._check_release()
	check(await settled(launcher) and not launcher._offline.disabled, "Connection error enables offline mode")
	launcher._launch_game()
	check("abriria o jogo v0.1.1" in launcher._status.text, "Offline launches the updated version")
	check(Release.is_newer("v0.1.1", "v0.1.0"), "v0.1.1 is newer than v0.1.0")
	check(not Release.is_newer("v0.1.0", "v0.1.1") and not Release.is_newer("v0.1.1", "v0.1.1"),
		"Older and equal releases do not qualify for an update")
	check(Release.is_newer("v0.10.0", "v0.9.0") and not Release.is_newer("v0.2.0-beta", "v0.1.0"), "Version comparison is numeric and stable")
	print("LAUNCHER TESTS · failures: ", _failures)
	quit(1 if _failures > 0 else 0)

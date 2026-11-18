extends Control

const Release := preload("res://release_info.gd")
const Store := preload("res://install_store.gd")
const SETTINGS := "user://launcher.cfg"

enum Job { IDLE, CHECK, DOWNLOAD, INSTALL }

var _job := Job.IDLE
var _request: HTTPRequest
var _store: RefCounted
var _installed := {}
var _offered := {}
var _stage := ""
var _repo := ""
var _fixture_base := ""
var _worker: Thread

@onready var _repository: LineEdit = %Repository
@onready var _version: Label = %Version
@onready var _status: Label = %Status
@onready var _progress: ProgressBar = %Progress
@onready var _check: Button = %Check
@onready var _install_button: Button = %Install
@onready var _offline: Button = %Offline


func _ready() -> void:
	_request = HTTPRequest.new()
	_request.use_threads = true
	_request.accept_gzip = false
	_request.request_completed.connect(_completed)
	add_child(_request)
	_check.pressed.connect(_check_release)
	_install_button.pressed.connect(_download)
	_offline.pressed.connect(_launch_game)
	_repository.text_submitted.connect(func(_text: String) -> void: _check_release())
	_repository.text_changed.connect(func(_text: String) -> void:
		_offered.clear()
		_sync_buttons())
	var local_app_data := OS.get_environment("LOCALAPPDATA")
	var root := ProjectSettings.globalize_path("user://installations")
	if not local_app_data.is_empty():
		root = local_app_data.path_join("Tech Repair Simulator/Launcher/installations").replace("\\", "/")
	var fixture_port := _get_fixture_port()
	if fixture_port > 0:
		_fixture_base = "http://127.0.0.1:%d" % fixture_port
		root = ProjectSettings.globalize_path("user://fixtures/%d" % fixture_port)
	_store = Store.new(root)
	_store.clean_interrupted()
	_installed = _store.installed()
	_repository.text = _configured_repository() if _fixture_base.is_empty() else "local/fixture"
	_status.text = "Informe OWNER/REPO para procurar versões."
	_sync_buttons()
	if not _repository.text.is_empty():
		_check_release.call_deferred()


func _configured_repository() -> String:
	var config := ConfigFile.new()
	var value := ""
	if config.load("res://repository.cfg") == OK:
		value = str(config.get_value("github", "repository", ""))
	if config.load(SETTINGS) == OK:
		value = str(config.get_value("github", "repository", value))
	return value.strip_edges()


func _get_fixture_port() -> int:
	if not OS.has_feature("editor"):
		return 0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--fixture-port="):
			var port := argument.trim_prefix("--fixture-port=")
			if port.is_valid_int() and int(port) >= 1024 and int(port) <= 65535:
				return int(port)
	return 0


func _sync_buttons() -> void:
	var busy := _job != Job.IDLE
	_repository.editable = not busy and _fixture_base.is_empty()
	_check.disabled = busy
	_offline.disabled = busy or _installed.is_empty()
	_install_button.visible = not _offered.is_empty()
	_install_button.disabled = busy
	_version.text = "Jogo ainda não instalado" if _installed.is_empty() else "Instalado  %s" % _installed.version


func _check_release() -> void:
	if _job != Job.IDLE:
		return
	_offered.clear()
	_repo = _repository.text.strip_edges()
	if not Release.valid_repository(_repo):
		_status.text = "Use o formato OWNER/REPO, por exemplo conta/tech-repair-simulator."
		_sync_buttons()
		return
	if _fixture_base.is_empty():
		var config := ConfigFile.new()
		config.set_value("github", "repository", _repo)
		if config.save(SETTINGS) != OK:
			_fail("Não foi possível salvar o repositório para a próxima execução.")
			return
	_job = Job.CHECK
	_status.text = "Verificando a última versão publicada…"
	_sync_buttons()
	var url := "https://api.github.com/repos/%s/releases/latest" % _repo
	if not _fixture_base.is_empty():
		url = _fixture_base + "/latest"
	_request.download_file = ""
	_request.max_redirects = 0
	_request.body_size_limit = 1024 * 1024
	_request.timeout = 12.0
	var headers := PackedStringArray(["Accept: application/vnd.github+json", "User-Agent: TechRepairSimulatorLauncher"])
	if _request.request(url, headers) != OK:
		_fail("Não foi possível iniciar a consulta de versões.")


func _download() -> void:
	if _job != Job.IDLE or _offered.is_empty():
		return
	_stage = _store.begin_staging()
	if _stage.is_empty():
		_fail("Não foi possível criar a pasta de instalação. Verifique as permissões.")
		return
	_job = Job.DOWNLOAD
	_request.download_file = _stage.path_join("download.part")
	_request.max_redirects = 4
	_request.body_size_limit = _offered.bytes
	_request.timeout = 600.0
	_progress.value = 0
	_progress.show()
	_sync_buttons()
	if _request.request(_offered.url) != OK:
		_fail("Não foi possível iniciar o download.")


func _completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _job == Job.CHECK:
		_finish_check(result, code, body)
	elif _job == Job.DOWNLOAD:
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			_fail("Download interrompido ou inválido. Tente novamente.")
			return
		_job = Job.INSTALL
		_progress.value = 100
		_status.text = "Verificando o SHA-256 e instalando…"
		_worker = Thread.new()
		if _worker.start(_store.install.bind(_stage, _offered.duplicate())) != OK:
			_worker = null
			_fail("Não foi possível iniciar a instalação.")


func _finish_check(result: int, code: int, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("Sem conexão com o servidor de versões. Tente novamente.")
		return
	if code != 200:
		match code:
			404: _fail("Release estável indisponível. Confira o repositório e se a release é pública.")
			403, 429: _fail("GitHub recusou a consulta ou atingiu o limite. Tente mais tarde.")
			_: _fail("Falha ao consultar versões (HTTP %d)." % code)
		return
	var remote := Release.parse(JSON.parse_string(body.get_string_from_utf8()), _repo, _fixture_base)
	if remote.is_empty():
		_fail("A release não contém um pacote Windows x64 válido com SHA-256.")
		return
	_job = Job.IDLE
	if _installed.is_empty() or Release.is_newer(remote.version, _installed.version):
		_offered = remote
		_install_button.text = "Instalar" if _installed.is_empty() else "Atualizar"
		_status.text = "Versão %s disponível · %s" % [remote.version, String.humanize_size(remote.bytes)]
		_sync_buttons()
		return
	_sync_buttons()
	_launch_game()


func _process(_delta: float) -> void:
	if _job == Job.DOWNLOAD:
		var received := _request.get_downloaded_bytes()
		_progress.value = 100.0 * float(received) / int(_offered.bytes)
		_status.text = "Baixando %s · %s de %s" % [
			_offered.version, String.humanize_size(received), String.humanize_size(_offered.bytes)
		]
	elif _job == Job.INSTALL and _worker != null and not _worker.is_alive():
		var result: Dictionary = _worker.wait_to_finish()
		_worker = null
		_stage = ""
		if result.has("error"):
			_fail(result.error)
			return
		_installed = result
		_offered.clear()
		_job = Job.IDLE
		_progress.hide()
		_sync_buttons()
		_launch_game()


func _fail(message: String) -> void:
	if not _stage.is_empty():
		_store.discard_staging(_stage)
		_stage = ""
	_job = Job.IDLE
	_progress.hide()
	_status.text = message
	_install_button.text = "Tentar novamente"
	_sync_buttons()


func _launch_game() -> void:
	if _job != Job.IDLE or _installed.is_empty():
		return
	if not _fixture_base.is_empty():
		_status.text = "Teste local · o launcher abriria o jogo %s." % _installed.version
		return
	var pid_path: String = _store.root.path_join("running-game.pid")
	var processes: Array = []
	var tasklist := OS.get_environment("SystemRoot").path_join("System32/tasklist.exe")
	var exit_code := OS.execute(tasklist, ["/FI", "IMAGENAME eq " + Store.GAME_EXE, "/FO", "CSV", "/NH"], processes)
	var already_running := false
	if exit_code == 0 and not processes.is_empty():
		already_running = str(processes[0]).to_lower().contains('"' + Store.GAME_EXE.to_lower() + '",')
	elif FileAccess.file_exists(pid_path):
		var previous_pid := FileAccess.get_file_as_string(pid_path).strip_edges()
		already_running = previous_pid.is_valid_int() and int(previous_pid) > 0 and OS.is_process_running(int(previous_pid))
	if already_running:
		_status.text = "O jogo já está aberto. Feche-o para iniciar outra sessão."
		return
	var pid := OS.create_process(_installed.executable, PackedStringArray())
	if pid > 0:
		var record := FileAccess.open(pid_path, FileAccess.WRITE)
		if record != null:
			record.store_line(str(pid))
			record.close()
		get_tree().quit()
	else:
		_status.text = "Não foi possível abrir o executável instalado. Verifique a instalação."


func _exit_tree() -> void:
	if _worker != null and _worker.is_started():
		_worker.wait_to_finish()
	if _job == Job.DOWNLOAD and is_instance_valid(_request):
		_request.cancel_request()
	if not _stage.is_empty():
		_store.discard_staging(_stage)

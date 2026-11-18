extends RefCounted

const Release := preload("res://release_info.gd")
const GAME_EXE := "Tech Repair Simulator.exe"
const RECORD := "installation.cfg"
const MAX_GAME_BYTES := 256 * 1024 * 1024

var root: String


func _init(path: String) -> void:
	root = path


func installed() -> Dictionary:
	var directory := DirAccess.open(root)
	var best := {}
	if directory == null:
		return best
	for folder in directory.get_directories():
		if not folder.begins_with("v") or directory.is_link(folder):
			continue
		var tag := folder.get_slice("-", 0)
		if not Release.is_newer(tag, best.get("version", "")):
			continue
		var path := root.path_join(folder)
		var record := ConfigFile.new()
		if record.load(path.path_join(RECORD)) != OK or record.get_value("game", "version", "") != tag:
			continue
		var executable := path.path_join(GAME_EXE)
		var file := FileAccess.open(executable, FileAccess.READ)
		if file == null or file.get_length() != record.get_value("game", "bytes", 0):
			continue
		file.close()
		var digest: Variant = record.get_value("game", "sha256", "")
		if digest is String and not digest.is_empty() and FileAccess.get_sha256(executable) == digest:
			best = {"version": tag, "executable": executable}
	return best


func begin_staging() -> String:
	if DirAccess.make_dir_recursive_absolute(root) != OK:
		return ""
	var name := ".stage-%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path := root.path_join(name)
	return path if DirAccess.make_dir_absolute(path) == OK else ""


func clean_interrupted() -> void:
	var directory := DirAccess.open(root)
	if directory == null:
		return
	for name in directory.get_directories():
		if not name.begins_with(".stage-") or directory.is_link(name):
			continue
		var pid := name.get_slice("-", 1)
		if pid.is_valid_int() and int(pid) > 0 and not OS.is_process_running(int(pid)):
			discard_staging(root.path_join(name))


func discard_staging(path: String) -> void:
	if path.get_base_dir() != root or not path.get_file().begins_with(".stage-"):
		return
	for file in ["download.part", GAME_EXE, RECORD]:
		var entry := path.path_join(file)
		if FileAccess.file_exists(entry):
			DirAccess.remove_absolute(entry)
	DirAccess.remove_absolute(path)


func install(stage: String, release: Dictionary) -> Dictionary:
	var result := _install(stage, release)
	if result.has("error"):
		discard_staging(stage)
	return result


func _install(stage: String, release: Dictionary) -> Dictionary:
	var package := stage.path_join("download.part")
	var downloaded := FileAccess.open(package, FileAccess.READ)
	if downloaded == null or downloaded.get_length() != release.bytes:
		return {"error": "O download ficou incompleto. Tente novamente."}
	downloaded.close()
	if FileAccess.get_sha256(package) != release.hash:
		return {"error": "A verificação SHA-256 falhou. Baixe o pacote novamente."}
	var archive := ZIPReader.new()
	if archive.open(package) != OK:
		return {"error": "O arquivo baixado não é um ZIP válido."}
	if archive.get_files() != PackedStringArray([GAME_EXE]):
		archive.close()
		return {"error": "O ZIP precisa conter apenas o executável oficial na raiz."}
	var bytes := archive.read_file(GAME_EXE)
	archive.close()
	if not _is_windows_x64(bytes):
		return {"error": "O pacote não contém um executável Windows x64 válido."}
	var executable := stage.path_join(GAME_EXE)
	var output := FileAccess.open(executable, FileAccess.WRITE)
	if output == null:
		return {"error": "Não foi possível gravar o jogo. Verifique o espaço e as permissões."}
	output.store_buffer(bytes)
	output.flush()
	var write_error := output.get_error()
	output.close()
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	var written_hash := FileAccess.get_sha256(executable)
	if write_error != OK or written_hash.is_empty() or written_hash != hashing.finish().hex_encode():
		return {"error": "A gravação do jogo ficou incompleta. Verifique o espaço em disco."}
	var record := ConfigFile.new()
	record.set_value("game", "version", release.version)
	record.set_value("game", "sha256", written_hash)
	record.set_value("game", "bytes", bytes.size())
	if record.save(stage.path_join(RECORD)) != OK or DirAccess.remove_absolute(package) != OK:
		return {"error": "Não foi possível concluir a instalação."}
	# The older version remains runnable until the verified directory is renamed into place.
	var destination := root.path_join(release.version + "-" + stage.get_file().trim_prefix(".stage-"))
	if DirAccess.rename_absolute(stage, destination) != OK:
		return {"error": "Não foi possível ativar a versão baixada. Tente novamente."}
	return {"version": release.version, "executable": destination.path_join(GAME_EXE)}


func _is_windows_x64(bytes: PackedByteArray) -> bool:
	if bytes.size() < 1024 or bytes.size() > MAX_GAME_BYTES or bytes.decode_u16(0) != 0x5a4d:
		return false
	var pe := bytes.decode_u32(0x3c)
	return pe >= 64 and pe <= bytes.size() - 26 and bytes.decode_u32(pe) == 0x4550 and (
		bytes.decode_u16(pe + 4) == 0x8664 and bytes.decode_u16(pe + 24) == 0x20b
	)

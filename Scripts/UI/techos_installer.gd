extends PanelContainer
## Screen shown on the bench monitor after booting the prepared USB drive.

const Prefs := preload("res://Scripts/UI/player_preferences.gd")

var ledger: RefCounted
var pc_id := ""
var _disk_id := ""
var _confirming := false
var _title: Label
var _description: Label
var _disks: OptionButton
var _progress: ProgressBar
var _action: Button
var _cancel: Button


func _ready() -> void:
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color("0c1723")
	add_theme_stylebox_override("panel", backdrop)
	var center := CenterContainer.new()
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 330
	content.add_theme_constant_override("separation", 14)
	center.add_child(content)
	_title = Label.new()
	_title.text = "Instalador TechOS"
	_title.add_theme_font_size_override("font_size", 23)
	content.add_child(_title)
	_description = Label.new()
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size.x = 330
	content.add_child(_description)
	_disks = OptionButton.new()
	_disks.name = "InstallTarget"
	_disks.fit_to_longest_item = false
	_disks.clip_text = true
	_disks.custom_minimum_size.y = 40
	_disks.item_selected.connect(func(_index: int) -> void:
		_confirming = false
		update_screen(ledger, pc_id))
	content.add_child(_disks)
	_progress = ProgressBar.new()
	_progress.name = "InstallProgress"
	_progress.max_value = 1.0
	_progress.step = 0.0
	_progress.custom_minimum_size.y = 24
	content.add_child(_progress)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	_action = Button.new()
	_action.name = "InstallAction"
	_action.custom_minimum_size.y = 40
	_action.pressed.connect(_act)
	buttons.add_child(_action)
	_cancel = Button.new()
	_cancel.name = "CancelInstallConfirmation"
	_cancel.text = Prefs.t("Cancelar")
	_cancel.pressed.connect(cancel_confirmation)
	buttons.add_child(_cancel)
	hide()


func update_screen(model: RefCounted, computer_id: String) -> void:
	var pc: Dictionary = model.item(computer_id)
	var installation: Dictionary = pc.get("installation", {})
	var phase: String = installation.get("phase", "")
	var disk_id: String = installation.get("disk", "")
	if pc_id != computer_id or _disk_id != disk_id:
		_disk_id = disk_id
		_confirming = false
		_disks.clear()
		_disks.add_item(Prefs.t("Selecione o disco"))
		if not disk_id.is_empty():
			for disk in model.installation_targets(computer_id):
				var state := Prefs.t("Sistema instalado" if disk.get("bootable", false) else "Sem sistema")
				_disks.add_item("%s · %s" % [model.storage_description(disk), state])
				_disks.set_item_metadata(_disks.item_count - 1, disk.id)
		_disks.select(0)
	pc_id = computer_id
	ledger = model
	visible = not phase.is_empty()
	if phase.is_empty(): return
	_disks.visible = phase == "setup"
	_progress.visible = phase == "copying"
	_action.visible = phase != "copying"
	_cancel.visible = phase == "setup" and _confirming
	match phase:
		"setup":
			_update_setup()
		"copying":
			_title.text = Prefs.t("Instalando TechOS")
			_description.text = Prefs.t("Copiando o sistema para %s. Mantenha o computador ligado.") % ledger.storage_description(ledger.item(_disk_id))
			_progress.value = 1.0 - float(installation.remaining) / ledger.INSTALL_DURATION
		"complete":
			_title.text = Prefs.t("Instalação concluída")
			_description.text = Prefs.t("Retire o pendrive para iniciar pelo disco." if pc.get("install_usb", false) else "Pronto para iniciar o TechOS pelo disco.")
			_action.text = Prefs.t("Reiniciar pelo disco")
			_action.disabled = pc.get("install_usb", false)


func _update_setup() -> void:
	_title.text = Prefs.t("Instalador TechOS")
	_action.text = Prefs.t("Confirmar instalação" if _confirming else "Instalar TechOS")
	_action.disabled = _disks.selected < 1
	_disks.disabled = _confirming
	if not _confirming:
		_description.text = Prefs.t("Selecione o disco em que o TechOS será instalado.")
		return
	var disk: Dictionary = ledger.item(_disks.get_selected_metadata())
	var message := "Substituir o sistema e apagar os aplicativos em %s?" if disk.get("bootable", false) else "Instalar o TechOS em %s?"
	_description.text = Prefs.t(message) % ledger.storage_description(disk)


func _act() -> void:
	var phase: String = ledger.item(pc_id).get("installation", {}).get("phase", "")
	if phase == "complete":
		ledger.restart_after_install(pc_id)
	elif phase == "setup" and _disks.selected > 0:
		if _confirming:
			_confirming = false
			ledger.start_os_install(pc_id, _disks.get_selected_metadata(), true)
		else:
			_confirming = true
			update_screen(ledger, pc_id)


func cancel_confirmation() -> bool:
	if not visible or not _confirming: return false
	_confirming = false
	update_screen(ledger, pc_id)
	return true


func focus_target() -> void:
	if visible and _disks.visible: _disks.grab_focus()

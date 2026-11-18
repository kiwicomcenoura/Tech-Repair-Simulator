extends RefCounted

const Prefs := preload("res://Scripts/UI/player_preferences.gd")

const BUILT_IN := {"browser": "Browser", "explorer": "Explorer", "store": "Store"}
const OPTIONAL := {"notes": "Bloco de Notas", "colors": "Teste de Cores"}
const PAGES := {
	"inicio": "Página inicial\n\nEscolha uma página nos favoritos ou digite inicio, noticias ou ajuda.",
	"noticias": "Notícias locais\n\nA feira de tecnologia da cidade abre neste fim de semana.",
	"ajuda": "Central de ajuda\n\nUse o Explorer para ver arquivos e a Store para instalar aplicativos.",
}
const FILES := {
	"Documentos": {"Lembretes.txt": "Revisar os documentos da semana.\nSeparar os recibos da próxima viagem."},
	"Downloads": {"Leia-me.txt": "Arquivos baixados nesta máquina aparecem aqui."},
}

static func definition(id: String) -> Dictionary:
	return {"title": BUILT_IN.get(id, OPTIONAL.get(id, "")), "empty_title": "", "description": ""}


static func build(id: String, desktop: Control) -> Control:
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	match id:
		"browser": _browser(content)
		"explorer": _explorer(content)
		"store": _store(content, desktop)
		"notes":
			var editor := TextEdit.new()
			editor.placeholder_text = "Digite uma anotação para testar o teclado."
			editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
			content.add_child(editor)
		"colors":
			var screen := preload("res://Scripts/UI/bench_video_screen.gd").new()
			screen.status = "pattern"
			screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
			content.add_child(screen)
	return content


static func _browser(content: VBoxContainer) -> void:
	var address := LineEdit.new()
	address.name = "BrowserAddress"
	content.add_child(address)
	var links := HBoxContainer.new()
	content.add_child(links)
	var page := _text_panel(content)
	var navigate := func(url: String) -> void:
		var path := url.strip_edges().to_lower().trim_prefix("tech://")
		address.text = "tech://" + path
		page.text = PAGES.get(path, "Página indisponível. Abra um dos favoritos do Browser.")
	address.text_submitted.connect(navigate)
	for key in PAGES:
		var link := Button.new()
		link.text = {"inicio": "Início", "noticias": "Notícias", "ajuda": "Ajuda"}[key]
		link.pressed.connect(navigate.bind(key))
		links.add_child(link)
	navigate.call("inicio")


static func _explorer(content: VBoxContainer) -> void:
	var folders := HBoxContainer.new()
	content.add_child(folders)
	var files := ItemList.new()
	files.name = "ExplorerFiles"
	files.custom_minimum_size.y = 64
	content.add_child(files)
	var preview := _text_panel(content)
	files.item_selected.connect(func(index: int) -> void: preview.text = files.get_item_metadata(index))
	var open_folder := func(folder: String) -> void:
		files.clear()
		preview.text = Prefs.t("Selecione um arquivo em %s.") % Prefs.t(folder)
		for filename in FILES[folder]:
			files.add_item(filename)
			files.set_item_metadata(files.item_count - 1, FILES[folder][filename])
	for folder in FILES:
		var button := Button.new()
		button.text = folder
		button.pressed.connect(open_folder.bind(folder))
		folders.add_child(button)
	open_folder.call("Documentos")


static func _store(content: VBoxContainer, desktop: Control) -> void:
	for id in OPTIONAL:
		var row := HBoxContainer.new()
		content.add_child(row)
		var name := Label.new()
		name.text = OPTIONAL[id]
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		var action := Button.new()
		action.name = "Install_" + id
		var update := func() -> void: action.text = "Abrir" if id in desktop.installed_apps else "Instalar"
		update.call()
		action.pressed.connect(func() -> void:
			if id in desktop.installed_apps:
				desktop.open_app(id)
			else:
				desktop.install_client_app(id)
				update.call())
		row.add_child(action)


static func _text_panel(content: VBoxContainer) -> RichTextLabel:
	var panel := RichTextLabel.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(panel)
	return panel

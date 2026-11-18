extends SceneTree
func _initialize() -> void:
	var look := preload("res://Scripts/World/workshop_appearance.gd")
	look.bake_mode = true
	DirAccess.make_dir_recursive_absolute("res://Assets/Decoration")
	var baked := {}
	for style in look.STYLES:
		for flooring in [false,true]:
			var key: String = look.material_key(style, flooring)
			if baked.has(key): continue
			var result: Error = look.texture(style,flooring).get_image().save_png("res://Assets/Decoration/"+key+".png")
			if result != OK:
				push_error("Could not save decoration material: "+key)
				quit(1)
				return
			baked[key] = true
	print("Baked %d original seamless 512x512 decoration textures." % baked.size())
	quit()

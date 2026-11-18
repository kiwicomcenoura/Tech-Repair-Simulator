extends SceneTree
func _initialize() -> void:
	preload("res://Tools/ram_art_builder.gd").build()
	print("Generated RAM catalog, fitted and isometric PNGs from original DIMM geometry.")
	quit()

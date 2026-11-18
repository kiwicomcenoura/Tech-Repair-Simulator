extends SceneTree
## Deterministic fine materials for workshop surfaces; no external textures.
func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12490
	for kind in ["metal_grain","floor_grain"]:
		var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
		for y in range(128):
			var brushed := rng.randf_range(-0.012,0.012)
			for x in range(128):
				var value := rng.randf_range(0.955,0.995) + brushed
				if kind == "floor_grain": value = rng.randf_range(0.93,0.995)
				image.set_pixel(x,y,Color(value,value,value,1))
		var result := image.save_png("res://Assets/Workshop/"+kind+".png")
		if result != OK:
			quit(1)
			return
	print("Generated two original 128x128 workshop material textures.")
	quit()

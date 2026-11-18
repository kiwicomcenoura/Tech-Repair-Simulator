extends RefCounted
## Original DIMM illustration from geometry: face icon, fitted profile and world projection.
static func build() -> void:
	var face := Image.create(432,102,false,Image.FORMAT_RGBA8)
	face.fill_rect(Rect2i(3,2,426,98),Color("245d38"))
	face.fill_rect(Rect2i(6,4,420,80),Color("397d47"))
	face.fill_rect(Rect2i(7,4,418,2),Color("74a56a"))
	# Sparse signal traces and solder mask vias around eight memory packages.
	for i in range(8):
		var x := 23+i*49
		face.fill_rect(Rect2i(x-2,13,39,49),Color("244531"))
		face.fill_rect(Rect2i(x,14,35,45),Color("101718"))
		face.fill_rect(Rect2i(x+1,14,33,2),Color("3b4440"))
		face.fill_rect(Rect2i(x+2,17,31,39),Color("1c2423"))
		face.fill_rect(Rect2i(x+4,51,9,1),Color("424b43"))
		for j in range(4):
			var y := 65+j*3
			face.fill_rect(Rect2i(x+j*3,y,1,17-j*3),Color("699459"))
		for y in [8,68,76]:
			face.fill_rect(Rect2i(x+9,y,5,2),Color("b9b599"))
			face.fill_rect(Rect2i(x+10,y,3,2),Color("6c765e"))
		face.fill_rect(Rect2i(x+29,66,2,2),Color("bbbc96"))
	# Contact fingers extend along the entire LONG lower edge, with keyed notch.
	for x in range(12,420,4):
		face.fill_rect(Rect2i(x,84,3,15),Color("ba9546"))
		face.fill_rect(Rect2i(x,85,1,13),Color("e0bf69"))
		face.fill_rect(Rect2i(x,98,3,1),Color("806f37"))
	face.fill_rect(Rect2i(239,82,9,20),Color.TRANSPARENT)
	# Retention cutouts belong to the PCB ends, not to the contact edge.
	for x in [0,425]:
		face.fill_rect(Rect2i(x,29,7,10),Color.TRANSPARENT)
		face.fill_rect(Rect2i(x,67,7,8),Color.TRANSPARENT)
	face.save_png("res://Assets/Physical/ram_catalog.png")
	# Original graphite heat spreader viewed directly from above, at 6x scale.
	# The catalog/world retain their separate exposed-PCB illustrations.
	var fitted := Image.create(48,312,false,Image.FORMAT_RGBA8)
	fitted.fill(Color.TRANSPARENT)
	fitted.fill_rect(Rect2i(5,0,38,312),Color("10171e"))
	fitted.fill_rect(Rect2i(2,5,44,302),Color("202b35"))
	fitted.fill_rect(Rect2i(5,5,38,302),Color("34434f"))
	fitted.fill_rect(Rect2i(8,7,32,298),Color("25323d"))
	# Symmetrical bevels, a fine machined highlight and recessed center channel.
	fitted.fill_rect(Rect2i(5,9,2,294),Color("81929b"))
	fitted.fill_rect(Rect2i(40,9,3,294),Color("111b23"))
	fitted.fill_rect(Rect2i(20,12,8,288),Color("121e27"))
	fitted.fill_rect(Rect2i(21,13,2,286),Color("4c6471"))
	for i in range(12):
		var y := 14+i*24
		# Raised cooling ribs break into pairs along the central groove.
		for x in [8,29]:
			fitted.fill_rect(Rect2i(x,y,11,17),Color("131e27"))
			fitted.fill_rect(Rect2i(x,y,11,3),Color("677985"))
			fitted.fill_rect(Rect2i(x+1,y+3,9,9),Color("3d4e5c"))
			fitted.fill_rect(Rect2i(x+1,y+12,9,3),Color("293845"))
	# A restrained teal inlay and solid end caps, without copied branding.
	for y in [6,296]:
		fitted.fill_rect(Rect2i(9,y,30,10),Color("4b5d68"))
		fitted.fill_rect(Rect2i(12,y+3,24,2),Color("97a7aa"))
	fitted.fill_rect(Rect2i(17,132,14,48),Color("182630"))
	fitted.fill_rect(Rect2i(20,138,3,36),Color("68abb2"))
	fitted.fill_rect(Rect2i(26,142,2,28),Color("80939c"))
	fitted.save_png("res://Assets/Inspection/Layers/ram.png")
	var world := Image.create(192,240,false,Image.FORMAT_RGBA8)
	var origin := Vector2(3,61)
	var along := Vector2(54,-18)
	var across := Vector2(7,13)
	var basis := Transform2D(along,across,origin).affine_inverse()
	for y in range(240):
		for x in range(192):
			var uv := basis * Vector2(float(x)/3,float(y)/3)
			if uv.x >= 0 and uv.x < 1 and uv.y >= 0 and uv.y < 1:
				world.set_pixel(x,y,face.get_pixel(mini(431,int(uv.x*432)),mini(101,int(uv.y*102))))
	world.save_png("res://Assets/Physical/ram.png")

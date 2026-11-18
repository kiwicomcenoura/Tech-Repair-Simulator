extends SceneTree
## Original hardware illustration at 4x resolution; logical geometry remains 320x240.
const S := 4
const OUT := "res://Assets/Inspection/Layers/"
var img: Image

func box(x: float,y: float,w: float,h: float,c: String) -> void:
	img.fill_rect(Rect2i(roundi(x*S),roundi(y*S),maxi(1,roundi(w*S)),maxi(1,roundi(h*S))),Color(c))
func line(a: Vector2,b: Vector2,c: String,width: float = 0.4) -> void:
	var count := maxi(1,ceili(a.distance_to(b)*S))
	for i in range(count+1):
		var p := a.lerp(b,float(i)/count)
		box(p.x,p.y,width,width,c)
func circle(cx: float,cy: float,r: float,c: String) -> void:
	for y in range(floori((cy-r)*S),ceili((cy+r)*S)+1):
		for x in range(floori((cx-r)*S),ceili((cx+r)*S)+1):
			if Vector2(float(x)/S-cx,float(y)/S-cy).length() <= r and x>=0 and y>=0 and x<img.get_width() and y<img.get_height(): img.set_pixel(x,y,Color(c))
func start(w: int,h: int) -> void:
	img = Image.create(w*S,h*S,false,Image.FORMAT_RGBA8)
func save(kind: String) -> void:
	if img.save_png(OUT+kind+".png") != OK: push_error("Could not save "+kind); quit(1)
func metal(x: float,y: float,w: float,h: float) -> void:
	box(x,y,w,h,"263440")
	for j in range(roundi(h*S)):
		var shade := Color("526471").lerp(Color("25313b"),float(j)/maxf(1,h*S))
		img.fill_rect(Rect2i(roundi(x*S),roundi(y*S)+j,roundi(w*S),1),shade)
	box(x,y,w,0.5,"9aaab3")
	box(x,y,0.5,h,"7b909c")
func fan(cx: float,cy: float,r: float) -> void:
	circle(cx,cy,r,"82909a")
	circle(cx,cy,r-0.8,"121b23")
	for i in range(9):
		var angle := i*TAU/9.0
		for t in range(8):
			var a := angle+t*0.055
			line(Vector2(cx,cy)+Vector2.from_angle(a)*4,Vector2(cx,cy)+Vector2.from_angle(a+0.34)*(r-2),"3f515d",1.1)
	circle(cx,cy,4,"6d818d")
	circle(cx-0.5,cy-0.5,2.6,"293c49")
func capacitor(x: float,y: float,audio: bool = false) -> void:
	# Solid cylindrical package: shadow, sleeve, aluminium top and polarity mark.
	circle(x+0.7,y+1,2.9,"0b171c")
	box(x-2.2,y-1,4.4,3.5,"94794d" if audio else "354d58")
	circle(x,y-0.8,2.3,"d2cda8" if audio else "acb9bc")
	circle(x,y-1,1.6,"998c68" if audio else "728d97")
	line(Vector2(x-1.2,y-1),Vector2(x+1.2,y-1),"3e5058",0.3)
	box(x-1.8,y-2,0.5,2.6,"d4dde0")

func board_variants() -> void:
	# Preserve the chassis mounting points and the two interactive DIMM slots.
	img = Image.load_from_file(OUT + "motherboard.png")
	box(0, 8, 27, 51, "22262a")
	box(1, 9, 24, 13, "383d43")
	box(1, 22, 17, 35, "303338")
	line(Vector2(4, 23), Vector2(4, 49), "eb7c2f", 1.25)
	line(Vector2(4, 49), Vector2(15, 56), "eb7c2f", 1.25)
	for offset in [0, 4, 8]:
		line(Vector2(72 + offset, 75), Vector2(95 + offset, 52), "757c83", 0.65)
	box(44, 23, 35, 35, "222527")
	for y in range(25, 57, 2):
		for x in range(46, 78, 2):
			if x not in range(56, 66) or y not in range(35, 45):
				box(x, y, 0.55, 0.55, "798086")
	for y in [17, 59]:
		box(47, y, 28, 4, "131719")
		box(48, y, 25, 0.65, "60676a")
	save("motherboard_amdera")

	img = Image.load_from_file(OUT + "motherboard.png")
	for x in range(4, 22, 8):
		metal(x, 7, 6, 20)
		metal(x, 32, 6, 16)
	for y in [10, 20, 30, 40, 50, 60]:
		capacitor(27, y)
	metal(41, 20, 43, 40)
	box(47, 25, 31, 30, "22282d")
	metal(52, 29, 21, 23)
	box(55, 32, 15, 16, "303940")
	for y in range(33, 48, 2):
		for x in range(56, 70, 2): box(x, y, 0.75, 0.5, "a99b75")
	line(Vector2(83, 24), Vector2(87, 52), "b2bec6", 1.1)
	line(Vector2(87, 52), Vector2(82, 61), "b2bec6", 1.1)
	metal(31, 82, 25, 15)
	for x in range(33, 55, 3): box(x, 84, 0.8, 11, "273540")
	save("motherboard_intara")

func amdera_cpu() -> void:
	start(27,27)
	box(0.5,0.5,26,26,"153839")
	box(1,1,25,25,"1d5757")
	for x in range(3,25,2):
		for y in [2,3,24,25]:
			box(x,y,0.8,0.48,"b39c59")
	for y in [7,8,18,19]:
		for x in [1,2,24,25]:
			box(x,y,0.6,0.55,"c4a968")
	# Recesses around the heat spreader expose the substrate and contact pads.
	metal(3,4,21,19)
	metal(4,2,4,23)
	metal(19,2,4,23)
	metal(2,10,23,7)
	for x in [4, 19]:
		box(x+0.5,2.5,3.25,4,"aebbc1")
		box(x+0.5,20.5,3.25,4,"9aaab3")
	box(2.5,10.5,22,5.75,"9cabb4")
	box(2.5,10.5,22,0.5,"d9e4e9")
	box(5,5,17,17,"b5c2c8")
	box(5,5,17,0.5,"e4ecef")
	for y in range(6,22,2): box(5,y,17,0.25,"a7b5bb")
	box(7,8,12,1.25,"43535e")
	box(7,10,9,0.8,"51626c")
	for y in [14,16,18]:
		box(7,y,8,0.4,"667984")
		box(17,y,3,0.4,"738792")
	box(2,24,0.8,0.8,"e1b964")
	save("cpu_amdera")

func _initialize() -> void:
	if "--amdera-cpu" in OS.get_cmdline_user_args():
		amdera_cpu()
		quit()
		return
	if "--board-variants" in OS.get_cmdline_user_args():
		board_variants()
		quit()
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	start(320,240)
	box(21,17,270,190,"060b11")
	metal(23,18,237,185)
	box(29,24,225,172,"141e27")
	for y in range(26,194,2): box(30,y,222,0.33,"19242d")
	metal(25,24,14,171)
	box(29,43,6,54,"0d151d")
	for y in range(100,157,9):
		box(28,y,9,7,"0a1117")
		for yy in range(y+1,y+6,2): box(29,yy,7,0.5,"4c606d")
	box(27,160,12,35,"1c2833")
	box(30,172,5,10,"090e15")
	metal(251,23,5,173)
	metal(260,20,27,183)
	for y in range(54,183,3): box(266,y,15,0.7,"101922")
	box(268,30,8,8,"111c27")
	circle(272,34,2.4,"55bdd4")
	for x in [266,274]: box(x,44,5,2,"090e15")
	metal(24,197,233,4)
	for x in [34,237]: box(x,204,17,5,"101922")
	for y in [42,151]:
		for x in [46,183]: circle(x,y,1.8,"8c7959")
	box(209,40,33,45,"1e2b35")
	for y in range(45,81,4): box(212,y,27,0.7,"3a4b57")
	box(209,100,34,48,"24323c")
	box(65,221,155,15,"2a3c49")
	box(67,223,151,11,"0c151e")
	save("chassis")
	start(145,115)
	box(0,0,145,115,"334d48")
	box(1,1,143,113,"172d2b")
	for i in range(35):
		var x := 8+(i*17)%129
		var y := 7+(i*13)%101
		line(Vector2(x,y),Vector2(x+4,y+4),"3c5a4a",0.33)
		line(Vector2(x+4,y+4),Vector2(mini(140,x+4),mini(109,y+15)),"3c5a4a",0.33)
		circle(x,y,0.5,"9d9772")
	for x in range(8,38,8):
		metal(x,11,5,21)
		for j in range(1,5): box(x+j,12,0.33,19,"263641")
	# CPU VRM: output capacitors beside the socket, away from DIMM/PCIe sockets.
	for y in [40,49,58,67]: capacitor(31,y)
	for x in [47,58,69,80]: capacitor(x,8)
	for x in [42,53,64,75]:
		box(x,2,5,2.5,"263b43")
		box(x+0.5,2,4,0.4,"8c9b9e")
	metal(36,14,52,55)
	box(40,18,44,47,"3b474d")
	box(44,23,35,35,"101c22")
	# DIMM rails share the runtime center lines: board x + 42 = 149 / 169.
	# Narrow sockets, end retainers and clear PCB space around each channel.
	for center_x in [107,127]:
		box(center_x-6,8,12,56,"0b171c")
		box(center_x-5,9,10,54,"36444a")
		box(center_x-3,10,6,52,"121c23")
		box(center_x-5,10,0.75,52,"70818a")
		box(center_x+4.25,10,0.75,52,"1c2a32")
		for y in range(12,61,2):
			box(center_x-2,y,0.5,0.5,"b59a59")
			box(center_x+1.5,y,0.5,0.5,"8b794a")
		box(center_x-2,40,4,2,"65716b")
		for y in [5,63]:
			box(center_x-5,y,10,4,"27343c")
			box(center_x-4,y+0.5,8,2.5,"9bafb3")
	box(7,79,133,5,"111b25")
	box(9,80,123,0.7,"aaa38b")
	for x in range(11,131,2): box(x,81,0.5,1.8,"887346")
	box(18,99,79,4,"b2b8b3")
	box(109,101,21,9,"293c46")
	for x in range(110,130,2): box(x,103,0.5,5,"5d7784")
	box(131,31,11,28,"121b22")
	for x in range(133,141,2):
		for y in range(33,57,3): box(x,y,0.6,1,"a4ac94")
	circle(22,63,6,"7c8b8f")
	circle(22,63,4.8,"b0bbb9")
	box(16,62,12,1,"738588")
	for p in [Vector2(42,76),Vector2(66,94),Vector2(111,73)]:
		box(p.x,p.y,9,7,"111b23")
		for x in range(9): box(p.x+x,p.y-1,0.4,9,"889c99")
	# Memory power filtering sits beside DIMM; audio cluster follows the lower-left edge.
	for y in [18,27]: capacitor(140,y)
	for y in [89,98,107]: capacitor(10,y,true)
	for y in [89,98]: capacitor(18,y,true)
	# Small surface-mount resistors near the VRM and memory regulator.
	for p in [Vector2(22,38),Vector2(22,47),Vector2(22,56),Vector2(138,36),Vector2(138,42)]:
		box(p.x,p.y,2.5,1,"b0b4a0")
		box(p.x+0.6,p.y,1.3,1,"665f4e")
	save("motherboard")
	start(49,51)
	metal(1,1,47,49)
	for x in range(3,47,2): box(x,2,0.7,47,"16242f")
	box(3,3,43,44,"24313b")
	fan(24.5,25.5,20)
	for y in [3,47]:
		for x in [4,45]: circle(x,y,1.8,"9ca9ad")
	save("cooling")
	start(27,27)
	box(0,0,27,27,"2d4a42")
	metal(2,2,23,23)
	box(4,4,19,19,"aab6ba")
	for y in range(6,20,2): box(6,y,15,0.33,"b7c2c5")
	box(6,9,11,1,"5d737f")
	box(6,12,14,0.5,"5d737f")
	box(6,15,8,0.5,"5d737f")
	box(2,22,2,2,"cfb56c")
	save("cpu")
	# Side-on GPU: upper PCB edge, heatsink fins below; fans face DOWN, not towards viewer.
	start(156,30)
	metal(0,0,7,30)
	box(7,4,149,24,"0c141d")
	box(9,3,143,3,"2f453a")
	for x in range(12,149,3): box(x,4,1,1,"b8b083")
	metal(9,7,143,4)
	box(11,11,140,13,"47535c")
	for x in range(12,150,2):
		box(x,11,0.5,13,"91a0a6")
		box(x+0.7,11,0.5,13,"1d2b35")
	box(9,24,144,4,"151f2a")
	box(14,24,131,0.7,"5f7481")
	box(49,25,47,2,"273e50")
	box(53,25.5,37,0.4,"91b2c3")
	for x in [27,109]:
		line(Vector2(x,12),Vector2(x+14,22),"b79767",1.2)
	box(129,0,16,7,"0d161e")
	for x in range(131,144,3): box(x,1,1,3,"b7a174")
	box(1,6,4,8,"09131b")
	box(1,19,4,7,"09131b")
	save("gpu")
	start(99,34)
	metal(0,0,99,34)
	box(3,3,93,28,"17232c")
	for y in range(5,29,2):
		for x in range(6,47,3): box(x,y,1.4,0.6,"465965")
	box(54,7,36,18,"c2c7c4")
	box(57,10,28,2,"395365")
	for y in range(15,21,2): box(58,y,25,0.5,"72838a")
	for x in range(57,84,2): box(x,23,0.5,2,"344c5b")
	save("psu")
	start(29,40)
	metal(0,0,29,40)
	box(3,4,23,30,"b3b9b5")
	box(4,7,21,8,"234459")
	box(6,10,16,1,"a4c9d2")
	for y in range(19,28,2): box(6,y,16,0.5,"6c7e87")
	for x in range(6,23,2): box(x,30,0.6,3,"3c505b")
	box(6,37,18,3,"101c24")
	save("storage")
	preload("res://Tools/ram_art_builder.gd").build()
	start(320,240)
	metal(28,24,224,172)
	box(31,27,218,166,"2b3c49")
	for y in range(30,190,2): box(33,y,214,0.33,"30424e")
	for y in range(58,159,3):
		for x in range(70,192,4): box(x,y,2,1,"111e27")
	box(226,98,10,27,"162733")
	box(228,100,1,23,"7b8d98")
	save("lid")
	print("Generated 9 detailed original hardware layers; chassis 1280x960, RAM retains its fitted dimensions.")
	quit()



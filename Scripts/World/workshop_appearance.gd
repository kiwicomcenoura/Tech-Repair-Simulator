extends RefCounted
## Pure visual appearance; save records contain only stable style names and colors.
const TARGETS := {"walls":"Paredes", "floor":"Chão", "repair":"Bancada de manutenção", "desk":"Mesa do computador", "counter":"Balcão de atendimento", "cabinet":"Armário"}
const STYLES := {
	"original": ["Original", "687c8c"],
	"modern": ["Moderno", "b5b8b4"],
	"oak": ["Madeira clara", "bfa580"],
	"walnut": ["Madeira escura", "7e6550"],
	"rustic": ["Rústico", "a38b70"],
	"concrete": ["Concreto", "9ca4aa"],
	"marble": ["Mármore", "c6c8c3"],
	"industrial": ["Industrial", "657e90"]
}
static var _textures: Dictionary = {}
static var bake_mode := false

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	for target in data:
		if not TARGETS.has(target) or not data[target] is Dictionary: return false
		var entry: Dictionary = data[target]
		if entry.get("style") not in STYLES or not entry.get("tint") is String: return false
		if entry.tint.length() != 6 or not Color.html_is_valid(entry.tint): return false
	return true

static var _maps: Array[Image] = []

# These styles differ by tint or only need a distinct texture on wood/tile flooring.
static func material_key(style: String, flooring: bool) -> String:
	if style == "walnut": style = "oak"
	if style == "modern" and not flooring: style = "original"
	return style + ("_floor" if flooring and style in ["oak", "rustic", "modern", "marble"] else "")


static func texture(style: String, flooring: bool = false) -> Texture2D:
	var key := material_key(style, flooring)
	if _textures.has(key): return _textures[key]
	var asset_path := "res://Assets/Decoration/"+key+".png"
	if not bake_mode and ResourceLoader.exists(asset_path):
		_textures[key] = load(asset_path)
		return _textures[key]
	# Generate the same image for a shared asset regardless of the requested variant.
	flooring = key.ends_with("_floor")
	style = key.trim_suffix("_floor")
	if _maps.is_empty():
		for i in range(3):
			var noise := FastNoiseLite.new()
			noise.seed = 9317+i*1741
			noise.frequency = [0.018,0.17,0.045][i]
			noise.fractal_octaves = 3
			var map: Image = noise.get_seamless_image(64 if i == 2 else 512,512)
			map.resize(512,512,Image.INTERPOLATE_BILINEAR)
			_maps.append(map)
	var img := Image.create(512,512,false,Image.FORMAT_RGBA8)
	for y in range(512):
		for x in range(512):
			var cloud: float = _maps[0].get_pixel(x,y).r-0.5
			var fine: float = _maps[1].get_pixel(x,y).r-0.5
			var grain: float = _maps[2].get_pixel(x,y).r-0.5
			var v := 0.98+fine*0.018
			if style in ["oak","walnut","rustic"]:
				v = 0.95+grain*0.15+fine*0.012+cloud*0.025
				if style == "rustic": v += cloud*0.065
				if flooring:
					var row := int(y/64)
					v += float((row*17+int((x+(row%2)*128)/256)*7)%5-2)*0.007
					if y%64 == 0: v -= 0.085
					if (x+(row%2)*128)%256 == 0: v -= 0.06
			elif style == "concrete": v = 0.96+cloud*0.10+fine*0.035
			elif style == "marble":
				var vein := exp(-pow((cloud-0.025)/0.009,2.0))
				v = 0.98+cloud*0.035-vein*0.12+fine*0.008
			elif style == "industrial": v = 0.95+grain*0.055+fine*0.018
			if flooring and style in ["modern","marble"]:
				if x%256 == 0 or y%256 == 0: v -= 0.07
			v = clampf(v,0.65,1.0)
			img.set_pixel(x,y,Color(v,v,v,1))
	_textures[key] = ImageTexture.create_from_image(img)
	return _textures[key]

static func surfaces(world: Node, target: String) -> Array[Polygon2D]:
	var result: Array[Polygon2D] = []
	if target in ["walls","floor"]:
		for child in world.get_node("WorkshopRoom").get_children():
			if child is Polygon2D and ((target == "walls" and child.name in [&"Surface296",&"Surface297"]) or (target == "floor" and child.z_index in [-10,-9])):
				result.append(child)
	else:
		var paths := {"repair":"RepairBench", "desk":"WorkComputer", "counter":"ServiceCounter", "cabinet":"Shelf"}
		var first_surface := {"repair":1,"desk":20,"counter":42,"cabinet":0}
		var prop := world.get_node("Actors/"+paths[target])
		for child in prop.get_children():
			if child is Polygon2D and String(child.name).begins_with("Surface"):
				var number := int(String(child.name).trim_prefix("Surface"))
				if (number >= first_surface[target] and number < first_surface[target]+6) or target == "cabinet": result.append(child)
		var details := prop.get_node_or_null("Details")
		if details != null:
			for child in details.get_children():
				if child is Polygon2D and (String(child.name).begins_with("InsetPanel") or String(child.name).begins_with("PanelRim")): result.append(child)
	return result

static func apply(world: Node, choices: Dictionary) -> void:
	for target in TARGETS:
		var entry: Dictionary = choices.get(target,{"style":"original","tint":"ffffff"})
		for polygon in surfaces(world,target):
			if not polygon.has_meta("original_appearance"):
				polygon.set_meta("original_appearance",[polygon.color,polygon.texture,polygon.texture_repeat,polygon.texture_scale,polygon.uv,polygon.visible])
			var original: Array = polygon.get_meta("original_appearance")
			if entry.style == "original":
				polygon.color = original[0]
				polygon.texture = original[1]
				polygon.texture_repeat = original[2]
				polygon.texture_scale = original[3]
				polygon.uv = original[4] if original.size() > 4 else PackedVector2Array()
				polygon.visible = original[5] if original.size() > 5 else true
				continue
			# A continuous finish replaces the old checkerboard overlay.
			polygon.visible = not (target == "floor" and polygon.z_index == -9)
			var base: Color = original[0]
			var light := maxf(base.r,maxf(base.g,base.b))
			var shade := clampf(0.45+light*0.75,0.48,0.98)
			if target == "floor": shade = 0.92
			polygon.color = Color(entry.tint)*Color(shade,shade,shade,1)
			polygon.texture = texture(entry.style,target == "floor")
			polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			polygon.texture_scale = Vector2.ONE
			var uv := PackedVector2Array()
			var vertical_face: bool = target == "walls"
			var slope := 0.5
			for i in range(polygon.polygon.size()):
				var edge: Vector2 = polygon.polygon[(i+1)%polygon.polygon.size()]-polygon.polygon[i]
				if absf(edge.x) < 0.01: vertical_face = true
				elif absf(edge.x) > 20: slope = edge.y/edge.x
			for point in polygon.polygon:
				var plane := Vector2(point.x*0.5+point.y,point.y-point.x*0.5)
				if vertical_face: plane = Vector2(point.x,point.y-slope*point.x)
				uv.append(plane*2.0)
			polygon.uv = uv


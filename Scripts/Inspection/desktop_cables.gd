extends Node3D
## Routes in chassis space. All strands in a harness share a single indexed mesh.

const ROUTES: Array[Dictionary] = [
	{
		"source": "psu", "target": "motherboard", "port": 0, "wires": 8, "radius": 0.010,
		"path": [Vector3(0.15, -0.68, 0.05), Vector3(0.57, -0.62, -0.12),
			Vector3(0.62, -0.36, -0.25), Vector3(0.56, 0.29, -0.21), Vector3(0.49, 0.54, -0.19)],
	},
	{
		"source": "psu", "target": "motherboard", "port": 1, "wires": 5, "radius": 0.008,
		"path": [Vector3(0.13, -0.70, -0.26), Vector3(0.46, -0.68, -0.35),
			Vector3(0.66, -0.47, -0.39), Vector3(0.68, 0.82, -0.39),
			Vector3(0.53, 0.925, -0.38), Vector3(-0.68, 0.936, -0.34)],
	},
	{
		"source": "psu", "target": "gpu", "port": 0, "wires": 6, "radius": 0.007,
		"path": [Vector3(0.17, -0.561, 0.243), Vector3(0.37, -0.515, 0.221),
			Vector3(0.486, -0.395, 0.173), Vector3(0.491, -0.272, 0.15)],
	},
	{
		"source": "psu", "target": "storage", "port": 1, "wires": 4, "radius": 0.009,
		"path": [Vector3(0.17, -0.84, 0.15), Vector3(0.69, -0.79, 0.04),
			Vector3(0.94, -0.65, -0.16)],
	},
	{
		"source": "motherboard", "target": "storage", "port": 0, "wires": 1, "radius": 0.017, "color": Color("9b5844"),
		"path": [Vector3(0.48, 0.015, -0.26), Vector3(0.50, -0.44, -0.29),
			Vector3(0.63, -0.61, -0.26)],
	},
	{
		"source": "", "target": "motherboard", "port": 2, "wires": 3, "radius": 0.006,
		"path": [Vector3(0.91, 0.63, -0.34), Vector3(0.88, -0.52, -0.408),
			Vector3(0.69, -0.68, -0.395), Vector3(0.49, -0.48, -0.385),
			Vector3(0.39, -0.205, -0.25)],
	},
	{
		"source": "", "target": "cooling", "port": 0, "board_header": true, "wires": 3, "radius": 0.0035,
		"path": [Vector3(-0.222, 0.656, -0.004), Vector3(-0.184, 0.669, -0.092),
			Vector3(-0.184, 0.69, -0.182)],
	},
]

const STRAND_COLORS: Array[Color] = [Color("625b5d"), Color("49494f"), Color("795e51"), Color("565357")]
const SIDES := 8
const STEPS := 6

var _bundles: Array[Array] = []


func build(chassis: Node3D, sources: Dictionary, targets: Dictionary) -> void:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.69
	for route in ROUTES:
		var key := "%s:%d" % [route.target, route.port]
		var source: Dictionary = sources[key]
		var target: Dictionary = targets[key]
		var variants: Array[MeshInstance3D] = []
		var source_states := 2 if route.source == "psu" else 1
		for source_index in source_states:
			for plug_index in 2:
				var start := _exit_transform(chassis, source, source_index == 1)
				var end := _exit_transform(chassis, target, plug_index == 1)
				var lead_in := 0.026 if route.target == "cooling" else 0.055
				var path := PackedVector3Array([start.origin, start.origin + start.basis.z * lead_in])
				path.append_array(PackedVector3Array(route.path))
				path.append(end.origin + end.basis.z * 0.050)
				path.append(end.origin)
				var cable := MeshInstance3D.new()
				cable.mesh = _bundle_mesh(path, route)
				cable.material_override = material
				cable.visible = false
				cable.set_meta(&"wire_start", start.origin)
				cable.set_meta(&"wire_end", end.origin)
				add_child(cable)
				variants.append(cable)
		_bundles.append(variants)


func sync(components: Dictionary, mounts: Dictionary, gpu_auxiliary: bool = true) -> void:
	for index in ROUTES.size():
		var route := ROUTES[index]
		var available: bool = components.has(route.target) and (route.source == "" or components.has(route.source))
		if route.target == "gpu" and route.port == 0 and not gpu_auxiliary: available = false
		if route.get("board_header", false):
			available = available and components.has("motherboard")
		var variant := 0
		if available:
			var connections: Array = mounts[route.target]
			variant = 0 if connections[route.port] else 1
			if route.source == "psu" and not mounts.psu[0]:
				variant += 2
		for i in _bundles[index].size():
			_bundles[index][i].visible = available and i == variant


func _exit_transform(chassis: Node3D, endpoint: Dictionary, loose: bool) -> Transform3D:
	var exit: Marker3D = endpoint.wire_exit
	var transform := chassis.global_transform.affine_inverse() * exit.global_transform
	if loose:
		transform.origin += transform.basis * endpoint.offset
	return transform


func _bundle_mesh(path: PackedVector3Array, route: Dictionary) -> ArrayMesh:
	var centers := PackedVector3Array()
	for i in path.size() - 1:
		var before := path[maxi(0, i - 1)]
		var after := path[mini(i + 2, path.size() - 1)]
		for j in STEPS:
			centers.append(path[i].cubic_interpolate(path[i + 1], before, after, float(j) / STEPS))
	centers.append(path[-1])

	var widths := PackedVector3Array()
	var heights := PackedVector3Array()
	var last_width := Vector3.BACK
	for i in centers.size():
		var tangent := (centers[mini(i + 1, centers.size() - 1)] - centers[maxi(i - 1, 0)]).normalized()
		var width := last_width - tangent * tangent.dot(last_width)
		if width.length_squared() < 0.01:
			width = tangent.cross(Vector3.UP)
		last_width = width.normalized()
		widths.append(last_width)
		heights.append(tangent.cross(last_width).normalized())

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var wires: int = route.wires
	var radius: float = route.radius
	for wire in wires:
		var finish: Color = route.get("color", STRAND_COLORS[wire % STRAND_COLORS.size()])
		var color := finish.srgb_to_linear()
		var start := vertices.size()
		for i in centers.size():
			var width_dir := widths[i]
			var height_dir := heights[i]
			var end_distance := mini(i, centers.size() - 1 - i)
			var taper := lerpf(0.34, 1.0, smoothstep(0.0, 8.0, float(end_distance)))
			var spread := (float(wire) - float(wires - 1) * 0.5) * radius * 1.66 * taper
			var center := centers[i] + width_dir * spread
			var sheath := color.darkened(0.14) if i % 2 == 0 else color
			for j in SIDES:
				var theta := TAU * float(j) / SIDES
				var normal := width_dir * cos(theta) + height_dir * sin(theta)
				vertices.append(center + normal * radius)
				normals.append(normal)
				colors.append(sheath)
				if i < centers.size() - 1:
					var a := start + i * SIDES + j
					var b := start + i * SIDES + (j + 1) % SIDES
					indices.append_array(PackedInt32Array([a, a + SIDES, b + SIDES, a, b + SIDES, b]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

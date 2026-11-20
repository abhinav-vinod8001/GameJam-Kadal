class_name Craft
extends RefCounted

static var cache: Dictionary = {}
static var geometry: Dictionary = {}

static func mat(color: String, metal: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var key = color + str(metal) + str(glow)
	if cache.has(key): return cache[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.83 if metal == 0 else 0.3
	m.metallic = metal
	if metal == 0.0: m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = glow
	cache[key] = m
	return m

static func mesh(parent: Node3D, resource: Mesh, p: Vector3, material: Material) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = resource
	n.material_override = material
	n.position = p
	parent.add_child(n)
	return n

static func box(parent: Node3D, p: Vector3, size: Vector3, material: Material, solid: bool = false) -> MeshInstance3D:
	if not geometry.has("box"):
		var unit = BoxMesh.new()
		unit.size = Vector3.ONE
		geometry["box"] = unit
	var n = mesh(parent, geometry["box"], p, material)
	n.scale = size
	if solid: collision(parent, p, size)
	return n

static func cylinder(parent: Node3D, p: Vector3, radius: float, height: float, material: Material, top: float = -1.0) -> MeshInstance3D:
	var ratio = 1.0 if top < 0 else top/maxf(radius,.001)
	var key = "cylinder_"+str(snappedf(ratio,.001))
	if not geometry.has(key):
		var unit = CylinderMesh.new()
		unit.bottom_radius = 1
		unit.top_radius = ratio
		unit.height = 1
		unit.radial_segments = 10
		geometry[key] = unit
	var n = mesh(parent,geometry[key],p,material)
	n.scale = Vector3(radius,height,radius)
	return n

static func sphere(parent: Node3D, p: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	if not geometry.has("sphere"):
		var unit = SphereMesh.new()
		unit.radial_segments = 10
		unit.rings = 5
		geometry["sphere"] = unit
	var n = mesh(parent,geometry["sphere"],p,material)
	n.scale = size
	return n

static func collision(parent: Node3D, p: Vector3, size: Vector3):
	var body = StaticBody3D.new()
	body.position = p
	var c = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	c.shape = shape
	body.add_child(c)
	parent.add_child(body)
	return body

static func beam(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material):
	var n = cylinder(parent, (a+b)/2.0, radius, a.distance_to(b), material)
	var dir = (b-a).normalized()
	n.quaternion = Quaternion(Vector3.UP, dir)
	return n

static func surface(parent: Node3D, vertices: PackedVector3Array, material: Material, colors: PackedColorArray = PackedColorArray()) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in vertices.size():
		if colors.size() > 0: st.set_color(colors[i])
		st.add_vertex(vertices[i])
	st.generate_normals()
	return mesh(parent, st.commit(), Vector3.ZERO, material)

static func label(parent: Node3D, text_value: String, p: Vector3, size: int = 28) -> Label3D:
	var l = Label3D.new()
	l.add_to_group("reflection_hidden")
	l.layers = 1 << 19
	l.text = text_value
	l.font_size = size
	l.pixel_size = 0.009
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color("f1dfb4")
	l.outline_modulate = Color("142e30")
	l.outline_size = 8
	l.no_depth_test = false
	parent.add_child(l)
	return l

static func painted(color: Color, frequency: float, grain: float, vertex_color: bool = false, axis: Vector3 = Vector3.ONE) -> ShaderMaterial:
	var key = str([color, frequency, grain, vertex_color, axis])
	if not cache.has(key):
		var material = ShaderMaterial.new()
		material.shader = preload("res://shaders/painted_surface.gdshader")
		material.set_shader_parameter("pigment", color)
		material.set_shader_parameter("frequency", frequency)
		material.set_shader_parameter("grain", grain)
		material.set_shader_parameter("use_vertex_color", vertex_color)
		material.set_shader_parameter("grain_axis", axis)
		cache[key] = material
	return cache[key]

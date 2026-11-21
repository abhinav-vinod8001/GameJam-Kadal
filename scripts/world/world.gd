class_name Malanadu
extends Node3D

var rng = RandomNumberGenerator.new()
var water_material: ShaderMaterial
var water_reflection: Node
var landmarks: Array = []
var enemies: Array = []
var boat
var encounters: SoldierEncounters
var grass: MultiMeshInstance3D
var path_segments: Array = []
var building_footprints: Array[Vector4] = []
var population: SettlementLife
var wildlife: WildlifeLife
var hill_temple: HillTemple

static func river_x(z: float) -> float:
	return 30.0 + sin(z*.025)*9.0

static func height_at(x: float, z: float) -> float:
	var h = 1.45 + sin(x*.055)*.25 + cos(z*.07)*.22
	h += 14.0*exp(-((x+77)*(x+77)+(z+77)*(z+77))/1100.0)
	h += 5.5*exp(-((x-104)*(x-104)+(z+90)*(z+90))/550.0)
	var channel = absf(x-river_x(z))
	h = lerpf(-2.8,h,smoothstep(9.0,16.0,channel))
	h -= smoothstep(72.0,98.0,z)*5.0
	h -= smoothstep(117.0,139.0,absf(x))*12.0
	h -= smoothstep(116.0,138.0,-z)*12.0
	return h

func ground(x: float, z: float, extra: float = 0.0) -> Vector3:
	return Vector3(x,height_at(x,z)+extra,z)

func _ready():
	rng.seed = 1870
	terrain()
	water()
	paths()
	settlement()
	hill_temple = HillTemple.new()
	add_child(hill_temple)
	coastal_details()
	plant_world()
	backwaters()
	flower_banks()
	forest_and_ruins()
	mountains()
	populate()
	population = SettlementLife.new()
	add_child(population)
	batch_scenery()
	wildlife = WildlifeLife.new()
	add_child(wildlife)
	var life = load("res://scripts/world/ambience.gd").new()
	add_child(life)
	water_reflection = load("res://scripts/world/water_reflection.gd").new()
	water_reflection.surface = water_material
	add_child(water_reflection)

func terrain():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var size_value = 142
	for iz in size_value:
		for ix in size_value:
			var x = float(ix*2-142)
			var z = float(iz*2-142)
			var points = [ground(x,z),ground(x,z+2),ground(x+2,z),ground(x+2,z),ground(x,z+2),ground(x+2,z+2)]
			for p in [points[0],points[2],points[1],points[3],points[5],points[4]]:
				var hue = .5+.5*sin(p.x*.29+sin(p.z*.21)*2.0)*cos(p.z*.26)
				var color = Color("447844").lerp(Color("799548"),hue*.76)
				color = color.lerp(Color("cab787"), 1.0-smoothstep(.48,1.2,p.y))
				if p.x > 44 and p.z < -20:
					color = Color("437e56").lerp(Color("557f45"),hue)
				elif p.y > 5:
					color = color.lerp(Color("7e995b"), .65)
				st.set_color(color)
				var dx = height_at(p.x+.12,p.z)-height_at(p.x-.12,p.z)
				var dz = height_at(p.x,p.z+.12)-height_at(p.x,p.z-.12)
				st.set_normal(Vector3(-dx,.24,-dz).normalized())
				st.add_vertex(p)
	var mat = Craft.painted(Color.WHITE, .68, .16, true)
	var n = Craft.mesh(self,st.commit(),Vector3.ZERO,mat)
	n.name = "Terrain"
	n.layers = 1 << 18
	n.create_trimesh_collision()
	# The island remains solid from below at riverbanks and after a respawn.
	for child in n.get_children():
		if child is StaticBody3D:
			for collider in child.get_children():
				if collider is CollisionShape3D and collider.shape is ConcavePolygonShape3D:
					collider.shape.backface_collision = true

func water():
	var plane = PlaneMesh.new()
	plane.size = Vector2(1400,1400)
	plane.subdivide_width = 80
	plane.subdivide_depth = 80
	water_material = ShaderMaterial.new()
	water_material.shader = load("res://shaders/water.gdshader")
	var n = Craft.mesh(self,plane,Vector3(0,.18,0),water_material)
	n.name = "Water"
	n.layers = 1 << 19
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func path(points: Array, width: float = 2.3, color: String = "b5ab7b"):
	var curve = Curve2D.new()
	curve.bake_interval = .6
	for i in points.size():
		var p: Vector2 = points[i]
		var tangent = (points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)])*.14
		curve.add_point(p,-tangent,tangent)
		if i>0: path_segments.append([points[i-1],p,width])
	var route = curve.get_baked_points()
	var left = PackedVector3Array()
	var right = PackedVector3Array()
	for i in route.size():
		var tangent = (route[mini(i+1,route.size()-1)]-route[maxi(i-1,0)]).normalized()
		var spread = width*(.48+.035*sin(i*.73)+.024*sin(i*1.32))
		var side = Vector2(tangent.y,-tangent.x)*spread
		var p = route[i]
		left.append(ground(p.x-side.x,p.y-side.y,.041))
		right.append(ground(p.x+side.x,p.y+side.y,.041))
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(route.size()-1):
		var positions = [left[i],right[i],left[i+1],right[i],right[i+1],left[i+1]]
		for index in range(6):
			var cross = 1.0 if index in [1,3,4] else 0.0
			surface.set_uv(Vector2(cross,float(i)))
			surface.add_vertex(positions[index])
	surface.generate_normals()
	var material = ShaderMaterial.new()
	material.shader = preload("res://shaders/earthen_trail.gdshader")
	material.set_shader_parameter("earth",Color(color).lerp(Color("b49464"),.64))
	var trail = Craft.mesh(self,surface.commit(),Vector3.ZERO,material)
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func paths():
	path([Vector2(-45,66),Vector2(-32,39),Vector2(-22,28),Vector2(-18,14),Vector2(-20,-5),Vector2(-36,-31)],4)
	path([Vector2(-23,32),Vector2(4,30),Vector2(11,22),Vector2(14,6)],2)
	path([Vector2(-20,-5),Vector2(14,-7)],3)
	path([Vector2(46,-7),Vector2(56,-21),Vector2(61,-42),Vector2(69,-62)],3)
	path([Vector2(-36,-31),Vector2(-54,-47),Vector2(-67,-64),Vector2(-74,-61),Vector2(-79,-61)],2.3)
	path([Vector2(62,-41),Vector2(87,-62),Vector2(96,-82)],1.5,"82976b")
	var bridge = Node3D.new()
	bridge.position = Vector3(river_x(-7),2.1,-7)
	add_child(bridge)
	Craft.box(bridge,Vector3.ZERO,Vector3(36,.35,4.0),Craft.mat("7c6648"),true)
	# Short ramps make both banks walkable without requiring a jump.
	for side in [-1,1]:
		var x0 = bridge.position.x+side*21
		var x1 = bridge.position.x+side*17.5
		var a = Vector3(x0,height_at(x0,-7)+.04,-9)
		var b = Vector3(x0,height_at(x0,-7)+.04,-5)
		var c = Vector3(x1,2.30,-9)
		var d = Vector3(x1,2.30,-5)
		var ramp_mat = Craft.mat("8f7e58").duplicate()
		ramp_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var ramp = Craft.surface(self,PackedVector3Array([a,b,c,b,d,c]),ramp_mat)
		ramp.create_trimesh_collision()
		for body in ramp.get_children():
			for shape in body.get_children():
				if shape is CollisionShape3D: shape.shape.backface_collision = true
	for i in range(46):
		Craft.box(bridge,Vector3(-17.6+i*.78,.2,0),Vector3(.7,.1,3.9),Craft.mat("ad9363"))
	for x in [-16,-8,0,8,16]:
		for z in [-1.8,1.8]:
			Craft.cylinder(bridge,Vector3(x,-.5,z),.11,4.0,Craft.mat("5a4734"))
	for z in [-1.8,1.8]:
		Craft.box(bridge,Vector3(0,1.1,z),Vector3(35,.12,.12),Craft.mat("b09a6a"))

func house(p: Vector3, size_value: Vector3, yaw: float = 0.0, wall_color: String = "e5d7ac"):
	building_footprints.append(Vector4(p.x,p.z,size_value.x*.5+.25,size_value.z*.5+.4))
	var root = Node3D.new()
	root.position = p
	root.rotation.y = yaw
	add_child(root)
	var wood = Craft.painted(Color("624135"), 1.6, .35, false, Vector3(5,.25,5))
	Craft.box(root,Vector3(0,.2,0),Vector3(size_value.x+1,.4,size_value.z+1.2),Craft.mat("81775f"),true)
	var plinth = Craft.painted(Color("77716a"),1.42,.31)
	Craft.box(root,Vector3(0,.044,0),Vector3(size_value.x+1.08,.14,size_value.z+1.29),plinth)
	Craft.box(root,Vector3(0,.34,0),Vector3(size_value.x+1.09,.12,size_value.z+1.28),plinth)
	var facade_z = -size_value.z/2
	Craft.box(root,Vector3(-size_value.x*.34,.59,facade_z-.12),Vector3(size_value.x*.275,.38,.052),Craft.mat("93523e"))
	Craft.box(root,Vector3(size_value.x*.34,.59,facade_z-.12),Vector3(size_value.x*.275,.38,.052),Craft.mat("93523e"))
	# Separate plaster wall panels leave an actual doorway and a furnished interior.
	var plaster = Craft.painted(Color(wall_color), 1.3, .14)
	Craft.box(root,Vector3(0,1.8,size_value.z/2),Vector3(size_value.x,3.2,.22),plaster)
	for side in [-1,1]:
		Craft.box(root,Vector3(side*size_value.x/2,1.8,0),Vector3(.22,3.2,size_value.z),plaster)
		Craft.box(root,Vector3(side*(size_value.x/4+.4),1.8,-size_value.z/2),Vector3(size_value.x/2-.8,3.2,.22),plaster)
	Craft.box(root,Vector3(0,3,-size_value.z/2),Vector3(1.6,.8,.22),plaster)
	Craft.box(root,Vector3(-size_value.x*.25,.55,1),Vector3(1.8,.5,2.4),Craft.mat("8d7650"))
	Craft.box(root,Vector3(-size_value.x*.25,.85,1),Vector3(1.7,.15,2.2),Craft.mat("bdad80"))
	Craft.cylinder(root,Vector3(size_value.x*.28,.65,.8),.45,.9,Craft.mat("966b42"),.3)
	# Leave a real opening in the front collision wall.
	Craft.collision(root,Vector3(0,1.8,size_value.z/2),Vector3(size_value.x,3.2,.3))
	for side in [-1,1]:
		Craft.collision(root,Vector3(side*size_value.x/2,1.8,0),Vector3(.3,3.2,size_value.z))
		Craft.collision(root,Vector3(side*(size_value.x/4+.4),1.8,-size_value.z/2),Vector3(size_value.x/2-.8,3.2,.3))
	# Keep the doorway clear between the turned pillars.
	for x in [-size_value.x/2,-1.22,1.22,size_value.x/2]:
		SceneryArt.timber_column(root,Vector3(x,.4,facade_z-.94),2.78,wood)
	Craft.box(root,Vector3(0,3.25,facade_z-.94),Vector3(size_value.x+1,.22,.25),wood)
	for side in [-1,1]:
		SceneryArt.shutter(root,Vector3(side*size_value.x*.30,1.93,facade_z-.115))
		SceneryArt.shutter(root,Vector3(side*(size_value.x/2+.118),1.93,.49),-side*PI/2)
	SceneryArt.brass_lantern(root,Vector3(0,3.26,facade_z-.94),.32)
	for z in [-size_value.z/2-.95,size_value.z/2+.14]:
		Craft.box(root,Vector3(0,.62,z),Vector3(size_value.x+.56,.32,.24),Craft.painted(Color("81715b"),1.7,.48))
		Craft.box(root,Vector3(0,3.12,z),Vector3(size_value.x+.67,.22,.31),wood)
		for i in range(int(size_value.x/.55)):
			var x = -size_value.x/2 + i*.55 + .18
			Craft.box(root,Vector3(x,3.01,z),Vector3(.15,.23,.42),wood)
	SceneryArt.roof(root,size_value.x/2+1.11,size_value.z/2+1.47,3.43,2.04)
	var portico = Node3D.new()
	portico.position = Vector3(0,0,facade_z-.66)
	portico.rotation.y = PI/2
	root.add_child(portico)
	SceneryArt.roof(portico,1.62,1.34,3.22,1.07)
	for side in [-1,1]:
		var x = side * (size_value.x/2-.27)
		for h in [.51,2.78]:
			Craft.box(root,Vector3(x,h,-size_value.z/2-.9),Vector3(.28,.22,.28),wood)
	var step = Craft.painted(Color("a39173"),1.16,.36)
	Craft.box(root,Vector3(0,.10,-size_value.z/2-1.0),Vector3(2.72,.22,1.37),step,true)
	Craft.box(root,Vector3(0,.24,-size_value.z/2-.69),Vector3(2.36,.22,1.04),step,true)
	# Collidable door mounted in the visible doorway, opens with E.
	var door = Node3D.new()
	door.position = Vector3(-.62,.35,-size_value.z/2-.12)
	root.add_child(door)
	Craft.box(door,Vector3(.62,1.1,0),Vector3(1.15,2.2,.14),wood,true)
	for i in range(5):
		Craft.box(door,Vector3(.2+i*.21,1.1,-.085),Vector3(.18,2.08,.03),Craft.mat("835b42" if i%2==0 else "754e37"))
	Craft.sphere(door,Vector3(1.01,1.06,-.11),Vector3(.11,.11,.1),Craft.mat("cc9a57",.55))
	door.add_to_group("interactables")
	door.set_meta("kind","door")
	door.set_meta("prompt","Open / close door")
	return root

func settlement():
	house(ground(-43,35),Vector3(7,4,6),.2)
	house(ground(-48,53),Vector3(6,4,5),-.4,"ded0a5")
	house(ground(-21,51),Vector3(7,4,6),PI,"c5c6a2")
	house(ground(-56,16),Vector3(8,4,6),-.2)
	house(ground(-36,7),Vector3(6,4,5),.15,"d5bd92")
	house(ground(-2,47),Vector3(5,4,5),.2)
	house(ground(-4,-27),Vector3(6,4,5),-.4)
	house(ground(56,25),Vector3(6,4,5),-.5)
	# The kalari is an open timber pavilion.
	var p = ground(-40,-33)
	Craft.box(self,p+Vector3(0,.2,0),Vector3(18,.4,14),Craft.mat("b99c6b"),true)
	for x in [-8,8]:
		for z in [-6,0,6]: Craft.box(self,p+Vector3(x,2.3,z),Vector3(.3,4.4,.3),Craft.mat("4c4031"))
	var hall = house(ground(-51,-48),Vector3(14,4,8),0,"e8ddba")
	hall.scale = Vector3(1.1,1.2,1.1)
	for i in range(5):
		Craft.box(self,ground(-41+i*2.5,-27,.5),Vector3(.3,1,.3),Craft.mat("5c4b34"))
	# A working, indestructible training target.
	var target = load("res://scripts/enemies/enemy.gd").new()
	target.training = true
	target.position = ground(-37,-30,.2)
	add_child(target)
	# Market awnings, spice bowls, baskets and displays.
	for i in range(5):
		var q = ground(-27+i*6,13 if i%2==0 else 21)
		for x in [-2,2]:
			for z in [-1.4,1.4]:
				SceneryArt.bamboo_pole(self,q+Vector3(x,0,z),3.04)
		var saffron = Color("cf8d30") if i%2==0 else Color("b87f38")
		var crimson = Color("ab4d3c") if i%2==0 else Color("ad5b44")
		SceneryArt.awning(self,q+Vector3(-1.1,3.02,0),saffron,2.26)
		SceneryArt.awning(self,q+Vector3(1.10,2.99,0),crimson,2.26)
		Craft.box(self,q+Vector3(0,.9,0),Vector3(3.8,.2,1.8),Craft.mat("77603f"),true)
		for x in [-1.76,1.76]:
			Craft.box(self,q+Vector3(x,.44,.0),Vector3(.12,.9,1.56),Craft.mat("624835"))
			SceneryArt.brass_lantern(self,q+Vector3(x,2.95,-1.40),.33)
		Craft.box(self,q+Vector3(0,.66,-.90),Vector3(1.16,.67,.02),Craft.mat("9b4938"))
		var spice = [Color("c64e2a"),Color("ebad38"),Color("799342"),Color("ae5c25"),Color("705238")]
		for j in range(5):
			SceneryArt.spice_basket(self,q+Vector3(-1.47+j*.71,1.003,0),.295,spice[(j+i)%5])
		for j in range(2):
			SceneryArt.clay_jar(self,q+Vector3(2.32+j*.37,0,1.2-j*.71),.26-j*.069,"a76042")
		SceneryArt.spice_basket(self,q+Vector3(-1.54,.01,1.16),.25,spice[(i+2)%5])
	for p2 in [Vector2(-29,29),Vector2(-12,28),Vector2(-32,0),Vector2(-39,-22)]: lamp(ground(p2.x,p2.y))

func palm(p: Vector3, s: float = 1.0):
	# Keep working rice plots open; coconut palms line the field edges.
	if p.x>50.5 and p.x<98 and p.z>37.5 and p.z<60.5:
		p = ground(p.x,37.0 if p.z<49 else 61.8)
	var root = Node3D.new()
	root.position = p
	root.rotation.y = rng.randf()*TAU
	root.scale *= s
	add_child(root)
	var trunk = Craft.painted(Color.WHITE,1.3,.26,true,Vector3(.44,6,.44))
	Craft.mesh(root,SceneryArt.palm_trunk(),Vector3.ZERO,trunk)
	var last = Vector3(.93*sin(2.18)+.48,7.4,.17)
	Craft.cylinder(root,last-Vector3.UP*.39,.17,.92,Craft.mat("809051"),.23)
	Craft.mesh(root,SceneryArt.palm_crown(rng.randi_range(0,2)),last,SceneryArt.foliage())
	for i in 4:
		var angle = i*TAU/4
		Craft.sphere(root,last+Vector3(cos(angle)*.24,-.25,sin(angle)*.24),Vector3(.39,.45,.35),Craft.mat("8d8048" if i%2==0 else "98864e"))

func broadleaf(p: Vector3, s: float):
	var root = Node3D.new()
	root.position = p
	root.scale *= s
	root.rotation.y = rng.randf()*TAU
	add_child(root)
	var bark = Craft.painted(Color("755942"),1.3,.51,false,Vector3(4,.23,4))
	Craft.cylinder(root,Vector3(0,2.45,0),.40,4.9,bark,.23)
	for i in 5:
		var a = i * 2.399
		var dir = Vector3(cos(a),0,sin(a))
		var branch = dir * (1.2 if i==4 else 1.95) + Vector3.UP * (4.1+rng.randf()*.7)
		if i==4: branch = Vector3(0,5.7,0)
		Craft.beam(root,Vector3(0,3.0,0),branch,.14,bark)
		Craft.beam(root,dir*.18 + Vector3.UP*.57,dir * 1.03 + Vector3.UP*.07,.13,bark)
		var canopy = Craft.mesh(root,SceneryArt.crown(i%3),branch-Vector3.UP*.21,SceneryArt.foliage())
		canopy.rotation.y = a
		canopy.scale *= rng.randf_range(.78,1.14)
		# The solid leaf masses give the card silhouettes a denser, readable interior.
		for lobe in 3:
			var local = Vector3(cos(a+lobe*2.1)*.81,.40+lobe*.23,sin(a+lobe*2.1)*.81)
			Craft.sphere(root,branch+local,Vector3(2.34,1.58,2.07),
				SceneryArt.canopy_mass(["346b48","42794d","568a52"][lobe]))
		if s>1.4:
			for v in 2:
				var tip = branch + dir*(.26+v*.39)
				Craft.beam(root,tip,tip+Vector3(.12,-1.7-v*.78,.1),.032,bark)

func plant_world():
	for i in range(123):
		var x = rng.randf_range(-105,112)
		var z = rng.randf_range(-102,77)
		var h = height_at(x,z)
		if h < 1 or near_path(x,z) or grass_excluded(x,z) or WildlifeLife.habitat_contains(x,z): continue
		if z > -13 or absf(x-river_x(z)) < 26: palm(Vector3(x,h,z),rng.randf_range(.7,1.3))
		else: broadleaf(Vector3(x,h,z),rng.randf_range(.8,1.8))
	for z in range(-90,76,17):
		for side in [-1,1]:
			var x = river_x(z)+side*19
			if abs(z+7)>9: palm(ground(x,z),rng.randf_range(.8,1.15))
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = SceneryArt.grass_clump()
	var transforms: Array[Transform3D] = []
	var colors: PackedColorArray = []
	for i in 21000:
		var x = rng.randf_range(-118,118)
		var z = rng.randf_range(-110,76)
		# The village verge gets extra clumps, with the roads kept clear.
		if i%3==0:
			x = rng.randf_range(-52,16)
			z = rng.randf_range(6,63)
		var h = height_at(x,z)
		if h<.85 or grass_excluded(x,z): continue
		var size_value = rng.randf_range(.42,1.32)
		if absf(x-river_x(z))<17: size_value *= 1.42
		transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*size_value),Vector3(x,h-.025,z)))
		colors.append(Color("2e7140").lerp(Color("91a54d"),rng.randf()))
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i,transforms[i])
		mm.set_instance_color(i,colors[i])
	grass = MultiMeshInstance3D.new()
	grass.layers = 1 << 19
	grass.multimesh = mm
	var material = ShaderMaterial.new()
	material.shader = preload("res://shaders/grass.gdshader")
	grass.material_override = material
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass)

func grass_excluded(x: float,z: float) -> bool:
	if SoldierEncounters.contains_site(x,z): return true
	if x>50 and x<101 and z>36 and z<66: return true
	for line in path_segments:
		if Vector2(x,z).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(x,z),line[0],line[1])) < line[2]*.57:
			return true
	for site in building_footprints:
		if absf(x-site.x)<site.z and absf(z-site.y)<site.w: return true
	if x > -37 and x < 7 and z > 2 and z < 28: return true
	if x > 61 and x < 79 and z > -74 and z < -60: return true
	return false

func near_path(x: float,z: float) -> bool:
	if x > -61 and x < 9 and z > 0 and z < 60: return true
	if absf(z+7)<5 and x > -22 and x < 50: return true
	if x > -55 and x < -27 and z > -55 and z < -20: return true
	if absf(x-64)<9 and z < -12 and z > -74: return true
	return false

func backwaters():
	var dock = ground(10,33)
	Craft.box(self,Vector3(15,1.1,33),Vector3(12,.3,3),Craft.mat("8d7751"),true)
	for x in [9,14,19]:
		for z in [31.8,34.2]: Craft.cylinder(self,Vector3(x,-.2,z),.12,4,Craft.mat("66513a"))
	boat = load("res://scripts/vehicles/boat.gd").new()
	boat.position = Vector3(24.5,.4,33)
	add_child(boat)
	for i in range(6):
		Craft.box(self,ground(14+i*.4,6,.2),Vector3(.3,.12,1.8),Craft.mat("873f32"))
	interactable("clue","Inspect the torn sail",ground(14,6,.55))
	Craft.beam(self,ground(14,6),ground(14,6)+Vector3(0,1.8,0),.04,Craft.mat("71513a"))
	var flag = Craft.box(self,ground(14,6)+Vector3(.55,1.35,0),Vector3(1.1,.6,.025),Craft.mat("ab5038"))
	flag.rotation.z = -.1

func forest_and_ruins():
	for i in range(16):
		var p = ground(rng.randf_range(46,109),rng.randf_range(-103,-32))
		SceneryArt.river_rock(self,p,Vector3(rng.randf_range(1,3),rng.randf_range(1,3),rng.randf_range(1,3)),i%3)
	var camp = ground(70,-67)
	var stone = Craft.painted(Color("83877a"),1.8,.36)
	stone = stone.duplicate()
	stone.set_shader_parameter("moss_amount", .78)
	var edges = Craft.painted(Color("a39d84"),1.8,.32)
	Craft.box(self,camp+Vector3(0,.12,0),Vector3(16,.24,13),edges,true)
	Craft.box(self,camp+Vector3(0,.025,0),Vector3(16.36,.095,13.34),stone)
	Craft.box(self,camp+Vector3(0,.18,0),Vector3(16.18,.083,13.17),stone)
	for i in range(3):
		Craft.box(self,camp+Vector3(0,.04+i*.034,-6.92+i*.235),Vector3(2.8,.049,.63),edges)
	for x in range(10):
		for z in range(8):
			var tint = ["a3987b","898c78","949378"][(x*5+z*7)%3]
			var slab = Craft.painted(Color(tint),1.5,.19)
			Craft.box(self,camp+Vector3(-7.23+x*1.6,.244,-5.64+z*1.6),Vector3(1.55,.025,1.55),slab)
	for x in [-7,7]:
		for z in [-5,5]:
			var column = camp+Vector3(x,0,z)
			Craft.box(self,column+Vector3(0,1.8,0),Vector3(.85,3.6,.85),stone,true)
			SceneryArt.ruin_column(self,column,stone,edges)
		Craft.box(self,camp+Vector3(x,3.8,0),Vector3(1.1,.5,11),stone)
		for z in [-3.3,.9,3.7]:
			SceneryArt.hanging_vines(self,camp+Vector3(x,3.99,z),1.33)
	for z in [-5.0,5.0]:
		for x in range(7):
			Craft.box(self,camp+Vector3(-6.26+x*2.09,3.79,z),Vector3(2.08,.39,.91),stone)
		SceneryArt.hanging_vines(self,camp+Vector3(-3.9,3.96,z-.44),1.53)
	# A four-metre breach lets the whole guard leave the camp together.
	for i in range(6):
		if i in [2,3]: continue
		Craft.box(self,camp+Vector3(-6+i*2,.6,5),Vector3(1.9,1.2,.7),stone,true)
		Craft.box(self,camp+Vector3(-6+i*2,1.19,5),Vector3(1.95,.13,.82),edges)
	var entry_low = Vector3(69,height_at(69,-56.8)-.08,-56.8)
	var entry_top = Vector3(69,camp.y+.26,-60.05)
	var entry_end = Vector3(69,camp.y+.26,-60.8)
	var entry_vertices = PackedVector3Array()
	for pair in [[entry_low,entry_top],[entry_top,entry_end]]:
		var a: Vector3 = pair[0]
		var b: Vector3 = pair[1]
		entry_vertices.append_array(PackedVector3Array([
			a+Vector3(-1.8,0,0),a+Vector3(1.8,0,0),b+Vector3(-1.8,0,0),
			a+Vector3(1.8,0,0),b+Vector3(1.8,0,0),b+Vector3(-1.8,0,0)]))
	var entry = Craft.surface(self,entry_vertices,stone)
	entry.create_trimesh_collision()
	for body in entry.get_children():
		for collider in body.get_children():
			if collider is CollisionShape3D: collider.shape.backface_collision = true
	var chest = interactable("ledger","Recover the vanchi ledger",camp+Vector3(0,.55,0))
	Craft.box(chest,Vector3.ZERO,Vector3(.7,.15,.5),Craft.mat("69452e"))
	Craft.box(chest,Vector3(0,.09,0),Vector3(.55,.04,.42),Craft.mat("d8c48d"))
	for i in range(8): lamp(ground(52+i*1.8,-19-i*5.4))
	for p in [ground(-65,-52),ground(87,32),ground(105,-81)]:
		var root = interactable("chest","Open the travel chest",p+Vector3(0,.5,0))
		Craft.box(root,Vector3.ZERO,Vector3(.9,.6,.6),Craft.mat("705239"))
		for x in [-.3,.3]: Craft.box(root,Vector3(x,0,0),Vector3(.065,.65,.64),Craft.mat("bd9c5e",.6))
	# A designated climbable watch platform.
	var climb = ground(-70,-62)
	Craft.box(self,climb+Vector3(0,2.4,0),Vector3(3,4.8,2),Craft.mat("7b8571"),true)
	for y in range(10): Craft.box(self,climb+Vector3(0,y*.45+.2,1.08),Vector3(1,.06,.1),Craft.mat("bfab75"))
	interactable("climb","Climb the lookout [C]",climb+Vector3(0,1,2.0))
	# Staggered moss ledges frame two streams and a shallow plunge pool.
	var falls = ground(101,-89)
	for i in 9:
		var x = (i%3-1)*2.75
		var y = 1.55+floorf(i/3.0)*2.75
		var rock = SceneryArt.river_rock(self,falls+Vector3(x,y,sin(i*1.21)*.83),
			Vector3(4.1,4.5,4.8),i%3)
		rock.rotation.y = .35*sin(i+1)
	for i in 5:
		var ox = sin(i*2.3)*4.5
		var oz = -3.4-i*.33
		SceneryArt.river_rock(self,falls+Vector3(ox,.40,oz),Vector3(1.8,1,1.8),i%3)
	var waterfall_mat = ShaderMaterial.new()
	waterfall_mat.shader = preload("res://shaders/waterfall.gdshader")
	for i in 3:
		var curtain = QuadMesh.new()
		var height = 7.48-float(i)*.49
		curtain.size = Vector2(1.25-i*.18,height)
		var model = Craft.mesh(self,curtain,falls+Vector3(-.91+i*.92,height*.5+.07,-2.67-i*.035),waterfall_mat)
		model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pool = CylinderMesh.new()
	pool.top_radius = 1.0
	pool.bottom_radius = 1.0
	pool.height = .026
	pool.radial_segments = 40
	var water_surface = Craft.mesh(self,pool,falls+Vector3(0,.08,-3.47),Craft.mat("699f97",.12,.1))
	water_surface.scale = Vector3(3.5,1,2.1)

func mountains():
	var noise = FastNoiseLite.new()
	noise.seed = 591
	noise.frequency = .010
	noise.fractal_octaves = 4
	var palette = [Color("91b8b7"),Color("76aaa7"),Color("538e8d"),Color("3d787a")]
	for layer in 4:
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var ridgeline: Array[Vector3] = []
		for j in range(181):
			var x = -450.0+j*5
			var n = noise.get_noise_2d(x+layer*209.0,layer*56.0)
			var h = (66.0-layer*9.0) + n*(66.0-layer*4.0) + sin(x*.022+layer)*14.0
			ridgeline.append(Vector3(x,h,-(348.0-layer*47.0)+sin(x*.016+layer)*17.0))
		for j in range(ridgeline.size()-1):
			for r in range(9):
				for pair in [Vector2i(j,r),Vector2i(j+1,r),Vector2i(j,r+1),
						Vector2i(j+1,r),Vector2i(j+1,r+1),Vector2i(j,r+1)]:
					var ridge = ridgeline[pair.x]
					var t = pair.y/9.0
					var crease = noise.get_noise_2d(ridge.x*2.4,layer*150+t*335)
					var wide = sin(ridge.x*.062+layer)*7.0+crease*18.0
					var y = lerpf(ridge.y,-5.0,pow(t,1.22)) + crease*sin(t*PI)*12.0
					var z = ridge.z+t*(34.0+wide)
					var tint = palette[layer].lerp(Color("aad1be"),pow(t,1.32)*.70)
					tint = tint.lightened(crease*.17+sin(ridge.x*.11+t*6)*sin(t*PI)*.032)
					SceneryArt.add_vertex(st,Vector3(ridge.x,y,z),tint,Vector2.ZERO)
		st.generate_normals()
		var material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var hills = Craft.mesh(self,st.commit(),Vector3.ZERO,material)
		hills.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func lamp(p: Vector3):
	# Limit real lights to showcase lamps. All remaining lanterns use emission.
	var local_light = (p.z>20 and p.x<0) or (p.x>56 and p.z<-44)
	SceneryArt.vilakku(self,p,local_light)

func interactable(kind: String,prompt_value: String,p: Vector3) -> Node3D:
	var n = Node3D.new()
	n.position = p
	n.set_meta("kind",kind)
	n.set_meta("prompt",prompt_value)
	n.add_to_group("interactables")
	add_child(n)
	return n

func populate():
	var positions = {"ravi":Vector2(-24,33),"meera":Vector2(-18,15),"amma":Vector2(-39,38),"fish":Vector2(-25,22),"guru":Vector2(-40,-26),"smith":Vector2(-51,14)}
	for id in positions:
		var n = load("res://scripts/npcs/npc.gd").new()
		n.npc_id = id
		n.position = ground(positions[id].x,positions[id].y,.1)
		add_child(n)
	reset_enemies()

func reset_enemies():
	if not is_instance_valid(encounters):
		encounters = SoldierEncounters.new()
		add_child(encounters)
	encounters.reset()

func coastal_details():
	var wood = Craft.mat("70533a")
	var rope = Craft.mat("9f9974")
	# Cantilever fishing nets: a coastal landmark, built from bamboo and knotted rope.
	for z in [51.0,69.0]:
		var x = river_x(z)-18
		var p = ground(x,z)
		Craft.box(self,p+Vector3(0,.1,0),Vector3(4,.2,4),wood,true)
		var pivot = p+Vector3(0,3,0)
		Craft.beam(self,p+Vector3(-1,0,-1),pivot,.12,wood)
		Craft.beam(self,p+Vector3(-1,0,1),pivot,.12,wood)
		var corners = [p+Vector3(7,.25,-3),p+Vector3(12,.25,-3),p+Vector3(7,.25,3),p+Vector3(12,.25,3)]
		for corner in corners:
			Craft.beam(self,pivot,corner+Vector3.UP*3,.055,wood)
			Craft.beam(self,corner,corner+Vector3.UP*3,.013,rope)
		for i in range(9):
			var t = i/8.0
			Craft.beam(self,corners[0].lerp(corners[1],t),corners[2].lerp(corners[3],t),.012,rope)
			Craft.beam(self,corners[0].lerp(corners[2],t),corners[1].lerp(corners[3],t),.012,rope)
		Craft.beam(self,pivot,p+Vector3(-4,1.5,0),.07,wood)
		for i in 3: Craft.sphere(self,p+Vector3(-4,1.1-i*.3,0),Vector3(.4,.45,.4),Craft.mat("78765b"))
	# Fence rails, woven baskets, firewood and pottery around the lived-in village.
	for i in range(11):
		var p = ground(-59,12+i*4.5)
		Craft.cylinder(self,p+Vector3.UP*.6,.07,1.2,wood)
		if i<10:
			for y in [.4,.85]: Craft.beam(self,p+Vector3.UP*y,ground(-59,16.5+i*4.5)+Vector3.UP*y,.04,wood)
	for v in [Vector2(-39,31),Vector2(-47,48),Vector2(-52,13),Vector2(-20,47),Vector2(-32,8),Vector2(-7,15),Vector2(-44,-29)]:
		var p = ground(v.x,v.y)
		for i in 3:
			Craft.cylinder(self,p+Vector3(i*.65,.35,0),.24,.7,Craft.mat("9b6c46"),.17)
			Craft.cylinder(self,p+Vector3(i*.65,.71,0),.16,.025,Craft.mat("493e2b"))
		for i in 4: Craft.beam(self,p+Vector3(-1+i*.14,.15,.2),p+Vector3(-1+i*.14,.15,1.1),.06,wood)
		Craft.box(self,p+Vector3(0,.35,1.8),Vector3(1.8,.14,.55),wood)
		for x in [-.65,.65]: Craft.box(self,p+Vector3(x,.15,1.8),Vector3(.12,.4,.4),wood)
	# Ginger, ferns and small marigold gardens soften the edges of the architecture.
	for i in range(130):
		var center = [Vector2(-40,32),Vector2(-48,51),Vector2(-21,47),Vector2(-36,4),Vector2(-45,-39),Vector2(-8,39)][i%6]
		var x = center.x+rng.randf_range(-3.5,3.5)
		var z = center.y+rng.randf_range(-1.2,1.2)
		var p = ground(x,z)
		for j in 3:
			var a = j*TAU/3+i
			var leaf = Craft.sphere(self,p+Vector3(cos(a)*.22,.25,sin(a)*.22),Vector3(.18,.65,.15),Craft.mat("4a7b50"))
			leaf.rotation = Vector3(.35,a,.3)
		if i%3==0: Craft.sphere(self,p+Vector3.UP*.52,Vector3(.16,.14,.16),Craft.mat("d8a04f" if i%2==0 else "ba735d"))
	for v in [Vector2(-11,31),Vector2(-31,25),Vector2(11,-12),Vector2(52,-14),Vector2(57,-37),Vector2(77,-53),Vector2(-51,-51),Vector2(-72,-72)]:
		var n = interactable("herb","Gather medicinal leaves",ground(v.x,v.y,.2))
		for i in range(5):
			var leaf = Craft.sphere(n,Vector3(sin(i)*.2,.23,cos(i)*.2),Vector3(.15,.7,.15),Craft.mat("7eaa68"))
			leaf.rotation = Vector3(.5,i*.7,.2)
		Craft.sphere(n,Vector3.UP*.57,Vector3(.11,.12,.11),Craft.mat("e4bd75"))
	# A banyan with exposed roots marks the village gathering place.
	var tree = ground(-39,43)
	Craft.cylinder(self,tree+Vector3.UP*.22,2.7,.4,Craft.mat("a89d77"))
	broadleaf(tree,1.7)
	for i in range(9):
		var angle = i*TAU/9
		Craft.beam(self,tree+Vector3(sin(angle)*2,4,cos(angle)*2),tree+Vector3(sin(angle)*1.6,.4,cos(angle)*1.6),.045,Craft.mat("726342"))

# Shared primitive meshes make static details cheap to instance. Interactive objects
# keep their own nodes so doors, herbs, characters and chests can still animate.
func batch_scenery():
	var groups: Dictionary = {}
	collect_static(self,groups)
	for key in groups:
		var nodes: Array = groups[key]
		if nodes.size()<4: continue
		var first: MeshInstance3D = nodes[0]
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = first.mesh
		mm.instance_count = nodes.size()
		var instance = MultiMeshInstance3D.new()
		instance.multimesh = mm
		instance.material_override = first.material_override
		instance.cast_shadow = first.cast_shadow
		add_child(instance)
		for i in nodes.size():
			mm.set_instance_transform(i,global_transform.affine_inverse()*nodes[i].global_transform)
			nodes[i].queue_free()

func collect_static(node: Node,groups: Dictionary):
	if node!=self and (node.is_in_group("interactables") or node.is_in_group("enemies") or node.is_in_group("wildlife") or node.name=="Hanging brass bell"): return
	if node is MeshInstance3D and node.get_child_count()==0 and node.name!="Water" and node.material_override:
		var key = str(node.mesh.get_instance_id())+"_"+str(node.material_override.get_instance_id())+"_"+str(node.cast_shadow)
		if not groups.has(key): groups[key] = []
		groups[key].append(node)
	for child in node.get_children(): collect_static(child,groups)


func flower_banks():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var scatter = RandomNumberGenerator.new()
	scatter.seed = 1870
	var beds = [Vector2(-35,40),Vector2(-26,39),Vector2(-37,31),Vector2(-17,31),
		Vector2(-13,9),Vector2(-9,22),Vector2(9,32),Vector2(15,17),
		Vector2(55,-19),Vector2(69,-41),Vector2(-63,-58)]
	for i in beds.size():
		for j in 45:
			var p = beds[i]+Vector2(scatter.randfn(0,1.3),scatter.randfn(0,1.55))
			if grass_excluded(p.x,p.y): continue
			var root = ground(p.x,p.y,.04)
			var h = scatter.randf_range(.25,.49)
			var tip = root+Vector3.UP*h
			for k in range(4):
				var a = j + k*2.399
				var dir = Vector3(cos(a),0,sin(a))
				var side = Vector3(-dir.z,0,dir.x)
				SceneryArt.leaf(st,root,root+dir*.25+Vector3.UP*.18,side*.04,Color("4d863b"),.047)
				var color = [Color("ecb65d"),Color("f6d779"),Color("e59270"),Color("eae6c8")][i%4]
				SceneryArt.leaf(st,tip,tip+dir*.096+Vector3.UP*.065,side*.039,color,.02)
			SceneryArt.leaf(st,root,tip,Vector3(.012,0,0),Color("658748"),.005)
	st.generate_normals()
	var blossoms = Craft.mesh(self,st.commit(),Vector3.ZERO,SceneryArt.foliage())
	blossoms.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

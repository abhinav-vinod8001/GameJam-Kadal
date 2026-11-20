class_name SettlementLife
extends Node3D

var world: Malanadu
var random = RandomNumberGenerator.new()
var tree_positions: Array[Vector3] = []
var tree_count := 0
var rice_count := 0
var added_stalls := 0
var villagers: Array[Node3D] = []
var field_centers: Array[Vector3] = []
var chunk_groups: Dictionary = {}
var clearings: Array[Vector3] = []

func _ready():
	name = "SettlementLife"
	world = get_parent()
	random.seed = 82491
	for n in get_tree().get_nodes_in_group("interactables"): clearings.append(n.global_position)
	clearings.append(Vector3(60,0,-54))
	market()
	forest()
	paddy_fields()
	village_people()
	print("WORLD LIFE · ",tree_count," extra trees · ",rice_count," rice clumps · ",5+added_stalls," stalls · ",6+villagers.size()," friendly NPCs")

func instance_group(mesh: Mesh, transforms: Array[Transform3D], material: Material, label: String, end: float = 160.0, reflected: bool = true):
	if transforms.is_empty(): return
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size(): mm.set_instance_transform(i,transforms[i])
	var node = MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = mm
	node.material_override = material
	node.visibility_range_end = end
	node.visibility_range_end_margin = 15.0
	if not reflected: node.layers = 1 << 19
	if end<100: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)

func tree_safe(p: Vector3) -> bool:
	if p.y<1.0 or WildlifeLife.habitat_contains(p.x,p.z): return false
	if p.x>-63 and p.x<10 and p.z>-18 and p.z<61: return false
	if p.x>58 and p.x<81 and p.z>-78 and p.z<-51: return false
	if p.x>-76 and p.x<-63 and p.z>-70 and p.z<-53: return false
	for line in world.path_segments:
		if Vector2(p.x,p.z).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),line[0],line[1]))<line[2]*.5+2.1: return false
	for site in world.building_footprints:
		if absf(p.x-site.x)<site.z+3.2 and absf(p.z-site.y)<site.w+3.2: return false
	for site in clearings:
		if Vector2(p.x,p.z).distance_to(Vector2(site.x,site.z))<3.4: return false
	for other in tree_positions:
		if Vector2(p.x,p.z).distance_squared_to(Vector2(other.x,other.z))<10.5: return false
	return true

func forest():
	for region in [[Rect2(46,-111,76,110),210],[Rect2(-116,-113,135,92),160],
		[Rect2(-112,-12,49,91),68],[Rect2(-63,61,70,12),18]]:
		var area: Rect2 = region[0]
		var planted = 0
		for attempt in int(region[1])*30:
			if planted>=int(region[1]): break
			var p = world.ground(random.randf_range(area.position.x,area.end.x),random.randf_range(area.position.y,area.end.y))
			if not tree_safe(p): continue
			tree_positions.append(p)
			planted += 1
			tree_count += 1
			var cell = Vector2i(floori(p.x/26),floori(p.z/26))
			var variant = random.randi_range(0,2)
			var key = str(cell)+"_"+str(variant)
			if not chunk_groups.has(key): chunk_groups[key] = {"variant":variant,"poses":[]}
			var scale_value = random.randf_range(.78,1.32)
			var transform_value = Transform3D(Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3(scale_value,scale_value*random.randf_range(.94,1.11),scale_value)),p)
			chunk_groups[key].poses.append(transform_value)
			Craft.collision(self,p+Vector3.UP*1.8,Vector3(.46,3.6,.46))
	for key in chunk_groups:
		var data = chunk_groups[key]
		var poses: Array[Transform3D] = []
		for pose in data.poses: poses.append(pose)
		instance_group(tree_mesh(data.variant,false),poses,Craft.painted(Color.WHITE,1.4,.28,true),"Forest trunks "+key,180)
		instance_group(tree_mesh(data.variant,true),poses,SceneryArt.foliage(),"Forest crowns "+key,180)
	# Low woodland layers make the forest floor read as a forest at eye level.
	var ferns: Array[Transform3D] = []
	for i in 2100:
		var center = tree_positions[random.randi_range(0,tree_positions.size()-1)]
		var p = world.ground(center.x+random.randf_range(-3.3,3.3),center.z+random.randf_range(-3.3,3.3))
		if p.y<1 or world.grass_excluded(p.x,p.z): continue
		var s = random.randf_range(.65,1.55)
		ferns.append(Transform3D(Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3.ONE*s),p))
	instance_group(fern_mesh(),ferns,SceneryArt.foliage(),"Forest ferns and understory",85,false)
	for i in 30:
		var p = tree_positions[(i*13)%tree_positions.size()]
		if i%2==0:
			SceneryArt.river_rock(self,p+Vector3(1.1,.15,.6),Vector3(1.3,.7,1.1),i%3)
		else:
			Craft.beam(self,p+Vector3(.7,.22,.5),p+Vector3(2.6,.18,.9),.17,Craft.mat("67503b"))
	for p in [Vector2(-58,35),Vector2(-61,52),Vector2(-15,59),Vector2(-5,59),Vector2(5,41),Vector2(8,47),
		Vector2(50,38),Vector2(66,65),Vector2(82,65),Vector2(98,58),Vector2(102,39),Vector2(-61,-6)]:
		world.palm(world.ground(p.x,p.y),random.randf_range(.85,1.15))
		tree_count += 1

static func primitive(st: SurfaceTool, mesh: Mesh, pose: Transform3D, color: Color):
	var data = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
	var normal_basis = pose.basis.inverse().transposed()
	for index in indices:
		st.set_color(color)
		st.set_uv(Vector2(.5,clampf((pose*vertices[index]).y/9.0,0,1)))
		st.set_normal((normal_basis*normals[index]).normalized())
		st.add_vertex(pose*vertices[index])

static func branch(st: SurfaceTool,a: Vector3,b: Vector3,radius: float,color: Color):
	var mesh = CylinderMesh.new()
	mesh.radial_segments = 8
	mesh.top_radius = .65
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	primitive(st,mesh,Transform3D(Basis(Quaternion(Vector3.UP,(b-a).normalized())).scaled(Vector3(radius,a.distance_to(b),radius)),(a+b)*.5),color)

static func tree_mesh(variant: int, crown: bool) -> Mesh:
	var key = "woodland_tree_"+str(variant)+str(crown)
	if Craft.geometry.has(key): return Craft.geometry[key]
	var source = RandomNumberGenerator.new()
	source.seed = 490+variant
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if not crown:
		branch(st,Vector3.ZERO,Vector3(.12,4.4,.13),.30,Color("6b5139"))
		for i in 4:
			var angle = i*2.399+variant
			var end = Vector3(cos(angle)*1.8,5.4+source.randf(),sin(angle)*1.8)
			branch(st,Vector3(.1,3.2,.1),end,.13,Color("796044"))
			branch(st,Vector3(cos(angle)*.9,.06,sin(angle)*.9),Vector3(0,.6,0),.12,Color("6b5139"))
	else:
		var sphere = SphereMesh.new()
		sphere.radial_segments = 10
		sphere.rings = 5
		var colors = [Color("285f3c"),Color("3a7944"),Color("4e8748"),Color("6d9850")]
		for i in 4:
			var angle = i*2.399+variant
			var center = Vector3(cos(angle)*1.45,5.7+i*.38,sin(angle)*1.45)
			primitive(st,sphere,Transform3D(Basis.IDENTITY.scaled(Vector3(4.4,2.65,4.15)),center),colors[i].darkened(.08))
			for j in 68:
				var a = source.randf()*TAU
				var radius = sqrt(source.randf())*2.3
				var dir = Vector3(cos(a),0,sin(a))
				var p = center+dir*radius+Vector3.UP*(sqrt(maxf(0,1-pow(radius/2.4,2)))*source.randf_range(.2,1.3))
				SceneryArt.leaf(st,p,p+dir*source.randf_range(.5,.95)+Vector3.UP*.08,Vector3(-dir.z,0,dir.x)*.21,colors[(i+j)%4],.12)
	st.generate_normals()
	Craft.geometry[key] = st.commit()
	return Craft.geometry[key]

static func fern_mesh() -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var a = i*2.399
		var dir = Vector3(cos(a),0,sin(a))
		for j in 3:
			var start = Vector3.UP*.09+dir*j*.16+Vector3.UP*sin(j*.7)*.24
			SceneryArt.leaf(st,start,start+dir*.40+Vector3.UP*.15,Vector3(-dir.z,0,dir.x)*(.12-j*.023),Color("438151").lightened(j*.045),.05)
	st.generate_normals()
	return st.commit()

func market():
	var ground_mesh = SurfaceTool.new()
	ground_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in 43:
		for z in 26:
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var px = -36.5+x+corner.x
				var pz = 1.5+z+corner.y
				ground_mesh.set_uv(Vector2((x+corner.x)/43.0,(z+corner.y)/26.0))
				ground_mesh.add_vertex(world.ground(px,pz,.055))
	ground_mesh.generate_normals()
	var earth = ShaderMaterial.new()
	earth.shader = preload("res://shaders/market_earth.gdshader")
	var plaza = Craft.mesh(self,ground_mesh.commit(),Vector3.ZERO,earth)
	plaza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var styles = ["fruit","pottery","cloth","fish","grain","vegetables","flowers","coconut"]
	var sites = [Vector3(-34,-PI/2,15.5),Vector3(-34,-PI/2,24),Vector3(-28,PI,5),Vector3(-10,PI,3),
		Vector3(-2,PI/2,9),Vector3(4,PI/2,18),Vector3(-9,0,25.5),Vector3(-1,0,25.5)]
	for i in sites.size():
		var site: Vector3 = sites[i]
		var root = Node3D.new()
		root.name = "Market "+styles[i]
		root.position = world.ground(site.x,site.z)
		root.rotation.y = site.y
		add_child(root)
		world.building_footprints.append(Vector4(site.x,site.z,2.1 if absf(sin(site.y))<.5 else 1.9,1.9 if absf(sin(site.y))<.5 else 2.1))
		var wood = Craft.mat("79553a")
		for x in [-1.9,1.9]:
			for z in [-1.3,1.3]: SceneryArt.bamboo_pole(root,Vector3(x,0,z),3.0)
		var colors = [Color("c78b36"),Color("aa4f40"),Color("607d75"),Color("b8a16b")]
		SceneryArt.awning(root,Vector3(0,2.95,0),colors[i%4],4.4)
		Craft.box(root,Vector3(0,.88,0),Vector3(3.6,.16,1.5),wood,true)
		for x in [-1.55,1.55]: Craft.box(root,Vector3(x,.4,0),Vector3(.12,.85,1.3),wood)
		SceneryArt.brass_lantern(root,Vector3(-1.65,2.95,-1.2),.35)
		var stock = Node3D.new()
		root.add_child(stock)
		for j in 5:
			var x = -1.4+j*.7
			match styles[i]:
				"pottery": SceneryArt.clay_jar(stock,Vector3(x,.97,0),.18+(j%3)*.045,["9d5138","bb7953","7e4d38"][j%3])
				"cloth":
					var roll = Craft.cylinder(stock,Vector3(x,1.15,0),.16,.77,Craft.mat(["a54b3e","d0a34f","497e79","8a687e","c5bb8b"][j]))
					roll.rotation.x = PI/2
				"fish":
					Craft.box(stock,Vector3(x,.99,0),Vector3(.57,.05,.95),Craft.mat("ad9260"))
					for k in 3:
						AvatarArt.ellipsoid(stock,Vector3(x+(k-1)*.13,1.055,0),Vector3(.12,.07,.55),Craft.mat("9db6b0",.2))
				_:
					var palette = [Color("c39e51"),Color("ae6137"),Color("668544"),Color("d0ad3d"),Color("a84f3c")]
					SceneryArt.spice_basket(stock,Vector3(x,.97,0),.27,palette[(i+j)%5])
					if styles[i] in ["fruit","vegetables","coconut"]:
						for k in 5:
							var pos = Vector3(x+sin(k*2.399)*.14,1.21+(k%2)*.10,cos(k*2.399)*.13)
							Craft.sphere(stock,pos,Vector3.ONE*.16,Craft.mat(["d3a14b","c36939","63864c"][k%3]))
		SceneryArt.clay_jar(root,Vector3(2.13,0,.8),.25,"a56645")
		Craft.box(root,Vector3(-1.3,.22,1.1),Vector3(.75,.44,.6),Craft.mat("8c6d43"))
		AvatarArt.bake_joint(stock)
		added_stalls += 1
	# Festive cloth, supplies and a handcart make the spaces between stalls useful.
	var left = world.ground(-33,28)+Vector3.UP*5.0
	var right = world.ground(3,28)+Vector3.UP*5.0
	for p in [left,right]:
		Craft.beam(self,p-Vector3.UP*5.0,p+Vector3.UP*.08,.055,Craft.mat("a78a55"))
	Craft.beam(self,left,right,.016,Craft.mat("786243"))
	for i in 28:
		var p = left.lerp(right,(i+.5)/28.0)
		var drop = .18+sin((i+.5)/28.0*PI)*.42
		Craft.surface(self,PackedVector3Array([p+Vector3(-.20,-drop,0),p+Vector3(.20,-drop,0),p+Vector3(0,-drop-.42,0)]),Craft.mat(["c68d3d","a95440","6d8b73"][i%3]))
	cart(world.ground(-6,33),.3)

func cart(p: Vector3,yaw: float):
	var root = Node3D.new()
	root.position = p
	root.rotation.y = yaw
	add_child(root)
	var wood = Craft.mat("86613e")
	Craft.box(root,Vector3(0,.65,0),Vector3(1.5,.17,2.0),wood)
	for x in [-.76,.76]:
		Craft.box(root,Vector3(x,.94,0),Vector3(.08,.52,2.0),wood)
		Craft.beam(root,Vector3(x,.55,.3),Vector3(x,.7,-2.3),.043,wood)
		var wheel = TorusMesh.new()
		wheel.inner_radius = .39
		wheel.outer_radius = .46
		wheel.rings = 20
		wheel.ring_segments = 6
		var n = Craft.mesh(root,wheel,Vector3(x,.48,.3),Craft.mat("574230"))
		n.rotation.z = PI/2
		for i in 8:
			var a = i*TAU/8
			Craft.beam(root,Vector3(x,.48,.3),Vector3(x,.48+sin(a)*.4,.3+cos(a)*.4),.019,wood)
	for i in 3: SceneryArt.spice_basket(root,Vector3((i%2)*.63-.3,.75,(i/2)*.7-.3),.25,Color("c7b274"))

func paddy_fields():
	var water = ShaderMaterial.new()
	water.shader = preload("res://shaders/paddy_water.gdshader")
	var rice_material = ShaderMaterial.new()
	rice_material.shader = preload("res://shaders/rice.gdshader")
	for field in 3:
		var center = world.ground(58+field*16,49)
		field_centers.append(center)
		var flooded = SurfaceTool.new()
		flooded.begin(Mesh.PRIMITIVE_TRIANGLES)
		for x in 12:
			for z in 20:
				for offset in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
					var px = center.x-6+x+offset.x
					var pz = center.z-10+z+offset.y
					flooded.add_vertex(world.ground(px,pz,.035))
		flooded.generate_normals()
		Craft.mesh(self,flooded.commit(),Vector3.ZERO,water)
		for side in [-1,1]:
			bund(Vector2(center.x+side*6.4,38.5),Vector2(center.x+side*6.4,59.5),.60)
			bund(Vector2(center.x-6.4,49+side*10.5),Vector2(center.x+6.4,49+side*10.5),.62)
		bund(Vector2(center.x,38.5),Vector2(center.x,59.5),.42)
		bund(Vector2(center.x-6.4,49),Vector2(center.x+6.4,49),.42)
		var poses: Array[Transform3D] = []
		for row in 44:
			for col in 27:
				var x = center.x-5.75+col*.44
				var z = center.z-9.55+row*.44
				if absf(x-center.x)<.48 or absf(z-center.z)<.48: continue
				var s = random.randf_range(.88,1.12)
				poses.append(Transform3D(Basis(Vector3.UP,random.randf_range(-.3,.3)).scaled(Vector3(s,s,s)),world.ground(x+random.randf_range(-.055,.055),z,.06)))
		rice_count += poses.size()
		instance_group(rice_mesh(field),poses,rice_material,"Rice rows "+str(field),100,false)
		# Planting tools, harvested bundles and baskets at each field corner.
		var corner = world.ground(center.x+5.8,61.0)
		SceneryArt.spice_basket(self,corner,.45,Color("c9b568"))
		for j in 4:
			var sheaf = Craft.cylinder(self,corner+Vector3(-1-j*.28,.4,.2),.18,.85,Craft.mat("b6a35f"),.065)
			sheaf.rotation.z = .12
			Craft.cylinder(self,corner+Vector3(-1-j*.28,.37,.2),.11,.07,Craft.mat("796344"))
		for j in 5: Craft.beam(self,world.ground(center.x+6.9,40+j*4.4),world.ground(center.x+6.9,40+j*4.4)+Vector3.UP*.8,.025,Craft.mat("ac9259"))
	# Shared irrigation ditch, sluice, shelter and a scarecrow.
	for x in [66.0,82.0]:
		var ditch = SurfaceTool.new()
		ditch.begin(Mesh.PRIMITIVE_TRIANGLES)
		for z in range(37,63):
			for p in [Vector2(x-.29,z),Vector2(x+.29,z),Vector2(x-.29,z+1),Vector2(x+.29,z),Vector2(x+.29,z+1),Vector2(x-.29,z+1)]:
				ditch.add_vertex(world.ground(p.x,p.y,.045))
		ditch.generate_normals()
		Craft.mesh(self,ditch.commit(),Vector3.ZERO,water)
		for side in [-1,1]: Craft.beam(self,world.ground(x+side*.44,37),world.ground(x+side*.44,37)+Vector3.UP*1.2,.04,Craft.mat("8c714a"))
		for j in 4: Craft.box(self,world.ground(x,37,.18+j*.16),Vector3(.75,.11,.07),Craft.mat("8c714a"))
	var shelter = world.ground(75,64)
	for x in [-1.8,1.8]:
		for z in [-1.3,1.3]: SceneryArt.bamboo_pole(self,shelter+Vector3(x,0,z),2.7)
	SceneryArt.awning(self,shelter+Vector3.UP*2.65,Color("ad9b65"),4.4)
	cart(shelter+Vector3(3,0,0),PI/2)
	SceneryArt.clay_jar(self,shelter+Vector3(-1.4,0,.5),.32,"a56e48")
	var scare = world.ground(90,49)
	Craft.beam(self,scare,scare+Vector3.UP*2.05,.055,Craft.mat("82623d"))
	Craft.beam(self,scare+Vector3(-.72,1.5,0),scare+Vector3(.72,1.5,0),.04,Craft.mat("9c8251"))
	Craft.box(self,scare+Vector3.UP*1.43,Vector3(.54,.65,.16),Craft.mat("a76841"))
	Craft.sphere(self,scare+Vector3.UP*1.95,Vector3.ONE*.32,Craft.mat("a99767"))
	Craft.cylinder(self,scare+Vector3.UP*2.12,.36,.13,Craft.mat("b9a16a"),.10)

func bund(a: Vector2,b: Vector2,width: float):
	var distance_value = a.distance_to(b)
	var steps = ceili(distance_value)
	for i in steps:
		var p = a.lerp(b,(i+.5)/steps)
		var node = Craft.box(self,world.ground(p.x,p.y,.08),Vector3(width,.15,distance_value/steps+.06),Craft.mat("8d8860"))
		node.rotation.y = atan2(b.x-a.x,b.y-a.y)

static func rice_mesh(variant: int) -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 5:
		var a = i*2.399
		var dir = Vector3(cos(a),0,sin(a))
		var start = dir*.055
		var height_value = .63+(i%3)*.10
		var tip = start+Vector3.UP*height_value+dir*.08
		SceneryArt.leaf(st,start,tip,Vector3(-dir.z,0,dir.x)*.012,Color("739344"),.008)
		for j in 2:
			var base = start+Vector3.UP*(.20+j*.17)
			SceneryArt.leaf(st,base,base+dir*(.24-j*.035)+Vector3.UP*.19,Vector3(-dir.z,0,dir.x)*.029,Color("64923d").lightened(variant*.08),.025)
		for j in 4:
			var grain = tip+dir*j*.025-Vector3.UP*j*j*.009
			SceneryArt.leaf(st,grain,grain+Vector3(.025,-.05,.01),Vector3(0,0,.012),Color("c6b467").lerp(Color("88a34c"),1.0-variant*.38),.009)
	st.generate_normals()
	return st.commit()

func village_people():
	var records: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/villagers.json"))
	for record in records:
		Game.dialogues[record.id] = record.dialogue
		var person = load("res://scripts/npcs/villager.gd").new()
		person.npc_id = record.id
		person.costume = record.costume
		person.tint = record.tint
		person.activity = record.activity
		person.speed_value = float(record.get("speed",.72))
		var p = record.position
		person.position = world.ground(p[0],p[1],.035)
		if record.get("dock",false): person.position.y = 1.25
		for point in record.get("route",[]): person.route.append(world.ground(point[0],point[1],.035))
		add_child(person)
		person.visual.rotation.y = float(record.get("yaw",0.0))
		person.visual.scale = Vector3.ONE*float(record.get("scale",1.0))
		villagers.append(person)

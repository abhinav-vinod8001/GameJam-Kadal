class_name SceneryArt
extends RefCounted

const LEAVES = preload("res://shaders/leaf_canopy.gdshader")

static func foliage() -> ShaderMaterial:
	if not Craft.cache.has("leaf_canopy"):
		var material = ShaderMaterial.new()
		material.shader = LEAVES
		Craft.cache["leaf_canopy"] = material
	return Craft.cache["leaf_canopy"]

static func add_vertex(st: SurfaceTool, p: Vector3, color: Color, uv: Vector2) -> void:
	st.set_color(color)
	st.set_uv(uv)
	st.add_vertex(p)

static func leaf(st: SurfaceTool, start: Vector3, end: Vector3, side: Vector3, color: Color, ridge: float) -> void:
	var center = (start + end) * .5 + Vector3.UP * ridge
	var left = center - side - Vector3.UP * ridge * .4
	var right = center + side - Vector3.UP * ridge * .4
	add_vertex(st,start,color.darkened(.21),Vector2(.5,0))
	add_vertex(st,left,color,Vector2(0,.55))
	add_vertex(st,center,color.lightened(.09),Vector2(.5,.55))
	add_vertex(st,center,color.lightened(.09),Vector2(.5,.55))
	add_vertex(st,left,color,Vector2(0,.55))
	add_vertex(st,end,color.lightened(.21),Vector2(.5,1))
	add_vertex(st,start,color.darkened(.21),Vector2(.5,0))
	add_vertex(st,center,color.lightened(.09),Vector2(.5,.55))
	add_vertex(st,right,color,Vector2(1,.55))
	add_vertex(st,center,color.lightened(.09),Vector2(.5,.55))
	add_vertex(st,end,color.lightened(.21),Vector2(.5,1))
	add_vertex(st,right,color,Vector2(1,.55))

static func palm_crown(variant: int) -> Mesh:
	var key = "palm_crown_" + str(variant)
	if Craft.geometry.has(key): return Craft.geometry[key]
	var rng = RandomNumberGenerator.new()
	rng.seed = 820 + variant
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var palette = [Color("28693f"),Color("3b8440"),Color("559144"),Color("679748")]
	for i in range(14):
		var angle = i * 2.399
		var forward = Vector3(cos(angle), 0, sin(angle))
		var cross = Vector3(-sin(angle), 0, cos(angle))
		var length = rng.randf_range(2.45, 4.5)
		var rise = rng.randf_range(.65, 1.8)
		var droop = rng.randf_range(.9, 2.3)
		var color = palette[i % palette.size()]
		for j in range(12):
			var t = j/12.0
			var a = palm_spine(t,forward,length,rise,droop)
			var b = palm_spine((j+1)/12.0,forward,length,rise,droop)
			leaf(st,a,b,cross*(.075+.135*sin(t*PI)),color,.05)
		for j in range(1,16):
			var t = j / 16.0
			var q = palm_spine(t, forward, length, rise, droop)
			var spread = sin(t * PI) * .8 + .12
			for side in [-1, 1]:
				var end = q + cross * float(side) * spread + forward * (.16 + t * .35)
				end.y -= spread * (.65 + t * .3)
				leaf(st,q,end,forward * .10,color,.065)
		leaf(st,palm_spine(.85,forward,length,rise,droop),palm_spine(1.0,forward,length,rise,droop),cross*.115,color,.05)
	st.generate_normals()
	Craft.geometry[key] = st.commit()
	return Craft.geometry[key]

static func palm_spine(t: float, forward: Vector3, length: float, rise: float, droop: float) -> Vector3:
	return forward * t * length + Vector3.UP * (sin(t * PI) * rise - t * t * droop)

static func crown(variant: int) -> Mesh:
	var key = "canopy_" + str(variant)
	if Craft.geometry.has(key): return Craft.geometry[key]
	var rng = RandomNumberGenerator.new()
	rng.seed = 228 + variant
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var palette = [Color("236749"),Color("327b4b"),Color("47854b"),Color("72a253")]
	for i in 260:
		var angle = rng.randf() * TAU
		var dir = Vector3(cos(angle), 0, sin(angle))
		var radius = sqrt(rng.randf()) * 2.5
		var height = sqrt(1.0 - pow(radius / 2.55, 2.0)) * rng.randf_range(.5, 1.8)
		var start = dir * radius + Vector3.UP * height
		var end = start + dir * rng.randf_range(.38,.92) + Vector3.UP * rng.randf_range(-.42,.25)
		var side = Vector3(-dir.z,0,dir.x) * rng.randf_range(.12,.30)
		leaf(st,start,end,side,palette[rng.randi_range(0,3)],.15)
	st.generate_normals()
	Craft.geometry[key] = st.commit()
	return Craft.geometry[key]

static func grass_clump() -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng = RandomNumberGenerator.new()
	rng.seed = 991
	for i in 8:
		var angle = i * 2.399
		var forward = Vector3(cos(angle),0,sin(angle))
		var side = Vector3(-forward.z,0,forward.x) * rng.randf_range(.026,.065)
		var base = forward * rng.randf_range(.025,.16)
		var tip = base + forward * rng.randf_range(.09,.33) + Vector3.UP * rng.randf_range(.24,.67)
		var middle = base.lerp(tip,.54) + Vector3.UP * .045
		for item in [[base-side,Vector2(0,0)],[middle+side*.66,Vector2(1,.6)],[base+side,Vector2(1,0)],
				[base-side,Vector2(0,0)],[middle-side*.66,Vector2(0,.6)],[middle+side*.66,Vector2(1,.6)],
				[middle-side*.66,Vector2(0,.6)],[tip,Vector2(.5,1)],[middle+side*.66,Vector2(1,.6)]]:
			st.set_uv(item[1])
			st.add_vertex(item[0])
	st.generate_normals()
	return st.commit()

static func roof(parent: Node3D, half_width: float, half_depth: float, eave: float, rise: float) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ridge = maxf(.8, half_width - half_depth * .60)
	var ring = [Vector3(-half_width,eave,-half_depth),Vector3(half_width,eave,-half_depth),
		Vector3(half_width,eave,half_depth),Vector3(-half_width,eave,half_depth)]
	var ridge_points = [Vector3(-ridge,eave+rise,0),Vector3(ridge,eave+rise,0),
		Vector3(ridge,eave+rise,0),Vector3(-ridge,eave+rise,0)]
	var rng = RandomNumberGenerator.new()
	rng.seed = int(half_width * 985 + half_depth * 111)
	for side in 4:
		var next = (side + 1) % 4
		var width = ring[side].distance_to(ring[next])
		var columns = int(ceil(width / .34))
		var rows = int(ceil(ring[side].distance_to(ridge_points[side]) / .43))
		for row in rows:
			var v0 = row / float(rows)
			var v1 = (row + 1) / float(rows)
			for col in columns:
				var u0 = col / float(columns)
				var u1 = (col + 1) / float(columns)
				var um = (u0 + u1) / 2.0
				var a = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],u0,v0)
				var b = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],u1,v0)
				var c = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],u0,v1)
				var d = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],u1,v1)
				var front = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],um,v0) + Vector3.UP * .091
				var back = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],um,v1) + Vector3.UP * .044
				var color = Color("bd6c4a").lerp(Color("8e4a36"),rng.randf() * .85)
				for p in [a,c,front,front,c,back,front,back,b,b,back,d]:
					add_vertex(st,p,color.lightened(.085 if p==front or p==back else -.05),Vector2.ZERO)
	st.generate_normals()
	var roof_mesh = Craft.mesh(parent,st.commit(),Vector3.ZERO,Craft.painted(Color.WHITE,2.0,.18,true))
	roof_mesh.name = "Hand-set terracotta tiles"
	var underlay = PackedVector3Array()
	for side in range(4):
		var next = (side + 1)%4
		for row in range(8):
			var a = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],0,row/8.0)
			var b = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],1,row/8.0)
			var c = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],0,(row+1)/8.0)
			var d = roof_point(ring[side],ring[next],ridge_points[side],ridge_points[next],1,(row+1)/8.0)
			underlay.append_array(PackedVector3Array([a,b,c,b,d,c]))
	var lining = Craft.surface(parent,underlay,Craft.painted(Color("694336"),1.2,.12))
	lining.position.y = -.035
	var trim = Craft.painted(Color("613b2f"),1.2,.3,false,Vector3(.3,4,4))
	for i in 4:
		Craft.beam(parent,ring[i],ring[(i+1)%4],.095,trim)
		Craft.beam(parent,ring[i],ridge_points[i],.11,Craft.mat("8a4e3c"))
	var ridge_span = ridge_points[0].distance_to(ridge_points[1])
	var caps = maxi(3,ceili(ridge_span/.45))
	for i in range(caps):
		var left = ridge_points[0].lerp(ridge_points[1],i/float(caps))
		var right = ridge_points[0].lerp(ridge_points[1],(i+1)/float(caps))
		Craft.beam(parent,left+Vector3.UP*.055,right+Vector3.UP*.055,.142,Craft.mat("ad6146"))
	for p in [ridge_points[0],ridge_points[1]]:
		Craft.cylinder(parent,p + Vector3.UP*.12,.14,.34,Craft.mat("985640"),.035)

static func roof_point(a: Vector3,b: Vector3,c: Vector3,d: Vector3,u: float,v: float) -> Vector3:
	var lower = a.lerp(b,u)
	var upper = c.lerp(d,u)
	var t = .23*v/.46 if v<.46 else lerpf(.23,1.0,(v-.46)/.54)
	var point = lower.lerp(upper,v)
	point.y = lerpf(lower.y,upper.y,t)
	return point

static func awning(parent: Node3D, origin: Vector3, color: Color, width: float = 4.75) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(24):
		for z in range(12):
			for pair in [Vector2i(x,z),Vector2i(x+1,z),Vector2i(x,z+1),
					Vector2i(x+1,z),Vector2i(x+1,z+1),Vector2i(x,z+1)]:
				var uv = Vector2(pair.x/24.0,pair.y/12.0)
				var droop = .37*sin(uv.y*PI) + .08*cos(uv.x*PI) - .27 * pow(absf(uv.y*2.0-1.0),12.0)
				var folds = sin(uv.x*24.0+uv.y*3.8) * .045
				add_vertex(st, Vector3((uv.x-.5)*width,droop+folds,(uv.y-.5)*3.55),Color.WHITE,uv)
	st.generate_normals()
	var fabric = ShaderMaterial.new()
	fabric.shader = preload("res://shaders/market_cloth.gdshader")
	fabric.set_shader_parameter("dye", color)
	Craft.mesh(parent,st.commit(),origin,fabric)
	for z in [-1.72,1.72]:
		Craft.beam(parent,origin+Vector3(-width*.51,-.065,z),origin+Vector3(width*.51,-.065,z),.043,Craft.mat("785536"))

static func river_rock(parent: Node3D, position_value: Vector3, size_value: Vector3, variant: int) -> MeshInstance3D:
	var key = "moss_rock_" + str(variant)
	if not Craft.geometry.has(key):
		var rng = RandomNumberGenerator.new()
		rng.seed = 7239 + variant
		var rings: Array[PackedVector3Array] = []
		for row in range(7):
			var t = row / 6.0
			var ring = PackedVector3Array()
			for j in 14:
				var a = j * TAU / 14.0
				var r = sin(t*PI)*(.46+.07*sin(j*2.7+variant)+rng.randf_range(-.04,.05)) + .008
				ring.append(Vector3(cos(a)*r,t-.5+rng.randf_range(-.045,.045),sin(a)*r))
			rings.append(ring)
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in range(6):
			for j in 14:
				var next = (j+1)%14
				for p in [rings[row][j],rings[row][next],rings[row+1][j],rings[row][next],
						rings[row+1][next],rings[row+1][j]]:
					var moss = smoothstep(.0,.38,p.y+sin(p.x*15+p.z*18)*.12)
					var tint = Color("697877").lerp(Color("6a8850"),moss*.9)
					add_vertex(st,p,tint,Vector2.ZERO)
		st.generate_normals()
		Craft.geometry[key] = st.commit()
	var model = Craft.mesh(parent,Craft.geometry[key],position_value,Craft.painted(Color.WHITE,1.75,.26,true))
	model.scale = size_value
	return model

static func shutter(parent: Node3D, at: Vector3, yaw: float = 0.0) -> void:
	var root = Node3D.new()
	root.position = at
	root.rotation.y = yaw
	parent.add_child(root)
	var teak = Craft.mat("593c2e")
	var edge = Craft.mat("8d6042")
	Craft.box(root,Vector3.ZERO,Vector3(1.16,1.32,.136),teak)
	Craft.box(root,Vector3(0,-.62,-.066),Vector3(1.29,.104,.14),edge)
	for x in [-.537,0.0,.537]:
		Craft.box(root,Vector3(x,0,-.075),Vector3(.065,1.15,.05),edge)
	for i in range(8):
		var y = -.43+i*.125
		var rail = Craft.box(root,Vector3(0,y,-.081),Vector3(1.01,.083,.062),edge)
		rail.rotation.x = .37
	for x in [-.116,.116]:
		Craft.sphere(root,Vector3(x,-.13,-.128),Vector3.ONE*.072,Craft.mat("bf935a",.31))

static func timber_column(parent: Node3D, base: Vector3, height: float, wood: Material) -> void:
	var graphite = Craft.painted(Color("777566"),1.6,.26)
	var dark = Craft.mat("4d352a")
	Craft.box(parent,base+Vector3.UP*.065,Vector3(.43,.13,.43),graphite)
	Craft.box(parent,base+Vector3.UP*.15,Vector3(.33,.06,.33),graphite)
	Craft.cylinder(parent,base+Vector3.UP*(height*.52),.132,height-.36,wood,.096)
	for lift in [.24,.32,height-.37,height-.28]:
		Craft.cylinder(parent,base+Vector3.UP*lift,.145,.053,dark,.133)
	Craft.box(parent,base+Vector3.UP*(height-.17),Vector3(.299,.13,.30),wood)
	Craft.box(parent,base+Vector3.UP*(height-.057),Vector3(.44,.108,.33),dark)
	for side in [-1,1]:
		Craft.beam(parent,base+Vector3(0,height-.43,0),base+Vector3(side*.37,height-.11,0),.058,wood)

static func brass_lantern(parent: Node3D, hook: Vector3, drop: float) -> void:
	var p = hook-Vector3.UP*(drop+.142)
	var brass = Craft.mat("a57945",.31)
	Craft.beam(parent,hook,p+Vector3.UP*.15,.012,Craft.mat("594b38"))
	Craft.cylinder(parent,p+Vector3.UP*.15,.092,.072,brass,.038)
	Craft.cylinder(parent,p-Vector3.UP*.139,.095,.048,brass)
	Craft.cylinder(parent,p,.071,.25,Craft.mat("f5ac53",0,1.6))
	for a in range(6):
		var angle = a*TAU/6.0
		Craft.cylinder(parent,p+Vector3(cos(angle)*.076,0,sin(angle)*.076),.009,.258,brass)

static func spice_basket(parent: Node3D, origin: Vector3, radius: float, fill: Color) -> void:
	if not Craft.cache.has("woven_reed"):
		var material = ShaderMaterial.new()
		material.shader = preload("res://shaders/woven_reed.gdshader")
		Craft.cache["woven_reed"] = material
	var height = radius*.78
	Craft.cylinder(parent,origin+Vector3.UP*(height*.5),radius*.73,height,Craft.cache["woven_reed"],radius)
	Craft.cylinder(parent,origin+Vector3.UP*(height-.01),radius,.045,Craft.mat("b7874b"),radius*.98)
	var pile = Craft.sphere(parent,origin+Vector3.UP*height,Vector3(radius*1.86,radius*.96,radius*1.86),
		Craft.painted(fill,14.0,.36))
	pile.rotation.y = 1.44

static func clay_jar(parent: Node3D, origin: Vector3, radius: float, color: String) -> void:
	var clay = Craft.painted(Color(color),2.2,.19)
	Craft.sphere(parent,origin+Vector3.UP*(radius*1.10),Vector3(radius*2.0,radius*2.25,radius*2.0),clay)
	Craft.cylinder(parent,origin+Vector3.UP*(radius*2.15),radius*.48,radius*.38,clay,radius*.52)
	Craft.cylinder(parent,origin+Vector3.UP*(radius*2.34),radius*.63,radius*.15,clay,radius*.63)
	Craft.cylinder(parent,origin+Vector3.UP*(radius*2.418),radius*.48,radius*.022,Craft.mat("40332b"))
	Craft.cylinder(parent,origin+Vector3.UP*(radius*1.54),radius*.944,radius*.08,Craft.mat("c59a6c"),radius*.929)

static func bamboo_pole(parent: Node3D, position_value: Vector3, height: float) -> void:
	Craft.cylinder(parent,position_value+Vector3.UP*(height*.5),.061,height,Craft.mat("ae8954"),.043)
	for y in [.34,1.04,1.77,2.55]:
		Craft.cylinder(parent,position_value+Vector3.UP*y,.069,.043,Craft.mat("c6a170"),.069)
	for y in [height-.31,height-.26,height-.21]:
		Craft.cylinder(parent,position_value+Vector3.UP*y,.074,.025,Craft.mat("796044"))

static func palm_trunk() -> Mesh:
	var key = "arched_coconut_trunk"
	if Craft.geometry.has(key): return Craft.geometry[key]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(24):
		for j in range(12):
			for ij in [Vector2i(row,j),Vector2i(row,j+1),Vector2i(row+1,j),
					Vector2i(row,j+1),Vector2i(row+1,j+1),Vector2i(row+1,j)]:
				var t = ij.x/24.0
				var a = (ij.y%12)*TAU/12.0
				var r = lerpf(.265,.125,t) + .016*(1.0-t)*sin(t*TAU*8.0)
				var center = Vector3(.93*sin(t*2.18)+t*.48,t*7.4,t*t*.17)
				var tint = Color("77664a").lerp(Color("bba071"),.42+.12*sin(ij.x*1.77)+.10*sin(a))
				add_vertex(st,center+Vector3(cos(a)*r,0,sin(a)*r),tint,Vector2(ij.y/12.0,t))
	st.generate_normals()
	Craft.geometry[key] = st.commit()
	return Craft.geometry[key]

static func vilakku(parent: Node3D, p: Vector3, lit: bool) -> void:
	var stone = Craft.painted(Color("747d6e"),2.1,.34)
	var edge = Craft.painted(Color("a29671"),2.2,.25)
	var brass = Craft.mat("ac8452",.29)
	Craft.box(parent,p+Vector3.UP*.052,Vector3(.63,.105,.63),stone)
	Craft.box(parent,p+Vector3.UP*.138,Vector3(.53,.084,.53),edge)
	Craft.box(parent,p+Vector3.UP*.23,Vector3(.42,.103,.42),stone)
	Craft.box(parent,p+Vector3.UP*.54,Vector3(.309,.57,.309),stone)
	for y in [.3,.77,.846]:
		Craft.box(parent,p+Vector3.UP*y,Vector3(.409,.069,.409),edge)
	Craft.box(parent,p+Vector3.UP*.920,Vector3(.50,.069,.50),stone)
	Craft.cylinder(parent,p+Vector3.UP*1.124,.098,.338,Craft.mat("eea84e",0,1.38))
	for x in [-.16,.16]:
		for z in [-.16,.16]:
			Craft.box(parent,p+Vector3(x,1.118,z),Vector3(.066,.331,.066),stone)
	Craft.box(parent,p+Vector3.UP*1.30,Vector3(.54,.055,.54),edge)
	var roof = Craft.cylinder(parent,p+Vector3.UP*1.391,.385,.17,stone,.137)
	roof.rotation.y = PI/4
	Craft.cylinder(parent,p+Vector3.UP*1.50,.133,.075,brass,.092)
	Craft.sphere(parent,p+Vector3.UP*1.606,Vector3(.099,.19,.099),Craft.mat("ffd184",0,2.3))
	if lit:
		var glow = OmniLight3D.new()
		glow.name = "Vilakku amber bounce"
		glow.position = p+Vector3.UP*1.28
		glow.light_color = Color("ffac53")
		glow.light_energy = .48
		glow.omni_range = 2.7
		glow.omni_attenuation = 1.65
		glow.shadow_enabled = false
		parent.add_child(glow)

static func ruin_column(parent: Node3D, p: Vector3, stone: Material, trim: Material) -> void:
	for setting in [[.34,1.17,.17],[.49,1.04,.13],[.61,.938,.12],[3.04,.97,.105],
			[3.14,1.04,.12],[3.40,1.21,.148],[3.51,1.30,.11]]:
		Craft.box(parent,p+Vector3.UP*setting[0],Vector3(setting[1],setting[2],setting[1]),trim)
	Craft.cylinder(parent,p+Vector3.UP*3.272,.451,.21,stone,.605)
	for axis in range(4):
		var angle = axis*PI*.5
		var normal = Vector3(cos(angle),0,sin(angle))
		var medallion = Craft.cylinder(parent,p+Vector3.UP*2.69+normal*.434,.139,.034,trim,.128)
		medallion.quaternion = Quaternion(Vector3.UP,normal)
		var inset = Craft.cylinder(parent,p+Vector3.UP*2.69+normal*.454,.086,.02,stone)
		inset.quaternion = Quaternion(Vector3.UP,normal)

static func hanging_vines(parent: Node3D, origin: Vector3, size_value: float) -> void:
	var vine = Craft.mat("4c6038")
	var leaf_mesh = SurfaceTool.new()
	leaf_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(5):
		var x = (float(i)-2.0)*.194
		var length_value = size_value*(.57+.40*sin(i*1.9+1.0)*.5+.19)
		var last = origin+Vector3(x,0,0)
		for j in range(1,8):
			var t = j/7.0
			var next = origin+Vector3(x+sin(t*4.1+i)*.11*t,-length_value*t,sin(t*6.0+i)*.09)
			Craft.beam(parent,last,next,.013*(1.05-.34*t),vine)
			last = next
			if j%2==0:
				var side = -1 if (j/2+i)%2==0 else 1
				leaf(leaf_mesh,next,next+Vector3(side*.155,-.12,.045),Vector3(.026,-side*.041,.017),Color("648646"),.04)
	leaf_mesh.generate_normals()
	var model = Craft.mesh(parent,leaf_mesh.commit(),Vector3.ZERO,foliage())
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func canopy_mass(color: String) -> ShaderMaterial:
	var key = "canopy_mass_" + color
	if not Craft.cache.has(key):
		var material = foliage().duplicate() as ShaderMaterial
		material.set_shader_parameter("use_vertex_color", false)
		material.set_shader_parameter("pigment", Color(color))
		material.set_shader_parameter("rim", .065)
		material.set_shader_parameter("wind", .09)
		Craft.cache[key] = material
	return Craft.cache[key]

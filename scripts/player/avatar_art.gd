class_name AvatarArt
extends RefCounted

# Profiles are [height, half width, half depth, center depth], bottom to top.
# Build UV-coherent rings so shading flows across the seams.
static func profile(parent: Node3D, key: String, rings: Array, mat: Material, segments: int = 24, pleats: float = 0.0) -> MeshInstance3D:
	key = "avatar_" + key
	if not Craft.geometry.has(key):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for y in range(rings.size()-1):
			for j in segments:
				for pair in [Vector2i(y,j),Vector2i(y,j+1),Vector2i(y+1,j),
						Vector2i(y,j+1),Vector2i(y+1,j+1),Vector2i(y+1,j)]:
					var theta = (pair.y % segments) * TAU / segments
					var r: Array = rings[pair.x]
					var fold = 1.0 + sin(theta*7.0+pair.x*.14)*pleats
					st.add_vertex(Vector3(cos(theta)*r[1]*fold,r[0],sin(theta)*r[2]*fold+r[3]))
		st.generate_normals()
		Craft.geometry[key] = st.commit()
	return Craft.mesh(parent,Craft.geometry[key],Vector3.ZERO,mat)

static func ellipsoid(parent: Node3D, p: Vector3, size_value: Vector3, mat: Material) -> MeshInstance3D:
	if not Craft.geometry.has("rounded_detail"):
		var sphere = SphereMesh.new()
		sphere.radial_segments = 20
		sphere.rings = 12
		Craft.geometry["rounded_detail"] = sphere
	var n = Craft.mesh(parent,Craft.geometry["rounded_detail"],p,mat)
	n.scale = size_value
	return n

static func angled(parent: Node3D, a: Vector3, b: Vector3, width: float, depth: float, mat: Material) -> MeshInstance3D:
	var n = ellipsoid(parent,(a+b)*.5,Vector3(width,a.distance_to(b)+width*.35,depth),mat)
	n.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return n

static func body(hips: Node3D, torso: Node3D, tint: String, role: String, skin: Material) -> void:
	var enemy = role == "raider"
	var linen = Craft.mat("9d4f37" if enemy else tint)
	var trim = Craft.mat("d6a660" if not enemy else "bf7747")
	var lower = Craft.mat("e1cba0" if not enemy else "5a3930")
	var leather = Craft.mat("47302b")
	var sari = role in ["meera","amma","fish"]
	var bare = role in ["arun","ravi","guru","smith"]
	var sash_color = {"arun":"2554b1","ravi":"42667b","guru":"c68338","smith":"735141",
		"meera":"ead4a5","amma":"e4cea5","fish":"eddbb9","raider":"54362b"}[role]
	var sash = Craft.mat(sash_color)
	var border = Craft.mat("d9ad56" if sari or role=="guru" else ("5284cb" if role=="arun" else "ae7e52"))
	var shirt = [[.79,.188,.138,0],[.94,.185,.145,0],[1.15,.228,.157,.012],
		[1.32,.261,.163,.013],[1.43,.244,.141,.008],[1.51,.11,.103,0],[1.575,.071,.073,0],[1.595,.007,.01,0]]
	profile(torso,"tunic",shirt,skin if bare else linen,28,.012)
	mundu(hips,role,lower,trim)
	profile(hips,"belt",[[.804,.229,.168,0],[.813,.249,.172,0],[.876,.247,.172,0],[.893,.225,.169,0]],leather)
	profile(hips,"belt_binding",[[.811,.252,.176,0],[.826,.252,.176,0]],trim)
	ellipsoid(hips,Vector3(.08,.851,-.17),Vector3(.148,.103,.064),Craft.mat("c59151",.27))
	ellipsoid(hips,Vector3(.08,.851,-.205),Vector3(.059,.05,.013),Craft.mat("efe0b1"))
	# Sample the same torso profile so the cloth stays outside the tunic.
	var double_sided = sash.duplicate() as StandardMaterial3D
	double_sided.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1,1]:
		var panel = PackedVector3Array()
		for row in range(13):
			for col in range(5):
				panel.append(sash_point(shirt,row/12.0,col/4.0,side))
		var faces = PackedVector3Array()
		for row in range(12):
			for col in range(4):
				var i = row*5+col
				faces.append_array(PackedVector3Array([panel[i],panel[i+5],panel[i+1],panel[i+1],panel[i+5],panel[i+6]]))
		Craft.surface(torso,faces,double_sided)
		for col in [0,4]:
			for row in range(12):
				var i = row*5+col
				var offset = Vector3(0,0,side*.005)
				Craft.beam(torso,panel[i]+offset,panel[i+5]+offset,.0055,border)
	if enemy:
		profile(torso,"raider_collar",[[1.425,.136,.116,0],[1.493,.112,.099,0]],Craft.mat("573b32"))
	var pouch = ellipsoid(hips,Vector3(-.205,.782,.131),Vector3(.183,.232,.142),Craft.mat("65442e"))
	pouch.rotation.z = -.22
	ellipsoid(hips,Vector3(-.211,.812,.201),Vector3(.133,.018,.018),trim)

static func sash_point(shirt: Array, t: float, u: float, side: int) -> Vector3:
	var y = lerpf(1.477,.861,t)
	var center = lerpf(-.160,.133,t)
	var half_width = .089 - .045*pow(1.0-t,7.0)
	var x = center + (u*2.0-1.0)*half_width
	for i in range(shirt.size()-1):
		var lo: Array = shirt[i]
		var hi: Array = shirt[i+1]
		if y < lo[0] or y > hi[0]: continue
		var w = inverse_lerp(lo[0],hi[0],y)
		var radius = lerpf(lo[1],hi[1],w)
		var depth = lerpf(lo[2],hi[2],w)
		var z = lerpf(lo[3],hi[3],w)
		var curve = sqrt(maxf(0.0,1.0 - pow(x/radius,2.0)))
		return Vector3(x,y,z + side*(depth*curve*.99+.019))
	return Vector3(x,y,side*.17)

static func face(head: Node3D, skin: Material, role: String) -> void:
	var enemy = role == "raider"
	var elder = role in ["guru","amma"]
	var sari = role in ["meera","fish","amma"]
	var ink = Craft.mat("182327")
	var hair = Craft.mat("b5b6b0" if elder else "19282f")
	var light_hair = Craft.mat("dee0d8" if elder else "314148")
	profile(head,"face",[
		[-.197,.024,.035,-.048],[-.18,.084,.087,-.028],[-.128,.131,.108,-.013],
		[-.071,.156,.128,0],[.012,.164,.139,.006],[.093,.164,.144,.009],
		[.157,.142,.132,.016],[.194,.095,.102,.024],[.211,.012,.024,.022]],skin,32)
	ellipsoid(head,Vector3(0,-.076,-.13),Vector3(.046,.073,.056),skin)
	ellipsoid(head,Vector3(0,-.133,-.122),Vector3(.064,.012,.019),Craft.mat("874b45"))
	for side in [-1,1]:
		var x = side*.158
		ellipsoid(head,Vector3(x,-.04,.006),Vector3(.073,.11,.063),skin)
		ellipsoid(head,Vector3(x+side*.025,-.043,-.022),Vector3(.022,.05,.013),Craft.mat("a66450"))
		var eye = ellipsoid(head,Vector3(side*.079,-.026,-.122),Vector3(.081,.035,.022),ink)
		eye.rotation.z = side*.11
		ellipsoid(head,Vector3(side*.079,-.029,-.134),Vector3(.066,.024,.013),Craft.mat("f0ddbe"))
		ellipsoid(head,Vector3(side*.076,-.027,-.143),Vector3(.025,.025,.011),Craft.mat("34454b"))
		ellipsoid(head,Vector3(side*.076+.004,-.019,-.150),Vector3(.010,.009,.003),Craft.mat("fff2d6"))
		var brow = ellipsoid(head,Vector3(side*.080,.021,-.131),Vector3(.091,.018,.025),ink)
		brow.rotation.z = side*.15
		if not enemy:
			ellipsoid(head,Vector3(side*.176,-.082,-.022),Vector3(.035,.050,.026),Craft.mat("d8ac62",.45))
	profile(head,"hair_mass",[[-.123,.116,.085,.097],[-.068,.161,.133,.065],[.025,.187,.152,.045],
		[.122,.183,.166,.026],[.192,.145,.133,.019],[.235,.089,.102,.022],[.258,.012,.025,.028]],hair,32)
	# Layered locks form a sloping fringe and fan out toward the nape.
	for i in range(7):
		var x = -.135+i*.041
		var a = Vector3(x*.79-.019,.16+sin(i*.38)*.064,-.062)
		var b = Vector3(x+.041,.019+sin(i*.46)*.072,-.15+absf(x)*.23)
		angled(head,a,b,.063,.056,light_hair if i==3 else hair)
	for side in [-1,1]:
		angled(head,Vector3(side*.144,.134,.032),Vector3(side*.157,-.084,.053),.071,.089,hair)
	angled(head,Vector3(-.049,.19,.09),Vector3(-.107,.035,.169),.098,.09,light_hair)
	if role in ["arun","raider","ravi","smith"]:
		var band = Craft.mat({"arun":"3b4750","raider":"84573e","ravi":"526a66","smith":"77583e"}[role])
		# Keep the cloth outside the fringe so the band reads from the front.
		profile(head,"tied_headband",[[.040,.183,.194,.006],[.085,.193,.202,.009],[.109,.188,.196,.012]],band,32)
		ellipsoid(head,Vector3(.008,.077,.222),Vector3(.102,.071,.057),band)
		for side in [-1,1]:
			angled(head,Vector3(.008,.068,.225),Vector3(side*.061,-.124,.221),
				.059,.021,band)
	if sari or role=="guru":
		ellipsoid(head,Vector3(0,.025,.184),Vector3(.211,.219,.172),hair)
	if sari:
		ellipsoid(head,Vector3(0,.034,-.142),Vector3(.023,.023,.011),Craft.mat("a0352d"))
		if not elder:
			for i in range(7):
				ellipsoid(head,Vector3(.071,.136-i*.024,.208+sin(i*.37)*.06),
					Vector3.ONE*.044,Craft.mat("f1e6b7"))
	if role in ["ravi","guru"]:
		for side in [-1,1]:
			angled(head,Vector3(0,-.104,-.142),Vector3(side*.059,-.117,-.128),
				.026,.02,hair)
	if role=="guru":
		ellipsoid(head,Vector3(0,-.152,-.101),Vector3(.161,.159,.098),light_hair)
		ellipsoid(head,Vector3(0,.247,.067),Vector3(.129,.116,.113),hair)

static func arm(pivot: Node3D, skin: Material, tint: String, role: String) -> Node3D:
	var enemy = role == "raider"
	var bare = role in ["arun","ravi","guru","smith"]
	var fabric = skin if bare else Craft.mat("9d4f37" if enemy else tint)
	var trim = Craft.mat("c28e58")
	profile(pivot,"sleeve",[[-.24,.082,.087,-.009],[-.209,.102,.103,0],[-.11,.111,.112,.005],
		[-.032,.106,.111,.012],[.031,.069,.077,.003],[.044,.011,.012,0]],fabric)
	if not bare:
		profile(pivot,"sleeve_edge",[[-.232,.089,.094,-.007],[-.207,.104,.108,0]],trim)
	var elbow = Node3D.new()
	elbow.name = "Elbow"
	elbow.position = Vector3(0,-.238,-.012)
	pivot.add_child(elbow)
	var detail = Node3D.new()
	detail.name = "Art"
	detail.position = -elbow.position
	elbow.add_child(detail)
	profile(detail,"forearm",[[-.52,.05,.054,-.045],[-.43,.062,.068,-.036],[-.33,.075,.074,-.016],
		[-.26,.078,.079,-.007],[-.201,.084,.082,0]],skin)
	profile(detail,"bracer",[[-.511,.053,.06,-.043],[-.481,.069,.074,-.047],[-.379,.078,.078,-.032],
		[-.343,.065,.070,-.023]],Craft.mat("483835" if enemy else "344743"))
	for item in [[-.482,.069,-.047],[-.391,.079,-.034]]:
		profile(detail,"bracer_trim_"+str(item[0]),[[item[0]-.009,item[1],item[1],item[2]],
			[item[0]+.009,item[1],item[1],item[2]]],trim)
	ellipsoid(detail,Vector3(0,-.541,-.051),Vector3(.104,.119,.104),skin)
	ellipsoid(detail,Vector3(-.037,-.535,-.084),Vector3(.042,.08,.055),skin)
	bake_joint(detail)
	return elbow

static func leg(pivot: Node3D, skin: Material, tint: String) -> Node3D:
	profile(pivot,"trousers",[[-.326,.072,.073,.005],[-.285,.084,.092,-.009],[-.16,.114,.108,.012],
		[-.024,.116,.104,.02],[.052,.02,.022,0]],Craft.mat(tint))
	var knee = Node3D.new()
	knee.name = "Knee"
	knee.position = Vector3(0,-.30,0)
	pivot.add_child(knee)
	var detail = Node3D.new()
	detail.name = "Art"
	detail.position = -knee.position
	knee.add_child(detail)
	profile(detail,"shin",[[-.61,.049,.06,.008],[-.512,.049,.057,.004],[-.43,.064,.073,.022],
		[-.35,.079,.086,.007],[-.279,.077,.08,-.011]],skin)
	profile(detail,"leg_wrap",[[-.606,.055,.066,.008],[-.528,.057,.067,.004],[-.503,.053,.058,0]],Craft.mat("a88c66"))
	ellipsoid(detail,Vector3(0,-.618,-.045),Vector3(.138,.092,.257),Craft.mat("665044"))
	ellipsoid(detail,Vector3(0,-.605,-.105),Vector3(.119,.051,.129),skin)
	for z in [-.065,-.103]:
		ellipsoid(detail,Vector3(0,-.594,z),Vector3(.129,.051,.05),Craft.mat("523e35"))
	bake_joint(detail)
	return knee

static func blade(parent: Node3D, length_value: float, width: float, curve: float, steel: Material, leaf_tip: bool = false) -> void:
	var key = "forged_blade_" + str([length_value,width,curve,leaf_tip])
	if not Craft.geometry.has(key):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rings: Array[PackedVector3Array] = []
		for i in 8:
			var t = i / 7.0
			var x = curve*t*t
			var z = -length_value*t
			var width_factor = (1.0-.19*t) * (1.0-smoothstep(.69,1.01,t))
			if leaf_tip:
				width_factor = sin(t*PI) * (1.25-.48*t) + .20*(1.0-t)
			var r = width * width_factor + .001
			rings.append(PackedVector3Array([Vector3(x-r,0,z),Vector3(x,.018*(1.0-t)+.003,z),
				Vector3(x+r,0,z),Vector3(x,-.018*(1.0-t)-.003,z)]))
		for i in range(7):
			for j in 4:
				var k = (j+1)%4
				for p in [rings[i][j],rings[i][k],rings[i+1][j],rings[i][k],rings[i+1][k],rings[i+1][j]]:
					st.add_vertex(p)
		st.generate_normals()
		Craft.geometry[key] = st.commit()
	var material = steel.duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	Craft.mesh(parent,Craft.geometry[key],Vector3.ZERO,material)

# Each rigid joint keeps its own transform. Merge only its visual pieces, leaving
# the named animation pivots and the weapon / shield attachment points separate.
static func bake_joint(joint: Node3D) -> void:
	if DisplayServer.get_name() == "headless": return
	if not Craft.cache.has("avatar_vertex_paint"):
		var mat = ShaderMaterial.new()
		mat.shader = preload("res://shaders/inked_character.gdshader")
		Craft.cache["avatar_vertex_paint"] = mat
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count = 0
	for child in joint.get_children():
		if not child is MeshInstance3D or not child.material_override is StandardMaterial3D: continue
		var mat: StandardMaterial3D = child.material_override
		var transform_value: Transform3D = child.transform
		var normal_basis = transform_value.basis.inverse().transposed()
		for surface in child.mesh.get_surface_count():
			var data = child.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
			var indices = data[Mesh.ARRAY_INDEX]
			if indices == null or indices.is_empty():
				for i in vertices.size():
					st.set_color(mat.albedo_color)
					st.set_normal((normal_basis * normals[i]).normalized())
					st.add_vertex(transform_value * vertices[i])
			else:
				for i in indices:
					st.set_color(mat.albedo_color)
					st.set_normal((normal_basis * normals[i]).normalized())
					st.add_vertex(transform_value * vertices[i])
			count += vertices.size()
		child.free()
	if count > 0:
		st.index()
		Craft.mesh(joint,st.commit(),Vector3.ZERO,Craft.cache["avatar_vertex_paint"])

static func mundu(hips: Node3D, role: String, cloth: Material, gold: Material) -> void:
	var length_value = .22 if role in ["meera","fish","amma"] else (.43 if role=="raider" else .35)
	var key = "mundu_" + str(length_value)
	if not Craft.geometry.has(key):
		var fabric = SurfaceTool.new()
		var kasavu = SurfaceTool.new()
		fabric.begin(Mesh.PRIMITIVE_TRIANGLES)
		kasavu.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in range(40):
			for r in range(8):
				for corner in [Vector2i(j,r),Vector2i(j+1,r),Vector2i(j,r+1),
						Vector2i(j+1,r),Vector2i(j+1,r+1),Vector2i(j,r+1)]:
					var a = (corner.x%40)*TAU/40.0
					var t = corner.y/8.0
					# The front fold rises between the knees and falls at either side.
					var front = maxf(0.0,-sin(a))
					var hem = length_value+.125*pow(front,10.0)
					var pleat = sin(a*9.0+t*1.8)*.018*t+sin(a*5.0)*.012
					var x = cos(a)*(.212+t*.093+pleat)
					var z = sin(a)*(.156+t*.050+pleat)+.012
					var p = Vector3(x,lerpf(.858,hem,t),z)
					if r==7 or j==27:
						kasavu.add_vertex(p)
					else:
						fabric.add_vertex(p)
		fabric.generate_normals()
		kasavu.generate_normals()
		Craft.geometry[key] = fabric.commit()
		Craft.geometry[key+"_trim"] = kasavu.commit()
	Craft.mesh(hips,Craft.geometry[key],Vector3.ZERO,cloth)
	Craft.mesh(hips,Craft.geometry[key+"_trim"],Vector3.ZERO,gold)
	# A second diagonal wrap overlaps the base cloth, with a continuous kasavu hem.
	var drape = SurfaceTool.new()
	var edging = SurfaceTool.new()
	drape.begin(Mesh.PRIMITIVE_TRIANGLES)
	edging.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(10):
		for col in range(14):
			for pair in [Vector2i(col,row),Vector2i(col+1,row),Vector2i(col,row+1),
					Vector2i(col+1,row),Vector2i(col+1,row+1),Vector2i(col,row+1)]:
				var u = pair.x/14.0
				var v = pair.y/10.0
				var a = lerpf(-PI*.92,-PI*.08,u)
				var bottom = lerpf(length_value+.055,length_value+.30,u)
				var y = lerpf(.843,bottom,v)
				var radius = .228+v*.081+sin(u*PI*6.0+v)*.009*v
				var depth = .168+v*.044
				var z = sin(a)*depth-.020
				var position_value = Vector3(cos(a)*radius,y,z)
				if row == 9:
					edging.add_vertex(position_value)
				else:
					drape.add_vertex(position_value)
	drape.generate_normals()
	edging.generate_normals()
	var two_sided = cloth.duplicate() as StandardMaterial3D
	two_sided.cull_mode = BaseMaterial3D.CULL_DISABLED
	var gold_two_sided = gold.duplicate() as StandardMaterial3D
	gold_two_sided.cull_mode = BaseMaterial3D.CULL_DISABLED
	Craft.mesh(hips,drape.commit(),Vector3.ZERO,two_sided)
	Craft.mesh(hips,edging.commit(),Vector3.ZERO,gold_two_sided)

static func paricha(shield: Node3D) -> void:
	var brass = Craft.mat("c5974e",.32)
	var teak = Craft.mat("634433")
	var lacquer = Craft.mat("904736")
	var hull = profile(shield,"paricha_body",[[-.035,.28,.28,0],[.005,.296,.296,0],
		[.044,.267,.267,0],[.077,.193,.193,0],[.096,.077,.077,0],[.098,.012,.012,0]],teak,40)
	hull.rotation.x = -PI/2
	var rim = profile(shield,"paricha_rim",[[-.026,.281,.281,0],[.0,.304,.304,0],
		[.025,.303,.303,0],[.048,.277,.277,0],[.026,.268,.268,0]],brass,40)
	rim.rotation.x = -PI/2
	for i in range(12):
		var angle = i*TAU/12.0
		var d = Vector3(cos(angle),sin(angle),0)
		ellipsoid(shield,d*.281+Vector3(0,0,-.038),Vector3(.024,.024,.021),brass)
		if i%3==1:
			angled(shield,d*.095+Vector3(0,0,-.097),d*.242+Vector3(0,0,-.064),.052,.027,lacquer)
			ellipsoid(shield,d*.195+Vector3(0,0,-.085),Vector3.ONE*.033,brass)
	ellipsoid(shield,Vector3(0,0,-.092),Vector3(.212,.212,.066),brass)
	ellipsoid(shield,Vector3(0,0,-.126),Vector3(.15,.15,.116),Craft.mat("edba64",.32))
	bake_joint(shield)

static func npc_accessory(hand: Node3D, role: String) -> void:
	var wood = Craft.mat("81543a")
	var metal = Craft.mat("605c5e",.18)
	match role:
		"ravi":
			Craft.beam(hand,Vector3(0,-.04,-.06),Vector3(.03,-.91,-.08),.024,wood)
			angled(hand,Vector3(.03,-.88,-.08),Vector3(.07,-1.20,-.10),.112,.035,wood)
		"guru":
			Craft.beam(hand,Vector3(.031,-.05,-.10),Vector3(.071,-1.24,-.13),.019,wood)
		"smith":
			Craft.beam(hand,Vector3(.012,-.43,-.076),Vector3(.015,-.78,-.104),.024,wood)
			Craft.box(hand,Vector3(.015,-.76,-.11),Vector3(.18,.072,.084),metal)

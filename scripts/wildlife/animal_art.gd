class_name AnimalArt
extends RefCounted

static func rounded(root: Node3D,p: Vector3,size_value: Vector3,color: String) -> MeshInstance3D:
	return AvatarArt.ellipsoid(root,p,size_value,Craft.mat(color))

static func pivot(root: Node3D,p: Vector3,label: String) -> Node3D:
	var node = Node3D.new()
	node.name = label
	node.position = p
	root.add_child(node)
	return node

static func tube(root: Node3D,a: Vector3,b: Vector3,radius: float,color: String):
	Craft.beam(root,a,b,radius,Craft.mat(color))

static func ear(root: Node3D,at: Vector3,size_value: Vector3,color: String,inner: String) -> Node3D:
	var node = pivot(root,at,"Ear")
	var w = size_value.x*.5
	var h = size_value.y
	var d = size_value.z
	var material = Craft.mat(color).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	Craft.surface(node,PackedVector3Array([Vector3(-w,0,0),Vector3(w,0,0),Vector3(0,h,d),
		Vector3(w,0,0),Vector3(-w,0,0),Vector3(0,h,-d)]),material)
	rounded(node,Vector3(0,h*.35,-d*.4-.005),Vector3(w*1.0,h*.45,.015),inner)
	return node

static func build(animal: Node3D,kind: String,variant: int) -> Dictionary:
	var body = pivot(animal,Vector3.ZERO,"Body")
	var head: Node3D
	var neck: Node3D
	var legs: Array[Node3D] = []
	var knees: Array[Node3D] = []
	var ears: Array[Node3D] = []
	var trunk: Array[Node3D] = []
	var tail: Array[Node3D] = []
	var joints: Array[Node3D] = [body]
	var shoulder = .0
	var hip = .0
	var leg_height = .0
	var coat = "b38457"
	var lower = "dfc49d"
	var width = .0
	if kind=="cat":
		coat = ["b77b49","666e73","ece1ca","584839"][variant%4]
		lower = "eee1c8"
		width = .125
		shoulder = -.22
		hip = .21
		leg_height = .28
		rounded(body,Vector3(0,.39,0),Vector3(.29,.32,.68),coat)
		rounded(body,Vector3(0,.33,-.18),Vector3(.24,.23,.26),lower)
		head = pivot(body,Vector3(0,.53,-.38),"Head")
		rounded(head,Vector3.ZERO,Vector3(.28,.26,.25),coat)
		rounded(head,Vector3(0,-.055,-.12),Vector3(.16,.095,.12),lower)
		for side in [-1,1]:
			ears.append(ear(head,Vector3(side*.09,.08,.015),Vector3(.13,.18,.025),coat,"bd8f83"))
			rounded(head,Vector3(side*.068,.024,-.115),Vector3(.052,.046,.021),"b3bc71")
			rounded(head,Vector3(side*.068,.024,-.128),Vector3(.013,.037,.008),"17282a")
			for i in 3: tube(head,Vector3(side*.055,-.054,-.16),Vector3(side*(.21+i*.008),-.05+(i-1)*.024,-.14),.002,"d8d2bf")
		rounded(head,Vector3(0,-.043,-.184),Vector3(.031,.025,.018),"aa7871")
		for z in [-.08,.04,.16]: rounded(body,Vector3(0,.535,z),Vector3(.27,.028,.063),coat if variant==2 else "66503b")
		var current = pivot(body,Vector3(0,.44,.30),"Tail")
		for i in 5:
			tail.append(current)
			var next = Vector3(0,.07,.11)
			tube(current,Vector3.ZERO,next,.028-i*.003,coat)
			current = pivot(current,next,"Tail joint")
	elif kind=="dog":
		coat = ["ba915e","ece0c4","554b40"][variant%3]
		lower = "ece0c7"
		width = .19
		shoulder = -.32
		hip = .30
		leg_height = .48
		rounded(body,Vector3(0,.64,0),Vector3(.43,.49,.99),coat)
		rounded(body,Vector3(0,.62,-.29),Vector3(.36,.47,.40),lower)
		head = pivot(body,Vector3(0,.88,-.53),"Head")
		rounded(head,Vector3.ZERO,Vector3(.37,.35,.37),coat)
		rounded(head,Vector3(0,-.065,-.23),Vector3(.22,.18,.31),lower)
		rounded(head,Vector3(0,-.035,-.39),Vector3(.13,.10,.064),"26302c")
		for side in [-1,1]:
			ears.append(ear(head,Vector3(side*.14,.10,.025),Vector3(.19,.24,.06),coat,"ac8575"))
			rounded(head,Vector3(side*.12,.045,-.145),Vector3(.064,.065,.032),"eee1c9")
			rounded(head,Vector3(side*.12,.045,-.165),Vector3(.039,.045,.020),"24312d")
			rounded(head,Vector3(side*.123,.058,-.176),Vector3(.012,.013,.009),"f5eddb")
		rounded(head,Vector3(0,-.14,-.26),Vector3(.07,.036,.13),"b67c76")
		var current = pivot(body,Vector3(0,.75,.43),"Tail")
		for i in 4:
			tail.append(current)
			var next = Vector3(0,.10,.13)
			tube(current,Vector3.ZERO,next,.047-i*.008,coat)
			current = pivot(current,next,"Tail joint")
	elif kind=="deer":
		coat = "a87743" if variant%2==0 else "ba8c57"
		lower = "ead4ac"
		width = .23
		shoulder = -.38
		hip = .42
		leg_height = .91
		rounded(body,Vector3(0,1.19,.02),Vector3(.52,.65,1.35),coat)
		rounded(body,Vector3(0,1.03,0),Vector3(.42,.25,.95),lower)
		neck = pivot(body,Vector3(0,1.23,-.40),"Neck")
		AvatarArt.angled(neck,Vector3.ZERO,Vector3(0,.64,-.25),.30,.34,Craft.mat(coat))
		head = pivot(neck,Vector3(0,.69,-.37),"Head")
		joints.append(neck)
		rounded(head,Vector3.ZERO,Vector3(.29,.37,.43),coat)
		rounded(head,Vector3(0,-.10,-.22),Vector3(.20,.18,.30),lower)
		rounded(head,Vector3(0,-.075,-.375),Vector3(.12,.08,.08),"3c3830")
		for side in [-1,1]:
			var e = ear(head,Vector3(side*.15,.12,.06),Vector3(.19,.35,.04),coat,"d4ba92")
			e.rotation.z = -side*.57
			ears.append(e)
			rounded(head,Vector3(side*.132,.035,-.09),Vector3(.055,.065,.055),"2c3029")
			rounded(head,Vector3(side*.151,.052,-.116),Vector3(.012,.016,.012),"eee2bf")
			if variant%3==0:
				var previous = Vector3(side*.09,.14,.03)
				for i in 3:
					var next = Vector3(side*(.10+i*.095),.34+i*.20,.06+i*.045)
					tube(head,previous,next,.025-i*.004,"c5b38a")
					tube(head,next,next+Vector3(-side*.04,.14,-.14),.014,"c5b38a")
					previous = next
			for i in 9:
				rounded(body,Vector3(side*(.235+sin(i)*.008),1.13+(i%3)*.14,-.35+floorf(i/3.0)*.30),Vector3(.025,.055,.085),"e4d2a4")
		var t = pivot(body,Vector3(0,1.36,.64),"Tail")
		rounded(t,Vector3(0,-.04,.08),Vector3(.11,.22,.15),lower)
		tail.append(t)
	else:
		coat = "777d75" if variant==0 else "8a8b7d"
		lower = "a5a18b"
		width = .65
		shoulder = -.80
		hip = .82
		leg_height = 1.49
		rounded(body,Vector3(0,2.02,0),Vector3(1.67,1.84,2.88),coat)
		rounded(body,Vector3(0,2.48,-.36),Vector3(1.42,1.05,1.63),coat)
		head = pivot(body,Vector3(0,2.44,-1.42),"Head")
		rounded(head,Vector3(0,.03,0),Vector3(1.12,1.26,.98),coat)
		for side in [-1,1]:
			rounded(head,Vector3(side*.23,.48,-.08),Vector3(.54,.43,.59),coat)
			var e = pivot(head,Vector3(side*.46,.18,.12),"Ear")
			rounded(e,Vector3(side*.33,-.25,.08),Vector3(.76,1.22,.15),coat)
			rounded(e,Vector3(side*.36,-.25,-.005),Vector3(.47,.82,.027),"958f7d")
			ears.append(e)
			rounded(head,Vector3(side*.415,.02,-.36),Vector3(.14,.12,.09),"b4aa8e")
			rounded(head,Vector3(side*.43,.03,-.407),Vector3(.075,.073,.041),"29332f")
			rounded(head,Vector3(side*.435,.05,-.428),Vector3(.018,.02,.012),"eee1be")
			if variant==0:
				var a = Vector3(side*.30,-.29,-.40)
				for i in 4:
					var b = a+Vector3(side*.016,.045-i*.008,-.15)
					tube(head,a,b,.065-i*.013,"e2d6b3")
					a = b
		var current = pivot(head,Vector3(0,.03,-.45),"Trunk")
		for i in 6:
			trunk.append(current)
			var radius = .21-i*.025
			rounded(current,Vector3(0,-.16,-.015),Vector3(radius*2,.41,radius*1.8),coat)
			for stripe in [-.07,.04]:
				tube(current,Vector3(-radius*.60,-.16+stripe,-radius*.80),Vector3(radius*.60,-.16+stripe,-radius*.80),.006,"636f68")
			current = pivot(current,Vector3(0,-.29,-.018),"Trunk joint")
		var tail_root = pivot(body,Vector3(0,2.15,1.35),"Tail")
		tube(tail_root,Vector3.ZERO,Vector3(0,-.78,.08),.045,coat)
		rounded(tail_root,Vector3(0,-.80,.08),Vector3(.12,.22,.10),"45514b")
		tail.append(tail_root)
	# Four articulated legs: shorter lower joints for cats, long slender deer shins.
	for i in 4:
		var side = -1.0 if i%2==0 else 1.0
		var front = i<2
		var root = pivot(body,Vector3(side*width,leg_height,shoulder if front else hip),"Leg "+str(i))
		var thick = {"cat":.075,"dog":.11,"deer":.08,"elephant":.37}[kind]
		var upper_length = leg_height*.49
		var shin_length = leg_height*.49
		rounded(root,Vector3(0,-upper_length*.40,.02),Vector3(thick*1.8,upper_length*1.24,thick*1.8),coat)
		var knee = pivot(root,Vector3(0,-upper_length,0),"Knee")
		rounded(knee,Vector3(0,-shin_length*.40,0),Vector3(thick*1.35,shin_length*1.13,thick*1.35),coat if kind=="elephant" else lower)
		var foot_color = "474d43" if kind=="deer" else (lower if kind!="elephant" else "7a8075")
		rounded(knee,Vector3(0,-shin_length,-thick*.2),Vector3(thick*1.6,thick*.65,thick*2.0),foot_color)
		if kind=="elephant":
			for toe in 3: rounded(knee,Vector3((toe-1)*.12,-shin_length+.04,-.31),Vector3(.10,.10,.035),"b0aa96")
		legs.append(root)
		knees.append(knee)
		joints.append(root)
		joints.append(knee)
	joints.append(head)
	joints.append_array(ears)
	joints.append_array(tail)
	joints.append_array(trunk)
	for joint in joints: AvatarArt.bake_joint(joint)
	return {"body":body,"head":head,"legs":legs,"knees":knees,"ears":ears,"tail":tail,"trunk":trunk,"neck":neck}

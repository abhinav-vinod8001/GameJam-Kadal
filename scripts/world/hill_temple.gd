class_name HillTemple
extends Node3D

var floor_y := 0.0
var bell: Node3D
var clock := 0.0
var world: Malanadu

func _ready():
	name = "HillTemple"
	world = get_parent()
	position = Vector3(-79,Malanadu.height_at(-79,-80)+.55,-80)
	floor_y = position.y+.045
	world.building_footprints.append(Vector4(-79,-80,11,11.5))
	world.building_footprints.append(Vector4(-79,-65,3.3,6))
	var stone = Craft.painted(Color("858374"),1.7,.28)
	var pale = Craft.painted(Color("c9bd99"),1.6,.18)
	var wood = Craft.painted(Color("603d2d"),1.9,.28,false,Vector3(6,.3,6))
	var dark = Craft.painted(Color("392b24"),1.4,.18)
	var brass = Craft.mat("c49b50",.65)
	# A single level courtyard rests above the rounded hill, with a stone retaining base.
	Craft.box(self,Vector3(0,-1.85,0),Vector3(20,3.7,21),stone,true)
	for y in [-.24,-.06]: Craft.box(self,Vector3(0,y,0),Vector3(20.3,.12,21.3),pale)
	for row in 14:
		for col in 13:
			var tint = ["a5a08a","939681","b1aa91","999c88"][(row*7+col*3)%4]
			Craft.box(self,Vector3(-9.18+col*1.53,.018,-9.76+row*1.5),Vector3(1.49,.05,1.46),Craft.painted(Color(tint),1.8,.16))
	approach(stone,pale)
	# Low laterite boundary, stone coping and periodic lamp niches.
	for x in [-9.6,9.6]:
		Craft.box(self,Vector3(x,.46,0),Vector3(.5,.88,20.5),Craft.painted(Color("875e48"),2,.30),true)
		Craft.box(self,Vector3(x,.94,0),Vector3(.66,.12,20.7),stone)
		for z in [-8,-4,0,4,8]:
			Craft.box(self,Vector3(x,1.05,z),Vector3(.8,.25,.8),pale)
			Craft.cylinder(self,Vector3(x,1.24,z),.25,.20,stone,.1)
	Craft.box(self,Vector3(0,.48,-10),Vector3(19.3,.92,.5),stone,true)
	for x in [-6.25,6.25]:
		Craft.box(self,Vector3(x,.48,9.7),Vector3(6.7,.92,.55),stone,true)
		Craft.box(self,Vector3(x,.99,9.7),Vector3(6.9,.12,.7),pale)
	# Raised inner sanctum with an open pillared veranda.
	var hall = Node3D.new()
	hall.position.z = -2.2
	hall.name = "Timber sanctum and veranda"
	add_child(hall)
	for tier in 3:
		Craft.box(hall,Vector3(0,.14+tier*.18,0),Vector3(8.25-tier*.18,.20,7.7-tier*.18),stone,true)
		Craft.box(hall,Vector3(0,.25+tier*.18,0),Vector3(8.3-tier*.18,.045,7.75-tier*.18),pale)
	for step in 3:
		Craft.box(hall,Vector3(0,.09+step*.17,4.55-step*.40),Vector3(2.65,.18+step*.34,.43),stone)
	# Smooth invisible collision over the short sculpted steps.
	ramp(hall,Vector3(-1.36,.03,4.82),Vector3(1.36,.62,3.38),stone,false)
	Craft.box(hall,Vector3(-1.95,1.79,-.08),Vector3(1.55,2.35,4.5),pale,true)
	Craft.box(hall,Vector3(1.95,1.79,-.08),Vector3(1.55,2.35,4.5),pale,true)
	Craft.box(hall,Vector3(0,1.79,-2.25),Vector3(5.35,2.35,.32),pale,true)
	Craft.box(hall,Vector3(0,3.03,-.08),Vector3(5.35,.28,4.5),wood)
	for x in [-2.73,2.73]:
		for z in [-1.48,.33,1.6]:
			Craft.box(hall,Vector3(x,1.93,z),Vector3(.07,1.55,.83),dark)
			for i in 5: Craft.box(hall,Vector3(x*1.015,1.93,z-.36+i*.18),Vector3(.07,1.55,.065),wood)
	# Deep brass-trimmed doorway and interior offering stone.
	Craft.box(hall,Vector3(0,1.75,2.18),Vector3(2.25,2.22,.08),dark)
	for x in [-1.22,1.22]:
		Craft.box(hall,Vector3(x,1.80,2.27),Vector3(.20,2.45,.22),wood,true)
		for y in [1.0,1.6,2.2,2.8]:
			var boss = Craft.cylinder(hall,Vector3(x,y,2.40),.079,.042,brass)
			boss.rotation.x = PI*.5
	Craft.box(hall,Vector3(0,3.03,2.3),Vector3(2.7,.24,.27),wood)
	Craft.box(hall,Vector3(0,2.93,2.45),Vector3(2.50,.035,.04),brass)
	for x in [-.68,.68]:
		Craft.box(hall,Vector3(x,1.67,2.25),Vector3(.82,1.95,.08),wood,true)
		for y in [1.18,1.8,2.4]: Craft.box(hall,Vector3(x,y,2.31),Vector3(.65,.055,.04),brass)
	# Articulated-looking carved columns, brackets and a continuous timber lintel.
	for x in [-3.55,3.55]:
		for z in [-3.15,-1.1,1.1,3.15]: pillar(hall,Vector3(x,.62,z),2.76,wood,stone,brass)
	for x in [-1.77,1.77]: pillar(hall,Vector3(x,.62,3.15),2.76,wood,stone,brass)
	for z in [-3.15,3.15]: Craft.box(hall,Vector3(0,3.40,z),Vector3(7.6,.28,.26),wood)
	for x in [-3.55,3.55]: Craft.box(hall,Vector3(x,3.40,0),Vector3(.26,.28,6.55),wood)
	tiled_roof(hall,4.9,4.45,3.55,1.94)
	# The second roof rises from a smaller timber clerestory.
	Craft.box(hall,Vector3(0,5.40,0),Vector3(3.55,.91,2.25),wood)
	for x in range(13):
		for z in [-1.15,1.15]: Craft.box(hall,Vector3(-1.66+x*.277,5.40,z),Vector3(.055,.62,.06),brass)
	tiled_roof(hall,2.42,1.94,5.83,1.43)
	for x in [-.9,0,.9]:
		Craft.cylinder(hall,Vector3(x,7.38,0),.13,.30,brass,.07)
		Craft.sphere(hall,Vector3(x,7.56,0),Vector3(.22,.28,.22),brass)
		Craft.cylinder(hall,Vector3(x,7.78,0),.08,.25,brass,0)
	# A separate tiled gateway frames the south-facing temple entrance.
	var gate = Node3D.new()
	gate.name = "Roofed stone gateway"
	gate.position.z = 8.7
	add_child(gate)
	for x in [-2.35,2.35]: pillar(gate,Vector3(x,.05,0),3.05,wood,stone,brass)
	Craft.box(gate,Vector3(0,3.20,0),Vector3(5.25,.29,.40),wood)
	tiled_roof(gate,3.20,1.65,3.42,1.20)
	# Two hanging bells, a tall tiered oil lamp, flowers and offerings.
	bell = Node3D.new()
	bell.name = "Hanging brass bell"
	bell.position = Vector3(0,3.14,8.7)
	add_child(bell)
	Craft.beam(bell,Vector3.ZERO,Vector3(0,-.62,0),.018,brass)
	Craft.cylinder(bell,Vector3(0,-.75,0),.25,.29,brass,.07)
	Craft.cylinder(bell,Vector3(0,-.90,0),.28,.045,brass)
	Craft.sphere(bell,Vector3(0,-.91,0),Vector3(.07,.11,.07),dark)
	for x in [-2.85,2.85]: SceneryArt.vilakku(self,Vector3(x,.04,4.7),false)
	lamp_tower(Vector3(-5.9,.04,5.0),brass)
	Craft.cylinder(self,Vector3(5.8,.12,5.8),.76,.24,stone)
	Craft.cylinder(self,Vector3(5.8,.37,5.8),.54,.30,Craft.mat("9d6645"),.66)
	Craft.cylinder(self,Vector3(5.8,.53,5.8),.57,.045,Craft.mat("809a87",.25))
	for i in 14:
		var angle = i*2.399
		var radius = .46*sqrt((i+.5)/14.0)
		Craft.sphere(self,Vector3(5.8+cos(angle)*radius,.58,5.8+sin(angle)*radius),Vector3(.12,.055,.12),Craft.mat("d8a24f" if i%3 else "e9d9ac"))
	for x in [-6.9,6.9]:
		Craft.box(self,Vector3(x,.34,.6),Vector3(1.4,.65,1.5),stone,true)
		for i in 6:
			var angle = i*2.399
			Craft.sphere(self,Vector3(x+cos(angle)*.43,.77,sin(angle)*.52+.6),Vector3(.42,.22,.40),Craft.mat("758c45"))
	var shrine = world.interactable("shrine","Rest at the hill temple",global_position+Vector3(0,.72,3.25))
	shrine.name = "Temple rest and discovery"
	print("HILL TEMPLE · two roof tiers · carved veranda · courtyard · walkable gateway")

func pillar(root: Node3D,p: Vector3,height: float,wood: Material,stone: Material,brass: Material):
	Craft.box(root,p+Vector3.UP*.12,Vector3(.65,.24,.65),stone,true)
	Craft.box(root,p+Vector3.UP*(height*.5+.12),Vector3(.27,height-.16,.27),wood,true)
	for y in [.35,.49,height-.37,height-.2]:
		Craft.box(root,p+Vector3.UP*y,Vector3(.40,.085,.40),wood)
		Craft.box(root,p+Vector3.UP*(y+.042),Vector3(.41,.02,.41),brass)
	for side in [-1,1]:
		Craft.beam(root,p+Vector3(0,height-.65,0),p+Vector3(side*.52,height-.06,0),.065,wood)
	Craft.box(root,p+Vector3.UP*height,Vector3(.84,.15,.54),wood)

func ramp(root: Node3D,a: Vector3,b: Vector3,material: Material,visible_value: bool):
	var model = Craft.surface(root,PackedVector3Array([a,Vector3(b.x,a.y,a.z),Vector3(a.x,b.y,b.z),
		Vector3(b.x,a.y,a.z),b,Vector3(a.x,b.y,b.z)]),material)
	model.visible = visible_value
	model.create_trimesh_collision()
	for body in model.get_children():
		for collider in body.get_children():
			if collider is CollisionShape3D: collider.shape.backface_collision = true

func approach(stone: Material,pale: Material):
	var start_y = Malanadu.height_at(-79,-60)-position.y-.18
	ramp(self,Vector3(-1.60,start_y,20),Vector3(1.60,.052,10.48),stone,true)
	var steps = 24
	for i in steps:
		var t = (i+.5)/steps
		var y = lerpf(start_y,.052,t)
		var z = lerpf(20.0,10.48,t)
		Craft.box(self,Vector3(0,y+.008,z),Vector3(3.17,.026,.06),pale)
	for side in [-1,1]:
		for t in [0.0,.25,.5,.75,1.0]:
			var p = Vector3(side*1.84,lerpf(start_y,.052,t),lerpf(20.0,10.48,t))
			Craft.box(self,p+Vector3.UP*.47,Vector3(.36,.94,.36),stone)
			Craft.sphere(self,p+Vector3.UP*.99,Vector3(.39,.20,.39),pale)
		Craft.beam(self,Vector3(side*1.84,start_y+.87,20),Vector3(side*1.84,.92,10.48),.07,stone)

func lamp_tower(p: Vector3,brass: Material):
	Craft.cylinder(self,p+Vector3.UP*.12,.65,.24,brass,.50)
	Craft.cylinder(self,p+Vector3.UP*1.65,.075,3.0,brass,.045)
	for y in [.65,1.25,1.85,2.45]:
		var r = .54-y*.065
		Craft.cylinder(self,p+Vector3.UP*y,r,.09,brass,r*.65)
		for i in 8:
			var a = i*TAU/8
			var flame = Craft.sphere(self,p+Vector3(cos(a)*r,y+.12,sin(a)*r),Vector3(.045,.15,.045),Craft.mat("ffc66e",0,1.2))
			flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Craft.sphere(self,p+Vector3.UP*3.21,Vector3(.18,.24,.18),brass)

func _process(delta):
	if Game.modal or Game.mode=="menu": return
	clock += delta
	bell.rotation.z = sin(clock*1.3)*.035

# Hip trim follows the curved roof profile rather than floating across its dip.
func tiled_roof(root: Node3D,half_width: float,half_depth: float,eave: float,rise: float):
	var first = root.get_child_count()
	SceneryArt.roof(root,half_width,half_depth,eave,rise)
	var hip_material = Craft.mat("8a4e3c")
	for child in root.get_children().slice(first):
		if child is MeshInstance3D and child.material_override==hip_material: child.free()
	var ridge = maxf(.8,half_width-half_depth*.60)
	var corners = [Vector3(-half_width,eave,-half_depth),Vector3(half_width,eave,-half_depth),
		Vector3(half_width,eave,half_depth),Vector3(-half_width,eave,half_depth)]
	var peaks = [Vector3(-ridge,eave+rise,0),Vector3(ridge,eave+rise,0),
		Vector3(ridge,eave+rise,0),Vector3(-ridge,eave+rise,0)]
	for side in 4:
		var next = (side+1)%4
		for row in 12:
			var a = SceneryArt.roof_point(corners[side],corners[next],peaks[side],peaks[next],0,row/12.0)
			var b = SceneryArt.roof_point(corners[side],corners[next],peaks[side],peaks[next],0,(row+1)/12.0)
			Craft.beam(root,a+Vector3.UP*.04,b+Vector3.UP*.04,.10,hip_material)

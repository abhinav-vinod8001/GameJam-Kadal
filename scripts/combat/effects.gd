extends Node3D

var frozen := false

func burst(p: Vector3, color_value: Color, count: int = 16, power: float = 3.0, metallic: bool = false):
	var particles = CPUParticles3D.new()
	particles.position = p
	particles.amount = maxi(4,int(count*Game.effects_scale))
	particles.lifetime = .42
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = .08
	particles.direction = Vector3(0,1,0)
	particles.spread = 80
	particles.initial_velocity_min = power*.4
	particles.initial_velocity_max = power
	particles.gravity = Vector3(0,-7,0)
	particles.scale_amount_min = .035
	particles.scale_amount_max = .085
	var mesh = BoxMesh.new()
	mesh.size = Vector3(.5,.5,2.5) if metallic else Vector3.ONE
	particles.mesh = mesh
	particles.material_override = Craft.mat(color_value.to_html(false),.3 if metallic else 0.0,.45 if metallic else 0.0)
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(.8).timeout.connect(particles.queue_free)

func arc(p: Vector3, yaw: float, radius: float, angle: float, color_value: Color, duration: float = .2, width: float = .12, tilt: float = 0.0):
	var root = Node3D.new()
	root.position = p
	root.rotation = Vector3(tilt,yaw,0)
	add_child(root)
	var verts = PackedVector3Array()
	for i in range(26):
		var a = -angle/2.0 + angle*i/26.0
		var b = -angle/2.0 + angle*(i+1)/26.0
		var inner = radius-width*(sin(float(i)/26*PI)*.7+.3)
		var a1 = Vector3(sin(a)*inner,0,-cos(a)*inner)
		var a2 = Vector3(sin(a)*radius,0,-cos(a)*radius)
		var b1 = Vector3(sin(b)*inner,0,-cos(b)*inner)
		var b2 = Vector3(sin(b)*radius,0,-cos(b)*radius)
		verts.append_array(PackedVector3Array([a1,b1,a2,a2,b1,b2]))
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_value
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var n = Craft.surface(root,verts,mat)
	var tween = create_tween()
	tween.tween_property(mat,"albedo_color:a",0.0,duration)
	tween.parallel().tween_property(n,"scale",Vector3.ONE*1.1,duration)
	tween.tween_callback(root.queue_free)

func swing(source: Node3D, weapon: int, heavy: bool, combo: int):
	var p = source.global_position+Vector3.UP*1.1
	var yaw = source.visual.rotation.y
	var c = Color(Game.weapons[weapon].color)
	Game.audio.play(Game.weapons[weapon].sound)
	var factor = 1.18 if heavy else 1.0
	if weapon == 1:
		var forward = Vector3(-sin(yaw),0,-cos(yaw))
		for i in 3:
			var n = Craft.beam(self,p+Vector3(i*.07-.07,0,0)+forward*.8,p+forward*4.2,.018 if i!=1 else .04,Craft.mat("d5e4df",.1,.3))
			var tween = create_tween()
			tween.tween_property(n,"scale",Vector3(.03,1,.03),.16)
			tween.tween_callback(n.queue_free)
	elif weapon == 4:
		for i in range(3):
			arc(p+Vector3.UP*(i*.09-.1),yaw+i*.12,3.5*factor-i*.12,4.8,c,.3,.045,.1)
	elif weapon == 2:
		arc(p,yaw,2.9*factor,3.8,c*.9,.18,.07,.18)
		burst(source.global_position+Vector3.UP*.15,Color("c0b386"),9,1.7)
	elif weapon == 3:
		arc(p,yaw,1.65,1.7,c,.14,.13,.45 if combo%2==0 else -.45)
	else:
		arc(p,yaw,2.25*factor,2.8,c,.22,.22 if heavy else .12,.38 if combo%2==0 else -.38)
		arc(p+Vector3.UP*.02,yaw+.05,2.1*factor,2.4,Color("ffffffaa"),.17,.035,.38 if combo%2==0 else -.38)
	if heavy:
		burst(source.global_position+Vector3.UP*.12,Color("bcb291"),18,2.0)

func impact(p: Vector3, damage: int, guard: bool = false):
	burst(p,Color("f9d991") if guard else Color("e0ccb1"),22,4.3,guard)
	arc(p,randf()*TAU,.55,TAU,Color("f4e8c8"),.12,.1,.8)
	if damage > 0: floating(p+Vector3.UP*.35,str(damage),Color("fff0c5"))
	if Game.player: Game.player.shake(.12 if guard else .07)
	Game.audio.play("block" if guard else "impact")
	freeze(.045)

func parry(p: Vector3):
	burst(p,Color("ffe8a9"),40,6.0,true)
	arc(p,0,1.4,TAU,Color("fff2bb"),.35,.1,.4)
	arc(p,0,1.0,TAU,Color("e9f5ed"),.25,.04,-.45)
	floating(p+Vector3.UP*.7,"PERFECT PARRY",Color("f9dfa2"))
	Game.audio.play("parry")
	Game.player.shake(.24)
	freeze(.11)

func step(p: Vector3, wet: bool = false, land: bool = false):
	if wet:
		var surface_y = maxf(.28,p.y+.06)
		arc(Vector3(p.x,surface_y,p.z),0,.65 if land else .3,TAU,Color("bee8dbaa"),.6,.04)
		burst(Vector3(p.x,surface_y,p.z),Color("b5dcd7"),12 if land else 5,2 if land else .8)
	else:
		burst(p+Vector3.UP*.08,Color("b6ae87"),12 if land else 4,1.5 if land else .5)
	Game.audio.play("splash" if wet else "step",-.0 if land else -8.0)

func floating(p: Vector3,message: String,color_value: Color):
	var text = Craft.label(self,message,p,35 if message.length()<5 else 22)
	text.modulate = color_value
	text.no_depth_test = true
	var tween = create_tween()
	tween.tween_property(text,"position:y",p.y+1.0,.8)
	tween.parallel().tween_property(text,"modulate:a",0.0,.8)
	tween.tween_callback(text.queue_free)

func heal(p: Vector3):
	burst(p+Vector3.UP*.5,Color("9fca96"),28,2.4)
	arc(p+Vector3.UP*.08,0,1.0,TAU,Color("afd6a2"),.7,.06)
	Game.audio.play("heal")

func freeze(seconds: float):
	if frozen: return
	frozen = true
	Engine.time_scale = .14
	await get_tree().create_timer(seconds,true,false,true).timeout
	Engine.time_scale = 1.0
	frozen = false

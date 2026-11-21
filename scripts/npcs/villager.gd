extends Node3D

var npc_id := ""
var costume := "ravi"
var tint := "a28a62"
var activity := "talk"
var route: Array[Vector3] = []
var visual: KadalAvatar
var title: Label3D
var route_index := 0
var route_direction := 1
var clock := 0.0
var pause_time := 0.0
var animation_time := 0.0
var greeting := 0.0
var was_near := false
var speed_value := .75
var current_speed := 0.0
var animation_motion := Vector3.ZERO

func _ready():
	add_to_group("interactables")
	add_to_group("speech_actors")
	add_to_group("villagers")
	set_meta("kind","npc")
	set_meta("prompt","Speak with "+str(Game.dialogues[npc_id].name))
	visual = KadalAvatar.new()
	visual.costume = costume
	visual.tint = tint
	add_child(visual)
	visual.weapon_root.hide()
	visual.shield.hide()
	clock = float(npc_id.hash()%1000)*.013
	visual.breath_clock = clock
	title = Craft.label(self,Game.dialogues[npc_id].name,Vector3(0,2.08,0),20)
	title.hide()
	var reed = Craft.mat("b39861")
	if activity in ["farm","carry","fish"]:
		var hat = Craft.cylinder(visual.head,Vector3(0,.22,.015),.34,.13,reed,.08)
		hat.name = "Woven field hat"
	if activity=="carry":
		var basket = Node3D.new()
		basket.position = Vector3(0,-.78,-.05)
		visual.right_hand_space.add_child(basket)
		SceneryArt.spice_basket(basket,Vector3.ZERO,.24,Color("b4a05a"))
	elif activity=="fish":
		Craft.beam(visual.right_hand_space,Vector3(0,-.54,-.04),Vector3(0,-.85,-2.2),.017,Craft.mat("a78c56"))
	elif activity=="farm":
		Craft.beam(visual.right_hand_space,Vector3(0,-.54,-.04),Vector3(0,-.93,-.20),.022,Craft.mat("725237"))
		AvatarArt.angled(visual.right_hand_space,Vector3(0,-.92,-.21),Vector3(.20,-.98,-.28),.031,.023,Craft.mat("a6b5ac",.3))
	set_range(visual)
	if not Craft.cache.has("villager_contact_shadow"):
		var shadow_material = ShaderMaterial.new()
		shadow_material.shader = preload("res://shaders/contact_shadow.gdshader")
		Craft.cache["villager_contact_shadow"] = shadow_material
	var shadow_plane = PlaneMesh.new()
	shadow_plane.size = Vector2(.72,.52)
	var shadow = Craft.mesh(self,shadow_plane,Vector3(0,.055,0),Craft.cache["villager_contact_shadow"])
	shadow.layers = 1 << 19
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.visibility_range_end = 45

func set_range(node: Node):
	if node is GeometryInstance3D:
		node.visibility_range_end = 80.0
		node.visibility_range_end_margin = 10.0
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Distant market crowds do not need a second copy in the water view.
		# Fishers at the waterfront keep their reflections.
		if activity!="fish": node.layers = 1 << 19
	for child in node.get_children(): set_range(child)

func _process(delta):
	if not is_instance_valid(Game.player): return
	clock += delta
	var distance_value = global_position.distance_to(Game.player.global_position)
	# Menu composition uses the camera's distance; distant villagers keep their route
	# state, but their articulated poses update at a reduced rate.
	var camera = get_viewport().get_camera_3d()
	var view_distance = global_position.distance_to(camera.global_position) if camera else distance_value
	visual.visible = view_distance<83
	title.visible = distance_value<7.0 and Game.mode!="menu"
	if Game.modal: return
	var near = distance_value<3.6 and Game.mode!="menu"
	if near and not was_near: greeting = 1.2
	was_near = near
	greeting = maxf(0,greeting-delta)
	pause_time = maxf(0,pause_time-delta)
	var moving = 0.0
	var before = global_position
	var wants_walk = not route.is_empty() and not near and pause_time<=0 and Game.mode!="menu"
	current_speed = move_toward(current_speed,speed_value if wants_walk else 0.0,delta*1.8)
	if wants_walk:
		var target = route[route_index]
		var difference = target-global_position
		difference.y = 0
		if difference.length()<.12:
			if route_index==route.size()-1: route_direction = -1
			elif route_index==0: route_direction = 1
			route_index = clampi(route_index+route_direction,0,route.size()-1)
			pause_time = 1.4+fmod(clock,2.1)
		else:
			var step = minf(difference.length(),current_speed*delta)
			global_position += difference.normalized()*step
			global_position.y = Malanadu.height_at(global_position.x,global_position.z)+.035
			visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-difference.x,-difference.z),1-exp(-delta*5))
			moving = step/maxf(delta,.001)
	var travelled = global_position-before
	travelled.y = 0
	animation_motion += travelled
	if near:
		var look = Game.player.global_position-global_position
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-look.x,-look.z),1-exp(-delta*4))
	animation_time += delta
	var interval = 0.0 if view_distance<25 else (.067 if view_distance<48 else .20)
	if animation_time<interval or not visual.visible: return
	var elapsed = animation_time
	var actual_motion = animation_motion/maxf(elapsed,.001)
	animation_motion = Vector3.ZERO
	animation_time = 0
	var scale_value = maxf(.1,visual.scale.y)
	visual.animate(elapsed,actual_motion.length()/scale_value,0,false,false,0,false,visual.global_basis.inverse()*actual_motion)
	if greeting>0:
		visual.left_arm.rotation = Vector3(2.1,0,.35+sin(clock*13)*.22)
		visual.elbows[0].rotation.x = .65
	elif activity=="farm" and not near and moving<.05:
		visual.torso.rotation.x = -.46+sin(clock*1.8)*.11
		visual.right_arm.rotation.x = 1.0+sin(clock*1.8)*.20
		visual.left_arm.rotation.x = .65
		visual.elbows[1].rotation.x = .55
	elif activity=="carry":
		visual.right_arm.rotation.x = .40
		visual.elbows[1].rotation.x = .55
	elif activity=="fish":
		visual.right_arm.rotation.x = .66+sin(clock*.65)*.08
		visual.elbows[1].rotation.x = .3
	elif activity in ["vendor","talk"] and moving==0:
		visual.right_arm.rotation.x = .15+maxf(0,sin(clock*1.3))*.40
		visual.elbows[1].rotation.x = .22+maxf(0,sin(clock*1.3))*.35

class_name KadalAnimal
extends CharacterBody3D

var kind := "cat"
var variant := 0
var home := Vector3.ZERO
var roam_radius := 4.0
var rig: Dictionary
var target := Vector3.ZERO
var state := "idle"
var clock := 0.0
var wait_time := 1.0
var alert_time := 0.0
var gait := 0.0
var pace := 0.0
var animation_elapsed := 0.0
var decision_elapsed := 0.0
var random = RandomNumberGenerator.new()
var visual: Node3D
var shadow: MeshInstance3D
var base_head := Vector3.ZERO
var base_ears: Array[Vector3] = []

func _ready():
	name = kind.capitalize()+" "+str(variant+1)
	add_to_group("wildlife")
	random.seed = int(home.x*1703+home.z*907)+variant*23
	clock = random.randf()*20
	wait_time = random.randf_range(.5,4.0)
	collision_layer = 0
	collision_mask = 1
	floor_snap_length = .7
	floor_max_angle = deg_to_rad(47)
	var shape = CapsuleShape3D.new()
	shape.radius = {"cat":.14,"dog":.23,"deer":.28,"elephant":.82}[kind]
	shape.height = {"cat":.50,"dog":.85,"deer":1.8,"elephant":2.9}[kind]
	var collider = CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = shape.height*.5+.035
	add_child(collider)
	visual = Node3D.new()
	add_child(visual)
	rig = AnimalArt.build(visual,kind,variant)
	base_head = rig.head.rotation
	for e in rig.ears: base_ears.append(e.rotation)
	set_visibility(visual)
	if not Craft.cache.has("animal_contact_shadow"):
		var material = ShaderMaterial.new()
		material.shader = preload("res://shaders/contact_shadow.gdshader")
		Craft.cache["animal_contact_shadow"] = material
	var plane = PlaneMesh.new()
	var width: float = {"cat":.45,"dog":.75,"deer":.9,"elephant":2.3}[kind]
	plane.size = Vector2(width,width*1.5)
	shadow = Craft.mesh(self,plane,Vector3(0,.045,0),Craft.cache["animal_contact_shadow"])
	shadow.layers = 1 << 19
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.visibility_range_end = 65
	target = home

func set_visibility(node: Node):
	if node is GeometryInstance3D:
		node.visibility_range_end = 105 if kind=="elephant" else 75
		node.visibility_range_end_margin = 8
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.layers = 1 << 19
	for child in node.get_children(): set_visibility(child)

func choose_target(away := Vector3.ZERO):
	var clearance: float = {"cat":.35,"dog":.5,"deer":.6,"elephant":1.1}[kind]
	for attempt in 12:
		var angle = random.randf()*TAU
		var offset = Vector3(sin(angle),0,cos(angle))*random.randf_range(roam_radius*.25,roam_radius)
		if away.length_squared()>.01:
			offset = (away.normalized()+Vector3(sin(angle),0,cos(angle))*.5).normalized()*roam_radius
		var point = home+offset
		point.y = Malanadu.height_at(point.x,point.z)+.06
		if point.y<1.1 or absf(point.y-global_position.y)>2.5: continue
		var ray = PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*clearance,point+Vector3.UP*clearance,1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		target = point
		state = "walk" if alert_time<=0 else "flee"
		return
	state = "idle"
	wait_time = .8

func _physics_process(delta):
	if not is_instance_valid(Game.player) or Game.mode=="menu" or Game.modal: return
	clock += delta
	alert_time = maxf(0,alert_time-delta)
	wait_time = maxf(0,wait_time-delta)
	decision_elapsed += delta
	var difference = Game.player.global_position-global_position
	var distance_value = difference.length()
	if decision_elapsed>.25:
		decision_elapsed = 0
		if kind=="deer" and distance_value<6.0 and alert_time<.5:
			alert_time = 3.5
			choose_target(-difference)
		elif kind in ["cat","dog"] and distance_value<2.4:
			state = "curious"
			wait_time = 1.5
		elif state=="curious" and distance_value>3.0:
			state = "idle"
		elif state in ["idle","graze"] and wait_time<=0:
			if random.randf()<.35:
				state = "graze"
				wait_time = random.randf_range(2,5)
			else: choose_target()
	var direction = target-global_position
	direction.y = 0
	var speed_value: float = {"cat":.65,"dog":1.0,"deer":1.05,"elephant":.62}[kind]
	if state=="flee": speed_value = 3.8
	if state in ["walk","flee"]:
		if direction.length()<.25:
			state = "idle"
			wait_time = random.randf_range(1.4,5.5)
			speed_value = 0
		else:
			visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),1-exp(-delta*4))
	else: speed_value = 0
	if state=="curious": visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-difference.x,-difference.z),1-exp(-delta*3))
	var desired = direction.normalized()*speed_value
	velocity.x = move_toward(velocity.x,desired.x,delta*4)
	velocity.z = move_toward(velocity.z,desired.z,delta*4)
	velocity.y = -2 if is_on_floor() else velocity.y-18*delta
	move_and_slide()
	if is_on_wall():
		state = "idle"
		wait_time = .35
		velocity.x = 0
		velocity.z = 0
	if global_position.y < -3 or global_position.distance_to(home)>roam_radius+4:
		global_position = home+Vector3.UP*.15
		velocity = Vector3.ZERO
		state = "idle"
		wait_time = 2
	pace = Vector2(velocity.x,velocity.z).length()
	gait += delta*pace*(5.0 if kind=="elephant" else 8.0)
	animation_elapsed += delta
	var camera = get_viewport().get_camera_3d()
	var view_distance = camera.global_position.distance_to(global_position) if camera else distance_value
	if view_distance>110: return
	if animation_elapsed < (.016 if view_distance<22 else (.067 if view_distance<48 else .2)): return
	animation_elapsed = 0
	animate_pose()

func animate_pose():
	var moving = clampf(pace,0,1)
	var stride = .24 if kind=="elephant" else (.65 if state=="flee" else .48)
	rig.body.position.y = sin(gait*2)*moving*(.035 if kind=="elephant" else .022)
	rig.body.rotation.z = sin(gait)*moving*(.018 if kind=="elephant" else .012)
	for i in 4:
		var phase = gait+(PI if i in [1,2] else 0.0)
		rig.legs[i].rotation.x = sin(phase)*stride*moving
		rig.knees[i].rotation.x = -maxf(0,cos(phase))*.44*moving
	rig.head.rotation = base_head+Vector3(sin(clock*1.4)*.035,sin(clock*.7)*.075,0)
	if state=="graze": rig.head.rotation.x -= .50
	if state=="curious": rig.head.rotation.z = sin(clock*.9)*.12
	if rig.has("neck") and rig.neck:
		rig.neck.rotation.x = lerpf(rig.neck.rotation.x,-.82 if state=="graze" else 0,.10)
	for i in rig.ears.size():
		rig.ears[i].rotation = base_ears[i]+Vector3(0,sin(clock*(1.7 if kind=="elephant" else 3.0)+i)*(.19 if kind=="elephant" else .07),0)
	for i in rig.tail.size():
		rig.tail[i].rotation.y = sin(clock*(7 if kind=="dog" and state=="curious" else 2.2)-i*.45)*(.24 if kind=="dog" else .11)
	for i in rig.trunk.size():
		rig.trunk[i].rotation.x = sin(clock*.9-i*.25)*.085+.025
		rig.trunk[i].rotation.z = sin(clock*.65-i*.28)*.055

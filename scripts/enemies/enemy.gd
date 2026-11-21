extends CharacterBody3D

var elite := false
var training := false
var level := 1
var role := "spearman"
var squad_id := ""
var encounters: SoldierEncounters
var formation_angle := 0.0
var health := 75.0
var max_health := 75.0
var damage := 15.0
var windup_duration := 1.0
var recovery_duration := .7
var attack_range := 2.7
var state := "patrol"
var timer := 0.0
var home: Vector3
var visual: KadalAvatar
var hp: Label3D
var tell: MeshInstance3D
var cooldown := 1.5
var walk_clock := 0.0
var dead := false
var hit_landed := false
var animation_elapsed := 0.0
var steering_clock := 0.0
var steering_direction := Vector3.ZERO
var animation_motion := Vector3.ZERO

func _ready():
	collision_layer = 4
	collision_mask = 1|2|4
	floor_snap_length = .6
	home = position
	add_to_group("enemies")
	var c = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = .33
	shape.height = 1.75
	c.shape = shape
	c.position.y = .9
	add_child(c)
	if training:
		health = 9999
		max_health = 9999
		Craft.cylinder(self,Vector3(0,1,0),.2,2,Craft.mat("8b6c43"))
		Craft.cylinder(self,Vector3(0,1.5,0),.36,.6,Craft.mat("bea475"))
		Craft.beam(self,Vector3(-.8,1.3,0),Vector3(.8,1.3,0),.09,Craft.mat("aa8756"))
		hp = Craft.label(self,"PRACTICE POST",Vector3(0,2.5,0),22)
		return
	if elite: role = "captain"
	add_to_group("speech_actors")
	set_meta("speech_hostile",true)
	configure_stats()
	visual = KadalAvatar.new()
	visual.enemy = true
	visual.tint = ["637660","7f5847","8d3937"][clampi(level-1,0,2)]
	visual.weapon_id = 1 if role=="spearman" else 0
	add_child(visual)
	if elite:
		visual.scale *= 1.08
		Craft.cylinder(visual.head,Vector3(0,.17,.025),.16,.09,Craft.mat("c7a055",.5))
		var plume = Craft.sphere(visual.head,Vector3(0,.31,.06),Vector3(.10,.31,.25),Craft.mat("a54234"))
		plume.rotation.x = -.3
	set_render_range(visual)
	hp = Craft.label(self,"",Vector3(0,2.35,0),18)
	hp.modulate = [Color("ddd4b3"),Color("e2b975"),Color("ef9d78")][clampi(level-1,0,2)]
	hp.hide()
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("edb75b") if role=="spearman" else Color("e78155")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var torus = TorusMesh.new()
	torus.inner_radius = 1.05
	torus.outer_radius = 1.12
	torus.rings = 24
	torus.ring_segments = 8
	tell = Craft.mesh(self,torus,Vector3(0,.05,0),mat)
	tell.layers = 1 << 19
	tell.visibility_range_end = 60
	tell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tell.visible = false
	cooldown += fposmod(formation_angle,.7)

func set_render_range(node: Node):
	if node is GeometryInstance3D:
		node.visibility_range_end = 95
		node.visibility_range_end_margin = 8
		node.layers = 1 << 19
	for child in node.get_children(): set_render_range(child)

func configure_stats(preserve_health := false):
	var ratio = health/maxf(max_health,1.0) if preserve_health else 1.0
	var profile = encounters.profile() if is_instance_valid(encounters) else Game.DIFFICULTIES[Game.difficulty]
	var growth = float(clampi(level,1,3)-1)
	var base_health = 125.0 if role=="captain" else (90.0 if role=="swordsman" else 75.0)
	max_health = base_health*(1.0+growth*.18)*float(profile.health)
	health = max_health*ratio
	damage = (24.0 if role=="captain" else (17.0 if role=="swordsman" else 15.0))*(1.0+growth*.16)*float(profile.damage)
	windup_duration = maxf(.58,(1.0-growth*.09-(.08 if elite else 0.0))*float(profile.windup))
	recovery_duration = (.72-growth*.06)*float(profile.recovery)
	attack_range = 3.15 if role=="spearman" else 2.35

func _physics_process(delta):
	if training or dead or Game.mode=="menu" or not is_instance_valid(Game.player) or Game.modal: return
	var player = Game.player
	if player.health<=0:
		tell.hide()
		return
	var diff = player.global_position-global_position
	var dist = diff.length()
	var flat = Vector3(diff.x,0,diff.z).normalized()
	cooldown -= delta
	timer -= delta
	walk_clock += delta
	steering_clock -= delta
	hp.text = "LV %d · %s\n%s  %d"%[level,role.to_upper(),"━".repeat(maxi(0,ceili(health/max_health*6))),ceili(health)]
	hp.visible = dist<15 and absf(diff.y)<7 and (elite or health<max_health or player.locked==self)
	if state=="stagger":
		velocity.x = move_toward(velocity.x,0,delta*10)
		velocity.z = move_toward(velocity.z,0,delta*10)
		if timer<=0: state = "chase"; cooldown = .8
	elif state=="windup":
		velocity.x = 0
		velocity.z = 0
		tell.show()
		tell.scale = Vector3.ONE*(1.0+sin(walk_clock*20)*.07)
		# Facing is committed for the last part of the tell, so a dodge can evade it.
		if timer>windup_duration*.45: face(flat,delta*4)
		if timer<=0:
			state = "strike"
			timer = .30
			hit_landed = false
			tell.hide()
			Game.fx.arc(global_position+Vector3.UP,visual.rotation.y,attack_range,2.4,Color("d5ac7f"),.22,.1,.15)
			Game.audio.play("spear" if role=="spearman" else "sword")
	elif state=="strike":
		velocity.x = 0
		velocity.z = 0
		if not hit_landed:
			hit_landed = true
			if dist<attack_range+.4 and (-visual.basis.z).dot(flat)>.3 and clear_sight(player):
				player.take_hit(damage,self)
		if state=="strike" and timer<=0:
			state = "recover"
			timer = recovery_duration
	elif state=="recover":
		velocity.x = 0
		velocity.z = 0
		if timer<=0:
			state = "chase"
			cooldown = .95*float(encounters.profile().recovery) if is_instance_valid(encounters) else 1.0
	else:
		if state=="patrol" and dist<10.5 and absf(diff.y)<5 and player.boat==null and clear_sight(player):
			if is_instance_valid(encounters): encounters.engage(squad_id)
			else: state = "chase"
		var direction: Vector3
		var speed_value = 2.75+level*.12
		if state=="return":
			direction = (encounters.approach_point(self,home) if is_instance_valid(encounters) else home)-global_position
			speed_value = 2.8
			if Vector2(direction.x,direction.z).length()<.4:
				state = "patrol"
				health = max_health
		elif state=="patrol":
			var target = home+Vector3(sin(walk_clock*.25+formation_angle),0,cos(walk_clock*.25+formation_angle))*.75
			direction = target-global_position
			speed_value = .7 if direction.length()>.25 else 0.0
		else:
			var flank = Vector3(sin(formation_angle),0,cos(formation_angle))*attack_range*.72
			var destination = player.global_position+flank
			if is_instance_valid(encounters): destination = encounters.approach_point(self,destination)
			direction = destination-global_position
			if dist<attack_range and clear_sight(player):
				speed_value = 0
				face(flat,delta*7)
				if cooldown<=0 and (not is_instance_valid(encounters) or encounters.try_attack(self)):
					state = "windup"
					timer = windup_duration
					Game.audio.play("telegraph",-8)
			direction += separation()*1.2
		direction.y = 0
		if speed_value>0:
			if steering_clock<=0:
				steering_direction = steer(direction.normalized())
				steering_clock = .12
			face(flat if state=="chase" else steering_direction,delta*7)
		velocity.x = steering_direction.x*speed_value
		velocity.z = steering_direction.z*speed_value
	velocity.y = -1 if is_on_floor() else maxf(-30,velocity.y-delta*21)
	var before = global_position
	move_and_slide()
	var travelled = global_position-before
	travelled.y = 0
	animation_motion += travelled
	if is_on_wall(): steering_clock = 0
	if global_position.y< -5:
		global_position = home+Vector3.UP*.2
		velocity = Vector3.ZERO
		state = "return"
		animation_motion = Vector3.ZERO
	animation_elapsed += delta
	var camera = get_viewport().get_camera_3d()
	var view_distance = global_position.distance_to(camera.global_position) if camera else dist
	visual.visible = view_distance<103
	if not visual.visible: return
	var interval = 0.0 if view_distance<25 else (.05 if view_distance<50 else .12)
	if animation_elapsed<interval: return
	var attack_progress = .3 if state=="windup" else (.7 if state=="strike" else 0.0)
	var actual_motion = animation_motion/maxf(animation_elapsed,.001)
	if state=="stagger": actual_motion = Vector3.ZERO
	visual.animate(animation_elapsed,actual_motion.length()/visual.scale.y,attack_progress,false,false,0,role=="spearman",visual.global_basis.inverse()*actual_motion)
	animation_elapsed = 0
	animation_motion = Vector3.ZERO

func face(direction: Vector3,weight: float):
	if direction.length_squared()>.01:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),minf(weight,1.0))

func separation() -> Vector3:
	var result = Vector3.ZERO
	if not is_instance_valid(encounters): return result
	for other in encounters.world.enemies:
		if other==self or not is_instance_valid(other) or other.dead: continue
		var away = global_position-other.global_position
		away.y = 0
		if away.length_squared()<1.35 and away.length_squared()>.001:
			result += away.normalized()*(1.16-away.length())
	return result

func steer(direction: Vector3) -> Vector3:
	for angle in [0.0,.55,-.55,1.1,-1.1,1.57,-1.57]:
		var candidate = direction.rotated(Vector3.UP,angle)
		var endpoint = global_position+candidate*1.35
		if Malanadu.height_at(endpoint.x,endpoint.z)<.65: continue
		# Probe below the waist, including the body's width: chest-height rays
		# can see over low walls which still stop a soldier's capsule.
		var side = Vector3(-candidate.z,0,candidate.x)*.30
		var blocked = false
		for offset in [-1,0,1]:
			var ray = PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.58+side*offset,endpoint+Vector3.UP*.58+side*offset,1)
			if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
				blocked = true
				break
		if not blocked: return candidate
	return Vector3.ZERO

func clear_sight(target: Node3D) -> bool:
	var query = PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.2,target.global_position+Vector3.UP*1.2,1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func take_hit(amount: float, source: Node3D, heavy: bool = false):
	if dead: return
	if training:
		Game.fx.impact(global_position+Vector3.UP,roundi(amount))
		Game.fx.floating(global_position+Vector3.UP*2.5,"GOOD FORM",Color("e5d2a0"))
		return
	if is_instance_valid(encounters): encounters.engage(squad_id)
	var facing = (-visual.basis.z).dot((source.global_position-global_position).normalized())>.2
	if elite and state=="recover" and facing and not heavy:
		Game.fx.impact(global_position+Vector3.UP,0,true)
		Game.fx.floating(global_position+Vector3.UP*2,"GUARDED · USE HEAVY",Color("d9c99f"))
		return
	health = maxf(0,health-amount)
	Game.fx.impact(global_position+Vector3.UP,roundi(amount))
	stagger(.9 if heavy else .4)
	var away = (global_position-source.global_position).normalized()
	velocity.x = away.x*(7 if heavy else 3.5)
	velocity.z = away.z*(7 if heavy else 3.5)
	if health<=0:
		dead = true
		state = "dead"
		tell.hide()
		hp.hide()
		collision_layer = 0
		collision_mask = 0
		if is_instance_valid(encounters): encounters.defeated(self)
		else: Game.defeated_enemy()
		Game.fx.burst(global_position+Vector3.UP,Color("c1b391"),24,2.0)
		var tween = create_tween()
		tween.tween_property(visual,"rotation:z",PI/2,.3)
		tween.tween_interval(3)
		tween.tween_property(visual,"scale",Vector3.ONE*.01,.6)
		tween.tween_callback(hide)

func stagger(duration_value: float):
	if training or dead: return
	state = "stagger"
	timer = duration_value
	tell.hide()

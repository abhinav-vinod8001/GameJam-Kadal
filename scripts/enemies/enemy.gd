extends CharacterBody3D

var elite := false
var training := false
var health := 75.0
var max_health := 75.0
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

func _ready():
	collision_layer = 4
	collision_mask = 1|2|4
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
	max_health = 155.0 if elite else 75.0
	health = max_health
	visual = KadalAvatar.new()
	visual.enemy = true
	visual.tint = "774334" if elite else "52605a"
	visual.weapon_id = 0 if elite else 1
	add_child(visual)
	if elite: visual.scale *= 1.1
	hp = Craft.label(self,"",Vector3(0,2.5,0),23)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("d87443")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var torus = TorusMesh.new()
	torus.inner_radius = 1.05
	torus.outer_radius = 1.12
	torus.rings = 24
	torus.ring_segments = 8
	tell = Craft.mesh(self,torus,Vector3(0,.05,0),mat)
	tell.visible = false

func _physics_process(delta):
	if training or dead or Game.mode=="menu" or not is_instance_valid(Game.player) or Game.modal: return
	var player = Game.player
	if player.health<=0: return
	var diff = player.global_position-global_position
	var dist = diff.length()
	var flat = Vector3(diff.x,0,diff.z).normalized()
	cooldown -= delta
	timer -= delta
	walk_clock += delta
	hp.text = ("ELITE GUARD" if elite else "RAIDER")+"  "+"━".repeat(maxi(0,int(health/max_health*10)))+"  %d"%int(health)
	hp.visible = dist<18 or health<max_health
	if state == "stagger":
		velocity.x = move_toward(velocity.x,0,delta*10)
		velocity.z = move_toward(velocity.z,0,delta*10)
		if timer<=0: state = "chase"; cooldown = .8
	elif state == "windup":
		velocity.x = 0
		velocity.z = 0
		tell.visible = true
		tell.scale = Vector3.ONE*(1.0+sin(walk_clock*20)*.07)
		if timer<=0:
			state = "strike"
			timer = .36
			hit_landed = false
			tell.visible = false
			Game.fx.arc(global_position+Vector3.UP,visual.rotation.y,2.5,2.4,Color("d5ac7f"),.22,.1,.15)
			Game.audio.play("spear" if not elite else "sword")
	elif state == "strike":
		if not hit_landed:
			hit_landed = true
			if dist<3.0 and (-visual.basis.z).dot(flat)>.25 and clear_sight(player):
				player.take_hit(24 if elite else 15,self)
		if state=="strike" and timer<=0:
			state = "recover"
			timer = .7
	elif state=="recover":
		velocity.x = 0
		velocity.z = 0
		if timer<=0: state = "chase"; cooldown = 1.0
	else:
		if dist<13 and clear_sight(player): state = "chase"
		if dist>24 or global_position.distance_to(home)>25: state = "patrol"
		var target_dir = flat
		var speed_value = 3.15 if elite else 2.8
		if state=="patrol":
			var target = home+Vector3(sin(walk_clock*.3)*2,0,cos(walk_clock*.3)*2)
			target_dir = (target-global_position).normalized()
			speed_value = 1.0
		elif dist<2.45:
			speed_value = 0
			if cooldown<=0:
				state = "windup"
				timer = .82 if elite else 1.0
				Game.audio.play("telegraph",-6)
		if target_dir.length()>.1:
			visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-target_dir.x,-target_dir.z),delta*7)
		velocity.x = target_dir.x*speed_value
		velocity.z = target_dir.z*speed_value
	velocity.y -= delta*21
	move_and_slide()
	var attack_progress = .3 if state=="windup" else (.7 if state=="strike" else 0.0)
	visual.animate(delta,Vector2(velocity.x,velocity.z).length(),attack_progress,false,false)

func clear_sight(target: Node3D) -> bool:
	var query = PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.2,target.global_position+Vector3.UP*1.2,1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func take_hit(amount: float, source: Node3D, heavy: bool = false):
	if dead: return
	if training:
		Game.fx.impact(global_position+Vector3.UP,roundi(amount))
		Game.fx.floating(global_position+Vector3.UP*2.5,"GOOD FORM",Color("e5d2a0"))
		return
	# The elite blocks front-on during recovery, but heavy blows break the guard.
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
		tell.visible = false
		hp.visible = false
		collision_layer = 0
		collision_mask = 0
		Game.defeated_enemy()
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
	tell.visible = false

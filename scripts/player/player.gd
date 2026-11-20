class_name KadalPlayer
extends CharacterBody3D

var visual: KadalAvatar
var rig: Node3D
var arm: SpringArm3D
var camera: Camera3D
var combat
var health := 100.0
var stamina := 100.0
var yaw := 0.0
var pitch := -.25
var invulnerable := 0.0
var dodge_time := 0.0
var dodge_dir := Vector3.ZERO
var step_clock := 0.0
var was_grounded := false
var swimming := false
var boat = null
var locked = null
var shake_amount := 0.0
var climb_time := 0.0
var region := ""
var camera_distance := 6.7
var previous_vertical_speed := 0.0
var landing_camera := 0.0

func _ready():
	collision_layer = 2
	collision_mask = 1|4
	floor_snap_length = .5
	var c = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = .33
	shape.height = 1.75
	c.shape = shape
	c.position.y = .9
	add_child(c)
	visual = KadalAvatar.new()
	visual.tint = "e0d5b0"
	add_child(visual)
	rig = Node3D.new()
	add_child(rig)
	rig.top_level = true
	rig.position = global_position+Vector3.UP*1.4
	arm = SpringArm3D.new()
	arm.spring_length = camera_distance
	arm.margin = .25
	arm.collision_mask = 1
	rig.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 68
	camera.far = 650
	arm.add_child(camera)
	combat = load("res://scripts/combat/combat.gd").new()
	add_child(combat)

func _unhandled_input(event):
	if not Game.active(): return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not "--capture" in OS.get_cmdline_user_args():
		yaw -= event.relative.x*Game.sensitivity
		pitch = clampf(pitch-event.relative.y*Game.sensitivity,-1.05,.45)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera_distance = maxf(3.2,camera_distance-.5)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera_distance = minf(10,camera_distance+.5)
	if event.is_action_pressed("lock_on"):
		if is_instance_valid(locked): locked = null
		else:
			var best = 18.0
			for e in get_tree().get_nodes_in_group("enemies"):
				var d = global_position.distance_to(e.global_position)
				if e.health>0 and d<best:
					best = d
					locked = e
	if event.is_action_pressed("heal"): heal()

func _physics_process(delta):
	invulnerable = maxf(0,invulnerable-delta)
	dodge_time = maxf(0,dodge_time-delta)
	if Game.mode == "menu": return
	if boat != null:
		global_transform = boat.rider_transform()
		visual.rotation = Vector3.ZERO
		visual.paddle_pose(delta,boat.stroke_phase,boat.stroke_power,boat.left_grip.global_position,boat.right_grip.global_position)
		set_traversal_equipment(true)
		update_camera(delta)
		return
	if climb_time > 0:
		visual.animate(delta,0,0,false,false)
		visual.climb_pose()
		set_traversal_equipment(true)
		climb_time -= delta
		velocity = Vector3.UP*3
		if climb_time <= 0:
			global_position += -visual.basis.z*1.5+Vector3.UP*.2
			set_traversal_equipment(false)
		move_and_slide()
		update_camera(delta)
		return
	# The hull's rocking never changes walking collision or camera heading.
	rotation = Vector3.ZERO
	swimming = global_position.y < .35 and Malanadu.height_at(global_position.x,global_position.z)<-.4
	if Game.active():
		var axes = Input.get_vector("left","right","forward","back")
		var direction = (Basis(Vector3.UP,yaw)*Vector3(axes.x,0,axes.y)).normalized()
		var sprinting = Input.is_action_pressed("sprint") and stamina>2 and axes.length()>.1 and not combat.blocking and not swimming
		var speed_value = 8.3 if sprinting else 4.6
		if swimming: speed_value = 2.8
		if combat.attacking(): speed_value *= .32
		if combat.blocking: speed_value *= .45
		if sprinting: stamina = maxf(0,stamina-delta*15)
		elif not combat.blocking and not combat.attacking() and dodge_time<=0: stamina = minf(100,stamina+delta*23)
		if Input.is_action_just_pressed("dodge") and dodge_time<=0 and stamina>=22 and not swimming:
			dodge_time = .48
			invulnerable = .30
			stamina -= 22
			dodge_dir = direction if direction.length()>.1 else -visual.basis.z
			combat.cancel()
			Game.fx.step(global_position,false,true)
			Game.audio.play("dodge")
		if dodge_time>0:
			velocity.x = dodge_dir.x*11
			velocity.z = dodge_dir.z*11
		else:
			var acceleration = 27.0 if is_on_floor() else (13.0 if swimming else 8.5)
			if axes.length()<.05: acceleration = 36.0 if is_on_floor() else (13.0 if swimming else 1.2)
			var target = direction*speed_value*axes.length()
			var horizontal = Vector2(velocity.x,velocity.z).move_toward(Vector2(target.x,target.z),delta*acceleration)
			velocity.x = horizontal.x
			velocity.z = horizontal.y
		if direction.length()>.1 and not is_instance_valid(locked):
			visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),minf(delta*14,1))
		if Input.is_action_just_pressed("jump") and (is_on_floor() or swimming):
			velocity.y = 7.2
			Game.fx.step(global_position,swimming or Game.app.weather.rain_strength>.3,true)
		if Input.is_action_just_pressed("climb"): try_climb()
	else:
		velocity.x = move_toward(velocity.x,0,delta*30)
		velocity.z = move_toward(velocity.z,0,delta*30)
	if swimming:
		velocity.y = 4.5 if Input.is_action_pressed("jump") else (-.6-global_position.y)*7
	else:
		if not is_on_floor(): velocity.y -= 21*delta
	if global_position.y < -12 or absf(global_position.x)>139 or absf(global_position.z)>139: respawn()
	var grounded_before = is_on_floor()
	previous_vertical_speed = velocity.y
	move_and_slide()
	if is_on_floor() and not grounded_before and velocity.y<1:
		Game.fx.step(global_position,swimming or Game.app.weather.rain_strength>.3,true)
		visual.landing = clampf(-previous_vertical_speed/10.0,0.0,1.0)
		landing_camera = visual.landing*.08
		shake(.035)
	var speed_horizontal = Vector2(velocity.x,velocity.z).length()
	var previous_gait = visual.clock
	var local_motion = visual.global_basis.inverse()*Vector3(velocity.x,0,velocity.z)
	visual.animate(delta,speed_horizontal,combat.progress(),combat.blocking,dodge_time>0,combat.combo,combat.weapon_id==1,local_motion,is_on_floor(),velocity.y)
	if speed_horizontal>1 and is_on_floor() and dodge_time<=0:
		if floori((previous_gait-PI*.5)/PI)!=floori((visual.clock-PI*.5)/PI):
			var side = 1.0 if sin(visual.clock)>0 else -1.0
			Game.fx.step(global_position+visual.basis.x*side*.13,Game.app.weather.rain_strength>.3)
	elif speed_horizontal>1 and swimming:
		step_clock += delta
		if step_clock>.72:
			step_clock = 0.0
			Game.fx.step(Vector3(global_position.x,.20,global_position.z),true)
	set_traversal_equipment(swimming)
	if swimming: visual.swim_pose()
	if is_instance_valid(locked):
		if locked.health<=0 or locked.global_position.distance_to(global_position)>23: locked = null
		else:
			var d = locked.global_position-global_position
			var target_yaw = atan2(-d.x,-d.z)
			visual.rotation.y = lerp_angle(visual.rotation.y,target_yaw,minf(delta*12,1))
			yaw = lerp_angle(yaw,target_yaw,delta*3.5)
	update_camera(delta)
	update_region()

func update_camera(delta):
	landing_camera = move_toward(landing_camera,0.0,delta*.45)
	var target = global_position+Vector3.UP*(1.45-landing_camera)
	if boat: target = boat.global_position+Vector3.UP*1.2
	rig.global_position = rig.global_position.lerp(target,1-exp(-delta*12))
	rig.rotation = Vector3(pitch,yaw,0)
	arm.spring_length = lerpf(arm.spring_length,9.0 if boat else camera_distance,delta*4)
	shake_amount = move_toward(shake_amount,0,delta*.7)
	camera.h_offset = randf_range(-shake_amount,shake_amount) if Game.shake_enabled else 0
	camera.v_offset = randf_range(-shake_amount,shake_amount) if Game.shake_enabled else 0
	camera.fov = lerpf(camera.fov,74 if velocity.length()>6 else 68,delta*3)

func shake(amount: float):
	shake_amount = maxf(shake_amount,amount)

func take_hit(damage: float, source: Node3D):
	if health<=0 or invulnerable>0: return "dodged"
	var dir = (source.global_position-global_position).normalized()
	var facing = (-visual.basis.z).dot(Vector3(dir.x,0,dir.z))>.05
	if combat.blocking and facing:
		if combat.block_age<.2 and stamina>=8:
			stamina -= 8
			combat.riposte = 2.5
			source.stagger(2.1)
			Game.fx.parry(global_position+Vector3.UP*1.2-visual.basis.z*.55)
			return "parry"
		if stamina >= damage*.85:
			stamina -= damage*.85
			Game.fx.impact(global_position+Vector3.UP,0,true)
			return "block"
		stamina = 0
		combat.blocking = false
		Game.notice.emit("Guard broken · dodge to recover")
	health = maxf(0,health-damage)
	invulnerable = .45
	velocity += -dir*4
	Game.fx.impact(global_position+Vector3.UP,int(damage))
	shake(.18)
	Game.ui.damage_flash()
	if health<=0:
		Game.audio.play("death")
		Game.ui.death_screen()
	return "hit"

func heal():
	if Game.herbs<=0: Game.notice.emit("No healing herbs. Visit Meera at the market."); return
	if health>=100: Game.notice.emit("Health is already full."); return
	Game.herbs -= 1
	health = minf(100,health+45)
	Game.fx.heal(global_position)

func respawn():
	health = 100
	stamina = 100
	invulnerable = 2
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	climb_time = 0.0
	swimming = false
	global_position = Game.SPAWN
	locked = null
	if boat:
		boat.occupied = false
		boat = null
	combat.cancel()
	if visual:
		visual.landing = 0.0
		visual.animate(.016,0,0,false,false)
		set_traversal_equipment(false)
	if rig: rig.global_position = global_position+Vector3.UP*1.4

func try_climb():
	for n in get_tree().get_nodes_in_group("interactables"):
		if n.get_meta("kind","") == "climb" and global_position.distance_to(n.global_position)<3:
			climb_time = 1.65
			visual.rotation.y = 0
			global_position = Vector3(n.global_position.x,n.global_position.y-1.0,n.global_position.z)
			stamina = maxf(0,stamina-15)
			Game.notice.emit("Climbing the old lookout")
			return
	Game.notice.emit("Climb at the ladder on the highland lookout.")

func update_region():
	var p = global_position
	var next = "AZHIMUKHAM · COASTAL VILLAGE"
	if p.x>43 and p.z<0: next = "VANAM · THE EMERALD FOREST"
	elif p.x>10: next = "KAYAL · THE BACKWATERS"
	elif p.z < -54: next = "MALAYORAM · MIST COUNTRY"
	elif p.z < -18: next = "KOTTA · THE OLD COURTYARD"
	if region!=next:
		region = next
		if Game.ui: Game.ui.region_enter(next)

func set_traversal_equipment(stowed: bool):
	visual.weapon_root.visible = not stowed
	visual.shield.visible = not stowed and combat.weapon_id==0

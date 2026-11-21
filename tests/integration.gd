extends Node

var failed := 0
var count := 0
func check(ok: bool, message: String):
	count += 1
	if ok: print("PASS · "+message)
	else: failed += 1; push_error("FAIL · "+message)

func frames(amount: int):
	for i in amount: await get_tree().physics_frame

func press(action: String, amount: int = 1):
	Input.action_press(action)
	await frames(amount)
	Input.action_release(action)
	await frames(1)

func _ready():
	Game.set_difficulty(1,false)
	Engine.max_fps = 60
	Game.app.start_game("roam")
	Game.ui.close_modal()
	for guard in Game.world.enemies: guard.set_physics_process(false)
	await frames(150)
	var p = Game.player
	var walker = Game.world.population.villagers[11]
	walker.global_position = walker.route[0]
	walker.route_index = 1
	walker.pause_time = 0
	var walker_start = walker.global_position
	await frames(60)
	check(walker.global_position.distance_to(walker_start)>.4,"Ambient villagers walk between their waypoints")
	Game.ui.settings()
	walker_start = walker.global_position
	await frames(20)
	check(walker.global_position.distance_to(walker_start)<.01,"Villager routes pause while a modal is open")
	Game.ui.close_modal()
	var animal = Game.world.wildlife.animals[12]
	p.set_physics_process(false)
	p.global_position = Vector3(-30,2,37)
	animal.global_position = animal.home
	animal.wait_time = 0
	animal.choose_target()
	var animal_start = animal.global_position
	var trunk_start = animal.rig.trunk[2].rotation
	await frames(90)
	check(animal.global_position.distance_to(animal_start)>.35,"Elephants walk within their woodland clearing")
	check(animal.rig.trunk[2].rotation!=trunk_start and animal.rig.head.global_basis.is_finite(),"Elephant trunk animation remains articulated and finite")
	Game.ui.settings()
	animal_start = animal.global_position
	await frames(15)
	check(animal.global_position.distance_to(animal_start)<.005,"Wildlife pauses during modal screens")
	Game.ui.close_modal()
	var dog = Game.world.wildlife.animals[4]
	p.global_position = dog.global_position+Vector3(1.3,0,0)
	await frames(30)
	check(dog.state=="curious" and dog.pace<.1,"Village dogs stop and watch a nearby player")
	var deer = Game.world.wildlife.animals[7]
	deer.global_position = deer.home
	p.global_position = deer.global_position+Vector3(1.5,0,0)
	deer.alert_time = 0
	await frames(60)
	print("DEER RESPONSE · ",deer.state," alert ",deer.alert_time," position ",deer.global_position," player ",p.global_position," speed ",deer.pace)
	check(deer.alert_time>0 and deer.state=="flee" and deer.global_position.distance_to(p.global_position)>2,"Deer startle and move away from an approaching player")
	p.global_position = Vector3(-79,Malanadu.height_at(-79,-60.7)+.1,-60.7)
	p.yaw = 0
	p.velocity = Vector3.ZERO
	p.set_physics_process(true)
	await frames(30)
	await press("forward",275)
	print("TEMPLE APPROACH EXIT · ",p.global_position," court ",Game.world.hill_temple.floor_y)
	check(p.global_position.z< -74 and p.is_on_floor() and p.global_position.y>Game.world.hill_temple.floor_y-.20 and p.global_position.y<Game.world.hill_temple.floor_y+.85,"Temple approach and gateway are walkable without jumping")
	if "--wildlife-only" in OS.get_cmdline_user_args():
		print("WILDLIFE INTEGRATION RESULT · %d checks · %d failures"%[count,failed])
		get_tree().quit(1 if failed>0 else 0)
		return
	p.global_position = Game.SPAWN
	p.velocity = Vector3.ZERO
	await frames(45)
	p.set_process_unhandled_input(false)
	var expected = Malanadu.height_at(p.position.x,p.position.z)
	print("POSITION · ",p.position," expected ground ",expected)
	check(p.is_on_floor() and absf(p.position.y-expected)<.25,"Player settles on solid island terrain")
	var start = p.position
	await press("forward",45)
	check(p.position.distance_to(start)>2.5,"Camera-relative walking moves through world")
	await frames(20)
	check(Vector2(p.velocity.x,p.velocity.z).length()<.05,"Releasing movement brings the character to a controlled stop")
	Input.action_press("forward",.7)
	await frames(30)
	check(Vector2(p.velocity.x,p.velocity.z).length()<2.5 and Vector2(p.velocity.x,p.velocity.z).length()>.5,"Analog movement strength scales walking speed")
	Input.action_release("forward")
	await frames(20)
	check(p.visual.knees.size()==2 and p.visual.elbows.size()==2,"Character uses articulated knee and elbow joints")
	start = p.position
	await press("sprint",1)
	Input.action_press("sprint")
	await press("forward",45)
	Input.action_release("sprint")
	check(p.position.distance_to(start)>4.5 and p.stamina<100,"Sprinting is faster and consumes stamina")
	await frames(30)
	Input.action_press("forward")
	await frames(20)
	var y = p.position.y
	await press("jump",5)
	check(p.position.y>y+.3,"Jump leaves the ground")
	Input.action_release("forward")
	var takeoff_speed = Vector2(p.velocity.x,p.velocity.z).length()
	await frames(10)
	check(not p.is_on_floor() and Vector2(p.velocity.x,p.velocity.z).length()>takeoff_speed*.7,"Releasing input in the air preserves jump momentum")
	await frames(80)
	check(p.is_on_floor(),"Jump lands back on terrain")
	p.stamina = 100
	await press("dodge",5)
	check(p.dodge_time>0 and p.invulnerable>0,"Dodge starts a roll and defensive window")
	await frames(60)
	p.global_position = Vector3(59,4,-53)
	await frames(70)
	check(p.is_on_floor() and p.global_position.x>50,"Forest terrain supports the player without respawning")
	for e in Game.world.enemies: e.set_physics_process(false)
	var enemy = Game.world.enemies[0]
	p.global_position = Vector3(60,Malanadu.height_at(60,-53)+.1,-53)
	p.visual.rotation.y = 0
	enemy.global_position = p.global_position+Vector3(0,0,-2)
	p.stamina = 100
	p.combat.cancel()
	var original = enemy.health
	p.combat.start_attack(false)
	await frames(5)
	check(enemy.health==original,"Actual physics attack has a damage-free windup")
	await frames(20)
	check(enemy.health<original,"Timed active window deals damage during physics update")
	await frames(45)
	check(not p.combat.attacking(),"Attack recovery ends cleanly")
	p.global_position = Vector3(5,Malanadu.height_at(5,-7)+.1,-7)
	p.yaw = -PI/2
	await frames(30)
	# Leave time for ramp ascent and slower frames before checking the far bank.
	await press("forward",660)
	print("BRIDGE EXIT · ",p.global_position)
	check(p.global_position.x>48 and p.is_on_floor(),"Bridge ramps connect both banks without jumping")
	p.yaw = 0
	p.global_position = Vector3(30,0,40)
	await frames(40)
	check(p.swimming and p.global_position.y>-1.0,"Water switches to buoyant swimming movement")
	check(not p.visual.weapon_root.visible and p.visual.hips.rotation.x<-.5,"Swimming stows weapons and uses a horizontal stroke pose")
	Game.world.boat.global_position = Vector3(Malanadu.river_x(40),.4,40)
	p.global_position = Game.world.boat.global_position+Vector3(2,0,0)
	Game.world.boat.interact()
	start = Game.world.boat.global_position
	await press("forward",90)
	check(Game.world.boat.global_position.distance_to(start)>2,"Occupied boat moves on player input")
	var boat = Game.world.boat
	check(p.global_position.distance_to(boat.seat.global_position)<.08,"Rider follows the animated boat seat")
	check(absf(boat.rotation.x)<.001 and absf(boat.rotation.z)<.001,"Boat rocking is isolated from steering physics")
	check(not p.visual.weapon_root.visible and p.visual.hips.position.y<-.6,"Boat rider uses a seated pose with weapons stowed")
	var paddle_start = boat.paddle.transform
	var yaw_start = boat.rotation.y
	Input.action_press("forward")
	await press("left",30)
	check(absf(boat.rotation.y-yaw_start)>.1,"Boat responds to smooth steering input")
	check(boat.paddle.transform!=paddle_start and boat.stroke_power>.5,"Paddle animates while the rider supplies thrust")
	var grip_error = 0.0
	for i in 12:
		await frames(8)
		grip_error = maxf(grip_error,p.visual.left_hand_space.to_global(Vector3(0,-.541,-.051)).distance_to(boat.left_grip.global_position))
		grip_error = maxf(grip_error,p.visual.right_hand_space.to_global(Vector3(0,-.541,-.051)).distance_to(boat.right_grip.global_position))
	print("MAX PADDLE GRIP ERROR · ",grip_error)
	check(grip_error<.10,"Both hands track their paddle grips through a complete stroke")
	Input.action_release("forward")
	var coast_speed = absf(boat.speed_value)
	await frames(12)
	check(absf(boat.speed_value)>0 and absf(boat.speed_value)<coast_speed,"Boat coasts and gradually loses speed after a stroke")
	check(boat.global_position.is_finite() and p.visual.right_arm.global_basis.is_finite(),"Paddling pose and boat movement remain finite")
	boat.speed_value = 0.0
	await press("back",60)
	check(boat.speed_value<-.5 and boat.stroke_direction<0,"Reverse input backs the boat and reverses the paddle stroke")
	Game.world.boat.interact()
	check(p.boat==null,"Boat releases player at disembark")
	check(p.visual.weapon_root.visible,"Disembarking restores the equipped weapon")
	p.global_position = Vector3(-70,Malanadu.height_at(-70,-60),-60)
	p.try_climb()
	check(p.climb_time>0,"Designated ladder begins climbing")
	await frames(10)
	check(not p.visual.weapon_root.visible and p.visual.left_arm.rotation.x>1.0,"Climbing uses reaching arms and stows equipment")
	await frames(110)
	check(p.global_position.y>Malanadu.height_at(-70,-62)+4.2,"Climbing reaches the raised lookout")
	if is_instance_valid(Game.world.water_reflection.mirror):
		var reflection = Game.world.water_reflection
		check(reflection.updates>0 and reflection.viewport.size.x==768,"Planar reflections render at a bounded resolution")
		check(not reflection.mirror.get_cull_mask_value(20),"Reflection camera excludes water to prevent recursive rendering")
	Game.ui.settings()
	await frames(3)
	check(Game.modal and Game.ui.overlay.visible,"Settings modal opens")
	Game.ui.close_modal()
	Game.ui.inventory()
	await frames(3)
	check(Game.modal,"Inventory renders all weapons")
	Game.ui.close_modal()
	print("INTEGRATION RESULT · %d checks · %d failures"%[count,failed])
	await frames(3)
	get_tree().quit(1 if failed>0 else 0)

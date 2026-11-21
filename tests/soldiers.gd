extends Node

var checks := 0
var failures := 0

func check(ok: bool,message: String):
	checks += 1
	if ok: print("PASS · "+message)
	else:
		failures += 1
		push_error("FAIL · "+message)

func frames(amount: int):
	for i in amount: await get_tree().physics_frame

func stage(id: String,center: Vector2) -> Array:
	var encounters = Game.world.encounters
	for squad in encounters.squads.values(): squad.alerted = false
	for enemy in Game.world.enemies:
		enemy.set_physics_process(false)
		enemy.global_position = enemy.home
		enemy.velocity = Vector3.ZERO
		enemy.state = "patrol"
		enemy.timer = 0
		enemy.cooldown = 0
		enemy.tell.hide()
	var player = Game.player
	player.global_position = Game.world.ground(center.x,center.y,.32)
	player.rig.global_position = player.global_position+Vector3.UP*1.4
	player.health = 100
	player.invulnerable = 100
	player.velocity = Vector3.ZERO
	player.combat.cancel()
	var members: Array = encounters.squads[id].members
	for i in members.size():
		var angle = i*TAU/members.size()
		members[i].global_position = player.global_position+Vector3(sin(angle),0,cos(angle))*1.85
		members[i].visual.rotation.y = angle+PI
	encounters.next_attack = encounters.clock+.05
	return members

func observe(amount: int) -> Vector2i:
	var peak = Vector2i.ZERO
	for i in amount:
		await frames(1)
		var strikes = 0
		for enemy in Game.world.enemies:
			if enemy.state=="strike": strikes += 1
		peak.x = maxi(peak.x,Game.world.encounters.attacking_count())
		peak.y = maxi(peak.y,strikes)
	return peak

func _ready():
	Engine.max_fps = 60
	Game.set_difficulty(1,false)
	Game.app.start_game("roam")
	Game.ui.close_modal()
	var player = Game.player
	player.set_process_unhandled_input(false)
	player.set_physics_process(false)
	await frames(10)
	var encounters = Game.world.encounters
	var squad = stage("scouts",Vector2(54,-19))
	squad[0].set_physics_process(true)
	await frames(8)
	check(encounters.squads.scouts.alerted and squad[1].state=="chase" and squad[2].state=="chase","One soldier alerts the rest of its squad")
	for enemy in squad: enemy.set_physics_process(true)
	var peak = await observe(210)
	print("NORMAL ATTACK PEAK · ",peak)
	check(peak.x>=2 and peak.y>=2,"Multiple soldiers overlap their windups and actual strikes")
	check(peak.x<=3,"Normal difficulty bounds concurrent attackers at three")
	check(player.health==100,"Invulnerability protects the player from simultaneous squad attacks")
	Game.ui.settings()
	var position_before: Vector3 = squad[0].global_position
	var timer_before: float = squad[0].timer
	await frames(20)
	check(position_before.distance_to(squad[0].global_position)<.001 and timer_before==squad[0].timer,"Soldier movement and attack timers pause during settings")
	check(Game.ui.modal_box.find_child("CombatDifficulty",true,false)!=null,"Settings expose a combat difficulty selector")
	Game.ui.close_modal()
	for enemy in Game.world.enemies: enemy.set_physics_process(false)
	var attacker = squad[1]
	attacker.global_position = player.global_position+Vector3(0,0,-1.7)
	attacker.visual.rotation.y = PI
	attacker.state = "windup"
	attacker.timer = attacker.windup_duration
	attacker.velocity = Vector3.ZERO
	player.invulnerable = 0
	attacker.set_physics_process(true)
	await frames(20)
	check(player.health==100 and attacker.tell.visible,"A soldier's warning ring precedes damage")
	await frames(50)
	check(player.health<100,"A committed soldier strike damages a player in reach")
	var health_after: float = player.health
	await frames(8)
	check(player.health==health_after,"A strike resolves damage only once")
	player.health = 100
	player.invulnerable = 0
	player.visual.rotation.y = 0
	player.combat.set_physics_process(false)
	player.combat.blocking = true
	player.combat.block_age = .1
	attacker.state = "windup"
	attacker.timer = .08
	await frames(10)
	check(player.health==100 and attacker.state=="stagger","A perfect parry interrupts a soldier's active strike")
	player.combat.blocking = false
	player.combat.set_physics_process(true)
	player.invulnerable = 1
	attacker.state = "windup"
	attacker.timer = .08
	await frames(10)
	check(player.health==100,"A dodge window avoids an incoming squad strike")
	attacker.set_physics_process(false)
	Game.set_difficulty(0,false)
	squad = stage("scouts",Vector2(54,-19))
	encounters.engage("scouts")
	for enemy in squad: enemy.set_physics_process(true)
	peak = await observe(180)
	check(peak.x==2,"Easy difficulty permits two attackers together")
	var easy_damage: float = squad[0].damage
	var easy_warning: float = squad[0].windup_duration
	Game.set_difficulty(2,false)
	check(squad[0].damage>easy_damage and squad[0].windup_duration<easy_warning,"Hard difficulty increases damage and shortens attack warnings")
	squad = stage("camp",Vector2(70,-67))
	encounters.engage("camp")
	for enemy in squad: enemy.set_physics_process(true)
	peak = await observe(210)
	print("HARD ATTACK PEAK · ",peak)
	check(peak.x==4,"Hard difficulty permits four concurrent attackers")
	check(Game.ui.encounter_text.visible and "LV 3" in Game.ui.encounter_text.text,"Encounter HUD identifies the nearby squad's level")
	Game.ui.settings()
	Game.set_difficulty(0,false)
	check(encounters.attacking_count()==0,"Changing difficulty cancels pending attacks before resuming")
	Game.ui.close_modal()
	player.health = 0
	await frames(8)
	check(not encounters.squads.camp.alerted and encounters.attacking_count()==0,"Squads disengage when the player dies")
	player.health = 100
	player.invulnerable = 100
	Game.set_difficulty(1,false)
	for enemy in Game.world.enemies: enemy.set_physics_process(false)
	var captain = squad[-1]
	captain.global_position = player.global_position+Vector3(0,0,-1.6)
	captain.visual.rotation.y = PI
	captain.state = "recover"
	var captain_health: float = captain.health
	captain.take_hit(20,player,false)
	check(captain.health==captain_health,"Captain guards frontal light blows during recovery")
	captain.take_hit(20,player,true)
	check(captain.health<captain_health and captain.state=="stagger","Heavy blows break the captain's guard")
	encounters.engage("camp")
	player.global_position = Game.SPAWN
	await frames(10)
	check(not encounters.squads.camp.alerted,"Soldiers stop pursuing beyond their encounter area")
	Game.app.start_game("roam")
	await frames(4)
	check(Game.world.enemies.size()==12 and encounters.living("camp")==5 and Game.defeated==0,"Starting a new run resets all squads and defeat progress")
	for enemy in Game.world.enemies: enemy.set_physics_process(false)
	player.set_physics_process(false)
	player.global_position = Game.world.ground(66,-55,.1)
	player.invulnerable = 100
	var guards: Array = encounters.squads.camp.members
	for guard in guards: guard.set_physics_process(true)
	await frames(30)
	check(encounters.squads.camp.alerted,"Camp sentries detect a player approaching along the real trail")
	await frames(480)
	var reached = 0
	for guard in guards:
		print("CAMP APPROACH · ",guard.role," · ",guard.global_position," · distance ",guard.global_position.distance_to(player.global_position)," · ",guard.state)
		if guard.global_position.distance_to(player.global_position)<5.5: reached += 1
	check(reached>=3,"Several soldiers reach the trail together from their original camp posts")
	for enemy in Game.world.enemies: enemy.set_physics_process(false)
	player.global_position = Game.world.ground(69,-55.7,.1)
	player.velocity = Vector3.ZERO
	player.yaw = 0
	player.set_physics_process(true)
	await frames(20)
	Input.action_press("forward")
	await frames(145)
	Input.action_release("forward")
	await frames(8)
	print("CAMP GATE EXIT · ",player.global_position)
	check(player.is_on_floor() and player.global_position.z< -63 and player.global_position.y>Malanadu.height_at(70,-67)+.15,"The camp gateway and raised floor are reachable without jumping")
	var guard = guards[0]
	guard.global_position = Game.world.ground(67,-67,.6)
	guard.velocity = Vector3.ZERO
	guard.state = "stagger"
	guard.timer = 100
	guard.set_physics_process(true)
	await frames(55)
	guard.state = "windup"
	guard.timer = guard.windup_duration
	await frames(3)
	check(guard.tell.visible and guard.tell.global_position.y>Malanadu.height_at(70,-67)+.24,"Soldier warning rings remain visible above the camp floor")
	print("SOLDIER RESULT · %d checks · %d failures"%[checks,failures])
	for audio_player in Game.audio.get_children():
		if audio_player is AudioStreamPlayer:
			audio_player.stop()
			audio_player.stream = null
	await get_tree().create_timer(.4,true,false,true).timeout
	get_tree().quit(0 if failures==0 else 1)

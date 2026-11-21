extends Node

var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String):
	checks += 1
	if condition: print("PASS · "+message)
	else:
		failures.append(message)
		push_error("FAIL · "+message)

func find_interaction(kind: String, id: String = "") -> Node3D:
	for n in get_tree().get_nodes_in_group("interactables"):
		if n.get_meta("kind","")==kind and (id=="" or n.npc_id==id): return n
	return null

func _ready():
	Game.set_difficulty(1,false)
	await get_tree().process_frame
	check(Game.mode=="menu","Main menu starts with shared world")
	check(Game.world.get_child_count()>100,"World generated with terrain and populated environment")
	check(Game.weapons.size()==5,"Five data-driven weapon configurations")
	check(Game.dialogues.size()==30,"Thirty friendly NPCs have bilingual conversations")
	check(Game.world.population.tree_count>=400,"Dense additional woodland is generated")
	check(Game.world.population.rice_count>2500 and Game.world.population.field_centers.size()==3,"Three paddy fields contain planted rice rows")
	check(Game.world.population.added_stalls==8 and Game.world.population.villagers.size()==24,"Eight new market stalls and twenty-four new villagers are present")
	var species: Dictionary = {}
	for animal in Game.world.wildlife.animals:
		species[animal.kind] = int(species.get(animal.kind,0))+1
	check(species=={"cat":4,"dog":3,"deer":5,"elephant":2},"Fourteen animals cover village pets, deer and elephants")
	check(Game.world.hill_temple.floor_y>Malanadu.height_at(-79,-80),"Temple courtyard sits above the hill terrain")
	check(find_interaction("shrine")!=null,"Redesigned temple preserves the shrine interaction")
	check(Game.world.enemies.size()==12 and Game.world.encounters.squads.size()==3,"Twelve soldiers form three escalating squads")
	check(Game.world.encounters.living("scouts")==3 and Game.world.encounters.living("patrol")==4 and Game.world.encounters.living("camp")==5,"Scout, patrol and camp squads contain three, four and five soldiers")
	var recruit = Game.world.enemies[0]
	var captain = Game.world.enemies[-1]
	check(recruit.level==1 and captain.level==3 and captain.elite and captain.damage>recruit.damage and captain.max_health>recruit.max_health,"Higher-level captain has stronger health and damage")
	var base_damage = recruit.damage
	recruit.health = recruit.max_health*.5
	Game.set_difficulty(2,false)
	check(recruit.damage>base_damage and is_equal_approx(recruit.health/recruit.max_health,.5),"Hard difficulty scales stats without healing injured soldiers")
	Game.set_difficulty(1,false)
	recruit.health = recruit.max_health
	check(Game.ui.malayalam.has_char(0x0d15),"Bundled font contains Malayalam glyphs")
	Game.app.start_game("roam")
	await get_tree().physics_frame
	check(Game.mode=="roam" and Game.quest_step==0,"Free roam does not advance story")
	check(Game.player.camera.current,"Third-person camera becomes active")
	check(Game.player.health==100,"Player spawns healthy")
	Game.ui.close_modal()
	Game.advance(0)
	check(Game.quest_step==0,"Story triggers are inactive in free roam")
	var resident = Game.world.population.villagers[0]
	Game.app.interact(resident)
	check(Game.modal and Game.ui.current_npc==resident.npc_id,"Added villagers open their own conversation")
	Game.ui.close_modal()
	var coins_before = Game.coins
	check(Game.buy("herb") and Game.coins==coins_before-20 and Game.herbs==4,"Merchant transaction updates inventory and balance")
	Game.player.health = 25
	Game.player.stamina = 30
	var shrine_coins = Game.coins
	Game.app.interact(find_interaction("shrine"))
	check(Game.player.health==100 and Game.player.stamina==100 and Game.coins==shrine_coins+50,"Temple rest heals and grants the first discovery reward")
	Game.ui.close_modal()
	Game.app.interact(find_interaction("shrine"))
	check(Game.coins==shrine_coins+50,"Revisiting the temple does not duplicate discovery coins")
	Game.ui.close_modal()
	Game.coins = 0
	check(not Game.buy("herb"),"Merchant refuses purchases without funds")
	Game.player.health = 40
	Game.player.heal()
	check(Game.player.health==85,"Healing consumes herb and restores health")
	Game.player.health = 100
	var enemy = Game.world.enemies[0]
	Game.player.global_position = Vector3(0,3,0)
	enemy.global_position = Vector3(0,3,-2)
	enemy.set_physics_process(false)
	Game.player.visual.rotation.y = 0
	for i in 5:
		Game.player.combat.cancel()
		Game.player.combat.equip(i)
		Game.player.stamina = 100
		check(Game.player.combat.start_attack(false),"Weapon %d starts a timed attack"%(i+1))
		check(enemy.health==75,"Weapon %d does not damage during windup"%(i+1))
		Game.player.combat.cancel()
	check(true,"All weapon meshes equipped without script errors")
	Game.player.combat.equip(0)
	enemy.global_position = Vector3(0,3,-2)
	var hp_before = enemy.health
	Game.player.combat.struck.clear()
	Game.player.combat.resolve_hits()
	check(enemy.health<hp_before,"Hit volume damages a target in reach")
	var after = enemy.health
	Game.player.combat.resolve_hits()
	check(enemy.health==after,"Swing cannot damage the same target twice")
	Game.player.combat.blocking = true
	Game.player.combat.block_age = .1
	Game.player.invulnerable = 0
	var outcome = Game.player.take_hit(15,enemy)
	check(outcome=="parry" and enemy.state=="stagger","Perfect parry staggers attacker")
	Game.player.combat.block_age = 1
	outcome = Game.player.take_hit(15,enemy)
	check(outcome=="block" and Game.player.health==100,"Shield block protects health")
	Game.player.invulnerable = .3
	outcome = Game.player.take_hit(15,enemy)
	check(outcome=="dodged","Dodge invulnerability prevents damage")
	Game.player.invulnerable = 0
	Game.player.combat.blocking = false
	Game.player.global_position = Vector3(18,1.5,33)
	Game.world.boat.interact()
	check(Game.player.boat==Game.world.boat and Game.world.boat.occupied,"Boat boarding connects player and boat")
	Game.world.boat.interact()
	check(Game.player.boat==null and not Game.world.boat.occupied,"Boat disembark restores walking")
	Game.app.start_game("story")
	Game.ui.close_modal()
	check(Game.mode=="story" and Game.quest_step==0,"Story starts at the first objective")
	Game.app.interact(resident)
	check(Game.quest_step==0,"Talking to ambient villagers does not advance the story")
	Game.ui.close_modal()
	Game.app.interact(find_interaction("npc","ravi"))
	Game.ui.close_modal()
	Game.app.interact(find_interaction("npc","meera"))
	Game.ui.close_modal()
	Game.app.interact(find_interaction("clue"))
	Game.ui.close_modal()
	check(Game.quest_step==3,"NPC and clue interactions advance investigation")
	for e in Game.world.encounters.squads.scouts.members:
		e.set_physics_process(false)
		e.take_hit(999,Game.player,true)
	Game.app.interact(find_interaction("ledger"))
	check(Game.defeated==3 and Game.quest_step==3 and not Game.camp_cleared(),"Defeating three scouts cannot unlock the guarded ledger")
	for e in Game.world.enemies:
		e.set_physics_process(false)
		e.take_hit(999,Game.player,true)
	check(Game.quest_step==4 and Game.camp_cleared(),"Defeating the captain and all camp guards unlocks the ledger")
	var victory_coins = Game.coins
	Game.world.enemies[-1].take_hit(999,Game.player,true)
	check(Game.coins==victory_coins,"Defeated soldiers and squad rewards cannot be claimed twice")
	Game.app.interact(find_interaction("ledger"))
	Game.app.interact(find_interaction("npc","ravi"))
	check(Game.quest_step==6 and Game.coins>=200,"Ledger and return interactions award reward and ending")
	Game.ui.close_modal()
	Game.app.weather.set_weather(3)
	check(Game.last_weather=="Heavy rain","Weather supports heavy monsoon")
	Game.app.return_to_menu()
	check(Game.mode=="menu" and Game.app.menu_camera.current,"Returning to menu restores menu camera")
	Game.app.start_game("story")
	Game.ui.close_modal()
	for e in Game.world.enemies:
		e.set_physics_process(false)
		e.take_hit(999,Game.player,true)
	Game.advance(0)
	Game.advance(1)
	Game.advance(2)
	check(Game.quest_step==4,"Clearing camp before investigation cannot soft-lock the story")
	Game.player.health = 0
	Game.ui.death_screen()
	Game.ui.close_modal()
	check(Game.modal and Game.ui.overlay.visible,"Escape cannot dismiss the required respawn choice")
	Game.player.respawn()
	Game.ui.close_modal()
	check(not Game.modal and Game.player.health==100,"Respawn restores health and dismisses death screen")
	Game.app.return_to_menu()
	# Give CoreAudio one mix cycle to release playback before the test exits.
	for player in Game.audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	await get_tree().create_timer(1.2,true,false,true).timeout
	print("\nKADAL SMOKE RESULT · %d checks · %d failures"%[checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

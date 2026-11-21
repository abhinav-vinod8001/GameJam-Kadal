class_name SoldierEncounters
extends Node3D

const SQUADS = [
	{"id":"scouts","title":"BRIDGE SCOUTS","level":1,"center":Vector2(54,-19),
		"positions":[Vector2(52,-17),Vector2(56,-20),Vector2(52,-22)],
		"roles":["spearman","swordsman","spearman"]},
	{"id":"patrol","title":"FOREST PATROL","level":2,"center":Vector2(61,-39),
		"positions":[Vector2(58,-36),Vector2(64,-38),Vector2(60,-42),Vector2(65,-43)],
		"roles":["swordsman","spearman","swordsman","spearman"]},
	{"id":"camp","title":"THE CAPTAIN'S GUARD","level":3,"center":Vector2(69,-64),
		"positions":[Vector2(63,-57),Vector2(72,-58),Vector2(66,-64),Vector2(73,-68),Vector2(69,-70)],
		"roles":["spearman","swordsman","spearman","swordsman","captain"]}
]
var world: Malanadu
var squads: Dictionary = {}
var clock := 0.0
var next_attack := 0.0
var difficulty_index := 1

static func contains_site(x: float,z: float) -> bool:
	for data in SQUADS:
		if Vector2(x,z).distance_to(data.center)<6.5: return true
	return false

func _ready():
	name = "SoldierEncounters"
	world = get_parent()
	for data in SQUADS.slice(0,2):
		var site = world.ground(data.center.x+4.4,data.center.y,.02)
		var timber = Craft.mat("5e4733")
		Craft.beam(self,site,site+Vector3.UP*3.4,.065,timber)
		Craft.box(self,site+Vector3(.48,2.78,0),Vector3(.94,.70,.035),Craft.mat("9a5940" if data.level==1 else "7f3835"))
		Craft.box(self,site+Vector3(.48,2.78,-.025),Vector3(.055,.58,.02),Craft.mat("d3b16c"))
		for i in 2:
			Craft.box(self,world.ground(site.x+.7+i*.85,site.z+.5,.3),Vector3(.7,.6,.6),timber,true)

func reset():
	for enemy in world.enemies:
		if not is_instance_valid(enemy): continue
		enemy.set_physics_process(false)
		enemy.remove_from_group("enemies")
		enemy.collision_layer = 0
		enemy.collision_mask = 0
		enemy.queue_free()
	world.enemies.clear()
	squads.clear()
	clock = 0
	next_attack = 0
	difficulty_index = Game.difficulty
	for data in SQUADS:
		var members: Array = []
		squads[data.id] = {"data":data,"members":members,"alerted":false,"cleared":false}
		for i in data.positions.size():
			var point: Vector2 = data.positions[i]
			var enemy = load("res://scripts/enemies/enemy.gd").new()
			enemy.encounters = self
			enemy.squad_id = data.id
			enemy.level = data.level
			enemy.role = data.roles[i]
			enemy.elite = enemy.role=="captain"
			enemy.formation_angle = i*TAU/data.positions.size()
			enemy.position = world.ground(point.x,point.y,.55)
			add_child(enemy)
			members.append(enemy)
			world.enemies.append(enemy)
	print("SOLDIERS · 12 soldiers · 3 squads · levels 1–3 · ",profile().name)

func profile() -> Dictionary:
	return Game.DIFFICULTIES[difficulty_index]

func living(id: String) -> int:
	if not squads.has(id): return 0
	var total = 0
	for enemy in squads[id].members:
		if is_instance_valid(enemy) and not enemy.dead: total += 1
	return total

func is_cleared(id: String) -> bool:
	return squads.has(id) and squads[id].cleared

func engage(id: String):
	if not squads.has(id) or squads[id].cleared: return
	var squad = squads[id]
	if not squad.alerted:
		squad.alerted = true
		Game.notice.emit("LV %d · %s · %d soldiers alerted"%[squad.data.level,squad.data.title,living(id)])
	for enemy in squad.members:
		if not enemy.dead and enemy.state in ["patrol","return"]:
			enemy.state = "chase"
			enemy.cooldown = maxf(enemy.cooldown,.45)

func attacking_count() -> int:
	var total = 0
	for enemy in world.enemies:
		if is_instance_valid(enemy) and not enemy.dead and enemy.state in ["windup","strike"]: total += 1
	return total

func try_attack(enemy: Node3D) -> bool:
	if not squads.has(enemy.squad_id) or not squads[enemy.squad_id].alerted: return false
	if clock<next_attack or attacking_count()>=int(profile().attackers): return false
	next_attack = clock+float(profile().spacing)
	return true

func defeated(enemy: Node3D):
	var squad = squads[enemy.squad_id]
	if living(enemy.squad_id)==0 and not squad.cleared:
		squad.cleared = true
		squad.alerted = false
		var bonus = 20*int(squad.data.level)
		Game.coins += bonus
		Game.herbs += 1
		Game.notice.emit("%s ROUTED · +%d fanam · +1 healing herb"%[squad.data.title,bonus])
		Game.audio.play("discover",-4)
	Game.defeated_enemy()

func disengage(id: String):
	squads[id].alerted = false
	for enemy in squads[id].members:
		if enemy.dead: continue
		enemy.state = "return"
		enemy.timer = 0
		enemy.cooldown = 1.3
		enemy.tell.hide()

func _physics_process(delta):
	if Game.mode=="menu" or Game.modal or not is_instance_valid(Game.player): return
	clock += delta
	for id in squads:
		if not squads[id].alerted: continue
		var center: Vector2 = squads[id].data.center
		var player_site = Vector2(Game.player.global_position.x,Game.player.global_position.z)
		if Game.player.health<=0 or Game.player.boat!=null or player_site.distance_to(center)>30:
			disengage(id)

func apply_difficulty(index: int):
	difficulty_index = clampi(index,0,Game.DIFFICULTIES.size()-1)
	for enemy in world.enemies:
		if enemy.dead: continue
		enemy.configure_stats(true)
		if enemy.state in ["windup","strike"]:
			enemy.state = "recover"
			enemy.timer = .7
			enemy.tell.hide()
	next_attack = clock+.7

func nearby_squad() -> Dictionary:
	if not is_instance_valid(Game.player): return {}
	var best = 24.0
	var found: Dictionary = {}
	for id in squads:
		var data = squads[id].data
		var center: Vector2 = data.center
		var distance_value = Vector2(Game.player.global_position.x,Game.player.global_position.z).distance_to(center)
		if distance_value<best:
			best = distance_value
			found = {"id":id,"title":data.title,"level":data.level,"remaining":living(id),"total":data.positions.size(),"cleared":squads[id].cleared}
	return found

# The camp's broken wall has one wide gateway. Route through it before fanning out.
func approach_point(enemy: Node3D,destination: Vector3) -> Vector3:
	if enemy.squad_id!="camp": return destination
	if enemy.global_position.z< -61.3 and destination.z> -61.3:
		return Vector3(69,destination.y,-59.2)
	if enemy.global_position.z> -62.7 and destination.z< -62.7:
		return Vector3(69,destination.y,-64)
	return destination

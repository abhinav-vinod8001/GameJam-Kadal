extends Node

var actor
var weapon_id := 0
var combo := 0
var timer := 0.0
var total_time := 0.0
var hit_done := false
var heavy := false
var blocking := false
var block_age := 1.0
var buffer := false
var combo_age := 0.0
var riposte := 0.0
var struck: Array = []

func _ready():
	actor = get_parent()

func attacking() -> bool: return timer>0
func progress() -> float: return 1.0-timer/total_time if timer>0 and total_time>0 else 0.0

func _unhandled_input(event):
	if not Game.active() or actor.boat!=null: return
	for i in 5:
		if event.is_action_pressed("weapon_%d"%i): equip(i)
	if event.is_action_pressed("attack"):
		if attacking() and timer<total_time*.5: buffer = true
		else: start_attack(false)
	if event.is_action_pressed("heavy"): start_attack(true)

func equip(id: int):
	if attacking(): return
	weapon_id = id
	actor.visual.set_weapon(id)
	combo = 0
	Game.audio.play("equip")
	Game.notice.emit(Game.weapons[id].type + " · " + Game.weapons[id].name)

func start_attack(is_heavy: bool) -> bool:
	if attacking() or actor.dodge_time>0 or actor.swimming or actor.health<=0: return false
	var data = Game.weapons[weapon_id]
	var cost = float(data.cost)*(1.7 if is_heavy else 1.0)
	if actor.stamina<cost:
		Game.notice.emit("Catch your breath · stamina low")
		return false
	actor.stamina -= cost
	heavy = is_heavy
	combo = (combo+1)%3 if combo_age<.8 else 0
	total_time = float(data.duration)*(1.45 if heavy else 1.0)
	timer = total_time
	hit_done = false
	blocking = false
	struck.clear()
	buffer = false
	# A nearby target draws the warrior's aim slightly, while preserving manual facing.
	var best = 5.0
	var target = null
	for e in get_tree().get_nodes_in_group("enemies"):
		var diff = e.global_position-actor.global_position
		if e.health>0 and diff.length()<best and (-actor.visual.basis.z).dot(diff.normalized())>.35:
			best = diff.length()
			target = e
	if target:
		var diff = target.global_position-actor.global_position
		actor.visual.rotation.y = atan2(-diff.x,-diff.z)
	return true

func _physics_process(delta):
	if not Game.active():
		blocking = false
		return
	riposte = maxf(0,riposte-delta)
	combo_age += delta
	var wants_block = Input.is_action_pressed("block") and timer<=0 and actor.dodge_time<=0 and actor.boat==null
	if wants_block and not blocking: block_age = 0
	blocking = wants_block
	block_age += delta
	if timer<=0: return
	timer -= delta
	var elapsed = total_time-timer
	var data = Game.weapons[weapon_id]
	var windup = float(data.windup)*(1.45 if heavy else 1.0)
	if elapsed>=windup and not hit_done:
		hit_done = true
		Game.fx.swing(actor,weapon_id,heavy,combo)
	# Short active window catches movement through the actual swing, once per target.
	if elapsed>=windup and elapsed<windup+.16:
		resolve_hits()
	if timer<=0:
		combo_age = 0
		if buffer: start_attack(false)

func resolve_hits():
	var data = Game.weapons[weapon_id]
	var reach = float(data.reach)*(1.16 if heavy else 1.0)
	var forward = -actor.visual.basis.z
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.health<=0 or struck.has(e): continue
		var diff = e.global_position-actor.global_position
		diff.y = 0
		if diff.length()>reach or absf(actor.global_position.y-e.global_position.y)>2: continue
		var angle = acos(clampf(forward.dot(diff.normalized()),-1,1))
		if angle>float(data.arc)/2: continue
		var query = PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP,e.global_position+Vector3.UP,1)
		if not actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		struck.append(e)
		var amount = float(data.damage)*(1.9 if heavy else 1.0)*(1+Game.upgrade*.15)
		if combo == 2: amount *= 1.25
		if riposte>0:
			amount *= 1.8
			riposte = 0
			Game.fx.floating(e.global_position+Vector3.UP*2,"COUNTER",Color("f9dfa2"))
		e.take_hit(amount,actor,heavy or combo==2)

func cancel():
	timer = 0
	buffer = false
	blocking = false

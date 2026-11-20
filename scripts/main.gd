extends Node3D

var menu_camera: Camera3D
var weather
var nearest: Node3D
var menu_clock := 0.0
var marker: Node3D

func _ready():
	Game.app = self
	Game.world = Malanadu.new()
	add_child(Game.world)
	weather = load("res://scripts/weather/weather.gd").new()
	add_child(weather)
	Game.fx = load("res://scripts/combat/effects.gd").new()
	add_child(Game.fx)
	Game.audio = load("res://scripts/managers/audio.gd").new()
	add_child(Game.audio)
	Game.player = KadalPlayer.new()
	Game.player.position = Game.SPAWN
	add_child(Game.player)
	Game.player.hide()
	menu_camera = Camera3D.new()
	menu_camera.position = Vector3(45,13,67)
	menu_camera.fov = 58
	menu_camera.far = 700
	add_child(menu_camera)
	menu_camera.look_at(Vector3(-5,2,9))
	menu_camera.current = true
	Game.ui = load("res://scripts/ui/interface.gd").new()
	add_child(Game.ui)
	if "--smoke" in OS.get_cmdline_user_args():
		call_deferred("smoke_test")
	if "--integration" in OS.get_cmdline_user_args():
		call_deferred("integration_test")
	if "--capture" in OS.get_cmdline_user_args():
		call_deferred("capture_tour")
	if "--play" in OS.get_cmdline_user_args():
		call_deferred("start_game","roam")

func start_game(mode_value: String):
	Game.reset_run(mode_value)
	Game.world.reset_enemies()
	for n in get_tree().get_nodes_in_group("interactables"):
		if n.get_meta("kind","") in ["chest","herb"]:
			n.set_meta("opened",false)
			for c in n.get_children():
				if c is MeshInstance3D: c.show()
	Game.player.respawn()
	Game.player.show()
	Game.player.camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Game.ui.show_hud()
	if mode_value == "story": Game.ui.introduction()
	else: Game.notice.emit("Welcome to Malanadu · M opens the map · 1–5 change weapons")

func return_to_menu():
	Game.mode = "menu"
	Game.modal = false
	Game.player.hide()
	Game.player.combat.cancel()
	menu_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Game.ui.show_menu()

func _process(delta):
	menu_clock += delta
	if Game.mode=="menu":
		menu_camera.position = Vector3(45+sin(menu_clock*.045)*3,13+sin(menu_clock*.1)*.3,67)
		menu_camera.look_at(Vector3(-5,2,9))
		return
	if Game.active(): find_interaction()

func find_interaction():
	nearest = null
	var distance_value = 3.2
	if Game.player.boat:
		nearest = Game.player.boat
		Game.ui.set_prompt("Disembark from the vanchi")
		return
	for n in get_tree().get_nodes_in_group("interactables"):
		if n.get_meta("opened",false): continue
		var d = n.global_position.distance_to(Game.player.global_position+Vector3.UP*.6)
		if n.get_meta("kind","")=="boat": d -= 1.6
		if d<distance_value:
			distance_value = d
			nearest = n
	Game.ui.set_prompt(nearest.get_meta("prompt","") if nearest else "")

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if Game.mode=="menu":
			if Game.modal: Game.ui.close_modal()
		elif Game.modal: Game.ui.close_modal()
		else: Game.ui.pause_menu()
		get_viewport().set_input_as_handled()
		return
	if not Game.active(): return
	if event.is_action_pressed("interact") and is_instance_valid(nearest): interact(nearest)
	if event.is_action_pressed("inventory"): Game.ui.inventory()
	if event.is_action_pressed("map"): Game.ui.map_screen()
	if event.is_action_pressed("weather"): weather.cycle()

func interact(n: Node3D):
	var kind = n.get_meta("kind","")
	match kind:
		"npc":
			if n.npc_id=="ravi" and Game.mode=="story" and Game.quest_step==5:
				Game.advance(5)
				return
			Game.ui.dialogue(n.npc_id)
			if n.npc_id=="ravi": Game.advance(0)
			if n.npc_id=="meera": Game.advance(1)
		"boat": n.interact()
		"clue":
			if Game.mode=="story" and Game.quest_step<2:
				Game.notice.emit("A torn red sail. Ravi at the village jetty may know more.")
				return
			Game.ui.clue()
			Game.advance(2)
		"ledger":
			if Game.defeated<3:
				Game.notice.emit("The raiders are guarding the ledger. Defeat all three.")
				return
			if Game.mode=="story" and Game.quest_step<4:
				Game.notice.emit("A cargo ledger. Investigate the torn sail at the backwater first.")
				return
			Game.advance(4)
			Game.notice.emit("Ledger recovered · the missing villagers escaped downriver.")
			Game.fx.heal(n.global_position)
		"chest":
			if n.get_meta("opened",false): return
			n.set_meta("opened",true)
			Game.coins += 30
			Game.herbs += 1
			Game.fx.burst(n.global_position,Color("dcc27f"),25,3)
			Game.audio.play("discover")
			Game.notice.emit("Travel chest · +30 fanam · +1 healing herb")
			for c in n.get_children():
				if c is MeshInstance3D: c.hide()
		"herb":
			if n.get_meta("opened",false): return
			n.set_meta("opened",true)
			Game.herbs += 1
			Game.fx.burst(n.global_position,Color("b4cd8e"),14,1.3)
			Game.audio.play("heal",-8)
			Game.notice.emit("Medicinal leaves gathered · +1 healing herb")
			for c in n.get_children():
				if c is MeshInstance3D: c.hide()
		"shrine":
			Game.player.health = 100
			Game.player.stamina = 100
			Game.fx.heal(Game.player.global_position)
			if not Game.discovered.has("shrine"):
				Game.discovered.append("shrine")
				Game.coins += 50
			Game.ui.shrine()
		"climb": Game.player.try_climb()
		"door":
			var opened = n.get_meta("door_open",false)
			n.set_meta("door_open",not opened)
			var tween = create_tween()
			tween.tween_property(n,"rotation:y",0.0 if opened else PI*.55,.35)
			Game.audio.play("staff",-10)

func smoke_test():
	var runner = load("res://tests/smoke.gd").new()
	add_child(runner)

func capture_tour():
	var runner = load("res://tests/capture.gd").new()
	add_child(runner)

func integration_test():
	var runner = load("res://tests/integration.gd").new()
	add_child(runner)

func _exit_tree():
	Engine.time_scale = 1.0
	Craft.cache.clear()
	Craft.geometry.clear()

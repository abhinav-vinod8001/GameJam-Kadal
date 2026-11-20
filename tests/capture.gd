extends Node

func shot(id: String):
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+id+".png")
	print("CAPTURE · "+id+" · FPS "+str(Engine.get_frames_per_second())+" · Draws "+str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))

func _ready():
	if "--wildlife" in OS.get_cmdline_user_args():
		await wildlife_tour()
		await finish()
		return
	if "--population" in OS.get_cmdline_user_args():
		await population_tour()
		await finish()
		return
	if "--water-motion" in OS.get_cmdline_user_args():
		await water_motion_tour()
		await finish()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	await shot("01-menu")
	Game.app.start_game("story")
	await shot("02-prologue")
	Game.ui.close_modal()
	await get_tree().create_timer(2).timeout
	await shot("03-village")
	if "--quick" in OS.get_cmdline_user_args():
		await finish()
		return
	Game.world.get_node("Water").hide()
	await shot("03b-terrain")
	Game.world.get_node("Water").show()
	Game.ui.dialogue("meera")
	await shot("04-dialogue")
	Game.ui.shop()
	await shot("05-shop")
	Game.ui.map_screen()
	await shot("06-map")
	Game.ui.close_modal()
	Game.player.global_position = Vector3(57,3,-54)
	Game.player.yaw = -.55
	Game.player.pitch = -.25
	for e in Game.world.enemies: e.set_physics_process(false)
	await get_tree().create_timer(1).timeout
	Game.fx.swing(Game.player,0,true,0)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/07-sword.png")
	Game.player.combat.equip(1)
	await shot("08-spear")
	Game.app.weather.set_weather(3)
	await get_tree().create_timer(5).timeout
	await shot("09-monsoon")
	Game.ui.settings()
	await shot("10-settings")
	Game.ui.close_modal()
	Game.player.global_position = Vector3(-77,Malanadu.height_at(-77,-75)+.2,-75)
	Game.player.yaw = -PI*.85
	Game.player.pitch = -.3
	await get_tree().create_timer(1).timeout
	await shot("11-highland")
	Game.app.weather.set_weather(0)
	Game.player.global_position = Vector3(-30,Malanadu.height_at(-30,37)+.08,37)
	Game.player.visual.rotation.y = -.29
	await get_tree().create_timer(6.0).timeout
	var portrait = Camera3D.new()
	get_tree().current_scene.add_child(portrait)
	portrait.fov = 44
	var focus: Vector3 = Game.player.global_position
	portrait.position = focus+Vector3(1.18,1.27,-2.72)
	portrait.look_at(focus+Vector3(0,1.03,0))
	portrait.make_current()
	Game.ui.hud.hide()
	await shot("12-arun")
	var falls = Vector3(101,Malanadu.height_at(101,-89),-89)
	portrait.position = falls+Vector3(7.5,4.8,-15.0)
	portrait.look_at(falls+Vector3(0,3.4,-2.0))
	await shot("13-waterfall")
	# Render the supplied reference categories using the real playable assets.
	Game.player.set_physics_process(false)
	Game.player.global_position = Vector3(-30,Malanadu.height_at(-30,37)+.04,37)
	Game.player.visual.rotation.y = -.29
	Game.player.visual.animate(.016,0,0,false,false)
	Game.player.combat.equip(0)
	focus = Game.player.global_position
	portrait.position = focus+Vector3(1.18,1.27,-2.72)
	portrait.look_at(focus+Vector3(0,1.06,0))
	await shot("14-reference-arun")
	Game.player.combat.equip(1)
	await shot("15-reference-kuntham")
	portrait.position = Vector3(-35.6,3.45,24.2)
	portrait.look_at(Vector3(-43,3.0,35))
	await shot("16-reference-cottage")
	portrait.position = Vector3(-13,3.35,7.2)
	portrait.look_at(Vector3(-15,2.20,14))
	await shot("17-reference-market")
	portrait.position = Vector3(58.8,4.2,-52.9)
	portrait.look_at(Vector3(68.6,3.1,-66.5))
	await shot("18-reference-ruins")
	Game.player.set_physics_process(true)
	Game.ui.hud.show()
	Game.player.camera.make_current()
	portrait.queue_free()
	# Let rendering settle after PNG writes before recording capped frame rate.
	Game.ui.hud.show()
	Game.player.camera.make_current()
	for view in [
		["village",Vector3(-30,Malanadu.height_at(-30,37)+.03,37),0.0],
		["backwater",Vector3(12,Malanadu.height_at(12,28)+.03,28),-PI*.35],
		["forest-rain",Vector3(57,Malanadu.height_at(57,-54)+.03,-54),-.55]]:
		Game.player.global_position = view[1]
		Game.player.yaw = view[2]
		Game.app.weather.rain_strength = 1.0 if view[0]=="forest-rain" else 0.0
		Game.app.weather.cloud_strength = Game.app.weather.rain_strength
		Game.app.weather.set_weather(3 if view[0]=="forest-rain" else 0)
		await get_tree().create_timer(3.0).timeout
		print("RENDER SAMPLE · ",view[0]," · ",Engine.get_frames_per_second()," FPS · ",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," draws")
	print("CAPTURE · TOUR COMPLETE")
	await finish()

func finish():
	for player in Game.audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	await get_tree().create_timer(.35,true,false,true).timeout
	get_tree().quit()

func water_motion_tour():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	Game.app.start_game("roam")
	Game.ui.close_modal()
	for e in Game.world.enemies: e.set_physics_process(false)
	Game.app.weather.manual = true
	Game.app.weather.set_weather(0)
	await get_tree().create_timer(2.0).timeout
	var boat = Game.world.boat
	boat.global_position = Vector3(30,.4,39)
	var view = Camera3D.new()
	get_tree().current_scene.add_child(view)
	view.fov = 52
	view.position = Vector3(38,3.2,46)
	view.look_at(Vector3(26,.6,29))
	view.make_current()
	Game.ui.hud.hide()
	await shot("19-water-clear")
	if Game.world.water_reflection.viewport:
		Game.world.water_reflection.viewport.get_texture().get_image().save_png("res://artifacts/reflection-buffer.png")
	view.position = boat.global_position+Vector3(4.6,2.5,-4.8)
	view.look_at(boat.global_position+Vector3(0,.45,0))
	await shot("20-vanchi")
	boat.interact()
	Input.action_press("forward")
	await get_tree().create_timer(1.0).timeout
	view.position = boat.global_position+Vector3(4.6,2.5,-4.8)
	view.look_at(boat.global_position+Vector3(0,.65,0))
	await shot("21-paddling")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/paddle-frames"))
	for i in 24:
		view.position = boat.global_position+Vector3(4.6,2.5,-4.8)
		view.look_at(boat.global_position+Vector3(0,.65,0))
		await get_tree().create_timer(.075).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/paddle-frames/%02d.png"%i)
	Input.action_release("forward")
	print("PADDLE GRIPS · left ",Game.player.visual.left_hand_space.to_global(Vector3(0,-.541,-.051)).distance_to(boat.left_grip.global_position)," · right ",Game.player.visual.right_hand_space.to_global(Vector3(0,-.541,-.051)).distance_to(boat.right_grip.global_position))
	boat.interact()
	Game.app.weather.set_weather(3)
	Game.app.weather.rain_strength = 1.0
	Game.app.weather.cloud_strength = 1.0
	view.position = Vector3(39,2.8,45)
	view.look_at(Vector3(24,.5,27))
	await shot("22-water-monsoon")
	Game.app.weather.set_weather(0)
	Game.app.weather.rain_strength = 0.0
	Game.app.weather.cloud_strength = 0.0
	Game.player.global_position = Vector3(-30,Malanadu.height_at(-30,37)+.03,37)
	Game.player.yaw = 0
	view.position = Game.player.global_position+Vector3(2.7,1.3,-3.8)
	view.look_at(Game.player.global_position+Vector3.UP)
	Input.action_press("forward")
	Input.action_press("sprint")
	await get_tree().create_timer(.4).timeout
	view.position = Game.player.global_position+Vector3(2.7,1.3,-3.8)
	view.look_at(Game.player.global_position+Vector3.UP)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/23-running.png")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/run-frames"))
	for i in 24:
		view.position = Game.player.global_position+Vector3(2.7,1.3,-3.8)
		view.look_at(Game.player.global_position+Vector3.UP)
		await get_tree().create_timer(.055).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/run-frames/%02d.png"%i)
	Input.action_release("forward")
	Input.action_release("sprint")
	Game.player.global_position = Vector3(34,-.5,43)
	await get_tree().create_timer(.6).timeout
	view.position = Game.player.global_position+Vector3(3.5,2.0,-3.0)
	view.look_at(Game.player.global_position+Vector3(0,.65,0))
	await shot("24-swimming")
	Game.ui.hud.show()
	Game.player.camera.make_current()
	view.queue_free()
	for sample in [["village",Vector3(-30,Malanadu.height_at(-30,37)+.03,37)],
		["waterfront",Vector3(18,1.4,33)],["boat",Vector3(30,.4,39)]]:
		if sample[0]=="boat":
			boat.global_position=sample[1]
			boat.interact()
		else: Game.player.global_position=sample[1]
		await get_tree().create_timer(3.0).timeout
		print("WATER MOTION SAMPLE · ",sample[0]," · ",Engine.get_frames_per_second()," FPS · ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," draws")
	print("WATER MOTION TOUR COMPLETE")

func population_tour():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	Game.app.start_game("roam")
	Game.ui.close_modal()
	Game.app.weather.manual = true
	Game.app.weather.set_weather(0)
	for enemy in Game.world.enemies: enemy.set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	await shot("25-lived-in-village")
	var view = Camera3D.new()
	get_tree().current_scene.add_child(view)
	view.fov = 62
	view.make_current()
	Game.ui.hud.hide()
	var sites = [
		["26-market-crowd",Vector3(-30,4.2,30),Vector3(-14,1.9,14),Vector3(-24,1.8,28)],
		["27-rice-fields",Vector3(46,5.8,44),Vector3(75,1.7,51),Vector3(59,2,40)],
		["28-paddy-workers",Vector3(62,2.9,40),Vector3(58,2.1,47),Vector3(59,2,42)],
		["29-forest-trail",Vector3(56,4.0,-28),Vector3(67,4.4,-57),Vector3(55,2,-29)],
		["30-village-gathering",Vector3(-29,3.5,45),Vector3(-38,2.0,37),Vector3(-33,2,42)],
		["31-market-stalls",Vector3(-22,3.2,25),Vector3(-32,2.1,17),Vector3(-23,2,24)]]
	for site in sites:
		Game.player.global_position=site[3]
		view.position=site[1]
		view.look_at(site[2])
		await get_tree().create_timer(.5).timeout
		await shot(site[0])
	Game.ui.hud.show()
	Game.player.camera.make_current()
	view.queue_free()
	for site in [["market",Vector3(-24,1.7,28),0.0],
		["paddy",Vector3(66.9,1.8,49),-PI*.5],["forest",Vector3(57,3,-40),-.45]]:
		Game.player.global_position=site[1]
		Game.player.yaw=site[2]
		await get_tree().create_timer(3.0).timeout
		print("POPULATION SAMPLE · ",site[0]," · ",Engine.get_frames_per_second()," FPS · ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," draws")
	print("POPULATION TOUR COMPLETE")

func wildlife_tour():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	Game.app.start_game("roam")
	Game.ui.close_modal()
	Game.app.weather.manual = true
	Game.app.weather.set_weather(0)
	for enemy in Game.world.enemies: enemy.set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	var view = Camera3D.new()
	get_tree().current_scene.add_child(view)
	view.fov = 48
	view.make_current()
	Game.ui.hud.hide()
	Game.player.hide()
	Game.player.set_physics_process(false)
	for sample in [["32-village-cat",0,Vector3(1.2,.75,-1.9),.3],
		["33-village-dog",4,Vector3(2,1.35,-3.3),.50],
		["34-forest-deer",7,Vector3(4,2.25,-5.5),1.0],
		["35-forest-elephant",12,Vector3(6,3.3,-7),1.4]]:
		var animal = Game.world.wildlife.animals[sample[1]]
		animal.set_physics_process(false)
		animal.global_position = animal.home
		animal.visual.rotation.y = 0
		Game.player.global_position = animal.global_position+Vector3(0,0,12)
		view.position = animal.global_position+sample[2]
		view.look_at(animal.global_position+Vector3.UP*sample[3])
		await shot(sample[0])
	var temple = Game.world.hill_temple
	Game.player.global_position = temple.global_position+Vector3(0,.2,7)
	view.fov = 55
	view.position = temple.global_position+Vector3(15,10,22)
	view.look_at(temple.global_position+Vector3(0,2.6,0))
	await shot("36-hill-temple")
	view.fov = 62
	view.position = temple.global_position+Vector3(5.0,2.9,8.5)
	view.look_at(temple.global_position+Vector3(0,2.75,-1))
	await shot("37-temple-courtyard")
	view.position = temple.global_position+Vector3(3.8,2.5,21)
	view.look_at(temple.global_position+Vector3(0,3.6,-1))
	await shot("38-temple-approach")
	Game.app.weather.set_weather(3)
	Game.app.weather.rain_strength = 1.0
	Game.app.weather.cloud_strength = 1.0
	view.position = temple.global_position+Vector3(12,7.4,18)
	view.look_at(temple.global_position+Vector3(0,2.9,-1))
	await shot("39-temple-monsoon")
	Game.app.weather.set_weather(0)
	Game.app.weather.rain_strength = 0
	Game.app.weather.cloud_strength = 0
	view.queue_free()
	Game.ui.hud.show()
	Game.player.show()
	Game.player.set_physics_process(true)
	Game.player.camera.make_current()
	for animal in Game.world.wildlife.animals: animal.set_physics_process(true)
	for site in [["village",Vector3(-30,2,37),0.0],
		["deer clearing",Vector3(85,2,-29),-.55],
		["elephant clearing",Vector3(-92,Malanadu.height_at(-92,-33),-33),.7],
		["hill temple",temple.global_position+Vector3(0,.2,7),0.0]]:
		Game.player.global_position = site[1]
		Game.player.yaw = site[2]
		await get_tree().create_timer(3.0).timeout
		print("WILDLIFE SAMPLE · ",site[0]," · ",Engine.get_frames_per_second()," FPS · ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," draws")
	print("WILDLIFE TOUR COMPLETE")

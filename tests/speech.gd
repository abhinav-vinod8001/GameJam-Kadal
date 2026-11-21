extends Node

var checks := 0
var failures := 0

func check(ok: bool,message: String):
	checks += 1
	if ok: print("PASS · "+message)
	else:
		failures += 1
		push_error("FAIL · "+message)

func frames(count: int):
	for i in count: await get_tree().physics_frame

func resident(id: String) -> Node3D:
	for actor in get_tree().get_nodes_in_group("speech_actors"):
		if not actor.is_in_group("enemies") and actor.npc_id==id: return actor
	return null

func button_with(node: Node,fragment: String) -> Button:
	if node is Button and fragment in node.text: return node
	for child in node.get_children():
		var found = button_with(child,fragment)
		if found: return found
	return null

func _ready():
	Engine.max_fps = 60
	Game.app.start_game("roam")
	Game.ui.dialogue("life_leela")
	check(Game.speech.current_line=="life_leela_intro","Conversations work immediately after soldiers are replaced for a new run")
	Game.ui.close_modal()
	var speech = Game.speech
	speech.automatic = false
	var player = Game.player
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	for enemy in Game.world.enemies: enemy.set_physics_process(false)
	await frames(8)
	var complete := true
	var matching := true
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://data/speech_manifest.json"))
	for id in speech.script_data.lines:
		var path = "res://assets/audio/speech/"+id+".mp3"
		if not ResourceLoader.exists(path): complete = false; continue
		var stream: AudioStream = load(path)
		if stream.get_length()<.3: complete = false
		var line: Dictionary = speech.script_data.lines[id]
		if manifest.clips[id].text_sha256!=str(line.ml).sha256_text(): matching = false
	check(complete and speech.script_data.lines.size()==114,"All 114 Malayalam lines have playable offline audio")
	check(matching,"Cached voices match the current Malayalam script")
	check(get_tree().get_nodes_in_group("speech_actors").size()==42,"All 30 villagers and 12 soldiers can speak; training post is excluded")
	var unique := {}
	for actor in get_tree().get_nodes_in_group("speech_actors"):
		if speech.hostile(actor): continue
		var d: Dictionary = Game.dialogues[actor.npc_id]
		unique[d.ml] = true
		unique[d.more_ml] = true
	check(unique.size()==60,"Every villager has a distinct introduction and follow-up")
	var meera = resident("meera")
	player.global_position = meera.global_position+Vector3(0,0,2.0)
	check(speech.play_line(meera,"meera_greet"),"A nearby NPC can play Malayalam speech")
	await frames(2)
	check(speech.voice.playing and not speech.dialogue_voice.playing,"Proximity dialogue uses one positional voice")
	check(Game.ui.speech_panel.visible and Game.ui.speech_ml.text==speech.script_data.lines.meera_greet.ml,"Subtitle text matches the spoken Malayalam line")
	check(Game.ui.speech_name.text=="MEERA","Subtitles identify the speaker")
	check(not speech.can_hear(meera,.5),"Proximity checks reject characters outside the hearing radius")
	var player_position = player.global_position
	player.global_position.y += 5
	check(not speech.can_hear(meera,10),"Characters on a different floor do not greet through ceilings")
	player.global_position = player_position
	var wall = StaticBody3D.new()
	wall.collision_layer = 1
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(4,4,.2)
	collision.shape = box
	wall.add_child(collision)
	get_tree().current_scene.add_child(wall)
	wall.global_position = (meera.global_position+player.global_position)*.5+Vector3.UP
	await frames(2)
	check(not speech.can_hear(meera,5),"Solid walls prevent proximity greetings")
	wall.queue_free()
	await frames(2)
	check(absf(speech.remaining-(speech.voice.stream.get_length()/speech.voice.pitch_scale+.65))<.2,"Subtitles remain for the full clip duration")
	Game.subtitle_translation = false
	speech.play_line(meera,"meera_local")
	check(not Game.ui.speech_en.visible and Game.ui.speech_ml.visible,"English translation is optional; Malayalam stays visible")
	Game.subtitle_translation = true
	Game.ui.dialogue("meera")
	await frames(2)
	check(speech.conversation and speech.dialogue_voice.playing and not speech.voice.playing,"Opening a conversation replaces the ambient voice")
	check(not Game.ui.speech_panel.visible and Game.ui.dialogue_ml.text==speech.script_data.lines.meera_intro.ml,"The dialogue panel displays its matching voiced line")
	button_with(Game.ui.modal_box,"Tell me more").pressed.emit()
	check(speech.current_line=="meera_more" and Game.ui.dialogue_ml.text==speech.script_data.lines.meera_more.ml,"Tell me more advances both speech and text")
	button_with(Game.ui.modal_box,"Tell me more").pressed.emit()
	check(speech.current_line=="meera_greet","Repeated follow-ups cycle through the character's other lines")
	Game.ui.close_modal()
	check(not speech.voice.playing and not speech.dialogue_voice.playing and speech.current_line=="","Closing a conversation clears speech and subtitles")
	var old_weather: String = Game.last_weather
	Game.last_weather = "Heavy rain"
	check(speech.friendly_pool(meera,{"count":2})=="weather_storm","Later visits can select storm-specific dialogue")
	Game.last_weather = old_weather
	Game.mode = "story"
	Game.quest_step = 5
	check(speech.friendly_pool(resident("ravi"),{})=="quest_ravi_return","Ravi recognizes the recovered ledger in his approach dialogue")
	Game.mode = "roam"
	Game.quest_step = 0
	speech.play_line(meera,"meera_greet")
	Game.ui.pause_menu()
	check(not speech.voice.playing and not Game.ui.speech_panel.visible,"Pause interrupts background speech cleanly")
	Game.ui.close_modal()
	speech.play_line(meera,"meera_greet")
	player.global_position += Vector3(25,0,0)
	await frames(3)
	check(speech.current_line=="","Walking away stops the distant greeting")
	speech.reset()
	check(speech.choose("meera")!=speech.choose("meera"),"Revisits rotate lines instead of immediately repeating")
	speech.reset()
	player.global_position = meera.global_position+Vector3(0,0,2.0)
	speech.automatic = true
	await frames(25)
	check(is_instance_valid(speech.speaker) and not speech.hostile(speech.speaker) and speech.current_line!="","Approaching a villager automatically triggers a greeting")
	var spoke_to = speech.speaker
	speech.stop()
	await frames(16)
	check(speech.current_line=="","Remaining beside an NPC respects the greeting cooldown")
	player.global_position = spoke_to.global_position+Vector3(20,0,0)
	await frames(16)
	speech.clock += 40
	player.global_position = spoke_to.global_position+Vector3(0,0,2)
	speech.next_line = 0
	await frames(25)
	check(speech.current_line!="","Returning after cooldown allows another greeting")
	speech.reset()
	speech.automatic = false
	var guard = Game.world.enemies[0]
	player.global_position = guard.global_position+Vector3(0,0,2)
	speech.play_line(guard,"soldier_alert_1")
	check(speech.voice.playing and Game.ui.speech_name.text.contains("LV 1"),"Soldiers have voiced Malayalam challenges and identified subtitles")
	guard.dead = true
	await frames(2)
	check(speech.current_line=="" and not speech.voice.playing,"A defeated speaker cannot continue talking")
	guard.dead = false
	speech.reset()
	speech.automatic = true
	guard.state = "chase"
	await frames(25)
	check(speech.current_line.begins_with("soldier_") and speech.hostile(speech.speaker),"Approaching soldiers automatically triggers a hostile callout")
	var guarded_until = float(speech.visits[guard.get_instance_id()].cooldown)
	check(guarded_until>speech.clock+5,"Squad callouts share a cooldown")
	speech.automatic = false
	speech.stop()
	var phase_before = guard.visual.clock
	guard.state = "windup"
	guard.timer = 3.0
	guard.set_physics_process(true)
	await frames(12)
	check(absf(guard.visual.clock-phase_before)<.01,"Soldiers stop their gait while preparing a stationary strike")
	guard.set_physics_process(false)
	guard.tell.hide()
	var avatar = KadalAvatar.new()
	avatar.costume = "ravi"
	add_child(avatar)
	var min_angle := INF
	var max_angle := -INF
	var min_sole := INF
	var max_sole := -INF
	for frame in 180:
		avatar.animate(1.0/60.0,.72,0,false,false,0,false,Vector3(0,0,-.72))
		min_angle = minf(min_angle,avatar.legs[0].rotation.x)
		max_angle = maxf(max_angle,avatar.legs[0].rotation.x)
		for i in 2:
			var sole = avatar.to_local(avatar.knees[i].get_node("Art").to_global(Vector3(0,-.664,-.045)))
			min_sole = minf(min_sole,sole.y)
			max_sole = maxf(max_sole,sole.y)
	print("SLOW GAIT · hip range ",max_angle-min_angle," · sole ",min_sole," to ",max_sole)
	check(max_angle-min_angle>.45,"Pedestrian speed produces a visible articulated stride")
	check(min_sole>-.07 and max_sole<.22,"Walking feet stay near the ground with a raised swing step")
	for frame in 90: avatar.animate(1.0/60.0,0,0,false,false)
	var stopped_clock = avatar.clock
	avatar.animate(.2,0,0,false,false)
	check(absf(avatar.clock-stopped_clock)<.001 and avatar.motion_blend<.001,"Stationary characters settle without walking in place")
	avatar.animate(.1,3.0,.7,false,false,0,true,Vector3(2,0,-2))
	check(avatar.right_arm.rotation.x< -1.2 and avatar.knees[0].transform.is_finite(),"Directional locomotion preserves the soldier attack pose")
	avatar.queue_free()
	Game.ui.settings()
	check(button_with(Game.ui.modal_box,"English translation")!=null,"Settings include a subtitle translation preference")
	Game.ui.close_modal()
	speech.reset()
	check(speech.visits.is_empty() and speech.rotations.is_empty(),"New runs reset speech visits and line rotation")
	if "--capture-speech" in OS.get_cmdline_user_args(): await capture_previews()
	Game.app.return_to_menu()
	check(speech.current_line=="" and not speech.voice.playing,"Returning to the menu clears the voice channel")
	print("SPEECH RESULT · ",checks," checks · ",failures," failures")
	get_tree().quit(1 if failures else 0)

func shot(id: String):
	await frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+id+".png")
	print("CAPTURE · "+id)

func capture_previews():
	Game.speech.automatic = false
	Game.speech.stop()
	Game.app.weather.set_weather(0)
	Game.ui.region_label.modulate.a = 0
	Game.ui.notification.modulate.a = 0
	var camera = Camera3D.new()
	add_child(camera)
	camera.fov = 46
	var actor = resident("meera")
	var focus = actor.global_position
	Game.player.global_position = focus+Vector3(-1.0,0,2)
	camera.global_position = focus+Vector3(3.6,2.4,6.1)
	camera.look_at(focus+Vector3(0,1,0))
	camera.make_current()
	Game.speech.play_line(actor,"meera_local")
	await shot("48-malayalam-market")
	Game.ui.dialogue("meera")
	await shot("49-voiced-conversation")
	Game.ui.close_modal()
	var soldier = Game.world.enemies[-1]
	focus = soldier.global_position
	Game.player.global_position = focus+Vector3(-1.5,0,2.5)
	soldier.visual.rotation.y = PI
	camera.global_position = focus+Vector3(4,2.8,6.8)
	camera.look_at(focus+Vector3(0,1,0))
	Game.speech.play_line(soldier,"soldier_captain_3")
	await shot("50-malayalam-soldiers")
	Game.speech.stop()
	Game.ui.settings()
	await shot("51-dialogue-settings")
	Game.ui.close_modal()
	Game.ui.hud.hide()
	var walker = resident("life_mary")
	walker.set_process(false)
	walker.global_position = Game.world.ground(-14,18,.035)
	walker.visual.show()
	focus = walker.global_position
	camera.global_position = focus+Vector3(2,1.5,3.9)
	camera.look_at(focus+Vector3(0,.95,0))
	walker.visual.rotation.y = PI*.55
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/walk-frames"))
	for i in 24:
		for step in 4: walker.visual.animate(1.0/60.0,.72,0,false,false,0,false,Vector3(0,0,-.72))
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/walk-frames/%02d.png"%i)
	Game.ui.hud.show()
	camera.queue_free()

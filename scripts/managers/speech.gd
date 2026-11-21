extends Node

# A single conversation channel keeps crowded markets and squad fights readable.
var script_data: Dictionary = {}
var streams: Dictionary = {}
var visits: Dictionary = {}
var rotations: Dictionary = {}
var voice: AudioStreamPlayer3D
var dialogue_voice: AudioStreamPlayer
var speaker: Node3D
var current_line := ""
var conversation := false
var remaining := 0.0
var clock := 0.0
var next_scan := 0.0
var next_line := 0.0
var automatic := true

func _ready():
	script_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/speech.json"))
	voice = AudioStreamPlayer3D.new()
	voice.unit_size = 5.0
	voice.max_distance = 20.0
	voice.max_db = 1.0
	add_child(voice)
	dialogue_voice = AudioStreamPlayer.new()
	add_child(dialogue_voice)

func reset():
	stop()
	visits.clear()
	rotations.clear()
	clock = 0
	next_scan = 0
	next_line = 0

func stop():
	if voice: voice.stop()
	if dialogue_voice: dialogue_voice.stop()
	speaker = null
	current_line = ""
	remaining = 0
	conversation = false
	if is_instance_valid(Game.ui): Game.ui.hide_speech()

func hostile(actor: Node3D) -> bool:
	return is_instance_valid(actor) and bool(actor.get_meta("speech_hostile",false))

func can_hear(actor: Node3D, radius: float) -> bool:
	if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.is_inside_tree(): return false
	if hostile(actor) and actor.dead: return false
	var offset = actor.global_position-Game.player.global_position
	if offset.length()>radius or absf(offset.y)>3.5: return false
	var ray = PhysicsRayQueryParameters3D.create(Game.player.global_position+Vector3.UP*1.3,actor.global_position+Vector3.UP*1.3,1)
	return actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func choose(pool: String, actor_key: String = "") -> String:
	var options: Array = script_data.pools.get(pool,[])
	if options.is_empty(): return ""
	var key = pool+":"+actor_key
	var index = int(rotations.get(key,0))
	rotations[key] = index+1
	return str(options[index%options.size()])

func friendly_pool(actor: Node3D, visit: Dictionary) -> String:
	if actor.npc_id=="ravi" and Game.mode=="story" and Game.quest_step==5: return "quest_ravi_return"
	if Game.mode=="story" and Game.quest_step==6 and not visit.get("thanked",false): return "quest_victory"
	# Alternate personal lines with weather remarks on later visits.
	if int(visit.get("count",0))%3==2:
		if Game.last_weather=="Heavy rain": return "weather_storm"
		if Game.last_weather=="Monsoon": return "weather_rain"
	return actor.npc_id

func _physics_process(delta):
	if not is_instance_valid(Game.player): return
	if Game.mode=="menu" or Game.player.health<=0:
		if current_line!="": stop()
		return
	if Game.modal:
		if not conversation and current_line!="": stop()
		return
	clock += delta
	if current_line!="":
		remaining -= delta
		if not is_instance_valid(speaker) or (hostile(speaker) and speaker.dead):
			stop()
		elif speaker.global_position.distance_to(Game.player.global_position)>(20.0 if hostile(speaker) else 9.0):
			stop()
		elif remaining<=0:
			stop()
		else:
			voice.global_position = speaker.global_position+Vector3.UP*1.6
	if not automatic or clock<next_scan: return
	next_scan = clock+.2
	var best: Node3D
	var best_score := -INF
	var best_pool := ""
	for actor in get_tree().get_nodes_in_group("speech_actors"):
		if not is_instance_valid(actor) or actor.is_queued_for_deletion(): continue
		var key = actor.get_instance_id()
		var entry: Dictionary = visits.get(key,{"near":false,"until":0.0,"cooldown":0.0,"count":0})
		visits[key] = entry
		var enemy = hostile(actor)
		if enemy and actor.dead: continue
		var distance_value = actor.global_position.distance_to(Game.player.global_position)
		var radius = 10.5 if enemy else 4.2
		if distance_value>radius+2.2:
			entry.near = false
			continue
		if distance_value>radius: continue
		if not entry.near:
			entry.near = true
			entry.until = clock+7.0
		var fighting = enemy and actor.state in ["chase","windup","strike","recover","stagger"]
		if clock<float(entry.cooldown): continue
		if not fighting and clock>float(entry.until): continue
		if not can_hear(actor,radius): continue
		var score = (100.0 if enemy else 0.0)-distance_value
		if score<=best_score: continue
		best = actor
		best_score = score
		if enemy:
			best_pool = "soldier_captain" if actor.elite else ("soldier_alert" if entry.count==0 else "soldier_combat")
			if actor.state=="return": best_pool = "soldier_return"
		else:
			best_pool = friendly_pool(actor,entry)
	if not is_instance_valid(best): return
	# A nearby hostile can interrupt a market greeting, then owns the channel.
	if current_line!="" and (not hostile(best) or hostile(speaker)): return
	if current_line=="" and clock<next_line: return
	var line_id = choose(best_pool,best_pool if hostile(best) else str(best.npc_id))
	if play_line(best,line_id):
		var entry: Dictionary = visits[best.get_instance_id()]
		entry.count += 1
		entry.cooldown = clock+(15.0 if hostile(best) else 32.0)
		entry.until = 0.0
		if best_pool=="quest_victory": entry.thanked = true
		# The squad shares a callout cooldown instead of twelve voices taking turns.
		if hostile(best):
			for actor in get_tree().get_nodes_in_group("speech_actors"):
				if hostile(actor) and actor!=best and visits.has(actor.get_instance_id()):
					visits[actor.get_instance_id()].cooldown = maxf(float(visits[actor.get_instance_id()].cooldown),clock+10.0)

func play_line(actor: Node3D, id: String, in_dialogue := false) -> bool:
	if not script_data.lines.has(id): return false
	if not in_dialogue and not is_instance_valid(actor): return false
	stop()
	var line: Dictionary = script_data.lines[id]
	speaker = actor
	current_line = id
	conversation = in_dialogue
	var path = "res://assets/audio/speech/"+id+".mp3"
	if not streams.has(id) and ResourceLoader.exists(path): streams[id] = load(path)
	var pitch = float(line.get("pitch",1.0))
	if is_instance_valid(actor) and hostile(actor) and actor.elite: pitch = .82
	var duration = maxf(3.0,str(line.ml).length()/15.0)
	if streams.has(id):
		var player = dialogue_voice if in_dialogue else voice
		player.stream = streams[id]
		player.pitch_scale = pitch
		player.volume_db = linear_to_db(maxf(.0001,Game.voice_volume))
		if not in_dialogue: voice.global_position = actor.global_position+Vector3.UP*1.6
		player.play()
		duration = player.stream.get_length()/pitch
	remaining = duration+.65
	next_line = clock+remaining+1.7
	if not in_dialogue and is_instance_valid(Game.ui):
		var title = ""
		if hostile(actor): title = "LV %d · %s"%[actor.level,actor.role.to_upper()]
		else: title = Game.dialogues[actor.npc_id].name
		Game.ui.show_speech(title,line,hostile(actor))
	return true

func converse(id: String, page: int = 0):
	var options: Array = script_data.pools.get(id,[])
	if options.is_empty(): return
	var actor: Node3D
	for candidate in get_tree().get_nodes_in_group("speech_actors"):
		if candidate.is_queued_for_deletion(): continue
		if not hostile(candidate) and candidate.npc_id==id:
			actor = candidate
			break
	if is_instance_valid(actor):
		visits[actor.get_instance_id()] = {"near":true,"until":0.0,"cooldown":clock+32.0,"count":page+1}
	play_line(actor,str(options[page%options.size()]),true)

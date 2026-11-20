extends Node

var sounds: Dictionary = {}
var ambient: AudioStreamPlayer
var rain_player: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0

func _ready():
	for id in ["sword","spear","staff","dagger","urumi","impact","block","parry","step","splash","dodge","heal","discover","purchase","equip","telegraph","death","thunder"]:
		sounds[id] = load("res://assets/audio/"+id+".wav")
	for i in range(16):
		var p = AudioStreamPlayer.new()
		add_child(p)
		voices.append(p)
	ambient = AudioStreamPlayer.new()
	ambient.stream = load("res://assets/audio/coast.wav")
	ambient.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambient.stream.loop_end = int(ambient.stream.get_length()*ambient.stream.mix_rate)
	ambient.volume_db = -18
	add_child(ambient)
	ambient.play()
	rain_player = AudioStreamPlayer.new()
	rain_player.stream = load("res://assets/audio/rain.wav")
	rain_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	rain_player.stream.loop_end = int(rain_player.stream.get_length()*rain_player.stream.mix_rate)
	rain_player.volume_db = -70
	add_child(rain_player)
	rain_player.play()
	Game.save_settings()

func play(id: String, gain: float = 0):
	if not sounds.has(id): return
	var p = voices[voice_index%voices.size()]
	voice_index += 1
	p.stream = sounds[id]
	p.volume_db = -10+gain
	p.pitch_scale = randf_range(.94,1.06) if id in ["sword","spear","impact","step","splash","staff","dagger"] else 1.0
	p.play()

func set_rain(amount: float):
	if rain_player: rain_player.volume_db = linear_to_db(maxf(.0002,amount*.28))

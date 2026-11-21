extends Node

signal notice(message: String)
signal quest_changed
signal state_changed

var app
var player
var world
var fx
var ui
var audio
var speech
var mode := "menu"
var modal := false
var quest_step := 0
var coins := 75
var herbs := 3
var upgrade := 0
var defeated := 0
var difficulty := 1
const DIFFICULTIES = [
	{"name":"Easy","health":.8,"damage":.65,"windup":1.2,"recovery":1.2,"attackers":2,"spacing":.38},
	{"name":"Normal","health":1.0,"damage":1.0,"windup":1.0,"recovery":1.0,"attackers":3,"spacing":.25},
	{"name":"Hard","health":1.2,"damage":1.3,"windup":.85,"recovery":.85,"attackers":4,"spacing":.18}
]
var discovered: Array[String] = []
var sensitivity := 0.003
var effects_scale := 1.0
var volume := 0.65
var voice_volume := 1.0
var subtitle_translation := true
var shake_enabled := true
var weapons: Array = []
var dialogues: Dictionary = {}
var last_weather := "Clear"
const SPAWN = Vector3(-30, 4, 37)
const OBJECTIVES = [
	"Speak with Ravi at the village jetty.",
	"Ask Meera at the spice market about the missing vanchi.",
	"Inspect the torn sail beside the backwater.",
	"Cross the bridge. Follow the trail to the forest camp.",
	"Recover the ledger from the raiders' camp.",
	"Return the ledger to Ravi at the village jetty.",
	"The village is safe. The monsoon keeps its secrets."
]
const TARGETS = [Vector3(-24, 2, 33), Vector3(-18, 2, 15), Vector3(14, 2, 6), Vector3(66, 2, -57), Vector3(70, 2, -67), Vector3(-24, 2, 33), Vector3(-24, 2, 33)]

func _ready():
	weapons = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
	dialogues = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogues.json"))
	var keys = {"left": KEY_A, "right": KEY_D, "forward": KEY_W, "back": KEY_S, "sprint": KEY_SHIFT, "jump": KEY_SPACE, "dodge": KEY_Q, "heavy": KEY_F, "interact": KEY_E, "pause": KEY_ESCAPE, "heal": KEY_H, "inventory": KEY_I, "map": KEY_M, "lock_on": KEY_TAB, "weather": KEY_F6, "climb": KEY_C}
	for action in keys:
		InputMap.add_action(action)
		var event = InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for i in range(5):
		var action = "weapon_%d" % i
		InputMap.add_action(action)
		var event = InputEventKey.new()
		event.physical_keycode = KEY_1 + i
		InputMap.action_add_event(action, event)
	for action in ["attack", "block"]:
		InputMap.add_action(action)
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT if action == "attack" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action, event)
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		sensitivity = cfg.get_value("settings", "sensitivity", sensitivity)
		volume = cfg.get_value("settings", "volume", volume)
		voice_volume = clampf(float(cfg.get_value("settings","voice_volume",1.0)),0.0,1.0)
		subtitle_translation = bool(cfg.get_value("settings","subtitle_translation",true))
		shake_enabled = cfg.get_value("settings", "shake", true)
		difficulty = clampi(int(cfg.get_value("settings","difficulty",1)),0,2)

func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("settings", "sensitivity", sensitivity)
	cfg.set_value("settings", "volume", volume)
	cfg.set_value("settings","voice_volume",voice_volume)
	cfg.set_value("settings","subtitle_translation",subtitle_translation)
	cfg.set_value("settings", "shake", shake_enabled)
	cfg.set_value("settings", "difficulty", difficulty)
	cfg.save("user://settings.cfg")
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))

func active() -> bool:
	return mode != "menu" and not modal and is_instance_valid(player) and player.health > 0

func advance(expected: int):
	if mode != "story" or quest_step != expected:
		return
	quest_step += 1
	if quest_step == 3 and camp_cleared(): quest_step = 4
	quest_changed.emit()
	if audio: audio.play("discover")
	notice.emit("Objective updated · " + OBJECTIVES[quest_step])
	if quest_step == 6:
		coins += 150
		ui.ending()

func objective() -> String:
	if mode=="story" and quest_step==3 and is_instance_valid(world.encounters):
		return "Defeat the level 3 camp guard · %d soldiers remain."%world.encounters.living("camp")
	return OBJECTIVES[quest_step] if mode == "story" else "Follow the waterways. Find your own story."

func buy(id: String) -> bool:
	var price = 20 if id == "herb" else 60
	if coins < price:
		notice.emit("Not enough fanam.")
		return false
	if id == "upgrade" and upgrade >= 3:
		notice.emit("Your weapons are fully honed.")
		return false
	coins -= price
	if id == "herb": herbs += 1
	else: upgrade += 1
	if audio: audio.play("purchase")
	notice.emit("Healing herb added." if id == "herb" else "All weapons honed · damage +15%")
	return true

func defeated_enemy():
	defeated += 1
	coins += 12
	if camp_cleared(): advance(3)
	quest_changed.emit()

func camp_cleared() -> bool:
	return is_instance_valid(world) and is_instance_valid(world.encounters) and world.encounters.is_cleared("camp")

func set_difficulty(index: int, persist: bool = true):
	difficulty = clampi(index,0,DIFFICULTIES.size()-1)
	if is_instance_valid(world) and is_instance_valid(world.encounters): world.encounters.apply_difficulty(difficulty)
	if persist: save_settings()
	state_changed.emit()

func reset_run(new_mode: String):
	mode = new_mode
	modal = false
	quest_step = 0
	coins = 75
	herbs = 3
	upgrade = 0
	defeated = 0
	discovered.clear()
	state_changed.emit()

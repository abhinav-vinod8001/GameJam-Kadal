extends Node3D

var npc_id := "ravi"
var visual: KadalAvatar
var clock := 0.0

func _ready():
	add_to_group("interactables")
	add_to_group("speech_actors")
	set_meta("kind","npc")
	set_meta("prompt","Speak with "+Game.dialogues[npc_id].name)
	visual = KadalAvatar.new()
	visual.costume = npc_id
	visual.tint = {"ravi":"c9be9c","meera":"5d8780","amma":"d6c68f","fish":"a96648","guru":"b17c49","smith":"596b64"}[npc_id]
	add_child(visual)
	visual.weapon_root.hide()
	visual.shield.hide()
	AvatarArt.npc_accessory(visual.right_hand_space,npc_id)
	Craft.label(self,Game.dialogues[npc_id].name,Vector3(0,2.25,0),24)

func _process(delta):
	if Game.modal: return
	clock += delta
	if not is_instance_valid(Game.player): return
	var diff = Game.player.global_position-global_position
	if diff.length()<6:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-diff.x,-diff.z),delta*3)
	visual.animate(delta,0,0,false,false)
	visual.head.rotation.y = sin(clock*.7)*.07
	visual.right_arm.rotation.z = sin(clock*.9)*.05

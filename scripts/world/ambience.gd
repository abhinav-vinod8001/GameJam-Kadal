extends Node3D

var birds: Array[Node3D] = []
var wings: Array = []
var clock := 0.0

func _ready():
	var mat = Craft.mat("344c47").duplicate()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 8:
		var bird = Node3D.new()
		add_child(bird)
		birds.append(bird)
		var pair: Array[Node3D] = []
		for side in [-1,1]:
			var wing = Node3D.new()
			bird.add_child(wing)
			Craft.surface(wing,PackedVector3Array([Vector3(0,0,-.2),Vector3(side*.65,0,.08),Vector3(0,0,.16)]),mat)
			pair.append(wing)
		wings.append(pair)

func _process(delta):
	clock += delta
	for i in birds.size():
		var t = clock*(.07+i*.005)+i*1.8
		birds[i].position = Vector3(-8+sin(t)*45,13+i*.65+sin(t*2),24+cos(t)*34)
		birds[i].rotation.y = -t-PI/2
		wings[i][0].rotation.z = sin(clock*6+i)*.32
		wings[i][1].rotation.z = -sin(clock*6+i)*.32

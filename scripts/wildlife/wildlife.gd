class_name WildlifeLife
extends Node3D

var animals: Array[KadalAnimal] = []
# Open habitats are reserved before trees are planted.
const HABITATS = [Vector4(-99,-38,10,10),Vector4(-95,-13,10,9),
	Vector4(91,-35,10,9),Vector4(10,-48,9,8)]

static func habitat_contains(x: float,z: float) -> bool:
	for site in HABITATS:
		if absf(x-site.x)<site.z and absf(z-site.y)<site.w: return true
	return false

func _ready():
	name = "Wildlife"
	var groups = [
		["cat",Vector2(-35,30),2.4,0],["cat",Vector2(-19,25),2.5,1],
		["cat",Vector2(-47,43),2.8,2],["cat",Vector2(-10,7),2.5,3],
		["dog",Vector2(-29,41),3.5,0],["dog",Vector2(-50,28),3.2,1],
		["dog",Vector2(-31,-12),3.5,2],
		["deer",Vector2(89,-34),4.0,0],["deer",Vector2(94,-35),4.0,1],
		["deer",Vector2(91,-40),4.0,2],["deer",Vector2(8,-47),3.5,3],
		["deer",Vector2(13,-49),3.5,4],
		["elephant",Vector2(-99,-39),5.5,0],["elephant",Vector2(-95,-13),5.0,1]]
	for entry in groups:
		var animal = KadalAnimal.new()
		animal.kind = entry[0]
		animal.variant = entry[3]
		animal.roam_radius = entry[2]
		animal.home = Vector3(entry[1].x,Malanadu.height_at(entry[1].x,entry[1].y)+.06,entry[1].y)
		animal.position = animal.home
		add_child(animal)
		animal.visual.rotation.y = entry[3]*1.8
		animals.append(animal)
	print("WILDLIFE · 4 cats · 3 dogs · 5 deer · 2 elephants")

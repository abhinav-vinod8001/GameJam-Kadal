extends Control

var sites = [
	[Vector2(-30,37),"AZHIMUKHAM", "Coastal village"],
	[Vector2(28,30),"KAYAL", "Backwaters"],
	[Vector2(71,-54),"VANAM", "Forest camp"],
	[Vector2(-78,-80),"MALAYORAM", "Hill shrine"],
	[Vector2(-42,-35),"KOTTA", "Kalari courtyard"]
]

func _ready():
	custom_minimum_size = Vector2(840,490)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func project(p: Vector2) -> Vector2:
	return Vector2((p.x+135)/270*size.x,(p.y+125)/255*size.y)

func _process(_delta): queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color("244b4c"))
	for i in range(1,10):
		draw_line(Vector2(size.x*i/10,0),Vector2(size.x*i/10,size.y),Color("315858"),1)
		draw_line(Vector2(0,size.y*i/10),Vector2(size.x,size.y*i/10),Color("315858"),1)
	var left_land = PackedVector2Array([project(Vector2(-126,-115)),project(Vector2(16,-115)),project(Vector2(18,-75)),project(Vector2(13,-20)),project(Vector2(22,25)),project(Vector2(25,71)),project(Vector2(-10,90)),project(Vector2(-105,85)),project(Vector2(-128,50))])
	var right_land = PackedVector2Array([project(Vector2(42,-115)),project(Vector2(125,-115)),project(Vector2(129,60)),project(Vector2(98,87)),project(Vector2(49,82)),project(Vector2(45,30)),project(Vector2(41,-18)),project(Vector2(36,-76))])
	draw_colored_polygon(left_land,Color("74846a"))
	draw_colored_polygon(right_land,Color("5d7f69"))
	draw_polyline(left_land,Color("a5ad82"),2,true)
	draw_polyline(right_land,Color("a5ad82"),2,true)
	for path_points in [[Vector2(-30,37),Vector2(-18,14),Vector2(-20,-7),Vector2(-42,-35),Vector2(-78,-80)],[Vector2(-20,-7),Vector2(48,-7),Vector2(61,-42),Vector2(69,-62)]]:
		var poly = PackedVector2Array()
		for p in path_points: poly.append(project(p))
		draw_polyline(poly,Color("d9c28e"),2,true)
	var font = load("res://assets/fonts/CormorantGaramond.ttf")
	for site in sites:
		var p = project(site[0])
		draw_circle(p,4,Color("e8d5a1"))
		draw_arc(p,9,0,TAU,30,Color("bfae7f"),1,true)
		draw_string(font,p+Vector2(15,1),site[1],HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("f3e7c4"))
		draw_string(ThemeDB.fallback_font,p+Vector2(15,19),site[2],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("d5ddbd"))
	if Game.player:
		var p = project(Vector2(Game.player.position.x,Game.player.position.z))
		draw_circle(p,10,Color("142e30"))
		draw_circle(p,5,Color("f6e7b8"))
		var forward = Vector2(-sin(Game.player.yaw),-cos(Game.player.yaw))
		draw_line(p,p+forward*20,Color("ffe3a1"),2,true)
	if Game.mode=="story" and Game.quest_step<6:
		var target = Game.TARGETS[Game.quest_step]
		var p = project(Vector2(target.x,target.z))
		draw_polyline(PackedVector2Array([p+Vector2(0,-9),p+Vector2(7,0),p+Vector2(0,9),p+Vector2(-7,0),p+Vector2(0,-9)]),Color("ffe4a2"),2,true)
	draw_string(font,Vector2(size.x-57,35),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("eee0b5"))
	draw_line(Vector2(size.x-50,44),Vector2(size.x-50,63),Color("eee0b5"),1,true)
	draw_string(font,Vector2(20,size.y-20),"MALANADU   /   THE MONSOON COAST",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("eee0b5"))

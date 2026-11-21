class_name KadalAvatar
extends Node3D

var hips: Node3D
var torso: Node3D
var right_arm: Node3D
var left_arm: Node3D
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var elbows: Array[Node3D] = []
var right_hand_space: Node3D
var left_hand_space: Node3D
var motion_blend := 0.0
var run_blend := 0.0
var landing := 0.0
var breath_clock := 0.0
var weapon_root: Node3D
var shield: Node3D
var head: Node3D
var clock := 0.0
var weapon_id := 0
var tint := "d8c7a4"
var enemy := false
var costume := "arun"
var roll_clock := 0.0

func _ready():
	hips = Node3D.new()
	add_child(hips)
	torso = Node3D.new()
	hips.add_child(torso)
	var role = "raider" if enemy else costume
	var skin = Craft.mat("c18a64" if not enemy else "a56f52")
	AvatarArt.body(hips,torso,tint,role,skin)
	head = Node3D.new()
	head.position = Vector3(0,1.666,-.018)
	head.scale = Vector3(.83,.92,.89)
	torso.add_child(head)
	AvatarArt.face(head,skin,role)
	for side in [-1,1]:
		var leg = Node3D.new()
		leg.position = Vector3(side*.129,.715,0)
		leg.scale = Vector3(.90,1.086,.94)
		hips.add_child(leg)
		knees.append(AvatarArt.leg(leg,skin,"a0a894" if not enemy else "66584b"))
		legs.append(leg)
		var arm = Node3D.new()
		arm.position = Vector3(side*.262,1.40,.013)
		arm.scale = Vector3(.91,1.0,.95)
		torso.add_child(arm)
		elbows.append(AvatarArt.arm(arm,skin,tint,role))
		if side == 1: right_arm = arm
		else: left_arm = arm
	for joint in [hips,torso,head,left_arm,right_arm,legs[0],legs[1]]:
		AvatarArt.bake_joint(joint)
	left_hand_space = elbows[0].get_node("Art")
	right_hand_space = elbows[1].get_node("Art")
	weapon_root = Node3D.new()
	right_hand_space.add_child(weapon_root)
	weapon_root.position = Vector3(0,-.53,-.05)
	shield = Node3D.new()
	left_hand_space.add_child(shield)
	shield.position = Vector3(-.06,-.4,-.15)
	AvatarArt.paricha(shield)
	set_weapon(weapon_id)

func set_weapon(id: int):
	weapon_id = id
	if not is_instance_valid(weapon_root): return
	for c in weapon_root.get_children(): c.free()
	shield.visible = id == 0
	var steel = Craft.mat("c8dce6",.43)
	var gold = Craft.mat("c49a62",.41)
	var wood = Craft.mat("654833")
	if id == 0 or id == 3:
		var length_value = 1.0 if id == 0 else .48
		AvatarArt.blade(weapon_root,length_value,.069 if id==0 else .057,.22 if id==0 else .035,steel)
		AvatarArt.angled(weapon_root,Vector3(-.135,0,.032),Vector3(.143,0,.051),.045,.052,gold)
		if id == 0:
			var last = Vector3(.128,0,.044)
			for next in [Vector3(.177,0,.084),Vector3(.187,0,.177),Vector3(.13,0,.255),Vector3(.037,0,.277)]:
				Craft.beam(weapon_root,last,next,.015,gold)
				last = next
		Craft.beam(weapon_root,Vector3(0,0,.035),Vector3(0,0,.253),.035,wood)
		for i in range(6):
			Craft.beam(weapon_root,Vector3(0,0,.066+i*.027),Vector3(0,0,.077+i*.027),.04,Craft.mat("82634d"))
		AvatarArt.ellipsoid(weapon_root,Vector3(0,0,.264),Vector3(.09,.082,.084),gold)
	elif id == 1 or id == 2:
		var shaft = Craft.cylinder(weapon_root,Vector3(0,0,-.375),.032,2.41,wood,.023)
		shaft.rotation.x = -PI/2
		for z in [-1.51,-1.46,-1.4,.72,.80]:
			Craft.beam(weapon_root,Vector3(0,0,z),Vector3(0,0,z+.035),.038,gold)
		for z in range(10):
			var near = -.26 + z*.038
			Craft.beam(weapon_root,Vector3(0,0,near),Vector3(0,0,near+.02),.032,Craft.mat("a38662"))
		if id == 1:
			var point = Node3D.new()
			point.position.z = -1.49
			weapon_root.add_child(point)
			AvatarArt.blade(point,.55,.073,0.0,steel,true)
			AvatarArt.ellipsoid(point,Vector3(0,.018,-.088),Vector3(.029,.012,.060),gold)
		else:
			for z in [-1.59,.83]: AvatarArt.ellipsoid(weapon_root,Vector3(0,0,z),Vector3(.073,.071,.1),gold)
	else:
		Craft.box(weapon_root,Vector3(0,0,.08),Vector3(.08,.07,.3),wood)
		for i in range(14):
			var z = -i*.16
			var n = Craft.box(weapon_root,Vector3(sin(i*.45)*.2,0,z),Vector3(.045,.018,.18),steel)
			n.rotation.y = cos(i*.45)*.45

func animate(delta: float, speed: float, attack: float, blocking: bool, dodge: bool, combo: int = 0, thrust: bool = false, local_velocity: Vector3 = Vector3.ZERO, grounded: bool = true, vertical_speed: float = 0.0):
	var blend = 1.0-exp(-delta*13.0)
	var pedestrian = enemy or costume!="arun"
	left_arm.scale = Vector3(.91,1.0,.95)
	right_arm.scale = Vector3(.91,1.0,.95)
	motion_blend = lerpf(motion_blend,clampf(speed/(.55 if pedestrian else 3.8),0.0,1.0),blend)
	run_blend = lerpf(run_blend,clampf((speed-4.6)/3.7,0.0,1.0),blend)
	breath_clock += delta
	var cycle_distance = lerpf(.90,1.90,clampf((speed-.5)/3.0,0.0,1.0)) if pedestrian else lerpf(3.2,4.0,run_blend)
	clock = fposmod(clock+delta*speed*TAU/cycle_distance,TAU)
	landing = move_toward(landing,0.0,delta*2.8)
	var gait = sin(clock)
	var moving = motion_blend if grounded else 0.0
	var swing = sin(attack*PI) if attack>0 else 0.0
	var stride = lerpf(.53,.84,run_blend)*moving
	var breathe = sin(breath_clock*2.1)*.007*(1.0-moving)
	hips.position = Vector3(sin(clock)*.014*moving,-.67*(1.0-cos(gait*stride))+breathe-landing*.13,0)
	hips.rotation = Vector3(0,0,-gait*.035*moving)
	if dodge:
		roll_clock += delta
		hips.rotation.x = minf(roll_clock/.48,1.0)*TAU
		hips.position = Vector3(0,.85,0)-hips.basis*Vector3(0,.85,0)
	else:
		roll_clock = 0
	for i in 2:
		var phase = clock+i*PI
		legs[i].rotation = Vector3(sin(phase)*stride,0,0)
		knees[i].rotation.x = -maxf(0.0,cos(phase))*lerpf(.70,1.12,run_blend)*moving-landing*.5
		elbows[i].rotation = Vector3(lerpf(.17,.80,run_blend)*moving+.12,0,0)
	torso.rotation.x = lerpf(torso.rotation.x,-.055*moving-.12*run_blend+landing*.17,blend)
	torso.rotation.z = lerpf(torso.rotation.z,clampf(-local_velocity.x*.035,-.16,.16)-gait*.025*moving,blend)
	torso.rotation.y = -gait*.055*moving+swing*(1.0 if combo%2==0 else -1.0)
	head.rotation.x = .025*sin(breath_clock*1.7)
	right_arm.rotation = Vector3(-.18-gait*.33*moving,0,-.075-.045*run_blend)
	left_arm.rotation = Vector3(gait*.40*moving,0,.065+.045*run_blend)
	weapon_root.position.z = -.05
	if attack>0:
		right_arm.rotation.x = -1.25-swing*.5
		right_arm.rotation.y = lerpf(-1.8,1.65,attack)*(1 if combo%2==0 else -1)
		elbows[1].rotation.x = .08+swing*.15
		if thrust:
			right_arm.rotation.y = 0
			weapon_root.position.z = -.05-swing*.85
	if blocking:
		left_arm.rotation = Vector3(-1.05,-.25,.04)
		elbows[0].rotation.x = .24
	if dodge:
		for i in 2:
			legs[i].rotation.x = .85
			knees[i].rotation.x = -1.45
			elbows[i].rotation.x = .9
		left_arm.rotation.x = .55
		right_arm.rotation.x = .55
	if not grounded and not dodge:
		var rising = clampf(vertical_speed/7.2,-1.0,1.0)
		legs[0].rotation.x = .18+maxf(rising,0.0)*.48
		legs[1].rotation.x = -.18
		knees[0].rotation.x = -.60-maxf(rising,0.0)*.3
		knees[1].rotation.x = -.30
		left_arm.rotation.z = .25
		right_arm.rotation.z = -.25
	if weapon_id==4:
		for i in range(1,weapon_root.get_child_count()):
			var piece = weapon_root.get_child(i)
			piece.position.x = sin((i-1)*.45+breath_clock*3.0)*(.15+swing*.3)
			piece.rotation.y = cos((i-1)*.45+breath_clock*3.0)*.45
	if blocking and weapon_id!=0:
		right_arm.rotation = Vector3(-1.25,0,-.2)
		weapon_root.rotation.y = PI/2 if weapon_id in [1,2] else .6
	else:
		weapon_root.rotation.y = 0
	weapon_root.rotation.x = -.30 if attack<=0 and not blocking else 0.0
	if pedestrian and grounded and not dodge:
		walk_pose(cycle_distance,local_velocity,attack,blocking)

func walk_pose(cycle_distance: float, local_velocity: Vector3, attack: float, blocking: bool):
	# A foot stays down during stance, then lifts for the return step. Leg angles
	# come from the ankle target so the knee bends during swing rather than contact.
	var feet: Array[Vector2] = []
	var reach := 0.0
	for i in 2:
		var phase = fposmod(clock/TAU+i*.5,1.0)
		var along: float
		var lift := 0.0
		var amplitude = minf(.48,cycle_distance*.275)*motion_blend
		if phase<.55:
			along = lerpf(-amplitude,amplitude,phase/.55)
		else:
			var swing = (phase-.55)/.45
			along = lerpf(amplitude,-amplitude,smoothstep(0.0,1.0,swing))
			lift = sin(swing*PI)*.12*motion_blend
		feet.append(Vector2(along,lift))
		reach = maxf(reach,absf(along))
	var lowering = .668-sqrt(maxf(.05,.668*.668-reach*reach))
	hips.position = Vector3(sin(clock)*.008*motion_blend,-lowering-landing*.10,0)
	hips.rotation = Vector3(0,sin(clock)*.035*motion_blend,0)
	var direction = local_velocity.normalized() if local_velocity.length()>.03 else Vector3.FORWARD
	for i in 2:
		var foot = feet[i]
		var down = (.715+hips.position.y-.05-foot.y)/1.086
		var z = foot.x*(-direction.z)/1.086
		var x = -foot.x*direction.x/1.086
		var distance_value = clampf(Vector3(x,down,z).length(),.08,.6175)
		var knee_angle = PI-acos(clampf((.30*.30+.318*.318-distance_value*distance_value)/(2*.30*.318),-1.0,1.0))
		var hip_angle = atan2(-z,sqrt(down*down+x*x))+acos(clampf((.30*.30+distance_value*distance_value-.318*.318)/(2*.30*distance_value),-1.0,1.0))
		legs[i].rotation = Vector3(hip_angle,0,atan2(x,down))
		knees[i].rotation = Vector3(-knee_angle,0,0)
	# Arms counter the advancing foot; the weapon hand retains its combat pose.
	if attack<=0 and not blocking:
		left_arm.rotation.x = -.06+sin(clock)*.28*motion_blend
		right_arm.rotation.x = -.12-sin(clock)*.24*motion_blend
		if enemy and weapon_id==1:
			right_arm.rotation.x = -.40-sin(clock)*.09*motion_blend
			elbows[1].rotation.x = .38

func swim_pose():
	var stroke = breath_clock*3.6
	hips.rotation.x = -.92
	hips.position.y = -.10+sin(stroke*2.0)*.025
	torso.rotation = Vector3(.04,sin(stroke)*.08,0)
	head.rotation.x = .32
	for i in 2:
		var phase = stroke+i*PI
		var limb = right_arm if i==1 else left_arm
		limb.rotation = Vector3(sin(phase)*1.35-.55,cos(phase)*.18,(-.20 if i==1 else .20))
		elbows[i].rotation.x = .28+maxf(0.0,cos(phase))*.65
		legs[i].rotation.x = sin(phase*1.7)*.22
		knees[i].rotation.x = -.15-maxf(0.0,sin(phase*1.7))*.35

func climb_pose():
	var cycle = breath_clock*6.0
	hips.rotation = Vector3(.08,0,0)
	hips.position.y = sin(cycle*2.0)*.025
	torso.rotation = Vector3(-.08,0,sin(cycle)*.025)
	for i in 2:
		var limb = right_arm if i==1 else left_arm
		var phase = cycle+i*PI
		limb.rotation = Vector3(2.2+sin(phase)*.45,0,0)
		elbows[i].rotation.x = .25
		legs[i].rotation.x = .30+maxf(0.0,sin(phase))*.65
		knees[i].rotation.x = -.55-maxf(0.0,sin(phase))*.7

func paddle_pose(delta: float, phase: float, power: float, left_grip: Vector3, right_grip: Vector3):
	breath_clock += delta
	hips.position = Vector3(0,-.85,0)
	hips.rotation = Vector3(0,0,0)
	torso.rotation = Vector3(-.05+sin(phase)*.09*power,cos(phase)*.08*power,0)
	head.rotation.x = .04
	for i in 2:
		legs[i].rotation = Vector3(1.28,0,0)
		knees[i].rotation.x = -1.28
	pose_hand(left_arm,elbows[0],left_grip,-1.0)
	pose_hand(right_arm,elbows[1],right_grip,1.0)

func pose_hand(upper: Node3D, lower: Node3D, target: Vector3, side: float):
	var origin = upper.global_position
	var offset = target-origin
	var direction = offset.normalized()
	var hand_rest = Vector3(0,-.303,-.039)
	var a = lower.position.length()
	var b = hand_rest.length()
	var distance_value = clampf(offset.length(),.05,a+b-.001)
	var along = (a*a-b*b+distance_value*distance_value)/(2.0*distance_value)
	var height_value = sqrt(maxf(0.0,a*a-along*along))
	var bend = global_basis*Vector3(side,.05,.6)
	bend = (bend-direction*bend.dot(direction)).normalized()
	var joint = origin+direction*along+bend*height_value
	upper.global_basis = Basis(Quaternion(lower.position.normalized(),(joint-origin).normalized()))
	lower.global_basis = Basis(Quaternion(hand_rest.normalized(),(target-lower.global_position).normalized()))
	weapon_root.position.z = -.05

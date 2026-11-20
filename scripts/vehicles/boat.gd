extends CharacterBody3D

var occupied := false
var speed_value := 0.0
var clock := 0.0
var stroke_phase := 0.0
var stroke_power := 0.0
var stroke_direction := 1.0
var steering := 0.0
var paddle: Node3D
var visual: Node3D
var seat: Marker3D
var left_grip: Marker3D
var right_grip: Marker3D
var splash_clock := 0.0
var wake_clock := 0.0
var last_thrust := 0.0

func _ready():
    collision_layer = 8
    collision_mask = 1
    add_to_group("interactables")
    set_meta("kind","boat")
    set_meta("prompt","Board the vanchi")
    visual = Node3D.new()
    visual.name = "Vanchi"
    add_child(visual)
    VanchiArt.build(visual)
    seat = Marker3D.new()
    seat.position = Vector3(0,.19,.46)
    visual.add_child(seat)
    paddle = Node3D.new()
    paddle.name = "Paddle"
    paddle.position = Vector3(.55,.72,.28)
    visual.add_child(paddle)
    VanchiArt.paddle(paddle)
    left_grip = Marker3D.new()
    left_grip.position = Vector3(0,.36,0)
    paddle.add_child(left_grip)
    right_grip = Marker3D.new()
    right_grip.position = Vector3(0,-.22,0)
    paddle.add_child(right_grip)
    var collider = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = Vector3(1.3,.4,4.9)
    collider.shape = shape
    add_child(collider)
    process_physics_priority = -10

func _physics_process(delta):
    clock += delta
    var thrust = 0.0
    var steer = 0.0
    if occupied and Game.active():
        thrust = Input.get_axis("back","forward")
        steer = Input.get_axis("right","left")
    last_thrust = thrust
    stroke_power = lerpf(stroke_power,absf(thrust),1.0-exp(-delta*5.0))
    steering = lerpf(steering,steer,1.0-exp(-delta*4.0))
    if absf(thrust)>.01:
        stroke_direction = signf(thrust)
        speed_value = move_toward(speed_value,thrust*(6.8 if thrust>0 else 3.6),delta*2.8)
    else:
        speed_value = move_toward(speed_value,0,delta*1.35)
    rotation.y += steering*delta*(.22+absf(speed_value)*.075)
    velocity = -basis.z*speed_value
    var old_position = global_position
    position.y = .40
    move_and_slide()
    if is_on_wall() and old_position.distance_to(global_position)<absf(speed_value)*delta*.35:
        speed_value = move_toward(speed_value,0,delta*10.0)
    # Only the visual hull rolls and pitches: steering and rider physics stay level.
    visual.position.y = sin(clock*1.45)*.032+sin(clock*2.6+.8)*.012
    visual.rotation.x = sin(clock*1.4)*.009-absf(speed_value)*.0025
    visual.rotation.z = sin(clock*1.8)*.012-steering*minf(absf(speed_value)/6.8,1.0)*.035
    if occupied:
        stroke_phase += delta*4.4*stroke_power*stroke_direction
        paddle.position = Vector3(.44+sin(stroke_phase)*.025,.57+maxf(0.0,cos(stroke_phase))*.08*stroke_power, .43+sin(stroke_phase)*.13*stroke_power)
        paddle.rotation = Vector3(sin(stroke_phase)*.30*stroke_power,0,.72+cos(stroke_phase)*.07*stroke_power)
    else:
        paddle.position = Vector3(.42,.21,.5)
        paddle.rotation = Vector3(-1.25,0,.24)
    splash_clock -= delta
    wake_clock -= delta
    if occupied and stroke_power>.2 and cos(stroke_phase)<-.65 and splash_clock<=0:
        splash_clock = .65
        var dip = paddle.to_global(Vector3(0,-1.43,0))
        dip.y = .205
        Game.fx.step(dip,true,false)
    if absf(speed_value)>1 and wake_clock<=0:
        wake_clock = .28
        var stern = global_position+basis.z*(2.3 if speed_value>0 else -2.3)
        stern.y = .205
        Game.fx.arc(stern,rotation.y+PI,.72,2.5,Color("bbded4a0"),1.0,.032)
    if Game.world:
        var material = Game.world.water_material
        material.set_shader_parameter("boat_position",global_position)
        var forward = -basis.z if speed_value>=0 else basis.z
        material.set_shader_parameter("boat_forward",Vector2(forward.x,forward.z))
        material.set_shader_parameter("boat_speed",speed_value)

func rider_transform() -> Transform3D:
    return seat.global_transform

func interact():
    if occupied:
        var spot = global_position+basis.x*2.0
        if global_position.distance_to(Vector3(23,.4,33))<7:
            spot = Vector3(18,1.4,33)
        Game.player.boat = null
        Game.player.global_position = spot+Vector3.UP*.3
        Game.player.velocity = Vector3.ZERO
        Game.player.visual.hips.position = Vector3.ZERO
        Game.player.set_traversal_equipment(false)
        occupied = false
        Game.notice.emit("Back on foot · E to board")
    else:
        occupied = true
        Game.player.boat = self
        Game.player.velocity = Vector3.ZERO
        Game.player.combat.cancel()
        Game.player.set_traversal_equipment(true)
        Game.notice.emit("W/S · paddle   A/D · steer   E · disembark")

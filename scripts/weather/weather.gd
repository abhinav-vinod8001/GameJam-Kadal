extends Node3D

var environment: Environment
var sun: DirectionalLight3D
var rain: CPUParticles3D
var weather_index := 0
var clock := 0.0
var change_clock := 0.0
var thunder_clock := 18.0
var target_rain := 0.0
var rain_strength := 0.0
var cloud_strength := 0.0
var wet_clock := 0.0
var manual := false
const NAMES = ["Clear", "Cloudy", "Monsoon", "Heavy rain"]

func _ready():
	var env_node = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var material = ShaderMaterial.new()
	material.shader = preload("res://shaders/coastal_sky.gdshader")
	sky.sky_material = material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("cad9cb")
	environment.ambient_light_energy = .38
	environment.ambient_light_sky_contribution = 0.0
	environment.reflected_light_source = 2
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("90b9b4")
	environment.fog_density = .0017
	environment.fog_sky_affect = 0.0
	env_node.environment = environment
	add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35,-136,0)
	sun.light_color = Color("ffe4ac")
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.shadow_opacity = .74
	sun.directional_shadow_max_distance = 100
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	rain = CPUParticles3D.new()
	rain.amount = 1100
	rain.lifetime = 1.2
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(18,0,18)
	rain.direction = Vector3(-.12,-1,.07)
	rain.spread = 2
	rain.initial_velocity_min = 22
	rain.initial_velocity_max = 27
	rain.gravity = Vector3(0,-6,0)
	rain.scale_amount_min = .65
	rain.scale_amount_max = 1.0
	var drop = BoxMesh.new()
	drop.size = Vector3(.012,.55,.012)
	rain.mesh = drop
	var rain_mat = Craft.mat("b4d8d3").duplicate()
	rain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mat.albedo_color.a = .45
	rain.material_override = rain_mat
	add_child(rain)
	rain.emitting = false

func _process(delta):
	clock += delta
	change_clock += delta
	if not manual and change_clock>100 and Game.mode!="menu":
		change_clock = 0
		set_weather((weather_index+1)%4)
	if Game.player:
		rain.global_position = Game.player.global_position+Vector3.UP*17
	rain_strength = move_toward(rain_strength,target_rain,delta*.18)
	cloud_strength = move_toward(cloud_strength,[0.0,.5,.8,1.0][weather_index],delta*.15)
	wet_clock += delta
	if wet_clock > .5:
		wet_clock = 0
		for material in Craft.cache.values():
			if material is StandardMaterial3D and material.metallic == 0:
				material.roughness = lerpf(.83,.4,rain_strength)
				material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX if rain_strength>.2 else BaseMaterial3D.SPECULAR_DISABLED
	rain.emitting = rain_strength>.05
	
	var day = .5+.5*sin(clock*.0015+.5)
	var warmth = .5+.5*sin(clock*.0015+1.0)
	sun.light_color = Color("ffd18a").lerp(Color("ffe6b7"),warmth*.25).lerp(Color("a3bad1"),cloud_strength*.8)
	sun.light_energy = lerpf(.33+day*.10,.13,cloud_strength)
	sun.rotation_degrees.x = -18-day*12
	environment.ambient_light_energy = lerpf(.55,.49,cloud_strength)
	environment.fog_density = lerpf(.00165,.006,cloud_strength)
	var sky_mat = environment.sky.sky_material as ShaderMaterial
	var painted_cloud = snappedf(cloud_strength, .025)
	if sky_mat.get_shader_parameter("storm") != painted_cloud:
		sky_mat.set_shader_parameter("storm", painted_cloud)
	if Game.world:
		Game.world.water_material.set_shader_parameter("rain",rain_strength)
		Game.world.water_material.set_shader_parameter("storm",cloud_strength)
	if Game.audio: Game.audio.set_rain(rain_strength)
	if weather_index==3:
		thunder_clock -= delta
		if thunder_clock<0:
			thunder_clock = randf_range(15,30)
			lightning()

func set_weather(index: int):
	weather_index = index%4
	target_rain = [0.0,0.0,.65,1.0][weather_index]
	rain.amount = 1100 if weather_index == 3 else 650
	Game.last_weather = NAMES[weather_index]
	Game.notice.emit(NAMES[weather_index]+" · the coast changes with the wind")

func cycle():
	manual = true
	set_weather(weather_index+1)

func lightning():
	environment.background_energy_multiplier = 2.5
	var tween = create_tween()
	tween.tween_property(environment,"background_energy_multiplier",1.0,.18)
	Game.audio.play("thunder",-6)

extends Node

# Small mirrored view, shared world, no recursive water rendering; 30 Hz maximum.
const WATER_Y = .18
const NO_REFLECTION = 1 << 19
var surface: ShaderMaterial
var viewport: SubViewport
var mirror: Camera3D
var elapsed := 1.0
var updates := 0
var clip_materials: Array[ShaderMaterial] = []

func _ready():
	if DisplayServer.get_name() == "headless": return
	viewport = SubViewport.new()
	viewport.name = "WaterReflectionView"
	viewport.size = Vector2i(768,480)
	viewport.world_3d = get_viewport().world_3d
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.positional_shadow_atlas_size = 0
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	add_child(viewport)
	mirror = Camera3D.new()
	mirror.cull_mask = ((1 << 20)-1) & ~NO_REFLECTION
	mirror.far = 420
	viewport.add_child(mirror)
	mirror.make_current()
	surface.set_shader_parameter("planar_reflection",viewport.get_texture())
	for label in get_tree().get_nodes_in_group("reflection_hidden"):
		if label is VisualInstance3D: label.layers = NO_REFLECTION
	for material in Craft.cache.values():
		if material is ShaderMaterial and material.shader.resource_path.get_file() in ["inked_character.gdshader","painted_surface.gdshader","boat_wood.gdshader"]:
			clip_materials.append(material)
	process_priority = 90

func _process(delta):
	if not is_instance_valid(mirror): return
	elapsed += delta
	var source = get_viewport().get_camera_3d()
	if not is_instance_valid(source) or source.global_position.y < WATER_Y+.12:
		surface.set_shader_parameter("reflection_enabled",false)
		return
	if elapsed < 1.0/30.0: return
	elapsed = 0.0
	var screen = get_viewport().get_visible_rect().size
	var desired = Vector2i(768,maxi(216,int(768.0*screen.y/maxf(screen.x,1.0))))
	if viewport.size != desired: viewport.size = desired
	var pose: Transform3D = source.get_camera_transform()
	var position_value = pose.origin
	position_value.y = WATER_Y*2.0-position_value.y
	var forward = -pose.basis.z
	forward.y = -forward.y
	var up = pose.basis.y
	up.y = -up.y
	mirror.global_position = position_value
	mirror.look_at(position_value+forward,-up)
	for material in clip_materials: material.set_shader_parameter("water_mirror_camera",position_value)
	mirror.fov = source.fov
	mirror.keep_aspect = source.keep_aspect
	mirror.near = source.near
	mirror.environment = source.environment
	var projection = mirror.get_camera_projection()*Projection(mirror.get_camera_transform().affine_inverse())
	surface.set_shader_parameter("reflection_projection",projection)
	surface.set_shader_parameter("reflection_enabled",true)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	updates += 1

func _exit_tree():
	for material in clip_materials: material.set_shader_parameter("water_mirror_camera",Vector3(-999,-999,-999))
	clip_materials.clear()
	if is_instance_valid(surface):
		surface.set_shader_parameter("reflection_enabled",false)
		surface.set_shader_parameter("planar_reflection",null)

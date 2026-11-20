shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec3 water_mirror_camera = vec3(-999.0);
varying vec3 world_position;

void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }

uniform vec3 rim_tint : source_color = vec3(.64,.78,.89);
uniform float rim_strength : hint_range(0.0,.35) = .14;

void fragment() {
	if (distance(CAMERA_POSITION_WORLD,water_mirror_camera)<.02 && world_position.y<.18) { discard; }
	ALBEDO = COLOR.rgb;
	float facing = max(abs(dot(NORMAL, VIEW)), 0.0);
	float rim = smoothstep(.55,.97,1.0-facing);
	EMISSION = rim_tint * (.34+.66*COLOR.rgb) * rim * rim_strength;
	ROUGHNESS = .85;
}

void light() {
	float incidence = dot(NORMAL, LIGHT);
	float lit = smoothstep(.08,.19,incidence);
	float key = smoothstep(.50,.61,incidence);
	float band = .095 + lit*.32 + key*.52;
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * (band * ATTENUATION / PI);
}

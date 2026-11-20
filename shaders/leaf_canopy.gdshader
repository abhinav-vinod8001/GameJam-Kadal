shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform float wind = .18;
uniform float rim = .10;
uniform bool use_vertex_color = true;
uniform vec3 pigment : source_color = vec3(.25,.47,.28);
varying vec3 crown_tint;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.x += sin(TIME * 1.45 + world_pos.x * .38 + world_pos.z * .24) * wind * UV.y;
	VERTEX.z += cos(TIME * 1.25 + world_pos.x * .29) * wind * .52 * UV.y;
	crown_tint = use_vertex_color ? COLOR.rgb : pigment;
}
void fragment() {
	float vein = (1.0 - smoothstep(.01, .10, abs(UV.x - .5))) * .10;
	ALBEDO = crown_tint * (.88 + .21 * UV.y + vein);

	ROUGHNESS = 1.0;
	EMISSION = crown_tint * rim * (.4 + .6 * pow(1.0 - abs(dot(NORMAL, VIEW)), 2.2));
}


void light() {
	float incidence = abs(dot(NORMAL, LIGHT));
	float lit = smoothstep(.13,.24,incidence);
	float key = smoothstep(.53,.65,incidence);
	float band = .19 + lit*.36 + key*.37;
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * (band * ATTENUATION / PI);
}

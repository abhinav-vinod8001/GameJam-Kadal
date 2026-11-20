shader_type spatial;
render_mode specular_schlick_ggx, cull_disabled;

uniform vec3 water_mirror_camera = vec3(-999.0);

uniform vec4 pigment : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
uniform float frequency = 1.0;
uniform float grain = .20;
uniform float moss_amount = 0.0;
uniform float roughness_value = .88;
uniform vec3 grain_axis = vec3(1.0);
varying vec3 world_pos;

float hash(vec3 p) {
	p = fract(p * .1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
		mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
		mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	if (distance(CAMERA_POSITION_WORLD,water_mirror_camera)<.02 && world_pos.y<.18) { discard; }
	vec3 p = world_pos * frequency * grain_axis;
	float wash = noise(p * .62);
	float grit = noise(p * 4.8);
	float pores = noise(p * 21.0);
	vec3 base = use_vertex_color ? COLOR.rgb : pigment.rgb;
	float shade = 1.0 + (wash - .5) * grain * 1.7 + (grit - .5) * grain
		+ (pores - .5) * grain * .45;
	if (moss_amount > .01) {
		vec3 world_normal = mat3(INV_VIEW_MATRIX) * NORMAL;
		float facing_up = max(0.0,world_normal.y);
		float moss = smoothstep(.51,.68,wash*.69+grit*.20+facing_up*.26);
		base = mix(base,vec3(.32,.43,.22),moss*moss_amount);
	}
	ALBEDO = base * shade;
	ROUGHNESS = roughness_value;
	SPECULAR = .19;
}

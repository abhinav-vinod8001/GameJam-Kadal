shader_type spatial;
render_mode cull_disabled, specular_disabled, depth_draw_never;

uniform vec4 earth : source_color = vec4(.66,.52,.34,1.0);
varying vec2 world_xz;

float seed(vec2 p) {
	return fract(sin(dot(p,vec2(41.31,113.57)))*43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 a = fract(p);
	a = a*a*(3.0-2.0*a);
	return mix(mix(seed(cell),seed(cell+vec2(1,0)),a.x),
		mix(seed(cell+vec2(0,1)),seed(cell+1.0),a.x),a.y);
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz;
}

void fragment() {
	float grit = noise(world_xz*12.0);
	float wash = noise(world_xz*1.38);
	float edge = 1.0-abs(UV.x*2.0-1.0);
	float mottled_border = edge+(wash-.5)*.19+(grit-.5)*.073;
	ALPHA = smoothstep(.02,.28,mottled_border);
	float wheel_tracks = 1.0-.035*exp(-100.0*pow(abs(UV.x-.5)-.20,2.0));
	vec3 shade = mix(vec3(.85,.81,.76),vec3(1.13,1.10,1.05),wash);
	ALBEDO = earth.rgb * shade * (.91+.19*grit) * wheel_tracks;
	ROUGHNESS = 1.0;
}

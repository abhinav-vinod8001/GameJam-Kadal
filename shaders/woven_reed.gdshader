shader_type spatial;
render_mode cull_disabled, specular_disabled;

void fragment() {
	float row = floor(UV.y * 22.0);
	float bands = smoothstep(.10,.32,fract(UV.y * 22.0));
	float reed = smoothstep(.12,.40,fract(UV.x * 37.0 + row * .5));
	float fibers = .028 * sin(UV.x * 628.0) + .022 * sin(UV.y * 480.0);
	ALBEDO = mix(vec3(.39,.23,.115),vec3(.70,.49,.257),bands*.62+reed*.33+fibers);
	ROUGHNESS = 1.0;
}

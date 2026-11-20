shader_type spatial;
render_mode cull_disabled, specular_disabled;
varying vec4 tint;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	float flex = UV.y * UV.y;
	VERTEX.x += sin(TIME * 1.65 + w.x * .6 + w.z * .4) * flex * .15;
	VERTEX.z += cos(TIME * 1.2 + w.z * .6) * flex * .07;
	tint = COLOR;
}
void fragment() {
	ALBEDO = tint.rgb * mix(.57, 1.38, UV.y);
	ROUGHNESS = 1.0;
	BACKLIGHT = tint.rgb * .28;
	EMISSION = tint.rgb * UV.y * .11;
}

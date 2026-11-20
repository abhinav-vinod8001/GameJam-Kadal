shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec4 dye : source_color = vec4(.66,.28,.19,1);
uniform vec4 thread : source_color = vec4(.90,.73,.43,1);

void vertex() {
	float sway = sin(TIME * 2.0 + UV.x * 6.0) * sin(UV.y * PI);
	VERTEX.y += sway * .033;
}

void fragment() {
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float border = smoothstep(.024,.032,edge) * (1.0 - smoothstep(.061,.069,edge));
	float stitch = smoothstep(.078,.081,edge) * (1.0 - smoothstep(.087,.092,edge));
	float folds = .88 + .12 * sin(UV.x * 38.0 + sin(UV.y*7.0));
	ALBEDO = mix(dye.rgb,thread.rgb,border+stitch*.6) * folds;
	BACKLIGHT = dye.rgb * .25;
	ROUGHNESS = 1.0;
}

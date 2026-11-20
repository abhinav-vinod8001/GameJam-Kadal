shader_type spatial;
render_mode unshaded,cull_disabled,depth_prepass_alpha;

float hash(float p) { return fract(sin(p*113.7)*8421.9); }
void fragment() {
	float u = UV.x;
	float v = UV.y;
	float edge = smoothstep(0.0,.13,u)*(1.0 - smoothstep(.86,1.0,u));
	float wisps = smoothstep(.10,.88,sin(u*36.0+sin(v*7.0-TIME*2.2)*1.8));
	float seams = pow(max(0.0,sin(u*97.0+cos(v*9.0-TIME*2.7)*1.45)),4.0);
	float drops = smoothstep(.1,.95,sin(v*58.0-TIME*13.0+hash(floor(u*18.0))*4.0));
	float spray = smoothstep(.71,1.0,v) * .28 + .13*(1.0-v);
	float crest = smoothstep(.0,.10,v);
	vec3 white = vec3(.88,.98,.91);
	ALBEDO = mix(vec3(.39,.70,.71),white, .29+wisps*.45+drops*.11+spray);
	ALPHA = edge * crest * (.64 + wisps*.18+seams*.11+spray*.2);
}

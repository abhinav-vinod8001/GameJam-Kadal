shader_type sky;

uniform float storm : hint_range(0.0, 1.0) = 0.0;
uniform float lightning = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
		mix(hash(i + vec2(0, 1)), hash(i + 1.0), f.x), f.y);
}
float clouds(vec2 p) {
	return noise(p) * .58 + noise(p * 2.1 + 8.0) * .25
		+ noise(p * 4.3 - 12.0) * .12 + noise(p * 9.1) * .05;
}
void sky() {
	vec3 dir = EYEDIR;
	float height = max(dir.y, 0.0);
	vec3 zenith = mix(vec3(.24, .57, .79), vec3(.20, .32, .42), storm);
	vec3 horizon = mix(vec3(.91, .91, .76), vec3(.56, .71, .72), storm);
	vec3 base = mix(horizon, zenith, pow(height, .55));
	vec2 p = dir.xz / (max(dir.y, .018) + .29) * 2.5 + vec2(3.8, 9.2);
	float field = clouds(p);
	float opacity = smoothstep(.48 - storm * .16, .66 - storm * .14, field);
	opacity *= smoothstep(-.035, .13, dir.y);
	float relief = clouds(p - vec2(.22, .15)) - field;
	vec3 gray = mix(vec3(.66, .76, .82), vec3(.29, .40, .51), storm);
	vec3 cream = mix(vec3(1.0, .97, .87), vec3(.69, .75, .77), storm);
	vec3 cloud = mix(gray, cream, smoothstep(-.12, .12, relief + .035));
	vec3 sun_dir = normalize(vec3(-.64, .38, -.67));
	float sun_facing = max(dot(dir, sun_dir), 0.0);
	base += vec3(.32, .19, .066) * pow(sun_facing, 16.0) * (1.0 - storm);
	base += vec3(.65, .41, .16) * smoothstep(.9991, .9996, sun_facing) * (1.0 - storm);
	COLOR = mix(base, cloud, opacity * .96) * (1.0 + lightning);
}

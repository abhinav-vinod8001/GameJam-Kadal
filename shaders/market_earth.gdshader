shader_type spatial;
render_mode cull_disabled, specular_disabled, depth_draw_never;
varying vec2 ground_xz;
void vertex() { ground_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; }
float hash(vec2 p) { return fract(sin(dot(p,vec2(41.3,113.7)))*43758.54); }
float noise(vec2 p) {
    vec2 cell=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(cell),hash(cell+vec2(1,0)),f.x),mix(hash(cell+vec2(0,1)),hash(cell+1.0),f.x),f.y);
}
void fragment() {
    float grain=noise(ground_xz*15.0);
    float wash=sin(ground_xz.x*.63+sin(ground_xz.y*.37))*cos(ground_xz.y*.71);
    float edge=min(min(UV.x,1.0-UV.x)*43.0,min(UV.y,1.0-UV.y)*26.0);
    ALPHA=smoothstep(.0,1.4,edge+wash*.40+(grain-.5)*.18);
    ALBEDO=vec3(.56,.44,.28)*(.92+grain*.12+wash*.055);
    ROUGHNESS=1.0;
}

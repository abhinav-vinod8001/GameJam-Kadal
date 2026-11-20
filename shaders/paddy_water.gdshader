shader_type spatial;
render_mode cull_disabled, unshaded;
varying vec3 position_world;
void vertex() { position_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 p=position_world.xz;
    vec3 eye=normalize(CAMERA_POSITION_WORLD-position_world);
    float fresnel=pow(1.0-max(eye.y,0.0),3.0);
    float ripples=sin(p.x*7.0+p.y*4.0+TIME*.7)*sin(p.y*6.0-TIME*.8)*.015;
    ALBEDO=mix(vec3(.19,.27,.18),vec3(.56,.70,.64),.22+fresnel*.57)+ripples;
}

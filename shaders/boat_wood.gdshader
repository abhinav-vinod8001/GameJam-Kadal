shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform vec3 water_mirror_camera = vec3(-999.0);
varying vec3 world_position;
varying vec2 plank_uv;
void vertex() { plank_uv=UV; world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    if (distance(CAMERA_POSITION_WORLD,water_mirror_camera)<.02 && world_position.y<.18) { discard; }
    float grain=sin(plank_uv.x*96.0+sin(plank_uv.x*7.0+plank_uv.y*21.0)*2.8);
    float seam=smoothstep(.0,.055,fract(plank_uv.y*4.0))*smoothstep(.0,.055,1.0-fract(plank_uv.y*4.0));
    ALBEDO=COLOR.rgb*(.91+grain*.055)*mix(.58,1.0,seam);
    ROUGHNESS=.46;
    SPECULAR=.32;
}

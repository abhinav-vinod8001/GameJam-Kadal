shader_type spatial;
render_mode cull_disabled, specular_disabled;
varying vec3 rice_color;
void vertex() {
    vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    float flex=UV.y*UV.y;
    VERTEX.x+=sin(TIME*1.65+w.x*.85+w.z*.43)*flex*.095;
    VERTEX.z+=cos(TIME*1.24+w.z*.71)*flex*.045;
    rice_color=COLOR.rgb;
}
void fragment() {
    ALBEDO=rice_color*mix(.65,1.13,UV.y);
    BACKLIGHT=rice_color*.24;
    ROUGHNESS=.95;
}

shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
    float radius=length((UV-vec2(.5))*2.0);
    ALBEDO=vec3(.06,.10,.065);
    ALPHA=(1.0-smoothstep(.15,1.0,radius))*.22;
}

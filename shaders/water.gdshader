shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D planar_reflection : source_color, repeat_disable, filter_linear;
uniform mat4 reflection_projection;
uniform bool reflection_enabled = false;
uniform float rain = 0.0;
uniform float storm = 0.0;
uniform vec3 deep_color : source_color = vec3(.018,.18,.23);
uniform vec3 shallow_color : source_color = vec3(.12,.49,.39);
uniform vec3 sky_color : source_color = vec3(.55,.79,.88);
uniform vec3 boat_position = vec3(-999.0);
uniform vec2 boat_forward = vec2(0.0,-1.0);
uniform float boat_speed = 0.0;
varying vec3 world_pos;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);
}
float wave(vec2 p) {
    float broad = sin(dot(p,vec2(.63,.41))+TIME*.78)*.045;
    float cross_wave = sin(dot(p,vec2(-1.15,.72))-TIME*1.08)*.021;
    float detail = sin(dot(p,vec2(2.6,1.43))+TIME*1.6)*.008;
    return (broad+cross_wave+detail)*(1.0+storm*.6);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 p=world_pos.xz;
    float w=wave(p);
    vec2 gradient=vec2(wave(p+vec2(.055,0.0))-w,wave(p+vec2(0.0,.055))-w)/.055;
    vec3 n=normalize(vec3(-gradient.x,1.0,-gradient.y));
    vec3 to_eye=normalize(CAMERA_POSITION_WORLD-world_pos);
    float fresnel=.035+.965*pow(1.0-max(dot(to_eye,n),0.0),4.5);
    float raw_depth=texture(scene_depth,SCREEN_UV).r;
    vec3 ndc=vec3(SCREEN_UV,raw_depth)*2.0-1.0;
    vec4 below=INV_PROJECTION_MATRIX*vec4(ndc,1.0);
    below/=below.w;
    float thickness=max(0.0,-below.z+VERTEX.z);
    float absorption=1.0-exp(-thickness*.46);
    vec2 distortion=gradient*.018*min(thickness,.9);
    vec3 bed=texture(scene_color,clamp(SCREEN_UV+distortion,vec2(.002),vec2(.998))).rgb;
    vec3 body=mix(shallow_color,deep_color,1.0-exp(-thickness*.21));
    body=mix(bed*vec3(.69,.91,.82),body,clamp(absorption,.14,.97));
    float caustic=pow(max(0.0,1.0-abs(sin(p.x*3.1+sin(p.y*2.3+TIME*.65))+sin(p.y*3.5-TIME*.7))),8.0);
    body+=vec3(.21,.32,.17)*caustic*exp(-thickness*.8)*.20;
    vec3 reflected=reflect(-to_eye,n);
    vec3 sky=mix(sky_color,vec3(.28,.40,.45),storm);
    sky+=vec3(.08)*smoothstep(.45,.76,noise(reflected.xz*7.0));
    vec3 reflection=sky;
    if (reflection_enabled) {
        vec4 projected=reflection_projection*vec4(world_pos,1.0);
        vec2 uv=projected.xy/projected.w*.5+.5;
        uv.y=1.0-uv.y;
        vec2 bent=uv+gradient*.026;
        float inside=smoothstep(.0,.035,bent.x)*smoothstep(.0,.035,bent.y)
            *(1.0-smoothstep(.965,1.0,bent.x))*(1.0-smoothstep(.965,1.0,bent.y));
        vec3 image=texture(planar_reflection,clamp(bent,vec2(.002),vec2(.998))).rgb;
        reflection=mix(sky,image,inside*step(0.0,projected.w));
    }
    float reflection_weight=clamp(.22+fresnel*.74,.0,.94);
    vec3 water=mix(body,reflection,reflection_weight);
    float sun=pow(max(dot(reflected,normalize(vec3(-.64,.48,-.60))),0.0),170.0);
    water+=vec3(1.0,.80,.45)*sun*(1.0-storm*.85)*.52;
    float edge=1.0-smoothstep(.04,.55,thickness);
    float wash=.5+.5*sin(p.x*2.2+p.y*1.7-TIME*1.6+noise(p*2.0)*3.0);
    float foam=edge*smoothstep(.33,.78,wash)*.55;
    vec2 delta=p-boat_position.xz;
    float aft=-dot(delta,boat_forward);
    float lateral=abs(dot(delta,vec2(-boat_forward.y,boat_forward.x)));
    float wake_line=exp(-pow((lateral-(.53+max(aft,0.0)*.25))/.15,2.0));
    float wake=wake_line*smoothstep(.5,1.9,aft)*(1.0-smoothstep(3.0,10.0,aft))*min(abs(boat_speed)/6.0,1.0);
    float rain_rings=pow(max(0.0,sin(length(fract(p*1.6)-.5)*38.0-TIME*11.0)),17.0)*rain*.035;
    water=mix(water,vec3(.76,.89,.80),clamp(foam+wake*.45+rain_rings,0.0,.64));
    ALBEDO=water;
}

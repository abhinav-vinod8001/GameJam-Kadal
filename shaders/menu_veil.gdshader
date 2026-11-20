shader_type canvas_item;
uniform float opacity = 1.0;
void fragment(){
 float left = 1.0-smoothstep(.12,.8,UV.x);
 float edge = pow(abs(UV.y-.48)*1.6,2.0)*.25;
 COLOR=vec4(.022,.074,.078,(left*.86+edge)*opacity);
}

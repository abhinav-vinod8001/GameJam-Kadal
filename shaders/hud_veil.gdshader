shader_type canvas_item;
void fragment(){
 float top=(1.0-smoothstep(.0,.19,UV.y))*.4;
 float bottom=smoothstep(.73,1.0,UV.y)*.65;
 float vignette=pow(length((UV-.5)*vec2(1.0,.75)),3.0)*.22;
 COLOR=vec4(.016,.055,.06,top+bottom+vignette);
}

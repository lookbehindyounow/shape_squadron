shader_type spatial;
uniform float fade=1;

void fragment(){
	ALBEDO=vec3(1,0.65,0)*(0.7+0.3*fade);
	ALPHA=fade;
	SPECULAR=0.0;
}
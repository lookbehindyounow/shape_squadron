shader_type spatial;
uniform float fade;

void fragment(){
	ALBEDO=vec3(2,1.3,0);
	ALPHA=fade;
	SPECULAR=0.0;
}
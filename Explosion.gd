extends MeshInstance3D
var life=3

func _ready():
	mesh.material=ShaderMaterial.new()
	mesh.material.set_shader(preload("res://explosion.gdshader"))

func _process(delta):
#	if life<0:
#		queue_free()
	life-=delta
	if life>0:
		scale+=Vector3(1,1,1)*life/10
	mesh.material.set_shader_parameter("fade",life/3)

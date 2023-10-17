extends MeshInstance3D
var cycle_length=0.2
var life
var switched=false
var fader=preload("res://explosion.tres")

func _ready():
	life=2*cycle_length

func _process(delta):
	if life>cycle_length:
		mesh.material.albedo_color=Color("#ff9300")*(0.5+0.5*(life-cycle_length)/cycle_length)
	elif life>0:
		if switched:
			mesh.material.set_shader_parameter("fade",life/cycle_length)
		else:
			switched=true
			mesh.material=fader
	else:
		queue_free()
	scale+=Vector3(1,1,1)*((life**2)/2)
	life-=delta

extends MeshInstance3D
var cycle_length=0.2
var life
var switched=false
var fader=preload("res://explosions/explosion.tres")
var explosion_sound=preload("res://explosions/explosion.mp3")
var big_explosion_sound=preload("res://explosions/big_explosion.mp3")

func _ready():
	life=2*cycle_length
	if cycle_length>0.3:
		$AudioStreamPlayer3D.set_stream(big_explosion_sound)
		if cycle_length>0.45:
			$AudioStreamPlayer3D.volume_db=-6
			$AudioStreamPlayer3D.attenuation_model=3
	else:
		$AudioStreamPlayer3D.set_stream(explosion_sound)
	$AudioStreamPlayer3D.play()

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

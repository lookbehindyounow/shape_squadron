extends MeshInstance3D
var life
var total_life
var explosion_sound=preload("res://explosions/explosion.mp3")
var big_explosion_sound=preload("res://explosions/big_explosion.mp3")

func _ready():
	total_life=life
	if life>0.5:
		$AudioStreamPlayer3D.set_stream(big_explosion_sound)
		if life>0.8:
			$AudioStreamPlayer3D.volume_db=-6
			$AudioStreamPlayer3D.attenuation_model=3
	else:
		$AudioStreamPlayer3D.set_stream(explosion_sound)
	$AudioStreamPlayer3D.play()
	
	mesh.material=StandardMaterial3D.new()
	mesh.material.set_transparency(1)
	mesh.material.flags_unshaded=true
	mesh.material.albedo_color=Color("#ff9300")

func _physics_process(delta):
	mesh.material.albedo_color.a=life/total_life
	scale+=Vector3(1,1,1)*((life**2)/(2.0))
	if life<0:
		queue_free()
	life-=delta

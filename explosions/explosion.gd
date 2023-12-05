extends MeshInstance3D
var life
var total_life

func _ready():
	mesh.material=StandardMaterial3D.new()
	mesh.material.set_transparency(1) # ENABLES transparency, does not set transparency value
	mesh.material.flags_unshaded=true
	mesh.material.albedo_color=Color("#ff9300")

func set_up(_position,_life):
	scale=Vector3.ONE
	position=_position
	life=_life
	total_life=_life
	if total_life>0.8:
		$AudioStreamPlayer3D.volume_db=-6
		$AudioStreamPlayer3D.attenuation_model=3
	else:
		$AudioStreamPlayer3D.volume_db=6
		$AudioStreamPlayer3D.attenuation_model=1

func _enter_tree():
	var sound
	if total_life>0.5:
		sound=get_node("/root/Main").big_explosion_sound
	else:
		sound=get_node("/root/Main").explosion_sound
	$AudioStreamPlayer3D.set_stream(sound)

func _physics_process(delta):
	mesh.material.albedo_color.a=life/total_life
	scale+=Vector3(1,1,1)*((life)**2)/2.0
	if life<0:
		get_node("/root/Main").explosion_pool.append(self)
		get_node("/root/Main").remove_child(self)
	life-=delta

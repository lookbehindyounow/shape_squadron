extends RigidBody3D
var life=10
var target
var target_angles
var watching
var silent

func _ready():
	contact_monitor=true
	max_contacts_reported=1

func set_up(_transform,_target,_watching,_silent=false):
	target=_target
	watching=_watching
	silent=_silent
	transform=_transform
	position+=2*basis.z
	life=10
	
	if target:
		target.missiles_following.append(self)

func _physics_process(delta):
	if get_colliding_bodies() || life<0:
		if get_colliding_bodies() && get_colliding_bodies()[0].is_in_group("jets"):
			get_colliding_bodies()[0]._on_missile_hit()
		explode()
	life-=delta
	
	if target:
		target_angles=target.Jet.get_HUD_angles(transform,target.position)
		var pitching=-4*target_angles[1]*cos(target_angles[0])
		var yawing=-4*target_angles[1]*sin(target_angles[0])
		transform.basis=target.Jet.turn(transform.basis,0,pitching,yawing,delta)
		if target_angles[1]>0.65:
			target.missiles_following.erase(self)
			target=null
			target_angles=null
	position+=25*delta*transform.basis.z
	
	if watching && Input.is_action_pressed("missile") && life>9.7 && life<9.75:
		get_node("/root/Main/UI").missile=self
		$Camera3D.current=true

func explode():
	if watching:
		get_node("/root/Main/UI").missile=null
	if target:
		target.missiles_following.erase(self)
	get_node("/root/Main").explosion(position,0.4,silent)
	get_node("/root/Main").missile_pool.append(self)
	get_node("/root/Main").remove_child(self)

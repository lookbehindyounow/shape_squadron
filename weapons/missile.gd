extends RigidBody3D
var life=10
var target
var target_angles={}
var watching
var silent
var Jet

func _ready():
	contact_monitor=true
	max_contacts_reported=1
	Jet=get_node("/root/Main").jet_methods

func set_up(_transform,_target,_watching,_silent=false):
	target=_target
	watching=_watching
	silent=_silent
	transform=_transform
	position+=2*basis.z
	life=10
	
	if target:
		target.state.missiles_following.append(self)

func _physics_process(delta):
	if get_colliding_bodies() || life<0:
		if get_colliding_bodies() && get_colliding_bodies()[0].is_in_group("jets"):
			get_colliding_bodies()[0]._on_missile_hit()
		explode()
	life-=delta
	
	if target:
		target_angles=Jet.get_HUD_angles(transform,target.position)
		var intercept_pos=Jet.find_intercept(position,target.position,target.velocity,25,target_angles.distance)
		var intercept_angles=Jet.get_HUD_angles(transform,intercept_pos)
		var pitching=-4*intercept_angles.forward_angle*cos(intercept_angles.clock_face)
		var yawing=-4*intercept_angles.forward_angle*sin(intercept_angles.clock_face)
		basis=Jet.turn(basis,0,pitching,yawing,delta)
		if target_angles.forward_angle>0.65: # target_angles or intercept_angles here? experiment
			target.state.missiles_following.erase(self)
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
		target.state.missiles_following.erase(self)
	get_node("/root/Main").explosion(position,0.4,silent)
	get_node("/root/Main").missile_pool.append(self)
	get_node("/root/Main").remove_child(self)

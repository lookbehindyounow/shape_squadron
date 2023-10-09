extends CharacterBody3D
const acceleration=2
const top_speed=10
var speed=0
var bullet_scene=preload("res://bullet.tscn")

var accelerating=false
var decelerating=false
var rolling_left=false
var rolling_right=false
var pitching_up=false
var pitching_down=false
var shooting=false

func _physics_process(delta):
	var player_pos=get_node("root/Main/Player").position
	var player_direction=player_pos-position
	var tracker_plane=Plane(position,position+transform.basis.z,player_pos)
	var HUD_angle=acos(tracker_plane.normal.dot(transform.basis.y))
	
	if accelerating:
		speed+=acceleration*delta
		if speed>top_speed:
			speed=top_speed
	if decelerating:
		speed-=acceleration*delta
		if speed<-top_speed:
			speed=-top_speed
	if rolling_left:
		transform.basis=transform.basis.rotated(transform.basis.z,-delta)
	if rolling_right:
		transform.basis=transform.basis.rotated(transform.basis.z,delta)
	if pitching_up:
		transform.basis=transform.basis.rotated(transform.basis.x,delta)
	if pitching_down:
		transform.basis=transform.basis.rotated(transform.basis.x,-delta)
	velocity=transform.basis.z*speed
	move_and_slide()
	
	if shooting:
		shoot()

func shoot():
	var bullet=bullet_scene.instantiate()
	bullet.global_transform=self.global_transform
	bullet.position+=self.transform.basis.z
	bullet.linear_velocity=transform.basis.z*50
	get_node("root/Main").add_child(bullet)

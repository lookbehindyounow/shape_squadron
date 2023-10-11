extends CharacterBody3D
var Jet=preload("res://JetMethods.gd")
const acceleration=2
const top_speed=10
var speed=10
var hits_taken=0
var crashes=0
signal hit
var cooldown=0
var HUD_points=[[[0,0],[0,0]]]

var chillin=false # for testing
func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_chillin") && event.pressed:
		chillin=not chillin

# could maybe have state:enum determined randomly

func _physics_process(delta):
	var player=get_node("/root/Main/Player")
	HUD_points[0]=Jet.track(transform,player.position,player.velocity)
	
	if chillin:
		velocity=Vector3.ZERO
	else:
		var suggestions=Jet.autopilot(HUD_points[0])
		var rolling=0.75*suggestions[0]
		var pitching=0.5*suggestions[1]
		
		var accelerating=false
		var decelerating=false
		if accelerating:
			speed=min(speed+acceleration*delta,top_speed)
		if decelerating:
			speed=min(speed-acceleration*delta,top_speed)
		# could also make pitch & roll depend on target o'clock or dot product navigation from autopilot if I get into that
		# both options would look more like analogue controls for player
		transform.basis=Jet.turn(transform.basis,rolling,pitching,delta)
		velocity=transform.basis.z*speed
	move_and_slide()
	
	if HUD_points[0][1][1]<PI/12:
		if cooldown>0.05:
			Jet.shoot(self)
			cooldown=0
		else:
			cooldown+=delta
	
	var collisions=[]
	for i in range(get_slide_collision_count()):
		if Jet.collide(get_slide_collision(i).get_collider()):
			hits_taken+=1
		else:
			crashes+=1
		hit.emit()

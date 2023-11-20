extends CharacterBody3D
var Jet=preload("res://players/JetMethods.gd")
var health=10
const acceleration=2
const top_speed=15
const roll_speed=0.75
const pitch_speed=0.75
const yaw_speed=1
var speed=15
var hits_taken=0
var crashes=0
var cooldown=0
var missiles=2
var missile_cooldown=0
var missiles_following=[]
var HUD_points=[]
var roll_momentum=0
var pitch_momentum=0
var yaw_momentum=0
var chemtrail_counter=0

signal die
func _ready():
	die.connect(get_node("/root/Main")._on_enemy_die.bind(self))

var chillin=false # for testing
func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_chillin") && event.pressed:
		chillin=not chillin

var state={"chasing":true,"chase_duration":0,"missile_memory":-1,"ground_memory":0}
var prev_targ_dist=0

func _physics_process(delta):
	var player=get_node("/root/Main/Player")
	var gaming=get_node("/root/Main").gaming
	if gaming:
		HUD_points=[Jet.track(transform,player.position,player.velocity)]
	else: # when player dies, have a spoof player in HUD_points for autopilot to direct to
		HUD_points=[Jet.track(transform,player.ave_enemy_pos+Vector3(100,0,0),Vector3.ZERO)]
	
	var allies=[]+get_node("/root/Main").enemies
	allies.erase(self)
	for ally in allies:
		HUD_points.append(Jet.track(transform,ally.position,ally.velocity,false))
	
	if chillin:
		velocity=Vector3.ZERO
	else:
		var target_distance=(HUD_points[0][0][2]-position).length()
		if gaming && target_distance<45 && HUD_points[0][1][1]<PI/12:
			if cooldown<0:
				get_node("/root/Main").bullet(transform)
				$AudioStreamPlayer3D.play()
				cooldown=0.05
			else:
				cooldown-=delta
		
		if HUD_points[0][0][1]<0.3 && target_distance<50:
			if missiles && missile_cooldown<0:
				get_node("/root/Main").missile(transform,player,false)
				missiles-=1
				missile_cooldown=3
		missile_cooldown-=delta
		
		var instructions=Jet.autopilot(transform,speed,pitch_speed,HUD_points,state,missiles_following) # change to just point locations (& ahead locations for enemies)
		
		state=instructions[4]
		state.chase_duration+=1
		if target_distance>200: # if far away
			state.chasing=true
			state.chase_duration=0
		elif target_distance<randf_range(18,22) && HUD_points[0][0][1]<0.3 && prev_targ_dist-target_distance>0.9*speed*delta:
			# if playing chicken & getting close
			state.chasing=false
			state.chase_duration=0
		elif !state.chasing && state.chase_duration>randi_range(200,20000): # if been retreating for a while
			state.chasing=true
			state.chase_duration=0
		elif state.chasing: # if pursuing
			if HUD_points[0][1][1]<0.3: # & target infront
				state.chase_duration=0 # forget how long been pursuing
			elif state.chase_duration>500: # if chasing tails for more than 8s
				state.chasing=false
				state.chase_duration=0
		prev_targ_dist=target_distance
		
		roll_momentum=(7.0*roll_momentum+instructions[0])/8
		pitch_momentum=(7.0*pitch_momentum+instructions[1])/8
		yaw_momentum=(7.0*yaw_momentum+instructions[2])/8
		
		speed=min(max(speed+(instructions[3]*acceleration*delta),5),top_speed)
		transform.basis=Jet.turn(transform.basis,roll_momentum*roll_speed,pitch_momentum*pitch_speed,yaw_momentum*yaw_speed,delta)
		velocity=transform.basis.z*speed

		chemtrail_counter+=1
		if chemtrail_counter>7:
			chemtrail_counter=0
			get_node("/root/Main").chemtrail(transform)
	move_and_slide()
	
	if not gaming: # remove spoof player from HUD points so it doesn't show up on enemies HUD when rendered in UI
		HUD_points.remove_at(0)
	
	for i in range(get_slide_collision_count()):
		if not get_slide_collision(i).get_collider().is_in_group("weapons"):
			diee()

func _on_bullet_hit():
	health-=1
	if health<=0:
		diee()

func _on_missile_hit():
	health-=5
	if health<=0:
		diee()

func diee():
	for missile in missiles_following:
		missile.target=null
	die.emit()

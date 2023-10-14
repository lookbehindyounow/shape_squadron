extends CharacterBody3D
var Jet=preload("res://JetMethods.gd")
var health=10
const acceleration=2
const top_speed=15
const roll_speed=0.75
const pitch_speed=0.75
var speed=15
var hits_taken=0
var crashes=0
var cooldown=0
var HUD_points=[]
var roll_momentum=0
var pitch_momentum=0

var rolling=0 # for showing in UI
var pitching=0

signal die
func _ready():
	die.connect(get_node("/root/Main")._on_enemy_die.bind(self))

var chillin=false # for testing
func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_chillin") && event.pressed:
		chillin=not chillin

# could maybe have state:enum determined randomly

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
		if gaming && HUD_points[0][1][1]<PI/12:
			if cooldown>0.05:
				Jet.shoot(self)
				cooldown=0
			else:
				cooldown+=delta
		
		var instructions=Jet.autopilot(transform,speed,pitch_speed,HUD_points) # change to just point locations (& ahead locations for enemies)
		
		rolling=instructions[0] # for showing in UI
		pitching=instructions[1]
		
		roll_momentum=(10.0*roll_momentum+instructions[0])/11
		pitch_momentum=(10.0*pitch_momentum+instructions[1])/11
		
		speed=min(speed+(instructions[2]*acceleration*delta),top_speed)
		transform.basis=Jet.turn(transform.basis,roll_momentum*roll_speed,pitch_momentum*pitch_speed,delta)
		velocity=transform.basis.z*speed
	move_and_slide()
	
	if not gaming: # remove spoof player from HUD points so it doesn't show up on enemies HUD when rendered in UI
		HUD_points.remove_at(0)
	
	for i in range(get_slide_collision_count()):
		if not get_slide_collision(i).get_collider().is_in_group("bullets"):
			die.emit()

func _on_bullet_hit():
	health-=1
	if health<=0:
		die.emit()

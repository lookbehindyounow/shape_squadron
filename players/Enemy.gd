extends CharacterBody3D
var Jet
var health=10
const acceleration=2
const top_speed=15
const roll_speed=0.75
const pitch_speed=0.75
const yaw_speed=1
var speed=15
var hits_taken=0
var crashes=0
var cooldown=-1
var missiles=2
var missile_cooldown=-1
var HUD_points=[]
var roll_momentum=0
var pitch_momentum=0
var yaw_momentum=0
var chemtrail_counter=0

signal die
func _ready():
	Jet=get_node("/root/Main").jet_methods
	die.connect(get_node("/root/Main")._on_enemy_die.bind(self))

var chillin=false # for testing
func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_chillin") && event.pressed:
		chillin=!chillin

var state={
	"frame_count":0,
	"instructions":{},
	"chasing":true,
	"state_duration":0,
	"missiles_following":[],
	"missile_memory":-1,
	"ground_memory":-1,
	"emergency_override":false,
	"ray":PhysicsRayQueryParameters3D.create(Vector3.ZERO,Vector3.ZERO,collision_mask,[self])
}
var missiles_following=state.missiles_following

func _physics_process(delta):
	var player=get_node("/root/Main/Player")
	
	if chillin:
		HUD_points[0]=Jet.track(transform,player.position)
		velocity=Vector3.ZERO
	else:
		state.frame_count+=1
		if state.frame_count>5:
			state.frame_count=floori(randf()*1.2)
			state.thinking=true
		else:
			state.thinking=false
		
		state.gaming=get_node("/root/Main").gaming
		if state.gaming:
			HUD_points=[Jet.track(transform,player.position,player.velocity)]
		else: # when player dies, have a spoof player in HUD_points for autopilot to direct to
			var horizon=Jet.get_HUD_angles(transform,player.ave_enemy_pos+Vector3(100,0,0))
			HUD_points=[{"pos":horizon,"intercept":horizon}]
		
		var allies=[]+get_node("/root/Main").enemies
		allies.erase(self)
		for ally in allies:
			HUD_points.append(Jet.track(transform,ally.position))
		
		state=Jet.autopilot(transform,speed,pitch_speed,HUD_points,state,self) # change to just point locations (& ahead locations for enemies)
		
		if state.instructions.shooting:
			if cooldown<0:
				get_node("/root/Main").bullet(transform)
				$AudioStreamPlayer3D.play()
				cooldown=0.05
		if cooldown>0:
			cooldown-=delta
		
		if state.instructions.firing_missile:
			if missiles && missile_cooldown<0:
				get_node("/root/Main").missile(transform,player,false)
				missiles-=1
				missile_cooldown=3
		if missile_cooldown>0:
			missile_cooldown-=delta
		
		for instruction in ["pitching","rolling","yawing","accelerating"]:
			if !state.instructions.has(instruction):
				state.instructions[instruction]=0
		roll_momentum=(7.0*roll_momentum+state.instructions.rolling)/8 # smoothing controls to simulate inertia
		pitch_momentum=(7.0*pitch_momentum+state.instructions.pitching)/8
		yaw_momentum=(7.0*yaw_momentum+state.instructions.yawing)/8
		
		speed=min(max(speed+(state.instructions.accelerating*acceleration*delta),5),top_speed)
		transform.basis=Jet.turn(transform.basis,roll_momentum*roll_speed,pitch_momentum*pitch_speed,yaw_momentum*yaw_speed,delta)
		velocity=transform.basis.z*speed#*0.2
		move_and_slide()
		
		chemtrail_counter+=1
		if chemtrail_counter>7:
			chemtrail_counter=0
			get_node("/root/Main").chemtrail(transform)
		
		if !state.gaming: # remove spoof player from HUD points so it doesn't show up on enemies HUD when rendered in UI
			HUD_points.remove_at(0)
	
	for i in range(get_slide_collision_count()):
		if !get_slide_collision(i).get_collider().is_in_group("weapons"):
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
	for missile in state.missiles_following:
		missile.target=null
	die.emit()

extends CharacterBody3D
var Jet=preload("res://JetMethods.gd")
var health=10
const acceleration=2
const top_speed=10
var speed=10
var hits_taken=0
var crashes=0
var cooldown=0
var HUD_points=[]
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
	var allies=[]+get_node("/root/Main").enemies
	allies.erase(self)
	HUD_points=[Jet.track(transform,player.position,player.velocity)]
	for ally in allies:
		HUD_points.append(Jet.track(transform,ally.position,ally.velocity,false))
	
	if chillin:
		velocity=Vector3.ZERO
	else:
		var instructions=Jet.autopilot(transform,HUD_points)
		var rolling=0.75*instructions[0]
		var pitching=0.5*instructions[1]
		var accelerating=instructions[2]
		
		speed=min(speed+(accelerating*acceleration*delta),top_speed)
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
	
	for i in range(get_slide_collision_count()):
		health-=Jet.collide(get_slide_collision(i).get_collider())
		if health<=0:
			die.emit()

extends CharacterBody3D
const acceleration=2
const top_speed=10
var speed=10
var bullet_scene=preload("res://bullet.tscn")
var chillin=false # could maybe turn into state:enum
var player_o_clock=0
var hits_taken=0
var crashes=0
signal hit

func _unhandled_input(event):
	if event.keycode==KEY_V && event.pressed:
		chillin=not chillin

func _physics_process(delta):
	var accelerating=false
	var decelerating=false
	var rolling_left=false
	var rolling_right=false
	var pitching_up=false
	var pitching_down=false
	var shooting=false
	
	# same calculation below as in UI.gd finding enemies & marking them on the HUD
	var player_pos=get_node("/root/Main/Player").position
	var tracker_plane=Plane(position,position+transform.basis.z,player_pos)
	player_o_clock=tracker_plane.normal.signed_angle_to(transform.basis.x,-transform.basis.z)
	
	if (player_pos-position).normalized().dot(transform.basis.z)>0.966: # player almost directly infront (0.966=cos(15deg), 15deg angle to forward is 30deg cone of violence)
		shooting=true
#	if randf()<0.1*delta:
#		chillin=not(chillin)
	if not chillin:
		# could maybe reduce code here by using positive/negative dot products (against all transform basis axes) to figure out which way to go
		# but could also make enemy pitch & roll amount depend on player o'clock angle for smoothness, would be like analogue controls for player
		if abs(player_o_clock)>PI/20 && abs(player_o_clock)<0.95*PI: # if player not at top or bottom centre of clock face
			if abs(player_o_clock)<2*PI/3: # player in top 2/3 of clock face
				if player_o_clock>0:# top-right
					rolling_right=true
				else: # top-left
					rolling_left=true
			elif abs(player_o_clock)>=2*PI/3: # player in bottom 1/3 of clock face
				if player_o_clock>0: # bottom-right
					rolling_left=true
				else: # bottom-left
					rolling_right=true

		if abs(player_o_clock)<0.4*PI || abs(player_o_clock)>0.6*PI: # if player in top 2/5 or bottom 2/5 of clock face
			if (player_pos-position).normalized().dot(transform.basis.y)>0: # player above
				pitching_up=true
			else: # player below
				pitching_down=true
	
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
			transform.basis=transform.basis.rotated(transform.basis.x,-0.75*delta)
		if pitching_down:
			transform.basis=transform.basis.rotated(transform.basis.x,0.75*delta)
	velocity=transform.basis.z*speed
	move_and_slide()
	
	if shooting && not Time.get_ticks_msec()%100:
		shoot()
	
	for i in range(get_slide_collision_count()):
		if get_slide_collision(i).get_collider().is_in_group("bullets"):
			hits_taken+=1
		else:
			crashes+=1
		hit.emit()

func shoot():
	var bullet=bullet_scene.instantiate()
	bullet.global_transform=self.global_transform
	bullet.position+=self.transform.basis.z
	bullet.linear_velocity=transform.basis.z*25
	get_node("/root/Main").add_child(bullet)

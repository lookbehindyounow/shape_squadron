extends Control
var screen_dimensions
var icon_scene=preload("res://UI/icon.tscn")
var font=preload("res://UI/Xolonium-Regular.ttf")
var icons=[]
var missilecons=[]
var guy
var missile=null
var gyro_angle_momentum=PI/2

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"))

	var crosshair_points=[5*Vector2.UP,15*Vector2.UP,5*Vector2.DOWN,15*Vector2.DOWN,5*Vector2.LEFT,15*Vector2.LEFT,5*Vector2.RIGHT,15*Vector2.RIGHT]
	for i in range(8):
		crosshair_points[i]+=screen_dimensions/2.0
	draw_multiline(crosshair_points,Color("#0f0"))

	if guy && guy.health>0: # rolling altimeter
		var altitude=guy.transform.origin.y
		var centre=screen_dimensions/2.0
		var rolling=[] # draw points to be rotated

		# to find gyroscopic rotation angle, first project global up vector onto viewport plane
		var view_projected_up=Vector3.UP-guy.transform.basis.z.dot(Vector3.UP)*guy.transform.basis.z
		# the angle between said vector & the viewport's up vector is the angle to true up from viewport clock face up
		var gyro_angle=guy.transform.basis.y.signed_angle_to(view_projected_up,guy.transform.basis.z)
		# if proposed change in rotation greater than half a circle, then we are crossing +/-PI (turning upsidedown)
		if abs(gyro_angle-gyro_angle_momentum)>PI:
			# rotate in other direction instead, now abs(gyro_angle)>PI
			gyro_angle=(2*PI-abs(gyro_angle))*sign(gyro_angle_momentum)
		# rotation speed smoothing can now take place without worrying about crossing +/-PI messing up averages
		gyro_angle_momentum=(gyro_angle_momentum*2.0+gyro_angle)/3.0
		# if +/-PI is crossed
		if abs(gyro_angle_momentum)>PI:
			# wrap smoothed angle so new measured angles will have the same sign
			gyro_angle_momentum=(2*PI-abs(gyro_angle_momentum))*sign(gyro_angle_momentum)*-1

		# rolling
		var height=(fmod(0.5+altitude/10.0,1)-0.5)*Vector2.UP # offset for 10 line (where the number is)
		var lowght=(fmod(altitude/10.0,1)-0.5)*Vector2.UP # offset for 5 line
		rolling+=[0.8*Vector2.LEFT+height,0.2*Vector2.LEFT+height,0.8*Vector2.RIGHT+height,0.2*Vector2.RIGHT+height] # 10 line
		rolling+=[0.8*Vector2.LEFT+lowght,0.8*Vector2.RIGHT+lowght] # 5 line

		rolling+=[Vector2.LEFT,3*Vector2.LEFT,Vector2.RIGHT,3*Vector2.RIGHT] # ground parallel lines
		rolling+=[0.5*Vector2.UP+Vector2.LEFT,0.5*Vector2.DOWN+Vector2.LEFT,0.5*Vector2.UP+Vector2.RIGHT,0.5*Vector2.DOWN+Vector2.RIGHT] # lines containing rolling altimeter

		for i in rolling.size(): # gyroscopic rotation & scaling
			rolling[i]=screen_dimensions.y/6.6*rolling[i].rotated(gyro_angle_momentum)
		for i in rolling.size()/2.0: # drawing lines from pairs
			draw_line(centre+rolling[2*i],centre+rolling[2*i+1],Color("#0f0"))

		var number_pos=centre+12*Vector2.DOWN+(screen_dimensions.y/6.6)*height.rotated(gyro_angle_momentum) # altitude reading
		draw_char(font,number_pos+30*Vector2.LEFT,str(10*round(altitude/10.0))[0],40,Color("#0f0"))
		draw_char(font,number_pos,(str(10*round(altitude/10.0))+"0")[1],40,Color("#0f0"))
		
		if guy.state.avoid_memory:
			draw_line(centre,centre-screen_dimensions.y/2.2*guy.state.avoid_memory.normalized(),Color("fff"),3)
			for i in guy.state.avoid_points:
				if i==Vector2.ZERO:
					draw_arc(centre,50,0,2*PI,9,Color("#fff"))
				else:
					draw_circle(centre+i*200,10,Color("#fff"))

func _ready():
	guy=get_node("/root/Main/Player")
	screen_dimensions=get_node("/root").size
	$Endgame.hide()

func _physics_process(delta):
	if $Pain.color.a>0:
		$Pain.color.a-=delta/2
	
	if missile || guy.health==0:
		$StatusLabel.text=""
	else:
		$StatusLabel.text="Health: %s\nMissiles: %s\nSpeed: %s" %[guy.health,guy.missiles,round(guy.speed*10)/10.0]
	
	for entity in icons:
		for icon in entity:
			icon.queue_free()
	icons=[]
	for missilecon in missilecons:
		missilecon.queue_free()
	missilecons=[]
	
	if missile:
		if missile.target_angles:
			var icon=icon_scene.instantiate()
			var point_radius=min(1,missile.target_angles.forward_angle/0.65)
			icon.position=Vector2(screen_dimensions/2)+((point_radius*screen_dimensions.y/2.2)*Vector2.UP.rotated(missile.target_angles.clock_face))
			if point_radius<1:
				icon.set_type("locked")
			icons.append([icon])
			add_child(icons[0][0])
		if not Input.is_action_pressed("missile"):
			guy.get_node("Camera3D").current=true
			missile.watching=false
			missile=null
	else:
		var HUD_points=guy.HUD_points
		for following_missile in guy.state.missiles_following:
			if Time.get_ticks_msec()%100<50:
				var missangles=guy.Jet.get_HUD_angles(guy.transform,following_missile.position)
				var missilecon=icon_scene.instantiate()
				var point_radius=min(1,missangles.forward_angle/0.65)
				missilecon.position=Vector2(screen_dimensions/2)+((point_radius*screen_dimensions.y/2.2)*Vector2.UP.rotated(missangles.clock_face))
				missilecon.set_type("missile")
				missilecon.set_colour("#f80")
				add_child(missilecon)
				missilecons.append(missilecon)
		
		var mindex=null
		var smallest_forward_angle=null
		for i in range(HUD_points.size()):
			icons.append([icon_scene.instantiate()])
			# angle between top of HUD circle & forward is 0.65 rad
			var point_radius=min(1,HUD_points[i].pos.forward_angle/0.65)
			icons[i][0].position=Vector2(screen_dimensions/2)+((point_radius*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i].pos.clock_face))
			if point_radius<1:
				icons[i][0].set_type("hollow")
			if not HUD_points[i].has("intercept"):
				icons[i][0].set_colour("#00f")
			add_child(icons[i][0])
			
			if HUD_points[i].has("intercept"):
				if HUD_points[i].intercept.forward_angle<0.65:
					icons[i].append(icon_scene.instantiate())
					icons[i][1].position=Vector2(screen_dimensions/2)+(((HUD_points[i].intercept.forward_angle/0.65)*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i].intercept.clock_face))
					icons[i][1].set_type("ahead")
					add_child(icons[i][1])
				
				if HUD_points[i].pos.forward_angle<0.3 && HUD_points[i].pos.distance<50:
					if mindex==null || HUD_points[i].pos.forward_angle<smallest_forward_angle:
						smallest_forward_angle=HUD_points[i].pos.forward_angle
						mindex=i
		if mindex!=null:
			icons[mindex][0].set_type("locked")
	
	queue_redraw()

func flash(amount):
	if $Pain.color.a<1:
		$Pain.color.a+=amount

extends Control
var screen_dimensions
var icon_scene=preload("res://UI/icon.tscn")
var font=preload("res://UI/Xolonium-Regular.ttf")
var icons=[]
var missilecons=[]
var guy
var missile=null
var prev_ground_angle=PI/2
var ground_angle_momentum=PI/2

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"))
	
	var crosshair_points=[5*Vector2.UP,15*Vector2.UP,5*Vector2.DOWN,15*Vector2.DOWN,5*Vector2.LEFT,15*Vector2.LEFT,5*Vector2.RIGHT,15*Vector2.RIGHT]
	for i in range(8):
		crosshair_points[i]+=screen_dimensions/2.0
	draw_multiline(crosshair_points,Color("#0f0"))
	
	if guy: # rolling altimeter
		var altitude=guy.transform.origin.y
		var centre=screen_dimensions/2.0
		var rolling=[] # draw points to be rotated
		
		# gyroscope angle
		var ground_angle=acos(guy.transform.basis.x.dot(Vector3.UP))*sign(guy.transform.basis.y.dot(Vector3.UP))
		var ang_diff=ground_angle-prev_ground_angle # rotation speed limit
		if abs(ang_diff)>2*PI-0.05: # if crossed over +/-PI
			pass
			ground_angle=(abs(ground_angle)+0.05-2*PI)*sign(ang_diff)
			print()
			print(ground_angle)
			print(prev_ground_angle)
		elif abs(ang_diff)>PI:
			ground_angle=prev_ground_angle-0.05*sign(ang_diff)
		elif abs(ang_diff)>0.05:
			ground_angle=prev_ground_angle+0.05*sign(ang_diff)
		ground_angle_momentum=(ground_angle_momentum*2.0+ground_angle)/3.0 # rotation speed smoothing
#		ground_angle_momentum=ground_angleSSD
		prev_ground_angle=ground_angle_momentum
		
		var height=(fmod(0.5+altitude/10.0,1)-0.5)*Vector2.RIGHT # roll amount
		var lowght=(fmod(guy.transform.origin.y/10.0,1)-0.5)*Vector2.RIGHT
		rolling+=[0.8*Vector2.UP+height,0.2*Vector2.UP+height,0.8*Vector2.DOWN+height,0.2*Vector2.DOWN+height]
		rolling+=[0.8*Vector2.UP+lowght,0.8*Vector2.DOWN+lowght]
		
		rolling+=[Vector2.UP,3*Vector2.UP,Vector2.DOWN,3*Vector2.DOWN] # ground parallel lines
		rolling+=[Vector2.UP+0.5*Vector2.LEFT,Vector2.UP+0.5*Vector2.RIGHT,Vector2.DOWN+0.5*Vector2.RIGHT,Vector2.DOWN+0.5*Vector2.LEFT] # beside rolling altimeter
		
		for i in rolling.size(): # gyroscopic rotation & scaling
			rolling[i]=screen_dimensions.y/6.6*rolling[i].rotated(ground_angle_momentum)
		for i in rolling.size()/2: # drawing lines from pairs
			draw_line(centre+rolling[2*i],centre+rolling[2*i+1],Color("#0f0"))
		
		var number_pos=centre+10*Vector2.DOWN+(screen_dimensions.y/6.6)*height.rotated(ground_angle_momentum) # altitude reading
		draw_char(font,number_pos+30*Vector2.LEFT,str(10*round(altitude/10.0))[0],40,Color("#0f0"))
		draw_char(font,number_pos,(str(10*round(altitude/10.0))+"0")[1],40,Color("#0f0"))

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
			var point_radius=min(1,missile.target_angles[1]/0.65)
			icon.position=Vector2(screen_dimensions/2)+((point_radius*screen_dimensions.y/2.2)*Vector2.UP.rotated(missile.target_angles[0]))
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
		if Time.get_ticks_msec()%100<50:
			for missile in guy.missiles_following:
				var missangles=guy.Jet.get_HUD_angles(guy.transform,missile.position)
				var missilecon=icon_scene.instantiate()
				var point_radius=min(1,missangles[1]/0.65)
				missilecon.position=Vector2(screen_dimensions/2)+((point_radius*screen_dimensions.y/2.2)*Vector2.UP.rotated(missangles[0]))
				missilecon.set_type("missile")
				missilecon.set_colour("#f80")
				add_child(missilecon)
				missilecons.append(missilecon)
		
		var mindex=null
		var smallest_forward_angle=null
		for i in range(HUD_points.size()):
			icons.append([icon_scene.instantiate()])
			# angle between top of HUD circle & forward is 0.65 rad
			var point_radius=min(1,HUD_points[i][0][1]/0.65)
			icons[i][0].position=Vector2(screen_dimensions/2)+((point_radius*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i][0][0]))
			if point_radius<1:
				icons[i][0].set_type("hollow")
			if HUD_points[i][1]==null:
				icons[i][0].set_colour("#00f")
			add_child(icons[i][0])
			
			if HUD_points[i][1]:
				if HUD_points[i][1][1]<0.65:
					icons[i].append(icon_scene.instantiate())
					icons[i][1].position=Vector2(screen_dimensions/2)+(((HUD_points[i][1][1]/0.65)*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i][1][0]))
					icons[i][1].set_type("ahead")
					add_child(icons[i][1])
				
				if HUD_points[i][0][1]<0.3 && (HUD_points[i][0][2]-guy.position).length()<50:
					if mindex==null || HUD_points[i][0][1]<smallest_forward_angle:
						smallest_forward_angle=HUD_points[i][0][1]
						mindex=i
		if mindex!=null:
			icons[mindex][0].set_type("locked")

func flash(amount):
	if $Pain.color.a<1:
		$Pain.color.a+=amount

extends Control
var screen_dimensions
var icon_scene=preload("res://icon.tscn")
var icons=[]
var missilecons=[]
var guy

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"))
	# crosshairs

func _ready():
	guy=get_node("/root/Main/Player")
	screen_dimensions=get_node("/root").size
	$Endgame.hide()

func _process(delta):
	var HUD_points=guy.HUD_points
	if guy.health==0:
		$StatusLabel.text=""
	else:
		$StatusLabel.text="Health: %s\nMissiles: %s" %[guy.health,guy.missiles]
	
	for missilecon in missilecons:
		missilecon.queue_free()
	missilecons=[]
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
	
	for entity in icons:
		for icon in entity:
			icon.queue_free()
	icons=[]
	var mindex=null
	var closest_point_dist=null
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
			
			var point_dist=(HUD_points[i][0][2]-guy.position).length()
			if HUD_points[i][0][1]<0.3 && point_dist<50:
				if not mindex || point_dist<closest_point_dist:
					closest_point_dist=point_dist
					mindex=i
	if mindex:
		icons[mindex][0].set_type("locked")

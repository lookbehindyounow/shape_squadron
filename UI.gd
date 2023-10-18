extends Control
var screen_dimensions
var icon_scene=preload("res://icon.tscn")
var icons=[]
var missilecons=[]
var guy
var missile=null

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"))
	var crosshair_points=[5*Vector2.UP,15*Vector2.UP,5*Vector2.DOWN,15*Vector2.DOWN,5*Vector2.LEFT,15*Vector2.LEFT,5*Vector2.RIGHT,15*Vector2.RIGHT]
	for i in range(8):
		crosshair_points[i]+=screen_dimensions/2.0
	draw_multiline(crosshair_points,Color("#0f0"))

func _ready():
	guy=get_node("/root/Main/Player")
	screen_dimensions=get_node("/root").size
	$Endgame.hide()

func _process(delta):
	if $Pain.color.a>0:
		$Pain.color.a-=delta/2
	
	if missile || guy.health==0:
		$StatusLabel.text=""
	else:
		$StatusLabel.text="Health: %s\nMissiles: %s\nSpeed: %s\nAltitude: %s" %[guy.health,guy.missiles,round(guy.speed*10)/10,round(guy.transform.origin.y*10)/10]
	
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

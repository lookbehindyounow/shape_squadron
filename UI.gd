extends Control
var screen_dimensions
var enemy_icon_scene=preload("res://enemy_icon.tscn")
var enemy_ahead_icon_scene=preload("res://enemy_ahead_icon.tscn")
var enemies=[]
var enemy_icons=[]

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"))

func _ready():
	screen_dimensions=get_node("/root").size
	
func _on_main_enemies_changed():
	enemies=get_node("/root/Main").enemies
	enemy_icons=[]
	for i in range(enemies.size()):
		enemy_icons.append([enemy_icon_scene.instantiate(),enemy_ahead_icon_scene.instantiate()])
		add_child(enemy_icons[i][0])
		add_child(enemy_icons[i][1])

func _process(delta):
	var HUD_points=[]
	var camera=get_node("/root/Main").current_camera
	if camera==-1:
		HUD_points=get_node("/root/Main/Player").HUD_points
	else:
		HUD_points=enemies[camera].HUD_points
	for i in range(HUD_points.size()):
		# angle between top of HUD circle & forward is 0.65
		var point_radius=min(1,HUD_points[i][0][1]/0.65)
		enemy_icons[i][0].position=Vector2(screen_dimensions/2)+((point_radius*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i][0][0]))
		if HUD_points[i][1][1]<0.65:
			enemy_icons[i][1].position=Vector2(screen_dimensions/2)+(((HUD_points[i][1][1]/0.65)*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i][1][0]))
			enemy_icons[i][1].show()
		else:
			enemy_icons[i][1].hide()

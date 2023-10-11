extends Control
var screen_dimensions
var enemy_icon_scene=preload("res://enemy_icon.tscn")
var enemy_ahead_icon_scene=preload("res://enemy_ahead_icon.tscn")
var enemy_icon
var enemy_ahead_icon
var enemy_camera=false
var watcher="Player"

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"))

func _ready():
	screen_dimensions=get_node("/root").size
	enemy_icon=enemy_icon_scene.instantiate()
	enemy_ahead_icon=enemy_ahead_icon_scene.instantiate()
	add_child(enemy_icon)
	add_child(enemy_ahead_icon)

func _process(delta):
	if enemy_camera:
		watcher="Enemy"
	else:
		watcher="Player"
	var HUD_points=get_node("/root/Main/%s" %watcher).HUD_points
	for i in range(HUD_points.size()):
		# angle between top of HUD circle & forward is 0.65
		var point_radius=min(1,HUD_points[i][0][1]/0.65)
		enemy_icon.position=Vector2(screen_dimensions/2)+((point_radius*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i][0][0]))
		if HUD_points[i][1][1]<0.65:
			enemy_ahead_icon.show()
			enemy_ahead_icon.position=Vector2(screen_dimensions/2)+(((HUD_points[i][1][1]/0.65)*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i][1][0]))
		else:
			enemy_ahead_icon.hide()

func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_camera") && event.pressed:
		enemy_camera=not enemy_camera

func _on_hit():
	$ScoreLabel.text="Hits: %d\nEnemy's hits: %d\nCrashes: %d\nEnemy's crashes: %d" %[get_node("/root/Main/Enemy").hits_taken,
	get_node("/root/Main/Player").hits_taken,get_node("/root/Main/Player").crashes,get_node("/root/Main/Enemy").crashes]

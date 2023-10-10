extends Control
var screen_dimensions
var enemy_icon_scene=preload("res://enemy_icon.tscn")
var enemy_icon
var enemy_camera=false
var watcher="Player"

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"),-1)

func _ready():
	screen_dimensions=get_node("/root").size
	enemy_icon=enemy_icon_scene.instantiate()
	add_child(enemy_icon)

func _process(delta):
	var HUD_angle
	if enemy_camera:
		watcher="Enemy"
	else:
		watcher="Player"
	HUD_angle=get_node("/root/Main/%s" %watcher).target_o_clock
	enemy_icon.position=Vector2(screen_dimensions/2)+((screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_angle))

func _unhandled_input(event):
	if InputMap.event_is_action(event,"switch_camera") && event.pressed:
		enemy_camera=not enemy_camera

func _on_hit():
	$ScoreLabel.text="Hits: %d\nEnemy's hits: %d\nCrashes: %d\nEnemy's crashes: %d" %[get_node("/root/Main/Enemy").hits_taken,
	get_node("/root/Main/Player").hits_taken,get_node("/root/Main/Player").crashes,get_node("/root/Main/Enemy").crashes]

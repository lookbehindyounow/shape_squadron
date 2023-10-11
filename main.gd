extends Node

var enemy_scene=preload("res://enemy.tscn")
var bullet_scene=preload("res://bullet.tscn")
var enemies=[]
var current_camera=-1

func _ready():
	var initial_enemy_count=5
	$Player/Camera3D.current=true
	for i in range(initial_enemy_count):
		enemies.append(enemy_scene.instantiate())
		enemies[i].transform.origin=Vector3(0,6,5)
		enemies[i].transform=enemies[i].transform.rotated(Vector3.UP,(1.0*i)/(initial_enemy_count-1)*PI/2)
		add_child(enemies[i])

func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_camera") && event.pressed:
		current_camera+=1
		if current_camera==enemies.size():
			$Player/Camera3D.current=true
			current_camera=-1
		else:
			enemies[current_camera].get_node("Camera3D").current=true

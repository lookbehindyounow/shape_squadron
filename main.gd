extends Node

var enemy_scene=preload("res://enemy.tscn")
var bullet_scene=preload("res://bullet.tscn")
var enemies=[]
var initial_enemy_count=5
var current_camera=-1
var gaming=true

func _ready():
	for i in range(initial_enemy_count):
		enemies.append(enemy_scene.instantiate())
		enemies[i].transform.origin=Vector3(0,6,5)
		enemies[i].transform=enemies[i].transform.rotated(Vector3.UP,(1.0+i)/(initial_enemy_count+1)*PI/2)
		add_child(enemies[i])
	current_camera=initial_enemy_count-1
	update_camera()

func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_camera") && event.pressed:
		update_camera()

func _on_enemy_die(dead):
	for i in range(enemies.size()):
		if enemies[i]==dead:
			enemies.remove_at(i)
			if current_camera>=i:
				current_camera-=1
				if current_camera==i-1:
					update_camera()
			break
	dead.queue_free()
	
	if enemies.size()==0:
		$UI/Endgame.text="Those triangles had families"
		$UI/Endgame.show()

func update_camera():
	current_camera+=1
	var guy
	if current_camera>=enemies.size():
		guy=$Player
		current_camera=-1
	else:
		guy=enemies[current_camera]
	guy.get_node("Camera3D").current=true
	$UI.guy=guy
	if not gaming && current_camera==-1:
		$UI/StatusLabel.text=""

func _on_restart_pressed():
	get_tree().reload_current_scene()

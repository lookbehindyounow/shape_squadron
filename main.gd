extends Node

var bullet_scene=preload("res://bullet.tscn")

func _ready():
	$Player/Camera3D.current==true

func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_camera") && event.pressed:
		$Player/Camera3D.current=$Enemy/Camera3D.current

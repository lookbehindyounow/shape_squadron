extends Control

func _draw():
	draw_arc(Vector2.ZERO,15,0,TAU,9,Color("#f00"))
	draw_multiline([Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT],Color("#f00"))

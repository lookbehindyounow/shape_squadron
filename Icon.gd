extends Control
var type="full"
var colour=Color("#f00")

func _draw():
	if type=="full":
		draw_circle(Vector2.ZERO,10,colour)
	elif type=="hollow":
		draw_arc(Vector2.ZERO,10,0,TAU,13,colour)
	elif type=="ahead":
		draw_arc(Vector2.ZERO,15,0,TAU,9,colour,2)
		draw_multiline([6*Vector2.UP,18*Vector2.UP,6*Vector2.DOWN,18*Vector2.DOWN,6*Vector2.LEFT,18*Vector2.LEFT,6*Vector2.RIGHT,18*Vector2.RIGHT],colour,2)

func set_type(_type):
	type=_type
	queue_redraw()

func set_colour(_colour):
	colour=Color(_colour)
	queue_redraw()

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
	elif type=="locked":
		draw_arc(Vector2.ZERO,10,0,TAU,13,colour)
		var arrow=[Vector2(15,15),Vector2(30,20),Vector2(20,20),Vector2(20,30)]
		for i in range(4):
			for j in range(4):
				arrow[j]=arrow[j].rotated(PI/2)
			draw_colored_polygon(arrow,colour)
	elif type=="missile":
		draw_arc(Vector2.ZERO,15,0,TAU,13,colour,3)
		draw_multiline([Vector2(9,9),Vector2(-9,-9),Vector2(9,-9),Vector2(-9,9)],colour,3)

func set_type(_type):
	type=_type
	queue_redraw()

func set_colour(_colour):
	colour=Color(_colour)
	queue_redraw()

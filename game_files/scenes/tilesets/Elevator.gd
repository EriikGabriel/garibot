extends "MovePlat.gd"

@export var open: Texture2D
@export var closed: Texture2D

func _ready():
	set_activated(false)
	distancing = false

func set_activated(_open):
	if _open:
		$Sprite2D.texture = open
	else:
		$Sprite2D.texture = closed
	
	DJ.play_sfx("gate_open")
	super.set_activated(_open)
	
func invert_direction():
	set_activated(false)

func set_direction():
	super.invert_direction()
	set_activated(true)

func _on_Area2D_body_entered(body):
	print_debug(str(body.position.y) + " " + str(self.position.y))
	
	if body.position.y > self.position.y + 60:
		set_direction()
	else:
		body_array.append(body)

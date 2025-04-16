extends KinematicBody2D

# Declare member variables here. Examples:
var angle = 10.0
var curve = 120.0
var speed = 100.0
var vec = Vector2.UP
var orientation = 1.0
var pos = Vector2(0,0)
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(true)
	add_to_group("Shoot")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	weirdShot(delta)
	pass

func weirdShot(delta):
	vec = vec.rotated(-angle * orientation * delta)
	move_and_slide(vec*curve)
	move_and_slide(pos * speed)
	pass

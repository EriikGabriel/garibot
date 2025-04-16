extends KinematicBody2D

# Declare member variables here. Examples:
var angle = 10.0
var curve = 120.0
var speed = 10.0
var vec = Vector2.UP
var orientation = 1.0
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(true)
	add_to_group("shoot")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	commonShot(delta)
	
	pass

func commonShot(_delta):
	var _collision = move_and_collide(Vector2.RIGHT * orientation * speed)
	if not _collision == null :
		if _collision.collider.is_in_group("player"):
			_collision.collider.recieve_damage(1)
		self.destroy()
	pass

func weirdShot(delta):
	vec = vec.rotated(-angle * orientation * delta)
	var _collision = move_and_slide(vec*curve)
	_collision = move_and_slide(Vector2.RIGHT * orientation * speed)
	pass

func _on_DamageArea_body_entered(_body):
#	if body.is_in_group("player"):
#		body.recieve_damage(1)
#	print(not body.is_in_group("shoot"))
#	if not body.is_in_group("shoot") :
#		self.destroy()
	pass

func destroy():
	self.queue_free()

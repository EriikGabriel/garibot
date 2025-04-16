extends TouchScreenButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_roll_attack_pressed():
	Input.action_press("roll_attack")
	pass # Replace with function body.


func _on_roll_attack_released():
	Input.action_release("roll_attack")
	pass # Replace with function body.

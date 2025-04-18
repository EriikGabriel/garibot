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


func _on_right_pressed():
	var a = InputEventAction.new()
	a.action = "ui_right"
	a.button_pressed = true
	Input.parse_input_event(a)

	pass # Replace with function body.


func _on_right_released():
	Input.action_release("ui_right")
	pass # Replace with function body.

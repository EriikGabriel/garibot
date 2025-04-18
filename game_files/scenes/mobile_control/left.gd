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


func _on_left_released():
	Input.action_release("ui_left")
	pass # Replace with function body.


func _on_left_pressed():
	var a = InputEventAction.new()
	a.action = "ui_left"
	a.button_pressed = true
	Input.parse_input_event(a)
	pass # Replace with function body.

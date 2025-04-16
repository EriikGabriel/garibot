extends TouchScreenButton


func _on_TouchScreenButton_Space_pressed():
	
	var ev = InputEventAction.new()

	ev.action = "ui_accept"
	ev.pressed = true
	Input.parse_input_event(ev)
	
	pass # Replace with function body.


func _on_TouchScreenButton_accept_released():
		
	var ev = InputEventAction.new()

	ev.action = "ui_accept"
	ev.pressed = false
	Input.parse_input_event(ev)
	
	pass # Replace with function body.

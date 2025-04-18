extends TouchScreenButton


func _on_TouchScreenButton_X_pressed():
	print("test")
	var ev = InputEventAction.new()

	ev.action = "ui_blaster"
	ev.button_pressed = true
	Input.parse_input_event(ev)
	
	pass # Replace with function body.



func _on_TouchScreenButton_X_released():
	print("test")
	var ev = InputEventAction.new()

	ev.action = "ui_blaster"
	ev.button_pressed = false
	Input.parse_input_event(ev)
	
	pass # Replace with function body.

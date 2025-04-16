extends TouchScreenButton

export var default_position: Vector2
export var bonus_stage_position: Vector2

func set_bonus_stage_position():
	self.set_position(bonus_stage_position)

func reset_default_position():
	self.set_position(default_position)

func _on_Pause_pressed():
	var a = InputEventAction.new()
	a.action = "ui_pause"
	a.pressed = true
	Input.parse_input_event(a)
	pass # Replace with function body.


func _on_Pause_released():
	Input.action_release("ui_pause")
	pass # Replace with function body.


func _on_Button_pressed():
	_on_Pause_pressed()

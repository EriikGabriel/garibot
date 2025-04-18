extends Button

const key_shortcut = "ui_accept"

@export var go_to_credits = false

func _unhandled_input(_event):
	if Input.is_action_just_released(key_shortcut):
		_pressed()

func _pressed():
	if !(self.is_visible_in_tree() and $Timer.is_stopped()):
		return
	
	self.get_tree().paused = false
	
	if go_to_credits:
		Global_variable.mobile_control_node.set_default_controls()
		StageManager.change_stage("credits")
		return
	
	var item = get_node("/root/Global_variable").get_name_item_collect()
	if item.size() == 0:
		Global_variable.mobile_control_node.set_default_controls()
		StageManager.change_stage("world_map")
	else:
		Global_variable.mobile_control_node.set_bonus_controls()
		StageManager.change_stage("bonus")

func _on_level_complete_visibility_changed():
	self.get_tree().paused = self.visible
	$Timer.start()

func _on_Timer_timeout():
	self.disabled = not self.visible
	#print_debug("Disabled ", str(self.disabled))


func _on_LevelCompleteButton_button_down():
	_pressed()

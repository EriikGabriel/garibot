extends Button

const key_shortcut = "ui_accept"

func _unhandled_input(_event):
	if Input.is_action_just_released(key_shortcut) and self.is_visible_in_tree() and $Timer.is_stopped():
		_pressed()

func _pressed():
	self.get_tree().paused = false
	StageManager.change_stage("world_map")

func _on_level_complete_visibility_changed():
	Global_variable.mobile_control_node.hide_pause_button()
	self.get_tree().paused = self.visible
	$Timer.start()

func _on_Timer_timeout():
	Global_variable.mobile_control_node.set_default_controls()
	self.disabled = not self.visible

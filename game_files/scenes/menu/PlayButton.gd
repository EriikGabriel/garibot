extends Button

const key_shortcut = "ui_accept"
const next_stage = "story"

signal if_button_pressed

func _unhandled_input(_event):
	if Input.is_action_just_released(key_shortcut) and self.is_visible_in_tree():
		_pressed()

func _pressed():
	emit_signal("if_button_pressed")
	#self.get_parent().get_parent().get_parent().get_parent().change_stage(next_stage)

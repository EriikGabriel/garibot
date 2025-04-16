extends Button

export (String) var texto = "TEXTO"
export var key_shortcut = "ui_accept"

func _unhandled_input(_event):
	if Input.is_action_just_released(key_shortcut) and self.is_visible_in_tree():
		emit_signal("pressed")


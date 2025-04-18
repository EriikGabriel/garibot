extends Button

@export var texto: String = "TEXTO"
const key_shortcut = "ui_accept"

signal was_pressed

func _unhandled_input(_event):
	if Input.is_action_just_released(key_shortcut) and self.is_visible_in_tree():
		emit_signal("was_pressed")


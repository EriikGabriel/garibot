extends TextureRect

onready var max_value = get_tree().get_nodes_in_group("value_bar").front().max_value

func _ready():
	self.set_texture(load("res://assets/Images/UI/Misc/cogIcon.png"))

func mission_complete():
	self.set_texture(load("res://assets/Images/check.png"))

func _on_TextureProgress_value_changed(value):
	if value == max_value:
		mission_complete()

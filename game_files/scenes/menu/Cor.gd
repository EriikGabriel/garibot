extends HBoxContainer

onready var player = get_tree().get_nodes_in_group("player").front()

func _ready():
	pass

func change_color(idx : int):
	if player.get_node("PlayerBody").change_skin(idx):
		return

func button_toggle( button_idx : int):
	var buttons = self.get_children().slice(1,3)

	if button_idx >= 0 and button_idx < 3:
		for i in range(3):
			if i != button_idx :
				buttons[i].set_disabled(false)
				buttons[i].set_pressed(false)
			else :
				buttons[i].set_pressed(true)
				buttons[i].set_disabled(true)
	
	change_color(button_idx)



func _on_TextureButton_pressed():
	button_toggle(0)


func _on_TextureButton2_pressed():
	button_toggle(1)


func _on_TextureButton3_pressed():
	button_toggle(2)

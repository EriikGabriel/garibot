extends Control

export(Texture) var full_star
enum TYPE {BASIC, BONUS}
export(TYPE) var type

onready var star_2 = $Panel/Pontos/HBoxContainer/VBoxContainer/HBoxContainer/Star2
onready var star_3 = $Panel/Pontos/HBoxContainer/VBoxContainer/HBoxContainer/Star3

func set_score():
	Global_variable.mobile_control_node.hide_pause_button()
	if type == TYPE.BASIC:
		DJ.play("win_fanfare")
	else:
		DJ.play("bonus_win_fanfare")
	$Panel/Pontos.set_visible(true)
	var total = get_tree().get_nodes_in_group("value_bar").front().max_value
	var value = get_tree().get_nodes_in_group("value_bar").front().value
	if value/total > 0.5:
		star_2.texture = full_star
		if value/total > 0.9:
			star_3.texture = full_star
	
	#$Panel/Pontos/Pontuacao2.set_text(str(value)+"/"+str(total))



func _on_LevelCompleteButton_pressed():
	pass # Replace with function body.


func hide_stars():
	if type == TYPE.BASIC:
		DJ.play("win_fanfare")
	else:
		DJ.play("bonus_win_fanfare")
	$Panel/Pontos/HBoxContainer/VBoxContainer.hide()


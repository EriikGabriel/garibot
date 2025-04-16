extends Node2D

export var color_hair_array: Array
export var color_shirt_array: Array
var shirt_color: Color
var hair_color: Color

export var cabeca : NodePath
onready var cabeca_node = get_node(cabeca)

func update_colors():
	material.set_shader_param("new_color", shirt_color)
	cabeca_node.material.set_shader_param("new_color", hair_color)


func select_random_color():
	randomize()
	if color_shirt_array.size() > 0 and color_hair_array.size():
		shirt_color = color_shirt_array[randi() % color_shirt_array.size()]
		hair_color = color_hair_array[randi() % color_hair_array.size()]
		shirt_color = shirt_color
		hair_color = hair_color
		update_colors()

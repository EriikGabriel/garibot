extends Node2D
onready var value_bar = get_tree().get_nodes_in_group("value_bar").front()
onready var maxvalue = 0
onready var arvores_anim = $AnimationPlayer

var nivel = 0

func _ready():
	nivel = 0
	arvores_anim.play("inicio")
	value_bar.connect("value_changed", self, "_on_Bar_value_changed")
	value_bar.connect("changed", self, "_on_Bar_changed")

func _on_Bar_changed():
	maxvalue = value_bar.max_value

func _on_Bar_value_changed(value : float):
	if value < maxvalue * 0.25: 
		if nivel == 0:
			nivel = 1
			arvores_anim.play("nivel1")
			return
	elif value < maxvalue * 0.5:
		if nivel == 1:
			nivel = 2
			arvores_anim.play("nivel2")
			return
	elif value < maxvalue * 0.75:
		if nivel == 2:
			nivel = 3
			arvores_anim.play("nivel3")
			return
	elif value == maxvalue:
		if nivel == 3:
			nivel = 4

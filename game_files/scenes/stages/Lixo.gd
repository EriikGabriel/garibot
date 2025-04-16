extends Sprite
onready var value_bar = get_tree().get_nodes_in_group("value_bar").front()
onready var maxvalue = 0
onready var arvores_anim = get_tree().get_nodes_in_group("arvore_anim").front()


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
			self.set_texture(load("res://assets/Images/Scenery/fundo2.2.png"))
			nivel = 1
			return
	elif value < maxvalue * 0.5:
		if nivel == 1:
			self.set_texture(load("res://assets/Images/Scenery/fundo2.1.png"))
			nivel = 2
			arvores_anim.play("nivel1")
			return
	elif value < maxvalue * 0.75:
		if nivel == 2:
			self.set_texture(load("res://assets/Images/Scenery/fundo2.0.png"))
			nivel = 3
			arvores_anim.play("nivel2")
			return
	elif value == maxvalue:
		if nivel == 3:
			self.set_visible(false)
			arvores_anim.play("nivel3")
			nivel = 4



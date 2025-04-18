extends TextureButton

@export var gate : NodePath
@export var galeria : NodePath
@export var dialogo : NodePath
@export var minigame : NodePath
@onready var gate_node = get_node_or_null(gate)
@onready var galeria_node = get_node(galeria)
@onready var dialogo_node = get_node(dialogo)
@onready var minigame_node = get_node(minigame)

func _on_USeItem_pressed():
	gate_node.open()
	galeria_node.close_gallery()
	galeria_node._close_info()
	minigame_node.set_correct_sprite(galeria_node.get_node("Panel/Info/HBoxContainer/VBoxContainer/Imagem").texture,galeria_node.get_node("Panel/Info/HBoxContainer/VBoxContainer/Nome").text)
	dialogo_node.monitoring = false 
	pass # Replace with function body.


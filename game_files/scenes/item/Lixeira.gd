extends Area2D
 
var float_amount
var float_direction = 1

var type = ["Amarelo","Azul","Marrom","Verde","Vermelho"]

signal changed_item

var textures = {
	"Amarelo" : load("res://assets/Images/Lixeira/lixeira_amarela.png"),
	"Azul" : load("res://assets/Images/Lixeira/lixeira_azul.png"),
	"Marrom" : load("res://assets/Images/Lixeira/lixeira_marrom.png"),
	"Verde": load("res://assets/Images/Lixeira/lixeira_verde.png"),
	"Vermelho" : load("res://assets/Images/Lixeira/lixeira_vermelha.png")
}


func _ready():
	change_item(type[0],0)
	add_to_group("lixeira")


func change_item( var name : String , typevar):
	if textures.has(name):
		$Sprite.set_texture(textures.get(name))
		emit_signal("changed_item", name)
		#get_parent().get_parent().get_node("CanvasLayer/GameUI/MarginContainer/HBoxContainer/CenterContainer3/MarginContainer2/TextureRect").set_texture(textures.get(name))
		#get_parent().get_parent().get_node("CanvasLayer/GameUI/MarginContainer/HBoxContainer/Label").set_text(texts.get(name))
		var count = 0
		for nametype in type :
			if nametype == name :
				typevar = count
				count +=1
		return typevar


func button_change(dir, typevar):
	typevar += dir
	
	if typevar >= len(type):
		typevar = 0
	if typevar < 0 :
		typevar = len(type)-1
	
	change_item(type[typevar], typevar)
	return typevar


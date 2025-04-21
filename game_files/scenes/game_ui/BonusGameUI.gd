extends Control

var texts = {
	"Amarelo" : tr("DOG_METAL"),
	"Azul" : tr("DOG_PAPER"),
	"Marrom" : tr("DOG_ORGANIC"),
	"Verde": tr("DOG_GLASS"),
	"Vermelho" : tr("DOG_PLASTIC"),
}


func _ready():
	for cor in texts.keys():
		get_node("Trashbins/" + cor + "/" + cor + "/Label").text = texts[cor]


func _on_Player_changed_item(new_item):
	for cor in texts.keys():
		if cor == new_item:
			get_node("Trashbins/" + cor + "/" + cor).set_modulate(Color(1, 1, 1, 1))
			get_node("Trashbins/" + cor).self_modulate.a = 1.0
		else:
			get_node("Trashbins/" + cor + "/" + cor).set_modulate(Color(1, 1, 1, 0.5))
			get_node("Trashbins/" + cor).self_modulate.a = 0.0

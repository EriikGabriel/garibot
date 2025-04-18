extends Button

@export var item: String = "impressora"

@onready var sprite = $Residuo_popup/HBoxContainer2/VBoxContainer2/CenterContainer/Sprite2D
@onready var item_name = $Residuo_popup/HBoxContainer2/VBoxContainer2/Name
@onready var blaster_name = $Residuo_popup/HBoxContainer2/VBoxContainer/HBoxContainer/BlasterName
@onready var blaster_texture = $Residuo_popup/HBoxContainer2/VBoxContainer/HBoxContainer/CenterContainer/BlasterTexture
@onready var description = $Residuo_popup/HBoxContainer2/VBoxContainer/Description


func _pressed():
	self.get_node("Residuo_popup").popup_centered()
	update_text(item)

	self.icon = ItemTextureMap.textures.get(name)
	
func set_item(name : String):
	item = name
	sprite.texture = self.icon
	item_name.text = name.to_upper()
	
	if ItemTextureMap.items.get(name).type == "REEE":
		blaster_name.text = """Pode ser usado para fazer\n as Engenhocas Recicladas """
		blaster_name.show()
		blaster_texture.show()
	else:
		blaster_name.hide()
		blaster_texture.hide()

func update_text(name):
	description.text = """\nQuantidade: """ + str(ItemTextureMap.count[name]) + """\nDescrição:\n""" + ItemTextureMap.descriptions.get(name)

func _ready():
	set_item(item)

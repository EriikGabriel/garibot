extends Control

var was_tree_paused : bool = false

@onready var item_list = $Panel/VBoxContainer/CenterContainer/ItemList
@onready var item_info_name = $Panel/Info/HBoxContainer/VBoxContainer/Nome
@onready var item_info_texture = $Panel/Info/HBoxContainer/VBoxContainer/Imagem
@onready var item_info_desc = $"Panel/Info/HBoxContainer/VBoxContainer2/Descrição"
@onready var item_info_blaster = $Panel/Info/HBoxContainer/VBoxContainer2/BlasterInfo
@onready var item_info_qtd = $Panel/Info/HBoxContainer/VBoxContainer/Qtd
@onready var item_info_sep = $Panel/Info/HBoxContainer/VBoxContainer2/HSeparator
@onready var info_panel = $Panel/Info
@export var flag = false
@export var item_qtd_min = 4

@export var useItemButton : NodePath
@onready var useItem_node = get_node(useItemButton)


func _ready():
	for item in ItemTextureMap.items.values():
		if item.recyclabe: item_list.add_item(tr(item.name), item.texture)


func _on_ItemList_item_selected(index):
	# Litte hack to make microwave work :)
	# PS: Can be fixed later
	index = index if index < 3 else 7
	
	_update_info(index)
	_open_info()
	
	DJ.play_sfx("ui_move")


func _update_info(i : int):
	var item = ItemTextureMap.items.values()[i]
	useItem_node.visible= false
	item_info_name.set_text(item.name)
	item_info_desc.set_text(item.description)
	item_info_texture.set_texture(item.texture)
	if item.blaster != "":
		useItem_node.visible = true
		item_info_blaster.set_text("Pode ser usado para construir a " + tr("BLASTER") + " " + item.blaster)
		if flag:
			item_info_qtd.set_text(str(item.count) + " coletados\n" + str(item_qtd_min) + " necessários")
			calculate_item(item)
	else :
		item_info_qtd.set_text(str(item.count) + " coletados")
	item_info_blaster.set_text("")
	item_info_sep.set_visible(item.blaster != "")

func open_gallery():
	self.visible = true
	was_tree_paused = self.get_tree().paused
	self.get_tree().paused = true


func close_gallery():
	self.get_tree().paused = was_tree_paused
	self.hide()
	
	DJ.play_sfx("ui_deselect")


func _open_info():
	info_panel.show()


func _close_info():
	info_panel.hide()
	
	DJ.play_sfx("ui_deselect")

func calculate_item(item):
	if item_qtd_min > item.count :
		$Panel/Info/HBoxContainer/VBoxContainer/HBoxContainer/USeItem.disabled = true
	else :
		$Panel/Info/HBoxContainer/VBoxContainer/HBoxContainer/USeItem.disabled = false

func _on_VoltarInfo_pressed():
	_close_info()


func _on_VoltarGaleria_pressed():
	close_gallery()

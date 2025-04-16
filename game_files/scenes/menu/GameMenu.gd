extends Control

export var gallery_path : NodePath = "../Galeria" 
onready var node_gallery = get_node(gallery_path)

onready var node_cores = $HBoxContainer/ConfigPanel/VBoxContainer/HBoxContainer2/Cores
onready var node_stageManager = StageManager
onready var slider = $HBoxContainer/ConfigPanel/VBoxContainer/HBoxContainer/HSlider
onready var controles_button_node = $HBoxContainer/ConfigPanel/VBoxContainer/CenterContainer/Controles

signal garibot_Color(idx)

func _ready():
	node_cores.select(0)
	if Global_variable.mobile_control_node:
		Global_variable.mobile_control_node.show_pause_button()
		controles_button_node.pressed = Global_variable.mobile_control_node.buttons_visibile()

#Abre o menu de pause
func open_pause_menu():
	self.visible = true
	self.get_tree().paused = true
	slider.set_value(db2linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))))
	
	DJ.play_sfx("ui_select")


#Fecha o menu de pause
func close_pause_menu():
	self.visible = false
	self.get_tree().paused = false
	
	DJ.play_sfx("ui_deselect")

#Acionado ao pressionar o botão de Voltar
func _on_Voltar_pressed():
	close_pause_menu()
	pass 

#Acionado ao pressionar o botão de Galeria
func _on_Galeria_pressed():
	node_gallery.open_gallery()
	
	DJ.play_sfx("ui_select")
	pass 

#Acionado ao pressionar o botão de Sair
func _on_Sair_pressed():
	#Retorna para o menu principal
	close_pause_menu()
	StageManager.change_stage("main_menu")
	
	DJ.play_sfx("ui_deselect")

#Acionado ao mudar o volume do jogo
func _on_HSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(value))
	pass 

#Acionado ao trocar a cor do garibot
func _on_Cores_item_selected(index):
	#Envia um sinal para o player
	emit_signal("garibot_Color",index)
	
	DJ.play_sfx("ui_select")
	pass 


func _on_Mapa_pressed():
	self.get_tree().paused = false
	StageManager.change_stage("world_map")
	
	DJ.play_sfx("ui_deselect")


func _on_Controles_toggled(button_pressed):
	if button_pressed:
		Global_variable.mobile_control_node.show_buttons()
	else:
		Global_variable.mobile_control_node.hide_buttons()
	Global_variable.mobile_control_flag = button_pressed

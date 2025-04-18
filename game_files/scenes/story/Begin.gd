extends Node2D

@onready var espaco = $CanvasLayer/Espaco
@onready var mobile_button = $CanvasLayer/Espaco/Mobile_button

func _ready():
	_show_mobile_button()


func next_scene():
	StageManager.change_stage("tutorial")


func _process(delta):
	skip_anim_control(delta)


func skip_anim_control(_delta) :
	if Input.is_action_just_pressed("ui_accept"):
		next_scene()


func _show_mobile_button():
	if Global_variable.mobile_control_node.buttons_visibile():
		espaco.set_text("PRESSIONE      PARA PULAR A HISTÓRIA")
		mobile_button.visible = true

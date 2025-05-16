extends Control

var stage = 0
var position_ = 1
var right_position = 1
var input_enabled : bool = true
var key_cd = 0
var shown_item_names = ["", "", ""]
var electronic_names = ["celular", "monitor", "tv",
"impressora", "furadeira", "fogao", "geladeira", "microondas", "radio", "bateria"]

@export var electronic_list = []
@export var organic_list = []

@export var right : Color
@export var wrong : Color

@onready var panel2_node = $Panel2
@onready var panel2_texto_node = $Panel2/VBoxContainer/Texto
@onready var panel2_textura_node = $Panel2/VBoxContainer/TextureRect
@onready var happy_texture = preload("res://assets/Images/Stage Elements/happy_emoji.png")
@onready var thinking_texture = preload("res://assets/Images/Stage Elements/emoji_think.png")

signal minigame_done


# Called when the node enters the scene tree for the first time.
func _ready():
	changed_button()
	pass

func _process(delta):
	if input_enabled:
		if key_cd <= 0:
			if Input.is_action_pressed("ui_left"):
				_on_left_button_up()
				key_cd = 0.15
			elif Input.is_action_pressed("ui_right"):
				_on_right_button_up()
				key_cd = 0.15
			elif Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_select"):
				_on_BotaoOK_button_up()
				key_cd = 0.3
		else:
			key_cd -= delta
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
		_on_Timer_timeout()


func change_items():
	right_position = randi() % 3
	for i in range(3):
		var item
		if i == right_position:
			item = electronic_list[randi() % electronic_list.size()]
		else:
			item = organic_list[randi() % organic_list.size()]
		
		opcao_node(i).texture = item[1]
		shown_item_names[i] = item[0]
		changed_button()


func changed_button():
	var alpha
	for i in range(3):
		if i == position_:
			alpha = 1
			$Panel/VBoxContainer/NomeDaOpcao.text = shown_item_names[i]
		else:
			alpha = 0.25
		opcao_node(i).set_modulate(Color(1, 1, 1, alpha))


func _on_left_button_up():
	if position_ > 0:
		position_ -= 1
	changed_button()


func _on_right_button_up():
	if position_ < 2:
		position_ += 1
	changed_button()


func _on_BotaoOK_button_up():
	if position_ == right_position:
		stage += 1
		_show_message_right($Panel/VBoxContainer/NomeDaOpcao.text)
		
	else:
		_show_message_wrong($Panel/VBoxContainer/NomeDaOpcao.text)
	change_items()


func opcao_node(i):
	return find_child("Opcao" + str(i), true, true).get_child(0)


func setup_items(item_list):
	for item in item_list.keys():
		if electronic_names.has(item[0]):
			add_to_electronics([item[0], item[1]])
		else:
			add_to_organics([item[0], item[1]])
			
	change_items()
	#changed_button()


func add_to_electronics(new):
	electronic_list.append(new)


func add_to_organics(new):
	organic_list.append(new)

func _show_message_right(nome):
	panel2_texto_node.text = 'Isso mesmo! \n' + nome + ' é eletroeletrônico!'
	
	match stage:
		1: DJ.play_sfx("right_answer_1")
		2: DJ.play_sfx("right_answer_2")
		3: DJ.play_sfx("right_answer_3")
	
	panel2_node.self_modulate = right
	panel2_textura_node.set_texture(happy_texture)
	input_enabled = false
	panel2_node.show()
	$Timer.start()

func _show_message_wrong(nome):
	panel2_texto_node.text = 'Essa não! \n' + nome + ' não é eletroeletrônico!'
	
	DJ.play_sfx("wrong_answer")
	
	panel2_node.self_modulate = wrong
	panel2_textura_node.set_texture(thinking_texture)
	input_enabled = false 
	panel2_node.show()
	$Timer.start()

func _on_Timer_timeout():
	panel2_node.hide()
	input_enabled = true
	
	if stage >= 3:
			emit_signal("minigame_done")
			queue_free()


func _on_Button_button_up():
	position_ = 0
	changed_button()
	_on_BotaoOK_button_up()
	DJ.play_sfx("ui_move")


func _on_Button2_button_up():
	position_ = 1
	changed_button()
	_on_BotaoOK_button_up()
	DJ.play_sfx("ui_move")

func _on_Button3_button_up():
	position_ = 2
	changed_button()
	_on_BotaoOK_button_up()
	DJ.play_sfx("ui_move")

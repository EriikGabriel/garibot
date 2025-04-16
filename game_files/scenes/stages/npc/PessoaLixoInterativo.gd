extends Node2D

var actual_state
var can_interact = false
onready var value_bar = get_tree().get_nodes_in_group("value_bar").front()
var enemypreload = preload("res://scenes/enemies/Enemy2.tscn")
export (int, 1,5) var qtditem = 0 #item q é ser coletado
export (int,0,2) var modo_converter = 0 # 0 Pessoas seguindo
#1 Sim
#2 Não
export var min_pessoas = 2
var vel = Vector2(0,0)

export(String, "boy", "woman", "girl") var person_type = "boy"

export var color_hair_array: Array
export var color_shirt_array: Array
var shirt_color: Color
var hair_color: Color

export var person: NodePath
onready var person_node := get_node(person)

#export var reaction: NodePath
onready var reaction_node := person_node.get_node("Reaction")

export var body_anim_player: NodePath
onready var body_anim_player_node := get_node(body_anim_player)

export var moscas_anim_player: NodePath
onready var moscas_anim_player_node := get_node(moscas_anim_player)


var garibot_followers

enum STATE{
	VERDE,
	AMARELO,
	VERMELHO,
}

func _ready():
	change_state("AMARELO")
	reaction_node.set_reaction('Thinking')
	moscas_anim_player_node.play("fly - 1")
	add_to_group("people")
	get_tree().get_root().get_node("Global_variable").reset_people_collect()
	$IndicadorCabecas.setup(min_pessoas)
	_select_random_color()

func _process(_delta):
	self.position = self.position + vel

func interact():
	if modo_converter == 0:
		converter_manager()
	else :
		converter_random()


func change_state(state):
	actual_state = STATE[state]
	if actual_state == 2:
		body_anim_player_node.play("attack")
	elif actual_state == 0:
		if qtditem == 0:
			body_anim_player_node.play("run")
		else:
			$Timer_Anim_Verde.start()
	elif actual_state == 1:
		body_anim_player_node.play("idle_no_balloon")


func converter_manager() :
	if actual_state == 1 :
		if min_pessoas <= Global_variable.get_people_collect():
			change_state("VERDE")
			moscas_anim_player_node.stop()
			collect_itens()
			Global_variable.add_people_collect(1)
			vel = Vector2(5,0)
			$pos_lixo.set_visible(false)
			garibot_followers.add_person(person_type, shirt_color, hair_color)
			queue_free()
		else :
			change_state("VERMELHO")
			throw_enemies()
			reaction_node.set_reaction('Angry')


func converter_random() :
	if modo_converter == 1 :
		change_state("VERDE")
		collect_itens()
		Global_variable.add_people_collect(1)
		queue_free()
	else : 
		change_state("VERMELHO")
		throw_enemies()


func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		body.change_state(body.STATE.HELLO)
		yield(body.get_body(),"anim_finished")
		body.change_state(body.last_state)
		_follow_player(body)


func _follow_player(body):
	garibot_followers = body.get_follow_people()
	garibot_followers.ready_set_person(person_type, shirt_color, hair_color)
	interact()


func collect_itens():
	value_bar.value += qtditem


func throw_enemies():
	if qtditem > 0:
		var enemy = enemypreload.instance()
		enemy.set_position(Vector2(5,0) + self.position)
		get_tree().get_root().call_deferred('add_child', enemy)
		qtditem -= 1
		$Timer_Anim_Vermelho.start()


func update_seguidores(seguidores):
	$IndicadorCabecas.update_seguidores(seguidores)


func _on_Timer_Anim_Verde_timeout():
	queue_free()
	

func _on_Timer_Anim_Vermelho_timeout():
	change_state("AMARELO")
	if qtditem == 0:
		change_state("VERDE")
		collect_itens()
		Global_variable.add_people_collect(1)
		vel = Vector2(5,0)
		$pos_lixo.visible = false
		$Timer_Anim_Verde.start()


func _select_random_color():
	randomize()
	if color_shirt_array.size() > 0 and color_hair_array.size():
		shirt_color = color_shirt_array[randi() % color_shirt_array.size()]
		hair_color = color_hair_array[randi() % color_hair_array.size()]
		person_node.shirt_color = shirt_color
		person_node.hair_color = hair_color
		person_node.update_colors()

extends Node2D

var actual_state
var can_interact = false
@onready var node_global = get_tree().get_root().get_node("/root/Global_variable")
@onready var value_bar = get_tree().get_nodes_in_group("value_bar").front()
var enemypreload = preload("res://scenes/enemies/Enemy2.tscn")
@export var qtditem = 0 #item q é ser coletado # (int, 1,5)
@export var modo_converter = 0 # 0 Pessoas seguindo # (int,0,2)
#1 Sim
#2 Não
@export var min_pessoas = 2
var vel = Vector2(0,0)

@export var color_hair_array: Array
@export var color_shirt_array: Array
var shirt_color: Color
var hair_color: Color

var garibot_followers

@onready var number_node = $Number.set_text(str(min_pessoas))

enum STATE{
	VERDE,
	AMARELO,
	VERMELHO,
}

func _ready():
	change_state("AMARELO")
	$Woman/Reaction.set_reaction('Thinking')
	$Mosquinhas/AnimationPlayer.play("fly - 2")
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
		$Woman/Corpo/PersonAnimationPlayer.play("attack")
	elif actual_state == 0:
		if qtditem == 0:
			$Woman/Corpo/PersonAnimationPlayer.play("run")
		else:
			$Timer_Anim_Verde.start()
			
	elif actual_state == 1:
		$Woman/Corpo/PersonAnimationPlayer.play("idle")
	
func converter_manager() :
	if actual_state == 1 :
		if min_pessoas <= node_global.get_people_collect():
			change_state("VERDE")
			$Mosquinhas/AnimationPlayer.stop()
			collect_itens()
			node_global.add_people_collect(1)
			vel = Vector2(5,0)
			$pos_lixo.set_visible(false)
			garibot_followers.add_person('woman', shirt_color, hair_color)
			queue_free()
		else :
			change_state("VERMELHO")
			throw_enemies()
			$Woman/Reaction.set_reaction('Angry')


func converter_random() :
	if modo_converter == 1 :
		change_state("VERDE")
		collect_itens()
		node_global.add_people_collect()
		queue_free()
	else : 
		change_state("VERMELHO")
		throw_enemies()


func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		garibot_followers = body.get_follow_people()
		garibot_followers.ready_set_person('woman', shirt_color, hair_color)
		interact()


func collect_itens():
	value_bar.value += qtditem


func throw_enemies():
	if qtditem > 0:
		var enemy = enemypreload.instantiate()
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
		node_global.add_people_collect(1)
		vel = Vector2(5,0)
		$pos_lixo.visible = false
		$Timer_Anim_Verde.start()

func _select_random_color():
	randomize()
	if color_shirt_array.size() > 0 and color_hair_array.size():
		shirt_color = color_shirt_array[randi() % color_shirt_array.size()]
		hair_color = color_hair_array[randi() % color_hair_array.size()]
		$Woman.shirt_color = shirt_color
		$Woman.hair_color = hair_color
		$Woman.update_colors()

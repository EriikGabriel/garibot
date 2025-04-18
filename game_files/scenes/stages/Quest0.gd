extends Node2D

var active = false
@onready var item = get_tree().get_nodes_in_group("value_bar").front()

func _ready():
	add_to_group("quest")
	_quest_active()

func _process(_delta):
	if active and item.value == item.max_value :
		queue_free()

func _quest_active():
	active = true

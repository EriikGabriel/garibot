extends Node2D

var active = false
onready var item = get_tree().get_nodes_in_group("value_bar").front()

signal checkpointed
signal open_gate

func _ready():
	add_to_group("quest")
	_quest_active()
	
	if StageManager.get_checkpointed():
		emit_signal("checkpointed", Vector2(8975, 540))
		emit_signal("open_gate")
		

func _process(_delta):
	if active and item.value == item.max_value :
		active = false

func _quest_active():
	active = true

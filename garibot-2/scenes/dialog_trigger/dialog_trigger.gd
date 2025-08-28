extends Area2D

@export var dialog_name: String

@onready var player: Player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		Dialogic.start(dialog_name)
	

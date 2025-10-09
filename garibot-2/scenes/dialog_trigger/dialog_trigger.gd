extends Area2D
class_name DialogTrigger

@export var dialog_name: String

@onready var player: Player = get_tree().get_first_node_in_group("player")
var dialog_open: bool = false

func _ready() -> void:
	# Conectar o sinal timeline_ended para retomar o controle após o diálogo
	Dialogic.timeline_ended.connect(_on_dialog_ended)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not dialog_open:
		dialog_open = true
		player.has_control = false
		Dialogic.start(dialog_name)

func _on_dialog_ended() -> void:
	dialog_open = false
	player.has_control = true

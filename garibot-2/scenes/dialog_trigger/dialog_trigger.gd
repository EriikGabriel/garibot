extends Area2D
class_name DialogTrigger

@export var dialog_timeline: DialogicTimeline
@export var once_exec: bool = false
@export var is_generic_text: bool = true

@onready var player: Player = get_tree().get_first_node_in_group("player")

var dialog_open: bool = false

func _ready() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not dialog_open:
		dialog_open = true
		player.has_control = false

		if not is_generic_text:
			var layout = Dialogic.Styles.load_style("bubbles")
			layout.register_character(load("res://dialogic/characters/garibot.dch"), player.dialog_point)
			
		# Conectar o sinal timeline_ended para retomar o controle após o diálogo
		Dialogic.timeline_ended.connect(_on_dialog_ended, CONNECT_ONE_SHOT)
		
		Dialogic.start(dialog_timeline)

func _on_dialog_ended() -> void:
	dialog_open = false
	
	if once_exec:
		monitoring = false

	player.has_control = true

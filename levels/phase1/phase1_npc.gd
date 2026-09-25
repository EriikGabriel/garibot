extends Node2D
class_name Phase1Npc

## NPC atravessável com área própria para iniciar conversa.
@export_file("*.dtl") var timeline_path := ""
@export var facing_direction := -1
var _spoke := false
var _player: Player

func _ready() -> void:
	$TalkArea.body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player") as Player

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var difference: float = _player.global_position.x - global_position.x
	if absf(difference) > 2.0:
		facing_direction = 1 if difference > 0.0 else -1
	$Eye.position.x = 9.0 if facing_direction > 0 else -13.0

func _on_body_entered(body: Node2D) -> void:
	if _spoke or not body is Player or timeline_path.is_empty():
		return
	_spoke = true
	$TalkArea.set_deferred("monitoring", false)
	Phase1Dialogue.start(timeline_path, get_parent())

extends Node2D
class_name Phase1Npc

## NPC atravessável com área própria para iniciar conversa.
@export_file("*.dtl") var timeline_path := ""
@export_file("*.dtl") var restored_timeline_path := ""
@export var facing_direction := -1
var _spoke := false
var _spoke_restored := false
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
	if not body is Player or body.in_cutscene or not body.has_control or Dialogic.current_timeline != null:
		return
	var world := get_parent().get_node_or_null("World") as Phase1World
	var restored := world != null and world.pollution_ratio() >= 0.6 and not restored_timeline_path.is_empty()
	if restored:
		if _spoke_restored:
			return
		_spoke_restored = true
	elif _spoke or timeline_path.is_empty():
		return
	else:
		_spoke = true
	Phase1Dialogue.start(restored_timeline_path if restored else timeline_path, get_parent())

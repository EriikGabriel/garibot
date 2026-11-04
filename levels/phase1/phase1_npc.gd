class_name Phase1Npc
extends Node2D

## Morador com quem o Garibot conversa ao passar pela área `TalkArea`.
## Com a vila recuperada (60% dos REEE), usa a fala de recuperação.

const RESTORED_THRESHOLD := 0.6

@export_file("*.dtl") var timeline_path := ""
@export_file("*.dtl") var restored_timeline_path := ""
@export var facing_direction := -1

var _spoke := false
var _spoke_restored := false
var _player: Player
var _restoration: RestorationProgress
## NPCs ainda sem arte usam o retângulo provisório Visual/Eye.
@onready var _body := get_node_or_null("Body") as VillagerBody


func _ready() -> void:
	$TalkArea.body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player") as Player
	_restoration = (
		get_tree().get_first_node_in_group(RestorationProgress.GROUP) as RestorationProgress
	)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var difference := _player.global_position.x - global_position.x
	if absf(difference) > 2.0:
		facing_direction = 1 if difference > 0.0 else -1
	if _body:
		_body.facing = facing_direction
		_body.happy = _is_restored()
	elif has_node("Eye"):
		$Eye.position.x = 9.0 if facing_direction > 0 else -13.0


func _is_restored() -> bool:
	return _restoration != null and _restoration.value >= RESTORED_THRESHOLD


func _on_body_entered(body: Node2D) -> void:
	if (
		not body is Player
		or body.in_cutscene
		or not body.has_control
		or Dialogic.current_timeline != null
	):
		return
	var restored := _is_restored() and not restored_timeline_path.is_empty()
	if restored:
		if _spoke_restored:
			return
		_spoke_restored = true
	elif _spoke or timeline_path.is_empty():
		return
	else:
		_spoke = true
	Phase1Dialogue.start(restored_timeline_path if restored else timeline_path, get_parent())

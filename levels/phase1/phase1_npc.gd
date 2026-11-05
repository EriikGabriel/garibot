class_name Phase1Npc
extends Node2D

## Morador com quem o Garibot conversa ao parar na área `TalkArea`.
## A primeira conversa é sempre a principal (pode abrir uma atividade); a fala de
## recuperação vem depois, com a vila recuperada e o Garibot voltando à área.
## Quem decide se a conversa pode começar agora é a fase (`try_start_npc_dialogue`).

const RESTORED_THRESHOLD := 0.45

@export_file("*.dtl") var timeline_path := ""
@export_file("*.dtl") var restored_timeline_path := ""
@export var facing_direction := -1

var _spoke := false
var _spoke_restored := false
## Depois de uma conversa, o Garibot precisa sair da área para puxar a próxima.
var _waiting_exit := false
var _player: Player
var _restoration: RestorationProgress
## NPCs ainda sem arte usam o retângulo provisório Visual/Eye.
@onready var _body := get_node_or_null("Body") as VillagerBody
@onready var _talk_area: Area2D = $TalkArea


func _ready() -> void:
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


## Consulta a área a cada quadro em vez de usar só `body_entered`: se o Garibot entrar
## rolando, no ar ou durante outra conversa, a fala espera em vez de ser perdida.
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	if not _talk_area.monitoring or not _talk_area.overlaps_body(_player):
		_waiting_exit = false
		return
	if _waiting_exit:
		return
	var timeline := _next_timeline()
	if timeline.is_empty():
		return
	var level := get_parent()
	if not level.has_method("try_start_npc_dialogue") or not level.try_start_npc_dialogue(timeline):
		return
	_waiting_exit = true
	if timeline == timeline_path:
		_spoke = true
	else:
		_spoke_restored = true


func _next_timeline() -> String:
	if not _spoke and not timeline_path.is_empty():
		return timeline_path
	if _is_restored() and not _spoke_restored and not restored_timeline_path.is_empty():
		return restored_timeline_path
	return ""


func _is_restored() -> bool:
	return _restoration != null and _restoration.value >= RESTORED_THRESHOLD

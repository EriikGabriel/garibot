class_name PlayerBody
extends Node2D

## Visual do Garibot: escolhe a animação conforme o estado do Player.

@export_range(0.0, 0.3, 0.01) var locomotion_blend_time := 0.08

var player: Player

var _cutscene_animation := false

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var magnet: Sprite2D = $Skeleton2D/Body/Head/Magnet


func _process(_delta: float) -> void:
	if player == null or _cutscene_animation:
		return
	anim_player.speed_scale = 1.0
	match player.state:
		Player.State.DAMAGE:
			_play_once("hurt")
		Player.State.IDLE:
			_play_once("idle", locomotion_blend_time)
		Player.State.MOVE:
			# Até 3x mais rápida no máximo da velocidade, igual para os dois lados.
			var speed_ratio := absf(player.move_velocity) / maxf(player.get_max_speed(), 1.0)
			anim_player.speed_scale = clampf(3.0 * speed_ratio, 1.0, 3.0)
			_play_once("walk", locomotion_blend_time)
		Player.State.AIR:
			_play_once("jump" if player.jump_velocity < 0.0 else "fall")
		Player.State.ROLL:
			_play_once("spin")
			anim_player.speed_scale = 2.0


## Toca uma animação roteirizada até `stop_cutscene_animation`.
func play_cutscene_animation(animation_name: String, speed := 1.0) -> void:
	_cutscene_animation = true
	anim_player.speed_scale = speed
	anim_player.play(animation_name)


func stop_cutscene_animation() -> void:
	_cutscene_animation = false


## Chamado pelo track de método da animação "Magnet".
func switch_magnet() -> void:
	if player:
		magnet.visible = player.magnet_on


## Evita reiniciar a animação a cada quadro (causava piscadas).
func _play_once(animation_name: StringName, blend := -1.0) -> void:
	if anim_player.assigned_animation != animation_name:
		anim_player.play(animation_name, blend)

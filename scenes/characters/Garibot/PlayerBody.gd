extends Node2D

## Controlador visual do Garibot: seleciona animações e atualiza acessórios.
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var blaster: Sprite2D = $Skeleton2D/Body/ShoulderR/ArmR/Blaster
@onready var player_body_blasters: Node = get_parent().get_node_or_null("PlayerBody/Blasters")
@onready var hand_item: Sprite2D = $Skeleton2D/Body/ShoulderL/ArmL/Trash
@onready var magnet_node: Sprite2D = $Skeleton2D/Body/Head/Magnet
var blaster_manager
var player: Player

signal anim_finished

@export var change_skin_enabled := true
var playing_cutscene_anim := false

var animation_details = {"vacuum":["aim_vaccum", 1], "bubble":["fly_bubble", 2], "shock":["aim_shock", 0], "magnet":["aim_magnet", 3],}

@onready var body_skins = [
	load("res://assets/sprites/player/PlayerChar.png"),
]

@onready var face_skins = [
	load("res://assets/sprites/player/face.png"),
]

func _ready() -> void:
	change_skin(0)

## Injeta dependências do Player após as duas cenas estarem prontas.
func setup(new_player: Player, new_blaster_manager: Node) -> void:
	player = new_player
	blaster_manager = new_blaster_manager

func _process(_delta: float) -> void:
	if player == null:
		return
	if playing_cutscene_anim:
		return
	var current_anim = anim_player.current_animation if anim_player.is_playing() else ""
	# Estados específicos (como giro) sobrescrevem a velocidade abaixo.
	# O reset impede que a velocidade do estado anterior vaze para a caminhada.
	anim_player.speed_scale = 1.0
	match(player.state):
		player.STATE.DAMAGE:
			if current_anim != "hurt":
				anim_player.play("hurt")
		player.STATE.IDLE:
			if current_anim != "idle":
				anim_player.play("idle")
		player.STATE.MOVE:
			# A animação usa o módulo da velocidade para funcionar igual nos dois lados.
			var speed_factor = 3.0 * absf(player.move_velocity) / maxf(float(player.get_max_speed()), 1.0)
			var speed = clampf(speed_factor, 1.0, 3.0)
			if current_anim != "walk":
				anim_player.play("walk", -1, speed)
			else:
				anim_player.speed_scale = speed
		player.STATE.AIR:
			if player.jump_velocity < 0:
				if current_anim != "jump":
					anim_player.play("jump")
			else:
				if current_anim != "fall":
					anim_player.play("fall")
		player.STATE.ROLL:
			if current_anim != "spin":
				anim_player.play("spin")
			anim_player.speed_scale = 2.0


func change_skin(index: int) -> bool:
	if not change_skin_enabled or index < 0 or index >= body_skins.size() or index >= face_skins.size():
		return false

	var body_node = $Skeleton2D/Body
	var face_node = $Skeleton2D/Body/Head/Face

	body_node.texture = body_skins[index]
	for child_node in body_node.get_children():
		if child_node is Sprite2D:
			child_node.texture = body_skins[index]
	face_node.texture = face_skins[index]

	return true

func play(animation_name: String, speed: float = 1.0) -> void:
	anim_player.play(animation_name, -1, speed)

func play_cutscene_animation(animation_name: String, speed: float = 1.0) -> void:
	# Bloqueia o controle automático para uma animação roteirizada tocar livremente.
	playing_cutscene_anim = true
	anim_player.play(animation_name, -1, speed)

func stop_cutscene_animation() -> void:
	playing_cutscene_anim = false

func set_hand_item_visible(is_visible: bool) -> void:
	hand_item.visible = is_visible

func switch_magnet() -> void:
	if player != null:
		magnet_node.visible = player.magnet_on

func _on_AnimationPlayer_animation_finished(animation_name: StringName) -> void:
	anim_finished.emit(animation_name)

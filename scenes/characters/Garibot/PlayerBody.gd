extends Node2D

@onready var anim_player = $AnimationPlayer
@onready var blaster = $Skeleton2D/Body/ShoulderR/ArmR/Blaster
@onready var player_body_blasters = self.get_parent().get_node_or_null("PlayerBody/Blasters")
@onready var hand_item = $Skeleton2D/Body/ShoulderL/ArmL/Trash
@onready var magnet_node = $Skeleton2D/Body/Head/Magnet
var blaster_manager
var player

signal anim_finished

@export var change_skin_enabled = true
var playing_cutscene_anim = false

var animation_details = {"vacuum":["aim_vaccum", 1], "bubble":["fly_bubble", 2], "shock":["aim_shock", 0], "magnet":["aim_magnet", 3],}

@onready var body_skins = [
	load("res://assets/sprites/player/PlayerChar.png"),
]

@onready var face_skins = [
	load("res://assets/sprites/player/face.png"),
]

func _ready():
	if self.change_skin(0):
		return

func setup(new_player, new_blaster_manager):
	self.player = new_player
	self.blaster_manager = new_blaster_manager

func _process(_delta):
	if playing_cutscene_anim:
		return
	var current_anim = anim_player.current_animation if anim_player.is_playing() else ""
	# State-specific branches below override this when needed (for example spin).
	# Resetting it here prevents a previous state's speed from leaking into walk.
	anim_player.speed_scale = 1.0
	match(player.state):
		player.STATE.DAMAGE:
			if current_anim != "hurt":
				anim_player.play("hurt")
		player.STATE.IDLE:
			if current_anim != "idle":
				anim_player.play("idle")
		player.STATE.MOVE:
			# The animation must use the magnitude of horizontal motion.  Using the
			# signed velocity made leftward movement play backwards/at a negative rate.
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
		player.STATE.HELLO:
			if current_anim != "hello":
				anim_player.play("hello")
			anim_player.speed_scale = 2.0

	#Blaster
	#   if(current_blaster == null):
	#       blaster.set_visible(false)
	#   else:
	#       if (animation_details.keys().has(current_blaster.name)):
	#           blaster.set_frame(animation_details[current_blaster.name][1])
	#       blaster.set_visible(true)

	pass

func change_skin( idx ) -> bool:
	var body_node = $Skeleton2D/Body
	var face_node = $Skeleton2D/Body/Head/Face

	if idx >= 0 and change_skin_enabled:
		body_node.set_texture(body_skins[idx])
		for child_node in body_node.get_children():
			child_node.set_texture(body_skins[idx])
		face_node.set_texture(face_skins[idx])

	return true;

func play(st : String, spd : int = 1):
	anim_player.play(st, -1, spd)

func play_cutscene_animation(st: String, speed: float = 1.0):
	# Locks auto state-driven animation so a scripted animation can play freely.
	playing_cutscene_anim = true
	anim_player.play(st, -1, speed)

func stop_cutscene_animation():
	playing_cutscene_anim = false

func set_hand_item_visible(b : bool):
	hand_item.set_visible(b);

func switch_magnet():
	magnet_node.set_visible(player.magnet_on)

func _on_AnimationPlayer_animation_finished(anim_name):
	emit_signal("anim_finished", anim_name)

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

var animation_details = {"vacuum":["aim_vaccum", 1], "bubble":["fly_bubble", 2], "shock":["aim_shock", 0], "magnet":["aim_magnet", 3],}

@onready var body_skins = [
	load("res://Assets/sprites/player/PlayerChar.png"),
	]

@onready var face_skins = [
	load("res://Assets/sprites/player/face.png"),
	]
	

func _ready():
	if self.change_skin(0):
		return


func setup(new_player, new_blaster_manager):
	self.player = new_player
	self.blaster_manager = new_blaster_manager


func _process(_delta):
	#if player_body_blasters != null:
	#	var current_blaster = blaster_manager.current_blaster
	#	
	#	#Body_animation
	#	if(current_blaster != null && (current_blaster.is_shooting || current_blaster.released_shoot) ):
	#		if (animation_details.keys().has(current_blaster.name)):
	#			anim_player.play(animation_details[current_blaster.name][0])
	#	else:
	match(player.state):
		player.STATE.DAMAGE:
			anim_player.play("hurt")
		player.STATE.IDLE:
			anim_player.play("idle")
		player.STATE.MOVE:
			anim_player.play("walk",-1,  player.orientation * (3 * (player.move_velocity / 300) ))
		player.STATE.AIR:
			if(player.jump_velocity < 0):
				anim_player.play("jump")
			else:
				anim_player.play("fall")
		player.STATE.ROLL:
			anim_player.play("spin",-1,2)
		player.STATE.HELLO:
			anim_player.play("hello",-1,2)

		#Blaster
	#	if(current_blaster == null):
	#		blaster.set_visible(false)
	#	else:
	#		if (animation_details.keys().has(current_blaster.name)):
	#			blaster.set_frame(animation_details[current_blaster.name][1])
	#		blaster.set_visible(true)
	
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


func set_hand_item_visible(b : bool):
	hand_item.set_visible(b);


func switch_magnet():
	magnet_node.set_visible(player.magnet_on)


func _on_AnimationPlayer_animation_finished(anim_name):
	emit_signal("anim_finished", anim_name)

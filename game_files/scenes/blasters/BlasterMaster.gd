extends Node2D

# BLASTERS
var blasters = {
	"magnet": preload("res://scenes/blasters/MagnetBlaster.tscn"),
	"bubble": preload("res://scenes/blasters/BubbleBlaster.tscn"),
	"shock": preload("res://scenes/blasters/ShockBlaster.tscn")
}

var current_blaster

func _ready():
	if get_child_count() and get_child(0):
		current_blaster = get_child(0)
	else:
		current_blaster = null


func change_blaster(new_blaster, player):
	if get_child_count() and get_child(0):
		if current_blaster.name == new_blaster:
			return
		get_child(0).destroy()
	
	current_blaster = blasters[new_blaster].instance()
	current_blaster.set_player(player)
	current_blaster.name = new_blaster
	add_child(current_blaster)


func _on_PlayerBody_anim_finished(anim_name):
	if anim_name == "fly_bubble":
		current_blaster._stop_floating(true)

extends Node2D

var just_shoot = false
var is_shooting = false
var released_shoot = false
var player

func _process(_event):
	
	just_shoot = false
	is_shooting = false
	released_shoot = false
	
	if Input.is_action_just_pressed("ui_blaster"):
		just_shoot = true
	
	if Input.is_action_pressed("ui_blaster"):
		is_shooting = true
	
	if Input.is_action_just_released("ui_blaster"):
		released_shoot = true
	pass

func set_player(_new):
	player = _new

func destroy():
	queue_free()

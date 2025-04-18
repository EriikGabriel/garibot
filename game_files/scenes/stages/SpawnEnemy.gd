extends Node2D

var timerspawn = false
var start = false
var enemypreload = preload("res://scenes/enemies/Enemy2.tscn")
# Called when the node enters the scene tree for the first time.
var rng = RandomNumberGenerator.new()
var positions = [Vector2(1645,120),Vector2(850,100),Vector2(850,0),Vector2(1645,250)]

func _process(delta):
	spawn()


func _on_Timer_timeout():
	timerspawn = true
	pass # Replace with function body.

func spawn():
	if timerspawn and start :
		var enemy = enemypreload.instantiate()
		var random_number = rng.randi_range(0, 3)
		rng.randomize()
		enemy.set_position(positions[random_number])
		get_tree().get_root().add_child(enemy)
		timerspawn = false

func _on_FinalBoss_half_life(variavle):
	if variavle == 1:
		start = true
	pass # Replace with function body.

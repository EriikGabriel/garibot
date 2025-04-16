extends Node2D

var posshoot
var bodyArray
var shootReady = false
var shot = preload("res://scenes/enemies/Shoot/BossShoot.tscn")


func _process(delta):
	bodyArray = $Area2D.get_overlapping_bodies()
	for body in bodyArray: 
		if body.is_in_group("player") :
			posshoot = body.position
			pass
		pass
	shoot()


func shoot():
	if shootReady:
		var bullet = shot.instance()
		posshoot.x = posshoot.x - position.x
		posshoot.y = posshoot.y - position.y 
		bullet.pos.x = posshoot.x/max(abs(posshoot.x),abs(posshoot.y))
		bullet.pos.y = posshoot.y/max(abs(posshoot.x),abs(posshoot.y))
		bullet.set_position(position + Vector2(0.0, -90.0))
		
		shootReady = false
		
		get_parent().add_child(bullet)


func _on_ShooTime_timeout():
	shootReady = true


func _on_FinalBoss_half_life(variable):
	if variable == 1:
		queue_free()

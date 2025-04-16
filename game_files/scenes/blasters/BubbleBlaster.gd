extends "blaster.gd"

var cooldown = false

func _process(_delta):
	if cooldown:
		if player.get_state() != player.STATE.AIR:
			cooldown = false
		return
	
	if is_shooting and player.get_state() != player.STATE.ROLL:
		if just_shoot:
			DJ.play_sfx("blaster_bubble")
		player.change_state(player.STATE.AIR)
		player.set_gravity_force(50)
		player.set_air_final_speed(-200)
	else:
		_stop_floating()


func _stop_floating(_cooldown = false):
	player.set_gravity_force(30)
	player.set_air_final_speed(700)
	cooldown = _cooldown


func destroy():
	_stop_floating()
	queue_free()

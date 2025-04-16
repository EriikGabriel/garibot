extends "blaster.gd"

var magnet = false
var can_shoot = true

func _process(_delta):
	if can_shoot:
		if just_shoot and player.get_state() != player.STATE.ROLL:
			magnet = !magnet
			if magnet:
				DJ.play_sfx("blaster_magnet_on")
			else:
				DJ.play_sfx("blaster_magnet_off")
			player.activate_gravity(magnet)
			can_shoot = false
			$Timer.start()


func _on_Timer_timeout():
	can_shoot = true

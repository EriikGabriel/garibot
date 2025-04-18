extends "blaster.gd"

#onready var player = get_tree().get_nodes_in_group("player").front()
var shot = preload("res://scenes/blasters/NewPlayerShoot.tscn")
var curve = preload("res://scenes/blasters/ShootCurve.tscn")
@onready var shootRate = get_node("Timer")

var shootReady = true
var power = 0.1
const POWER_INCREASE = 0.1
const MAX_POWER = 1.75

func _process(_delta):
	if just_shoot:
		power = 0.1
	
	player.set_ctrl_pressed(true)
	
	if is_shooting:
		player.set_ctrl_pressed(false)
		power += POWER_INCREASE
	
	if released_shoot:
			#Play animation
			player.set_ctrl_pressed(false)
			shoot()
			$SFX.play()

func shoot():
	if shootReady:
		var bullet_curve = curve.instantiate()
		var bullet = shot.instantiate()
		
		bullet_curve.set_position(player.position + Vector2(10.0*player.orientation, 8.0))
		bullet_curve.scale = Vector2(player.orientation*min(power,MAX_POWER),1)
		shootRate.start()
		
		#print_debug("Pew Pew: ", count)
		#count += 1
		shootReady = false
		bullet_curve.add_child(bullet)
		get_tree().get_root().add_child(bullet_curve) # nao vou mudar isso pq n depende de nada

func destroy():
	player.set_ctrl_pressed(true)
	queue_free()


func _on_Timer_timeout():
	shootReady = true

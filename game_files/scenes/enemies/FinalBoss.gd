extends KinematicBody2D

var life = 15
onready var animPlayer = $AnimationPlayer
onready var player = get_tree().get_nodes_in_group("player").front()
var shot = preload("res://scenes/enemies/Shoot/Shoot.tscn")

enum ENEMY {
	MOVE,
	SLEEP,
	TALK
}
var state
var motion = Vector2(0,0)
var angle = 5.0
var curve = 250.0
var speed = 100.0
var vec = Vector2.UP
var orientation = 1
var temp = 1
var shootReady = true
var flaglife = true
#signal half_life
#signal enemy_defeated

func _ready():
	add_to_group("enemies")
	state = ENEMY.SLEEP


func _physics_process(_delta):
	var ori = (player.position - self.position)
	
	match state:
		ENEMY.MOVE:
			ori.x = int(clamp(ori.x,-1,1))
			ori.y = int(clamp(ori.y,-1,1))
			change_orientation(ori.x)
			var _collision = move_and_slide(ori * speed)
			$BossBody/AnimationPlayer.play("move")
			$DamageArea.monitoring = true
		ENEMY.SLEEP:
			$DamageArea.monitoring = false
		ENEMY.TALK:
			$BossBody/AnimationPlayer.play("talk")
			$DamageArea.monitoring = false


func change_state(new_state):
	if(new_state != state):
		state = new_state


func _on_ShootTimer_timeout():
	shootReady = true


func change_orientation(ori):
	if(orientation != ori and ori != 0):
		orientation = ori
		self.scale.x *= -1


func destroy():
	if life == 0:
		queue_free()


func _on_DamageArea_body_entered(body):
	if body.is_in_group("player"):
		body.recieve_damage(1)
		state = ENEMY.SLEEP
		$Timer.start()


func play_anim_talk():
	state = ENEMY.TALK


func boss_start_move():
	state = ENEMY.MOVE


func boss_sleep():
	state = ENEMY.SLEEP


func _on_Timer_timeout():
	state = ENEMY.MOVE



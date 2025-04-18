extends "blaster.gd"


#onready var player = get_parent().get_parent().get_parent()
@onready var area = $Area2D
@onready var pos = $Area2D/Marker2D
@onready var collision = $Area2D/CollisionShape2D
@onready var sound_effect = $SFX

var is_sucking = false
var last_enemy = null


func _process(_delta):
	
	if is_shooting or is_sucking:
			#Play animation
			player.set_ctrl_pressed(false)
			
			collision.disabled = false
			
			if not sound_effect.playing:
				sound_effect.play()
	else:
		player.set_ctrl_pressed(false)
		collision.disabled = true
		sound_effect.stop()
	pass


func _on_Area2D_body_entered(body):
	if body.is_in_group("enemies"):
		is_sucking = true
		last_enemy = body.name
		
		disable_damage(body)
		
		$TweenPos.interpolate_property(body, "global_position", body.global_position, pos.global_position, 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN)
		$TweenScale.interpolate_property(body, "scale", body.scale, Vector2(0,0) , 1,
		Tween.TRANS_CIRC, Tween.EASE_IN)
		$TweenRotation.interpolate_property(body, "rotation_degrees", body.rotation_degrees, 900, 1,
		Tween.TRANS_CIRC, Tween.EASE_IN)
		$TweenPos.start()
		$TweenScale.start()
		$TweenRotation.start()


func _on_TweenScale_tween_completed(object, _key):
	if object.name == last_enemy:
		is_sucking = false
		
	object.call_deferred("destroy")

func destroy():
	player.set_ctrl_pressed(true)
	queue_free()

func disable_damage(body):
	body.get_node("DamageArea").monitoring = false
	body.get_node("CollisionShape2D").disabled = true

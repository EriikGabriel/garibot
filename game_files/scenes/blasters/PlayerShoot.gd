extends Area2D

var angle = 10.0
var curve = 120.0
var speed = 300.0
var vec = Vector2.UP
var orientation = 1.0
var last_pos = Vector2(0,0)
const ACC_FACTOR = 0.6

var anim_time = null

func _ready():
	set_process(true)
	add_to_group("playershoot")
	set_scale(Vector2(1/self.get_parent().get_parent().get_scale().x, 1/self.get_parent().get_parent().get_scale().y))

func _process(delta):
	move(delta)
	
	if anim_time != null:
		if anim_time <= 0:
			self.queue_free()
		else:
			anim_time -= delta

func move(delta):
	get_parent().progress_ratio += delta + acceleration(delta)
	if get_parent().progress_ratio >= 1:
		$CollisionShape2D.disabled = true
		$AnimationPlayer.play("disapear")

func acceleration(delta) -> float:
	if last_pos < self.get_position():
		last_pos = self.get_position()
		return -1*delta*ACC_FACTOR
	else:
		last_pos = self.get_position()
		return delta*ACC_FACTOR

func _on_PlayerShoot_body_entered(body):
	if body.has_method("destroy"):
		body.destroy()
	$AnimationPlayer.play("disapear")
	anim_time = 0.05


func _on_PlayerShoot_area_entered(_area):
	$AnimationPlayer.play("disapear")
	anim_time = 0.05

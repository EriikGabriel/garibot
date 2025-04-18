extends CharacterBody2D

@onready var sprite = $Sprite2D
signal enemy_defeated

var shot = preload("res://scenes/enemies/Shoot/Shoot.tscn")

# Visual variables
@export var itemIdx = 0
var item = preload("res://scenes/item/Item.tscn")

# Movement variables
@export var speed := 100.0
@export var gravity := 1000.0
var velocity := Vector2(speed, 0.0)
var orientation := 1.0
var count = 0

# State machine variables
var resting = false
var hopReady = false
var jumpReady = false
var shootReady = false
var seeingPlayer = false
@onready var shootRate = get_node("ShootTimer")

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("enemies")
	pass 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity.x = rest()
	
	velocity.y += gravity * delta
	
	hop()
	look_and_shoot()
	
	if is_on_wall():
		turn()
	
	if Input.is_action_just_pressed("debug_trigger"):
		shoot()
	
	velocity.x *= orientation
	
	set_velocity(velocity)
	set_up_direction(Vector2.UP)
	set_floor_stop_on_slope_enabled(true)
	set_max_slides(4)
	set_floor_max_angle(0.79)
	move_and_slide()
	velocity = velocity
	pass

func turn():
	orientation *= -1.0
	self.scale.x = -abs(self.scale.x)
	pass

func hop():
	if hopReady:
		velocity = Vector2(100.0,-150.0)
		hopReady = false

func jump():
	if jumpReady and velocity.x != 0.0:
		velocity = Vector2(100.0,-400.0)
		jumpReady = false

func rest():
	if resting:
		return 0.0
	else:
		return speed

func look_and_shoot():
	if seeingPlayer:
		shoot()
	
func shoot():
	if shootReady:
		$SFX.play()
		
		var bullet = shot.instantiate()
		bullet.orientation = orientation
		bullet.set_position(position + Vector2(30.0*orientation, -10.0))
		
		shootRate.start()
		
		print_debug("Pew Pew: ", count)
		count += 1
		shootReady = false
		
		get_parent().add_child(bullet)

func spawn_item():
	$SFX.play()

	var itemDrop = item.instantiate()
	itemDrop.set_position(self.position)
	itemDrop.change_item("impressora")
	
	var questNode = get_tree().get_nodes_in_group("quest").front()
	if not questNode == null:
		questNode.add_child(itemDrop)


func destroy():
	emit_signal("enemy_defeated")
	spawn_item()
	queue_free()

func _on_HopTimer_timeout():
	hopReady = true
	pass 

func _on_JumpTimer_timeout():
	jumpReady = true
	pass 

func _on_RestTimer_timeout():
	resting = !resting
	pass 

func _on_TurnTimer_timeout():
	if !is_on_wall():
		turn()
	pass 

func _on_ShootTimer_timeout():
	shootReady = true
	pass 

func _on_VisionArea_body_entered(_body):
	seeingPlayer = true
	pass 

func _on_VisionArea_body_exited(_body):
	seeingPlayer = false
	pass 

func _on_HitArea_body_entered(_body):
	pass

func _on_HitArea_area_entered(area):
	if area.is_in_group("player_hit"):
		area.get_parent().apply_jump()
		destroy()
	pass 

func _on_DamageArea_body_entered(body):
	if body.is_in_group("player"):
		body.recieve_damage(1)
	pass 

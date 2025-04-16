extends KinematicBody2D

#onready var sprite = $Sprite
signal enemy_defeated

var shot = preload("res://scenes/enemies/Shoot/Shoot.tscn")

# Visual variables
export var itemIdx = 0
var item = preload("res://scenes/item/Item.tscn")

# Movement variables
export var speed := 100.0
export var gravity := 1500.0
var velocity := Vector2(speed, 0.0)
var orientation := 1.0
var count = 0

#Addicional features 
export (int,"Off", "Common", "Drill","Printer") var enemyType
export var shoot_ability = false
export var dash_ability = false
export var jump_immunity = false
export (String,"celular", "monitor", "tv", "impressora",
		"furadeira", "fogao", "geladeira", "microondas") var itemType
		
# Sound file for hop sound effect
export var sfxHop_sound = "res://assets/Sounds/enemy_sfx/enemy_computer.mp3"
export var sfxDash_sound = "res://assets/Sounds/enemy_sfx/enemy_furadeira_dash.mp3"
export var sfxShoot_sound = "res://assets/Sounds/enemy_sfx/enemy_furadeira_dash.mp3"
var destroyedSfx = preload("res://scenes/enemies/Sounds/DestroyedSfx.tscn")

#Dictionary of features

var table_ability ={
	0 : [false,false,false],
	1 : [false,false,false],
	2 : [false,true,false],
	3 : [true,false,false],
}

# State machine variables
var resting = false
var hopReady = false
var jumpReady = false
var shootReady = false
var seeingPlayer = false
onready var shootRate = get_node("AbilityTimer")

# Called when the node enters the scene tree for the first time.
func _ready():
	var hop_stream = load(sfxHop_sound)
	var shoot_stream = load(sfxShoot_sound)
	var dash_stream = load(sfxDash_sound)
	$EnemySfx/SfxHop.set_stream(hop_stream)
	$EnemySfx/SfxShoot.set_stream(shoot_stream)
	$EnemySfx/SfxDash.set_stream(dash_stream)
	add_to_group("enemies")
	change_abilities()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity.x = rest()
	velocity.y += gravity * delta
	
	hop()
	jump()
	
	if is_on_wall():
		turn()
	
	if shoot_ability and seeingPlayer:
		shoot()
	
	if dash_ability and seeingPlayer:
		dash()
	
	velocity.x *= orientation
	velocity = move_and_slide(velocity, Vector2.UP, true, 4, 0.79)


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
		$EnemySfx/SfxHop.play(0)
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
		$EnemySfx/SfxShoot.play(0)
		
		var bullet = shot.instance()
		bullet.orientation = orientation
		bullet.set_position(position + Vector2(30.0*orientation, -10.0))
		
		shootRate.start()
		
		#print_debug("Pew Pew: ", count)
		count += 1
		shootReady = false
		
		get_parent().add_child(bullet)

func dash():
	if shootReady:
		$EnemySfx/SfxDash.play(0)
		speed = speed * 3
		$DashTimer.start()
		shootReady = false
		$AbilityTimer.start()
		$HopTimer.stop()
		pass


func spawn_item():
	var itemDrop = item.instance()
	itemDrop.set_position(self.position)
	itemDrop.itemName = itemType
	
	var questNode = get_tree().get_nodes_in_group("quest").front()
	if not questNode == null:
		questNode.add_child(itemDrop)

func destroy():
	emit_signal("enemy_defeated")
	spawn_item()
	
	var destroyed_sfx = destroyedSfx.instance()
	destroyed_sfx.set_position(self.position)
	get_parent().add_child(destroyed_sfx)
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

func _on_VisionArea_body_entered(_body):
	seeingPlayer = true

func _on_VisionArea_body_exited(_body):
	seeingPlayer = false


func _on_HitArea_body_entered(_body):
	pass

func _on_HitArea_area_entered(area):
	if area.is_in_group("player_hit"):
		area.get_parent().apply_jump()
		if jump_immunity == false :
			destroy()

func _on_DamageArea_body_entered(body):
	if body.is_in_group("player"):
		body.recieve_damage(1)

func change_abilities():
	if not enemyType == 0 :
		shoot_ability = table_ability[enemyType][0]
		dash_ability = table_ability[enemyType][1]
		jump_immunity = table_ability[enemyType][2] 


func _on_DashTimer_timeout():
	print(speed)
	speed = speed/3
	print(speed)
	$DashTimer.stop()
	$HopTimer.start()

func _on_AbilityTimer_timeout():
	shootReady = true

extends CharacterBody2D

@export var initial_sprite: Texture2D
var correct_item = false
var center = null
var timer = 0
var saved_position = null
var name_item = null

var velocity = Vector2(0, 0)
var acceleration = Vector2(0, 0)


func _ready():
	set_sprite(initial_sprite)


func init(_velocity, _position):
	self.velocity = _velocity
	self.position = _position


func _process(delta):
	if (center != null):
		global_position = center.global_position
		saved_position = center.global_position
	
	velocity += delta*acceleration
	var _collision = move_and_collide(velocity)


func set_center(_center):
	if _center == null:
		# print_debug("center null")
		velocity = Vector2(0, 0)
		acceleration = Vector2(0, 3)
		if saved_position != null:
			global_position.x = saved_position.x
			saved_position = null
	
	self.center = _center


func set_sprite(_new):
	$Sprite2D.texture = _new


func set_gravity(isInverted):
	print_debug("set_gravity " + str(isInverted))
	if isInverted:
		velocity.y = 0
		acceleration = Vector2(0, -3)
	else:
		acceleration = Vector2(0, 3)

#Atualiza a textura do item quebrado
#name_item: String
func set_texture_item(item):
	$UsinaItemArea.texture = ItemTextureMap.textures_d[item]	
	name_item = item

func set_correct(a):
	correct_item = a


func connect_to_minigame4(minigame4):
	minigame4.connect("gravity_altered", Callable(self, "set_gravity"))
	# print_debug("connect to minigame4")


func _on_UsinaItemArea_body_entered(_body):
	velocity.x = 0
	acceleration = Vector2(0, 0)


func _on_UsinaItemArea_body_exited(_body):
	if acceleration == Vector2(0, 0):
		# print_debug("usina body exited")
		velocity = Vector2(0,0)
		acceleration = Vector2(0, 3)

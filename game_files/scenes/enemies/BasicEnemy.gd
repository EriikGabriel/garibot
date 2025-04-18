extends CharacterBody2D

signal enemy_defeated()

@export var WALK_SPEED: int = 64
@export var STARTER_DIRECTION: int = 1
@export var AIR_FINAL_SPEED: int = 550
@export var GRAV: int = 16
@export var IS_BULLET_PROOF: bool = false


@onready var sprite = $Sprite2D
@onready var floor_detection = $Sprite2D/RayCast2D


var motion = Vector2(0,0)
var FALL_DIR = Vector2(0,-1)
var SPEED = 0
var orientation = 1
var state


var is_virus = false: set = set_virus


enum ENEMY {
	MOVE,
	AIR
}


func _ready():
	
	#if is_virus:
	#	$Sprite/animRoot/Corpo.visible = false
	#else:
	#	self.connect("enemy_defeated", get_parent(), "_on_enemy_defeated")
	
	add_to_group("basic_enemies")
	change_orientation(STARTER_DIRECTION)
	state = ENEMY.MOVE
	
	
func set_virus(v):
	is_virus = v
	
	
func _physics_process(delta):
	match state:
		ENEMY.MOVE:
			SPEED = WALK_SPEED
			
			if is_on_wall():
				change_orientation(orientation*(-1))
			elif !floor_detection.is_colliding():
				if is_on_floor():
					change_orientation(orientation*(-1))
				else:
					change_state(ENEMY.AIR)
		ENEMY.AIR:
			SPEED = 0
			
			if is_on_floor():
				change_state(ENEMY.MOVE)
	
	if state == ENEMY.MOVE:
		motion.x = SPEED * orientation
	else:
		motion.x = SPEED
	
	motion.y = approach(motion.y, AIR_FINAL_SPEED, GRAV)
	
	set_velocity(motion)
	# TODOConverter3To4 looks that snap in Godot 4 is float, not vector like in Godot 3 - previous value `Vector2(0,32)`
	set_up_direction(FALL_DIR)
	set_floor_stop_on_slope_enabled(true)
	set_max_slides(4)
	set_floor_max_angle(0.79)
	move_and_slide()
	motion = velocity
	
	
func destroy():
	emit_signal("enemy_defeated")
	queue_free()
	
	
func change_state(new_state):
	if(new_state != state):
		state = new_state


func change_orientation(ori):
	if(orientation != ori and ori != 0):
		orientation = ori
		self.scale.x *= -1
		
		
func approach(a, b, amount):
	if (a < b):
		a += amount
		if (a > b):
			return b
	else:
		a -= amount
		if(a < b):
			return b
	return a

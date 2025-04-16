extends KinematicBody2D

signal enemy_defeated()

export (int) var WALK_SPEED = 64
export (int) var STARTER_DIRECTION = 1
export (int) var AIR_FINAL_SPEED = 550
export (int) var GRAV = 16
export (bool) var IS_BULLET_PROOF = false


onready var sprite = $Sprite
onready var floor_detection = $Sprite/RayCast2D


var motion = Vector2(0,0)
var FALL_DIR = Vector2(0,-1)
var SPEED = 0
var orientation = 1
var state


var is_virus = false setget set_virus


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
	
	motion = move_and_slide_with_snap(motion, Vector2(0,32), FALL_DIR, true, 4, 0.79)
	
	
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

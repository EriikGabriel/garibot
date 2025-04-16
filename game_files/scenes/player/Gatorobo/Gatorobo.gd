extends KinematicBody2D

onready var body = $GatoroboBody
onready var anim_player = $GatoroboBody/GariDog/Corpo/PersonAnimationPlayer

# EXPORT VARIABLES
export (int) var MAXSPEED = 300
export (int) var FLOOR_ACC = 125
export (int) var AIR_ACC = 75
export (int) var JUMP_MIN_HEIGHT = 200
export (int) var JUMP_MAX_HEIGHT = 750
export (int) var AIR_FINAL_SPEED = 700
export (int) var GRAVITY_FORCE = 30
export (int) var ROLL_SPEED = 1200
export (int) var ROLL_DURATION = 15 # How further the dash goes
export (int) var ROLL_COOLDOWN = 50 # How many frames to activate dash again
export (int) var DAMAGE_DURATION = 15
export (bool) var has_control = true

# SCRIPT VARIABLES
var move_velocity = 0
var jump_velocity = 0
var velocity = Vector2(0, 0)
var floor_normal = Vector2(0, -1)
var orientation
var key_left
var key_right
var dir
var jump
var roll_attack
var state
var last_state
var gravity
var last_gravity
var gravity_on
var damage
var life = 3
var typelixeira = 0 


# FRAMES COOLDOWN
var ledgedrop_cooldown_max = 10
var ledgedrop_cooldown = ledgedrop_cooldown_max
var roll_duration = ROLL_DURATION
var roll_cooldown = ROLL_COOLDOWN
var damage_duration = DAMAGE_DURATION

enum STATE {
	IDLE,
	MOVE,
	AIR,
	ROLL,
	DAMAGE
}


enum GRAVITY {
	DOWN,
	RIGHT,
	UP,
	LEFT
}

signal changed_item

func _ready():
	state = STATE.IDLE
	gravity = GRAVITY.DOWN
	orientation = 1
	gravity_on = true
	add_to_group("player")


func _physics_process(_delta):
	key_left = 0
	key_right = 0

	jump = false
	roll_attack = false
	damage = false
	dir = 0

	if has_control:
		handle_input()
	
	calculate_cooldown()
	begin_state_machine()
	calculate_velocity()
	pass


func handle_input():
	match gravity:
		GRAVITY.DOWN:
			if Input.is_action_pressed("ui_left"):
				key_left = -1
			if Input.is_action_pressed("ui_right"):
				key_right = 1
				
			dir = key_left + key_right
			if dir != 0:
				change_orientation(dir)
		GRAVITY.RIGHT:
			if Input.is_action_pressed("ui_up"):
				key_right = -1
			if Input.is_action_pressed("ui_down"):
				key_left = 1
			dir = key_right + key_left
			if dir != 0:
				change_orientation(dir)
		GRAVITY.UP:
			if Input.is_action_pressed("ui_left"):
				key_left = -1
			if Input.is_action_pressed("ui_right"):
				key_right = 1
				
			dir = key_left + key_right
			if dir != 0:
				change_orientation(dir)
		GRAVITY.LEFT:
			if Input.is_action_pressed("ui_up"):
				key_right = -1
			if Input.is_action_pressed("ui_down"):
				key_left = 1
			dir = key_left + key_right
			if dir != 0:
				change_orientation(dir)
		
	
	if Input.is_action_just_pressed("ui_accept"):
		jump = true
	if(Input.is_action_just_released("ui_accept")):
		if(jump_velocity  < JUMP_MIN_HEIGHT*-1):
			jump_velocity = JUMP_MIN_HEIGHT*-1
			
	if Input.is_action_just_pressed("roll_attack"):
		typelixeira = $Lixeira.button_change(-1,typelixeira)
	if Input.is_action_just_pressed("ui_blaster"):
		typelixeira = $Lixeira.button_change(1,typelixeira)
	pass


func begin_state_machine():
	match state:
		STATE.IDLE:
			anim_player.play("idle")
			
			move_velocity = 0
			if damage:
				damage_duration = 0
				change_state(STATE.DAMAGE)
			elif roll_attack:
				roll_duration = 0
				change_state(STATE.ROLL)
			elif jump:
				calculate_jump(JUMP_MAX_HEIGHT, true)
				change_state(STATE.AIR)
			elif !is_on_floor() and !is_on_wall():
				ledgedrop_cooldown = 0
				change_state(STATE.AIR)
			elif dir != 0:
				change_state(STATE.MOVE)
		STATE.MOVE:
			anim_player.play("walk")
			
			move_velocity = approach(move_velocity, MAXSPEED * dir, FLOOR_ACC)
			if damage:
				damage_duration = 0
				change_state(STATE.DAMAGE)
			elif roll_attack:
				roll_duration = 0
				change_state(STATE.ROLL)
			elif jump:
				calculate_jump(JUMP_MAX_HEIGHT, true)
				change_state(STATE.AIR)
			elif !is_on_floor() and !is_on_wall():
				ledgedrop_cooldown = 0
				change_state(STATE.AIR)
			elif move_velocity == 0:
				change_state(STATE.IDLE)
		STATE.AIR:
			
			if(jump_velocity < 0):
				anim_player.play("jump")
			else:
				anim_player.play("fall")
		
			move_velocity = approach(move_velocity, MAXSPEED * dir, AIR_ACC)
			
			if jump:
				if ledgedrop_cooldown < ledgedrop_cooldown_max:
					calculate_jump(JUMP_MAX_HEIGHT)
					#ledgedrop_cooldown = ledgedrop_cooldown_max
			if damage:
				damage_duration = 0
				change_state(STATE.DAMAGE)
			elif roll_attack:
				roll_duration = 0
				change_state(STATE.ROLL)
			if is_on_floor():
				jump_velocity = 1
				if move_velocity == 0:
					change_state(STATE.IDLE)
				else:
					change_state(STATE.MOVE)
			pass
			
	pass


func calculate_velocity():
	var snap = Vector2(0, 0)
	
	match gravity:
		GRAVITY.DOWN:
			if gravity_on and state == STATE.AIR:
				jump_velocity = approach(jump_velocity, AIR_FINAL_SPEED, GRAVITY_FORCE)
			
			if state == STATE.IDLE or state == STATE.MOVE:
				snap = Vector2(0, 31)
			
			velocity.x = move_velocity
			velocity.y = jump_velocity
			floor_normal = Vector2(0, -1)
		GRAVITY.RIGHT:
			if gravity_on and state == STATE.AIR:
				jump_velocity = approach(jump_velocity, AIR_FINAL_SPEED, GRAVITY_FORCE)
			
			if state == STATE.IDLE or state == STATE.MOVE:
				snap = Vector2(31, 0)
			
			velocity.y = move_velocity
			velocity.x = jump_velocity
			floor_normal = Vector2(-1, 0)
		GRAVITY.UP:
			if gravity_on and state == STATE.AIR:
				jump_velocity = approach(jump_velocity, AIR_FINAL_SPEED, GRAVITY_FORCE)
			
			if state == STATE.IDLE or state == STATE.MOVE:
				snap = Vector2(0, -31)
			
			velocity.x = move_velocity
			velocity.y = jump_velocity * -1
			floor_normal = Vector2(0, 1)
		GRAVITY.LEFT:
			if gravity_on and state == STATE.AIR:
				jump_velocity = approach(jump_velocity, AIR_FINAL_SPEED, GRAVITY_FORCE)
			
			if state == STATE.IDLE or state == STATE.MOVE:
				snap = Vector2(-31, 0)
			
			velocity.y = move_velocity
			velocity.x = jump_velocity * -1
			floor_normal = Vector2(1, 0)
				
	velocity = move_and_slide_with_snap(velocity, snap, floor_normal, true, 5, 0.85)
	pass


func calculate_cooldown():
	ledgedrop_cooldown = min(ledgedrop_cooldown + 1, ledgedrop_cooldown_max)
	roll_duration = min(roll_duration + 1, ROLL_DURATION)
	roll_cooldown = min(roll_cooldown + 1, ROLL_COOLDOWN)
	damage_duration = min(damage_duration + 1,DAMAGE_DURATION)


func change_state(new_state):
	if new_state != state:
		last_state = state
		state = new_state


func change_orientation(ori):
	if(orientation != ori and ori != 0):
		match gravity:
			GRAVITY.DOWN:
				orientation = ori
				body.scale.x *= -1
			GRAVITY.RIGHT:
				orientation = ori
				body.scale.x *= -1
			GRAVITY.UP:
				orientation = ori
				body.scale.x *= -1
			GRAVITY.LEFT:
				orientation = ori
				body.scale.x *= -1
		
		
func change_gravity(grav):
	if grav != gravity:
		last_gravity = gravity
		gravity = grav
		
		# jump_velocity = 0
		
		match gravity:
			GRAVITY.DOWN:
				if last_gravity != GRAVITY.LEFT:
					orientation *= -1
				$Tween.interpolate_property(self, "rotation_degrees", self.rotation_degrees, 0, 0.5,
						Tween.TRANS_ELASTIC, Tween.EASE_OUT)
				$Tween.start()
			GRAVITY.RIGHT:
				if last_gravity != GRAVITY.UP:
					orientation *= -1
				$Tween.interpolate_property(self, "rotation_degrees", self.rotation_degrees, -90, 0.5,
						Tween.TRANS_ELASTIC, Tween.EASE_OUT)
				$Tween.start()
			GRAVITY.UP:
				if last_gravity != GRAVITY.RIGHT:
					orientation *= -1
				$Tween.interpolate_property(self, "rotation_degrees", self.rotation_degrees, -180, 0.5,
						Tween.TRANS_ELASTIC, Tween.EASE_OUT)
				$Tween.start()
			GRAVITY.LEFT:
				if last_gravity != GRAVITY.DOWN:
					orientation *= -1
				$Tween.interpolate_property(self, "rotation_degrees", self.rotation_degrees, 90, 0.5,
						Tween.TRANS_ELASTIC, Tween.EASE_OUT)
				$Tween.start()


func calculate_jump(jump_height: int = JUMP_MAX_HEIGHT, _is_floor_jump: bool = false):
	jump_velocity = jump_height*-1
	pass


func apply_jump():
	jump = true
	calculate_jump()
	calculate_velocity()
	pass


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


func _on_Lixeira_changed_item(new_item):
	emit_signal("changed_item", new_item)

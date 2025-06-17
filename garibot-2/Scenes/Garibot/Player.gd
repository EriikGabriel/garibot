extends CharacterBody2D


# PRELOADS
# warning-ignore:unused_class_variable
@onready var body = $PlayerBody
@onready var blaster_manager = $PlayerBody/Blasters
@onready var health_bar = get_tree().get_nodes_in_group("health_bar").front()
@onready var game_over = get_tree().get_nodes_in_group("game_over").front()

# EXPORT VARIABLES
@export var MAXSPEED: int = 300
@export var FLOOR_ACC: int = 125
@export var AIR_ACC: int = 75
@export var JUMP_MIN_HEIGHT: int = 300
@export var JUMP_MAX_HEIGHT: int = 750
@export var AIR_FINAL_SPEED: int = 700
@export var GRAVITY_FORCE: int = 30
@export var ROLL_SPEED: int = 1200
@export var ROLL_DURATION: int = 15 # How far the dash goes
@export var ROLL_COOLDOWN: int = 50 # How many frames to activate dash again
@export var DAMAGE_DURATION: int = 15
@export var has_control: bool = true
var in_cutscene = false

# SCRIPT VARIABLES
var move_velocity = 0
var jump_velocity = 0
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
var current_gravity
var last_gravity
var gravity_on
var magnet_on = false
var damage
var life = 5
var invinc_duration = 0
var invinc_fading = true

# FRAMES COOLDOWN
var ledgedrop_cooldown_max = 10
var ledgedrop_cooldown = ledgedrop_cooldown_max
var roll_duration = ROLL_DURATION
var roll_cooldown = ROLL_COOLDOWN
var damage_duration = DAMAGE_DURATION

signal emit_player

enum STATE {
	IDLE,
	MOVE,
	AIR,
	ROLL,
	DAMAGE,
	HELLO
}


enum GRAVITY {
	DOWN,
	RIGHT,
	UP,
	LEFT
}


func _ready():
	state = STATE.IDLE
	gravity = GRAVITY.DOWN
	current_gravity = gravity
	orientation = 1
	gravity_on = true
	add_to_group("player")
	emit_signal("emit_player", self)
	
	# setup variables
	body.setup(self, blaster_manager)


func _physics_process(_delta):
	key_left = 0
	key_right = 0

	jump = false
	roll_attack = false
	damage = false
	dir = 0
	
	if has_control and !in_cutscene:
		handle_input()
	
	calculate_cooldown()
	begin_state_machine()
	calculate_velocity()
	invinc_frames(_delta)
	
	$Debug/State.text = str(state)


func invinc_frames(delta):
	if invinc_duration > 0:
		invinc_duration -= delta
		var modulater = $PlayerBody.get_modulate()
		if invinc_duration <= 0:
			$PlayerBody.set_modulate(Color(1, 1, 1, 1))
			invinc_fading = true
			return
		
		if invinc_fading:
			if modulater.a <= 0.2:
				invinc_fading = false
			$PlayerBody.set_modulate(modulater + Color(0, 0, 0, -25*delta))
		else:
			if modulater.a >= 0.95:
				invinc_fading = true
			$PlayerBody.set_modulate(modulater + Color(0, 0, 0, 25*delta))


func handle_input():
	if Input.is_action_just_pressed("move_up"):
		jump = true
	
	if(Input.is_action_just_released("move_up")):
		if(jump_velocity  < JUMP_MIN_HEIGHT*-1):
			jump_velocity = JUMP_MIN_HEIGHT*-1
		
	if Input.is_action_pressed("move_left"):
		key_left = -1
	if Input.is_action_pressed("move_right"):
		key_right = 1
	
	dir = key_left + key_right
	if dir != 0:
		change_orientation(dir)
			
	if Input.is_action_just_pressed("attack"):
		if roll_cooldown == ROLL_COOLDOWN:
			roll_attack = true
			roll_cooldown = 0


func begin_state_machine():
	match state:
		STATE.IDLE:
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
			move_velocity = approach(move_velocity, MAXSPEED * dir, AIR_ACC)
			
			if jump:
				if ledgedrop_cooldown < ledgedrop_cooldown_max:
					calculate_jump(JUMP_MAX_HEIGHT)
			if damage:
				damage_duration = 0
				change_state(STATE.DAMAGE)
			elif roll_attack:
				roll_duration = 0
				change_state(STATE.ROLL)
			if is_on_floor():
				if true:
					#if blaster_manager.current_blaster.name == "bubble" and blaster_manager.current_blaster.is_shooting:
					pass
				jump_velocity = 1
				if move_velocity == 0:
					change_state(STATE.IDLE)
				else:
					change_state(STATE.MOVE)
			pass
			
		STATE.ROLL:
			move_velocity = ROLL_SPEED * orientation
			jump_velocity = 1
			has_control = false
			gravity_on = false
			switch_spin_hit(true)
			
			if roll_duration == ROLL_DURATION:
				switch_spin_hit(false)
				if is_on_floor():
					jump_velocity = 1
					if move_velocity == 0:
						change_state(STATE.IDLE)
					else:
						change_state(STATE.MOVE)
					has_control = true
					gravity_on = true
				else:
					change_state(STATE.AIR)
					has_control = true
					gravity_on = true
					
			if not $SFX/roll.playing:
				$SFX/roll.play(0.0)
				
		STATE.DAMAGE:
			if not $SFX/damage.playing:
				$SFX/damage.play()
			
			if damage_duration == DAMAGE_DURATION:
			
				if roll_attack:
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
				elif move_velocity == 0:
					change_state(STATE.IDLE)
			pass
			
		STATE.HELLO:
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
			velocity.y = -jump_velocity
			floor_normal = Vector2(0, 1)
		GRAVITY.LEFT:
			if gravity_on and state == STATE.AIR:
				jump_velocity = approach(jump_velocity, AIR_FINAL_SPEED, GRAVITY_FORCE)
			
			if state == STATE.IDLE or state == STATE.MOVE:
				snap = Vector2(-31, 0)
			
			velocity.y = move_velocity
			velocity.x = -jump_velocity
			floor_normal = Vector2(1, 0)
				
	set_velocity(velocity)
	set_up_direction(floor_normal)
	set_floor_stop_on_slope_enabled(true)
	set_max_slides(5)
	set_floor_max_angle(0.85)
	move_and_slide()
	velocity = velocity


func calculate_cooldown():
	ledgedrop_cooldown = min(ledgedrop_cooldown + 1, ledgedrop_cooldown_max)
	roll_duration = min(roll_duration + 1, ROLL_DURATION)
	roll_cooldown = min(roll_cooldown + 1, ROLL_COOLDOWN)
	damage_duration = min(damage_duration + 1,DAMAGE_DURATION)


func change_orientation(ori):
	if(orientation != ori and ori != 0):
		orientation = ori
		body.scale.x *= -1

func calculate_jump(jump_height: int = JUMP_MAX_HEIGHT, _is_floor_jump: bool = false):
	jump_velocity = jump_height*-1
	$SFX/jump.play()
	pass

func apply_jump():
	jump = true
	calculate_jump()
	$SFX/jump.play()
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

func recieve_damage( dmg_points : int ):
	if damage == false and invinc_duration <= 0:
		damage = true
		life = max(life - dmg_points, 0)
		health_bar._damage(life)
		if life == 0 :
			game_over.set_visible(true)
		damage = false
		damage_duration = 0
		change_state(STATE.DAMAGE)
		invinc_duration = 1.5
		has_control = true
		gravity_on = true
		
func switch_spin_hit( value : bool ):
	$SpinHit.visible = value
	$SpinHit.monitoring = value
	pass


func _on_SpinHit_body_entered(body_entered):
	if body_entered.is_in_group("enemies"):
		body_entered.destroy()
	pass


# ---------- Setters/Getters ----------------------

func get_body():
	return $PlayerBody

func change_state(new_state):
	if new_state != state:
		last_state = state
		state = new_state

func get_state():
	return state

func get_orientation():
	return orientation

func set_in_cutscene(_new):
	in_cutscene = _new

func set_ctrl_pressed(_new):
	has_control = _new

func get_has_control():
	return has_control

func _get_camera():
	return $Camera2D

func set_gravity_force(_new):
	GRAVITY_FORCE = _new

func set_air_final_speed(_new):
	AIR_FINAL_SPEED = _new

func set_camera_current(_new):
	_get_camera().current = _new

func set_camera_position(_new):
	_get_camera().set_global_position(_new)

func get_camera_position():
	return _get_camera().get_global_position()

func set_camera_offset(offset):
	_get_camera().set_offset(offset)

func set_camera_zoom(zoom):
	_get_camera().set_zoom(zoom)

func change_blaster(blaster):
	$PlayerBody/Blasters.change_blaster(blaster, self)

func is_gravity_correct():
	return gravity == GRAVITY.DOWN

func checkpointed(new_position):
	print_debug("checkpointed")
	self.position = new_position
	change_blaster("bubble")

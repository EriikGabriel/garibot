class_name Player
extends CharacterBody2D

## Garibot: entrada, máquina de estados e movimento. Velocidades em px/s,
## durações em quadros de física. Cutscenes o controlam pelos métodos `cutscene_*`.

enum State { IDLE, MOVE, AIR, ROLL, DAMAGE }

const INVINCIBILITY_TIME := 1.5
## Quadros após sair de uma borda em que o pulo ainda é aceito.
const COYOTE_FRAMES := 10

@export var max_speed := 300
@export var cutscene_max_speed := 180
@export var floor_acceleration := 125
@export var air_acceleration := 75
## Velocidade do pulo curto (botão solto cedo) e do pulo completo.
@export var jump_min_speed := 300
@export var jump_max_speed := 750
@export var max_fall_speed := 700
@export var gravity_step := 30
@export var roll_speed := 1200
@export var roll_frames := 15
@export var roll_cooldown_frames := 50
@export var damage_frames := 15
@export var has_control := true

var in_cutscene := false
var state := State.IDLE
var orientation := 1
var move_velocity := 0.0
var jump_velocity := 0.0
## Lido pela animação "Magnet" do PlayerBody.
var magnet_on := false

var _dir := 0
var _jump := false
var _roll := false
var _gravity_on := true
var _coyote_frames := COYOTE_FRAMES
var _roll_frames := 0
var _roll_cooldown := 0
var _damage_frames := 0
var _invincible_time := 0.0
var _fading_out := true

var _cutscene_dir := 0
var _cutscene_jump := false
var _cutscene_roll := false

@onready var body: PlayerBody = $PlayerBody
@onready var bubble_point: Marker2D = $BubblePoint
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_roll_frames = roll_frames
	_roll_cooldown = roll_cooldown_frames
	_damage_frames = damage_frames
	max_slides = 5
	floor_max_angle = 0.85
	body.player = self
	Settings.setting_changed.connect(_on_setting_changed)
	_apply_reduced_motion(Settings.get_setting("reduced_motion", false))


func _physics_process(delta: float) -> void:
	_dir = 0
	_jump = false
	_roll = false
	if in_cutscene:
		_read_cutscene_input()
	elif has_control:
		_read_input()
	_tick_cooldowns()
	_update_state()
	_move()
	_update_invincibility(delta)
	_check_contact_damage()


func get_max_speed() -> int:
	return cutscene_max_speed if in_cutscene else max_speed


func change_orientation(direction: int) -> void:
	if direction != 0 and direction != orientation:
		orientation = direction
		body.scale.x *= -1


func cutscene_move(direction: int) -> void:
	_cutscene_dir = signi(direction)


func cutscene_stop() -> void:
	_cutscene_dir = 0


func cutscene_jump() -> void:
	if is_on_floor():
		_cutscene_jump = true


func cutscene_roll() -> void:
	if _roll_cooldown == roll_cooldown_frames:
		_cutscene_roll = true


func cutscene_face(direction: int) -> void:
	change_orientation(signi(direction))


func _read_input() -> void:
	if Input.is_action_just_pressed("move_up"):
		_jump = true
	if Input.is_action_just_released("move_up") and jump_velocity < -jump_min_speed:
		jump_velocity = -jump_min_speed
	_dir = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	change_orientation(_dir)
	if Input.is_action_just_pressed("attack") and _roll_cooldown == roll_cooldown_frames:
		_roll = true
		_roll_cooldown = 0


func _read_cutscene_input() -> void:
	_dir = _cutscene_dir
	change_orientation(_dir)
	if _cutscene_jump:
		_jump = true
		_cutscene_jump = false
	if _cutscene_roll and _roll_cooldown == roll_cooldown_frames:
		_roll = true
		_roll_cooldown = 0
		_cutscene_roll = false


func _tick_cooldowns() -> void:
	_coyote_frames = mini(_coyote_frames + 1, COYOTE_FRAMES)
	_roll_frames = mini(_roll_frames + 1, roll_frames)
	_roll_cooldown = mini(_roll_cooldown + 1, roll_cooldown_frames)
	_damage_frames = mini(_damage_frames + 1, damage_frames)


func _update_state() -> void:
	match state:
		State.IDLE:
			move_velocity = 0.0
			if not _start_ground_action() and _dir != 0:
				move_velocity = move_toward(
					move_velocity, get_max_speed() * _dir, floor_acceleration
				)
				state = State.MOVE
		State.MOVE:
			move_velocity = move_toward(move_velocity, get_max_speed() * _dir, floor_acceleration)
			if not _start_ground_action() and move_velocity == 0.0:
				state = State.IDLE
		State.AIR:
			move_velocity = move_toward(move_velocity, get_max_speed() * _dir, air_acceleration)
			if _jump and _coyote_frames < COYOTE_FRAMES:
				_start_jump()
			if _roll:
				_start_roll()
			if is_on_floor():
				_land()
		State.ROLL:
			_update_roll()
		State.DAMAGE:
			if not $SFX/Damage.playing:
				$SFX/Damage.play()
			if _damage_frames == damage_frames and not _start_ground_action():
				state = State.MOVE if _dir != 0 else State.IDLE


## Rolamento, pulo ou queda a partir do chão. Retorna true se mudou de estado.
func _start_ground_action() -> bool:
	if _roll:
		_start_roll()
	elif _jump:
		_start_jump()
		state = State.AIR
	elif not is_on_floor() and not is_on_wall():
		_coyote_frames = 0
		state = State.AIR
	else:
		return false
	return true


func _start_jump() -> void:
	jump_velocity = -jump_max_speed
	$SFX/Jump.play()


func _start_roll() -> void:
	_roll_frames = 0
	state = State.ROLL


func _land() -> void:
	jump_velocity = 1.0
	state = State.IDLE if move_velocity == 0.0 else State.MOVE


func _update_roll() -> void:
	move_velocity = roll_speed * orientation
	jump_velocity = 1.0
	has_control = false
	_gravity_on = false
	_set_spin_hit(true)
	if _roll_frames == roll_frames:
		_set_spin_hit(false)
		has_control = true
		_gravity_on = true
		if is_on_floor():
			_land()
		else:
			state = State.AIR
	if not $SFX/Roll.playing:
		$SFX/Roll.play()


func _move() -> void:
	if _gravity_on and state == State.AIR:
		jump_velocity = move_toward(jump_velocity, max_fall_speed, gravity_step)
	velocity = Vector2(move_velocity, jump_velocity)
	move_and_slide()


func _check_contact_damage() -> void:
	var collision := get_last_slide_collision()
	if collision == null or _invincible_time > 0.0:
		return
	var collider := collision.get_collider() as Node
	if collider and collider.is_in_group("DamageOnContact"):
		$HitboxComponent.damage((collider.get_node("ContactDamage") as ContactDamage).attack)
		_take_hit()


func _take_hit() -> void:
	_damage_frames = 0
	state = State.DAMAGE
	_invincible_time = INVINCIBILITY_TIME
	has_control = true
	_gravity_on = true


## Pisca o corpo enquanto o Garibot está invencível.
func _update_invincibility(delta: float) -> void:
	if _invincible_time <= 0.0:
		return
	_invincible_time -= delta
	if _invincible_time <= 0.0:
		body.modulate = Color.WHITE
		_fading_out = true
		return
	var alpha := body.modulate.a + (-25.0 if _fading_out else 25.0) * delta
	body.modulate.a = alpha
	if _fading_out and alpha <= 0.2:
		_fading_out = false
	elif not _fading_out and alpha >= 0.95:
		_fading_out = true


func _set_spin_hit(enabled: bool) -> void:
	$SpinHit.visible = enabled
	$SpinHit.monitoring = enabled


func _on_spin_hit_body_entered(other: Node2D) -> void:
	if other.is_in_group("enemies"):
		other.destroy()


func _on_setting_changed(setting_name: String, value: Variant) -> void:
	if setting_name == "reduced_motion":
		_apply_reduced_motion(value)


## Sem suavização, a câmera não persegue o personagem (menos desconforto).
func _apply_reduced_motion(enabled: bool) -> void:
	camera.position_smoothing_enabled = not enabled

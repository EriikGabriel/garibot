class_name ElectrolyteProjectile
extends Area2D

## Gota de eletrólito arremessada pela pilha corroída. Voa em arco; ao acertar o
## Garibot causa dano, e ao cair no chão vira uma poça ácida.

const PUDDLE_SCENE := preload("res://scenes/characters/enemies/acid_battery/acid_puddle.tscn")
## Camada "world" (cenário).
const WORLD_MASK := 8
## Normais com Y abaixo disso contam como chão (e não parede/teto).
const FLOOR_NORMAL_Y := -0.6

@export var gravity_force := 900.0
@export var max_lifetime := 4.0
@export var radius := 5.0
@export var color := Color("#b6e34a")

var velocity := Vector2.ZERO
var damage := 1.0
var puddle_lifetime := 3.0
var puddle_width := 44.0
var puddle_damage := 1.0

var _age := 0.0
var _done := false


func configure(
	initial_velocity: Vector2,
	hit_damage: float,
	lifetime_of_puddle: float,
	width_of_puddle: float,
	damage_of_puddle: float
) -> void:
	velocity = initial_velocity
	damage = hit_damage
	puddle_lifetime = lifetime_of_puddle
	puddle_width = width_of_puddle
	puddle_damage = damage_of_puddle


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_age += delta
	if _age >= max_lifetime:
		queue_free()
		return
	velocity.y += gravity_force * delta
	var motion := velocity * delta
	# Raio no trecho do quadro: evita atravessar o chão em alta velocidade.
	var query := PhysicsRayQueryParameters2D.create(
		global_position, global_position + motion, WORLD_MASK
	)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position += motion
		return
	global_position = hit.position
	var normal: Vector2 = hit.normal
	if normal.y <= FLOOR_NORMAL_Y:
		_spawn_puddle(hit.position)
	_finish()


func _on_body_entered(body: Node2D) -> void:
	if _done or not body is Player:
		return
	body.take_damage(damage, global_position)
	_finish()


func _spawn_puddle(at: Vector2) -> void:
	var puddle: AcidPuddle = PUDDLE_SCENE.instantiate()
	puddle.lifetime = puddle_lifetime
	puddle.width = puddle_width
	puddle.damage = puddle_damage
	get_parent().add_child(puddle)
	puddle.global_position = at


func _finish() -> void:
	_done = true
	set_deferred("monitoring", false)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_rect(Rect2(Vector2(-1, -3), Vector2(2, 2)), Color.WHITE)

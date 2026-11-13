class_name SmogPuff
extends Area2D

## Bolinha de fumaça lenta solta pela nuvem inchada. Anda em linha reta, machuca o
## Garibot ao encostar e some sozinha (ou ao tocar o chão).

## Camada "world" (cenário).
const WORLD_MASK := 8

@export var radius := 9.0
@export var lifetime := 4.0
@export var fade_time := 0.6
@export var color := Color("#5b5649")

var velocity := Vector2.ZERO
var damage := 1.0

var _age := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Garibot
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = radius * 0.8
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	var motion := velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + motion, WORLD_MASK)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		_age = maxf(_age, lifetime - fade_time)  # bateu no chão: desmancha
		velocity = Vector2.ZERO
	global_position += motion
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and _age < lifetime - fade_time:
		body.take_damage(damage, global_position, "fumaca")


func _draw() -> void:
	var alpha := clampf((lifetime - _age) / fade_time, 0.0, 1.0)
	var wobble := sin(_age * 7.0) * 1.5
	draw_circle(Vector2(-radius * 0.45, wobble), radius * 0.7, Color(color.darkened(0.25), alpha))
	draw_circle(Vector2(radius * 0.4, -wobble), radius * 0.75, Color(color.darkened(0.25), alpha))
	draw_circle(Vector2.ZERO, radius * 0.8, Color(color, alpha))
	draw_circle(Vector2(-radius * 0.3, -radius * 0.35), radius * 0.3, Color(color.lightened(0.35), alpha))

@tool
class_name Collectable
extends Area2D

@export var follow_speed: float = 100.0
@export var follow_distance: float = 32.0
@export var repel_radius: float = 24.0           # distância mínima entre coletáveis
@export var repel_strength: float = 0.5          # força da repulsão
@export var orbit_radius: float = 40.0           # raio do círculo ao redor do player
@export var orbit_speed: float = 2.0             # velocidade de rotação no círculo
@export var texture: Texture2D:
	set(value):
		texture = value
		if sprite:
			sprite.texture = texture

@onready var sprite: Sprite2D = $Sprite2D

var collected: bool = false
var player: Node2D = null
var orbit_angle: float = randf() * TAU

func _ready() -> void:
	add_to_group("collectables")

	if texture:
		sprite.texture = texture

	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		collected = true
		player = body
		set_deferred("monitoring", false) # evita erro de sinal bloqueado


func _process(delta: float) -> void:
	if not collected or not player:
		return

	var player_pos = player.global_position
	var player_velocity := Vector2.ZERO

	if "velocity" in player:
		player_velocity = player.velocity

	var moving = player_velocity.length() > 5.0

	if moving:
		_follow_player(delta)
	else:
		_orbit_around_player(delta)


func _follow_player(delta: float) -> void:
	var player_pos = player.global_position
	var dir = player_pos - global_position
	var distance = dir.length()

	if distance > follow_distance:
		dir = dir.normalized()

		# Oscilação sutil para o movimento parecer “flutuante”
		dir = dir.rotated(sin(Time.get_ticks_msec() / 500.0 + hash(self)) * 0.1)

		var step = dir * follow_speed * delta

		# Repulsão entre coletáveis
		var repel_force = Vector2.ZERO
		for other in get_tree().get_nodes_in_group("collectables"):
			if other == self or not other.collected:
				continue

			var diff = global_position - other.global_position
			var dist = diff.length()
			if dist < repel_radius and dist > 0.0:
				repel_force += diff.normalized() * (repel_radius - dist)

		global_position += step + repel_force * repel_strength * delta

func _orbit_around_player(delta: float) -> void:
	var collectables = get_tree().get_nodes_in_group("collectables").filter(func(c): return c.collected)
	var index = collectables.find(self)
	var total = collectables.size()

	if total == 0:
		return

	# distribui os itens igualmente em torno do círculo
	var angle_offset = TAU * index / total
	orbit_angle += orbit_speed * delta
	var angle = orbit_angle + angle_offset

	var target_pos = player.global_position + Vector2(cos(angle), sin(angle)) * orbit_radius

	# movimento suave e com velocidade máxima controlada
	var dir = target_pos - global_position
	var distance = dir.length()

	if distance > 1.0:
		var max_speed = follow_speed * 0.6   # limite de velocidade ao orbitar
		var step = dir.normalized() * min(distance, max_speed * delta)
		global_position += step

@tool
class_name Collectable
extends Area2D

@export var follow_speed: float = 100.0
@export var follow_distance: float = 32.0
@export var texture: Texture2D:
	set(value):
		texture = value
		if sprite:
			sprite.texture = texture

@onready var sprite: Sprite2D = $Sprite2D

var collected: bool = false
var player: Node2D = null

func _ready() -> void:
	# aplica no editor e em runtime
	if texture:
		sprite.texture = texture

	# conecta apenas em runtime
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		collected = true
		player = body
		monitoring = false

func _process(delta: float) -> void:
	if collected and player:
		var target_pos = player.global_position
		var dir = (target_pos - global_position)
		var distance = dir.length()

		if distance > follow_distance:
			var step = dir.normalized() * follow_speed * delta
			global_position += step

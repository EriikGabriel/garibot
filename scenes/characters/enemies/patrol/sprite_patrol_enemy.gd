@tool
class_name SpritePatrolEnemy
extends "res://scenes/characters/enemies/patrol/patrol_enemy.gd"

## Patrulha com sprite animado no lugar do placeholder (televisão, rolling steal...).
##
## Espera um nó `Body` (Node2D) com um `AnimatedSprite2D` chamado `Sprite`. A direção é
## trocada espelhando `Body.scale.x`, então o sprite pode ter deslocamento próprio
## (ex.: alinhar a roda ao centro) sem "pular" ao virar.

## Animação parado (esperando num ponto da rota).
@export var idle_animation := &"idle"
## Animação andando.
@export var move_animation := &"walk"
## Animação ao levar um golpe que não derrota (sem loop).
@export var hurt_animation := &"hurt"
## O desenho original olha para a esquerda (os dois sprites atuais olham).
@export var sprite_faces_left := true
## Velocidade mínima (px/s) para considerar que está andando.
@export var moving_threshold := 5.0

var _hurting := false

@onready var body := get_node_or_null("Body") as Node2D
@onready var sprite := get_node_or_null("Body/Sprite") as AnimatedSprite2D


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	if health:
		health.health_changed.connect(_on_health_changed)
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
	defeated.connect(_on_defeated)
	_apply_facing()


func _physics_process(delta: float) -> void:
	super(delta)
	if Engine.is_editor_hint() or _defeated or _hurting or sprite == null:
		return
	var moving := absf(velocity.x) > moving_threshold
	_play(move_animation if moving else idle_animation)


func face(direction: int) -> void:
	super(direction)
	_apply_facing()


func _apply_facing() -> void:
	if body == null:
		return
	var flip := facing > 0 if sprite_faces_left else facing < 0
	var scale_x := -1.0 if flip else 1.0
	# Só mexe quando muda, como o Garibot (`change_orientation`).
	if body.scale.x != scale_x:
		body.scale.x = scale_x


## Toca a animação só quando ela muda (replay a cada frame causa tremido).
func _play(animation: StringName) -> void:
	if sprite.animation != animation or not sprite.is_playing():
		sprite.play(animation)


func _on_health_changed(current: float, maximum: float) -> void:
	if current < maximum and current > 0.0 and sprite and sprite.sprite_frames.has_animation(hurt_animation):
		_hurting = true
		sprite.play(hurt_animation)


func _on_animation_finished() -> void:
	if sprite.animation == hurt_animation:
		_hurting = false


func _on_defeated() -> void:
	if sprite and sprite.sprite_frames.has_animation(hurt_animation):
		sprite.play(hurt_animation)


func _draw() -> void:
	# Sem placeholder: o sprite já mostra o inimigo. Só os guias da rota.
	if guides_visible():
		_draw_editor_guides()

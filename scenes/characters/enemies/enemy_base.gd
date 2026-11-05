@tool
class_name Enemy
extends CharacterBody2D

## Base de todos os inimigos: gravidade, dano por contato, vida e visual provisório.
##
## Subclasses implementam `_enemy_physics(delta)` (definindo `velocity`) e, se quiserem,
## `_draw_details()` para enfeitar o placeholder. Nós filhos esperados:
## `HealthComponent`, `HitboxComponent`, `ContactDamage` e `ContactArea` (Area2D que
## detecta o Garibot). O corpo fica na camada "enemies" e só colide com o cenário,
## então o Garibot atravessa o inimigo e leva dano pela `ContactArea`.
##
## No editor (@tool) nada de jogo roda: o inimigo só desenha o placeholder e os
## guias da subclasse (`_draw_editor_guides`). Subclasses que tenham limites
## ajustáveis expõem alças ao plugin "Garibot Enemy Tools" com `editor_handles()`,
## `editor_handle_properties()` e `editor_handle_moved()`.

signal defeated

@export_group("Física")
@export var uses_gravity := true
@export var gravity := 1200.0
@export var max_fall_speed := 700.0

@export_group("Combate")
## Nome do tipo de inimigo na telemetria (ex.: "patrulha").
@export var enemy_type := "inimigo"
## Empurrão ao levar um golpe que não derrota (px/s).
@export var hit_knockback := 160.0
@export var defeat_duration := 0.25

@export_group("Placeholder")
## Visual provisório até o inimigo ganhar sprite.
@export var placeholder_size := Vector2(24, 24)
@export var placeholder_color := Color("#c0504d")
@export var placeholder_outline := Color("#2b1414")

@export_group("Editor")
## Mostra os guias (rota, alcance) também durante o jogo, para depuração.
@export var show_guides_in_game := false
## Cor dos guias desenhados no editor.
@export var guide_color := Color(1.0, 0.82, 0.3, 0.9)

## 1 = olhando para a direita, -1 = para a esquerda.
var facing := -1
var _defeated := false
var _player: Player

@onready var health := get_node_or_null("HealthComponent") as HealthComponent
@onready var hitbox := get_node_or_null("HitboxComponent") as HitboxComponent
@onready var contact_damage := get_node_or_null("ContactDamage") as ContactDamage
@onready var contact_area := get_node_or_null("ContactArea") as Area2D


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	add_to_group("enemies")
	if health:
		health.died.connect(_defeat)
	_player = get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		# Reflete na hora mudanças feitas no Inspector ou pelas alças.
		queue_redraw()
		return
	if _defeated:
		return
	if uses_gravity and not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	_enemy_physics(delta)
	move_and_slide()
	_hurt_overlapping_player()


## Comportamento específico de cada inimigo; deve ajustar `velocity`.
func _enemy_physics(_delta: float) -> void:
	velocity.x = 0.0


## Golpe vindo do Garibot (rolamento). `from` é a posição de quem atacou.
func receive_attack(attack: Attack, from: Vector2) -> void:
	if _defeated:
		return
	if hitbox:
		hitbox.damage(attack)
	else:
		_defeat()
	if not _defeated:
		velocity.x = signf(global_position.x - from.x) * hit_knockback


func is_defeated() -> bool:
	return _defeated


## Garibot existe e pode levar dano agora (fora de diálogos, cutscenes e invencibilidade).
func player_is_targetable() -> bool:
	return is_instance_valid(_player) and _player.can_be_hurt()


func get_player() -> Player:
	return _player if is_instance_valid(_player) else null


func face(direction: int) -> void:
	if direction != 0 and direction != facing:
		facing = direction
		queue_redraw()


func _hurt_overlapping_player() -> void:
	if contact_area == null or contact_damage == null:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player:
			body.take_damage(contact_damage.attack.damage, global_position, enemy_type)


func _defeat() -> void:
	if _defeated:
		return
	_defeated = true
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	if contact_area:
		contact_area.set_deferred("monitoring", false)
	defeated.emit()
	Analytics.track("inimigo_derrotado", {"tipo": enemy_type, "x": roundi(global_position.x), "y": roundi(global_position.y)})
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.4, 0.2), defeat_duration)
	tween.tween_property(self, "modulate:a", 0.0, defeat_duration)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var rect := Rect2(-placeholder_size / 2.0, placeholder_size)
	draw_rect(rect, placeholder_color)
	draw_rect(rect, placeholder_outline, false, 2.0)
	# Olho no lado para onde o inimigo está virado, para ler a direção.
	var eye_x := placeholder_size.x * 0.25 * facing
	draw_rect(Rect2(Vector2(eye_x - 2.0, -placeholder_size.y * 0.2), Vector2(4, 4)), Color.WHITE)
	_draw_details(rect)
	if guides_visible():
		_draw_editor_guides()


## Guias aparecem no editor (ou no jogo, com `show_guides_in_game`).
func guides_visible() -> bool:
	return Engine.is_editor_hint() or show_guides_in_game


## Rota, alcance etc. (sobrescreva nas subclasses). Coordenadas locais ao inimigo.
func _draw_editor_guides() -> void:
	pass


## Detalhes extras do placeholder (sobrescreva nas subclasses).
func _draw_details(_rect: Rect2) -> void:
	pass

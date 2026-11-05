@tool
class_name AcidBatteryEnemy
extends "res://scenes/characters/enemies/enemy_base.gd"

## Pilha corroída: fica parada, mira no Garibot e arremessa eletrólito em arco.
## Onde a gota cai, forma uma poça ácida temporária (ver ElectrolyteProjectile).
##
## Ciclo: IDLE (procura o alvo) -> WINDUP (aviso visual) -> arremesso -> COOLDOWN.
##
## No editor o alcance aparece como um círculo a partir do ponto de arremesso;
## com a pilha selecionada, arraste a alça do círculo para mudar `detection_range`.

enum AttackState { IDLE, WINDUP, COOLDOWN }

const PROJECTILE_SCENE := preload(
	"res://scenes/characters/enemies/acid_battery/electrolyte_projectile.tscn"
)
## Camada "world" (cenário), usada para checar linha de visão.
const WORLD_MASK := 8
const MIN_DETECTION_RANGE := 32.0

@export_group("Alcance")
@export var detection_range := 340.0:
	set(value):
		detection_range = maxf(value, MIN_DETECTION_RANGE)
		queue_redraw()
## Não ataca se o cenário estiver entre a pilha e o Garibot.
@export var requires_line_of_sight := true

@export_group("Ataque")
## Aviso antes do arremesso (s), para a criança conseguir reagir.
@export var windup_time := 0.6
@export var attack_cooldown := 2.4
@export var projectile_damage := 1.0
## Mira nos pés do Garibot, onde a poça fará sentido.
@export var aim_offset := Vector2(0, 24)
## Tempo de voo por pixel de distância, limitado pelo intervalo abaixo.
@export var flight_time_per_px := 0.0035
@export var flight_time_range := Vector2(0.55, 1.1)

@export_group("Poça")
@export var puddle_lifetime := 3.0
@export var puddle_width := 44.0
@export var puddle_damage := 1.0

var attack_state := AttackState.IDLE
var _timer := 0.0

@onready var muzzle := get_node_or_null("Muzzle") as Marker2D


func _enemy_physics(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, hit_knockback * 4.0 * delta)
	var player := get_player()
	if player:
		face(int(signf(player.global_position.x - global_position.x)))
	_timer = maxf(_timer - delta, 0.0)
	match attack_state:
		AttackState.IDLE:
			if _can_attack():
				_set_attack_state(AttackState.WINDUP, windup_time)
		AttackState.WINDUP:
			if _timer <= 0.0:
				# O alvo pode ter entrado em diálogo/cutscene durante o aviso.
				if _can_attack():
					_throw_at(player.global_position + aim_offset)
				_set_attack_state(AttackState.COOLDOWN, attack_cooldown)
		AttackState.COOLDOWN:
			if _timer <= 0.0:
				_set_attack_state(AttackState.IDLE, 0.0)


func _can_attack() -> bool:
	if not player_is_targetable():
		return false
	var target := get_player().global_position
	if muzzle.global_position.distance_to(target) > detection_range:
		return false
	return not requires_line_of_sight or _has_line_of_sight(target)


func _has_line_of_sight(target: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(muzzle.global_position, target, WORLD_MASK)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Lança a gota num arco balístico que chega em `target` após o tempo de voo.
func _throw_at(target: Vector2) -> void:
	var projectile: ElectrolyteProjectile = PROJECTILE_SCENE.instantiate()
	var start := muzzle.global_position
	var offset := target - start
	var flight_time := clampf(
		offset.length() * flight_time_per_px, flight_time_range.x, flight_time_range.y
	)
	var launch_velocity := Vector2(
		offset.x / flight_time,
		offset.y / flight_time - 0.5 * projectile.gravity_force * flight_time
	)
	projectile.configure(
		launch_velocity, projectile_damage, puddle_lifetime, puddle_width, puddle_damage
	)
	# Na fase (e não na pilha), para a gota continuar se a pilha for derrotada.
	get_parent().add_child(projectile)
	projectile.global_position = start


func _set_attack_state(new_state: AttackState, duration: float) -> void:
	attack_state = new_state
	_timer = duration
	queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if attack_state == AttackState.WINDUP:
		queue_redraw()


func _draw_details(rect: Rect2) -> void:
	# Polo positivo e manchas de corrosão: lê como "pilha" mesmo sem sprite.
	draw_rect(Rect2(Vector2(-4, rect.position.y - 4), Vector2(8, 4)), Color("#9aa3a0"))
	draw_rect(Rect2(rect.position + Vector2(3, 4), Vector2(5, 4)), Color("#8bc34a"))
	draw_rect(Rect2(rect.end - Vector2(9, 9), Vector2(6, 5)), Color("#8bc34a"))
	if attack_state == AttackState.WINDUP:
		# Aviso: a pilha pisca antes de arremessar.
		var blink := int(_timer * 12.0) % 2 == 0
		if blink or Settings.get_setting("reduced_motion", false):
			draw_rect(rect.grow(3), Color("#d4ff4f"), false, 2.0)


func _muzzle_position() -> Vector2:
	return muzzle.position if muzzle else Vector2.ZERO


func _draw_editor_guides() -> void:
	var center := _muzzle_position()
	draw_circle(center, detection_range, Color(guide_color, 0.06))
	draw_arc(center, detection_range, 0.0, TAU, 96, guide_color, 2.0)
	var handle := center + Vector2(detection_range, 0)
	draw_dashed_line(center, handle, Color(guide_color, 0.6), 1.0, 5.0)
	draw_string(
		ThemeDB.fallback_font, handle + Vector2(6, -6), "alcance %d" % roundi(detection_range),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, guide_color
	)


# --- Alças do editor (plugin Garibot Enemy Tools) ---------------------------


func editor_handles() -> PackedVector2Array:
	return PackedVector2Array([_muzzle_position() + Vector2(detection_range, 0)])


func editor_handle_properties() -> PackedStringArray:
	return PackedStringArray(["detection_range"])


func editor_handle_moved(_index: int, local_position: Vector2) -> Dictionary:
	var radius := roundf(local_position.distance_to(_muzzle_position()))
	return {"detection_range": maxf(radius, MIN_DETECTION_RANGE)}

class_name BatterySummonAttack
extends BossAttack

## O chefe arremessa pilhas corroídas na arena.
## 1. Marca no chão onde cada pilha vai cair (longe do Garibot) e pisca o aviso.
## 2. Joga as pilhas em arco, de baixo do chefe até as marcas; ao cair, cada uma vira
##    uma `AcidBatteryEnemy` que age como as pilhas da fase.
## Nunca há mais de `max_alive` pilhas vivas ao mesmo tempo (contando as que estão no
## ar): com o limite cheio, `can_start` recusa e o chefe escolhe outro ataque.

const BATTERY_SCENE := preload(
	"res://scenes/characters/enemies/acid_battery/acid_battery_enemy.tscn"
)
## A origem da pilha fica no meio do corpo (32 px de altura).
const BATTERY_HALF_HEIGHT := 16.0

## Máximo de pilhas invocadas vivas na arena.
@export var max_alive := 2
## Quantas pilhas cada arremesso tenta jogar (limitado pelas vagas livres).
@export var per_summon := 2
## Tempo do aviso piscando antes do arremesso (s).
@export var warning_time := 0.9
## Tempo de voo de cada pilha (s).
@export var flight_time := 0.8
## Altura do arco acima do ponto mais alto do trajeto (px).
@export var arc_height := 50.0
## Intervalo entre uma pilha arremessada e a próxima (s).
@export var throw_interval := 0.25
## As pilhas nunca caem mais perto do Garibot do que isto (px).
@export var min_player_distance := 110.0
## Distância mínima entre duas pilhas (px).
@export var min_gap := 64.0
## Distância mínima das bordas da arena (px).
@export var edge_margin := 48.0
## Pilhas invocadas arremessam ácido com menos frequência que as da fase (s).
@export var battery_attack_cooldown := 3.2
## Tempo das pilhas sumindo quando o chefe é derrotado (s).
@export var dismiss_time := 0.5
@export var warning_color := Color("#d4ff4f")
@export var battery_color := Color("#5c6b55")
@export var outline_color := Color("#18252a")

## Pontos de queda (X global) marcados no chão.
var landing_spots: PackedFloat32Array = []

var _alive: Array[Enemy] = []
## Pilhas no ar: {"from": Vector2, "to": Vector2, "age": float}.
var _flights: Array[Dictionary] = []
var _time := 0.0


func _process(delta: float) -> void:
	if landing_spots.is_empty() and _flights.is_empty():
		return
	_time += delta
	for flight in _flights.duplicate():
		flight["age"] += delta
		if flight["age"] >= flight_time:
			_flights.erase(flight)
			_land(flight["to"])
	queue_redraw()


## Pilhas vivas ou a caminho (no ar).
func alive_count() -> int:
	_prune()
	return _alive.size() + _flights.size()


func can_start(_attacker: Node2D) -> bool:
	return alive_count() < max_alive


## Tira da arena as pilhas invocadas (vivas ou no ar), ex.: chefe derrotado.
func dismiss_summons() -> void:
	_flights.clear()
	landing_spots = PackedFloat32Array()
	queue_redraw()
	_prune()
	for battery in _alive:
		battery.set_physics_process(false)
		battery.set_process(false)
		battery.set_deferred("collision_layer", 0)
		if battery.contact_area:
			battery.contact_area.set_deferred("monitoring", false)
		if battery.hitbox:
			battery.hitbox.set_deferred("collision_layer", 0)
		var tween := create_tween()
		tween.tween_property(battery, "modulate:a", 0.0, 0.01 if reduced_motion() else dismiss_time)
		tween.tween_callback(battery.queue_free)
	_alive.clear()


func _perform() -> void:
	var count := mini(per_summon, max_alive - alive_count())
	if count <= 0:
		return
	landing_spots = _pick_spots(count)
	_time = 0.0
	if boss.has_method(&"set_mood"):
		boss.call(&"set_mood", &"attack")
	if not await wait(warning_time):
		return
	var floor_y: float = boss.get(&"arena_floor_y")
	for spot_x in landing_spots.duplicate():
		_throw(Vector2(spot_x, floor_y - BATTERY_HALF_HEIGHT))
		if not await wait(throw_interval):
			return
	# Espera a última pilha cair antes de devolver a vez ao chefe.
	await wait(flight_time)


func _cleanup() -> void:
	# Pilhas já arremessadas continuam o voo; só some o aviso das que não saíram.
	landing_spots = PackedFloat32Array()
	for flight in _flights:
		landing_spots.append(flight["to"].x)
	queue_redraw()
	if boss and boss.has_method(&"set_mood"):
		boss.call(&"set_mood", &"idle")


func _prune() -> void:
	_alive.assign(_alive.filter(_is_alive))


## Sem tipo no parâmetro: pilhas já liberadas não podem ser convertidas para `Enemy`.
static func _is_alive(battery: Variant) -> bool:
	return is_instance_valid(battery) and not (battery as Enemy).is_defeated()


## Escolhe pontos longe do Garibot e das outras pilhas (vivas ou no ar).
func _pick_spots(count: int) -> PackedFloat32Array:
	var left: float = boss.get(&"arena_left") + edge_margin
	var right: float = boss.get(&"arena_right") - edge_margin
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var taken: Array[float] = []
	for battery in _alive:
		taken.append(battery.global_position.x)
	for flight in _flights:
		taken.append(flight["to"].x)
	var picked := PackedFloat32Array()
	var tries := 0
	while picked.size() < count and tries < 60:
		tries += 1
		var x := randf_range(left, right)
		if player and absf(player.global_position.x - x) < min_player_distance:
			continue
		if taken.any(func(other: float) -> bool: return absf(other - x) < min_gap):
			continue
		picked.append(x)
		taken.append(x)
	# Arena apertada (ou azar): usa a borda mais longe do Garibot.
	if picked.is_empty():
		var far := right
		if player and player.global_position.x > (left + right) / 2.0:
			far = left
		picked.append(far)
	return picked


func _throw(target: Vector2) -> void:
	var from := boss.global_position
	if boss.has_method(&"get_bottom"):
		from = boss.call(&"get_bottom")
	_flights.append({"from": from, "to": target, "age": 0.0})


func _land(at: Vector2) -> void:
	var index := landing_spots.find(at.x)
	if index >= 0:
		landing_spots.remove_at(index)
	if boss == null or not is_instance_valid(boss):
		return
	var battery: AcidBatteryEnemy = BATTERY_SCENE.instantiate()
	battery.attack_cooldown = battery_attack_cooldown
	# Na arena (e não no chefe), como as gotas.
	boss.get_parent().add_child(battery)
	battery.global_position = at
	_alive.append(battery)


## Posição no arco (parábola) depois de `t` (0..1) do voo.
func _arc_point(from: Vector2, to: Vector2, t: float) -> Vector2:
	var peak := minf(from.y, to.y) - arc_height
	var x := lerpf(from.x, to.x, t)
	# Bezier quadrática com o ponto de controle acima do meio do trajeto.
	var control_y := 2.0 * peak - (from.y + to.y) / 2.0
	var y := (1.0 - t) * (1.0 - t) * from.y + 2.0 * (1.0 - t) * t * control_y + t * t * to.y
	return Vector2(x, y)


func _draw() -> void:
	if boss == null:
		return
	var floor_y: float = boss.get(&"arena_floor_y")
	var blink := 1.0 if reduced_motion() else 0.55 + 0.45 * sin(_time * 14.0)
	for spot_x in landing_spots:
		# Marca no chão e a silhueta da pilha que vai cair ali.
		draw_rect(Rect2(spot_x - 14.0, floor_y - 4.0, 28.0, 4.0), Color(warning_color, 0.8 * blink))
		var icon := Rect2(spot_x - 6.0, floor_y - 34.0, 12.0, 20.0)
		draw_rect(icon, Color(warning_color, blink), false, 2.0)
		draw_rect(Rect2(spot_x - 3.0, icon.position.y - 4.0, 6.0, 4.0), Color(warning_color, blink))
	for flight in _flights:
		var t := clampf(flight["age"] / flight_time, 0.0, 1.0)
		var at := _arc_point(flight["from"], flight["to"], t)
		var spin := 0.0 if reduced_motion() else t * TAU
		draw_set_transform(at, spin)
		draw_rect(Rect2(-7, -11, 14, 22), outline_color)
		draw_rect(Rect2(-5, -9, 10, 18), battery_color)
		draw_rect(Rect2(-3, -13, 6, 3), Color("#9aa3a0"))
	draw_set_transform(Vector2.ZERO)

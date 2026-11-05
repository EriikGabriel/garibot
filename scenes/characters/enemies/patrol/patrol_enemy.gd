@tool
class_name PatrolEnemy
extends "res://scenes/characters/enemies/enemy_base.gd"

## Patrulha: percorre, em ordem, os pontos de `patrol_points`.
##
## Os pontos são relativos à posição inicial do inimigo e ficam fixos no mapa ao
## iniciar (a rota não "anda junto"). No editor a rota aparece desenhada; com o
## inimigo selecionado, arraste as alças para mover os limites, clique no "+" de
## um trecho para inserir um ponto e clique com o botão direito num ponto para
## removê-lo (plugin Garibot Enemy Tools). Também dá para editar no Inspector.

enum RouteMode { LOOP, PING_PONG }

const MIN_POINTS := 2

## Pontos da rota, relativos ao inimigo. Patrulhas terrestres ignoram o Y.
@export var patrol_points := PackedVector2Array([Vector2(-80, 0), Vector2(80, 0)]):
	set(value):
		patrol_points = value
		queue_redraw()
@export var speed := 70.0
## Pausa em cada ponto da rota (s).
@export var wait_time := 0.6
@export var route_mode := RouteMode.PING_PONG:
	set(value):
		route_mode = value
		queue_redraw()
@export var arrive_distance := 4.0
## Patrulha voadora: segue também o eixo Y e ignora a gravidade.
@export var flying := false:
	set(value):
		flying = value
		queue_redraw()

var _points := PackedVector2Array()
var _target := 0
var _step := 1
var _wait_left := 0.0


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	if flying:
		uses_gravity = false
	for point in patrol_points:
		_points.append(global_position + _route_point(point))
	if _points.is_empty():
		push_warning("%s: patrulha sem pontos; ficará parada." % name)


func _enemy_physics(delta: float) -> void:
	if _points.is_empty():
		velocity.x = 0.0
		return
	if _wait_left > 0.0:
		_wait_left -= delta
		_stop()
		return
	var to_target := _points[_target] - global_position
	if not flying:
		to_target.y = 0.0
	# Parede no caminho de uma patrulha terrestre conta como chegada, para não travar.
	if to_target.length() <= arrive_distance or (not flying and is_on_wall()):
		_arrive()
		return
	var direction := to_target.normalized()
	velocity.x = direction.x * speed
	if flying:
		velocity.y = direction.y * speed
	if absf(direction.x) > 0.01:
		face(int(signf(direction.x)))


func _arrive() -> void:
	_stop()
	_wait_left = wait_time
	if _points.size() < 2:
		return
	match route_mode:
		RouteMode.LOOP:
			_target = (_target + 1) % _points.size()
		RouteMode.PING_PONG:
			if _target + _step < 0 or _target + _step >= _points.size():
				_step = -_step
			_target += _step


func _stop() -> void:
	velocity.x = 0.0
	if flying:
		velocity.y = 0.0


## Patrulha terrestre anda só no eixo X: o ponto fica na altura do inimigo.
func _route_point(point: Vector2) -> Vector2:
	return point if flying else Vector2(point.x, 0.0)


func _draw_details(rect: Rect2) -> void:
	# Faixa de "alerta" para diferenciar a patrulha no placeholder.
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 6), Vector2(rect.size.x, 4)), Color("#f2c14e"))


func _draw_editor_guides() -> void:
	var points := _guide_points()
	if points.size() >= 2:
		for i in points.size() - 1:
			_draw_dashed(points[i], points[i + 1])
		if route_mode == RouteMode.LOOP and points.size() > 2:
			_draw_dashed(points[-1], points[0])
	var font := ThemeDB.fallback_font
	for i in points.size():
		var p := points[i]
		draw_line(p + Vector2(0, -10), p + Vector2(0, 10), guide_color, 2.0)
		draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), guide_color)
		draw_string(font, p + Vector2(5, -8), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, guide_color)


## Pontos da rota em coordenadas locais. No jogo o inimigo anda, então a rota
## (fixa no mapa) é convertida a partir das posições globais guardadas no _ready.
func _guide_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	if Engine.is_editor_hint() or _points.is_empty():
		for point in patrol_points:
			points.append(_route_point(point))
	else:
		for point in _points:
			# Terrestre: a rota acompanha a altura atual (o inimigo pode ter caído ao nascer).
			points.append(_route_point(to_local(point)))
	return points


func _draw_dashed(from: Vector2, to: Vector2) -> void:
	draw_dashed_line(from, to, Color(guide_color, guide_color.a * 0.8), 2.0, 6.0)
	# Seta no meio do trecho indicando o sentido da patrulha.
	var mid := (from + to) / 2.0
	var dir := (to - from).normalized()
	if dir == Vector2.ZERO:
		return
	var side := dir.orthogonal() * 4.0
	draw_colored_polygon(PackedVector2Array([mid + dir * 5.0, mid - dir * 3.0 + side, mid - dir * 3.0 - side]), guide_color)


# --- Alças do editor (plugin Garibot Enemy Tools) ---------------------------


func editor_handles() -> PackedVector2Array:
	var handles := PackedVector2Array()
	for point in patrol_points:
		handles.append(_route_point(point))
	return handles


func editor_handle_properties() -> PackedStringArray:
	return PackedStringArray(["patrol_points"])


func editor_handle_moved(index: int, local_position: Vector2) -> Dictionary:
	var points := patrol_points.duplicate()
	points[index] = _route_point(local_position.round())
	return {"patrol_points": points}


func editor_insert_point(after_index: int, local_position: Vector2) -> Dictionary:
	var points := patrol_points.duplicate()
	points.insert(after_index + 1, _route_point(local_position.round()))
	return {"patrol_points": points}


func editor_remove_point(index: int) -> Dictionary:
	if patrol_points.size() <= MIN_POINTS:
		return {}
	var points := patrol_points.duplicate()
	points.remove_at(index)
	return {"patrol_points": points}

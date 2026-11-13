class_name HealingPlant
extends Area2D

## Canteiro de planta curativa (placeholder desenhado, sem sprite).
##
## Estados: DORMANT (só a semente) → READY (broto brilhando, com seta: "encoste aqui")
## → GROWING → GROWN. No READY, o Garibot encosta (ou passa de dash) e a planta cresce
## como uma trepadeira até `target` (a nuvem), terminando enrolada nela.
## Quem controla a luta chama `activate()` e escuta `grown`.

signal grown

enum PlantState { DORMANT, READY, GROWING, GROWN }

@export var grow_time := 1.4
## Largura/altura da área de toque do canteiro (px).
@export var touch_size := Vector2(30, 34)
@export var soil_color := Color("#6b4a32")
@export var stem_color := Color("#3f8f4a")
@export var leaf_color := Color("#7fcf6a")
@export var glow_color := Color("#d8ff8a")
@export var outline_color := Color("#18252a")
## Espaço entre folhas ao longo do caule (px).
@export var leaf_spacing := 16.0

var state := PlantState.DORMANT
## Ponto onde a trepadeira termina (normalmente a nuvem).
var target: Node2D
## Deslocamento a partir de `target` (ex.: a borda da nuvem do lado desta planta).
var target_offset := Vector2.ZERO
## 0..1 enquanto cresce.
var growth := 0.0:
	set(value):
		growth = value
		queue_redraw()

var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Garibot
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = touch_size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -touch_size.y / 2.0)
	add_child(collision)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Deixa o broto pronto para ser tocado.
func activate() -> void:
	if state != PlantState.DORMANT:
		return
	state = PlantState.READY
	# O Garibot pode já estar em cima do canteiro.
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func is_ready_to_grow() -> bool:
	return state == PlantState.READY


func is_grown() -> bool:
	return state == PlantState.GROWN


func _on_body_entered(body: Node2D) -> void:
	if state != PlantState.READY or not body is Player:
		return
	state = PlantState.GROWING
	GameAudio.play_sound(&"correct")
	var duration := 0.01 if bool(Settings.get_setting("reduced_motion", false)) else grow_time
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "growth", 1.0, duration)
	tween.tween_callback(_on_grown)


func _on_grown() -> void:
	state = PlantState.GROWN
	grown.emit()


# --- Desenho -------------------------------------------------------------------------


func _draw() -> void:
	_draw_soil()
	match state:
		PlantState.DORMANT:
			draw_rect(Rect2(-2, -6, 4, 3), soil_color.darkened(0.4))  # semente
		PlantState.READY:
			_draw_ready_sprout()
		_:
			_draw_vine()


func _draw_soil() -> void:
	draw_rect(Rect2(-17, -5, 34, 6), outline_color)
	draw_rect(Rect2(-16, -4, 32, 4), soil_color)
	draw_rect(Rect2(-12, -6, 24, 2), soil_color.lightened(0.15))


func _draw_ready_sprout() -> void:
	var still := bool(Settings.get_setting("reduced_motion", false))
	var pulse := 0.6 if still else 0.5 + 0.5 * sin(_time * 5.0)
	# Brilho no chão e coluna de luz: "aqui!"
	draw_circle(Vector2(0, -8), 14.0 + 3.0 * pulse, Color(glow_color, 0.25 + 0.2 * pulse))
	draw_rect(Rect2(-6, -60, 12, 54), Color(glow_color, 0.12 + 0.1 * pulse))
	# Broto com duas folhas
	draw_line(Vector2(0, -4), Vector2(0, -14), stem_color, 3.0)
	_draw_leaf(Vector2(0, -12), -1.0, 7.0)
	_draw_leaf(Vector2(0, -14), 1.0, 7.0)
	# Seta pulando acima do broto
	var bob := 0.0 if still else sin(_time * 6.0) * 3.0
	var tip := Vector2(0, -30 + bob)
	var arrow := PackedVector2Array([tip, tip + Vector2(-6, -8), tip + Vector2(6, -8)])
	draw_colored_polygon(arrow, glow_color)
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[0]]), outline_color, 1.0)


## Trepadeira do canteiro até a nuvem, numa curva que balança de leve.
func _draw_vine() -> void:
	var end := Vector2(0, -60)
	if is_instance_valid(target):
		end = to_local(target.global_position + target_offset)
	var sway := 0.0 if bool(Settings.get_setting("reduced_motion", false)) else sin(_time * 1.6) * 6.0
	var control := Vector2(end.x * 0.2 + 18.0 * signf(end.x if end.x != 0.0 else 1.0) + sway, end.y * 0.55)
	var points := PackedVector2Array()
	var steps := 24
	var visible_steps := maxi(1, roundi(steps * growth))
	for i in visible_steps + 1:
		var t := float(i) / steps
		points.append(_bezier(Vector2(0, -4), control, end, t))
	draw_polyline(points, outline_color, 6.0)
	draw_polyline(points, stem_color, 4.0)
	# Folhas alternando de lado ao longo do caule
	var length := 0.0
	var side := 1.0
	for i in range(1, points.size()):
		length += points[i].distance_to(points[i - 1])
		if length >= leaf_spacing:
			length = 0.0
			_draw_leaf(points[i], side, 8.0)
			side = -side
	# Ponta: folhinha enrolando
	if growth >= 1.0:
		_draw_leaf(end, side, 10.0)


func _draw_leaf(at: Vector2, side: float, size: float) -> void:
	var leaf := PackedVector2Array(
		[at, at + Vector2(side * size * 0.6, -size * 0.7), at + Vector2(side * size, -size * 0.1)]
	)
	draw_colored_polygon(leaf, leaf_color)
	draw_polyline(PackedVector2Array([leaf[0], leaf[1], leaf[2], leaf[0]]), outline_color, 1.0)


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)

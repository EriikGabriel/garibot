class_name AcidPuddle
extends Area2D

## Poça ácida deixada pelo eletrólito. Machuca o Garibot enquanto ele estiver
## sobre ela (a invencibilidade do Player evita dano a cada quadro) e some após
## `lifetime` segundos, esmaecendo no final.

@export var lifetime := 3.0
@export var fade_time := 0.6
@export var damage := 1.0
@export var width := 44.0
## Altura da área de dano acima do chão (alcança os pés do Garibot).
@export var hurt_height := 10.0
@export var color := Color(0.6, 0.85, 0.2, 0.85)

var _age := 0.0


func _ready() -> void:
	# A forma depende da largura configurada pela gota, por isso é criada aqui.
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, hurt_height)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -hurt_height / 2.0)
	add_child(collision)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body is Player:
			body.take_damage(damage, global_position, "poca_acida")
	queue_redraw()


func _draw() -> void:
	var alpha := clampf((lifetime - _age) / fade_time, 0.0, 1.0)
	var tint := Color(color, color.a * alpha)
	draw_rect(Rect2(Vector2(-width / 2.0, -4), Vector2(width, 4)), tint)
	draw_rect(Rect2(Vector2(-width / 2.0 + 4, -6), Vector2(width - 8, 2)), tint)
	# Bolhas fixas, sem animação (respeita movimento reduzido).
	var bubble := Color(Color("#e8ff9a"), alpha)
	draw_rect(Rect2(Vector2(-width * 0.25, -7), Vector2(2, 2)), bubble)
	draw_rect(Rect2(Vector2(width * 0.15, -8), Vector2(2, 2)), bubble)

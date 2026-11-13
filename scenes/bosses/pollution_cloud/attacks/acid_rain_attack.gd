class_name AcidRainAttack
extends BossAttack

## Chuva ácida que pinga de baixo do chefe.
## 1. O chefe voa até ficar em cima do Garibot (`set_anchor`) e para ali.
## 2. Uma faixa no chão, embaixo dele, pisca como aviso.
## 3. Gotas caem da parte de baixo do chefe, só dentro da faixa; onde caem, ficam poças.
## Reaproveita a gota e a poça da pilha corroída (ElectrolyteProjectile/AcidPuddle).

const DROP_SCENE := preload(
	"res://scenes/characters/enemies/acid_battery/electrolyte_projectile.tscn"
)

## Tempo para o chefe chegar em cima do Garibot (s).
@export var aim_time := 0.8
## Tempo do aviso piscando antes da chuva (s).
@export var warning_time := 1.0
## A faixa é a largura do chefe mais esta folga de cada lado (px).
@export var zone_padding := 10.0
@export var drop_count := 9
@export var drop_interval := 0.12
@export var drop_speed := 40.0
@export var damage := 1.0
@export var puddle_lifetime := 1.6
@export var puddle_width := 28.0
@export var warning_color := Color("#d4ff4f")

var _warning := false
var _time := 0.0


func _process(delta: float) -> void:
	if running:
		_time += delta
		queue_redraw()


func _perform() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and boss.has_method(&"set_anchor"):
		boss.call(&"set_anchor", player.global_position.x)
	if boss.has_method(&"set_mood"):
		boss.call(&"set_mood", &"attack")
	if not await wait(aim_time):
		return
	_warning = true
	_time = 0.0
	if not await wait(warning_time):
		return
	_warning = false
	var half := _zone_half_width()
	for _drop in drop_count:
		var bottom := _bottom()
		_spawn_drop(bottom + Vector2(randf_range(-half, half), 0))
		if not await wait(drop_interval):
			return
	_release_boss()


func _cleanup() -> void:
	_warning = false
	_release_boss()
	if boss and boss.has_method(&"set_mood"):
		boss.call(&"set_mood", &"idle")


func _release_boss() -> void:
	if boss and boss.has_method(&"clear_anchor"):
		boss.call(&"clear_anchor")


func _bottom() -> Vector2:
	if boss.has_method(&"get_bottom"):
		return boss.call(&"get_bottom")
	return boss.global_position


func _zone_half_width() -> float:
	var size: Variant = boss.get(&"body_size")
	var width: float = size.x if size is Vector2 else 48.0
	return width / 2.0 + zone_padding


func _spawn_drop(at: Vector2) -> void:
	var drop: ElectrolyteProjectile = DROP_SCENE.instantiate()
	drop.configure(Vector2(0, drop_speed), damage, puddle_lifetime, puddle_width, damage)
	boss.get_parent().add_child(drop)
	drop.global_position = at


func _draw() -> void:
	if not _warning or boss == null:
		return
	var floor_y: float = boss.get(&"arena_floor_y")
	var bottom := _bottom()
	var half := _zone_half_width()
	var blink := 1.0 if reduced_motion() else 0.55 + 0.45 * sin(_time * 14.0)
	# Faixa no chão e coluna clarinha ligando o chefe ao chão.
	var strip := Rect2(bottom.x - half, floor_y - 4.0, half * 2.0, 4.0)
	draw_rect(strip, Color(warning_color, 0.8 * blink))
	var column := Rect2(bottom.x - half, bottom.y, half * 2.0, floor_y - bottom.y)
	draw_rect(column, Color(warning_color, 0.08 + 0.06 * blink))
	# Gotinhas penduradas embaixo do chefe.
	for i in 3:
		var drop_at := bottom + Vector2((i - 1) * half * 0.6, 4.0 + (i % 2) * 4.0)
		draw_circle(drop_at, 3.0, Color(warning_color, blink))

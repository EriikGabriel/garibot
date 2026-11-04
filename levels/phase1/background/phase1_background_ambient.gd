@tool
extends Sprite2D
class_name Phase1BackgroundAmbient

## Animação de ambiente do fundo (fumaça, rotor eólico, pássaros).
## Aparece só na versão suja ou só na limpa, acompanhando o degrau do objeto.
@export var fps := 8.0
@export var start_frame := 0
## Degrau de restauração do objeto (0 = acompanha o progresso de forma gradual).
@export_range(0.0, 1.0, 0.05) var restore_step := 0.0
@export var visible_when_clean := false
## Movimento próprio (pássaros), oscilando dentro de drift_range.
@export var drift := Vector2.ZERO
@export var drift_range := 0.0

var _time := 0.0
var _origin := Vector2.ZERO

func _ready() -> void:
	_origin = position
	frame = start_frame % maxi(1, hframes * vframes)

func update_ambient(progress: float, delta: float, animate: bool) -> void:
	var restored := Phase1Background.restore_factor(progress, restore_step)
	modulate.a = restored if visible_when_clean else 1.0 - restored
	visible = modulate.a > 0.01
	if not visible or not animate:
		return
	_time += delta
	frame = (start_frame + int(_time * fps)) % maxi(1, hframes * vframes)
	if drift != Vector2.ZERO and drift_range > 0.0:
		var travel := fposmod(_time * drift.length(), drift_range * 2.0)
		var range_offset := travel if travel < drift_range else drift_range * 2.0 - travel
		position = _origin + drift.normalized() * range_offset
		flip_h = travel >= drift_range

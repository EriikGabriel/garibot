class_name BackgroundAmbient
extends Sprite2D

## Animação de ambiente (fumaça, rotor, pássaros) que aparece só na versão suja
## ou só na limpa, acompanhando o degrau do objeto a que pertence.

@export var fps := 8.0
@export var start_frame := 0
## 0 = acompanha o progresso; 0.2…1.0 = troca no 1º…5º REEE.
@export_range(0.0, 1.0, 0.05) var restore_step := 0.0
@export var visible_when_clean := false
## Voo de ida e volta (pássaros) dentro de drift_range.
@export var drift := Vector2.ZERO
@export var drift_range := 0.0

var _time := 0.0
@onready var _origin := position


func _ready() -> void:
	frame = start_frame % (hframes * vframes)
	_on_progress(0.0)
	RestorationProgress.connect_to(self, _on_progress)


func _process(delta: float) -> void:
	if not visible or Settings.get_setting("reduced_motion", false):
		return
	_time += delta
	frame = (start_frame + int(_time * fps)) % (hframes * vframes)
	if drift != Vector2.ZERO and drift_range > 0.0:
		var travel := fposmod(_time * drift.length(), drift_range * 2.0)
		var range_offset := travel if travel < drift_range else drift_range * 2.0 - travel
		position = _origin + drift.normalized() * range_offset
		flip_h = travel >= drift_range


func _on_progress(shown: float) -> void:
	var restored := RestorationProgress.restore_factor(shown, restore_step)
	modulate.a = restored if visible_when_clean else 1.0 - restored
	visible = modulate.a > 0.01

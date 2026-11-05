class_name BatteryHealthHud
extends Control

## Vida do Garibot como uma pilha animada no canto superior direito.
##
## Usa a folha `battery_hud.png` (níveis de carga 0..5 x `frames_per_level` quadros,
## em sequência horizontal: nível * quadros + quadro). Ao perder carga, uma faísca
## aparece sobre a barrinha perdida; ao recuperar, as barrinhas enchem uma a uma.
## Arte gerada por tools/ui/build_battery_hud.py (fonte em assets/sprites/ui/hud/aseprite).

const SHEET := preload("res://assets/sprites/ui/hud/battery_hud.png")
const SPARK_SHEET := preload("res://assets/sprites/ui/hud/battery_hud_spark.png")
## Geometria da arte (pixels da folha), usada para posicionar a faísca.
const FRAME_SIZE := Vector2i(60, 22)
const SPARK_SIZE := Vector2i(12, 16)
const SPARK_FRAMES := 4
const FIRST_SEGMENT_X := 13
const SEGMENT_STEP := 7
const SEGMENT_Y := 5

@export var pixel_scale := 3
@export var margin := Vector2(20, 18)
@export var frames_per_level := 8
@export var frame_duration := 0.11
## Intervalo entre o brilho de uma passada e a próxima (s), para não cansar a vista.
@export var glint_pause := 1.6
@export var spark_frame_duration := 0.07
## Tempo para encher cada barrinha ao recuperar carga (s).
@export var refill_step := 0.12
@export var announce_changes := true

var charge := 5
var capacity := 5

## Carga exibida; acompanha `charge` com animação ao recuperar.
var _shown := 5
var _time := 0.0
var _refill_left := 0.0
var _spark_time := -1.0
var _spark_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Settings.setting_changed.connect(_on_setting_changed)


## Atualiza a carga (vida atual e máxima, em barrinhas).
func set_charge(value: int, maximum: int) -> void:
	value = clampi(value, 0, maximum)
	capacity = maximum
	if value < charge:
		_shown = value
		_spark_index = value
		_spark_time = 0.0
		if announce_changes:
			Speech.speak(_announcement(value, maximum))
	charge = value
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _shown < charge:
		_refill_left -= delta
		if _refill_left <= 0.0:
			_shown += 1
			_refill_left = refill_step
	if _spark_time >= 0.0:
		_spark_time += delta
		if _spark_time >= spark_frame_duration * SPARK_FRAMES:
			_spark_time = -1.0
	queue_redraw()


func _announcement(value: int, maximum: int) -> String:
	if value == 0:
		return "Bateria descarregada!"
	if value == 1:
		return "Bateria fraca! Resta 1 de %d." % maximum
	return "Bateria: %d de %d." % [value, maximum]


func _current_frame() -> int:
	if Settings.get_setting("reduced_motion", false):
		# Quadro parado e sem brilho (no nível 1 e 0 é a versão acesa).
		return 0
	var cycle := frame_duration * frames_per_level
	# Níveis altos: o brilho passa e depois espera; níveis críticos piscam sem pausa.
	var period := cycle if _shown <= 1 else cycle + glint_pause
	var t := fmod(_time, period)
	return mini(int(t / frame_duration), frames_per_level - 1)


func _draw() -> void:
	var level := clampi(_shown, 0, frames_per_level - 1)
	var scaled := Vector2(FRAME_SIZE) * pixel_scale
	var origin := Vector2(size.x - margin.x - scaled.x, margin.y)
	var index := level * frames_per_level + _current_frame()
	var region := Rect2(Vector2(index * FRAME_SIZE.x, 0), Vector2(FRAME_SIZE))
	draw_texture_rect_region(SHEET, Rect2(origin, scaled), region)
	if _spark_time >= 0.0 and _spark_index >= 0:
		var spark_frame := mini(int(_spark_time / spark_frame_duration), SPARK_FRAMES - 1)
		var center_x := FIRST_SEGMENT_X + _spark_index * SEGMENT_STEP + 3
		var spark_pos := Vector2(center_x - SPARK_SIZE.x / 2.0, SEGMENT_Y - 2)
		draw_texture_rect_region(
			SPARK_SHEET,
			Rect2(origin + spark_pos * pixel_scale, Vector2(SPARK_SIZE) * pixel_scale),
			Rect2(Vector2(spark_frame * SPARK_SIZE.x, 0), Vector2(SPARK_SIZE))
		)


func _on_setting_changed(setting_name: String, _value: Variant) -> void:
	if setting_name == "reduced_motion":
		queue_redraw()

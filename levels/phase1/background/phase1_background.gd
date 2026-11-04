@tool
extends Node2D
class_name Phase1Background

## Fundo em parallax da Fase 1. Cada camada (céu, nuvens, longe, meio, perto)
## tem versão suja e limpa; `progress` (0 a 1) acompanha os REEE recolhidos.
## A arte e as máscaras ficam em assets/sprites/backgrounds/phase1/aseprite.

## Prévia no editor: arraste para ver a fase ficando limpa.
@export_range(0.0, 1.0, 0.01) var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		_set_shown(progress)
## Prévia no editor: centro de câmera simulado para alinhar as camadas.
@export var editor_camera_center := Vector2(160, 0)
@export var transition_time := 1.8
const STEP_SOFTNESS := 0.2

var _shown := 0.0
var _tween: Tween
var _materials: Array[ShaderMaterial] = []
var _layers: Array[Phase1ParallaxLayer] = []
var _ambient: Array[Phase1BackgroundAmbient] = []

static func restore_factor(value: float, step: float) -> float:
	if step <= 0.0:
		return value
	return smoothstep(step - STEP_SOFTNESS, step, value)

func _ready() -> void:
	process_priority = 100  # depois da câmera
	add_to_group("phase1_background")
	_collect(self)
	_set_shown(progress)

func _collect(node: Node) -> void:
	for child in node.get_children():
		if child is Phase1ParallaxLayer:
			_layers.append(child)
		if child is Phase1BackgroundAmbient:
			_ambient.append(child)
		elif child is CanvasItem and child.material is ShaderMaterial:
			_materials.append(child.material)
		_collect(child)

## Atualiza o progresso de limpeza. Com animate, os objetos se restauram em sequência.
func set_progress(value: float, animate := true) -> void:
	value = clampf(value, 0.0, 1.0)
	if _tween:
		_tween.kill()
	if not animate or not is_inside_tree():
		progress = value
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_shown, _shown, value, transition_time)
	_tween.tween_callback(func() -> void: progress = value)

## Progresso exibido no momento (inclui a transição animada).
func shown_progress() -> float:
	return _shown

func _set_shown(value: float) -> void:
	_shown = value
	for mat in _materials:
		mat.set_shader_parameter("progress", value)

func _process(delta: float) -> void:
	var center := editor_camera_center
	if not Engine.is_editor_hint():
		var camera := get_viewport().get_camera_2d()
		if camera == null:
			return
		center = camera.get_screen_center_position()
	var animate := not _reduced_motion()
	for layer in _layers:
		layer.follow(center, delta, animate)
	for item in _ambient:
		item.update_ambient(_shown, delta, animate)

func _reduced_motion() -> bool:
	if Engine.is_editor_hint():
		return false
	var settings := get_node_or_null("/root/Settings")
	return settings != null and bool(settings.get_setting("reduced_motion", false))

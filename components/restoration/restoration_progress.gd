class_name RestorationProgress
extends Node

## Progresso de limpeza do cenário: 0 = poluído, 1 = recuperado.
## A arte restaurável escuta `shown_changed`, que acompanha `value` com uma transição.

signal shown_changed(shown: float)

const GROUP := &"restoration_progress"
const BLEND_SHADER := preload("res://components/restoration/restoration_blend.gdshader")
const STEP_SOFTNESS := 0.2

@export var transition_time := 1.8

var value := 0.0
var shown := 0.0

var _tween: Tween


## Conecta `callback(shown)` ao progresso da cena atual e já o chama com o valor inicial.
static func connect_to(node: Node, callback: Callable) -> RestorationProgress:
	var progress := node.get_tree().get_first_node_in_group(GROUP) as RestorationProgress
	if progress:
		progress.shown_changed.connect(callback)
		callback.call(progress.shown)
	return progress


## Quanto um objeto está restaurado. Com `step` 0 ele acompanha o progresso;
## com 0.2…1.0 ele se restaura dentro desse degrau (1º…5º REEE).
static func restore_factor(progress: float, step: float) -> float:
	if step <= 0.0:
		return progress
	return smoothstep(step - STEP_SOFTNESS, step, progress)


static func create_material(clean_texture: Texture2D, mask: Texture2D = null) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = BLEND_SHADER
	material.set_shader_parameter("clean_texture", clean_texture)
	material.set_shader_parameter("progress_mask", mask)
	material.set_shader_parameter("use_mask", mask != null)
	return material


func _enter_tree() -> void:
	add_to_group(GROUP)


func set_value(new_value: float, animate := true) -> void:
	value = clampf(new_value, 0.0, 1.0)
	if _tween:
		_tween.kill()
	if not animate:
		_set_shown(value)
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_shown, shown, value, transition_time)


func _set_shown(new_shown: float) -> void:
	shown = new_shown
	shown_changed.emit(shown)

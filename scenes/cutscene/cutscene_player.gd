class_name CutscenePlayer
extends Node

## Diretor de cutscenes: executa `steps` em ordem, controlando o Garibot como se fosse o jogador.
##
## Passos aceitos (o campo "type" é obrigatório):
##   {"type": "bars_on", "speed": 0.3}           barras de cinema entram
##   {"type": "bars_off", "speed": 0.3}          barras saem
##   {"type": "wait", "seconds": 1.0}
##   {"type": "walk", "dir": 1, "duration": 1.5}
##   {"type": "stop"}
##   {"type": "face", "dir": -1}
##   {"type": "jump"}
##   {"type": "roll", "dir": 1}
##   {"type": "animation", "name": "hello", "speed": 1.0, "duration": 1.0}
##   {"type": "say", "timeline": "res://dialogic/..."}   espera o diálogo terminar
##   {"type": "signal"}                          só emite `step_reached`
##
## No passo "say", se a cena pai tiver `start_dialogue(timeline)`, ela abre o diálogo.

signal started
signal finished
signal step_reached(step: Dictionary, index: int)

const DEFAULT_BAR_TIME := 0.4
const GARIBOT_CHARACTER := "res://dialogic/characters/garibot.dch"

@export_storage var steps: Array[Dictionary] = []
@export var player_path: NodePath
@export_range(48.0, 120.0, 4.0) var cinematic_bar_height := 84.0

var _player: Player
var _index := 0
var _active := false
var _bars_before_dialog := false
var _bar_tween: Tween

@onready var _bar_layer := _create_bar_layer()
@onready var _bar_top: ColorRect = _bar_layer.get_child(0)
@onready var _bar_bottom: ColorRect = _bar_layer.get_child(1)


func run() -> void:
	_player = get_node_or_null(player_path) as Player
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	if _player == null:
		push_warning("CutscenePlayer: nenhum Player encontrado.")
		finished.emit()
		return
	_active = true
	_index = 0
	_player.in_cutscene = true
	_player.has_control = false
	_player.cutscene_stop()
	started.emit()
	_advance()


func is_running() -> bool:
	return _active


func _advance() -> void:
	if _index >= steps.size():
		_finish()
		return
	var step := steps[_index]
	_index += 1
	step_reached.emit(step, _index - 1)
	match step.get("type", ""):
		"bars_on":
			_animate_bars(true, step, _advance)
		"bars_off":
			_animate_bars(false, step, _advance)
		"wait":
			_after(step.get("seconds", 1.0), _advance)
		"walk":
			_player.cutscene_move(step.get("dir", 1))
			_after(step.get("duration", 1.0), _on_walk_done)
		"stop":
			_player.cutscene_stop()
			_advance()
		"face":
			_player.cutscene_face(step.get("dir", 1))
			_advance()
		"jump":
			_player.cutscene_jump()
			_after(0.35, _advance)
		"roll":
			_player.cutscene_face(step.get("dir", 1))
			_player.cutscene_roll()
			_after(0.5, _advance)
		"animation":
			_player.body.play_cutscene_animation(step.get("name", "hello"), step.get("speed", 1.0))
			_after(step.get("duration", 1.0), _on_animation_done)
		"say":
			_play_dialog(step.get("timeline", ""))
		"signal":
			_advance()
		var unknown:
			push_warning("CutscenePlayer: passo desconhecido '%s'." % unknown)
			_advance()


func _on_walk_done() -> void:
	_player.cutscene_stop()
	_advance()


func _on_animation_done() -> void:
	_player.body.stop_cutscene_animation()
	_advance()


func _play_dialog(timeline: String) -> void:
	if timeline.is_empty():
		_advance()
		return
	# Só um passo "bars_off" explícito esconde as barras que já estavam na tela.
	_bars_before_dialog = _bar_top.visible
	Dialogic.timeline_ended.connect(_on_dialog_done, CONNECT_ONE_SHOT)
	if get_parent().has_method("start_dialogue"):
		get_parent().start_dialogue(timeline)
		return
	Settings.apply_dialogue_settings()
	var layout: Node = Dialogic.Styles.load_style("bubbles")
	if layout and layout.has_method("register_character"):
		layout.register_character(load(GARIBOT_CHARACTER), _player.bubble_point)
	Dialogic.start(timeline)


func _on_dialog_done() -> void:
	_restore_bars_after_dialog()
	_advance()


func _finish() -> void:
	_restore_bars_after_dialog()
	_player.cutscene_stop()
	_player.body.stop_cutscene_animation()
	_player.in_cutscene = false
	_player.has_control = true
	_active = false
	finished.emit()


func _after(seconds: float, callback: Callable) -> void:
	get_tree().create_timer(maxf(seconds, 0.0)).timeout.connect(callback)


# Barras de cinema ---------------------------------------------------------------


func _create_bar_layer() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "CinematicBars"
	layer.layer = 100
	for preset in [Control.PRESET_TOP_WIDE, Control.PRESET_BOTTOM_WIDE]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.set_anchors_preset(preset)
		bar.hide()
		layer.add_child(bar)
	add_child(layer)
	return layer


func _animate_bars(show: bool, step: Dictionary, on_finished: Callable) -> void:
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill()
	if show:
		_set_bars_shown(false)
		_bar_top.show()
		_bar_bottom.show()
	elif not _bar_top.visible:
		_on_bars_done(false, on_finished)
		return
	var duration := _bar_time(step)
	if duration <= 0.0:
		_set_bars_shown(show)
		_on_bars_done(show, on_finished)
		return
	var height := cinematic_bar_height
	_bar_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC)
	_bar_tween.set_ease(Tween.EASE_OUT if show else Tween.EASE_IN)
	_bar_tween.tween_property(_bar_top, "offset_top", 0.0 if show else -height, duration)
	_bar_tween.tween_property(_bar_top, "offset_bottom", height if show else 0.0, duration)
	_bar_tween.tween_property(_bar_bottom, "offset_top", -height if show else 0.0, duration)
	_bar_tween.tween_property(_bar_bottom, "offset_bottom", 0.0 if show else height, duration)
	_bar_tween.finished.connect(_on_bars_done.bind(show, on_finished))


func _set_bars_shown(shown: bool) -> void:
	var height := cinematic_bar_height
	_bar_top.offset_top = 0.0 if shown else -height
	_bar_top.offset_bottom = height if shown else 0.0
	_bar_bottom.offset_top = -height if shown else 0.0
	_bar_bottom.offset_bottom = 0.0 if shown else height


func _on_bars_done(shown: bool, on_finished: Callable) -> void:
	_bar_tween = null
	if not shown:
		_bar_top.hide()
		_bar_bottom.hide()
	on_finished.call()


func _restore_bars_after_dialog() -> void:
	_set_bars_shown(_bars_before_dialog)
	_bar_top.visible = _bars_before_dialog
	_bar_bottom.visible = _bars_before_dialog
	_bars_before_dialog = false


func _bar_time(step: Dictionary) -> float:
	if Settings.get_setting("reduced_motion", false):
		return 0.0
	return maxf(step.get("speed", DEFAULT_BAR_TIME), 0.0)

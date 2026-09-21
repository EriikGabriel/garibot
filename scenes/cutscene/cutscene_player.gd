class_name CutscenePlayer
extends Node

## Modular cutscene director.
##
## Add this node to a level, fill `steps` with an array of instruction
## dictionaries, and call `run()`. It temporarily takes control away from
## Garibot (driving him like a player), plays optional cinematic black bars,
## raw animations and Dialogic dialogs, then restores control.
##
## Supported step types (a valid `type` is required for every step):
##   {"type": "bars_on",  "speed": 0.3}                 # fade cinematic black bars in
##   {"type": "bars_off", "speed": 0.3}                 # fade black bars out
##   {"type": "wait", "seconds": 1.0}                   # do nothing for N seconds
##   {"type": "walk", "dir": 1, "duration": 1.5}        # move Garibot in a direction for N seconds
##   {"type": "stop"}                                   # stop walking
##   {"type": "face", "dir": -1}                        # turn Garibot to face a direction
##   {"type": "jump"}                                   # make Garibot jump (if on floor)
##   {"type": "roll", "dir": 1}                         # make Garibot dash/roll in a direction
##   {"type": "animation", "name": "hello", "duration": 1.0}  # play a raw body animation for N seconds
##   {"type": "say", "timeline": "res://dialogic/...dl"}      # play a Dialogic dialog and wait for it
##   {"type": "signal"}                                # emit the `step_reached` signal
##
## Example:
##   steps = [
##       {"type": "bars_on", "speed": 0.3},
##       {"type": "walk", "dir": 1, "duration": 1.5},
##       {"type": "jump"},
##       {"type": "roll", "dir": 1},
##       {"type": "say", "timeline": "res://dialogic/timelines/teste/teste.dtl"},
##       {"type": "bars_off", "speed": 0.3},
##   ]

signal step_reached(step: Dictionary, index: int)
signal finished

@export_storage var steps: Array[Dictionary] = []

@export var player_path: NodePath = NodePath("")

## Dialogic character resource shown in the speech bubble during "say" steps.
## Defaults to the game's garibot character when left empty.
@export var character_resource: Resource = null

var _player: Player
var _index: int = 0
var _active: bool = false
var _bar_layer: CanvasLayer
var _bar_top: ColorRect
var _bar_bottom: ColorRect

const _BAR_HEIGHT := 140.0
const _DEFAULT_BAR_SPEED := 0.4


func _ready():
	_ensure_bars()


func run() -> void:
	_resolve_player()
	if _player == null:
		push_warning("CutscenePlayer: no player found, cannot run.")
		finished.emit()
		return

	_active = true
	_index = 0
	_player.in_cutscene = true
	_player.has_control = false
	_player.cutscene_stop()
	_advance()


func is_running() -> bool:
	return _active


func _advance() -> void:
	if _index >= steps.size():
		_finish()
		return

	var step: Dictionary = steps[_index]
	_index += 1
	step_reached.emit(step, _index - 1)

	match step.get("type", ""):
		"bars_on":
			_set_bars_visibility(true, step)
			_await(_bar_time(step), _advance)
		"bars_off":
			_set_bars_visibility(false, step)
			_await(_bar_time(step), _advance)
		"wait":
			_await(float(step.get("seconds", 1.0)), _advance)
		"walk":
			_player.cutscene_move(int(step.get("dir", 1)))
			_await(float(step.get("duration", 1.0)), _on_walk_done)
		"stop":
			_player.cutscene_stop()
			_advance()
		"face":
			_player.cutscene_face(int(step.get("dir", 1)))
			_advance()
		"jump":
			_player.cutscene_jump()
			_await(0.35, _advance)
		"roll":
			_player.cutscene_face(int(step.get("dir", 1)))
			_player.cutscene_roll()
			_await(0.5, _advance)
		"animation":
			var name: String = step.get("name", "hello")
			var speed: float = step.get("speed", 1.0)
			_player.body.play_cutscene_animation(name, speed)
			_await(float(step.get("duration", 1.0)), _on_animation_done)
		"say":
			_play_dialog(String(step.get("timeline", "")))
		"signal":
			_advance()
		_:
			push_warning("CutscenePlayer: unknown step type '%s'" % step.get("type", ""))
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
	if get_parent().is_in_group("phase1_level"):
		if not Dialogic.timeline_ended.is_connected(_on_dialog_done):
			Dialogic.timeline_ended.connect(_on_dialog_done)
		Phase1Dialogue.start(timeline, get_parent())
		return
	if not Dialogic.timeline_ended.is_connected(_on_dialog_done):
		Dialogic.timeline_ended.connect(_on_dialog_done)

	# Apply accessibility settings (font size, text speed, etc.) as the normal
	# dialog triggers do, so the cutscene speech matches the player's prefs.
	Settings.apply_setting("dialog_font_size", Settings.get_setting("dialog_font_size", 18))
	Settings.apply_setting("text_speed", Settings.get_setting("text_speed", 1.0))
	Settings.apply_setting("skip_on_click", Settings.get_setting("skip_on_click", true))

	# Show the speech in a bubble attached to the player's bubble/dialog point,
	# replicating how the in-game DialogTrigger links Dialogic to the character.
	var char_res: Resource = character_resource
	if char_res == null:
		char_res = load("res://dialogic/characters/garibot.dch")

	var bubble_point: Node2D = null
	if _player != null:
		bubble_point = _player.get_node_or_null("bubble_point")
		if bubble_point == null:
			bubble_point = _player.dialog_point

	if bubble_point != null and char_res != null:
		var bubble_layout: Node = Dialogic.Styles.load_style("bubbles")
		if bubble_layout != null and bubble_layout.has_method("register_character"):
			bubble_layout.register_character(char_res, bubble_point)

	Dialogic.start(timeline)


func _on_dialog_done() -> void:
	if Dialogic.timeline_ended.is_connected(_on_dialog_done):
		Dialogic.timeline_ended.disconnect(_on_dialog_done)
	_advance()


func _finish() -> void:
	_player.cutscene_stop()
	_player.body.stop_cutscene_animation()
	_player.in_cutscene = false
	_player.has_control = true
	_active = false
	finished.emit()


# ---- Black bars ----

func _ensure_bars() -> void:
	if _bar_layer != null:
		return
	_bar_layer = CanvasLayer.new()
	_bar_layer.layer = 100
	_bar_layer.name = "CinematicBars"

	_bar_top = ColorRect.new()
	_bar_top.color = Color.BLACK
	_bar_top.anchor_left = 0.0
	_bar_top.anchor_top = 0.0
	_bar_top.anchor_right = 1.0
	_bar_top.anchor_bottom = 0.0
	_bar_top.offset_top = 0.0
	_bar_top.offset_bottom = _BAR_HEIGHT

	_bar_bottom = ColorRect.new()
	_bar_bottom.color = Color.BLACK
	_bar_bottom.anchor_left = 0.0
	_bar_bottom.anchor_top = 1.0
	_bar_bottom.anchor_right = 1.0
	_bar_bottom.anchor_bottom = 1.0
	_bar_bottom.offset_top = -_BAR_HEIGHT
	_bar_bottom.offset_bottom = 0.0

	_bar_layer.add_child(_bar_top)
	_bar_layer.add_child(_bar_bottom)
	add_child(_bar_layer)

	_bar_top.visible = false
	_bar_bottom.visible = false


func _set_bars_visibility(show: bool, step: Dictionary) -> void:
	_ensure_bars()
	# Bars appear/disappear instantly (kept simple and headless-safe).
	# The step's "speed" just paces how long the camera/bars settle.
	_bar_top.visible = show
	_bar_bottom.visible = show


func _bar_time(step: Dictionary) -> float:
	# Give a moment for the bar transition to read visually.
	return step.get("speed", _DEFAULT_BAR_SPEED)


# ---- Helpers ----

func _resolve_player() -> void:
	if is_instance_valid(_player):
		return
	var p = get_node_or_null(player_path) if not player_path.is_empty() else null
	if p is Player:
		_player = p
		return
	var in_group = get_tree().get_first_node_in_group("player")
	if in_group is Player:
		_player = in_group


func _await(duration: float, callback: Callable) -> void:
	var timer := get_tree().create_timer(maxf(duration, 0.0))
	timer.timeout.connect(func():
		if callback.is_valid():
			callback.call()
	)

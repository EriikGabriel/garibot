extends Node
## Áudio persistente: os recursos e volumes podem ser editados na cena.
@export var sounds: Dictionary = {}
@export var voices: Dictionary = {}
@export_range(0.05, 0.5, 0.01) var navigation_interval := 0.09

@onready var music: AudioStreamPlayer = $Music
@onready var ui: AudioStreamPlayer = $UI
@onready var feedback: AudioStreamPlayer = $Feedback
@onready var voice: AudioStreamPlayer = $Voice
var _last_navigation_ms := -1000

func _ready() -> void:
	# Só a cópia usada por este player entra em loop.
	if music.stream:
		music.stream = music.stream.duplicate()
		music.stream.set("loop", true)
		music.play()
	get_tree().node_added.connect(_on_node_added)
	_connect_dialogue.call_deferred()

func play_sound(cue: StringName) -> void:
	var stream: AudioStream = sounds.get(cue)
	if stream == null:
		return
	var target := ui if String(cue).begins_with("ui_") else feedback
	target.stream = stream
	target.play()

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_bind_button.call_deferred(node)

func _bind_button(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.has_meta("game_audio_bound"):
		return
	button.set_meta("game_audio_bound", true)
	button.mouse_entered.connect(_navigate.bind(button))
	button.focus_entered.connect(_navigate.bind(button))
	button.button_down.connect(_activate.bind(button))

func _navigate(button: BaseButton) -> void:
	if button.disabled or not button.is_visible_in_tree():
		return
	var now := Time.get_ticks_msec()
	if now - _last_navigation_ms < navigation_interval * 1000:
		return
	_last_navigation_ms = now
	play_sound(&"ui_move")

func _activate(button: BaseButton) -> void:
	if button.disabled:
		return
		
	# Respostas têm feedback próprio
	if button.has_meta("audio_cue"):
		play_sound(StringName(button.get_meta("audio_cue")))
	elif button.name in ["Previous", "Return", "Resume", "MainMenu", "Skip"]:
		play_sound(&"ui_back")
	elif button.name == "Jogar":
		play_sound(&"ui_start")
	else:
		play_sound(&"ui_select")

func _connect_dialogue() -> void:
	if not Dialogic.has_subsystem("Text"):
		return
	Dialogic.Text.text_started.connect(_on_text_started)
	Dialogic.Text.text_finished.connect(_on_text_finished)
	Dialogic.timeline_ended.connect(voice.stop)

func _on_text_started(info: Dictionary) -> void:
	voice.stop()
	var character: Resource = info.get("character")
	if character == null:
		return
	var character_name := character.resource_path.get_file().get_basename()
	var stream: AudioStream = voices.get(character_name)
	if stream:
		voice.stream = stream
		voice.play()

func _on_text_finished(_info: Dictionary) -> void:
	voice.stop()

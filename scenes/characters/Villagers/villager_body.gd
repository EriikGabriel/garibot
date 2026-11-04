@tool
extends Node2D
class_name VillagerBody

## Corpo animado de morador. Parado: respira e mexe as mãos. Falando: gesticula
## e mexe a boca enquanto o Dialogic revela a fala dele ou toca a dublagem.
## O rosto (olhos e boca) é um sprite separado que acompanha o balanço da cabeça.

enum Mouth { SAD, SMILE, HALF, OPEN, ROUND }
const IDLE_FRAMES := 8
const TALK_FRAMES := 8
const TALK_MOUTHS: Array[int] = [Mouth.HALF, Mouth.OPEN, Mouth.HALF, Mouth.ROUND, Mouth.OPEN, Mouth.SAD, Mouth.HALF, Mouth.OPEN]

## Personagem do Dialogic que controla a boca (ex.: res://dialogic/characters/morador.dch).
@export_file("*.dch") var dialogic_character := ""
## Deslocamento vertical do rosto em cada quadro do corpo (respiração).
@export var face_bob := PackedInt32Array()
@export var idle_fps := 5.0
@export var talk_fps := 8.0
@export var mouth_fps := 11.0
## Expressão feliz (sobrancelhas relaxadas e sorriso). A fase liga quando a vila se recupera.
@export var happy := false
## 1 = olha para a direita, -1 = esquerda.
@export var facing := 1:
	set(value):
		facing = 1 if value >= 0 else -1
		scale.x = facing
## Prévia no editor da animação de fala.
@export var preview_talking := false

var _time := 0.0
var _blink_wait := 3.0
var _blink_left := 0.0
var _speaker_is_me := false
var _revealing := false
var _voice := false
var _was_talking := false
@onready var _body: Sprite2D = $Corpo
@onready var _eyes: Sprite2D = $Olhos
@onready var _mouth: Sprite2D = $Boca
@onready var _eyes_base := _eyes.position
@onready var _mouth_base := _mouth.position

func _ready() -> void:
	_time = randf() * 4.0  # moradores lado a lado não respiram em sincronia
	_blink_wait = randf_range(1.5, 4.0)
	if Engine.is_editor_hint() or get_node_or_null("/root/Dialogic") == null:
		return
	Dialogic.Text.about_to_show_text.connect(_on_about_to_show_text)
	Dialogic.Text.text_started.connect(_on_text_started)
	Dialogic.Text.text_finished.connect(_on_text_finished)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	if Dialogic.has_subsystem("Voice"):
		Dialogic.Voice.voiceline_started.connect(_on_voice_started)
		Dialogic.Voice.voiceline_finished.connect(_on_voice_ended)
		Dialogic.Voice.voiceline_stopped.connect(_on_voice_ended)

func is_talking() -> bool:
	if Engine.is_editor_hint():
		return preview_talking
	return _speaker_is_me and (_revealing or _voice)

func _process(delta: float) -> void:
	var talking := is_talking()
	if talking != _was_talking:
		_was_talking = talking
		_time = 0.0
	_time += delta
	var still := _reduced_motion()
	var frame_index := 0
	if talking:
		frame_index = IDLE_FRAMES + (0 if still else int(_time * talk_fps) % TALK_FRAMES)
	elif not still:
		frame_index = int(_time * idle_fps) % IDLE_FRAMES
	_body.frame = frame_index
	var bob := face_bob[frame_index] if frame_index < face_bob.size() else 0
	_eyes.position = _eyes_base + Vector2(0, bob)
	_mouth.position = _mouth_base + Vector2(0, bob)

	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_left = 0.12
		_blink_wait = randf_range(2.0, 5.0)
	_blink_left = maxf(0.0, _blink_left - delta)
	_eyes.frame = (2 if happy else 0) + (1 if _blink_left > 0.0 else 0)

	if talking:
		_mouth.frame = TALK_MOUTHS[int(_time * mouth_fps) % TALK_MOUTHS.size()]
	else:
		_mouth.frame = Mouth.SMILE if happy else Mouth.SAD

func _reduced_motion() -> bool:
	if Engine.is_editor_hint():
		return false
	var settings := get_node_or_null("/root/Settings")
	return settings != null and bool(settings.get_setting("reduced_motion", false))

func _on_about_to_show_text(info: Dictionary) -> void:
	var character: Resource = info.get("character")
	_speaker_is_me = character != null and character.resource_path == dialogic_character
	_revealing = false
	_voice = false

func _on_text_started(_info: Dictionary) -> void:
	_revealing = _speaker_is_me

func _on_text_finished(_info: Dictionary) -> void:
	_revealing = false

func _on_voice_started(_info: Dictionary) -> void:
	_voice = _speaker_is_me

func _on_voice_ended(_info: Dictionary) -> void:
	_voice = false

func _on_timeline_ended() -> void:
	_speaker_is_me = false
	_revealing = false
	_voice = false

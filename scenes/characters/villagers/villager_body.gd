class_name VillagerBody
extends Node2D

## Corpo animado de morador. Parado: respira e mexe as mãos. Falando: gesticula e
## mexe a boca enquanto o Dialogic revela a fala deste personagem ou toca a dublagem dele.
## Olhos e boca são sprites separados que acompanham o balanço da cabeça (`face_bob`).

enum Mouth { SAD, SMILE, HALF, OPEN, ROUND }

const IDLE_FRAMES := 8
const TALK_FRAMES := 8
const TALK_MOUTHS: Array[int] = [
	Mouth.HALF, Mouth.OPEN, Mouth.HALF, Mouth.ROUND, Mouth.OPEN, Mouth.SAD, Mouth.HALF, Mouth.OPEN
]
const BLINK_TIME := 0.12

@export_file("*.dch") var dialogic_character := ""
## Deslocamento vertical do rosto em cada quadro do corpo.
@export var face_bob := PackedInt32Array()
@export var idle_fps := 5.0
@export var talk_fps := 8.0
@export var mouth_fps := 11.0
## Sobrancelhas relaxadas e sorriso (a vila recuperada).
@export var happy := false
## 1 = olha para a direita, -1 = esquerda.
@export var facing := 1:
	set(value):
		facing = 1 if value >= 0 else -1
		scale.x = facing

var _time := 0.0
var _blink_wait := 0.0
var _blink_left := 0.0
var _was_talking := false
var _speaker_is_me := false
var _revealing := false
var _voice_playing := false

@onready var _body: Sprite2D = $BodySprite
@onready var _eyes: Sprite2D = $Eyes
@onready var _mouth: Sprite2D = $Mouth
@onready var _eyes_base := _eyes.position
@onready var _mouth_base := _mouth.position


func _ready() -> void:
	_time = randf() * 4.0  # moradores lado a lado não respiram em sincronia
	_blink_wait = randf_range(1.5, 4.0)
	Dialogic.Text.about_to_show_text.connect(_on_about_to_show_text)
	Dialogic.Text.text_started.connect(_on_text_started)
	Dialogic.Text.text_finished.connect(_on_text_finished)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	if Dialogic.has_subsystem("Voice"):
		Dialogic.Voice.voiceline_started.connect(_on_voice_started)
		Dialogic.Voice.voiceline_finished.connect(_on_voice_ended)
		Dialogic.Voice.voiceline_stopped.connect(_on_voice_ended)


func is_talking() -> bool:
	return _speaker_is_me and (_revealing or _voice_playing)


func _process(delta: float) -> void:
	var talking := is_talking()
	if talking != _was_talking:
		_was_talking = talking
		_time = 0.0
	_time += delta
	_update_body(talking)
	_update_eyes(delta)
	if talking:
		_mouth.frame = TALK_MOUTHS[int(_time * mouth_fps) % TALK_MOUTHS.size()]
	else:
		_mouth.frame = Mouth.SMILE if happy else Mouth.SAD


func _update_body(talking: bool) -> void:
	var still: bool = Settings.get_setting("reduced_motion", false)
	var frame := 0
	if talking:
		frame = IDLE_FRAMES + (0 if still else int(_time * talk_fps) % TALK_FRAMES)
	elif not still:
		frame = int(_time * idle_fps) % IDLE_FRAMES
	_body.frame = frame
	var bob := Vector2(0, face_bob[frame] if frame < face_bob.size() else 0)
	_eyes.position = _eyes_base + bob
	_mouth.position = _mouth_base + bob


func _update_eyes(delta: float) -> void:
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_left = BLINK_TIME
		_blink_wait = randf_range(2.0, 5.0)
	_blink_left = maxf(0.0, _blink_left - delta)
	_eyes.frame = (2 if happy else 0) + (1 if _blink_left > 0.0 else 0)


func _on_about_to_show_text(info: Dictionary) -> void:
	var character: Resource = info.get("character")
	_speaker_is_me = character != null and character.resource_path == dialogic_character
	_revealing = false
	_voice_playing = false


func _on_text_started(_info: Dictionary) -> void:
	_revealing = _speaker_is_me


func _on_text_finished(_info: Dictionary) -> void:
	_revealing = false


func _on_voice_started(_info: Dictionary) -> void:
	_voice_playing = _speaker_is_me


func _on_voice_ended(_info: Dictionary) -> void:
	_voice_playing = false


func _on_timeline_ended() -> void:
	_speaker_is_me = false
	_revealing = false
	_voice_playing = false

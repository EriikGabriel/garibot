@tool
extends Node2D

const PHASE1_MINIGAMES := preload("res://levels/phase1/minigames/phase1_minigames/phase1_minigames.tscn")
@export var fall_reset_y := 380.0

var _reee_count := 0
var _intro_finished := false
var _learned_walk := false
var _learned_jump := false
var _reee_total := 0
var _phase_completed := false
var _pending_tutorial_speech := false
var _last_narrated_tutorial := ""
var _conclusion_dialogue_active := false
var _conclusion_started := false
var _minigames_active := false
var _zone_index := 0
var _dialogue_active := false
@onready var objective_label: Label = $HUD/Objective
@onready var tutorial_label: Label = $HUD/Tutorial
@onready var hud_panels = $HUD/PixelPanels
@onready var player: Player = $Player
@onready var reee_cutscene: CutscenePlayer = $ReeeCutscene
@onready var intro_cutscene: CutscenePlayer = $CutscenePlayer

func _ready() -> void:
	if Engine.is_editor_hint():
		$HUD.hide()
		return
	$HUD.show()
	add_to_group("phase1_level")
	Settings.setting_changed.connect(_on_accessibility_setting_changed)
	_apply_accessibility_preferences()
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = -300
	camera.limit_right = 5400
	camera.limit_top = -650
	camera.limit_bottom = 380
	var items := get_tree().get_nodes_in_group("phase1_reee")
	_reee_total = items.size()
	$World.reee_total = _reee_total
	for item in items:
		item.monitoring = false
		item.collected.connect(_on_reee_collected)
	for npc in [get_node("Garidog"), get_node("CorreioBo"), get_node("Morador")]:
		npc.get_node("TalkArea").monitoring = false
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	intro_cutscene.started.connect(_on_cinematic_started)
	intro_cutscene.finished.connect(_on_intro_finished)
	reee_cutscene.started.connect(_on_cinematic_started)
	reee_cutscene.finished.connect(_resume_tutorial)
	_set_tutorial_visible(false)
	_update_hud()
	intro_cutscene.run()

func _on_accessibility_setting_changed(setting_name: String, _value: Variant) -> void:
	if setting_name in ["high_contrast", "dialog_font_size"]:
		_apply_accessibility_preferences()

func _apply_accessibility_preferences() -> void:
	var high_contrast := bool(Settings.get_setting("high_contrast", false))
	var font_size := int(Settings.get_setting("dialog_font_size", 18))
	objective_label.add_theme_font_size_override("font_size", maxi(17, font_size))
	tutorial_label.add_theme_font_size_override("font_size", maxi(18, font_size))
	var foreground := Color.WHITE if high_contrast else Color("#f5edca")
	objective_label.add_theme_color_override("font_color", foreground)
	tutorial_label.add_theme_color_override("font_color", foreground)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not _intro_finished or _tutorial_blocked():
		return
	if not _learned_walk and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
		_learned_walk = true
		_update_hud()
	if _learned_walk and not _learned_jump and Input.is_action_just_pressed("move_up"):
		_learned_jump = true
		_update_hud()
	var zone := 0
	for marker in $Flow.get_children():
		if player.position.x >= marker.position.x:
			zone = marker.get_index()
	if zone != _zone_index:
		_zone_index = zone
		_update_hud()
	if not _conclusion_started and _reee_count == _reee_total and player.position.x >= $Flow/Finish.position.x and player.is_on_floor():
		_begin_conclusion()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not _intro_finished:
		return
	if player.position.y > fall_reset_y:
		# A margem segura permite tentar de novo e voltar para buscar itens perdidos.
		player.position = $RiverCheckpoint.position
		player.velocity = Vector2.ZERO
		player.move_velocity = 0
		player.jump_velocity = 0
		player.get_node("Camera2D").reset_smoothing()

func _on_intro_finished() -> void:
	_intro_finished = true
	for item in get_tree().get_nodes_in_group("phase1_reee"):
		item.set_deferred("monitoring", true)
	for npc in [get_node("Garidog"), get_node("CorreioBo"), get_node("Morador")]:
		npc.get_node("TalkArea").set_deferred("monitoring", true)
	_resume_tutorial()

func _on_cinematic_started() -> void:
	Speech.stop()
	_pending_tutorial_speech = true
	_last_narrated_tutorial = ""
	_set_tutorial_visible(false)

func _on_dialogue_started() -> void:
	_dialogue_active = true
	player.has_control = false
	_on_cinematic_started()

func _on_dialogue_ended() -> void:
	_dialogue_active = false
	# O Dialogic e a cutscene terminam sua limpeza antes de retomar o HUD.
	_resume_tutorial.call_deferred()

func _tutorial_blocked() -> bool:
	return not _intro_finished or intro_cutscene.is_running() or reee_cutscene.is_running() or _dialogue_active or _conclusion_dialogue_active or _minigames_active

func _set_tutorial_visible(value: bool) -> void:
	tutorial_label.visible = value
	hud_panels.set_tutorial_visible(value)

func _resume_tutorial() -> void:
	if _tutorial_blocked():
		return
	player.has_control = true
	_set_tutorial_visible(true)
	_update_hud()
	_narrate_tutorial_when_ready()

func _on_reee_collected(_item_name: String) -> void:
	GameAudio.play_sound(&"collect")
	_reee_count += 1
	$World.register_reee()
	if _reee_count == 1:
		reee_cutscene.run()
	_update_hud()

func _begin_conclusion() -> void:
	_conclusion_started = true
	_conclusion_dialogue_active = true
	player.position = $FinishPoint.position
	player.velocity = Vector2.ZERO
	player.move_velocity = 0
	player.has_control = false
	$Garidog.position = $FinishPoint.position + Vector2(-105, 14)
	$Morador.position = $FinishPoint.position + Vector2(105, 14)
	$Garidog/TalkArea.set_deferred("monitoring", false)
	$Morador/TalkArea.set_deferred("monitoring", false)
	Dialogic.timeline_ended.connect(_on_conclusion_finished, CONNECT_ONE_SHOT)
	Phase1Dialogue.start("res://dialogic/timelines/fase1/conclusao.dtl", self)

func _on_conclusion_finished() -> void:
	_conclusion_dialogue_active = false
	_minigames_active = true
	var minigames := PHASE1_MINIGAMES.instantiate()
	minigames.connect("finished", _on_minigames_finished)
	add_child(minigames)

func _on_minigames_finished() -> void:
	_phase_completed = true
	_minigames_active = false
	player.has_control = true
	_resume_tutorial()

func _update_hud() -> void:
	if not is_instance_valid(objective_label):
		return
	objective_label.text = "REEE recolhidos: %d/%d" % [_reee_count, _reee_total]
	hud_panels.set_progress(_reee_count, _reee_total)
	var previous_text := tutorial_label.text
	if not _intro_finished:
		tutorial_label.text = ""
		return
	if _phase_completed:
		tutorial_label.text = "Missão concluída! Explore a vila recuperada e veja o parque e o rio."
	elif not _learned_walk:
		tutorial_label.text = "Primeiro, ande pela rua: A/D ou setas esquerda/direita."
	elif not _learned_jump:
		tutorial_label.text = "Pule os bloqueios: Espaço, W ou seta para cima. Segure para pular mais alto."
	elif _reee_count == _reee_total:
		tutorial_label.text = "Todos os REEE recolhidos! Siga para a praça de reciclagem, depois do rio."
	elif _zone_index == $Flow/Finish.get_index():
		tutorial_label.text = "Faltam %d REEE. Volte e procure nas varandas, no mirante e nas pedras do rio." % (_reee_total - _reee_count)
	else:
		var marker := $Flow.get_child(_zone_index)
		tutorial_label.text = str(marker.get_meta("hint", ""))
	if tutorial_label.text != previous_text:
		_pending_tutorial_speech = true
	_narrate_tutorial_when_ready()

func _narrate_tutorial_when_ready() -> void:
	if not _pending_tutorial_speech or _tutorial_blocked() or not tutorial_label.is_visible_in_tree():
		return
	_pending_tutorial_speech = false
	if tutorial_label.text == _last_narrated_tutorial:
		return
	_last_narrated_tutorial = tutorial_label.text
	Speech.speak(tutorial_label.text, "instruction")

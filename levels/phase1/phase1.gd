extends Node2D

## Fase 1: tutorial guiado por áreas, coleta de REEE e conclusão com minigames.

const MINIGAMES_SCENE := preload("res://levels/phase1/minigames/phase1_minigames.tscn")
const CONCLUSION_TIMELINE := "res://dialogic/timelines/fase1/conclusao.dtl"
## Peso dos REEE na restauração; o restante vem do bônus de atenção e atividades.
const REEE_RESTORATION_WEIGHT := 0.8
## Atividades chamadas pelos diálogos via `[signal arg="minigame:<id>"]`.
const MINIGAME_PAGES := {
	"triagem": [Phase1Minigames.PAGE_SORTING],
	"associacao": [Phase1Minigames.PAGE_MATCHING],
	"cruzadinha": [Phase1Minigames.PAGE_CROSSWORD],
}

@export var fall_reset_y := 380.0
## Limites da câmera do Garibot (esquerda, topo, largura, altura).
@export var camera_limits := Rect2i(-300, -650, 5700, 1030)
## Bônus de restauração por resposta certa ou atividade concluída (máx. 1 - peso dos REEE).
@export var bonus_per_reward := 0.04
## Pausa entre a bateria acabar e o Garibot renascer (s).
@export var respawn_delay := 1.4

var _reee_count := 0
var _reee_total := 0
var _zone_index := 0
var _intro_finished := false
var _learned_walk := false
var _learned_jump := false
var _dialogue_active := false
var _conclusion_started := false
var _conclusion_dialogue_active := false
var _minigames_active := false
var _phase_completed := false
var _bonus := 0.0
## Último ponto seguro: início da fase ou marcador da zona mais avançada alcançada.
var _respawn_point := Vector2.ZERO
var _respawn_zone := 0
var _pending_minigame := ""
var _pending_tutorial_speech := false
var _last_narrated_tutorial := ""

@onready var player: Player = $Player
@onready var restoration: RestorationProgress = $Restoration
@onready var intro_cutscene: CutscenePlayer = $CutscenePlayer
@onready var reee_cutscene: CutscenePlayer = $ReeeCutscene
@onready var objective_label: Label = $HUD/Objective
@onready var tutorial_label: Label = $HUD/Tutorial
@onready var hud_panels: CollectibleProgressHud = $HUD/PixelPanels
@onready var battery_hud: BatteryHealthHud = $HUD/Battery
@onready var talking_npcs: Array[Phase1Npc] = [$Garidog, $CorreioBo, $Morador, $Crianca, $DonaLia, $Pipa]


func _ready() -> void:
	$HUD.show()
	_setup_camera()
	_respawn_point = player.position
	_respawn_zone = _current_zone()
	player.health.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	battery_hud.set_charge(int(player.health.health), int(player.health.max_health))
	var items := get_tree().get_nodes_in_group("phase1_reee")
	_reee_total = items.size()
	for item: AreaCollectible in items:
		item.monitoring = false
		item.collected.connect(_on_reee_collected)
	_set_npcs_listening(false)
	restoration.set_value(0.0, false)
	Settings.setting_changed.connect(_on_setting_changed)
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	Dialogic.signal_event.connect(_on_dialogue_signal)
	intro_cutscene.started.connect(_on_cinematic_started)
	intro_cutscene.finished.connect(_on_intro_finished)
	reee_cutscene.started.connect(_on_cinematic_started)
	reee_cutscene.finished.connect(_resume_tutorial)
	_apply_accessibility_preferences()
	_set_tutorial_visible(false)
	_update_hud()
	intro_cutscene.run()


func _process(_delta: float) -> void:
	if _tutorial_blocked():
		return
	if (
		not _learned_walk
		and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"))
	):
		_learned_walk = true
		_update_hud()
	if _learned_walk and not _learned_jump and Input.is_action_just_pressed("move_up"):
		_learned_jump = true
		_update_hud()
	var zone := _current_zone()
	if zone != _zone_index:
		_zone_index = zone
		_update_hud()
	if zone > _respawn_zone and player.is_on_floor():
		_respawn_zone = zone
		_respawn_point = $Flow.get_child(zone).position
	if _can_conclude():
		_begin_conclusion()


func _physics_process(_delta: float) -> void:
	if _intro_finished and player.position.y > fall_reset_y:
		_return_to_river_bank()


## Usada pelo CutscenePlayer para abrir diálogos nos balões da fase.
func start_dialogue(timeline_path: String) -> void:
	Phase1Dialogue.start(timeline_path, self)


func _setup_camera() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = camera_limits.position.x
	camera.limit_top = camera_limits.position.y
	camera.limit_right = camera_limits.end.x
	camera.limit_bottom = camera_limits.end.y


func _current_zone() -> int:
	var zone := 0
	for marker: Marker2D in $Flow.get_children():
		if player.position.x >= marker.position.x:
			zone = marker.get_index()
	return zone


func _can_conclude() -> bool:
	return (
		not _conclusion_started
		and _reee_count == _reee_total
		and player.position.x >= $Flow/Finish.position.x
		and player.is_on_floor()
	)


## Cair no rio devolve o Garibot à margem, sem perder as coletas.
func _return_to_river_bank() -> void:
	player.position = $RiverCheckpoint.position
	player.velocity = Vector2.ZERO
	player.move_velocity = 0.0
	player.jump_velocity = 0.0
	player.get_node("Camera2D").reset_smoothing()


func _on_player_health_changed(health: float, max_health: float) -> void:
	battery_hud.set_charge(ceili(health), int(max_health))


## Bateria zerada: o Garibot "recarrega" e volta ao último ponto seguro,
## sem perder os REEE coletados.
func _on_player_died() -> void:
	_set_tutorial_visible(false)
	Speech.speak("O Garibot ficou sem bateria! Recarregando no último ponto seguro.", "instruction")
	await get_tree().create_timer(respawn_delay).timeout
	player.revive(_respawn_point)
	_resume_tutorial()


func _set_npcs_listening(enabled: bool) -> void:
	for npc in talking_npcs:
		npc.get_node("TalkArea").set_deferred("monitoring", enabled)


func _on_setting_changed(setting_name: String, _value: Variant) -> void:
	if setting_name in ["high_contrast", "dialog_font_size"]:
		_apply_accessibility_preferences()


func _apply_accessibility_preferences() -> void:
	var font_size := int(Settings.get_setting("dialog_font_size", 18))
	var foreground := (
		Color.WHITE if Settings.get_setting("high_contrast", false) else Color("#f5edca")
	)
	objective_label.add_theme_font_size_override("font_size", maxi(17, font_size))
	tutorial_label.add_theme_font_size_override("font_size", maxi(18, font_size))
	objective_label.add_theme_color_override("font_color", foreground)
	tutorial_label.add_theme_color_override("font_color", foreground)


func _on_intro_finished() -> void:
	_intro_finished = true
	for item in get_tree().get_nodes_in_group("phase1_reee"):
		item.set_deferred("monitoring", true)
	_set_npcs_listening(true)
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
	if not _pending_minigame.is_empty() and not _conclusion_dialogue_active:
		var minigame_id := _pending_minigame
		_pending_minigame = ""
		_open_minigame.call_deferred(minigame_id)
		return
	# Espera o Dialogic e a cutscene terminarem a limpeza antes de retomar o HUD.
	_resume_tutorial.call_deferred()


## Sinais emitidos pelas timelines: `acerto` premia a resposta certa e
## `minigame:<id>` abre a atividade quando o diálogo terminar.
func _on_dialogue_signal(argument: String) -> void:
	if argument == "acerto":
		_add_bonus()
	elif argument.begins_with("minigame:"):
		_pending_minigame = argument.trim_prefix("minigame:")


func _add_bonus() -> void:
	GameAudio.play_sound(&"correct")
	_bonus = minf(_bonus + bonus_per_reward, 1.0 - REEE_RESTORATION_WEIGHT)
	_refresh_restoration()


func _refresh_restoration() -> void:
	var base := float(_reee_count) / maxi(_reee_total, 1) * REEE_RESTORATION_WEIGHT
	# Com todos os REEE a vila fica 100% recuperada, independentemente do bônus.
	restoration.set_value(1.0 if _reee_count == _reee_total else base + _bonus)


func _open_minigame(minigame_id: String) -> void:
	if not MINIGAME_PAGES.has(minigame_id):
		push_error("Minigame desconhecido: %s" % minigame_id)
		return
	_minigames_active = true
	player.has_control = false
	var minigames: Phase1Minigames = MINIGAMES_SCENE.instantiate()
	minigames.pages.assign(MINIGAME_PAGES[minigame_id])
	minigames.final_title = "Muito bem!"
	minigames.final_message = "Você está cada vez mais perto de salvar a vila."
	minigames.final_button_text = "Continuar"
	minigames.finished.connect(_on_activity_finished)
	add_child(minigames)


func _on_activity_finished(perfect: bool) -> void:
	_minigames_active = false
	if perfect:
		_add_bonus()
	player.has_control = true
	_resume_tutorial()


func _on_reee_collected(_item_name: String) -> void:
	GameAudio.play_sound(&"collect")
	_reee_count += 1
	_refresh_restoration()
	if _reee_count == 1:
		reee_cutscene.run()
	_update_hud()


func _begin_conclusion() -> void:
	_conclusion_started = true
	_conclusion_dialogue_active = true
	player.position = $FinishPoint.position
	player.velocity = Vector2.ZERO
	player.move_velocity = 0.0
	player.has_control = false
	$Garidog.position = $FinishPoint.position + Vector2(-105, 14)
	$Morador.position = $FinishPoint.position + Vector2(105, 14)
	$Garidog/TalkArea.set_deferred("monitoring", false)
	$Morador/TalkArea.set_deferred("monitoring", false)
	Dialogic.timeline_ended.connect(_on_conclusion_finished, CONNECT_ONE_SHOT)
	start_dialogue(CONCLUSION_TIMELINE)


func _on_conclusion_finished() -> void:
	_conclusion_dialogue_active = false
	_minigames_active = true
	var minigames: Phase1Minigames = MINIGAMES_SCENE.instantiate()
	minigames.pages.assign([Phase1Minigames.PAGE_CROSSWORD])
	minigames.finished.connect(_on_minigames_finished)
	add_child(minigames)


func _on_minigames_finished(_perfect: bool) -> void:
	_phase_completed = true
	_minigames_active = false
	player.has_control = true
	_resume_tutorial()


func _tutorial_blocked() -> bool:
	return (
		not _intro_finished
		or player.is_dead()
		or intro_cutscene.is_running()
		or reee_cutscene.is_running()
		or _dialogue_active
		or _conclusion_dialogue_active
		or _minigames_active
	)


func _set_tutorial_visible(value: bool) -> void:
	tutorial_label.visible = value
	hud_panels.set_tutorial_visible(value)


func _resume_tutorial() -> void:
	if _tutorial_blocked():
		return
	player.has_control = true
	_set_tutorial_visible(true)
	_update_hud()


func _update_hud() -> void:
	objective_label.text = "REEE recolhidos: %d/%d" % [_reee_count, _reee_total]
	hud_panels.set_progress(_reee_count, _reee_total)
	if not _intro_finished:
		tutorial_label.text = ""
		return
	var previous_text := tutorial_label.text
	tutorial_label.text = _tutorial_text()
	if tutorial_label.text != previous_text:
		_pending_tutorial_speech = true
	_narrate_tutorial_when_ready()


func _tutorial_text() -> String:
	if _phase_completed:
		return "Missão concluída! Explore a vila recuperada e veja o parque e o rio."
	if not _learned_walk:
		return "Primeiro, ande pela rua: A/D ou setas esquerda/direita."
	if not _learned_jump:
		return "Pule os bloqueios: Espaço, W ou seta para cima. Segure para pular mais alto."
	if _reee_count == _reee_total:
		return "Todos os REEE recolhidos! Siga para a praça de reciclagem, depois do rio."
	if _zone_index == $Flow/Finish.get_index():
		return (
			"Faltam %d REEE. Volte e procure nas varandas, no mirante e nas pedras do rio."
			% (_reee_total - _reee_count)
		)
	return str($Flow.get_child(_zone_index).get_meta("hint", ""))


func _narrate_tutorial_when_ready() -> void:
	if (
		not _pending_tutorial_speech
		or _tutorial_blocked()
		or not tutorial_label.is_visible_in_tree()
	):
		return
	_pending_tutorial_speech = false
	if tutorial_label.text != _last_narrated_tutorial:
		_last_narrated_tutorial = tutorial_label.text
		Speech.speak(tutorial_label.text, "instruction")
